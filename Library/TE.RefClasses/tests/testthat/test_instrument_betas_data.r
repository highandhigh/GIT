context("Testing Instrument Betas Data")

#############################
#
# InstrumentBetasData Tests
#
#############################

tested.class          <-  "InstrumentBetasData"
valid.component       <- "Betas"
valid.risk_model      <- "RiskModel.DevelopedEuropePrototype150.1.1"
valid.risk_model_obj  <- new(valid.risk_model)
valid.model_factors   <- getRiskModelFactorNames(valid.risk_model_obj)
valid.model_prefix    <- getRiskModelPrefix(valid.risk_model_obj)
valid.lookback        <- getRiskModelLookback(valid.risk_model_obj)

valid.key_cols        <- c(risk_model_objectstore_keys, "InstrumentID")
valid.values          <- c("Date", "InstrumentID",
                           valid.model_factors)
valid.required_colnms <- c('Date', "InstrumentID",
                           valid.model_factors)

# valid.column_name_map <- hash(c("Instrument", "InstrumentID"),
#                               c("InstrumentID","Instrument"))

valid.column_name_map <- hash("dtDateTime"    = "Date",
                              "dtDate"        = "Date",
                              "lInstrumentID" = "InstrumentID",
                              "sFactorName"   = "FactorName",
                              "Instrument"    = "InstrumentID")
init.key_values       <-  data.frame(Date = as.Date(character()),
                                     InstrumentID = integer())




test_that(paste("Can create", tested.class, "object"), {
  expect_is(new(tested.class), tested.class)
})

test_that(paste("Can use basic accessors of ", tested.class, "object"), {

  object <- new(tested.class)
  expect_is(object, tested.class)

  expect_equal(getRiskModelComponentName(object), valid.component)

  expect_equal(getRiskModelName(object), valid.model_prefix)

  expect_is(getRiskModelObject(object), valid.risk_model)

  expect_equal(getRiskModelLookback(object), valid.lookback)

  expect_equal(getDataSourceQueryKeyColumnNames(object), valid.key_cols)

  expect_equal(getDataSourceReturnColumnNames(object), valid.values)

  expect_equal(getDataSourceQueryKeyValues(object), init.key_values)

  expect_equal(getDataSourceClientColumnNameMap(object), valid.column_name_map)


})


test_that("Cannot .setDataSourceQueryKeyValues with invalid data", {

  object <- new(tested.class)

  expect_error(TE.RefClasses:::.setDataSourceQueryKeyValues(object, init.key_values),
               regexp = "Zero row query keys data.frame passed")



  invalid.key_values <- data.frame(lC = numeric(), dtD = as.Date(character()))

  expect_error(TE.RefClasses:::.setDataSourceQueryKeyValues(object, invalid.key_values),
               regexp = "Invalid column names of query keys passed")

  expect_equal(getDataSourceQueryKeyValues(object), init.key_values)

})


test_that("Can .setDataSourceQueryKeyValues with valid data", {

  object <- new(tested.class)

  valid.key_vals <- data.frame(Date = seq(from = as.Date('2016-06-01'),
                                                 to = as.Date('2016-06-03'),
                                                 by = "1 day"),
                               InstrumentID = 4454
                               )

  object <- TE.RefClasses:::.setDataSourceQueryKeyValues(object, valid.key_vals)

  expect_equal(getDataSourceQueryKeyValues(object), valid.key_vals)

})


test_that("Cannot dataRequest() with invalid key_values", {

  object <- new(tested.class)


  invalid.key_values <- data.frame(InstrumentID = integer(),
                                   Date = as.Date(character()))

  expect_error(dataRequest(object, invalid.key_values),
               regexp = "Zero row query keys data.frame passed")



  invalid.key_values <- data.frame(lC = numeric(), dtD = as.Date(character()))

  expect_error(dataRequest(object, invalid.key_values),
               regexp = "Invalid column names of query keys passed")


  expect_equal(getDataSourceQueryKeyValues(object), init.key_values)

})


test_that("Generates empty data.frame when dataRequest() with nonexistent key_values", {

  object <- new(tested.class)

  nexist.key_vals <- data.frame(InstrumentID = 1984,
                                Date = seq(from = today(),
                                                  today() + 5,
                                                  by = "1 day"))
  diff <- setdiff(valid.required_colnms,valid.key_cols)

  valid.ret_data <- cbind(nexist.key_vals,data.frame(t(rep(NA,length(diff)))))

  colnames(valid.ret_data) <- c(colnames(nexist.key_vals), diff)


  object <- dataRequest(object, nexist.key_vals)

  var_names <- intersect(getRequiredVariablesNames(object), valid.required_colnms)

  expect_equal(var_names , valid.required_colnms)

  ret_data <- getReferenceData(object)

  valid.ret_data <- valid.ret_data[colnames(ret_data)]

  class_names <- Map(class, ret_data)

  setAs("numeric", "Date", function(from){as.Date(from)})

  cols <- colnames(valid.ret_data)
  valid.ret_data <- as.data.frame(lapply(seq(length(class_names)),
                                         function(x) {as(valid.ret_data[,x], class_names[[x]])}), stringsAsFactors = FALSE)

  colnames(valid.ret_data) <- cols

  expect_equivalent(ret_data, valid.ret_data)

})




test_that("Can dataRequest() with valid key_values", {

  skip_if_not(as.logical(Sys.getenv("R_TESTTHAT_RUN_LONG_TESTS", unset = "FALSE")))

  object <- new(tested.class)

  # instruments with large ammount of events for these days
  # 5004 5793 6496 7703 8038 5826 5687 6002 6203
  # 6    6    7    7    7    8   11   11   12
  valid.key_vals <- expand.grid(InstrumentID = as.integer(c(5004, 5793, 6496, 7703, 8038, 5826, 5687, 6002, 6203)),
                                Date = seq(from = as.Date('2016-06-20'),
                                               to = as.Date('2016-06-23'),
                                               by = "1 day"))

  values <- getDataSourceReturnColumnNames(object)

  # create valid return data.frame
  start        <- min(valid.key_vals$Date)
  end          <- max(valid.key_vals$Date)
  rm_str       <- get_most_recent_model_objectstore(valid.model_prefix, end, valid.lookback)
  name         <- getID(rm_str)
  query_data   <- queryDailyRiskModelObjectStore(rm_str,name,valid.lookback,valid.component)
  query_data   <- getData(query_data)
  query_data   <- query_data[query_data$Date >= start & query_data$Date <= end, ]

  merge_keys   <- valid.key_vals

  #colnames(merge_keys) <- TE.RefClasses:::.translateDataSourceColumnNames(object, colnames(merge_keys))
  colnames(merge_keys) <- c("Instrument", "Date")

  valid.ret_data <- merge(query_data,
                        merge_keys[merge_keys$Date >= start & merge_keys$Date <= end, ], all.y = TRUE)

  colnames(valid.ret_data) <- TE.RefClasses:::.translateDataSourceColumnNames(object, colnames(valid.ret_data))

  rownames(valid.ret_data) <- seq(nrow(valid.ret_data))

  valid.ret_data <- arrange(valid.ret_data, InstrumentID, Date)

  object <- dataRequest(object, valid.key_vals)

  expect_true(setequal(getDataSourceQueryKeyColumnNames(object), colnames(valid.key_vals)))
  expect_true(setequal(getDataSourceQueryKeyValues(object), valid.key_vals))

  ret_data <- getReferenceData(object)

  valid.ret_data <- valid.ret_data[colnames(ret_data)]

  expect_equal(unlist(Map(class, ret_data)), unlist(Map(class, valid.ret_data)))

  expect_equal(ret_data, valid.ret_data)

})

########################################################
#
# InstrumentBetasData Tests with different risk models
#
#########################################################

valid.risk_model      <- "RiskModel.DevelopedEuropePrototype150"

context(sprintf("Testing Instrument Betas Data with %s risk model", valid.risk_model))

tested.class          <-  "InstrumentBetasData"
valid.component       <- "Betas"

valid.risk_model_obj  <- new(valid.risk_model)
valid.model_factors   <- getRiskModelFactorNames(valid.risk_model_obj)
valid.model_prefix    <- getRiskModelPrefix(valid.risk_model_obj)
valid.lookback        <- getRiskModelLookback(valid.risk_model_obj)
# valid.column_name_map <- hash(c("Instrument", "InstrumentID"),
#                               c("InstrumentID","Instrument"))

valid.key_cols        <- c(risk_model_objectstore_keys, "InstrumentID")
valid.values          <- c("Date", "InstrumentID",
                           valid.model_factors)
valid.required_colnms <- c('Date', "InstrumentID",
                           valid.model_factors)

init.key_values       <-  data.frame(Date = as.Date(character()),
                                     InstrumentID = integer())



test_that(paste("Can create", tested.class, "object"), {
  object <- new(tested.class)
  object <- setRiskModelObject(object, valid.risk_model_obj)

  expect_is(object, tested.class)
})


test_that(paste("Can use basic accessors of ", tested.class, "object"), {

  object <- new(tested.class)
  object <- setRiskModelObject(object, valid.risk_model_obj)


  expect_is(object, tested.class)

  expect_equal(getRiskModelComponentName(object), valid.component)

  expect_equal(getRiskModelName(object), valid.model_prefix)

  expect_is(getRiskModelObject(object), valid.risk_model)

  expect_equal(getRiskModelFactorNames(object), valid.model_factors)

  expect_equal(getRiskModelLookback(object), valid.lookback)

  expect_equal(getDataSourceQueryKeyColumnNames(object), valid.key_cols)

  expect_equal(getDataSourceReturnColumnNames(object), valid.values)

  expect_equal(getDataSourceQueryKeyValues(object), init.key_values)

  expect_equal(getDataSourceClientColumnNameMap(object), valid.column_name_map)


})


test_that("Cannot .setDataSourceQueryKeyValues with invalid data", {

  object <- new(tested.class)
  object <- setRiskModelObject(object, valid.risk_model_obj)

  expect_error(TE.RefClasses:::.setDataSourceQueryKeyValues(object, init.key_values),
               regexp = "Zero row query keys data.frame passed")



  invalid.key_values <- data.frame(lC = numeric(), dtD = as.Date(character()))

  expect_error(TE.RefClasses:::.setDataSourceQueryKeyValues(object, invalid.key_values),
               regexp = "Invalid column names of query keys passed")

  expect_equal(getDataSourceQueryKeyValues(object), init.key_values)

})


test_that("Can .setDataSourceQueryKeyValues with valid data", {

  object <- new(tested.class)
  object <- setRiskModelObject(object, valid.risk_model_obj)

  valid.key_vals <- data.frame(Date = seq(from = as.Date('2016-10-01'),
                                          to = as.Date('2016-10-03'),
                                          by = "1 day"),
                               InstrumentID = 4454
  )

  object <- TE.RefClasses:::.setDataSourceQueryKeyValues(object, valid.key_vals)

  expect_equal(getDataSourceQueryKeyValues(object), valid.key_vals)

})


test_that("Cannot dataRequest() with invalid key_values", {

  object <- new(tested.class)
  object <- setRiskModelObject(object, valid.risk_model_obj)

  invalid.key_values <- data.frame(InstrumentID = integer(),
                                   Date = as.Date(character()))

  expect_error(dataRequest(object, invalid.key_values),
               regexp = "Zero row query keys data.frame passed")



  invalid.key_values <- data.frame(lC = numeric(), dtD = as.Date(character()))

  expect_error(dataRequest(object, invalid.key_values),
               regexp = "Invalid column names of query keys passed")


  expect_equal(getDataSourceQueryKeyValues(object), init.key_values)

})


test_that("Generates empty data.frame when dataRequest() with nonexistent key_values", {

  object <- new(tested.class)
  object <- setRiskModelObject(object, valid.risk_model_obj)

  nexist.key_vals <- data.frame(InstrumentID = 1984,
                                Date = seq(from = as.Date('2016-06-01'),
                                           to = as.Date('2016-06-03'),
                                           by = "1 day"))
  diff <- setdiff(valid.required_colnms,valid.key_cols)

  valid.ret_data <- cbind(nexist.key_vals,data.frame(t(rep(NA,length(diff)))))

  colnames(valid.ret_data) <- c(colnames(nexist.key_vals), diff)


  object <- dataRequest(object, nexist.key_vals)

  var_names <- intersect(getRequiredVariablesNames(object), valid.required_colnms)

  expect_equal(var_names , valid.required_colnms)

  ret_data <- getReferenceData(object)

  valid.ret_data <- valid.ret_data[colnames(ret_data)]

  class_names <- Map(class, ret_data)

  setAs("numeric", "Date", function(from){as.Date(from)})

  cols <- colnames(valid.ret_data)
  valid.ret_data <- as.data.frame(lapply(seq(length(class_names)),
                                         function(x) {as(valid.ret_data[,x], class_names[[x]])}), stringsAsFactors = FALSE)

  colnames(valid.ret_data) <- cols

  expect_equivalent(ret_data, valid.ret_data)

})


test_that("Can dataRequest() with valid key_values", {

  skip_if_not(as.logical(Sys.getenv("R_TESTTHAT_RUN_LONG_TESTS", unset = "FALSE")))

  object <- new(tested.class)
  object <- setRiskModelObject(object, valid.risk_model_obj)

  # instruments with large ammount of events for these days
  # 5004 5793 6496 7703 8038 5826 5687 6002 6203
  # 6    6    7    7    7    8   11   11   12
  valid.key_vals <- expand.grid(InstrumentID = as.integer(c(5004, 5793, 6496, 7703, 8038, 5826, 5687, 6002, 6203)),
                                Date = seq(from = as.Date('2016-06-20'),
                                           to = as.Date('2016-06-23'),
                                           by = "1 day"))

  values <- getDataSourceReturnColumnNames(object)

  # create valid return data.frame
  start        <- min(valid.key_vals$Date)
  end          <- max(valid.key_vals$Date)
  rm_str       <- get_most_recent_model_objectstore(valid.model_prefix, end, valid.lookback)
  name         <- getID(rm_str)
  query_data   <- queryDailyRiskModelObjectStore(rm_str,name,valid.lookback,valid.component)
  query_data   <- getData(query_data)
  query_data   <- query_data[query_data$Date >= start & query_data$Date <= end, ]

  merge_keys   <- valid.key_vals

  # colnames(merge_keys) <- TE.RefClasses:::.translateDataSourceColumnNames(object, colnames(merge_keys))
  colnames(merge_keys) <- c("Instrument", "Date")

  valid.ret_data <- merge(query_data,
                          merge_keys[merge_keys$Date >= start & merge_keys$Date <= end, ], all.y = TRUE)

  colnames(valid.ret_data) <- TE.RefClasses:::.translateDataSourceColumnNames(object, colnames(valid.ret_data))

  rownames(valid.ret_data) <- seq(nrow(valid.ret_data))

  valid.ret_data <- arrange(valid.ret_data, InstrumentID, Date)

  object <- dataRequest(object, valid.key_vals)

  expect_true(setequal(getDataSourceQueryKeyColumnNames(object), colnames(valid.key_vals)))
  expect_true(setequal(getDataSourceQueryKeyValues(object), valid.key_vals))

  ret_data <- getReferenceData(object)

  valid.ret_data <- valid.ret_data[colnames(ret_data)]

  expect_equal(unlist(Map(class, ret_data)), unlist(Map(class, valid.ret_data)))

  expect_equal(ret_data, valid.ret_data)

})
