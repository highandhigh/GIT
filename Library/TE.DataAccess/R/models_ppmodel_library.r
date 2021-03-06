#' @include features_preprocessor_library.r
#' @include models_ppmodel.r
NULL

#' List of outcome price features
outcome_price_features <- c("PnLOutof","PsnReturnOut","PsnReturnOutFull", "Hit1D", 'PtvePnLOutof')

#' List of context price features
context_price_features <- c("PnLInto", "CompoundReturnInto","CompoundReturnOutof","PsnReturnIn","VolInto","VolOutof","SkewInto","SkewOutof","ClosePrice","PriorClosePrice","PtvePnLInto","PriceMavg","MidOnEntry","Offside","RSI14","PriorRSI14","LegOpenClose","RelativeRSI14","SectorRelativeRSI14","DailyN","MavgPrice50")

#' List of outcome volume features
context_volume_features<- c("AvgDailyValTraded5Day")

#' List of control price features
control_price_features <- c("ProfitTarget","StopLoss","MarketValue")

#' List of control features
control_features       <- c("ActivityIntoTrade","ActivityOutofTrade")

#' List of context meta features
context_meta           <- c("InputDirection")

#' List context results day features
context_resultsday_features        <- c("DaysToNextResults","DaysSinceLastResults","EPSRevision")

#' List of primary placing features
context_primary_placing_features   <- c("DaysToPrimaryPlacing","DaysSincePrimaryPlacing")

#' List of outcome price features
context_secondary_placing_features <- c("DaysToSecondaryPlacing","DaysSinceSecondaryPlacing")

#' List of position age features
context_position_age_features      <- c("Age","NewPosition","ClosePosition")


devtools::use_data(outcome_price_features,
                   context_price_features,
                   context_volume_features,
                   control_price_features,
                   control_features,
                   context_meta,
                   context_resultsday_features,
                   context_primary_placing_features,
                   context_position_age_features,
                   overwrite = TRUE)

offside <- function(mv,iv,long){
  if(is.na(mv)||is.na(iv)||is.na(long)){
    rval <- NA
  }
  else{
    if(long){
      rval <- mv<iv
    }
    else{
      rval <- mv>iv
    }
  }
  return(rval)
}

is_psn_offside <- function(data){
  ##This could be strange if position market value swaps signs, but this should
  ##not be possible witin the same strategy.
  return(unlist(Map(offside,data$MarketValue,data$InitialValue,data$PsnLong)))
}

compute_position_offside <- function(ppmodel_computation_object){
      data <- ppmodel_computation_object@ppdata@data
      data$PsnOffside <- is_psn_offside(data)
      ppmodel_computation_object@output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,data)
      return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelOffsidePostComputation",
      prototype = prototype(
            compute = compute_position_offside
      ),
      contains = c("PPModelPostComputation")
)

#' PPModel derived class ResultsDayBatchGatherer
#'
#' @title ResultsDayBatchGatherer
#' @name ResultsDayBatchGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass ResultsDayBatchGatherer

ppmodel_class_factory("ResultsDayBatchGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features,context_resultsday_features),"PPModelSetupPassThruComputation","PPModelOffsidePostComputation")

#Extract position data on the day of numbers to determine what happened to untraded
#positions on the day of results.
psn_data_by_feature_slice <- function(ppmodel_computation_object,feature,slice_fn){
      psn <- getRawPositionData(ppmodel_computation_object@wh)
      psn <- psn@data
      ppdata <- subset(ppmodel_computation_object@ppdata@data,slice_fn(ppmodel_computation_object@ppdata@data[feature]))
      if(nrow(ppdata)==0){
            output <- ppmodel_computation_object@ppdata@data
            output$PsnTraded <- NA
            output$PsnHit <- NA
            output$PsnOffside <- NA
            output$Tag <- NA
            output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
      }
      else{
            colnames(psn)[colnames(psn)=='Date'] <- 'TradeDate'
            colnames(psn)[colnames(psn)=='InstrumentID'] <- 'Instrument'
            psn <- psn[c('TradeDate','Instrument','StrategyID','MarketValue','TodayPL')]
            ppdata <- ppdata[c('TradeDate','Instrument','StrategyID','TradeID','PtvePnLInto','PsnLong','InitialValue')]
            output <- merge(psn,ppdata,by=c('TradeDate','Instrument','StrategyID'),all.x=TRUE)
            output$PsnTraded <- !is.na(output$TradeID)
            output$PsnHit <- output$TodayPL > 0
            output$PsnOffside <- is_psn_offside(output)
            output$Tag <- as.character(output$PsnHit)
            output$Tag[output$Tag=='TRUE'] <- 'Hit'
            output$Tag[output$Tag=='FALSE'] <- 'Miss'
            output$Indicator <- 1
            output <- output[c('TradeDate','Instrument','StrategyID','PsnTraded','TodayPL','PsnHit','Tag','PsnOffside','Indicator')]
            output <- unique(merge(ppmodel_computation_object@ppdata@data,output,by=c('TradeDate','Instrument','StrategyID'),all.x=TRUE))
            output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
      }
      ppmodel_computation_object@output <- output
      return(ppmodel_computation_object)
}
psn_data_day_of_numbers <- function(ppmodel_computation){
      return(psn_data_by_feature_slice(ppmodel_computation,'DaysSinceLastResults',function(x)x==0))
}

setClass(
      Class = "PPModelPsnOnResultsComputation",
      prototype = prototype(
            compute = psn_data_day_of_numbers
      ),
      contains = c("PPModelPostComputation")
)

#' PPModel derived class ResultsDayPsnGatherer
#'
#' @title ResultsDayPsnGatherer
#' @name ResultsDayPsnGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass ResultsDayPsnGatherer

ppmodel_class_factory("ResultsDayPsnGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features,context_resultsday_features),"PPModelSetupPassThruComputation","PPModelPsnOnResultsComputation")

#Position size adjustments

context_size_adjustment_features <- c("NewPosition")

tagger <- function(psnup){
  if(!is.na(psnup)){
    if(psnup==TRUE){
      rval <- 'Hit'
    }
    else{
      rval <- 'Miss'
    }
  }
  else{
    rval <- NA
  }
  return(rval)
}

back_from_bps <- function(item){
      return((item/10000)+1)
}
clean_values <- function(df){
      df[df==Inf] <- NA
      df[df==-Inf] <- NA
      df[is.nan(df)] <- NA
      return(df)
}
compute_pnl_ratio <- function(ppmodel_computation_object){
      data <- ppmodel_computation_object@ppdata@data
      data$AbsPnlRatio <- clean_values(data$PnLOutof/abs(data$PnLInto))
      data$RelPnlRatio <- clean_values(data$AbsPnlRatio - (back_from_bps(data$CompoundReturnOutof)/abs(back_from_bps(data$CompoundReturnInto))))
      data$Indicator <- 1
      data$Tag <- unlist(Map(tagger,data$Hit1D))
      ppmodel_computation_object@output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,data)
      return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelPnlRatioPostComputation",
      prototype = prototype(
            compute = compute_pnl_ratio
      ),
      contains = c("PPModelPostComputation")
)

#' PPModel derived class SizeAdjustmentBatchGatherer
#'
#' @title SizeAdjustmentBatchGatherer
#' @name SizeAdjustmentBatchGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass SizeAdjustmentBatchGatherer

ppmodel_class_factory("SizeAdjustmentBatchGatherer","FeatureGathererWithSummary","gatherFeatures",c('TodayPL',outcome_price_features,context_price_features,context_size_adjustment_features),"PPModelSetupPassThruComputation","PPModelPnlRatioPostComputation")

#Position sizing
number_deciles <- function(data){
      deciles <- as.character(sort(unique(data$Av.MarketValueDecile)))
      data$DecileNumber <- as.character(data$Av.MarketValueDecile)
      for(d in 1:length(deciles)){
            data$DecileNumber[data$DecileNumber==deciles[[d]]] <- d
      }
      data$DecileNumber <- as.numeric(data$DecileNumber)
      return(data)
}
#Add ability to compute relative psn performance to position summary function
#(and PsnVolatility)

tagger <- function(psnup){
  if(!is.na(psnup)){
    if(psnup==TRUE){
      rval <- 'Hit'
    }
    else{
      rval <- 'Miss'
    }
  }
  else{
    rval <- NA
  }
  return(rval)
}

size_computations <- function(ppmodel_computation_object){
      data <- ppmodel_computation_object@ppdata@data
      data <- number_deciles(data)
      data$PsnUp <- (data$PsnReturn > 0)
      data$Indicator <- 1
      data$Tag <- unlist(Map(tagger,data$PsnUp))
      ppmodel_computation_object@output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,data)
      return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelNumberDecilePostComputation",
      prototype = prototype(
            compute = size_computations
      ),
      contains = c("PPModelPostComputation")
)

#' PPModel derived class PositionSizeBatchQuantiler
#'
#' @title PositionSizeBatchQuantiler
#' @name PositionSizeBatchQuantiler-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass PositionSizeBatchQuantiler

ppmodel_class_factory("PositionSizeBatchQuantiler","Av.MarketValueDecile","decileAvMarketValue",NULL,"PPModelSetupPassThruComputation","PPModelNumberDecilePostComputation")

#Primary placing
psn_data_day_of_primary_placing <- function(ppmodel_computation){
      return(psn_data_by_feature_slice(ppmodel_computation,'DaysSincePrimaryPlacing',function(x)x==0))
}

setClass(
      Class = "PPModelPsnOnPrimaryPlacingComputation",
      prototype = prototype(
            compute = psn_data_day_of_primary_placing
      ),
      contains = c("PPModelPostComputation")
)

#' PPModel derived class PrimaryPlacingPsnGatherer
#'
#' @title PrimaryPlacingPsnGatherer
#' @name PrimaryPlacingPsnGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass PrimaryPlacingPsnGatherer

ppmodel_class_factory("PrimaryPlacingPsnGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features,context_primary_placing_features),"PPModelSetupPassThruComputation","PPModelPsnOnPrimaryPlacingComputation")

#Secondary placing
psn_data_day_of_secondary_placing <- function(ppmodel_computation){
      return(psn_data_by_feature_slice(ppmodel_computation,'DaysSinceSecondaryPlacing',function(x)x==0))
}

setClass(
      Class = "PPModelPsnOnSecondaryPlacingComputation",
      prototype = prototype(
            compute = psn_data_day_of_secondary_placing
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class SecondaryPlacingPsnGatherer
#'
#' @title SecondaryPlacingPsnGatherer
#' @name SecondaryPlacingPsnGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass SecondaryPlacingPsnGatherer

ppmodel_class_factory("SecondaryPlacingPsnGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features,context_secondary_placing_features),"PPModelSetupPassThruComputation","PPModelPsnOnSecondaryPlacingComputation")

#Returns around placings
psn_returns_around_placings <- function(ppmodel_computation_object,ptype,ndays=90){
      psn <- getRawPositionData(ppmodel_computation_object@wh)
      psn <- psn@data
      sum_data <- getRawPositionSummary(ppmodel_computation_object@wh)
      sum_data$PsnLong <- sum_data$Long
      sum_data$Instrument <- sum_data$InstrumentID
      colnames(psn)[colnames(psn)=='Date'] <- 'TradeDate'
      colnames(psn)[colnames(psn)=='InstrumentID'] <- 'Instrument'
      psn <- psn[c('TradeDate','Instrument','StrategyID','MarketValue','TodayPL')]
      sum_data <- sum_data[c('Instrument','StrategyID','PsnLong','InitialValue','PsnReturn')]
      output <- merge(psn,sum_data,by=c('Instrument','StrategyID'),all.x=TRUE)

      output$PsnHit <- output$PsnReturn > 0
      output$Tag   <- as.character(output$PsnHit)
      output$Tag[output$Tag=='TRUE'] <- 'Hit'
      output$Tag[output$Tag=='FALSE']<- 'Miss'
      output$Indicator <- 1
      output$PsnOffside<- is_psn_offside(output)

      ppdata <- ppmodel_computation_object@ppdata@data
      if(ptype=='primary'){
        slct <- ppmodel_computation_object@ppdata@data$DaysSincePrimaryPlacing<=ndays|ppmodel_computation_object@ppdata@data$DaysToPrimaryPlacing<=ndays
      }
      if(ptype=='secondary'){
        slct <- ppmodel_computation_object@ppdata@data$DaysSinceSecondaryPlacing<=ndays|ppmodel_computation_object@ppdata@data$DaysToSecondaryPlacing<=ndays
      }
      slct[is.na(slct)] <- FALSE
      beforeafter <- ppdata[slct,]
      if(ptype=='primary'){
        beforeafter$BeforeEvent[beforeafter$DaysToPrimaryPlacing<=ndays]    <- TRUE
        beforeafter$BeforeEvent[beforeafter$DaysSincePrimaryPlacing<=ndays] <- FALSE
      }
      if(ptype=='secondary'){
        beforeafter$BeforeEvent[beforeafter$DaysToSecondaryPlacing<=ndays]    <- TRUE
        beforeafter$BeforeEvent[beforeafter$DaysSinceSecondaryPlacing<=ndays] <- FALSE
      }
      output <- merge(output,beforeafter[c('TradeID','TradeDate','Instrument','StrategyID','BeforeEvent')],by=c('TradeDate','Instrument','StrategyID'),all.x=TRUE)
      output$PsnTraded <- !is.na(output$TradeID)
      output <- output[c('TradeDate','Instrument','StrategyID','PsnTraded','TodayPL','PsnHit','Tag','Indicator','BeforeEvent','PsnOffside')]
      output <- unique(merge(ppmodel_computation_object@ppdata@data,output,by=c('TradeDate','Instrument','StrategyID'),all.x=TRUE))
      output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
      ppmodel_computation_object@output <- output
      return(ppmodel_computation_object)
}
psn_returns_around_prmryplacing <- function(ppmodel_computation){
      return(psn_returns_around_placings(ppmodel_computation,'primary'))
}

setClass(
      Class = "PPModelPsnAroundPrimaryPlacingComputation",
      prototype = prototype(
            compute = psn_returns_around_prmryplacing
      ),
      contains = c("PPModelPostComputation")
)

#' PPModel derived class PrimaryPlacingPsnGatherer
#'
#' @title PrimaryPlacingPsnGatherer
#' @name PrimaryPlacingPsnGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass PrimaryPlacingPsnGatherer

ppmodel_class_factory("PrimaryPlacingPsnGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features,context_primary_placing_features),"PPModelSetupPassThruComputation","PPModelPsnAroundPrimaryPlacingComputation")

psn_returns_around_scndryplacing <- function(ppmodel_computation){
      return(psn_returns_around_placings(ppmodel_computation,'secondary'))
}

setClass(
      Class = "PPModelPsnAroundSecondaryPlacingComputation",
      prototype = prototype(
            compute = psn_returns_around_scndryplacing
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class SecondaryPlacingPsnGatherer
#'
#' @title SecondaryPlacingPsnGatherer
#' @name SecondaryPlacingPsnGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass SecondaryPlacingPsnGatherer

ppmodel_class_factory("SecondaryPlacingPsnGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features,context_secondary_placing_features),"PPModelSetupPassThruComputation","PPModelPsnAroundSecondaryPlacingComputation")

#Pet names
#Pre-computation to insert statistics regarding leg number and
#span. Inserts into the summary so that these quantities are available
#to the downstream pre-processor.
fetch_leg_stats <- function(ppmodel_computation_object){
  wh <- ppmodel_computation_object@wh
  instruments <- listInstruments(wh)
  n_legs <- c()
  spans  <- c()
  for(instrument in instruments){
    n_legs <- c(n_legs,getNumberLegs(wh,instrument))
    spans  <- c(spans,getLegSpan(wh,instrument))
  }
  smmry <- getRawPositionSummary(wh)
  smmry <- merge(smmry,data.frame(InstrumentID=instruments,NLegs=n_legs),by=c('InstrumentID'),all.x=TRUE)
  smmry <- merge(smmry,data.frame(InstrumentID=instruments,LegSpan=spans),by=c('InstrumentID'),all.x=TRUE)
  wh@psn_summary <- dataset_factory(wh@psn_summary@key_cols,smmry)
  ppmodel_computation_object@output <- wh
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelInsertLegStatsComputation",
      prototype = prototype(
            compute = fetch_leg_stats
      ),
      contains = c("PPModelSetupComputation")
)

#Post computation to compute the average numbers of legs and spans
#and to designate positions as pet names
compute_leg_stats <- function(ppmodel_computation_object){
  output <- ppmodel_computation_object@ppdata@data
  avg_legs <- mean(output$NLegs,na.rm=TRUE)
  avg_span <- mean(output$LegSpan,na.rm=TRUE)
  output$PetName   <- (output$NLegs>avg_legs)&(output$LegSpan>avg_span)
  output$Indicator <- 1
  output$Pet  <- output$PetName
  output$Pet[output$Pet=='TRUE'] <- 'Pet'
  output$Pet[output$Pet=='FALSE']<- 'NotPet'
  output$PsnOffside <- is_psn_offside(output)
  output$Tag   <- as.character(output$PtvePnLOutof)
  output$Tag[output$Tag=='TRUE'] <- 'Hit'
  output$Tag[output$Tag=='FALSE']<- 'Miss'
  output$PsnUp <- output$PsnReturn > 0
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelComputeLegStatsComputation",
      prototype = prototype(
            compute = compute_leg_stats
      ),
      contains = c("PPModelPostComputation")
)

#' PPModel derived class PetNamesPsnGatherer
#'
#' @title PetNamesPsnGatherer
#' @name PetNamesPsnGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass PetNamesPsnGatherer

ppmodel_class_factory("PetNamesPsnGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features),"PPModelInsertLegStatsComputation","PPModelComputeLegStatsComputation")

#Position holding periods
#Categorise trades according to holding period
categorise_age <- function(ppmodel_computation_object){
  output <- ppmodel_computation_object@ppdata@data
  output$AgeCategory <- as.character(output$Age)
  output$AgeCategory[output$Age<7]   <- 'New'
  output$AgeCategory[output$Age>21]  <- 'Old'
  output$AgeCategory[output$AgeCategory!='New'&output$AgeCategory!='Old'] <- 'Remainder'
  output$Indicator <- 1
  output$PsnUp <- output$PsnReturn > 0
  output$Tag   <- as.character(output$PsnUp)
  output$Tag[output$Tag=='TRUE'] <- 'Hit'
  output$Tag[output$Tag=='FALSE']<- 'Miss'
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelAgeCategoryComputation",
      prototype = prototype(
            compute = categorise_age
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel class for PsnAgeGatherer
#'
#' @title PsnAgeGatherer
#' @name PsnAgeGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass PsnAgeGatherer

ppmodel_class_factory("PsnAgeGatherer","FeatureGathererWithSummary","gatherFeatures",c(outcome_price_features,context_position_age_features),"PPModelSetupPassThruComputation","PPModelAgeCategoryComputation")

#Compute position holding period data
#Also merge in all position history and trade price data

compute_delta_stats <- function(ppmodel_computation_object){
  data <- ppmodel_computation_object@ppdata@data
  stock_rtn <- data$CompoundReturnOutof/10000
  data$DeltaPL <- stock_rtn*((-1)^(data$Long+1))*((-1)^(data$PsnLong+1))*data$ValueUSD
  stock_rtn_vol <- data$VolOutof/10000
  data$DeltaSwing <- stock_rtn_vol*((-1)^(data$Long+1))*((-1)^(data$PsnLong+1))*data$ValueUSD
  stock_rtn_skew <- sign(data$SkewOutof)*(abs(data$SkewOutof)^(1/3))*stock_rtn_vol
  data$DeltaSkew <- stock_rtn_skew*((-1)^(data$Long+1))*((-1)^(data$PsnLong+1))*data$ValueUSD
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,data)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

trade_history <- function(ppmodel_computation_object){
  ppmodel_computation_object <- compute_delta_stats(ppmodel_computation_object)
  output <- ppmodel_computation_object@output@data
  output <- output[setdiff(colnames(output),c('ClosePrice','MarketValue'))]
  trades <- unique(output$TradeID)
  raw_psn_data <- getRawPositionData(ppmodel_computation_object@wh)
  raw_psn_data <- raw_psn_data@data[c('Date','InstrumentID','Strategy','MarketValue','TodayPL')]
  colnames(raw_psn_data) <- c('TradeDate','Instrument','Strategy','MarketValue','TodayPL')
  first_trade <- TRUE
  for(trade in trades){
    trd <- getTrade(ppmodel_computation_object@wh,trade)
    if(nrow(trd@daily_data@data)>0){
      if(first_trade){
        tryCatch({
                  trade_data <- cbind(InstrumentID=trd@instrument,trd@daily_data@data[c('DateTime','ClosePrice')])
                  first_trade <- FALSE
                  trade_data <- cbind(Strategy=trd@strategy,trade_data)
                 },error=function(cond){
                  message(paste("ppModel trade history: Warning trade",trade,"daily date bind failure."))
                 })
      }
      else{
        tryCatch({
                  df <- cbind(InstrumentID=trd@instrument,trd@daily_data@data[c('DateTime','ClosePrice')])
                  df <- cbind(Strategy=trd@strategy,df)
                  trade_data <- rbind(trade_data,df)
                 },error=function(cond){
                  message(paste("ppModel trade history: Warning trade",trade,"daily date bind failure."))
                 })
      }
    }
    else{
      message(paste("ppModel trade history: Warning trade",trade,"has no daily data."))
    }
  }
  trade_data <- unique(trade_data)
  colnames(trade_data) <- c('Strategy','Instrument','TradeDate','ClosePrice')
  raw_psn_data <- merge(raw_psn_data,trade_data,by=c('Strategy','Instrument','TradeDate'),all.x=TRUE)
  raw_psn_data <- merge(raw_psn_data,output,by=c('Strategy','Instrument','TradeDate'),all.x=TRUE)
  ppmodel_computation_object@output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,raw_psn_data)
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelTradeHistoryComputation",
      prototype = prototype(
            compute = trade_history
      ),
      contains = c("PPModelPostComputation")
)

coalesce_on_key <- function(ppmodel_computation_object){
  ppmodel_computation_object@output <- rowCoalesceOn(ppmodel_computation_object@ppdata,by=ppmodel_computation_object@key)
  return(ppmodel_computation_object)
}

get_data_frame <- function(source,cols){
  if(length(source)>0){
    rval <- source@data
  }
  else{
    rval <- data.frame(t(rep(NA,length(cols))))
    colnames(rval) <- cols
  }
  return(rval)
}

#Short term hack: need proper structure around database access.
get_event_data_db <- function(event_keys){
  min_date <- min(event_keys$DateTime)
  max_date <- max(event_keys$DateTime)
  SQL <- paste("prEvent_GetByDate @dtFrom = '",min_date,"', @dtTo = '",max_date,"'",sep="")
  cn <- odbcConnect(database_config@database,uid=database_config@dbuser)
  evt_data <- sqlQuery(cn,SQL)
  close(cn)
  evt_data <- evt_data[c('lInstrumentID','dtDateTime','sEventType')]
  colnames(evt_data) <- c('InstrumentID','DateTime','EventType')
  evt_data$InstrumentID <- as.numeric(evt_data$InstrumentID)
  evt_data$DateTime <- as.Date(evt_data$DateTime)
  evt_data$EventType <- as.character(evt_data$EventType)
  evt_data <- merge(event_keys,evt_data,by=c('InstrumentID','DateTime'),all.x=TRUE)
  return(evt_data)
}

event_transform <- function(event_data,keys,data_col){
  key_values <- unique(event_data[keys])
  not_na <- rep(TRUE,nrow(key_values))
  for(key in keys){
    not_na <- not_na&!is.na(key_values[key])
  }
  key_values <- key_values[not_na,]
  types <- unique(event_data[data_col])
  types <- types[!is.na(types)]
  initialise <- TRUE
  for(ty in types){
    subdata <- event_data
    subdata <- subdata[!is.na(subdata[data_col]),]
    subdata <- subdata[subdata[data_col]==ty,]
    subdata <- unique(subdata)
    colnames(subdata)[colnames(subdata)==data_col]<-ty
    if(initialise){
      rval <- merge(key_values,subdata,by=keys,all.x=TRUE)
      initialise <- FALSE
    }
    else{
      rval <- merge(rval,subdata,by=keys,all.x=TRUE)
    }
  }
  rval <- cbind(rval[keys],data.frame(Map(function(x)!is.na(x),rval[types])))
  return(rval)
}

get_history_metadata <- function(ppmodel_computation_object){
  data <- ppmodel_computation_object@ppdata@data
  trader <- ppmodel_computation_object@wh@trader_id
  instruments <- unique(data$Instrument)
  instruments <- data.frame(ID=instruments)
  instrument_tickers <- data_request("instrument_details",instruments,c("Name"))
  instrument_tickers <- get_data_frame(instrument_tickers,c("ID","Name"))
  colnames(instrument_tickers) <- c("Instrument","Name")
  instrument_tickers$Name <- gsub("- DELAYED","",instrument_tickers$Name)
  dealer_keys <- unique(data$TradeDate)
  dealer_keys <- data.frame(lTraderID=trader,dtTradeDate=dealer_keys)
  all_dealer_data <- data_request("dealing_datastore",dealer_keys,c("lInstrumentID","sTradeRationale","sInputDirection"))
  all_dealer_data <- get_data_frame(all_dealer_data,c("lTraderID","dtTradeDate","lInstrumentID","sTradeRationale","sInputDirection"))
  all_dealer_data <- all_dealer_data[,2:5]
  colnames(all_dealer_data) <- c("TradeDate","Instrument","Rationale","InputDirection")
  dealer_data <- event_transform(all_dealer_data[c("TradeDate","Instrument","InputDirection")],c("TradeDate","Instrument"),"InputDirection")
  all_dealer_data <- unique(all_dealer_data[!is.na(all_dealer_data$Rationale),])
  event_keys <- unique(data[c("Instrument","TradeDate")])
  colnames(event_keys) <- c("InstrumentID","DateTime")
  #event_data <- data_request("event_datastore",event_keys,c("EventType"))
  #event_data <- get_data_frame(event_data,c("InstrumentID","DateTime","EventType"))
  event_data <- get_event_data_db(event_keys)
  colnames(event_data) <- c("Instrument","TradeDate","Event")
  event_data <- event_transform(event_data,c("Instrument","TradeDate"),"Event")
  inst_keys <- unique(data[is.na(data$ClosePrice),c('Instrument','TradeDate')])
  colnames(inst_keys) <- c('lInstrumentID','dtDateTime')
  price_data <- data_request("instrument_price",inst_keys,c('dblClosePrice'))
  price_data <- get_data_frame(price_data,c("lInstrumentID","dtDateTime","dblClosePrice"))
  colnames(price_data) <- c('Instrument','TradeDate','FillClosePrice')
  data <- merge(data,instrument_tickers,by=c("Instrument"),all.x=TRUE)
  data <- merge(data,dealer_data,by=c("Instrument","TradeDate"),all.x=TRUE)
  data <- merge(data,event_data,by=c("Instrument","TradeDate"),all.x=TRUE)
  data <- merge(data,all_dealer_data[c("TradeDate","Instrument","Rationale")],by=c("Instrument","TradeDate"),all.x=TRUE)
  data <- merge(data,price_data,by=c("Instrument","TradeDate"),all.x=TRUE)
  data$ClosePrice[is.na(data$ClosePrice)] <- data$FillClosePrice[is.na(data$ClosePrice)]
  data <- data[setdiff(colnames(data),'FillClosePrice')]
  data <- unique(data)
  ppmodel_computation_object@output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,data)
  return(ppmodel_computation_object)
}

#At present this does not work correctly!
#Daily PL accumulated across intraday trades.
#Need to remove duplicate PL
compute_integrated_pl <- function(ppmodel_computation_object){
  history_data <- ppmodel_computation_object@ppdata@data
  instruments <- unique(history_data$Instrument)
  history_data$CumulativePL <- history_data$TodayPL
  history_data$CumulativePL[is.na(history_data$CumulativePL)] <- 0
  history_data$IntegratedPL <- NA
  for(ins in instruments){
    history_data[history_data$Instrument==ins,'CumulativePL'] <- cumsum(history_data[history_data$Instrument==ins,'CumulativePL'])
    history_data[history_data$Instrument==ins,'IntegratedPL'] <- cumsum(history_data[history_data$Instrument==ins,'CumulativePL'])
  }
  ppmodel_computation_object@output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,history_data)
  return(ppmodel_computation_object)
}

coalesce_and_get_metadata <- function(ppmodel_computation_object){
  ppmodel_computation_object <- coalesce_on_key(ppmodel_computation_object)
  ppmodel_computation_object@ppdata <- ppmodel_computation_object@output
  ppmodel_computation_object <- get_history_metadata(ppmodel_computation_object)
  ppmodel_computation_object@ppdata <- ppmodel_computation_object@output
  ppmodel_computation_object <- compute_integrated_pl(ppmodel_computation_object)
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelHistoryPostComputation",
      representation = representation(
            key = 'character'
      ),
      prototype = prototype(
            key = c('Strategy','Instrument','TradeDate'),
            compute = coalesce_and_get_metadata
      ),
      contains = c("PPModelSummaryComputation")
)


#' PPModel derived class TradeHistory
#'
#' @title TradeHistory
#' @name TradeHistory-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass TradeHistory

ppmodel_class_factory("TradeHistory","FeatureGathererWithSummary","gatherFeatures",c(outcome_price_features,context_price_features,context_position_age_features,control_price_features),"PPModelSetupPassThruComputation","PPModelTradeHistoryComputation","PPModelHistoryPostComputation",index_by_date_column='TradeDate')


#' PPModel derived class TradeHistorySimple
#'
#' @title TradeHistorySimple
#' @name TradeHistorySimple-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass TradeHistorySimple

ppmodel_class_factory("TradeHistorySimple","FeatureGatherer","gatherFeatures",c(outcome_price_features, context_price_features),"PPModelSetupPassThruComputation","PPModelPostPassThruComputation","PPModelSummaryPassThruComputation",index_by_date_column='TradeDate')


#' PPModel derived class TradeHistorySimpleWithSummary
#'
#' @title TradeHistorySimpleWithSummary
#' @name TradeHistorySimpleWithSummary-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass TradeHistorySimpleWithSummary

ppmodel_class_factory("TradeHistorySimpleWithSummary","FeatureGathererWithSummary","gatherFeatures",c(outcome_price_features, context_price_features,control_price_features),"PPModelSetupPassThruComputation","PPModelTradeHistoryComputation","PPModelSummaryPassThruComputation",index_by_date_column='TradeDate')



#Price snapshot
#Attaches price snapshot data to the trade feature information
#For each trade id, identifying a leg, produce a single trace
#which is the average of the local prices for each trade
attach_snapshot <- function(ppmodel_computation_object){
  #This is a clunky way to compose pre-processor level functions
  #ToDo: provide object-level composition mechanism
  ppmodel_computation_object <- categorise_age(ppmodel_computation_object)
  wh     <- ppmodel_computation_object@wh
  trades <- unique(ppmodel_computation_object@output@data$TradeID)
  first_trade <- TRUE
  for(trade in trades){
    snapshot <- tryCatch({
                            getPriceSnapshot(wh,trade)
                         }, error = function(cond){
                            message(paste("Could not get price snapshot for trade",trade))
                         })
    if(length(snapshot)>0){
      snapshot$Group <- 1 #Dummy to aggregate over all rows
      snapshot <- dataset_factory(c('Group'),snapshot)
      average  <- tryCatch({
                              aggregateGroup(snapshot,snapshot@data_cols,c('Group'),function(x)mean(x,na.rm=TRUE))
                            }, error=function(cond){
                              message("Error in aggregate group on trade",trade)
                            })
      if(length(average)>0){
        average  <- average[setdiff(colnames(average),'Group')]
        average  <- cbind(trade,average)
        colnames(average)[1] <- 'TradeID'
        if(first_trade){
          all_trades <- average
        }
        else{
          all_trades <- rbind(all_trades,average)
        }
        first_trade <- FALSE
      }
    }
  }
  ppmodel_computation_object@output <- innerJoinFrame(ppmodel_computation_object@output,all_trades,ppmodel_computation_object@ppdata@key_cols)
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelPriceBySnapshotComputation",
      prototype = prototype(
            compute = attach_snapshot
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class PriceBySnapshotGatherer
#'
#' @title PriceBySnapshotGatherer
#' @name PriceBySnapshotGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass PriceBySnapshotGatherer

ppmodel_class_factory("PriceBySnapshotGatherer","FeatureGathererWithSummary","gatherFeatures",c(outcome_price_features,context_price_features,context_position_age_features),"PPModelSetupPassThruComputation","PPModelPriceBySnapshotComputation")

#Averagedown analysis at the position level
#How did positions featuring averaging down do?
#THIS INCORRECT -> Does not take into account active
#changes to position size.
average_down <- function(data){
  return ((data$MarketValue<data$InitialValue&data$PsnLong&data$Long)|(data$MarketValue>data$InitialValue&!data$PsnLong&!data$Long))
}

average_down_frame <- function(ppmodel_computation_object){
  output <- ppmodel_computation_object@ppdata@data
  output$AverageDown <- average_down(output)
  output$Indicator <- 1
  output$PsnUp <- output$PsnReturn > 0
  output$Tag   <- as.character(output$PsnUp)
  output$Tag[output$Tag=='TRUE'] <- 'Up'
  output$Tag[output$Tag=='FALSE']<- 'Down'
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelAverageDownComputation",
      prototype = prototype(
        compute = average_down_frame
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class AverageDownPsnGatherer
#'
#' @title AverageDownPsnGatherer
#' @name AverageDownPsnGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass AverageDownPsnGatherer

ppmodel_class_factory("AverageDownPsnGatherer","FeatureGathererWithSummary","gatherFeatures",c("MarketValue",outcome_price_features,context_price_features),"PPModelSetupPassThruComputation","PPModelAverageDownComputation")

#Level of trade entry
#Determine how many 5 day standard deviations the
#trade is from the 20day price average

trade_level <- function(ppmodel_computation_object){
  ppmodel_computation_object <- average_down_frame(ppmodel_computation_object)
  output <- ppmodel_computation_object@output@data
  output$EntryLevel <- (output$MidOnEntry-output$PriceMavg)/((output$VolInto/10000)*output$MidOnEntry)
  output$EntryLevel[is.na(output$EntryLevel)] <- (output$PriorClosePrice[is.na(output$EntryLevel)]-output$PriceMavg[is.na(output$EntryLevel)])/((output$VolInto[is.na(output$EntryLevel)]/10000)*output$PriorClosePrice[is.na(output$EntryLevel)])
  output$EntryType <- as.character(output$EntryLevel)
  output$EntryType[output$EntryLevel < -1] <-'Low'
  output$EntryType[output$EntryLevel > 1] <-'High'
  output$EntryType[output$EntryLevel<=1&output$EntryLevel>=-1] <- 'Central'
  output$Tag  <- as.character(output$Hit1D)
  output$Tag[output$Tag=='TRUE'] <- 'Hit'
  output$Tag[output$Tag=='FALSE']<- 'Miss'
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelTradeLevelComputation",
      prototype = prototype(
        compute = trade_level
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class TradeLevelGatherer
#'
#' @title TradeLevelGatherer
#' @name TradeLevelGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass TradeLevelGatherer

ppmodel_class_factory("TradeLevelGatherer","FeatureGathererWithSummary","gatherFeatures",c("TodayPL","MarketValue",outcome_price_features,context_price_features),"PPModelSetupPassThruComputation","PPModelTradeLevelComputation")

#Snapshot analysis for trade level
#This has been superceeded by the version for results below
#the two should be combined
attach_snapshot_level <- function(ppmodel_computation_object){
  #Can re-write this so that we pass function compositions in to a parent
  #function
  ppmodel_computation_object <- trade_level(ppmodel_computation_object)
  wh     <- ppmodel_computation_object@wh
  trades <- unique(ppmodel_computation_object@output@data$TradeID)
  first_trade <- TRUE
  for(trade in trades){
    snapshot <- tryCatch({
                            getPriceSnapshot(wh,trade)
                         }, error = function(cond){
                            message(paste("Could not get price snapshot for trade",trade))
                         })
    if(length(snapshot)>0){
      snapshot$Group <- 1 #Dummy to aggregate over all rows
      snapshot <- dataset_factory(c('Group'),snapshot)
      average  <- tryCatch({
                              aggregateGroup(snapshot,snapshot@data_cols,c('Group'),function(x)mean(x,na.rm=TRUE))
                            }, error=function(cond){
                              message("Error in aggregate group on trade",trade)
                            })
      if(length(average)>0){
        average  <- average[setdiff(colnames(average),'Group')]
        average  <- cbind(trade,average)
        colnames(average)[1] <- 'TradeID'
        if(first_trade){
          all_trades <- average
        }
        else{
          all_trades <- rbind(all_trades,average)
        }
        first_trade <- FALSE
      }
    }
  }
  ppmodel_computation_object@output <- innerJoinFrame(ppmodel_computation_object@output,all_trades,ppmodel_computation_object@ppdata@key_cols)
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelTradeLevelSnapshotComputation",
      prototype = prototype(
            compute = attach_snapshot_level
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class TradeLevelSnapShot
#'
#' @title TradeLevelSnapShot
#' @name TradeLevelSnapShot-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass TradeLevelSnapShot

ppmodel_class_factory("TradeLevelSnapShot","FeatureGathererWithSummary","gatherFeatures",c("TodayPL","MarketValue",outcome_price_features,context_price_features),"PPModelSetupPassThruComputation","PPModelTradeLevelSnapshotComputation")

#Module to determine if trades have been stopped out,
#or if profit targets have been reached
stopped_out <- function(ppmodel_computation_object){
  output <- ppmodel_computation_object@ppdata@data
  stop_diff <- output$MidOnEntry - output$StopLoss
  output$StoppedOut[output$Long] <- stop_diff[output$Long]<=0
  output$StoppedOut[!output$Long] <- stop_diff[!output$Long]>=0
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

target_hit <- function(ppmodel_computation_object){
  output <- ppmodel_computation_object@ppdata@data
  target_diff <- output$MidOnEntry - output$ProfitTarget
  output$HitTarget[output$Long] <- target_diff[output$Long]>=0
  output$HitTarget[!output$Long]<- target_diff[!output$Long]<=0
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

stops_targets <- function(ppmodel_computation_object){
  ppmodel_computation_object <- stopped_out(ppmodel_computation_object)
  ppmodel_computation_object@ppdata <- ppmodel_computation_object@output
  ppmodel_computation_object <- target_hit(ppmodel_computation_object)
  output <- ppmodel_computation_object@output@data
  output$Indicator <- 1
  output$Tag  <- as.character(output$Hit1D)
  output$Tag[output$Tag=='TRUE'] <- 'Hit'
  output$Tag[output$Tag=='FALSE']<- 'Miss'
  output$StopSet <- !is.na(output$StopLoss)
  output$TargetSet <- !is.na(output$ProfitTarget)
  output <- dataset_factory(ppmodel_computation_object@ppdata@key_cols,output)
  ppmodel_computation_object@output <- output
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelStopsTargetsComputation",
      prototype = prototype(
            compute = stops_targets
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class StopTargetsGatherer
#'
#' @title StopTargetsGatherer
#' @name StopTargetsGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass StopTargetsGatherer

ppmodel_class_factory("StopTargetsGatherer","FeatureGathererWithSummary","gatherFeatures",c("TodayPL","MarketValue",outcome_price_features,context_price_features,control_price_features),"PPModelSetupPassThruComputation","PPModelStopsTargetsComputation")

#Results day snapshot analysis
resultsday_snapshot <- function(ppmodel_computation_object,exposure=FALSE){
  ppmodel_computation_object <- compute_position_offside(ppmodel_computation_object)
  wh     <- ppmodel_computation_object@wh
  trades <- unique(ppmodel_computation_object@output@data$TradeID)
  output <- ppmodel_computation_object@output@data
  output$Indicator <- 1
  output$Tag  <- as.character(output$Hit1D)
  output$Tag[output$Tag=='TRUE'] <- 'Hit'
  output$Tag[output$Tag=='FALSE']<- 'Miss'
  ppmodel_computation_object@output <- resetData(ppmodel_computation_object@output,output)
  first_trade <- TRUE
  for(trade in trades){
    snapshot <- tryCatch({
                            getPriceSnapshot(wh,trade,exposure=exposure)
                         }, error = function(cond){
                            message(paste("Could not get price snapshot for trade",trade,":",cond))
                         })
    if(length(snapshot)>0){
      snapshot$Group <- 1 #Dummy to aggregate over all rows
      snapshot[is.na(snapshot)] <- 0
      snapshot <- tryCatch({
                            dataset_factory(c('Group'),snapshot)
                           }, error=function(cond){
                            message("Error creating snapshot:",cond)
                           })
      average  <- tryCatch({
                              aggregateGroup(snapshot,snapshot@data_cols,c('Group'),function(x)mean(x))
                            }, error=function(cond){
                              message("Error in aggregate group on trade",trade,":",cond)
                            })
      if(length(average)>0){
        average  <- average[setdiff(colnames(average),'Group')]
        average  <- cbind(trade,average)
        colnames(average)[1] <- 'TradeID'
        if(first_trade){
          all_trades <- average
        }
        else{
          all_trades <- rbind(all_trades,average)
        }
        first_trade <- FALSE
      }
    }
  }
  #all_trades <- merge(all_trades,output,by=c("TradeID"),all.x=TRUE)
  ppmodel_computation_object@output <- tryCatch({
                                                  innerJoinFrame(ppmodel_computation_object@output,all_trades,ppmodel_computation_object@ppdata@key_cols)
                                                },error=function(cond){
                                                  message(paste("Inner join on frame failed:",cond))
                                                  message(paste(head(all_trades),collapse=" "))
                                                })
  return(ppmodel_computation_object)
}

setClass(
      Class = "PPModelResultsSnapShotPostComputation",
      prototype = prototype(
            compute = resultsday_snapshot
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class ResultsDaySnapShotBatchGatherer
#'
#' @title ResultsDaySnapShotBatchGatherer
#' @name ResultsDaySnapShotBatchGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass ResultsDaySnapShotBatchGatherer


ppmodel_class_factory("ResultsDaySnapShotBatchGatherer","FeatureGathererWithSummary","gatherFeatures",c("TodayPL","MarketValue",outcome_price_features,context_price_features,context_resultsday_features),"PPModelSetupPassThruComputation","PPModelResultsSnapShotPostComputation")

#Results day exposure
resultsday_exposure <- function(ppmodel_computation_object){
  return(resultsday_snapshot(ppmodel_computation_object,exposure=TRUE))
}

setClass(
      Class = "PPModelResultsExposureSnapShotPostComputation",
      prototype = prototype(
            compute = resultsday_exposure
      ),
      contains = c("PPModelPostComputation")
)


#' PPModel derived class ResultsDayExposureSnapShotBatchGatherer
#'
#' @title ResultsDayExposureSnapShotBatchGatherer
#' @name ResultsDayExposureSnapShotBatchGatherer-class
#' @docType class
#' @rdname PPModel-class
#' @exportClass ResultsDayExposureSnapShotBatchGatherer

ppmodel_class_factory("ResultsDayExposureSnapShotBatchGatherer","FeatureGathererWithSummary","gatherFeatures",c("TodayPL","MarketValue",outcome_price_features,context_price_features,context_resultsday_features),"PPModelSetupPassThruComputation","PPModelResultsExposureSnapShotPostComputation")
