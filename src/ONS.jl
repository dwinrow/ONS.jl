module ONS
using JSON, Requests

struct Contact
    email::String
    name::String
    telephone::String
end
Contact(d::Dict) = Contact(get(d, "email", ""), 
get(d, "name", ""), 
get(d, "telephone", ""))

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
    haskey(d, "contact") ? Contact(d["contact"]) :  empty(Contact),
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
    for r in R
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
    println("Displaying: ", R.startIndex + (1:R.itemsPerPage))
    println()
    display(R.items)
end


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

empty(::Type{Int}) = typemin(Int)
empty(::Type{Bool}) = false
empty(::Type{String}) = ""
empty(::Type{Vector{T}}) where T = T[]

for t in (Records, MetaData, Contact, MetaDataDescription, Period, Version, Data)
    sig = :(empty(::Type{$t}))
    body = :($(Symbol(t))())
    for i = 1:nfields(t)
        fname = fieldname(t, i)
        ftype = fieldtype(t, i)
        push!(body.args, :(empty($ftype)))
    end
    @eval $sig = $body
end

function list_datasets()
    req = get("https://api.ons.gov.uk/dataset")
    d = JSON.Parser.parse(String(req.data))
    return Records(d)
end

function list_timeseries(start = 0)
    req = get("https://api.ons.gov.uk/timeseries?start=$start&limit=100")
    d = JSON.Parser.parse(String(req.data))
    return Records(d)
end

function search_datasets(q)
    req = get("https://api.ons.gov.uk/search?q=$q")
    d = JSON.Parser.parse(String(req.data))
    return Records(d)
end





function get_dataset(q)
    req = get("https://api.ons.gov.uk/dataset/$q/timeseries")
    d = JSON.Parser.parse(String(req.data))
    return Records(d)
end
function get_dataset(md::MetaData)
    if !isempty(md.description.datasetId)
        get_dataset(md.description.datasetId)
    else
        error("No datasetId found")
    end
end

function get_timeseries(md::MetaData)
    dataset = md.description.datasetId
    timeseries = md.description.cdid
    req = get("https://api.ons.gov.uk/dataset/$dataset/timeseries/$timeseries/data")
    d = JSON.Parser.parse(String(req.data))
    return Data(d)
end

end
