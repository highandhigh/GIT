sourceTo("../analysis_modules/portfolio_factor_exposure/portfolio_factor_exposure.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
sourceTo("../models/key_library.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)
library(testthat)

#########################
#
# PortfolioFactorExposureAnalysisBlock Tests
#
#########################
tested.class          <-  "PortfolioFactorExposureAnalysisBlock"
valid.column_name_map <- hash(c("TraderID", "start", "end"), c("id", "start", "end"))
init.key_values       <- data.frame(TraderID = character(),
                                    start    = as.Date(character()),
                                    end    = as.Date(character()))

test_that(paste("Can create", tested.class, "object"), {
  expect_is(new(tested.class), tested.class)
})



test_that(paste("Can use basic accessors of ", tested.class, "object"), {
  
  object <- new(tested.class)
  expect_is(object, tested.class)
  
  expect_is(getPortfolioDataObject(object), "StrategyPortfolio")
  expect_is(getFactorExposureDataObject(object), "FactorExposureData")
  
  expect_is(getOutputGGPlotData(object), "data.frame")
  expect_is(getOutputFrontendData(object), "data.frame")

  expect_equal(getDataSourceClientColumnNameMap(object), valid.column_name_map)
  
  
})


test_that("Cannot dataRequest() with invalid key_values", {
  
  object <- new(tested.class)
  
  
  invalid.key_values <- data.frame(TraderID = integer(), 
                                   start = as.Date(character()),
                                   end = as.Date(character()))
  
  expect_error(dataRequest(object, invalid.key_values),
               regexp = "Zero row query keys data.frame passed")
  
  invalid.key_values <- data.frame(lC = numeric(), dtD = as.Date(character()))
  
  expect_error(dataRequest(object, invalid.key_values),
               regexp = "Invalid column names of query keys passed")
  
  
  expect_equal(getDataSourceQueryKeyValues(object), init.key_values)
  
})



test_that("Can dataRequest() with valid key_values", {
  
  object <- new(tested.class)
  
  valid.key_values <- dated_twelve_monthly_lookback(11, "2016-06-30")
  colnames(valid.key_values) <- c("TraderID", "start", "end")
  
  object <- dataRequest(object, valid.key_values)
  
  expect_equal(getDataSourceQueryKeyValues(object), valid.key_values)
  
  # portfolio data verification
  portf_data <- getPortfolioDataObject(object)
  expect_is(portf_data, "StrategyPortfolio")
  expect_gt(getStoredNRows(portf_data), 0)
  
  # factor exposure data verification
  fct_exp_data <- getFactorExposureDataObject(object)
  expect_is(fct_exp_data, "FactorExposureData")
  expect_gt(getStoredNRows(fct_exp_data), 0)

  
})


test_that(paste("Can Process() on", tested.class), {
  
  object <- new(tested.class)
  
  valid.key_values <- dated_twelve_monthly_lookback(11, "2016-06-30")
  colnames(valid.key_values) <- c("TraderID", "start", "end")
  
  object <- dataRequest(object, valid.key_values)
  
  expect_equal(getDataSourceQueryKeyValues(object), valid.key_values)
  
  # portfolio data verification
  portf_data <- getPortfolioDataObject(object)
  expect_is(portf_data, "StrategyPortfolio")
  expect_gt(getStoredNRows(portf_data), 0)
  
  # factor exposure data verification
  fct_exp_data <- getFactorExposureDataObject(object)
  expect_is(fct_exp_data, "FactorExposureData")
  expect_gt(getStoredNRows(fct_exp_data), 0)

  
  object <- Process(object)
  
  expect_is(getOutputGGPlot(object), "ggplot")
  expect_is(getOutputGGPlotData(object), "data.frame")

})


