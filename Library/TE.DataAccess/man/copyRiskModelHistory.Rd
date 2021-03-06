% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/common_daily_riskmodel_objectstore.r
\docType{methods}
\name{copyRiskModelHistory}
\alias{copyRiskModelHistory}
\alias{copyRiskModelHistory,DailyRiskModelObjectStore,DailyRiskModelObjectStore,character,Date,integer-method}
\title{Copy risk model data from one store to current object}
\usage{
copyRiskModelHistory(object, source_rmstr, name_in_source, date,
  lookback = 150L, cmp_to_update = c("ImpliedFactorReturns",
  "ResidualReturns", "Betas", "FactorCorrelation", "FactorVariance",
  "MarketStyle"), force = FALSE)


  \S4method{copyRiskModelHistory}{DailyRiskModelObjectStore,DailyRiskModelObjectStore,character,Date,integer}(object,
  source_rmstr, name_in_source, date, lookback = 150L,
  cmp_to_update = c("ImpliedFactorReturns", "ResidualReturns", "Betas",
  "FactorCorrelation", "FactorVariance", "MarketStyle"), force = FALSE)
}
\arguments{
\item{object}{object of class "DailyRiskModelObjectStore"}

\item{source_rmstr}{object of class "DailyRiskModelObjectStore" from which the data will be copied}

\item{name_in_source}{"character" name of the store from which the data will be copied}

\item{date}{"Date" latest date of data from source "DailyRiskModelObjectStore"}

\item{lookback}{"integer" number of lookback horizon of the model, default is 150L}

\item{cmp_to_update}{"character" vector of components to update, default is
c('ImpliedFactorReturns', 'ResidualReturns', 'Betas',
  'FactorCorrelation', 'FactorVariance', 'MarketStyle')}

\item{force}{"logical" if TRUE existing values will be overwritten}
}
\value{
\code{object} object object of class "DailyRiskModelObjectStore"
}
\description{
Copy risk model data from one store to current object
}
\section{Methods (by class)}{
\itemize{
\item \code{object = DailyRiskModelObjectStore,source_rmstr = DailyRiskModelObjectStore,name_in_source = character,date = Date,lookback = integer}: Copy risk model data from one store to current object
}}

