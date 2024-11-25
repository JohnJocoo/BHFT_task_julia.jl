module json

using yyjson_jll
using InlineStrings

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

function parse_json(json::String)
    size = Csize_t(sizeof(json))
    data_ptr = pointer(json)
    #dynamic_allocator = ccall((:yyjson_alc_dyn_new, libyyjson), Ptr{Cvoid}, (),)
    doc_ptr = ccall((:yyjson_read_opts, libyyjson), Ptr{Nothing}, (Ptr{UInt8}, Csize_t, UInt32, Ptr{Cvoid}, Ptr{Cvoid}), data_ptr, size, 0, C_NULL, C_NULL)
    doc_ptr == C_NULL && error("Error reading JSON")
    root = ccall((:yyjson_doc_get_root, libyyjson), Ptr{Cvoid}, (Ptr{Cvoid},), doc_ptr)
    result = parse_value(root)
    ccall((:yyjson_doc_free, libyyjson), Cvoid, (Ptr{Cvoid},), doc_ptr)
    #ccall((:yyjson_alc_dyn_free, libyyjson), Cvoid, (Ptr{Cvoid},), dynamic_allocator)
    result
end

function parse_value(ptr::Ptr{Cvoid})
    if ccall((:yyjson_is_str, libyyjson), Bool, (Ptr{Cvoid},), ptr)
        value_to_string(ptr)
    elseif ccall((:yyjson_is_num, libyyjson), Bool, (Ptr{Cvoid},), ptr)
        ccall((:yyjson_get_num, libyyjson), Float64, (Ptr{Cvoid},), ptr)
    elseif ccall((:yyjson_is_bool, libyyjson), Bool, (Ptr{Cvoid},), ptr)
        ccall((:yyjson_get_bool, libyyjson), Bool, (Ptr{Cvoid},), ptr)
    elseif ccall((:yyjson_is_obj, libyyjson), Bool, (Ptr{Cvoid},), ptr)
        parse_object(ptr)
    elseif ccall((:yyjson_is_arr, libyyjson), Bool, (Ptr{Cvoid},), ptr)
        parse_array(ptr)
    else
        nothing
    end
end

function parse_object(obj_ptr::Ptr{Cvoid})
    iter = YYJSONObjIter(0, 0, C_NULL)
    ccall((:yyjson_obj_iter_init, libyyjson), Bool, (Ptr{Cvoid}, Ptr{YYJSONObjIter}), obj_ptr, pointer_from_objref(iter)) || error("Failed to initialize object iterator")
    dict = Dict{AbstractString,Any}()
    while true
        key_ptr = ccall((:yyjson_obj_iter_next, libyyjson), Ptr{Cvoid}, (Ptr{YYJSONObjIter},), pointer_from_objref(iter))
        key_ptr == C_NULL && break
        key = value_to_string(key_ptr)
        val_ptr = ccall((:yyjson_obj_iter_get_val, libyyjson), Ptr{Cvoid}, (Ptr{Cvoid},), key_ptr)
        dict[key] = parse_value(val_ptr)
    end
    dict
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
    size = @ccall libyyjson.yyjson_get_len(ptr::Ptr{Cvoid})::Csize_t
    c_string = @ccall libyyjson.yyjson_get_str(ptr::Ptr{Cvoid})::Ptr{UInt8}
    if size > 15
        unsafe_string(c_string, size)
    else  
        String15(c_string, size)
    end
end

end
