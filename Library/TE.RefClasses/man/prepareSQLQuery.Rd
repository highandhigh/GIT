% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rodbc_client.r
\name{prepareSQLQuery}
\alias{prepareSQLQuery}
\title{Prepare SQL query strings}
\usage{
prepareSQLQuery(object, key_values)
}
\arguments{
\item{object}{object of class 'VirtualSQLQuery'.}

\item{key_values}{"data.frame" with query keys}
}
\value{
\code{object} object of class 'VirtualSQLQuery'.
}
\description{
Parses key_values to vector of SQL query strings
}

