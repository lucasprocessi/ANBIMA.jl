
### UTILS
FloatOrNothing = Union{Float64, Nothing}
IntOrNothing = Union{Int64, Nothing}

### IDA
struct IDA
    name::String # Index Name
    date::Date    # Date
    index::Float64 # Index
    return_1d::FloatOrNothing # 1 Day (%)
    return_month_to_date::FloatOrNothing # Month-to-Date (%)
    return_year_to_date::FloatOrNothing # Year-to-Date (%)
    return_12_months::FloatOrNothing # 12-Months (%)
    return_24_months::FloatOrNothing # 24-Months (%)
    duration::IntOrNothing # Duration (business day)
    weight::FloatOrNothing # Weight (%)
    market_value::FloatOrNothing # Portifolio at Market Value (R$ thousand)
end

struct IDAResult
    elements::Dict{String, IDA}
end

function IDAResult(v::Vector{IDA})
    d = Dict([x.name => x for x in v])
    return IDAResult(d)
end

Base.getindex(x::IDAResult, i::String) = getindex(x.elements, i)
Base.keys(x::IDAResult) = keys(x.elements)

### IMA
struct IMA
    name::String # Index Name
    date::Date    # Date
    index::Float64 # Index
    return_1d::FloatOrNothing # 1 Day (%)
    return_month_to_date::FloatOrNothing # Month-to-Date (%)
    return_year_to_date::FloatOrNothing # Year-to-Date (%)
    return_12_months::FloatOrNothing # 12-Months (%)
    return_24_months::FloatOrNothing # 24-Months (%)
    weight::FloatOrNothing # Weight (%)
    duration::FloatOrNothing # Duration (business day)
    market_value::FloatOrNothing # Portifolio at Market Value (R$ thousand)
    number_of_trades::IntOrNothing # Number of Trades *
    amount_traded_1000_bonds::FloatOrNothing # Amount Traded (1,000 bonds)
    amount_traded_thousand_BRL::FloatOrNothing # Amount Traded (R$ thousand)
    pmr::FloatOrNothing # PMR
    convexity::FloatOrNothing # Convexidade
    yield::FloatOrNothing # Yield
    redemption_yield::FloatOrNothing # Redemption Yield
end

struct IMAResult
    elements::Dict{String, IMA}
end

function IMAResult(v::Vector{IMA})
    d = Dict([x.name => x for x in v])
    return IMAResult(d)
end

Base.getindex(x::IMAResult, i::String) = getindex(x.elements, i)
Base.keys(x::IMAResult) = keys(x.elements)

struct SvenssonCurve
    β1::Float64
    β2::Float64
    β3::Float64
    β4::Float64
    λ1::Float64
    λ2::Float64
end

"Zero rates for a SvenssonCurve. `t` in business days. Returns 0.1 for a 10% p.a. rate."
function zerorate(cv::SvenssonCurve, t::Int64)::Float64
    β1 = cv.β1
    β2 = cv.β2
    β3 = cv.β3
    β4 = cv.β4
    λ1 = cv.λ1
    λ2 = cv.λ2
    τ = t/252
    return (
        β1 +
        β2 *  (1-exp(-λ1*τ)) / (λ1*τ) +
        β3 * ((1-exp(-λ1*τ)) / (λ1*τ) - exp(-λ1*τ)) +
        β4 * ((1-exp(-λ2*τ)) / (λ2*τ) - exp(-λ2*τ))
    )
end

struct NelsonSiegelCurve
    β1::Float64
    β2::Float64
    β3::Float64
    λ::Float64
end

function zerorate(cv::NelsonSiegelCurve, t::Int64)::Float64
    β1 = cv.β1
    β2 = cv.β2
    β3 = cv.β3
    λ = cv.λ
    τ = t/252
    return (
        β1 +
        β2 *  (1-exp(-λ*τ)) / (λ*τ) +
        β3 * ((1-exp(-λ*τ)) / (λ*τ) - exp(-λ*τ))
    )
end
