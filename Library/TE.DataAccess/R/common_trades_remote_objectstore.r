#' @include objectstore.r
#' @include global_configs.r
NULL

#' Generate Trade objectstore name from keys
#'
#' Creates Trade ObjectStore and loads data from
#' associated file if exists.
#'
#' @param keys "data.frame", keys from which name(s) of objectstore is created
#'
#' @export

get_trade_objectstore_name <- function(keys) {
  rv <- apply(keys, 1, function(x){paste0(c("trade_store", unlist(x)), collapse = "_")})
  return(rv)
}

#' helper function to generate key from objectstore name
#'
#' @param name "character" name of the objectstore
#' @return \code{key} "data.frame" with columns "id", "start", "end"
key_from_trade_objectstore_name <- function(name) {

  str_keys <- strsplit(name, "_")

  key <- data.frame(id          = str_keys[[1]][3],
                    instrument  = as.integer(str_keys[[1]][4]),
                    buysell     = str_keys[[1]][5],
                    strategy    = str_keys[[1]][6],
                    start       = as.Date(str_keys[[1]][7]),
                    end         = as.Date(str_keys[[1]][8]))

  return(key)
}


setClass(
  Class          = "VirtualTradeQuery",
  prototype = prototype(
    fields       = c('hash', 'id', 'instrument', 'buysell', 'strategy', 'start', 'end')
  ), contains = c("ObjectQuery", "VIRTUAL")
)

setMethod("hashKey",
          signature(object = "VirtualTradeQuery",
                    key    = "data.frame"),
          function(object,key){
            hash <- hash_data_frame(key[object@fields[2:7]], algo = "murmur32")
            hashedkey <- cbind(data.frame(hash=hash),key)
            return(hashedkey)
          }
)

setGeneric("setTradeQuery",function(object,key){standardGeneric("setTradeQuery")})
setMethod("setTradeQuery",
          signature(object = "VirtualTradeQuery",
                    key    = "data.frame"),
          function(object,key){
            hashedkey <- hashKey(object,key)
            object <- setQueryValuesFromKey(object,hashedkey)
            return(object)
          }
)

setGeneric("updateStoredTradeKeys",function(object,key){standardGeneric("updateStoredTradeKeys")})
setMethod("updateStoredTradeKeys",
          signature(object = "VirtualTradeQuery",
                    key    = "data.frame"),
          function(object,key){
            hashedkey <- hashKey(object,key)
            object <- updateKnownKeys(object,hashedkey)
            return(object)
          }
)

setGeneric("isTradeStored",function(object,key){standardGeneric("isTradeStored")})
setMethod("isTradeStored",
          signature(object = "VirtualTradeQuery",
                    key    = "data.frame"),
          function(object,key){

            if(length(object@known_keys)==0){
              rval <- FALSE
            }
            else{
              hash <- hash_data_frame(key[object@fields[2:7]], algo = "murmur32")

              rval <- hash%in%object@known_keys[['hash']]

            }
            return(rval)
          }
)




#' An S4 class handling queries to TradeObjectstore.
#'
#' @export

setClass(
  Class          = "TradeQuery",
  contains = c("VirtualTradeQuery")
)

#' An S4 class handling queries to WarehouseObjectstore.

setClass(
  Class = "RemoteTradeQuery",
  prototype = prototype(
    #fields need to match column names
    #of key data frame
    tb_name = "tRDTE_TradeObjectstore"
  ),
  contains =c("RemoteObjectQuery", "VirtualTradeQuery")
)

#' Initialize method for "RemoteTradeQuery" class
#'
#' @param .Object, object of class "RemoteTradeQuery"
#' @return \code{.Object} object of class "RemoteTradeQuery"
setMethod("initialize", "RemoteTradeQuery",
          function(.Object){
            sql_query <- new("BlobStorage.SQLProcedureCall.JointFileTable_QueryByHashID",
                             .getObjectQueryDBName(.Object),
                             .getObjectQuerySchemaName(.Object),
                             .getObjectQueryTableName(.Object))
            .Object <- setSQLQueryObject(.Object, sql_query)

            sql_insert <- new("BlobStorage.SQLProcedureCall.JointFileTable_UpdateByHashID",
                              .getObjectQueryDBName(.Object),
                              .getObjectQuerySchemaName(.Object),
                              .getObjectQueryTableName(.Object))
            .Object <- setSQLInsertObject(.Object, sql_insert)

            return(.Object)

          }
)

#' An S4 class implementing of Trade Objectstore.
#'
#' Implements storage, queries, and update of Trades
#' in an object and saving in related file.
#'
#' Inherits from "VirtualObjectStore"
#'
#' @slot objectstore_q      "TradeQuery"
#' @slot qry_store_nme    "character",
#'
#' @export

setClass(
  Class          = "TradeObjectStore",
  representation = representation(
    objectstore_q   = "VirtualTradeQuery",
    qry_store_nme   = "character"
  ),
  prototype      = prototype(
    objectstore_q  = new("RemoteTradeQuery"),
    qry_store_nme= "trade_queries"
  ),
  contains = c("VirtualRemoteObjectStore")
)


setMethod(".setObjectStoreQuery",
          signature( object = "VirtualRemoteObjectStore",
                     objectstore_q = "VirtualTradeQuery"),
          function(object, objectstore_q){

            # copy slots of Warehouse Query
            new_query <- new("RemoteTradeQuery")

            new_query@values <- objectstore_q@values
            new_query@known_keys <- objectstore_q@known_keys

            object <- callNextMethod(object, new_query)
            return(object)
          }
)


setMethod(".setObjectStoreQuery",
          signature( object = "VirtualRemoteObjectStore",
                     objectstore_q = "TradeQuery"),
          function(object, objectstore_q){

            # copy slots of Warehouse Query
            new_query <- new("RemoteTradeQuery")

            new_query@values <- objectstore_q@values
            new_query@known_keys <- objectstore_q@known_keys

            object <- callNextMethod(object, new_query)
            return(object)
          }
)




setMethod(".generateKeyFromID",
          signature( object = "TradeObjectStore"),
          function(object){

            id <- getID(object)

            name <- key_from_trade_objectstore_name(id)

            return(name)
          }
)


#' Initialize method for "TradeObjectStore" class
#'
#' @param .Object, object of class "TradeObjectStore"
#' @param id id to set when initializing
#' @return \code{.Object} object of class "TradeObjectStore"

setMethod("initialize", "TradeObjectStore",
          function(.Object,id){
            .Object@id <- id
            .Object@path <- tempdir()
            .Object
          }
)

setGeneric("initialiseTradeStore",function(object){standardGeneric("initialiseTradeStore")})
setMethod("initialiseTradeStore","TradeObjectStore",
          function(object){
            object <- loadObject(object)

            query <- getFromObjectStore(object,object@qry_store_nme)

            object <- .setObjectStoreQuery(object, query)
            return(object)
          }
)

#' Query store for Trade
#'
#' Querries Trade Objectstore for Trade stored under given key
#' Returns Trade if present NULL otherwise
#'
#' @param object object of class "TradeObjectStore"
#' @param key "data.frame" with key related to query
#' @return \code{rval} object of class "Trade"
#'
#' @export

setGeneric("queryTradeStore",function(object,key){standardGeneric("queryTradeStore")})

#' @describeIn queryTradeStore
#' Query store for Trade
#'
#' Querries Trade Objectstore for Trade stored under given key
#' Returns Trade if present NULL otherwise
#'
#' @inheritParams queryTradeStore
#' @return \code{rval} object of class "Trade"
#' @export

setMethod("queryTradeStore","TradeObjectStore",
          function(object,key){
            query <- getObjectStoreQuery(object)
            if(isTradeStored(query,key)){
              message(paste("Key",paste(unlist(Map(as.character,key)),collapse=", "),"found in ppmodel store."))
              query <- setTradeQuery(query,key)
              object <- .setObjectStoreQuery(object, query)
              name <- getIdentifier(query)
              rval <- getFromObjectStore(object,name)
            }
            else{
              message(paste("Key",paste(unlist(Map(as.character,key)),collapse=", "),"not found in ppmodel store."))
              rval <- NULL
            }

            return(rval)
          }
)

#' Store PPmodel in Store
#'
#' Stores Trade and reated Query in Store
#'
#' @param object object of class "TradeObjectStore"
#' @param ppmodel_object object of class "Trade"
#' @param key "data.frame" with key related to query
#' @param force "logical" force update of Trade if it is already present
#' @return \code{object} object of class "TradeObjectStore"
#'
#' @export

setGeneric("updateTradeStore",function(object,ppmodel_object,key,force=FALSE){standardGeneric("updateTradeStore")})


#' @describeIn updateTradeStore
#' Store PPmodel in Store
#'
#' Stores Trade and reated Query in Store
#'
#' @inheritParams updateTradeStore
#' @return \code{object} object of class "TradeObjectStore"
#' @export

setMethod("updateTradeStore","TradeObjectStore",
          function(object,ppmodel_object,key,force=FALSE){
            query <- getObjectStoreQuery(object)
            if(isTradeStored(query,key) && !force){
              message(paste("Key",paste(unlist(Map(as.character,key)),collapse=", "),"found in ppmodel store."))
              message("No update made.")
            }
            else{
              if(force)message("Force update flag set, data will be overwritten ...")
              message(paste("Updating ppmodel store for key",paste(unlist(Map(as.character,key)),collapse=", "),collapse=", "))
              query <- setTradeQuery(query,key)
              query <- updateStoredTradeKeys(query,key)

              object <- .setObjectStoreQuery(object, query)

              object <- placeInObjectStore(object,query,object@qry_store_nme)
              object <- placeInObjectStore(object,ppmodel_object,getIdentifier(query))
            }
            return(object)
          }
)


#' Commit store data to file
#'
#' Saves data stored in the object into file.
#'
#' @param object object of class "TradeObjectStore"
#' @return \code{object} object of class "TradeObjectStore"
#'
#' @export

setGeneric("commitTradeStore",function(object){standardGeneric("commitTradeStore")})

#' @describeIn commitTradeStore
#' Commit store data to file
#'
#' @inheritParams commitTradeStore
#' @return \code{object} object of class "TradeObjectStore"
#' @export

setMethod("commitTradeStore","TradeObjectStore",
          function(object){
            saveObject(object)
          }
)

setGeneric("getTradeStoreContents",function(object){standardGeneric("getTradeStoreContents")})
setMethod("getTradeStoreContents","TradeObjectStore",
          function(object){
            names <- getNamesFromStore(object)
            names <- names[names!=object@qry_store_nme]
            return(names)
          }
)

#' Create TradeObjectstore object
#'
#' Creates Trade ObjectStore and loads data from
#' associated file if exists.
#'
#' @param key "data.frame", with keys for trade
#' required keys are: c("id", "instrument", "buysell", "strategy", "legstart", "legend")
#'
#' @export

trade_objectstore_factory <- function(key){
  message("Initialising ppmodel store ...")

  name <- get_trade_objectstore_name(key)

  trdstr <- new("TradeObjectStore",id=name)

  pth <- getPath(trdstr)
  key <- key_from_ppmodel_objectstore_name(basename(pth))

  query <- getObjectstoreQuery(trdstr)
  is_known <- isKeyKnownInRemoteStore(query, key)

  if (is_known) {
    trdstr <- initialiseTradeStore(trdstr)
  }

  else{
    message(paste("No previous store data found at",pth,"new store created."))
  }
  return(trdstr)
}

#' Copy Trades from local objectstores to remote store.
#'
#' copies all locally stored ppmodels to remote store and updates keys
#'
#' @return \code{count} number of warehouses copied

update_trade_remote_storage <- function(){
  message("Generating list of existing stores...")
  pth <- model_defaults@data_path

  # list of all objectstore files
  rds.files <- list.files(pth, "ppmodel_store_.*_objectstore.rds")

  # function fo find the store
  wh.cond.fn <- function(x){
    name.el <- strsplit(x, "_")[[1]]
    if (length(name.el) != 7) return(FALSE)
    if (!grepl("^[0-9]+$", name.el[4], perl = TRUE)) return(FALSE)
    dates <- tryCatch({ as.Date(name.el[5:6])})
    if (!is.Date(dates)) return(FALSE)
    return(TRUE)
  }

  wh_str.files <- rds.files[sapply(rds.files, wh.cond.fn)]

  count <- 0
  for (name in wh_str.files) {

    name <- gsub("_objectstore.rds", "", name)

    whstr <- ppmodel_objectstore_factory(name)

    stored_name <- setdiff(getNamesFromStore(whstr), whstr@qry_store_nme)

    stored_name <- grep(gsub("ppmodel_store_", "", name), stored_name, value = TRUE)

    item <- tryCatch({
      getFromObjectStore(whstr, stored_name)
    }, error = function(cond) {

     browser()
    })

    new_whstr <- new("TradeObjectStore", id = name)

    key <- key_from_ppmodel_objectstore_name(name)

    new_whstr <- updateTradeStore(new_whstr, item, key, TRUE)

    saveObject(new_whstr)

    count <- count + 1

  }


  return(count)
}
