#Define the standard interface for trading analysis
#features.
#Should ensure all features contain this.

# @exportClass FeatureOutput
setClassUnion("FeatureOutput",c("data.frame","NULL"))
#Features should return a frame of scalars for each trade indexed with trade date.
# @exportClass FeatureInput
setClassUnion("FeatureInput",c("data.frame","NULL"))
setClass(
  Class      = "FeatureComputation",
  representation = representation(
    input    = "FeatureInput",
    compute  = "function",
    output   = "FeatureOutput",
    output_colnms= "character"
  )
)
setGeneric("setComputationData",function(object,data){standardGeneric("setComputationData")})
setMethod("setComputationData", "FeatureComputation",
          function(object,data){
            object@output_colnms <- c('DateTime',class(object)[[1]])
            object@input <- data
            return(object)
          }
)

# @exportClass FeatureComputations
setClassUnion("FeatureComputations",c("FeatureComputation"))
setClass(
  Class      = "VirtualFeature",
  representation = representation(
    computation  = "FeatureComputations"
  )
)

setGeneric("tearDown",function(object){standardGeneric("tearDown")})
setMethod("tearDown","VirtualFeature",
          function(object){
            object@computation@input <- NULL
            return(object)
          }
)

setGeneric("updateCompute",function(object){standardGeneric("updateCompute")})
setMethod("updateCompute","VirtualFeature",
          function(object){
            #Need to have updated the FeatureComputation data first if this is relevant
            #Not implemented in the virtual function because it could adopt various forms
            message(paste("Triggering feature computation:",class(object)[[1]]))
            cmpt <- tryCatch({
                object@computation@compute(object@computation)
              }, error = function(cond){
                message(paste("Error when computing feature",class(object)[[1]],":",cond))
                if(inherits(object,"Preprocessor"))
                {
                  stop("Object is a preprocessor, halting.")
                }
            })
            if(length(cmpt)>0){
              object@computation <- cmpt
              if(length(object@computation@output_colnms)>0 && class(cmpt@output)[[1]]=="data.frame"){
                colnames(object@computation@output)<-object@computation@output_colnms
              }
            }
            else{
              object@computation@output <- NULL
            }
            return(object)
          }
)

setGeneric("getOutPut",function(object){standardGeneric("getOutPut")})
setMethod("getOutPut","VirtualFeature",
          function(object){
            return(object@computation@output)
          }
)

