#' @include portfolio_variance_decomposition.r
NULL


################################################################################
#
# MarketStyleFactorStatisticAnalysisBlock Class
#
# Computation block class to pull data required data for Market Style
# Pulls data required for computation and adds required columns.
###############################################################################


#' Analysis computing MarketStyle data and generating boxplot
#'
#' Market style is z-score of first eigenvector of factor covariance matrix.
#'
#' Computation block class to pull data required data for Market Style
#  Pulls data required for computation and adds required columns.
#'
#' Inherits from "VirtualAnalysisBlock",
#'               "VirtualRiskModelHandler",
#'               "VirtualMarketStyleDataHandler"
#'
#' @export

setClass(
  Class             = "MarketStyleFactorStatisticAnalysisBlock",
  slots             = c(
    market_style       = "MarketStyleData"
  ),
  prototype         = list(
    key_cols        = c("start", "end"),
    key_values      = data.frame(start    = as.Date(character()),
                                 end    = as.Date(character())),
    column_name_map = hash(c("start", "end"),
                           c("start", "end")),
    market_style    = new("MarketStyleData"),
    risk_model      = new("RiskModel.DevelopedEuropePrototype150.1.1")
  ),
  contains          = c("VirtualAnalysisBlock",
                        "VirtualRiskModelHandler",
                        "VirtualMarketStyleDataHandler"
  )
)

#' Set risk_model object in object slot
#'
#' Public method to set trade_data slot with "VirtualRiskModel"
#' class object
#'
#' @rdname setRiskModelObject-MarketStyleFactorStatisticAnalysisBlock-method
#' @param object object of class "MarketStyleFactorStatisticAnalysisBlock"
#' @param risk_model object of class "VirtualRiskModel"
#' @return \code{object} object of class "MarketStyleFactorStatisticAnalysisBlock"
#' @export

setMethod("setRiskModelObject",
          signature(object = "MarketStyleFactorStatisticAnalysisBlock",
                    risk_model = "VirtualRiskModel"),
          function(object, risk_model){
            object <- TE.RiskModel:::.setRiskModelObject(object, risk_model)
            return(object)
          }
)

#' Request data from data source
#'
#' @param object object of class 'MarketStyleFactorStatisticAnalysisBlock'.
#' @param key_values data.frame with keys specifying data query.
#' @return \code{object} object of class 'MarketStyleFactorStatisticAnalysisBlock'.
#' @export

setMethod("dataRequest",
          signature(object = "MarketStyleFactorStatisticAnalysisBlock", key_values = "data.frame"),
          function(object, key_values){

            object <- TE.RefClasses:::.setDataSourceQueryKeyValues(object,key_values)

            market_style <- getMarketStyleDataObject(object)

            market_style <- setRiskModelObject(market_style, getRiskModelObject(object))

            # getting marketStyle data

            query_keys <- data.frame(Date = seq(from = as.Date(min(key_values$start)),
                                                to   = as.Date(min(key_values$end)),
                                                by = 1))

            start <- query_keys$start
            end <- query_keys$to

            market_style <- tryCatch({
              dataRequest(market_style, query_keys)

            },error = function(cond){
              message(sprintf("Error when calling %s on %s class", "dataRequest()", class(market_style)))
              message(sprintf("Querried for keys: start = %s, end = %s", start, end))
              end(sprintf("Error when calling %s on %s class : \n %s", "dataRequest()", class(market_style), cond))
            })

            object <- TE.RefClasses:::.setMarketStyleDataObject(object, market_style)

            return(object)
          }
)


#' Trigger computation of analysis data.
#'
#' @param object object of class "MarketStyleFactorStatisticAnalysisBlock"
#' @return \code{object} object object of class "MarketStyleFactorStatisticAnalysisBlock"
#' @export
setMethod("Process",
          signature(object = "MarketStyleFactorStatisticAnalysisBlock"),
          function(object){

            # retrieve data
            risk_model <- getRiskModelObject(object)
            all_factors <- getRiskModelFactorNames(risk_model)
            factor_groups <- get_portfolio_decomposition_factor_groups(risk_model)

            market_style <- getMarketStyleDataObject(object)

            all_market_st <- getReferenceData(market_style)


            first <- TRUE

            # stack market data
            for(rm_date in sort(unique(all_market_st$Date))){

              rm_date <- as_date(rm_date)

              if(wday(rm_date)!=7&wday(rm_date)!=1){

                market_st <- all_market_st[all_market_st$Date==rm_date,setdiff(colnames(all_market_st),'Date')]

                plot_data <- stack(market_st, select = c(all_factors))

                colnames(plot_data) <- c("Value", "RiskType")

                plot_data <- data.frame(Date = rm_date, plot_data)

                plot_data$RiskGroup <- plot_data$RiskType
                levels(plot_data$RiskGroup) <- factor_groups
                plot_data <- data.frame(Date = rm_date, plot_data)

                if(first){
                  mrkt_plot_data <- plot_data
                  first <- FALSE
                }
                else{
                  mrkt_plot_data <- rbind(mrkt_plot_data, plot_data)

                }

              }
            }

            #order of factors
            ord_frm <- unique(mrkt_plot_data[c("RiskType", "RiskGroup")])
            ord_frm <- ord_frm[order(ord_frm$RiskGroup, ord_frm$RiskType, decreasing = TRUE),]

            mrkt_plot_data$RiskType <- factor(as.character(mrkt_plot_data$RiskType),
                                                 levels = as.character(ord_frm$RiskType))

            #Create plot
            plt_risk <- ggplot(data=mrkt_plot_data,aes_string(x="RiskType",
                                                              y="Value",
                                                              color="RiskType"
                                                              )
                               ) +
                        geom_boxplot() +
                        coord_flip() +
                        guides(color = FALSE)


            object <- .setOutputGGPlotData(object, mrkt_plot_data)
            object <- .setOutputGGPlot(object, plt_risk)

            return(object)
          }
)
