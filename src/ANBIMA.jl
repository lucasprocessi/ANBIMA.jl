module ANBIMA

using HTTP
using Dates
using BusinessDays

include("types.jl")
include("IMA.jl")
include("IDA.jl")
include("ettj.jl")

function parse_value(T::Type, x::String)
    if x == "--"
        return nothing
    end
    return parse(T, replace(replace(x, r"\." => ""), r"," => "."))
end

parse_value(T::Type, x::SubString{String}) = parse_value(T, String(x))

end # module
