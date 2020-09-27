
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
