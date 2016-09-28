context("Test PPMOdel Objectstore")

#############################
#
# Test PPModelObjectStore
#
#############################
tested.class <- "PPModelObjectStore"

valid.key  <- data.frame(model_class = "TradeHistorySimpleWithSummary",
                         id          = 11L,
                         start       = as.Date("2016-03-29"),
                         end         = as.Date("2016-04-01"))

valid.name <- get_ppmodel_objectstore_name(valid.key)
valid.key2  <- TE.DataAccess:::key_from_ppmodel_objectstore_name(valid.name)

test_that("Key generators are working properly", {
  expect_equivalent(valid.key, valid.key2)
})


test_that("Can move local objectstore files to Blob Objectstore", {

  skip_if_not(as.logical(Sys.getenv("R_TESTTHAT_RUN_LONG_TESTS", unset = "FALSE")))
  skip_if_not(FALSE)

  object <- TE.DataAccess:::update_ppmodel_remote_storage()

})


test_that("Can call ppmodel_objectstore_factory() with locally existing file", {

  object <- ppmodel_objectstore_factory(valid.name)

  expect_is(object, tested.class)

})

test_that("Can check for keys in remote store() ", {

  object <- ppmodel_objectstore_factory(valid.name)

  expect_is(object, tested.class)

  query <- getObjectStoreQuery(object)
  expect_is(query, "RemotePPModelQuery")

  local.key <- TE.DataAccess:::hashKey(query,valid.key)


  is_known <- TE.DataAccess:::isKeyKnown(query, local.key)
  expect_true(is_known)

  is_known <- TE.DataAccess:::isKeyKnownInLocalStore(query, local.key)
  expect_true(is_known)

  is_known <- TE.DataAccess:::isKeyKnownInRemoteStore(query, valid.key)
  expect_true(is_known)

})


test_that("Can check for keys in remote store() ", {

  skip_if_not(as.logical(Sys.getenv("R_TESTTHAT_RUN_LONG_TESTS", unset = "FALSE")))

  object <- ppmodel_objectstore_factory(valid.name)

  expect_is(object, tested.class)

  query <- getObjectStoreQuery(object)
  expect_is(query, "RemotePPModelQuery")

  local.key <- TE.DataAccess:::hashKey(query,valid.key)


  is_known <- TE.DataAccess:::isKeyKnown(query, local.key)
  expect_true(is_known)

  is_known <- TE.DataAccess:::isKeyKnownInLocalStore(query, local.key)
  expect_true(is_known)

  ret <- TE.DataAccess:::removeObjectFromRemoteStore(object)
  expect_true(ret %in% c(-1,0))

  is_known <- TE.DataAccess:::isKeyKnownInRemoteStore(query, valid.key)
  expect_false(is_known)

  ret <- TE.DataAccess:::saveObjectInRemoteStore(object)
  expect_true(ret)

  is_known <- TE.DataAccess:::isKeyKnownInRemoteStore(query, valid.key)
  expect_true(is_known)

})


test_that("Can load warehouse from remote store() ", {

  skip_if_not(as.logical(Sys.getenv("R_TESTTHAT_RUN_LONG_TESTS", unset = "FALSE")))

  object <- new(tested.class, valid.name)
  expect_is(object, tested.class)

  query <- getObjectStoreQuery(object)
  expect_is(query, "RemotePPModelQuery")

  local.key <- TE.DataAccess:::hashKey(query,valid.key)

  valid.path <- TE.DataAccess:::getPath(object)

  expect_true(file.exists(valid.path))

  expect_true(file.remove(valid.path))

  expect_false(file.exists(valid.path))

  object <- ppmodel_objectstore_factory(valid.name)

  expect_is(object, tested.class)

  query <- getObjectStoreQuery(object)
  expect_is(query, "RemotePPModelQuery")

  local.key <- TE.DataAccess:::hashKey(query,valid.key)


  is_known <- TE.DataAccess:::isKeyKnown(query, local.key)
  expect_true(is_known)

  is_known <- TE.DataAccess:::isKeyKnownInLocalStore(query, local.key)
  expect_true(is_known)

  is_known <- TE.DataAccess:::isKeyKnownInRemoteStore(query, valid.key)
  expect_true(is_known)


  ret <- TE.DataAccess:::removeObjectFromRemoteStore(object)
  expect_true(ret %in% c(-1,0))

  is_known <- TE.DataAccess:::isKeyKnownInRemoteStore(query, valid.key)
  expect_false(is_known)

  ret <- TE.DataAccess:::saveObjectInRemoteStore(object)
  expect_true(ret)

  is_known <- TE.DataAccess:::isKeyKnownInRemoteStore(query, valid.key)
  expect_true(is_known)

})


