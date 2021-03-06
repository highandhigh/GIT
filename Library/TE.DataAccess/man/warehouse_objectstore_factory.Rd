% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/common_warehouse_objectstore.r
\name{warehouse_objectstore_factory}
\alias{warehouse_objectstore_factory}
\title{Create WarehouseObjectStore object}
\usage{
warehouse_objectstore_factory(name)
}
\arguments{
\item{name}{'character', name of the objectstore file}
}
\value{
\code{whstr} object of class "WarehouseObjectStore"
}
\description{
Factory function for WarehouseObjectStore objects.
Creates new WarehouseObjectStore object for given filename.
If file already exists loads file content to memory.
}

