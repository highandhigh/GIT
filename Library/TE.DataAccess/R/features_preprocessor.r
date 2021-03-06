#' @include dataset.r
#' @include common_trade_factory.r
#' @include features_virtual_aggregate_feature.r
#' @include features_preprocessor_functions.r
NULL


#' Union class PreprocessorOutput
#' union of "DataSet" and "NULL"
#'
#' @title PreprocessorOutput-class
#' @name PreprocessorOutput-class
#' @docType class
#' @exportClass PreprocessorOutput
setClassUnion("PreprocessorOutput",c("DataSet","NULL"))

#Preprocessors should return a DataSet.

#' Union class PreprocessorInput
#' union of "data.frame"
#'
#' @title PreprocessorInput-class
#' @name PreprocessorInput-class
#' @docType class
#' @exportClass PreprocessorInput

setClassUnion("PreprocessorInput",c("data.frame"))

setClass(
  Class      = "PreprocessorComputation",
  representation = representation(
    input    = "PreprocessorInput",
    compute  = "function",
    output   = "PreprocessorOutput",
    key_cols = "character",
    output_colnms= "character"
  )
)

setGeneric("setPreprocessorData",function(object,data){standardGeneric("setPreprocessorData")})
setMethod("setPreprocessorData", "PreprocessorComputation",
          function(object,data){
            object@input <- data
            return(object)
          }
)

setClass(
  Class      = "Preprocessor",
  prototype = prototype(
  	setup = setPreprocessorData
  ),
  contains = c("VirtualAggregateFeature")
)

# @exportClass FeatureComputations
setClassUnion("FeatureComputations",c("FeatureComputation","PreprocessorComputation"))

# FeatureGatherer
# Tabulates feature data

setClass(
  Class = "FeatureGathererComputation",
  prototype = prototype(
    compute = ftr_gther,
    key_cols= c('TradeID')
  ),
  contains = c("PreprocessorComputation")
)

setClass(
  Class = "FeatureGatherer",
  prototype = prototype(
    feature_mrg_on = list(TradeID="TradeID",TradeDate="DateTime"),
    gather_method  = getTradeInformation,
    feature_method = getTradeFeatures,
    computation    = new("FeatureGathererComputation")
    ),
  contains = c('Preprocessor')
)

setGeneric("gatherFeatures",function(object,warehouse,features){standardGeneric("gatherFeatures")})
setMethod("gatherFeatures","FeatureGatherer",
  function(object,warehouse,features){
      object@features <- features
      object <- gatherData(object,warehouse)
      object <- updateCompute(object)
      return(object)
    }
)

setClass(
  Class = "FeatureGathererWithSummary",
  prototype = prototype(
    gather_method  = getPositionSummary
    ),
  contains = c('FeatureGatherer')
)

setClass(
  Class = "Fractiler",
  contains = c('FeatureGatherer')
)
