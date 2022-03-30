using ONS, Test

@test typeof(list_datasets()) == ONS.Records
@test typeof(list_timeseries()) == ONS.Records
@test typeof(search_datasets("RPI")) == ONS.Records
@test typeof(get_dataset("MM23")) == ONS.Records
@test typeof(get_data("MM23","CHAW")) == ONS.Data