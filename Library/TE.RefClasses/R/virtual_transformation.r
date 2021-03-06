#' @include referenceobject.r transformation_functions.r
NULL


################################################
#
# Generic VirtualBaseTransformation Class
#
################################################

#' Virtual S4 class implementing basic transformation
#'
#' This is basic class defining Tranformation base
#' slots and accessors. Inherits from "VirtualReferenceObject"
#'
#' @slot computed_colnms      "character"
#' @slot is_computed          "logical"

setClass(
  Class      = "VirtualBaseTransformation",
  slots = c(
    computed_colnms = "character",
    is_computed = "logical"
  ),
  prototype = list(
    is_computed = FALSE
  ),
  contains = c("VirtualReferenceObject", "VIRTUAL")
)


#' Is computation done
#'
#' Returns logical value indicating if computation has
#' been done.
#'
#' @param object object of class 'VirtualBaseTransformation'.
#' @return \code{is_computed} logical inicating if computation is done
#' @export

setGeneric("isComputed", function(object){standardGeneric("isComputed")})

#' @describeIn isComputed
#' Is computation done
#'
#' Returns logical value indicating if computation has
#' been done.
#'
#' @inheritParams isComputed
#' @return \code{is_computed} logical inicating if computation is done
#' @export
setMethod("isComputed",
          signature(object = "VirtualBaseTransformation"),
          function(object){
            return(object@is_computed)

          }
)

#' Set value of computation status
#'
#' @param object object of class 'VirtualBaseTransformation'.
#' @param state logical value to set.
#' @return \code{object} object of class 'VirtualBaseTransformation'

setGeneric(".setIsComputed", function(object, state = FALSE){standardGeneric(".setIsComputed")})
setMethod(".setIsComputed",
          signature(object = "VirtualBaseTransformation", state = "logical"),
          function(object, state){
            object@is_computed <- state
            return(object)
          }
)


#' Get names of computed columns
#'
#' Returns Names of the variables that are generated by computation object.
#'
#' @param object object of class 'VirtualBaseTransformation'.
#' @return \code{computed_colnms} character vector of names of computed columns
#' @export

setGeneric("getComputedVariablesNames", function(object){standardGeneric("getComputedVariablesNames")})

#' @describeIn getComputedVariablesNames
#' Get names of computed columns
#'
#' Returns Names of the variables that are generated by computation object.
#'
#' @inheritParams getComputedVariablesNames
#' @return \code{computed_colnms} character vector of names of computed columns
#' @export
setMethod("getComputedVariablesNames",
          signature(object = "VirtualBaseTransformation"),
          function(object){
            return(object@computed_colnms)

          }
)

#' Get names of output columns
#'
#' Returns Names of the variables that are returned by computation object.
#'
#' @param object object of class 'VirtualBaseTransformation'.
#' @return \code{output_colnms} character vector of names of output columns
#' @export

setGeneric("getOutputVariablesNames", function(object){standardGeneric("getOutputVariablesNames")})

#' @describeIn getOutputVariablesNames
#' Get names of output columns
#'
#' Returns Names of the variables that are returned by computation object.
#'
#' @inheritParams getOutputVariablesNames
#' @return \code{output_colnms} character vector of names of output columns
#' @export
setMethod("getOutputVariablesNames",
          signature(object = "VirtualBaseTransformation"),
          function(object){
            return(unique(c(getRequiredVariablesNames(object), getComputedVariablesNames(object))))
          }
)



################################################
#
# VirtualTransformationComputation Class
#
################################################

setClassUnion("TransformationOutput",c("data.frame","NULL"))
setClassUnion("TransformationInput",c("data.frame","NULL"))

#' Virtual S4 class implementing basic transformation
#'
#' This is wrapper class wrapping computation
#' function and managing validation of variables
#' for input and output. Inherits from "VirtualBaseTransformation"
#'
#' @slot input      "character"
#' @slot output     "logical"
#' @slot compute    "function"

setClass(
  Class = "VirtualTransformationComputation",
  slots = c(
    input = "TransformationInput",
    output = "TransformationOutput",
    compute = "function"
  ),
  prototype      = list(
    compute = pass_thru_computation
  ),
  contains = c("VirtualBaseTransformation", "VIRTUAL")
)


#' Set value of computation input
#'
#' Sets internal input datastore to new data and performs data validity checks .
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @param data data to store in.
#' @return \code{object} object of class 'VirtualTransformationComputation'
#' @export

setGeneric("setInputData", function(object,data){standardGeneric("setInputData")})

#' @describeIn setInputData
#' Set value of computation input
#'
#' Sets internal input datastore to new data and performs data validity checks .
#'
#' @inheritParams setInputData
#' @return \code{object} object of class 'VirtualTransformationComputation'
#' @export
setMethod("setInputData",
          signature(object = "VirtualTransformationComputation", data = "data.frame"),
          function(object,data){
            required_colnms <- getRequiredVariablesNames(object)
            message(paste("Updating input data in ", class(object), "object."))
            if(!has_required_columns(data, required_colnms))
            {
              message(paste("Error setting data in", class(object)))
              message(paste("Columns:",paste(colnames(data),collapse=" ")))
              message(paste("Required Columns:",paste(required_colnms,collapse=" ")))
              message(paste("Missing Columns:",paste(setdiff(required_colnms, colnames(data)),collapse=" ")))
              stop("Missing required Columns")
            } else if (nrow(data) == 0) {
              message(paste("Error setting data in", class(object)))
              stop("Incoming data has zero rows.")
            }

            object@input <- unique(data)
            object <- .setIsComputed(object, FALSE)

            tryCatch ({
              validObject(object)
            }, error = function(cond){
              message(paste("Object", class(object), "became invalid after call to setInputData()", cond))
              stop("Failure when updating setting InputData")
            })
            return(object)
          }
)

#' Get value of computation input
#'
#' Returns data from internal input datastore.
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @return \code{data} data.frame data stored in input
#' @export

setGeneric("getInputData", function(object){standardGeneric("getInputData")})

#' @describeIn getInputData
#' Get value of computation input
#'
#' Returns data from internal input datastore.
#'
#' @inheritParams getInputData
#' @return \code{data} data.frame data stored in input
#' @export
setMethod("getInputData",
          signature(object = "VirtualTransformationComputation"),
          function(object){
            return(object@input)
          }
)

#' Set value of computation output
#'
#' Private method to set internal output datastore to new data
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @param data data to store in.
#' @return \code{object} object of class 'VirtualTransformationComputation'

setGeneric(".setOutputData", function(object,data){standardGeneric(".setOutputData")})
setMethod(".setOutputData",
          signature(object = "VirtualTransformationComputation", data = "data.frame"),
          function(object,data){
            required_colnms <- getOutputVariablesNames(object)
            message(paste("Updating output data in ", class(object), "object."))
            if(!has_required_columns(data, required_colnms))
            {
              message(paste("Error setting data in", class(object)))
              message(paste("Columns:",paste(colnames(data),collapse=" ")))
              message(paste("Required Columns:",paste(required_colnms,collapse=" ")))
              message(paste("Missing Columns:",paste(setdiff(required_colnms, colnames(data)),collapse=" ")))
              stop("Missing required Columns")
            } else if (nrow(data) == 0) {
              message(paste("Error setting output data in", class(object)))
              stop("Incoming data has zero rows.")
            }

            object@output <- unique(data)

            tryCatch ({
              validObject(object)
            }, error = function(cond){
              message(paste("Object", class(object), "became invalid after call to .setOutputData()", cond))
              stop("Failure when updating setting InputData")
            })
            return(object)
          }
)

#' Get value of computation output
#'
#' Returns data from internal output datastore.
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @return \code{data} data.frame data stored in output
#' @export

setGeneric("getOutputData", function(object){standardGeneric("getOutputData")})

#' @describeIn getOutputData
#' Get value of computation output
#'
#' Returns data from internal output datastore.
#'
#' @inheritParams getOutputData
#' @return \code{data} data.frame data stored in output
#' @export
setMethod("getOutputData",
          signature(object = "VirtualTransformationComputation"),
          function(object){
            return(object@output)
          }
)

#' Get code of computation function
#'
#' Returns function object used for computation
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @return \code{compute} function used for computation of specific transformation

setGeneric("getComputationFunction", function(object){standardGeneric("getComputationFunction")})
setMethod("getComputationFunction",
          signature(object = "VirtualTransformationComputation"),
          function(object){
            return(object@compute)
          }
)

#' Trigger computation
#'
#' triggers computation and copies computed data to output datastore.
#' input has to be set using setInputData(object, data) prior to triggering
#' this function otherwise will return error
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @return \code{object} object object of class 'VirtualTransformationComputation'.
#' @export

setGeneric("computeTransformation",function(object){standardGeneric("computeTransformation")})

#' @describeIn computeTransformation
#' Trigger computation
#'
#' triggers computation and copies computed data to output datastore.
#' input has to be set using setInputData(object, data) prior to triggering
#' this function otherwise will return error
#'
#' @inheritParams computeTransformation
#' @return \code{object} object object of class 'VirtualTransformationComputation'.
#' @export
setMethod("computeTransformation",
          signature(object = "VirtualTransformationComputation"),
          function(object){
            message(paste("Triggering computation:",class(object)[[1]]))
            compute <- getComputationFunction(object)
            required_colnms <- getOutputVariablesNames(object)
            input <- getInputData(object)
            output <- tryCatch({
              compute(input)
            }, error = function(cond){
              message(paste("Error when computing",class(object)[[1]],":",cond))
            })


            if(!has_required_columns(output, required_colnms)){
              message(paste("Error when computing",class(object)[[1]]))
              message(paste("Columns:",paste(colnames(output),collapse=" ")))
              message(paste("Required Columns:",paste(required_colnms,collapse=" ")))
              message(paste("Missing Columns:",paste(setdiff(required_colnms, colnames(output)),collapse=" ")))
              stop("Missing required Columns from computation result")

            } else if(nrow(output) != nrow(input)){
              message(paste("Error when computing",class(object)[[1]]))
              message(paste("Output data has different number of rows that input."))
              message(paste("Output number of rows:",paste(nrow(output),collapse=" ")))
              message(paste("Input number of rows:",paste(nrow(input),collapse=" ")))
              stop("Computation result has wrong number of rows")

            }
            else{
              object <- .setIsComputed(object, TRUE)
              object <- .setOutputData(object,output)

            }
            return(object)
          }
)


################################################
#
#  TestTransformationComputation Classes
#
# These are only for test purposes
################################################

#'class for test purposes only do not use
#' @export

setClass(
  Class = "TestTransformationComputation",
  prototype      = list(
    required_colnms = c("A", "B", "C")
  ),
  contains = c("VirtualTransformationComputation")
)

#'class for test purposes only do not use

#' @export
setClass(
  Class = "RowMeansTransformationComputation",
  prototype      = list(
    required_colnms = c("A", "B", "C"),
    compute = row_mean_computation,
    computed_colnms = "RowMean"
  ),
  contains = c("VirtualTransformationComputation")
)

#'class for test purposes only do not use
#' @export

setClass(
  Class = "InvalidRowMeansTransformationComputation",
  prototype      = list(
    required_colnms = c("A", "B", "C"),
    compute = pass_thru_computation,
    computed_colnms = "RowMean"
  ),
  contains = c("VirtualTransformationComputation")
)


################################################
#
# Generic VirtualTransformation Class
#
################################################

#' Virtual S4 class implementing transformations
#'
#' This is adaptation class wrapping computation
#' class  and preparing computation input and
#' output for calling entity. Inherits
#' from "VirtualBaseTransformation"
#'
#' @slot computation  "VirtualTransformationComputation"

setClass(
  Class      = "VirtualTransformation",
  slots = c(
    computation  = "VirtualTransformationComputation"
  ),
  contains = c("VirtualBaseTransformation", "VIRTUAL")
)

#' Get computation object
#'
#' Returns computation object encapsulated in Transformation .
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @return \code{compute} function used for computation of specific transformation
#' @export

setGeneric("getComputation",function(object){standardGeneric("getComputation")})

#' @describeIn getComputation
#' Get computation object
#'
#' Returns computation object encapsulated in Transformation .
#'
#' @inheritParams getComputation
#' @return \code{compute} function used for computation of specific transformation
#' @export
setMethod("getComputation",
          signature(object = "VirtualTransformation"),
          function(object){
            return(object@computation)
          }
)


#' Set computation object
#'
#' Private method to set computation object encapsulated in Transformation .
#'
#' @param object object of class 'VirtualTransformationComputation'.
#' @param computation object of type VirtualTransformationComputation
#' @return \code{compute} function used for computation of specific transformation

setGeneric(".setComputation",function(object, computation){standardGeneric(".setComputation")})
setMethod(".setComputation",
          signature(object = "VirtualTransformation",
                    computation = "VirtualTransformationComputation"),
          function(object, computation){
            object@computation <- computation
            return(object)
          }
)

#' Set computation object
#'
#' sets computation object encapsulated in Transformation.
#' Handles all checks and settings.
#'
#' @param object object of class 'VirtualTransformation'.
#' @param computation object of type VirtualTransformationComputation
#' @return \code{object} object of class 'VirtualTransformation'
#' @export

setGeneric("setComputation",function(object, computation){standardGeneric("setComputation")})

#' @describeIn setComputation
#' Set computation object
#'
#' sets computation object encapsulated in Transformation.
#' Handles all checks and settings.
#'
#' @inheritParams setComputation
#' @return \code{object} object of class 'VirtualTransformation'
#' @export
setMethod("setComputation",
          signature(object = "VirtualTransformation", computation = "VirtualTransformationComputation"),
          function(object, computation){
            if(!is(computation, "VirtualTransformationComputation")){
              message(paste("Error when setting computation for",class(object)[[1]]))
              message(paste("Computation has to extend VirtualTransformationComputation class."))
              message(paste("Class of argument extends",extends(class(computation)[[1]])))
              stop("Incorrect class of computation object passed to setComputation(...)")

            }

            # testing for required required variables
            req_comp_vars <- getRequiredVariablesNames(computation)
            req_trans_vars <- getRequiredVariablesNames(object)
            have_req_vars <- all(req_trans_vars %in% req_comp_vars)

            if(!have_req_vars){
              message(paste("Error when setting computation for transformation ",class(object)[[1]]))
              message(paste("Computation", class(computation)[[1]], "does not support all required Variables for transformation."))
              message(paste("Required transformation Variables :",req_trans_vars))
              message(paste("Variables supported by Computation :",req_comp_vars))
              stop("Computation has different set of required variable space than guaranteed/required by transformation.")

            }

            # testing for required output variables
            req_comp_vars <- getComputedVariablesNames(computation)
            req_trans_vars <- getComputedVariablesNames(object)
            have_req_vars <- all(req_trans_vars %in% req_comp_vars)

            if(!have_req_vars){
              message(paste("Error when setting computation for transformation ",class(object)[[1]]))
              message(paste("Computation", class(computation)[[1]], "does not support all required output Variables for transformation."))
              message(paste("Required transformation Variables :",req_trans_vars))
              message(paste("Variables supported by Computation :",req_comp_vars))
              stop("Computation has different set of required output variables than guaranteed/required by transformation.")

            }

            # copying input data and storing new computation
            input <- getComputationInput(object)
            if (!is.null(input)){
              computation <- setInputData(computation, input)
            }

            object <- .setComputation(object, computation)

            tryCatch ({
              validObject(object)
            }, error = function(cond){
              message(paste("Object", class(object), "became invalid after call to setComputation()", cond))
              stop("Failure when updating setting Computation")
            })

            object <- .setIsComputed(object,FALSE)

            return(object)
          }
)

#' Get value of computation input
#'
#' Returns internal input datastore of computation object .
#'
#' @param object object of class 'VirtualTransformation'.
#' @return \code{data} data.frame with transformation computation input
#' @export

setGeneric("getComputationInput", function(object){standardGeneric("getComputationInput")})

#' @describeIn getComputationInput
#' Get value of computation input
#'
#' Returns internal input datastore of computation object .
#'
#' @inheritParams getComputationInput
#' @return \code{data} data.frame with transformation computation input
#' @export
setMethod("getComputationInput",
          signature(object = "VirtualTransformation"),
          function(object){
            return(getInputData(getComputation(object)))
          }
)


#' Set value of computation input
#'
#' Sets internal input datastore to new data and performs data validity checks .
#'
#' @param object object of class 'VirtualTransformation'.
#' @param data object of class 'VirtualReferenceData'.
#' @return \code{object} object of class 'VirtualTransformation'
#' @export

setGeneric("setComputationInput", function(object,data){standardGeneric("setComputationInput")})


#' Set value of computation input
#'
#' Sets internal input datastore to new data and performs data validity checks .
#'
#' @param object object of class 'VirtualTransformation'.
#' @param data object of class 'data.frame'.
#' @return \code{object} object of class 'VirtualTransformation'
#' @export
setMethod("setComputationInput",
          signature(object = "VirtualTransformation", data = "data.frame"),
          function(object,data){
            required_colnms <- getRequiredVariablesNames(object)
            message(paste("Updating", class(object), "object."))

            if(!has_required_columns(data, required_colnms))
            {
              message(paste("Error setting computation data in", class(object)))
              message(paste("Columns:",paste(colnames(data),collapse=" ")))
              message(paste("Required Columns:",paste(required_colnms,collapse=" ")))
              message(paste("Missing Columns:",paste(setdiff(required_colnms, colnames(data)),collapse=" ")))
              stop("Missing required Columns")
            }  else if (nrow(data) == 0) {
              message(paste("Error setting data in", class(object)))
              stop("Incoming data has zero rows in setComputationInput().")
            }

            comp <- getComputation(object)
            comp <- setInputData(comp, data)
            object <- .setComputation(object, comp)
            object <- .setIsComputed(object,FALSE)

            tryCatch ({
              validObject(object)
            }, error = function(cond){
              message(paste("Object", class(object), "became invalid after call to setComputationInput()", cond))
              stop("Failure when updating setting ComputationInput")
            })

            return(object)
          }
)

#' @describeIn setComputationInput
#' Set value of computation input
#'
#' Sets internal input datastore to new data and performs data validity checks .
#'
#' @inheritParams setComputationInput
#' @return \code{object} object of class 'VirtualTransformation'
#' @export
setMethod("setComputationInput",
          signature(object = "VirtualTransformation", data = "VirtualReferenceData"),
          function(object,data){
            required_colnms <- getRequiredVariablesNames(object)
            message(paste("Updating", class(object), "object."))

            data <- getReferenceData(data)

            object <- setComputationInput(object, data)

            return(object)
          }
)


#' Trigger transformation Computation
#'
#' Sets internal input datastore to new data and performs data validity checks .
#'
#' @param object object of class 'VirtualTransformation'.
#' @param force logical value indicating if new computation has to be forced if it has been
#' computed before.
#' @return \code{object} object of class 'VirtualTransformation'
#' @export

setGeneric("triggerComputation",function(object, force = FALSE){standardGeneric("triggerComputation")})

#' @describeIn triggerComputation
#' Trigger transformation Computation
#'
#' Sets internal input datastore to new data and performs data validity checks .
#'
#' @inheritParams triggerComputation
#' @return \code{object} object of class 'VirtualTransformation'
#' @export
setMethod("triggerComputation",
          signature(object = "VirtualTransformation"),
          function(object, force = FALSE ){
            #Need to have updated the TransormationComputation data first if this is relevant
            #Not implemented in the virtual function because it could adopt various forms
            if (isComputed(object) && force == FALSE) {
              message(paste("Computation already done for :",class(object)[[1]]))
              message(paste("Skipping ... "))
              message(paste("Please set triggerComputation(obje, force = TRUE) to force recalculation "))
              return(object)
            }

            message(paste("Triggering Transformation computation:",class(object)[[1]]))
            cmpt <- tryCatch({
              comp <- getComputation(object)
              comp <- computeTransformation(comp)
            }, error = function(cond){
              message(paste("Error when computing Transformation",class(object)[[1]],":",cond))
              stop("Failure when running computeTransformation(comp) in triggerComputation().")

            })
            if(isComputed(comp)){
              object <- .setComputation(object,comp)
              object <- .setIsComputed(object, TRUE)
            }
            else{
              message(paste("Error when computing Transformation",class(object)[[1]]))
              message(paste("Computation",class(comp)[[1]], "Did not produce any result."))
              stop("Computation did not produce any result in triggerComputation().")
            }
            return(object)
          }
)

#' Get value of computation output
#'
#' Returns internal output datastore of computation object .
#'
#' @param object object of class 'VirtualTransformation'.
#' @return \code{data} data.frame with transformation computation output
#' @export

setGeneric("getComputationOutput",function(object){standardGeneric("getComputationOutput")})

#' @describeIn getComputationOutput
#' Get value of computation output
#'
#' Returns internal output datastore of computation object .
#'
#' @inheritParams getComputationOutput
#' @return \code{data} data.frame with transformation computation output
#' @export
setMethod("getComputationOutput",
          signature(object = "VirtualTransformation"),
          function(object){
            if (!isComputed(object)) {
              message(paste("Error when calling getComputationOutput on",class(object)[[1]]))
              message(paste("Computation hasn't been triggered use triggerComputation() before requesting Output."))
              stop("Computation hasn't been triggered.).")

            } else {
              return(getOutputData(getComputation(object)))
            }
          }
)


################################################
#
#  TestTransformation Classes
#
# These are only for test purposes
################################################

#'class for test purposes only do not use
#'@export

setClass(
  Class = "TestTransformation",
  prototype      = list(
    required_colnms = c("A", "B", "C"),
    computation = new("TestTransformationComputation")
  ),
  contains = c("VirtualTransformation")
)

#'class for test purposes only do not use
#'@export

setClass(
  Class = "RowMeansTransformation",
  prototype      = list(
    required_colnms = c("A", "B", "C"),
    computed_colnms = c("RowMean"),
        computation = new("RowMeansTransformationComputation")
  ),
  contains = c("VirtualTransformation")
)

#'class for test purposes only do not use
#'@export

setClass(
  Class = "InvalidRowMeansTransformation",
  prototype      = list(
    required_colnms = c("A", "B", "C"),
    computed_colnms = c("RowMean"),
    computation = new("InvalidRowMeansTransformationComputation")
  ),
  contains = c("VirtualTransformation")
)
