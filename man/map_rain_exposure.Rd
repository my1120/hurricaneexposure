% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/map_exposure.R
\name{map_rain_exposure}
\alias{map_rain_exposure}
\title{Map counties with rain exposure}
\usage{
map_rain_exposure(storm, rain_limit, dist_limit, days_included = c(-2, -1, 0,
  1))
}
\arguments{
\item{storm}{Character string giving the name of the storm to plot (e.g.,
"Floyd-1999")}

\item{rain_limit}{Minimum of rainfall, in millimeters, summed across the days
selected to be included (\code{days_included}), that must fall in a
county for the county to be classified as "exposed" to the storm.}

\item{dist_limit}{Maximum distance, in kilometers, of how close the storm
track must come to the county's population mean center to classify
the county as "exposed" to the storm.}

\item{days_included}{A numeric vector listing the days to include when
calculating total precipitation. Negative numbers are days before the
closest date of the storm to a county. For example,
\code{c(-1, 0, 1)} would calculate rain for a county as the sum of the
rainfall for the day before, the day of, and the day after the date when
the storm center was closest to the county center. Values can range from
-3 to 3 (i.e., at most, you can calculate the total rainfall for the
seven-day window centered on the day when the storm is closest to the
county).}
}
\description{
Map counties as "exposed" or "unexposed" based on the criteria that the
storm came within a given distance (specified by \code{dist_limit}) of
the county's population mean center and a certain amount of rain
\code{rain_limit} fell during a specified window of days (\code{days_included}).
}
\examples{
# Ensure that data package is available before running the example.
#  If it is not, see the `hurricaneexposure` package vignette for details
# on installing the required data package.
if (requireNamespace("hurricaneexposuredata", quietly = TRUE)) {

floyd_map <- map_rain_exposure(storm = "Floyd-1999", rain_limit = 50,
                               dist_limit = 100)
floyd_map

allison_map <- map_rain_exposure(storm = "Allison-2001", rain_limit = 20,
                                 dist_limit = 100, days_included = 0)
map_tracks("Allison-2001", plot_points = FALSE, plot_object = allison_map)
}
}

