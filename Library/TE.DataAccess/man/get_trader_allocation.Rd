% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/common_dataplex.r
\name{get_trader_allocation}
\alias{get_trader_allocation}
\title{Get trader allocation value}
\usage{
get_trader_allocation(trader, start, end)
}
\arguments{
\item{trader}{integer, trader ID.}

\item{start}{Date start date}

\item{end}{Date end date}
}
\value{
\code{allocation} numeric, allocation value.
}
\description{
Returns trader allocation value in USD.
Reads from "trader_allocation" datastore
}

