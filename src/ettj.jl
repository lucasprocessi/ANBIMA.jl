
function read_ettj(dt::Date)
	url = "https://www.anbima.com.br/informacoes/est-termo/CZ-down.asp"
	header = [
	    "Host" => "www.anbima.com.br"
	    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:80.0) Gecko/20100101 Firefox/80.0"
	    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
	    "Accept-Language" => "pt-BR,pt;q=0.8,en-US;q=0.5,en;q=0.3"
	    "Accept-Encoding" => "gzip, deflate, br"
	    "Content-Type" => "application/x-www-form-urlencoded"
	    "Origin" => "https://www.anbima.com.br"
	    "Connection" => "keep-alive"
	    "Referer" => "https://www.anbima.com.br/informacoes/est-termo/default.asp"
	    "Upgrade-Insecure-Requests" => "1"
	]
	str_dt = Dates.format(dt, "dd%2Fmm%2Fyyyy")
	body = "Idioma=PT&Dt_Ref=$str_dt&saida=csv"
	r = HTTP.post(url, header, body)

    response_body = String(r.body)
    @assert _has_data_ettj(response_body) "no ETTJ data for date $dt"
    filedate, out = _parse_ettj_result(response_body)
    @assert dt == filedate "Wrong date: expected $dt, got $filedate"
    return out
end

function _has_data_ettj(str::String)
	out = split(str, "\r\n")
	return length(out) >= 3
end

function _parse_ettj_result(str::String)
	out = split(str, "\r\n")
	date = _parse_ettj_date(String(out[1]))
	cvpre = _parse_ettj_parameters(String(out[2]))
	cvipca = _parse_ettj_parameters(String(out[3]))
	return date, Dict([cvpre, cvipca])
end

struct SvenssonCurve
	β1::Float64
	β2::Float64
	β3::Float64
	β4::Float64
	λ1::Float64
	λ2::Float64
end

function _parse_ettj_date(line::String)::Date
	s = split(line, ";")
	return Date(String(s[1]), "dd/mm/yyyy")
end

function _parse_ettj_parameters(line::String)::Pair{String, SvenssonCurve}
	s = split(line, ";")
	@assert length(s) == 7 "bad ettj csv: expected 7 columns, got $(length(s))"
	name = String(s[1])
	cv = SvenssonCurve(
		parse_value(Float64, s[2]),
		parse_value(Float64, s[3]),
		parse_value(Float64, s[4]),
		parse_value(Float64, s[5]),
		parse_value(Float64, s[6]),
		parse_value(Float64, s[7])
	)
	return (name => cv)
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
