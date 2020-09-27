
function read_credit_spread_curves(dt::Date)

	url = "https://www.anbima.com.br/informacoes/curvas-debentures/CD-down.asp"
	headers = [
	    "Host" => "www.anbima.com.br"
	    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:80.0) Gecko/20100101 Firefox/80.0"
	    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
	    "Accept-Language" => "pt-BR,pt;q=0.8,en-US;q=0.5,en;q=0.3"
	    "Accept-Encoding" => "gzip, deflate, br"
	    "Content-Type" => "application/x-www-form-urlencoded"
	    "Origin" => "https://www.anbima.com.br"
	    "Connection" => "keep-alive"
	    "Referer" => "https://www.anbima.com.br/informacoes/curvas-debentures/default.asp"
	    "Upgrade-Insecure-Requests" => "1"
	]
	str_dt = Dates.format(dt, "dd%2Fmm%2Fyyyy")
	body = "escolha=2&Idioma=PT&saida=csv&Dt_Ref_Ver=20200918&Dt_Ref=$str_dt"

	r = HTTP.post(url, headers, body)
	response_date = _parse_date_credit_curve(r)
	@assert dt == response_date "Wrong date: expected $dt, got $response_date"

	response_body = String(r.body)
	@assert _has_data_credit_curve(response_body) "no credit spread data for date $dt"
	out = _parse_credit_curve_result(response_body)
	return out

end

function _has_data_credit_curve(str::String)
	spl = split(str, "\r\n")
	return length(spl) > 2
end

function _parse_date_credit_curve(r)
	d = Dict(r.headers)
	@assert haskey(d, "content-disposition") "response header must have content-disposition"
	m = match(r"\d{8}", d["content-disposition"])
	@assert m != nothing "invalid content-disposition"
	str_dt = String(m.match)

	return Date(str_dt, "ddmmyyyy")
end

function _parse_credit_curve_result(str::String)
	rates = _parse_credit_curve_rates(str)
	return rates
end

function _parse_credit_curve_rates(str::String)
	lines = split(str, "\r\n")
	vertices = Vector{Float64}()
	rate_aaa = Vector{Float64}()
	rate_aa  = Vector{Float64}()
	rate_a   = Vector{Float64}()
	for line in lines[3:end]
		if line != ""
			s = split(line, ";")
			push!(vertices, parse_value(Float64, s[1]))
			push!(rate_aaa, parse_value(Float64, s[2]))
			push!(rate_aa , parse_value(Float64, s[3]))
			push!(rate_a  , parse_value(Float64, s[4]))
		end
	end
	return Dict([
		"AAA" => [k => v/100 for (k,v) in zip(vertices, rate_aaa)]
		"AA" =>  [k => v/100 for (k,v) in zip(vertices, rate_aa)]
		"A" =>   [k => v/100 for (k,v) in zip(vertices, rate_a)]
	])
end
