# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

#' @title Create a network plot with the person-to-person query
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#'
#' Analyse a person-to-person (P2P) network query, with multiple visualisation
#' and analysis output options. Pass a data frame containing a person-to-person
#' query and return a network visualization. Options are available for community
#' detection using either the Louvain or the Leiden algorithms.
#'
#'
#' @param data Data frame containing a person-to-person query.
#' @param hrvar String containing the label for the HR attribute.
#' @param display String determining what output to return. Valid values
#'   include:
#'   - `"hrvar"` (default): compute analysis or visuals without computing
#'   communities.
#'   - `"louvain"`: compute analysis or visuals with community detection, using
#'   the Louvain algorithm.
#'   - `"leiden"`: compute analysis or visuals with community detection, using
#'   the Leiden algorithm. This requires all the pre-requisites of the
#'   **leiden** package installed, which includes Python and **reticulate**.
#'
#' @param return String specifying what output to return. This must be one of the
#'   following strings:
#'   - `'plot'` (default)
#'   - `'sankey'`
#'   - `'table'`
#'   - `'data'`
#'   - `'describe'`
#'   - `'network'`
#'
#' See `Value` for more information.
#'
#' @param path File path for saving the PDF output. Defaults to a timestamped
#'   path based on current parameters.
#' @param desc_hrvar Character vector of length 3 containing the HR attributes
#'   to use when returning the `"describe"` output. See `network_describe()`.
#' @param bg_fill String to specify background fill colour.
#' @param font_col String to specify font and link colour.
#' @param legend_pos String to specify position of legend. Defaults to
#'   `"bottom"`. See `ggplot2::theme()`. This is applicable for both the
#'   'ggraph' and the fast plotting method. Valid inputs include:
#'   - `"bottom"`
#'   - `"top"`
#'   - `"left"`
#'   -`"right"`
#'
#' @param palette Function for generating a colour palette with a single
#'   argument `n`. Uses "rainbow" by default.
#' @param node_alpha A numeric value between 0 and 1 to specify the transparency
#'   of the nodes. Defaults to 0.7.
#' @param edge_alpha A numeric value between 0 and 1 to specify the transparency
#'   of the edges (only for 'ggraph' mode). Defaults to 1.
#' @param res Resolution parameter to be passed to `leiden::leiden()`. Defaults
#'   to 0.5.
#' @param seed Seed for the random number generator passed to `leiden::leiden()`
#'   to ensure consistency. Only applicable when `display` is set to `"leiden"`.
#' @param algorithm String to specify the node placement algorithm to be used.
#'   Defaults to `"mds"` for the deterministic multi-dimensional scaling of
#'   nodes. See
#'   <https://rdrr.io/cran/ggraph/man/layout_tbl_graph_igraph.html> for a full
#'   list of options.
#' @param size_threshold Numeric value representing the maximum number of edges
#'   before `network_leiden()` switches to use a more efficient, but less
#'   elegant plotting method (native igraph). Defaults to 5000. Set as `0` to
#'   coerce to a fast plotting method every time, and `Inf` to always use the
#'   default plotting method (with 'ggraph').
#' @param weight String to specify which column to use as weights for the
#' network. Defaults to `"StrongTieScore`. To create a graph without weights,
#' supply `NULL` to this argument.
#'
#' @return
#' A different output is returned depending on the value passed to the `return`
#' argument:
#'   - `'plot'`: return a network plot.
#'   - `'sankey'`: return a sankey plot combining communities and HR attribute.
#'   This is only valid if a community detection method is selected at
#'   `display`.
#'   - `'table'`: return a vertex summary table with counts in communities and
#'   HR attribute.
#'   - `'data'`: return a vertex data file that matches vertices with
#'   communities and HR attributes.
#'   - `'describe'`: return a list of data frames which describe each of the
#'   identified communities. The first data frame is a summary table of all the
#'   communities. This is only valid if a community detection method is selected
#'   at `display`.
#'   - `'network'`: return 'igraph' object.
#'
#' @family Network
#'
#' @examples
#' # Simulate a small person-to-person dataset
#' p2p_data <- p2p_data_sim(size = 50)
#'
#' # Return a network plot to console, coloured by hrvar
#' p2p_data %>%
#'   network_p2p(display = "hrvar",
#'               path = NULL,
#'               return = "plot")
#'
#' # Return a network plot to console, coloured by Louvain communities
#' p2p_data %>%
#'   network_p2p(display = "louvain",
#'               path = NULL,
#'               return = "plot")
#'
#'
#' # Return a network plot to console
#' # Coloured by Leiden communities
#' # Using Fruchterman-Reingold force-directed layout algorithm
#' # Force the use of fast plotting method
#' p2p_data %>%
#'   network_p2p(display = "hrvar",
#'               path = NULL,
#'               return = "plot",
#'               algorithm = "lgl",
#'               size_threshold = 0)
#'
#' # Return a data frame matching HR variable and communities to nodes
#' # Using Louvain communities
#' p2p_data %>%
#'   network_p2p(display = "louvain",
#'               return = "data",
#'               algorithm = "fr")
#'
#' @section Running Leiden communities:
#'
#' Running Leiden communities requires python dependencies installed.
#' You can run the following:
#'
#' ```R
#' # Return a network plot to console, coloured by Leiden communities
#'   p2p_data %>%
#'     network_p2p(display = "leiden",
#'                 path = NULL,
#'                 return = "plot")
#' ```
#' When installing the 'leiden' package, you may be required to install the Python
#' libraries 'python-igraph' and 'leidenalg'. You can install them with:
#'
#' ```R
#' reticulate::py_install("python-igraph")
#' reticulate::py_install("leidenalg")
#' ```
#'
#' @import ggplot2
#' @import dplyr
#' @importFrom grDevices rainbow
#' @importFrom graphics legend
#' @importFrom graphics par
#'
#' @export
network_p2p <- function(data,
                        hrvar = "Organization",
                        display = "hrvar",
                        return = "plot",
                        path = paste0("network_p2p_", display),
                        desc_hrvar = c("Organization", "LevelDesignation", "FunctionType"),
                        bg_fill = "#FFFFFF",
                        font_col = "grey20",
                        legend_pos = "bottom",
                        palette = "rainbow",
                        node_alpha = 0.7,
                        edge_alpha = 1,
                        res = 0.5,
                        seed = 1,
                        algorithm = "mds",
                        size_threshold = 5000,
                        weight = "StrongTieScore"){

  ## Set edges df
  if(is.null(weight)){

    edges <-
      data %>%
      mutate(NoWeight = 1) %>% # No weight
      select(from = "TieOrigin_PersonId",
             to = "TieDestination_PersonId",
             weight = "NoWeight")

  } else {

    edges <-
      data %>%
      select(from = "TieOrigin_PersonId",
             to = "TieDestination_PersonId",
             weight = weight)

  }

  ## Set variables
  TO_hrvar <- paste0("TieOrigin_", hrvar)
  TD_hrvar <- paste0("TieDestination_", hrvar)

  ## Vertices data frame to provide meta-data
  vert_ft <-
    rbind(
      # TieOrigin
      edges %>%
        select(from) %>% # Single column
        unique() %>% # Remove duplications
        left_join(select(data, TieOrigin_PersonId, TO_hrvar),
                  by = c("from"  = "TieOrigin_PersonId")) %>%
        select(node = "from", !!sym(hrvar) := TO_hrvar),

      # TieDestination
      edges %>%
        select(to) %>% # Single column
        unique() %>% # Remove duplications
        left_join(select(data, TieDestination_PersonId, TD_hrvar),
                  by = c("to"  = "TieDestination_PersonId")) %>%
        select(node = "to", !!sym(hrvar) := TD_hrvar)
    )


  ## Create 'igraph' object
  g_raw <-
    igraph::graph_from_data_frame(edges,
                                  directed = TRUE, # Directed, but FALSE for visualization
                                  vertices = unique(vert_ft)) # remove duplicates

  ## Assign weights
  g_raw$weight <- edges$weight

  ## Finalise `g` object
  ## If community detection is selected, this is where the communities are appended

  if(display == "hrvar"){

    g <- g_raw %>% igraph::simplify()

    ## Name of vertex attribute
    v_attr <- hrvar

    } else if(display == "louvain"){

    ## Convert to undirected
    g_ud <- igraph::as.undirected(g_raw)

    ## Return a numeric vector of partitions / clusters / modules
    ## Set a low resolution parameter to have fewer groups
    ## weights = NULL means that if the graph as a `weight` edge attribute, this
    ## will be used by default.
    lc <- igraph::cluster_louvain(g_ud, weights = NULL)

    ## Add cluster
    g <-
      g_ud %>%
      # Add louvain partitions to graph object
      igraph::set_vertex_attr("cluster", value = as.character(igraph::membership(lc))) %>% # Return membership - diff from Leiden
      igraph::simplify()

    ## Name of vertex attribute
    v_attr <- "cluster"

  } else if(display == "leiden"){

    # Check package installation
    check_pkg_installed(pkgname = "leiden")

    ## Return a numeric vector of partitions / clusters / modules
    ## Set a low resolution parameter to have fewer groups
    ld <- leiden::leiden(
      g_raw,
      resolution_parameter = res,
      seed = seed,
      weights = g_raw$weight) # create partitions

    ## Add cluster
    g <-
      g_raw %>%
      # Add leiden partitions to graph object
      igraph::set_vertex_attr("cluster", value = as.character(ld)) %>%
      igraph::simplify()

    ## Name of vertex attribute
    v_attr <- "cluster"

  } else {

    stop("Please enter a valid input for `display`.")

  }


  # Common area -------------------------------------------------------------

  ## Create vertex table
  vertex_tb <-
    g %>%
    igraph::get.vertex.attribute() %>%
    as_tibble()

  ## Set layout for graph
  g_layout <-
    g %>%
    ggraph::ggraph(layout = "igraph", algorithm = algorithm)

  ## Timestamped File Path
  out_path <- paste0(path, "_", tstamp(), ".pdf")

  # Return ------------------------------------------------------------------

  if(return == "plot"){

    ## Use fast plotting method

    if(igraph::ecount(g) > size_threshold){

      message("Using fast plot method due to large network size...")

      ## Set colours
      colour_tb <-
        tibble(!!sym(v_attr) := unique(igraph::get.vertex.attribute(g, name = v_attr))) %>%
        mutate(colour = rainbow(nrow(.))) # No palette choice

      ## Colour vector
      colour_v <-
        tibble(!!sym(v_attr) := igraph::get.vertex.attribute(g, name = v_attr)) %>%
        left_join(colour_tb, by = v_attr) %>%
        pull(colour)

      ## Set graph plot colours
      igraph::V(g)$color <- grDevices::adjustcolor(colour_v, alpha.f = node_alpha)
      igraph::V(g)$frame.color <- NA
      igraph::E(g)$width <- 1

      ## Internal basic plotting function used inside `network_p2p()`
      plot_basic_graph <- function(lpos = legend_pos){

        old_par <- par(no.readonly = TRUE)
        on.exit(par(old_par))

        par(bg = bg_fill)

        layout_text <- paste0("igraph::layout_with_", algorithm)

        ## Legend position

        if(lpos == "left"){

          leg_x <- -1.5
          leg_y <- 0.5

        } else if(lpos == "right"){

          leg_x <- 1.5
          leg_y <- 0.5

        } else if(lpos == "top"){

          leg_x <- 0
          leg_y <- 1.5

        } else if(lpos == "bottom"){

          leg_x <- 0
          leg_y <- -1.0

        } else {

          stop("Invalid `legend_pos` input.")

        }

        graphics::plot(g,
                       layout = eval(parse(text = layout_text)),
                       vertex.label = NA,
                       vertex.size = 3,
                       edge.arrow.mode = "-",
                       edge.color = "#adadad")

        graphics::legend(x = leg_x,
                         y = leg_y,
                         legend = colour_tb[[v_attr]], # vertex attribute
                         pch = 21,
                         text.col = font_col,
                         col = "#777777",
                         pt.bg = colour_tb$colour,
                         pt.cex = 2,
                         cex = .8,
                         bty = "n",
                         ncol = 1)
      }

      ## Default PDF output unless NULL supplied to path
      if(is.null(path)){

        plot_basic_graph()

      } else {

        grDevices::pdf(out_path)

        plot_basic_graph()

        grDevices::dev.off()

        message(paste0("Saved to ", out_path, "."))

      }

    } else {

      plot_output <-
        g_layout +
        ggraph::geom_edge_link(colour = "lightgrey", edge_width = 0.05, alpha = edge_alpha) +
        ggraph::geom_node_point(aes(colour = !!sym(v_attr)),
                                alpha = node_alpha,
                                pch = 16) +
        theme_void() +
        theme(
          legend.position = legend_pos,
          legend.background = element_rect(fill = bg_fill, colour = bg_fill),

          text = element_text(colour = font_col),
          axis.line = element_blank(),
          panel.grid = element_blank()
          ) +
        labs(caption = paste0("Person to person collaboration showing ", v_attr, ".  "), # spaces intentional
             y = "",
             x = "")


      # Default PDF output unless NULL supplied to path
      if(is.null(path)){

        plot_output

      } else {

        ggsave(out_path,
               plot = plot_output,
               width = 16,
               height = 9)

        message(paste0("Saved to ", out_path, "."))

      }

    }

  } else if(return == "table"){


    if(display == "hrvar"){

      vertex_tb %>% count(!!sym(hrvar))

    } else if(display %in% c("louvain", "leiden")){

      vertex_tb %>%
        count(!!sym(hrvar), cluster)

    }

  } else if(return == "data"){

    vertex_tb

  } else if(return == "network"){

    g

  } else if(return == "sankey"){

    if(display == "hrvar"){

      message("Note: no sankey return option is available if `display` is set to 'hrvar'.
      Please specify either 'louvain' or 'leiden'")

    } else if(display %in% c("louvain", "leiden")){

      create_sankey(data = vertex_tb %>% count(!!sym(hrvar), cluster),
                    var1 = hrvar,
                    var2 = "cluster",
                    count = "n")

    }

  } else if(return == "describe"){

    if(display == "hrvar"){

      message("Note: no describe return option is available if `display` is set to 'hrvar'.
      Please specify either 'louvain' or 'leiden'")

    } else if(display %in% c("louvain", "leiden")){

      describe_tb <-
        vertex_tb %>%
        left_join(select(data, starts_with("TieOrigin_")),
                  by = c("name" = "TieOrigin_PersonId"))

      desc_str <-
        describe_tb %>%
        pull(cluster) %>%
        unique()

      out_list <-
        desc_str %>%
        purrr::map(function(x){
          describe_tb %>%
            filter(cluster == x) %>%
            network_describe(hrvar = desc_hrvar)
        }) %>%
        setNames(nm = desc_str)

      summaryTable <-
        list(i = out_list,
             j = names(out_list)) %>%
        purrr::pmap(function(i, j){
          i %>%
            arrange(desc(Percentage)) %>%
            # slice(1) %>%
            mutate_at(vars(starts_with("feature_")), ~tidyr::replace_na(., "")) %>%
            mutate(Community = j,
                   `Attribute 1` = paste(feature_1, "=", feature_1_value),
                   `Attribute 2` = paste(feature_2, "=", feature_2_value),
                   `Attribute 3` = paste(feature_3, "=", feature_3_value)) %>%
            select(Community,
                   `Attribute 1`,
                   `Attribute 2`,
                   `Attribute 3`,
                   PercentageExplained = "Percentage") %>%
            mutate_at(vars(starts_with("Attribute")), ~ifelse(. == " = ", NA, .))
        }) %>%
        bind_rows() %>%
        mutate(sum_na = select(., `Attribute 1`, `Attribute 2`, `Attribute 3`) %>%
                 apply(1, function(x) sum(is.na(x)))) %>%
        arrange(desc(PercentageExplained)) %>%
        group_by(Community, sum_na) %>%
        summarise_all(~first(.)) %>%
        select(-sum_na)

      c(list("summaryTable" = summaryTable), out_list)

    }

  } else {

    stop("Please enter a valid input for `return`.")

  }
}





