module ONS

using JSON, HTTP
import Base:empty

struct Contact
    email::String
    name::String
    telephone::String
end
Contact(d::Dict) = Contact(
    get(d, "email", ""), 
    get(d, "name", ""), 
    get(d, "telephone", "")
)

struct MetaDataDescription
    title::String
    summary::String
    keywords::Vector{String}
    metaDescription::String
    nationalStatistics::Bool
    contact::Contact
    releaseDate::String
    nextRelease::String
    edition::String
    datasetId::String
    datasetUri::String
    cdid::String
    unit::String
    preUnit::String
    source::String
    date::String
    number::String
    keyNote::String
    sampleSize::String
end
MetaDataDescription(d::Dict) = MetaDataDescription(
    get(d, "title", ""), 
    get(d, "summary", ""), 
    get(d, "keywords", []), 
    get(d, "metaDescription", ""), 
    get(d, "nationalStatistics", false), 
    haskey(d, "contact") ? Contact(d["contact"]) : empty(Contact),
    get(d, "releaseDate", ""),     
    get(d, "nextRelease", ""),
    get(d, "edition", ""), 
    get(d, "datasetId", ""), 
    get(d, "datasetUri", ""), 
    get(d, "cdid", ""), 
    get(d, "unit", ""), 
    get(d, "preUnit", ""), 
    get(d, "source", ""), 
    get(d, "date", ""), 
    get(d, "number", ""), 
    get(d, "keyNote", ""), 
    get(d, "sampleSize", "")
)

struct MetaData
    uri::String
    typ::String
    description::MetaDataDescription
    searchBoost::Vector{String}
end
MetaData(d::Dict) = MetaData(
    get(d, "uri", ""),
    get(d, "type", ""),
    haskey(d, "description") ? MetaDataDescription(d["description"]) : empty(MetaDataDescription),
    get(d, "searchBoost", String[])
)
function Base.display(r::MetaData)
    !isempty(r.description.title) ? println(r.description.title) : println("No title")
    println("  dataset    : ", r.description.datasetId)
    println("  timeseries : ", r.description.cdid)
    println()
end

function Base.display(R::Vector{MetaData})
    for (i, r) in enumerate(R)
        println("$i.")
        display(r)
        println()
    end
end

struct Records
    items::Vector{MetaData}
    itemsPerPage::Int
    startIndex::Int
    totalItems::Int
end
Records(d::Dict) = Records(
    haskey(d, "items") ? MetaData.(d["items"]) : MetaData[],
    get(d, "itemsPerPage", typemin(Int)),
    get(d, "startIndex", typemin(Int)),
    get(d, "totalItems", typemin(Int))
)

function Base.display(R::Records)
    println("Total items: ", R.totalItems)
    println("Displaying: ", R.startIndex .+ (1:R.itemsPerPage))
    println()
    display(R.items)
end
Base.getindex(R::Records, i) = R.items[i]

struct Period
    date::String
    value::String
    label::String
    year::String
    month::String
    quarter::String
    sourceDataset::String
    updateDate::String
end
Period(d::Dict) = Period(
    get(d, "date", ""),
    get(d, "value", ""),
    get(d, "label", ""),
    get(d, "year", ""),
    get(d, "month", ""),
    get(d, "quarter", ""),
    get(d, "sourceDataset", ""),
    get(d, "updateDate", "")
)

struct Version
    uri::String
    updateDate::String
    correctionNotice::String
    label::String
end
Version(d::Dict) = Version(
    get(d, "uri", ""),
    get(d, "updateDate", ""),
    get(d, "correctionNotice", ""),
    get(d, "label", ""),
)

struct DataSetRef
    uri::String
end
DataSetRef(d::Dict) = DataSetRef(get(d, "uri", ""))

struct Data
    years::Vector{Period}
    quarters::Vector{Period}
    months::Vector{Period}
    relatedDataset::Vector{DataSetRef}
    relatedDocuments::Vector{DataSetRef}
    relatedData::Vector{DataSetRef}
    versions::Vector{Version}
    typ::String
    uri::String
    description::MetaDataDescription
end
Data(d::Dict) = Data(
    haskey(d, "years") ? Period.(d["years"]) : [],
    haskey(d, "quarters") ? Period.(d["quarters"]) : [],
    haskey(d, "months") ? Period.(d["months"]) : [],
    haskey(d, "relatedDataset") ? DataSetRef.(d["relatedDataset"]) : [],
    haskey(d, "relatedDocuments") ? DataSetRef.(d["relatedDocuments"]) : [],
    haskey(d, "relatedData") ? DataSetRef.(d["relatedData"]) : [],
    haskey(d, "versions") ? Version.(d["versions"]) : [],
    get(d, "type", ""),
    get(d, "uri", ""),
    haskey(d, "description") ? MetaDataDescription(d["description"]) : empty(MetaDataDescription),
)

function Base.display(d::Data)
    display(d.description.title)
    if !isempty(d.years)
        println("  Annual data from $(first(d.years).year) to $(last(d.years).year)")
    end
    if !isempty(d.quarters)
        println("  Quarterly data from $(first(d.quarters).year):$(first(d.quarters).quarter) to $(last(d.quarters).year):$(last(d.quarters).quarter)")
    end
    if !isempty(d.months)
        println("  Monthly data from $(first(d.months).year):$(first(d.months).month) to $(last(d.months).year):$(last(d.months).month)")
    end
end

function Base.getindex(d::Data, freq::Symbol)
    if freq == :yearly
        return [parse(x.value) for x in d.years]
    elseif freq == :years
        return [parse(x.year) for x in d.years]
    elseif freq == :quarterly
        return [parse(x.value) for x in d.quarters]
    elseif freq == :quarterly
        return [parse(x.value) for x in d.quarters]
    elseif freq == :monthly
        return [parse(x.value) for x in d.months]
    else
        return Float64[]
    end
end

empty(::Type{Int}) = typemin(Int)
empty(::Type{Bool}) = false
empty(::Type{String}) = ""
empty(::Type{Vector{T}}) where T = T[]

for t in (Records, MetaData, Contact, MetaDataDescription, Period, Version, Data)
    tn = split("$t",".")[end]
    sig = :(empty(::Type{$t}))
    body = :($(Symbol(tn))()) #Had to change this so it only gives the last part of the type otherwise it can't find the method
    for (fname,ftype) in zip(fieldnames(t),fieldtypes(t)) 
        push!(body.args, :(empty($ftype)))
    end
    @eval $sig = $body
end

#endpoints


"""
    getjson(command,parameters)
Access the ONS API
"""
function getjson(command,parameters=nothing)
    url = "https://api.ons.gov.uk/"
    r = HTTP.request("GET",url*command,query=parameters)
    @info url*r.request.target
    JSON.parse(String(r.body))
end

"""
    list_datasets(start=0, limit=100)
List the datasets from ONS.
This is unlikely to be useful since there are 9000+ datasets.
Many of them don't return a readable description and just a uri to the ONS page.
"""
function list_datasets(start=0, limit=100)
    parameters = Dict(
        "start" => start,
        "limit" => limit
    )
    Records(getjson("dataset",parameters))
end

"""
    list_timeseries(start=0, limit=100)
List the datasets from ONS.
Although this returns 53,000+ records, it is more useful than list_datasets
since it returns descriptions as well as the dataset and timeseries codes
which can be used to retrieve the data with `get_data`.
"""
function list_timeseries(start=0, limit=100)
    parameters = Dict(
        "start" => start,
        "limit" => limit
    )
    Records(getjson("timeseries",parameters))
end

"""
    search_timeseries(q, start=0, limit=100)
This is the most useful for finding the timeseries you need.
The search query `q` is important to narrow down the results.
"""
function search_timeseries(q, start=0, limit=100)
    parameters = Dict(
        "q" => q,
        "start" => start,
        "limit" => limit
    )
    Records(getjson("search",parameters))
end

"""
    get_dataset(dataset)
Can be used to get a list of the timeseries from a dataset name
"""
get_dataset(dataset) = Records(getjson("dataset/$dataset/timeseries"))
function get_dataset(md::MetaData)
    if !isempty(md.description.datasetId)
        get_dataset(md.description.datasetId)
    else
        error("No datasetId found")
    end
end

"""
    get_data(dataset,timeseries)
Given a dataset and timeseries, is used to get the data which returns months, quarters and years
as well as all of the metadata.
"""
get_data(dataset,timeseries) = Data(getjson("dataset/$dataset/timeseries/$timeseries/data"))
function get_data(md::MetaData)
    dataset = md.description.datasetId
    timeseries = md.description.cdid
    get_data(dataset,timeseries)
end

export search_timeseries, list_datasets, list_timeseries, get_dataset, get_data

end
