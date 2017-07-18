# ONS

[![Build Status](https://travis-ci.org/ZacLN/ONS.jl.svg?branch=master)](https://travis-ci.org/ZacLN/ONS.jl)

[![Coverage Status](https://coveralls.io/repos/ZacLN/ONS.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ZacLN/ONS.jl?branch=master)

[![codecov.io](http://codecov.io/github/ZacLN/ONS.jl/coverage.svg?branch=master)](http://codecov.io/github/ZacLN/ONS.jl?branch=master)
## Exported functions
### `search_datasets(q, start = 0)`
Search for timeseries on string `q`, returns 100 results. For the next page of 100 results increase `start`. Returns a `Record` of `MetaData` objects whose items can be selected using array access.

### `get_data(md::MetaData)`
Returns a `Data` object whose data can be accessed at `:yearly`, `:quarterly` or `:monthly` where available.


## Example
```
using ONS
md = search_datasets("8102000200")
ts = get_timeseries(md[1])
```

`display(md)`
```
Total items: 1
Displaying: 1:50

1.
8102000200: Processed & Preserved Fish, Crustaceans & Molluscs - Non EU Imports
  dataset    : MM22
  timeseries : K3G9
```
`display(ts)`
```
"8102000200: Processed & Preserved Fish, Crustaceans & Molluscs - Non EU Imports"
  Annual data from 1998 to 2016
  Quarterly data from 1998:Q1 to 2017:Q2
  Quarterly data from 1996:January to 2017:June
```

`ts[:monthly]`
```
258-element Array{Float64,1}:
   0.0
   0.0
   0.0
   0.0
   0.0
   ⋮
 150.9
 153.0
 151.5
 155.1
 156.7
```

