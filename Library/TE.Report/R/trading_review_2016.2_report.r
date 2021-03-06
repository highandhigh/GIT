#' @include report_analysis_block.r
NULL
################################################################################
#
# TradingReview2016.2Report Class
#
# Computation block class to generate plots required for quarterly report 2016.2
# Pulls data required for computation and outputs plots to plot list
###############################################################################


#' List of Analysis modules used by TradingReview2016.2Report Class
trading_review_2016.2_report_analysis_blocks <- c(
                                             "OffsidePositions",
                                             "OffsidePositionsBpsPerMonth",
                                             "AverageDownTradesFocus",

                                             "PositionsHoldingDayZeroPnL",
                                             "PositionsHoldingCapitalDistribution",

                                             "StrategyBreakdownAUMAndTurnover",
                                             "StrategyBreakdownTotalAndDeltaPnL",
                                             "StrategyBreakdownPnLAndTurnoverPerEvent",
                                             "PortfolioFactorExposure",

                                             "PositionRevisitsDeltaPrevQuarter"
                                             )

#' Strategy Tactics Report class.
#'
#' Report class computing following blocks:
#'  "OffsidePositions",
#'  "OffsidePositionsBpsPerMonth",
#'  "AverageDownTradesFocus",
#'  "PositionsHoldingDayZeroPnL",
#'  "PositionsHoldingCapitalDistribution",
#'  "StrategyBreakdownAUMAndTurnover",
#'  "StrategyBreakdownTotalAndDeltaPnL",
#'  "StrategyBreakdownPnLAndTurnoverPerEvent",
#'  "PortfolioFactorExposure",
#'  "PositionRevisitsDeltaPrevQuarter"
#'
#' Also generates summary plot with following subplots:
#'  "StrategyBreakdownAUMAndTurnover",
#'  "StrategyBreakdownTotalAndDeltaPnL"
#'  "OffsidePositions",
#'  "PositionsHoldingCapitalDistribution"
#'  "PositionRevisitsDeltaPrevQuarter"
#'  "StrategyBreakdownPnLAndTurnoverPerEvent",
#'  "PortfolioFactorExposure"
#'
#' Inherits from "VirtualReportAnalysisBlock"
#'
#' @export

setClass(
  Class             = "TradingReview2016.2Report",
  prototype         = list(
    key_cols        = c("TraderID", "start", "end"),
    key_values      = data.frame(TraderID = character(),
                              start    = as.Date(character()),
                              end    = as.Date(character())),
    column_name_map = hash(c("TraderID", "start", "end"), c("id", "start", "end")),
    ggplot_list        = list(),
    ggplot_data_list   = list(),
    frontend_data_list = list(),
    output_list        = list()
  ),
  contains          = c("VirtualReportAnalysisBlock"
                        )
)

#' Request data from data source
#'
#' @param object object of class 'TradingReview2016.2Report'.
#' @param key_values data.frame with keys specifying data query.
#' @return \code{object} object of class 'TradingReview2016.2Report'.
#' @export
setMethod("dataRequest",
          signature(object = "TradingReview2016.2Report", key_values = "data.frame"),
          function(object, key_values){

            object <- setDataSourceQueryKeyValues(object,key_values)

            return(object)
          }
)


#' Trigger computation of report data.
#'
#' @param object object of class "TradingReview2016.2Report"
#' @return \code{object} object object of class "TradingReview2016.2Report"
#' @export
setMethod("Process",
          signature(object = "TradingReview2016.2Report"),
          function(object){

            # retrieve query keys
            key_values <- getDataSourceQueryKeyValues(object)

            ######################################################
            #
            # OffsidePositionsAnalysisBlock xx
            #
            ######################################################

            # create/get data/process offside positions analyzer
            offside.pos.an <- new("OffsidePositionsAnalysisBlock")

            # gets position and price data
            offside.pos.an <- dataRequest(offside.pos.an, key_values)

            #process
            offside.pos.an <- Process(offside.pos.an)

            offside.pos.rd <- getOutputObject(offside.pos.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, offside.pos.an)

            ######################################################
            #
            # "OffsidePositionsBpsPerMonthAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            offside.bps.an <- new("OffsidePositionsBpsPerMonthAnalysisBlock")

            # set needed ref_data from previous analysis block
            offside.bps.an <- setPositionDataObject(offside.bps.an, offside.pos.rd)

            # process
            offside.bps.an <- Process(offside.bps.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, offside.bps.an)


            ######################################################
            #
            # "AverageDownTradesAnalysisBlock" x
            #
            ######################################################
            # create analyzer
            avg.down.trd.an <- new("AverageDownTradesAnalysisBlock")

            # set needed ref_data from previous analysis block
            avg.down.trd.an <- setPositionDataObject(avg.down.trd.an, offside.pos.rd)

            # get additional trade data
            avg.down.trd.an <- dataRequest(avg.down.trd.an, key_values)

            # store row trade data for use by other blocks
            trade.data.rd   <- getTradeDataObject(avg.down.trd.an)

            # process
            avg.down.trd.an <- Process(avg.down.trd.an)

            # retreive data for later block
            avg.down.trd.rd <- getOutputObject(avg.down.trd.an)

            # set processed result
            #object <- .copyAnalyzerOutputData(object, avg.down.trd.an)

            ######################################################
            #
            # "AverageDownTradesFocusAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            avg.down.fcs.an <- new("AverageDownTradesFocusAnalysisBlock")

            # set needed ref_data from previous analysis block
            avg.down.fcs.an <- setTradeDataObject(avg.down.fcs.an, avg.down.trd.rd)

            # process
            avg.down.fcs.an <- Process(avg.down.fcs.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, avg.down.fcs.an)


            ######################################################
            #
            # "PositionsHoldingDayZeroPnLAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            pos.hold.d0.an <- new("PositionsHoldingDayZeroPnLAnalysisBlock")

            # set data computed in previous blocks
            pos.hold.d0.an <- setPositionDataObject(pos.hold.d0.an, offside.pos.rd)
            pos.hold.d0.an <- setTradeDataObject(pos.hold.d0.an, trade.data.rd)

            # process
            pos.hold.d0.an <- Process(pos.hold.d0.an)

            # retreive data for later block
            offside.pos.rd <- getPositionDataObject(pos.hold.d0.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, pos.hold.d0.an)



            ######################################################
            #
            # "PositionsHoldingCapitalDistributionAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            pos.hold.per.an <- new("PositionsHoldingCapitalDistributionAnalysisBlock")

            # set needed ref_data from previous analysis block
            pos.hold.per.an <- setPositionDataObject(pos.hold.per.an, offside.pos.rd)

            # process
            pos.hold.per.an <- Process(pos.hold.per.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, pos.hold.per.an)

            ######################################################
            #
            # StrategyBreakdownAnalysisBlock x
            #
            ######################################################

            # create/get data/process offside positions analyzer
            strat.brdwn.an <- new("StrategyBreakdownAnalysisBlock")

            # set data computed in previous blocks
            strat.brdwn.an <- setTradeDataObject(strat.brdwn.an, trade.data.rd)

            # process
            strat.brdwn.an <- Process(strat.brdwn.an)

            strat.brdwn.rd <- getOutputObject(strat.brdwn.an)

            # set processed result
            #object <- .copyAnalyzerOutputData(object, strat.brdwn.an)

            ######################################################
            #
            # "StrategyBreakdownAUMAndTurnoverAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            sb.aum.trn.an <- new("StrategyBreakdownAUMAndTurnoverAnalysisBlock")

            sb.aum.trn.an <- setStrategyDataObject(sb.aum.trn.an, strat.brdwn.rd)
            sb.aum.trn.an <- Process(sb.aum.trn.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, sb.aum.trn.an)

            ######################################################
            #
            # "StrategyBreakdownTotalAndDeltaPnLAnalysisBlock" xx
            #
            ######################################################
            # create buys sells analyzer
            sb.pnl.dlt.an <- new("StrategyBreakdownTotalAndDeltaPnLAnalysisBlock")

            # set needed ref_data from previous analysis block
            sb.pnl.dlt.an <- setStrategyDataObject(sb.pnl.dlt.an, strat.brdwn.rd)

            # process
            sb.pnl.dlt.an <- Process(sb.pnl.dlt.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, sb.pnl.dlt.an)

            ######################################################
            #
            # "StrategyBreakdownValueTradedPerSignalAnalysisBlock" x
            #
            ######################################################
            # create analyzer
            sb.vt.ps.an <- new("StrategyBreakdownValueTradedPerSignalAnalysisBlock")

            # set needed ref_data from previous analysis block
            sb.vt.ps.an <- setTradeDataObject(sb.vt.ps.an, trade.data.rd)

            # get missing data
            sb.vt.ps.an <- dataRequest(sb.vt.ps.an, key_values)

            # process
            sb.vt.ps.an <- Process(sb.vt.ps.an)
            sb.vt.ps.rd <- getOutputObject(sb.vt.ps.an)

            # set processed result
            #object <- .copyAnalyzerOutputData(object, sb.vt.ps.an)


            ######################################################
            #
            # "StrategyBreakdownPnLAndTurnoverPerEventAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            sb.pnl.pe.an <- new("StrategyBreakdownPnLAndTurnoverPerEventAnalysisBlock")

            # set needed ref_data from previous analysis block
            sb.pnl.pe.an <- setTradeDataObject(sb.pnl.pe.an, sb.vt.ps.rd)

            # process
            sb.pnl.pe.an <- Process(sb.pnl.pe.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, sb.pnl.pe.an)


            ######################################################
            #
            # "PortfolioFactorExposureAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            prtf.fe.an <- new("PortfolioFactorExposureAnalysisBlock")


            # request Data
            prtf.fe.an <- dataRequest(prtf.fe.an, key_values)

            # process
            prtf.fe.an <- Process(prtf.fe.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, prtf.fe.an)



            ######################################################
            #
            # "PositionRevisitsDeltaPrevQuarterAnalysisBlock" xx
            #
            ######################################################
            # create analyzer
            pos.rev.pq.an <- new("PositionRevisitsDeltaPrevQuarterAnalysisBlock")

            # set needed ref_data from previous analysis block
            pos.rev.pq.an <- setTradeDataObject(pos.rev.pq.an, trade.data.rd)

            # process
            pos.rev.pq.an <- Process(pos.rev.pq.an)

            # set processed result
            object <- .copyAnalyzerOutputData(object, pos.rev.pq.an)



            ######################################################
            #
            # "Summary Grid Plot"
            #
            ######################################################

            ggplot_list <- getOutputGGPlotList(object)

            inset_plt_list <- lapply(ggplot_list[c("StrategyBreakdownAUMAndTurnover",
                                                   "StrategyBreakdownTotalAndDeltaPnL")], ggplotGrob)
            plt_list <- list()
            plt_list[[1]] <- arrangeGrob(grobs = inset_plt_list, nrow = 1)

            inset_plt_list <- lapply(ggplot_list[c("OffsidePositions",
                                                    "PositionsHoldingCapitalDistribution")], ggplotGrob)

            inset_plt_list[[1]] <- arrangeGrob(grobs = inset_plt_list, nrow = 1)
            inset_plt_list[[2]] <- ggplotGrob(ggplot_list[["PositionRevisitsDeltaPrevQuarter"]])

            plt_list[[3]] <- arrangeGrob(grobs = inset_plt_list)

            plt_list[c(2,4)] <- lapply(ggplot_list[c("StrategyBreakdownPnLAndTurnoverPerEvent",
                                                  "PortfolioFactorExposure")], ggplotGrob)

            grid_grob <- arrangeGrob(grobs = plt_list)

            ggplot_list[["Summary"]] <- grid_grob

            # set data
            object <- .setOutputGGPlotList(object, ggplot_list)


            return(object)
          }
)
