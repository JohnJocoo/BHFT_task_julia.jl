module values

using yyjson_jll

mutable struct YYJSONArrIter
  idx::Csize_t
  max::Csize_t
  cur::Ptr{Cvoid}
end

mutable struct YYJSONObjIter
  idx::Csize_t
  max::Csize_t
  cur::Ptr{Cvoid}
end

function parse_value(ptr::Ptr{Cvoid})
  if @ccall libyyjson.yyjson_is_str(ptr::Ptr{Cvoid})::Bool
      value_to_string(ptr)
  elseif @ccall libyyjson.yyjson_is_num(ptr::Ptr{Cvoid})::Bool
      @ccall libyyjson.yyjson_get_num(ptr::Ptr{Cvoid})::Float64
  elseif @ccall libyyjson.yyjson_is_bool(ptr::Ptr{Cvoid})::Bool
      @ccall libyyjson.yyjson_get_bool(ptr::Ptr{Cvoid})::Bool
  elseif @ccall libyyjson.yyjson_is_obj(ptr::Ptr{Cvoid})::Bool
      parse_object(ptr)
  elseif @ccall libyyjson.yyjson_is_arr(ptr::Ptr{Cvoid})::Bool
      parse_array(ptr)
  else
      nothing
  end
end

function parse_object(obj_ptr::Ptr{Cvoid})
  Main.json.lazy_dict.LazyDict(obj_ptr)
end

function parse_array(arr_ptr::Ptr{Cvoid})
  iter = YYJSONArrIter(0, 0, C_NULL)
  ccall((:yyjson_arr_iter_init, libyyjson), Bool, (Ptr{Cvoid}, Ptr{YYJSONArrIter}), arr_ptr, pointer_from_objref(iter)) || error("Failed to initialize array iterator")
  size = ccall((:yyjson_arr_size, libyyjson), Int64, (Ptr{Cvoid},), arr_ptr)
  array = Vector{Any}(undef, size) 
  for i in 1:size
      val_ptr = ccall((:yyjson_arr_iter_next, libyyjson), Ptr{Cvoid}, (Ptr{YYJSONArrIter},), pointer_from_objref(iter))
      val_ptr == C_NULL && break
      array[i] = parse_value(val_ptr)
  end
  array
end

function value_to_string(ptr::Ptr{Cvoid})
  unsafe_string(@ccall libyyjson.yyjson_get_str(ptr::Ptr{Cvoid})::Ptr{UInt8})
end

export YYJSONArrIter, YYJSONObjIter, parse_value, value_to_string

end