% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/warehouse_client.r
\docType{methods}
\name{dataRequest,VirtualWarehouseClient,data.frame-method}
\alias{dataRequest,VirtualWarehouseClient,data.frame-method}
\title{Request data from data source}
\usage{
\S4method{dataRequest}{VirtualWarehouseClient,data.frame}(object, key_values)
}
\arguments{
\item{object}{object of class 'VirtualWarehouseClient'.}

\item{key_values}{data.frame with keys specifying data query.}
}
\value{
\code{object} object of class 'VirtualWarehouseClient'.
}
\description{
Generic method to request data from data source.
Needs to be implemented in derived classes to work
}

