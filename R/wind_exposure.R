#' Hurricane exposure by wind for counties
#'
#' This function takes a list of US counties,based on their 5-digit Federal
#' Information Processing Standard (FIPS) codes, boundaries on
#' the range of years to be considered, and thresholds for wind speed (in meters
#' per second) for each  county to be considered "exposed" to the
#' storm. Based on these inputs, the function returns a dataframe with the
#' subset of Atlantic basin storms meeting those criteria for each of the listed
#' counties.
#'
#' @inheritParams county_distance
#' @inheritParams filter_wind_data
#'
#' @return Returns a dataframe with a row for each county-storm
#'    pair and with columns for:
#'    \itemize{
#'      \item{\code{storm_id}: }{Unique storm identifier with the storm name and year,
#'                  separated by a hyphen(e.g., "Alberto-1988",
#'                  "Katrina-2005")}
#'      \item{\code{fips}: }{County's 5-digit Federal Information Processing Standard
#'                  (FIPS) code}
#'      \item{\code{max_sust}: }{Maximum sustained wind speed (in m / s)}
#'      \item{\code{max_gust}: }{Maximum gust wind speed (in m / s)}
#'    }
#'
#' @details For more information on how wind speeds are modeled in this data,
#'    see the documentation for the \code{stormwindmodel} R package.
#' @note Only counties in states in the eastern half of the United States can
#'    be processed by this function.
#'
#' @examples
#' county_wind(counties = c("22071", "51700"),
#'             start_year = 1988, end_year = 2005,
#'             wind_limit = 20, wind_var = "max_sust")
#'
#' @export
#'
#' @importFrom dplyr %>%
county_wind <- function(counties, start_year, end_year, wind_limit,
                        wind_var = "max_sust"){

        wind_df <- filter_wind_data(counties = counties,
                                         year_range = c(start_year, end_year),
                                         wind_limit = wind_limit,
                                         output_vars = c("storm_id", "fips",
                                                         "max_sust",
                                                         "max_gust"))

        return(wind_df)
}

#' Hurricane exposure by wind for communities
#'
#' This function takes a dataframe with multi-county communities and returns a
#' community-level dataframe of "exposed" storms, based on the highest of the
#' maximum sustained wind speed for each county in the community.
#'
#' @inheritParams county_wind
#' @inheritParams county_distance
#' @inheritParams filter_wind_data
#' @inheritParams multi_county_rain
#'
#' @return Returns the same type dataframe as \code{county_rain},
#'    but with storms listed by community instead of county.
#'
#' @export
#'
#' @examples
#' communities <- data.frame(commun = c(rep("ny", 6), "no", "new"),
#'                          fips = c("36005", "36047", "36061",
#'                                   "36085", "36081", "36119",
#'                                   "22071", "51700"))
#' wind_df <- multi_county_wind(communities = communities,
#'                                      start_year = 1988, end_year = 2005,
#'                                      wind_limit = 20)
#'
#' @importFrom dplyr %>%
multi_county_wind <- function(communities, start_year, end_year,
                              wind_limit){

        communities <- dplyr::mutate_(communities, fips = ~ as.character(fips))

        wind_df <- hurricaneexposuredata::storm_winds %>%
                dplyr::mutate_(year = ~ gsub("*.+-", "", storm_id)) %>%
                dplyr::filter_(~ fips %in% communities$fips &
                                       year >= start_year &
                                       year <= end_year) %>%
                dplyr::left_join(communities, by = "fips") %>%
                dplyr::group_by_(~ commun, ~ storm_id) %>%
                dplyr::mutate_(max_wind = ~ max(max_sust)) %>%
                dplyr::filter_(~ max_wind >= wind_limit) %>%
                dplyr::summarize_(mean_wind = ~ mean(max_sust),
                                  max_wind = ~ dplyr::first(max_wind))
        return(wind_df)
}

#' Write storm wind exposure files
#'
#' This function takes an input of locations (either a vector of county FIPS
#' or a dataframe of multi-county FIPS, with all FIPS listed for each county)
#' and creates time series dataframes that can be merged with health time series,
#' giving the dates and exposures for all storms meeting the given
#' storm wind criteria.
#'
#' @inheritParams county_distance
#' @inheritParams county_rain
#' @inheritParams rain_exposure
#'
#' @return Writes out a directory with rain exposure files for each county or
#'    community indicated. For more on the columns in this output, see the
#'    documentation for \code{\link{county_wind}} and
#'    \code{\link{multi_county_wind}}.
#'
#' @examples
#' # By county
#' wind_exposure(locations = c("22071", "51700"),
#'               start_year = 1988, end_year = 2005,
#'               wind_limit = 10,
#'               out_dir = "~/tmp/storms")
#'
#' # For multi-county communities
#' communities <- data.frame(commun = c(rep("ny", 6), "no", "new"),
#'                           fips = c("36005", "36047", "36061",
#'                           "36085", "36081", "36119",
#'                           "22071", "51700"))
#' wind_exposure(locations = communities,
#'               start_year = 1988, end_year = 2005,
#'               wind_limit = 10,
#'               out_dir = "~/tmp/storms")
#'
#' @export
#'
#' @importFrom dplyr %>%
wind_exposure <- function(locations, start_year, end_year,
                              wind_limit, out_dir, out_type = "csv"){

        if(!dir.exists(out_dir)){
                dir.create(out_dir)
        }

        if("commun" %in% colnames(locations)){
                df <- multi_county_wind(communities = locations,
                                        start_year = start_year,
                                        end_year = end_year,
                                        wind_limit = wind_limit) %>%
                        dplyr::rename_(loc = ~ commun) %>%
                        dplyr::ungroup()
        } else {
                df <- county_wind(counties = locations,
                                  start_year = start_year,
                                  end_year = end_year,
                                  wind_limit = wind_limit) %>%
                        dplyr::rename_(loc = ~ fips)
        }
        locs <- as.character(unique(df$loc))

        for(i in 1:length(locs)){
                out_df <- dplyr::filter_(df, ~ loc == locs[i]) %>%
                        dplyr::select_('-loc')
                out_file <- paste0(out_dir, "/", locs[i], ".", out_type)
                if(out_type == "rds"){
                        saveRDS(out_df, file = out_file)
                } else if (out_type == "csv"){
                        utils::write.csv(out_df, file = out_file,
                                         row.names = FALSE)
                }

        }
}
