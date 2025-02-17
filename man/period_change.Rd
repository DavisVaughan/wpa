% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/period_change.R
\name{period_change}
\alias{period_change}
\title{Plot the distribution of percentage change between periods
of a Workplace Analytics metric by the number of employees.}
\usage{
period_change(
  data,
  compvar,
  before_start = min(as.Date(data$Date, "\%m/\%d/\%Y")),
  before_end,
  after_start = as.Date(before_end) + 1,
  after_end = max(as.Date(data$Date, "\%m/\%d/\%Y")),
  return = "count"
)
}
\arguments{
\item{data}{Person Query as a dataframe including date column named \code{"Date"}
This function assumes the data format is \code{MM/DD/YYYY} as is standard in a
Workplace Analytics query output.}

\item{compvar}{WpA comparison variable to compare person change before and
after For example, \code{"Collaboration_hours"}}

\item{before_start}{Start date of "before" time period in \code{YYYY-MM-DD}}

\item{before_end}{End date of "before" time period in \code{YYYY-MM-DD}}

\item{after_start}{Start date of "after" time period in \code{YYYY-MM-DD}}

\item{after_end}{End date of "after" time period in \code{YYYY-MM-DD}}

\item{return}{Character vector specifying whether to return plot as Count or
Percentage of Employees. Valid inputs include:
\itemize{
\item "count" (default)
\item "percentage"
\item "table"
}}
}
\value{
ggplot object showing a bar plot (histogram) of change for two time
intervals.
}
\description{
This function also presents the p-value for the null hypothesis
that the variable has not changed, using a Wilcox signed-rank test.
}
\examples{
# Run plot
period_change(sq_data, compvar = "Workweek_span", before_end = "2019-11-16")

\donttest{
# Run plot with more specific arguments
period_change(sq_data,
              compvar = "Workweek_span",
              before_start = "2019-11-03",
              before_end = "2019-11-16",
              after_start = "2019-12-03",
              after_end = "2019-12-16",
              return = "percentage")
}
}
\seealso{
Other Visualization: 
\code{\link{afterhours_dist}()},
\code{\link{afterhours_fizz}()},
\code{\link{afterhours_line}()},
\code{\link{afterhours_rank}()},
\code{\link{afterhours_summary}()},
\code{\link{afterhours_trend}()},
\code{\link{collaboration_area}()},
\code{\link{collaboration_dist}()},
\code{\link{collaboration_fizz}()},
\code{\link{collaboration_line}()},
\code{\link{collaboration_rank}()},
\code{\link{collaboration_sum}()},
\code{\link{collaboration_trend}()},
\code{\link{create_bar_asis}()},
\code{\link{create_bar}()},
\code{\link{create_boxplot}()},
\code{\link{create_bubble}()},
\code{\link{create_dist}()},
\code{\link{create_fizz}()},
\code{\link{create_inc}()},
\code{\link{create_line_asis}()},
\code{\link{create_line}()},
\code{\link{create_period_scatter}()},
\code{\link{create_rank}()},
\code{\link{create_sankey}()},
\code{\link{create_scatter}()},
\code{\link{create_stacked}()},
\code{\link{create_tracking}()},
\code{\link{create_trend}()},
\code{\link{email_dist}()},
\code{\link{email_fizz}()},
\code{\link{email_line}()},
\code{\link{email_rank}()},
\code{\link{email_summary}()},
\code{\link{email_trend}()},
\code{\link{external_network_plot}()},
\code{\link{hr_trend}()},
\code{\link{hrvar_count}()},
\code{\link{hrvar_trend}()},
\code{\link{internal_network_plot}()},
\code{\link{keymetrics_scan}()},
\code{\link{meeting_dist}()},
\code{\link{meeting_fizz}()},
\code{\link{meeting_line}()},
\code{\link{meeting_quality}()},
\code{\link{meeting_rank}()},
\code{\link{meeting_summary}()},
\code{\link{meeting_trend}()},
\code{\link{meetingtype_dist_ca}()},
\code{\link{meetingtype_dist_mt}()},
\code{\link{meetingtype_dist}()},
\code{\link{meetingtype_summary}()},
\code{\link{mgrcoatt_dist}()},
\code{\link{mgrrel_matrix}()},
\code{\link{one2one_dist}()},
\code{\link{one2one_fizz}()},
\code{\link{one2one_freq}()},
\code{\link{one2one_line}()},
\code{\link{one2one_rank}()},
\code{\link{one2one_sum}()},
\code{\link{one2one_trend}()},
\code{\link{workloads_dist}()},
\code{\link{workloads_fizz}()},
\code{\link{workloads_line}()},
\code{\link{workloads_rank}()},
\code{\link{workloads_summary}()},
\code{\link{workloads_trend}()},
\code{\link{workpatterns_area}()},
\code{\link{workpatterns_rank}()}

Other Time-series: 
\code{\link{IV_by_period}()},
\code{\link{create_line_asis}()},
\code{\link{create_line}()},
\code{\link{create_period_scatter}()},
\code{\link{create_trend}()}

Other Flexible: 
\code{\link{create_bar_asis}()},
\code{\link{create_bar}()},
\code{\link{create_boxplot}()},
\code{\link{create_bubble}()},
\code{\link{create_dist}()},
\code{\link{create_fizz}()},
\code{\link{create_hist}()},
\code{\link{create_inc}()},
\code{\link{create_line_asis}()},
\code{\link{create_line}()},
\code{\link{create_period_scatter}()},
\code{\link{create_rank}()},
\code{\link{create_sankey}()},
\code{\link{create_scatter}()},
\code{\link{create_stacked}()},
\code{\link{create_tracking}()},
\code{\link{create_trend}()}

Other Flexible Input: 
\code{\link{create_ITSA}()}
}
\author{
Mark Powers \href{mailto:mark.powers@microsoft.com}{mark.powers@microsoft.com}
}
\concept{Flexible}
\concept{Flexible Input}
\concept{Time-series}
\concept{Visualization}
