% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/report_analysis_block.r
\name{.checkSlotClass}
\alias{.checkSlotClass}
\title{check if slot class is as required}
\usage{
.checkSlotClass(object, slot, class, req_class)
}
\arguments{
\item{object}{object of class "VirtualReportAnalysisBlock"}

\item{slot}{"character" slot name which class is beeing checked}

\item{class}{"character" class name of the slot}

\item{req_class}{"character" vector of allowed slot classes}
}
\value{
\code{object} object of class "VirtualReportAnalysisBlock"
}
\description{
Private method to check if given value has correct class for the slot
}

