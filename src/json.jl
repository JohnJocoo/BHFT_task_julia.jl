module json

using yyjson_jll

include("json/lazy_dict.jl")

using .lazy_dict

function parse_json(json::String)
  size = Csize_t(sizeof(json))
  data_ptr = pointer(json)
  doc_ptr = ccall((:yyjson_read_opts, libyyjson), Ptr{Nothing}, (Ptr{UInt8}, Csize_t, UInt32, Ptr{Cvoid}, Ptr{Cvoid}), data_ptr, size, 0, C_NULL, C_NULL)
  doc_ptr == C_NULL && error("Error reading JSON")

  free_doc = function (_)
    @ccall libyyjson.yyjson_doc_free(doc_ptr::Ptr{Cvoid})::Cvoid
  end

  root = @ccall libyyjson.yyjson_doc_get_root(doc_ptr::Ptr{Cvoid})::Ptr{Cvoid}
  result = LazyDict(root)
  finalizer(free_doc, result)
  result
end

end
