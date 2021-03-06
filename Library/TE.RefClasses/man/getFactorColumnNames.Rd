% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasource_client.r
\docType{methods}
\name{getFactorColumnNames}
\alias{getFactorColumnNames}
\alias{getFactorColumnNames,VirtualDataSourceClient-method}
\title{Get factorized columns names}
\usage{
getFactorColumnNames(object)

\S4method{getFactorColumnNames}{VirtualDataSourceClient}(object)
}
\arguments{
\item{object}{object of class 'VirtualDataSourceClient'.}
}
\value{
\code{factorized_cols} character vector with list of factorized column names

\code{factorized_cols} character vector with list of factorized column names
}
\description{
Returns names of columns that are going to be factorized.
Factorization is unstacking operation where individual
factor values of factorized columns are turned into separate
set of columns spanning factor levels with logical values
indicating if given factor is present for unique set of
remaining factorization key columns
}
\section{Methods (by class)}{
\itemize{
\item \code{VirtualDataSourceClient}: Get factorized columns names

Returns names of columns that are going to be factorized.
Factorization is unstacking operation where individual
factor values of factorized columns are turned into separate
set of columns spanning factor levels with logical values
indicating if given factor is present for unique set of
remaining factorization key columns
}}

