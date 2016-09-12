#' @include factor_variance_data.r
NULL

#########################################
#
# VirtualFactorVarianceDataHandler Class
#
#########################################

#' Virtual S4 class handling VirtualFactorVarianceData objects
#'
#' Class that is to be inherited by any objects
#' that will contain VirtualFactorVarianceData or derived classes
#'
#' @slot factor_variance object of class "VirtualFactorVarianceData"

setClass(
  Class          = "VirtualFactorVarianceDataHandler",
  slots = c(
    factor_variance = "VirtualFactorVarianceData"
  ),
  contains = c("VIRTUAL")
)


#' Get factor_variance stored in object
#'
#' Returns factor_variance object of class "VirtualFactorVarianceData"
#'
#' @param object object of class "VirtualFactorVarianceDataHandler"
#' @return \code{factor_variance} object of class "VirtualFactorVarianceData"
#' @export

setGeneric("getFactorVarianceDataObject", function(object){standardGeneric("getFactorVarianceDataObject")})

#' @describeIn getFactorVarianceDataObject
#' Get factor_variance stored in object
#'
#' Returns factor_variance object of class "VirtualFactorVarianceData"
#'
#' @inheritParams getFactorVarianceDataObject
#' @return \code{factor_variance} object of class "VirtualFactorVarianceData"
#' @export
setMethod("getFactorVarianceDataObject",
          signature(object = "VirtualFactorVarianceDataHandler"),
          function(object){
            return(object@factor_variance)
          }
)


#' Set factor_variance object in object slot
#'
#' Public method to set factor_variance slot with "VirtualFactorVarianceData"
#' class object to be implemented in derived
#  classes where we want to allow for setting data.
#'
#' @param object object of class "VirtualFactorVarianceDataHandler"
#' @param factor_variance object of class "VirtualFactorVarianceData"
#' @return \code{object} object of class "VirtualFactorVarianceDataHandler"
#' @export

setGeneric("setFactorVarianceDataObject", function(object,factor_variance){standardGeneric("setFactorVarianceDataObject")})


#' Set factor_variance object in object slot
#'
#' Private method to set factor_variance slot with "VirtualFactorVarianceData"
#'
#' @rdname private_setFactorVarianceDataObject
#' @param object object of class "VirtualFactorVarianceDataHandler"
#' @param factor_variance object of class "VirtualFactorVarianceData"
#' @return \code{object} object of class "VirtualFactorVarianceDataHandler"

setGeneric(".setFactorVarianceDataObject", function(object,factor_variance){standardGeneric(".setFactorVarianceDataObject")})

setMethod(".setFactorVarianceDataObject",
          signature(object = "VirtualFactorVarianceDataHandler", factor_variance = "VirtualFactorVarianceData"),
          function(object, factor_variance){
            object@factor_variance <- factor_variance
            return(object)
          }
)


#' Update factor_variance risk model
#'
#' Trigger update of risk model of factor_variance object
#'
#' @param object object of class "VirtualFactorVarianceDataHandler"
#' @param risk_model object of class "VirtualRiskModel"
#' @export

setGeneric("updateFactorVarianceDataRiskModel",
           function(object, risk_model){standardGeneric("updateFactorVarianceDataRiskModel")})


#' @describeIn updateFactorVarianceDataRiskModel
#' Update factor_variance risk model
#'
#' Trigger update of risk model of factor_variance object
#'
#' @inheritParams updateFactorVarianceDataRiskModel
#' @return \code{factor_variance} object of class "VirtualFactorVarianceData"
#' @export
setMethod("updateFactorVarianceDataRiskModel",
          signature(object = "VirtualFactorVarianceDataHandler",
                    risk_model = "VirtualRiskModel"),
          function(object, risk_model){
            factor_variance <- getFactorVarianceDataObject(object)
            factor_variance <- setRiskModelObject(factor_variance, risk_model)
            object <- .setFactorVarianceDataObject(object, factor_variance)
            return(object)
          }
)
