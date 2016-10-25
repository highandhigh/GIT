#' @include rodbc_client_functions.r
#' @include risk_model_objectstore_client.r
NULL


####################################################
#
# RefClasses.RiskModel.VirtualSQLProcedureCall Class
#
####################################################

#' Virtual S4 class handling sql procedures calls to RiskModel DB.
#'
#' Implements handling of access to data via sql stored procedures calls.
#' Inherits from "VirtualSQLProcedureCall"
#'
#' @export
setClass(
  Class     = "RiskModel.VirtualSQLProcedureCall",
  prototype = list(
    db_name        = RISK_MODEL_DB(),
    db_schema      = "Research",
    key_cols       = c("RiskModelName", "Date"),
    key_values     = data.frame(RiskModelName = character(),
                                Date = as.Date(character())),
    query_parser   = parse_riskmodel_date_keys,
    results_parser = TE.SQLQuery:::convert_column_class,
    arguments    = c("@sRiskModelName", "@dtDateFrom", "@dtDateTo")
  ),
  contains  = c("VirtualSQLProcedureCall", "VIRTUAL")
)

setClass(
  Class     = "RiskModel.SQLProcedureCall.MultiFactorRisk_FactorCorrelationByModelNameDate",
  prototype = list(
    procedure    = "prMultiFactorRisk_FactorCorrelationByModelNameDate"
  ),
  contains  = c("RiskModel.VirtualSQLProcedureCall")
)

setClass(
  Class     = "RiskModel.SQLProcedureCall.MultiFactorRisk_FactorCovarianceByModelNameDate",
  prototype = list(
    procedure    = "prMultiFactorRisk_FactorCovarianceByModelNameDate"
  ),
  contains  = c("RiskModel.VirtualSQLProcedureCall")
)

setClass(
  Class     = "RiskModel.SQLProcedureCall.MultiFactorRisk_FactorVarianceByModelNameDate",
  prototype = list(
    procedure    = "prMultiFactorRisk_FactorVarianceByModelNameDate"
  ),
  contains  = c("RiskModel.VirtualSQLProcedureCall")
)

setClass(
  Class     = "RiskModel.SQLProcedureCall.MultiFactorRisk_MarketStyleByModelNameDate",
  prototype = list(
    procedure    = "prMultiFactorRisk_MarketStyleByModelNameDate"
  ),
  contains  = c("RiskModel.VirtualSQLProcedureCall")
)

setClass(
  Class     = "RiskModel.SQLProcedureCall.MultiFactorRisk_ImpliedFactorReturnsByModelNameDate",
  prototype = list(
    procedure    = "prMultiFactorRisk_ImpliedFactorReturnsByModelNameDate"
  ),
  contains  = c("RiskModel.VirtualSQLProcedureCall")
)


setClass(
  Class     = "RiskModel.SQLProcedureCall.MultiFactorRisk_InstrumentBetasByInstrumentIDModelNameDate",
  prototype = list(
    db_name        = RISK_MODEL_DB(),
    db_schema      = "Research",
    key_cols       = c("RiskModelName", "InstrumentID", "Date"),
    key_values     = data.frame(RiskModelName = character(),
                                InstrumentIDs = integer(),
                                Date = as.Date(character())),
    query_parser   = parse_riskmodel_instrument_date_keys,
    results_parser = TE.SQLQuery:::convert_column_class,
    arguments    = c("@sRiskModelName", "@sInstrumentIds", "@dtDateFrom", "@dtDateTo"),
    procedure    = "prMultiFactorRisk_InstrumentBetasByInstrumentIDModelNameDate"
  ),
  contains  = c("RiskModel.VirtualSQLProcedureCall")
)

setClass(
  Class     = "RiskModel.SQLProcedureCall.MultiFactorRisk_ResidualReturnsByInstrumentIDModelNameDate",
  prototype = list(
    db_name        = RISK_MODEL_DB(),
    db_schema      = "Research",
    key_cols       = c("RiskModelName", "InstrumentID", "Date"),
    key_values     = data.frame(RiskModelName = character(),
                                InstrumentIDs = integer(),
                                Date = as.Date(character())),
    query_parser   = parse_riskmodel_instrument_date_keys,
    results_parser = TE.SQLQuery:::convert_column_class,
    arguments    = c("@sRiskModelName", "@sInstrumentIds", "@dtDateFrom", "@dtDateTo"),
    procedure    = "prMultiFactorRisk_ResidualReturnsByInstrumentIDModelNameDate"
  ),
  contains  = c("RiskModel.VirtualSQLProcedureCall")
)

#########################################
#
# VirtualRiskModelRODBCClient Class
#
#########################################

#' list of key column names for RODBC riskmodel client
risk_model_rodbc_keys <-  c("dtDate")

devtools::use_data(risk_model_rodbc_keys,
                   overwrite = TRUE)


#' Virtual S4 class for access to Risk Model Objectstore.
#'
#' This is handler class that is to be inherited
#' by other classes handling Risk Model Objects
#'
#' Inherits from "VirtualDataSourceClient" and "VirtualRiskModelHandler"
#'
#' @slot component    "character", name of the component of risk model

setClass(
  Class                = "VirtualRiskModelRODBCClient",
  slots = c(
    component          = "character", # name of component in Risk Model
    sql_query          = "RiskModel.VirtualSQLProcedureCall"
    ),
  prototype = list(
    key_cols        = risk_model_objectstore_keys,
    key_values      = data.frame(Date = as.Date(character())),
    column_name_map = hash("dtDateTime"    = "Date",
                           "dtDate"        = "Date",
                           "lInstrumentID" = "InstrumentID",
                           "sFactorName"   = "FactorName",
                           "Instrument"    = "InstrumentID")
  ),
  contains = c("VirtualRiskModelDataSourceClient","VirtualRODBCClient", "VIRTUAL")
)


#' get specific SQL query for given risk component name
#'
#' @param object object of class 'VirtualDataSourceClient'.
#' @return \code{sql_query} object of class "RiskModel.VirtualSQLProcedureCall"
setGeneric(".getSQLQueryObjectForRiskComponent",
           function(object){standardGeneric(".getSQLQueryObjectForRiskComponent")})

setMethod(".getSQLQueryObjectForRiskComponent",
          signature(object = "VirtualRiskModelRODBCClient"),
          function(object){


            component <- getRiskModelComponentName(object)

            component_map <- hash("FactorCorrelation"    = "RiskModel.SQLProcedureCall.MultiFactorRisk_FactorCorrelationByModelNameDate",
                                  "FactorCovariance"     = "RiskModel.SQLProcedureCall.MultiFactorRisk_FactorCovarianceByModelNameDate",
                                  "FactorVariance"       = "RiskModel.SQLProcedureCall.MultiFactorRisk_FactorVarianceByModelNameDate",
                                  "MarketStyle"          = "RiskModel.SQLProcedureCall.MultiFactorRisk_MarketStyleByModelNameDate",
                                  "ImpliedFactorReturns" = "RiskModel.SQLProcedureCall.MultiFactorRisk_ImpliedFactorReturnsByModelNameDate",
                                  "Betas"                = "RiskModel.SQLProcedureCall.MultiFactorRisk_InstrumentBetasByInstrumentIDModelNameDate",
                                  "ResidualReturns"      = "RiskModel.SQLProcedureCall.MultiFactorRisk_ResidualReturnsByInstrumentIDModelNameDate"
                                  )
            if (component %in% names(component_map)){
              sql_query <- new(component_map[[component]])
            } else {
              stop(sprintf("Unknown risk model component name %s",
                           component))
            }


            return(sql_query)
          }
)



#' initialize method for "VirtualRiskModelRODBCClient" derived classes
#'
#' initializes required column names from the values obtained from contained risk model
#'
#' @param .Object object of class derived from "VirtualRiskModelRODBCClient"
#' @export

setMethod("initialize",
          "VirtualRiskModelRODBCClient",
          function(.Object){

            .Object <- callNextMethod()

            component <- getRiskModelComponentName(.Object)

            sql_query <- tryCatch({
              .getSQLQueryObjectForRiskComponent(.Object)
            }, error = function(cond){
              message(sprintf("Could not obtain sql_object for class %s and component name %s in initialize()",
                              class(.Object),
                              component))
              stop(cond)
            })

            if (is.null(sql_query) || !is(sql_query, "RiskModel.VirtualSQLProcedureCall")){
              stop(sprintf("Invalid class %s of sql_query returned for component name %s in initialize(%s)",
                           class(sql_query),
                           component,
                           class(.Object)))
            }


            .Object <- TE.SQLQuery:::.setSQLQueryObject(.Object, sql_query)

            return(.Object)
          }
)


#' Request data from data source
#'
#' Generic method to request data from data source.
#' Needs to be implemented in derived classes to work
#'
#' @param object object of class 'VirtualRiskModelRODBCClient'.
#' @param key_values data.frame with keys specifying data query.
#' @return \code{object} object of class 'VirtualRiskModelRODBCClient'.
#' @export
setMethod("dataRequest",
          signature(object = "VirtualRiskModelRODBCClient", key_values = "data.frame"),
          function(object, key_values){


            rm_name <- getRiskModelName(object)

            if (0 == nrow(key_values)){
              key_values <- cbind(data.frame(RiskModelName = character()),
                                  key_values)
            } else {
              key_values <- cbind(data.frame(RiskModelName = rm_name),
                                  key_values)
            }

            object <- callNextMethod(object, key_values)

            return(object)
          }
)



#########################################
#
# VirtualRiskModelClientPicker Class
#
#########################################


#' Virtual S4 class for access to Risk Model Objectstore.
#'
#' This is a class serving as a switcher between RODBC and Objectstore
#' Source of data for risk model
#'
#' Inherits from "VirtualDataSourceClient" and "VirtualRiskModelHandler"
#'
#' @slot component    "character", name of the component of risk model
setClass(
  Class                = "VirtualRiskModelClientPicker",
  contains = c("VirtualRiskModelRODBCClient", "VIRTUAL")
)
