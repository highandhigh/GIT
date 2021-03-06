#' @include analysis_block.r
NULL

################################################################################
#
# PositionRevisitsDeltaPrevQuarterAnalysisBlock Class
#
# Computation block class to pull data required for Computation of
# number of position revisits
#
###############################################################################


#' Analysis Module for computation of stock position revisits change in quarter.
#'
#' Computation block class that computes position revisits data.
#' Computes change of stock revisits vs previous quarter.
#' Gets required data and generates ggplot with PnL per position
#' revisit and relative change of revisit trades.
#'
#' Inherits from "VirtualAnalysisBlock",
#'               "VirtualTradeDataHandler"
#' @export

setClass(
  Class             = "PositionRevisitsDeltaPrevQuarterAnalysisBlock",
  prototype         = list(
    key_cols        = c("TraderID", "start", "end"),
    key_values      = data.frame(TraderID = character(),
                              start    = as.Date(character()),
                              end    = as.Date(character())),
    column_name_map = hash(c("TraderID", "start", "end"), c("id", "start", "end"))
  ),
  contains          = c("VirtualAnalysisBlock",
                        "VirtualTradeDataHandler"
                        )
)


#' Set trade_data object in object slot
#'
#' Public method to set trade_data slot with "VirtualTradeData"
#' class object
#'
#' @rdname setTradeDataObject-PositionRevisitsDeltaPrevQuarter-TradeData-method
#' @param object object of class "PositionRevisitsDeltaPrevQuarterAnalysisBlock"
#' @param trade_data object of class "VirtualTradeData"
#' @return \code{object} object of class "PositionRevisitsDeltaPrevQuarterAnalysisBlock"
#' @export

setMethod("setTradeDataObject",
          signature(object = "PositionRevisitsDeltaPrevQuarterAnalysisBlock", trade_data = "VirtualTradeData"),
          function(object, trade_data){
            TE.RefClasses:::.setTradeDataObject(object, trade_data)
          }
)


#' Request data from data source
#'
#' @rdname dataRequest-PositionRevisitsDeltaPrevQuarter-method
#' @param object object of class 'PositionRevisitsDeltaPrevQuarterAnalysisBlock'.
#' @param key_values data.frame with keys specifying data query.
#' @return \code{object} object of class 'PositionRevisitsDeltaPrevQuarterAnalysisBlock'.
#' @export

setMethod("dataRequest",
          signature(object = "PositionRevisitsDeltaPrevQuarterAnalysisBlock", key_values = "data.frame"),
          function(object, key_values){

            object <- TE.RefClasses:::.setDataSourceQueryKeyValues(object,key_values)

            trader <- unique(key_values$TraderID)[1]
            start <- min(key_values$start)
            end <- max(key_values$end)

            # retrieve price reference data for query key_values
            trade_data <- getTradeDataObject(object)

            trade_data <- tryCatch({
              req_key_vals <- key_values
              colnames(req_key_vals) <- c("id", "start", "end")

              dataRequest(trade_data, req_key_vals)

            },error = function(cond){
              message(sprintf("Error when calling %s on %s class", "dataRequest()", class(trade_data)))
              message(sprintf("Querried for keys: id = %s, start = %s, end = %s", trader, start, end))
              stop(sprintf("Error when calling %s on %s class : \n %s", "dataRequest()", class(trade_data), cond))
            })

            object <- TE.RefClasses:::.setTradeDataObject(object, trade_data)

            return(object)
          }
)


#' Trigger computation of analysis data.
#'
#' @rdname Process-PositionRevisitsDeltaPrevQuarter-method
#' @param object object of class "PositionRevisitsDeltaPrevQuarterAnalysisBlock"
#' @return \code{object} object object of class "PositionRevisitsDeltaPrevQuarterAnalysisBlock"
#' @export

setMethod("Process",
          signature(object = "PositionRevisitsDeltaPrevQuarterAnalysisBlock"),
          function(object){

            trade_data <- getTradeDataObject(object)

            # retrieve needed ref_data
            trade_df <- getReferenceData(trade_data)

            trade_df_ht <- trade_df[!is.na(trade_df$TradeID),]
            trade_df_nt <- unique(trade_df[is.na(trade_df$TradeID),])

            history_data <- rbind(trade_df_ht, trade_df_nt)

            object <- setReferenceData(object, history_data)


            this_quarter <- quarter(max(trade_df_ht$Date), with_year = TRUE)
            prev_quarter <- quarter(max(trade_df_ht$Date) %m-% months(3), with_year = TRUE)

            this_q_hd <- history_data[quarter(history_data$Date, with_year = TRUE) == this_quarter,]
            prev_q_hd <- history_data[quarter(history_data$Date, with_year = TRUE) == prev_quarter,]

            flat_data <- count_flats(prev_q_hd)
            revisit_data <- create_revisit_data(flat_data[[1]],history_data)
            revisit_plt_data  <- build_revisit_plot_data(revisit_data,flat_data[[2]],function(x)sum(x,na.rm=TRUE))

            revisit_plt_data_prev_q <- aggregate(revisit_plt_data[c('IsTrade','TodayPL')],list(TotalVisits=revisit_plt_data$TotalVisits,
                                                                                               Visit=revisit_plt_data$Visit),sum)

            flat_data <- count_flats(this_q_hd)
            revisit_data <- create_revisit_data(flat_data[[1]],history_data)
            revisit_plt_data  <- build_revisit_plot_data(revisit_data,flat_data[[2]],function(x)sum(x,na.rm=TRUE))

            revisit_plt_data_this_q <- aggregate(revisit_plt_data[c('IsTrade','TodayPL')],list(TotalVisits=revisit_plt_data$TotalVisits,
                                                                                        Visit=revisit_plt_data$Visit),sum)

            revisit_plt_data_this_q <- merge(revisit_plt_data_this_q,
                                      revisit_plt_data_prev_q,
                                      by = c("TotalVisits", "Visit"),
                                      all.x = TRUE, suffixes = c("", ".prev"),
                                      nomatch = 0)

            # fill nonmatched data with zeros
            revisit_plt_data_this_q$IsTrade.prev[is.na(revisit_plt_data_this_q$IsTrade.prev)] <- 0
            revisit_plt_data_this_q$TodayPL.prev[is.na(revisit_plt_data_this_q$TodayPL.prev)] <- 0

            revisit_plt_data <- with(revisit_plt_data_this_q,rbind(data.frame(Quantity='Number Trades',
                                                                               Value=IsTrade,
                                                                               TotalN=TotalVisits,
                                                                               VisitN=as.integer(Visit),
                                                                               Delta = as.integer(IsTrade - IsTrade.prev))))
            width <- 0.9

            revisit_smmry <- ggplot(revisit_plt_data,aes_string(x="TotalN",
                                                                group="as.factor(VisitN)",
                                                                fill="as.factor(VisitN)")) +
              geom_bar(position="dodge",aes_string(weight="Value"), width = width) +
              scale_fill_brewer(palette = "Set1", direction = -1) +
              ylab("") +
              xlab("Total visits to stock") +
              labs(fill="Increasing trades") +
              geom_text(aes_string(x= "TotalN + width *(VisitN - (TotalN+1)/2)/TotalN",
                                   y="Value",
                                   label = "Delta"),
                        size=4,
                        fontface='bold',
                        nudge_y = 20) +
              ggtitle('Revisits to stocks') +
              # theme(text = element_text(size=15)) +
              facet_grid(Quantity~.,scales="free_y")


            # set processed data as an output

            object <- .setOutputGGPlotData(object, revisit_plt_data)
            object <- .setOutputGGPlot(object, revisit_smmry)


            return(object)
          }
)
