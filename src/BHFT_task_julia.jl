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

println("Benchmarking YYJSON parser")
@btime YYJSON.parse_json($str_json)
println(YYJSON.parse_json(str_json)["symbols"][2]["status"])
println("")
println("Benchmarking original JSON parser")
@btime json_original.parse_json($str_json)
println(json_original.parse_json(str_json)["symbols"][2]["status"])
println("")
println("Benchmarking my JSON parser")
@btime json.parse_json($str_json)
println(json.parse_json(str_json)["symbols"][2]["status"])

#Profile.clear()
#@profile for i in (1:100) json.parse_json(str_json) end
#pprof()

versioninfo()
