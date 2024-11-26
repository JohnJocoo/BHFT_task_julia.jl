module lazy_dict

using yyjson_jll

include("values.jl")

using .values

mutable struct LazyDict <: AbstractDict{String, Any}
  obj::Ptr{Cvoid}
end

function Base.get(dict::LazyDict, key::String, default)
  val_ptr = @ccall libyyjson.yyjson_obj_getn(dict.obj::Ptr{Cvoid}, pointer(key)::Ptr{Cstring}, Csize_t(sizeof(key))::Csize_t)::Ptr{Cvoid}

  if val_ptr == C_NULL
    default
  end

  parse_value(val_ptr)
end
  
function Base.keys(dict::LazyDict)
  iter = YYJSONObjIter(0, 0, C_NULL)
  (@ccall libyyjson.yyjson_obj_iter_init(dict.obj::Ptr{Cvoid}, pointer_from_objref(iter)::Ptr{YYJSONObjIter})::Bool) || error("Failed to initialize object iterator")
  keys = Vector{String}()
  while true
    key_ptr = @ccall libyyjson.yyjson_obj_iter_next(pointer_from_objref(iter)::Ptr{YYJSONObjIter})::Ptr{Cvoid}
    key_ptr == C_NULL && break
    push!(keys, value_to_string(key_ptr))
  end
  keys
end

export LazyDict
  
end