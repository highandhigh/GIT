% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/common_trade_factory.r
\docType{class}
\name{Trade-class}
\alias{Trade-class}
\title{An S4 class for storing trade info.}
\description{
Stores information about trade leg together with
all necessary "features" that can be attached
}
\section{Slots}{

\describe{
\item{\code{trade_id}}{"numeric",}

\item{\code{leg_start}}{"Date",}

\item{\code{leg_end}}{"NullableDate",}

\item{\code{long}}{"logical",}

\item{\code{value_usd}}{"numeric",}

\item{\code{features}}{"list",}

\item{\code{daily_data}}{"DataSet",}

\item{\code{strategy}}{"character",}

\item{\code{trader}}{"character",}

\item{\code{instrument}}{"numeric",}

\item{\code{consolidation}}{"data.frame",}

\item{\code{dly_data_pad}}{"integer",}

\item{\code{datekey}}{"character"}
}}

