using EasyCurl
using BenchmarkTools

using Profile
using PProf

include("json_original.jl")
include("json.jl")

import .json_original
import .json
import YYJSON

req = curl_get("https://api.binance.com/api/v3/exchangeInfo")
str_json = String(req.body)

#println("Bencmarking YYJSON parser")
#@btime YYJSON.parse_json($str_json)
#println("")
println("Bencmarking original JSON parser")
@btime json_original.parse_json($str_json)
println("")
println("Bencmarking my JSON parser")
@btime json.parse_json($str_json)

#Profile.clear()
#@profile for i in (1:100) json.parse_json(str_json) end
#pprof()

versioninfo()
