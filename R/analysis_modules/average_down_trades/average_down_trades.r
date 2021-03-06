sourceTo("../analysis_modules/analysis_block/analysis_block.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
sourceTo("../analysis_modules/offside_positions/offside_positions.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
sourceTo("../analysis_modules/analysis_block/position_data_handler.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
sourceTo("../analysis_modules/analysis_block/trade_data_handler.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
sourceTo("../analysis_modules/analysis_block/analysis_block_functions.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)

################################################################################
#
# AverageDownTradesAnalysisBlock Class
# 
# Computation block class to pull data required for Computation of extended stock
# Pulls data required for computation and adds required columns.
###############################################################################

avg_dwn_cols <- c('InstrumentID','Date','TodayPL','PnLOutof','VolInto','SkewInto',
                  'PnLInto','DeltaPL','DeltaSwing','DeltaSkew','MarketValue','Av.MarketValue',
                  'Long','PsnLong','CumulativePL','MarketRelPL','CumulativeMarketRelPL',
                  'ValueUSD')

setClass(
  Class             = "AverageDownTradesData",
  prototype         = list(
    required_colnms = avg_dwn_cols
  ),
  contains          = c("VirtualTradeData")
)

setClass(
  Class             = "AverageDownTradesAnalysisBlock",
  slots             = c(
    position_data     = "OffsidePositionData"
  ),
  prototype         = list(
    key_cols        = c("TraderID", "start", "end"),
    key_values      = data.frame(TraderID = character(),
                              start    = as.Date(character()),
                              end    = as.Date(character())),
    column_name_map = hash(c("TraderID", "start", "end"), c("id", "start", "end")),
    required_colnms = avg_dwn_cols,
    position_data   = new("OffsidePositionData"),
    output          = new("AverageDownTradesData")
  ),
  contains          = c("VirtualAnalysisBlock",
                        "VirtualPositionDataHandler",
                        "VirtualTradeDataHandler"
                        )
)

setMethod("setPositionDataObject",  
          signature(object = "AverageDownTradesAnalysisBlock", position_data = "OffsidePositionData"),
          function(object, position_data){
            .setPositionDataObject(object, position_data)
          }
)



setMethod("dataRequest",
          signature(object = "AverageDownTradesAnalysisBlock", key_values = "data.frame"),
          function(object, key_values){
            
            object <- .setDataSourceQueryKeyValues(object,key_values)
            
            trader <- unique(key_values$TraderID)[1]
            start <- min(key_values$start)
            end <- max(key_values$end)
            
            req_key_vals <- data.frame(id = trader, start = start, end = end)
            
            # retrieve position reference data for query key_values
            position_data <- getPositionDataObject(object)
            
            if (getStoredNRows(position_data) == 0) {
              
              # using AverageDownTradesAnalysisBlock to retrieve and process input data
              offside.pos.an <- new("OffsidePositionsAnalysisBlock")
              offside.pos.an <- dataRequest(offside.pos.an, key_values)
              offside.pos.an <- Process(offside.pos.an)
              offside.pos.rd <- getOutputObject(offside.pos.an)
              object <- .setPositionDataObject(object, offside.pos.rd)
            }
            
            
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
            
            object <- .setTradeDataObject(object, trade_data)

            return(object)
          }
)



setMethod("Process",  
          signature(object = "AverageDownTradesAnalysisBlock"),
          function(object, key_values){
            
            pos_data <- getPositionDataObject(object)
            trade_data <- getTradeDataObject(object)
            
            # retrieve needed ref_data
            history_data <- getReferenceData(pos_data)
            instruments <- unique(history_data$Instrument)
            
            trade_df <- getReferenceData(trade_data)
            
            trade_df_ht <- trade_df[!is.na(trade_df$TradeID),]
            trade_df_nt <- unique(trade_df[is.na(trade_df$TradeID),])
            
            trade_df <- rbind(trade_df_ht, trade_df_nt)
            
            merge_cols <- c("Date", "InstrumentID", "StrategyID")
            hist_cols <- setdiff(colnames(history_data), colnames(trade_df))
            hist_cols <- c(merge_cols, hist_cols)
            
            # trade_df <- trade_df[!is.na(trade_df$TradeID), trade_cols]
            
            # merge price data to position data
            history_data <- merge(trade_df,history_data[hist_cols], by = merge_cols)

            object <- setReferenceData(object, history_data)
            
            # adding Date column for compatibility with legacy functions.
            
            hd <- history_data
            average_down_trades <- unique(hd[(hd$CumulativePL<0)&!is.na(hd$TradeID)&hd$Age>0,avg_dwn_cols])
            average_down_trades <- subset(average_down_trades,(average_down_trades$Long&average_down_trades$PsnLong)|(!average_down_trades$Long&!average_down_trades$PsnLong))
            
            average_down_positions <- unique(average_down_trades$InstrumentID)
            other_trades <- unique(hd[(hd$CumulativePL>0)&!is.na(hd$TradeID),avg_dwn_cols])
            
            pl_frame <- merge(hd,data.frame(InstrumentID=instruments),by=c('InstrumentID'))
            pl_frame <- unique(pl_frame[c(avg_dwn_cols)])
            pl_frame$TradeCount <- NA
            pl_frame$PsnAge <- NA
            for(ins in instruments){
              cnt <- sum(average_down_trades$InstrumentID==ins)
              pl_frame$TradeCount[pl_frame$InstrumentID==ins] <- cnt
              pl_frame$PsnAge[pl_frame$InstrumentID==ins] <- as.numeric(pl_frame$Date[pl_frame$InstrumentID==ins] - min(pl_frame$Date[pl_frame$InstrumentID==ins],na.rm=TRUE))
            }
            avg_dwn <- aggregate(pl_frame[pl_frame$PsnAge<50,c('TodayPL','MarketRelPL')],list(TradeCount=pl_frame[pl_frame$PsnAge<50,]$TradeCount),function(x){sum(x, na.rm = TRUE)})
            avg_dwn <- merge(avg_dwn,aggregate(pl_frame[pl_frame$PsnAge<50,c('InstrumentID')],list(TradeCount=pl_frame[pl_frame$PsnAge<50,]$TradeCount),function(x)length(unique(x))),by=c('TradeCount'))
            adown_plt <- rbind(data.frame(Quantity='Abs PL',TradeCount=avg_dwn$TradeCount,PL=avg_dwn$TodayPL,Ntrades=avg_dwn$x),
                               data.frame(Quantity='Rel PL',TradeCount=avg_dwn$TradeCount,PL=avg_dwn$MarketRelPL,Ntrades=avg_dwn$x))
            
            colnames(adown_plt)[colnames(adown_plt)=='Quantity'] <- 'Type'
            colnames(adown_plt)[colnames(adown_plt)=='Ntrades'] <- 'Num.Trades'
            adown_smmry <- ggplot(data=adown_plt,aes(x=TradeCount,y=PL,size=Num.Trades)) +
              ylab("Total position PL $") + 
              xlab("Total number average down trades") + 
              ggtitle('Position PL by times averaged down') +
              scale_colour_brewer(palette="Set1") +
              theme(text = element_text(size=15)) +
              geom_point(aes(colour=Type))
            
            # set processed data as an output
            
            outp_object <- getOutputObject(object)
            outp_object <- setReferenceData(outp_object, average_down_trades)
            object <- .setOutputObject(object, outp_object)
            
            
            object <- .setOutputGGPlotData(object, adown_plt)
            object <- .setOutputGGPlot(object, adown_smmry)
            
            
            return(object)
          }
)
