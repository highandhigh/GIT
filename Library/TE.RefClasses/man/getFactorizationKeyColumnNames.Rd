% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasource_client.r
\docType{methods}
\name{getFactorizationKeyColumnNames}
\alias{getFactorizationKeyColumnNames}
\alias{getFactorizationKeyColumnNames,VirtualDataSourceClient-method}
\title{Get factorization keys}
\usage{
getFactorizationKeyColumnNames(object)

\S4method{getFactorizationKeyColumnNames}{VirtualDataSourceClient}(object)
}
\arguments{
\item{object}{object of class 'VirtualDataSourceClient'.}
}
\value{
\code{factorization_keys} character vector with list of key columns used in factorization

\code{factorization_keys} character vector with list of key columns used in factorization
}
\description{
Returns names of columns that are going to be used as unique keys
during factorizations.
Factorization is unstacking operation where individual
factor values of factorized columns are turned into separate
set of columns spanning factor levels with logical values
indicating if given factor is present for unique set of
remaining factorization key columns
}
\section{Methods (by class)}{
\itemize{
\item \code{VirtualDataSourceClient}: Get factorization keys

Returns names of columns that are going to be used as unique keys
during factorizations.
Factorization is unstacking operation where individual
factor values of factorized columns are turned into separate
set of columns spanning factor levels with logical values
indicating if given factor is present for unique set of
remaining factorization key columns
}}

