# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

#' @title Create a rank table of working patterns
#'
#' @description
#' Takes in an Hourly Collaboration query and returns a count
#' table of working patterns, ranked from the most common to the
#' least.
#'
#' @param data A data frame containing hourly collaboration data.
#' @param signals Character vector to specify which collaboration metrics to
#'   use:
#'   - `"email"` (default) for emails only
#'   - `"IM"` for Teams messages only
#'   - `"unscheduled_calls"` for Unscheduled Calls only
#'   - `"meetings"` for Meetings only
#'   - or a combination of signals, such as `c("email", "IM")`
#' @param start_hour A character vector specifying starting hours,
#' e.g. "`0900"`
#' @param end_hour A character vector specifying starting hours,
#' e.g. `"1700"`
#' @param top number specifying how many top working patterns to display in plot,
#' e.g. `"10"`
#' @param return String specifying what to return. This must be one of the
#'   following strings:
#'   - `"plot"`
#'   - `"table"`
#'
#' See `Value` for more information.

#' @return
#' A different output is returned depending on the value passed to the `return`
#' argument:
#'   - `"plot"`: ggplot object. A plot with the y-axis showing the top ten
#'   working patterns and the x-axis representing each hour of the day.
#'   - `"table"`: data frame. A summary table for the top working patterns.
#'
#' @importFrom data.table ":=" "%like%" "%between%"
#'
#' @examples
#' workpatterns_rank(
#'   data = em_data,
#'   signals = c(
#'     "email",
#'     "IM",
#'     "unscheduled_calls",
#'     "meetings"
#'   )
#'   )
#'
#' @family Visualization
#' @family Working Patterns
#'
#' @export
workpatterns_rank <- function(data,
                              signals = c("email", "IM"),
                              start_hour = "0900",
                              end_hour = "1700",
                              top = 10,
                              return = "plot"){

  # Make sure data.table knows we know we're using it
  .datatable.aware = TRUE

  ## Save original
  start_hour_o <- start_hour
  end_hour_o <- end_hour

  ## Coerce to numeric, remove trailing zeros
  start_hour <- as.numeric(gsub(pattern = "00$", replacement = "", x = start_hour))
  end_hour <- as.numeric(gsub(pattern = "00$", replacement = "", x = end_hour))

  ## convert to data.table
  data2 <-
    data %>%
    dplyr::mutate(Date = as.Date(Date, format = "%m/%d/%Y")) %>%
    data.table::as.data.table() %>%
    data.table::copy()

  ## Dynamic input for signals
  ## Text replacement only for allowed values
  if(any(signals %in% c("email", "IM", "unscheduled_calls", "meetings"))){

    signal_set <- gsub(pattern = "email", replacement = "Emails_sent", x = signals) # case-sensitive
    signal_set <- gsub(pattern = "IM", replacement = "IMs_sent", x = signal_set)
    signal_set <- gsub(pattern = "unscheduled_calls", replacement = "Unscheduled_calls", x = signal_set)
    signal_set <- gsub(pattern = "meetings", replacement = "Meetings", x = signal_set)

    ## Create label for plot subtitle
    subtitle_signal <- "signals" # placeholder

  } else {

    stop("Invalid input for `signals`.")

  }

  ## Create 24 summed `Signals_sent` columns
  signal_cols <- purrr::map(0:23, ~combine_signals(data, hr = ., signals = signal_set))
  signal_cols <- bind_cols(signal_cols)

  ## Use names for matching
  input_var <- names(signal_cols)

  ## Signals sent by Person and Date
  signals_df <-
    data2 %>%
    .[, c("PersonId", "Date")] %>%
    cbind(signal_cols)

  ## Signal label
  sig_label <- ifelse(length(signal_set) > 1, "Signals_sent", signal_set)

  ## Create binary variable 0 or 1
  num_cols <- names(which(sapply(signals_df, is.numeric))) # Get numeric columns

  signals_df <-
    signals_df %>%
    data.table::as.data.table() %>%
    .[, (num_cols) := lapply(.SD, function(x) ifelse(x > 0, 1, 0)), .SDcols = num_cols]

  signals_df <- signals_df[, list(WeekCount = .N,
                                  PersonCount = dplyr::n_distinct(PersonId)), by = input_var]

  myTable_return <- data.table::setorder(signals_df, -PersonCount)

  if(return == "plot"){

    ## Plot return
    sig_label_ <- paste0(sig_label, "_")

	myTable_return <-
	  myTable_return %>%
	  arrange(desc(WeekCount)) %>%
	  mutate(patternRank= 1:nrow(.))

    ## Table for annotation
    myTable_legends <-
      myTable_return %>%
      dplyr::select(patternRank, WeekCount) %>%
      dplyr::mutate(WeekPercentage = WeekCount / sum(WeekCount, na.rm = TRUE),
                    WeekCount = paste0(scales::percent(WeekPercentage, accuracy = 0.1))) %>%
      utils::head(top)

	coverage <-
	  myTable_legends %>%
	  summarize(total = sum(WeekPercentage)) %>%
	  pull(1) %>%
	  scales::percent(accuracy = 0.1)

	myTable_return %>%
	  dplyr::select(patternRank, dplyr::starts_with(sig_label_))  %>%
	  purrr::set_names(nm = gsub(
	    pattern = sig_label_,
	    replacement = "",
	    x = names(.)
	  )) %>%
	  purrr::set_names(nm = gsub(
	    pattern = "_.+",
	    replacement = "",
	    x = names(.)
	  )) %>%
	  utils::head(top)  %>%
	  tidyr::gather(Hours, Freq, -patternRank)  %>%
	  ggplot2::ggplot(ggplot2::aes(x = Hours, y = patternRank, fill = Freq)) +
	  ggplot2::geom_tile(height = .5) +
	  ggplot2::ylab(paste("Top", top, "activity patterns")) +
	  #ggplot2::scale_fill_gradient2(low = "white", high = "#1d627e") +
	  ggplot2::scale_y_reverse(expand = c(0, 0), breaks = seq(1, top)) +
	  theme_wpa_basic() +
	  ggplot2::scale_x_discrete(position = "top")+
      ggplot2::theme(
        axis.title.x = element_blank(),
        axis.line = element_blank(),
        axis.ticks = element_blank()
      ) +
      scale_fill_continuous(
        guide = "legend",
        low = "white",
        high = "#1d627e",
        breaks = 0:1,
        name = "",
        labels = c("", paste("Observed", subtitle_signal, "activity"))
      ) +
      ggplot2::annotate(
        "text",
        y = myTable_legends$patternRank,
        x = 26.5,
        label = myTable_legends$WeekCount,
        size = 3
      )+
      ggplot2::annotate("rect",
               xmin = 25,
               xmax = 28,
               ymin = 0.5,
               ymax = length(myTable_legends$patternRank) + 0.5,
               alpha = .2) +
      ggplot2::annotate("rect",
               xmin = 0.5,
               xmax = start_hour + 0.5,
               ymin = 0.5,
               ymax = length(myTable_legends$patternRank) + 0.5,
               alpha = .1,
               fill = "gray50") +
      ggplot2::annotate("rect",
               xmin = end_hour + 0.5,
               xmax = 24.5,
               ymin = 0.5,
               ymax = length(myTable_legends$patternRank) + 0.5,
               alpha = .1,
               fill = "gray50") +
  labs(
    title = "Patterns of digital activity",
    subtitle = paste("Hourly activity based on", subtitle_signal ,"sent over a week"),
    caption = paste(
      "Top", top, "patterns represent", coverage, "of workweeks.", extract_date_range(data, return = "text"))
    )

  } else if(return == "table"){

    dplyr::as_tibble(myTable_return)

  } else {

    stop("Invalid `return`")

  }
}
