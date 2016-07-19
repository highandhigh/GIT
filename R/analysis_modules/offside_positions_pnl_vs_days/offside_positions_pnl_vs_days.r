sourceTo("../analysis_modules/analysis_block/analysis_block.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
sourceTo("../analysis_modules/offside_positions_gain_vs_days/offside_positions_gain_vs_days.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
sourceTo("../analysis_modules/analysis_block/position_data_handler.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)

################################################################################
#
# OffsidePositionsPnLVsDaysAnalysisBlock Class
# 
# Computation block class to pull data required for Computation of extended stock
# Pulls data required for computation and adds required columns.
###############################################################################

setClass(
  Class             = "OffsidePositionGainAndCategoryData",
  prototype         = list(
    required_colnms = c( "InstrumentID",          "CumulativePL",          "CumulativeMarketRelPL", "TodayPL" ,             
                         "MarketRelPL",           "OffsideCnt",            "RelOffsideCnt",         "MarketValue",          
                         "Offside",               "OffsideRel",            "Gain",                  "RelGain", 
                         "OffCat")
  ),
  contains          = c("OffsidePositionGainData")
)

setClass(
  Class             = "OffsidePositionsPnLVsDaysAnalysisBlock",
  slots             = c(
    position_data   = "OffsidePositionGainData"
  ),
  prototype         = list(
    required_colnms = c( "InstrumentID",          "CumulativePL",          "CumulativeMarketRelPL", "TodayPL" ,             
                         "MarketRelPL",           "OffsideCnt",            "RelOffsideCnt",         "MarketValue",          
                         "Offside",               "OffsideRel",            "Gain",                  "RelGain"),
    position_data   = new("OffsidePositionGainData"), 
    output          = new("OffsidePositionGainAndCategoryData")
  ),
  contains          = c("VirtualAnalysisBlock",
                        "VirtualPositionDataHandler"
                        )
)

setMethod("setPositionDataObject",  
          signature(object = "OffsidePositionsPnLVsDaysAnalysisBlock", position_data = "OffsidePositionGainData"),
          function(object, position_data){
            .setPositionDataObject(object, position_data)
          }
)


setMethod("Process",  
          signature(object = "OffsidePositionsPnLVsDaysAnalysisBlock"),
          function(object, key_values){
            
            pos_data <- getPositionDataObject(object)
            
            # retrieve needed ref_data
            rank_offside <- getReferenceData(pos_data)
            

            rank_offside$OffCat <- "NA"
            rank_offside$OffCat[rank_offside$OffsideCnt<10] <- "< 10d"
            rank_offside$OffCat[rank_offside$OffsideCnt>9&rank_offside$OffsideCnt<20] <- "10 - 20d"
            rank_offside$OffCat[rank_offside$OffsideCnt>19&rank_offside$OffsideCnt<30] <- "20 - 30d"
            rank_offside$OffCat[rank_offside$OffsideCnt>29&rank_offside$OffsideCnt<40] <- "30 - 40d"
            rank_offside$OffCat[rank_offside$OffsideCnt>39&rank_offside$OffsideCnt<50] <- "40 - 50d"
            pl_by_offside <- aggregate(rank_offside[c('TodayPL','MarketRelPL')],list(DaysOff=rank_offside$OffCat),sum)
            pl_bucket_plt <- rbind(cbind(Type='Abs. offside',data.frame(Days=pl_by_offside$DaysOff,PL=pl_by_offside$TodayPL)),
                                   cbind(Type='Rel. offside',data.frame(Days=pl_by_offside$DaysOff,PL=pl_by_offside$MarketRelPL)))
            
            bucket_off_pl <- ggplot(data=pl_bucket_plt,aes(x=Days,fill=Type)) +
              geom_bar(aes(weight=PL),position="dodge") +
              ylab("Total PL $") + 
              xlab("Total days position offside") + 
              labs(fill="") +
              theme(legend.position = "bottom") +
              scale_fill_brewer(palette="Set1") +
              theme(text = element_text(size=15)) +
              ggtitle('Position PL by total days offside') 
            
            # set processed data as an output
            object <- setReferenceData(object, rank_offside)
            
            outp_object <- getOutputObject(object)
            outp_object <- setReferenceData(outp_object, rank_offside)
            object <- .setOutputObject(object, outp_object)
            
            
            object <- .setOutputGGPlotData(object, pl_bucket_plt)
            object <- .setOutputGGPlot(object, bucket_off_pl)
            
            
            return(object)
          }
)
