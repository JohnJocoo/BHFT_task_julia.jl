# BHFT_task_julia
Task of improving Json parser.

## Results
```
Benchmarking YYJSON parser
  51.279 ms (1045947 allocations: 48.99 MiB)

Benchmarking original JSON parser
  57.286 ms (1079515 allocations: 49.51 MiB)

Benchmarking my JSON parser
  12.899 ms (2 allocations: 32 bytes)
```  

## Approach
In the end the only way I could significally reduce parcer time was to create custom lazy Dict that takes pointer yyjson value and adapts Julia's `AbstractDict` interface to yyjson calls. That way `parse_json(json::String)` returns immidiately after yyjson document is ready, leaving all yyjson -> Julia transformations for later. yyjson document is freed when root LazyDict is finalized. 

Another change that won a little time was changing `length(json)` to `sizeof(json)` in `parse_json(json::String)`. I assume yyjson is interested in number of bytes and not unicode codepoints.
