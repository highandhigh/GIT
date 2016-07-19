sourceTo("../lib/sockets.r", modifiedOnly = getOption("modifiedOnlySource"), local = FALSE)

#1. Start the engine by excuting ../engine/engine_service_main.r within a 
#   sepatate process. 

#2. Run the following:
client_emulation <- new("ProcessSocket",server=FALSE)
client_emulation <- openConnection(client_emulation)
client_emulation <- writeToConnection(client_emulation,"TEST")
client_emulation <- readConnection(client_emulation)
test_data <- getData(client_emulation)
message(paste("Got:",test_data))

#3. Test getting analysis data
client_emulation <- writeToConnection(client_emulation,"SETTRADER|11")
client_emulation <- readConnection(client_emulation)
resp <- getData(client_emulation)
message(paste("Got:",resp))
client_emulation <- writeToConnection(client_emulation,paste("SETDATE|",as.character(Sys.Date()),sep=""))
client_emulation <- readConnection(client_emulation)
resp <- getData(client_emulation)
message(paste("Got:",resp))
client_emulation <- writeToConnection(client_emulation,"SETLOOKBACK|dated_three_monthly_lookback")
client_emulation <- readConnection(client_emulation)
resp <- getData(client_emulation)
message(paste("Got:",resp))
client_emulation <- writeToConnection(client_emulation,"SETMODULE|ResultsDayPsnModule")
client_emulation <- readConnection(client_emulation)
resp <- getData(client_emulation)
message(paste("Got:",resp))
client_emulation <- writeToConnection(client_emulation,"GETANALYSISDATA")
client_emulation <- readConnection(client_emulation)
resp <- getData(client_emulation)
message(paste("Got:",resp))
client_emulation <- readConnection(client_emulation)
data <- getData(client_emulation)
message(paste("Got:",data))
client_emulation <- writeToConnection(client_emulation,"GOT")
client_emulation <- writeToConnection(client_emulation,"STOP")
client_emulation <- closeConnection(client_emulation)