
function read_ettj(dt::Date)
	url = "https://www.anbima.com.br/informacoes/est-termo/CZ-down.asp"
	header = [
	    "Host" => "www.anbima.com.br"
	    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:80.0) Gecko/20100101 Firefox/80.0"
	    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
	    "Accept-Language" => "pt-BR,pt;q=0.8,en-US;q=0.5,en;q=0.3"
	    "Accept-Encoding" => "gzip, deflate, br"
	    "Content-Type" => "application/x-www-form-urlencoded"
	    #"Content-Length" => "71"
	    "Origin" => "https://www.anbima.com.br"
	    "Connection" => "keep-alive"
	    "Referer" => "https://www.anbima.com.br/informacoes/est-termo/default.asp"
	    #"Cookie" => "lumClientId=8A2AB290749450B201749709905D1504; lumMonUid=GB9v_UzD1CZbwjVzKKYvn0QTc3CJxsuf; __utma=234609614.893389923.1600261823.1600738371.1601057272.7; __utmz=234609614.1600707402.4.2.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); _ga=GA1.3.893389923.1600261823; _fbp=fb.2.1600261824060.1044754934; _hjid=67d810ba-8ef2-40f5-80d2-63d7dbac00b7; __trf.src=encoded_eyJmaXJzdF9zZXNzaW9uIjp7InZhbHVlIjoiMjM0NjA5NjE0LjE2MDAyNjE4MjMuMS4xLnV0bWNzcj1nb29nbGV8dXRtY2NuPShvcmdhbmljKXx1dG1jbWQ9b3JnYW5pY3x1dG1jdHI9KG5vdCBwcm92aWRlZCkiLCJleHRyYV9wYXJhbXMiOnt9fSwiY3VycmVudF9zZXNzaW9uIjp7InZhbHVlIjoiKG5vbmUpIiwiZXh0cmFfcGFyYW1zIjp7fX0sImNyZWF0ZWRfYXQiOjE2MDEwNTcyNzQwODB9; rdtrk=%7B%22id%22%3A%221d5766e6-4883-442c-930a-d1d22efb296f%22%7D; JSESSIONID=697B27C26AB85F97D299DCC7716A2321.LumisProdB; lumUserLocale=pt_BR; AWSELB=359F6F8906C702E7D2BBD3C04A400F8539C6D91FD2D3B672197D945A025B58D14C3BDEDC02D06CC72D836D42F801575BD9540092BD253DADEB8B0E4B5FA65E7C31CAC9DFA0D7DD645B8FE3F74949C2B5A404CDF59A; ASPSESSIONIDSETRADAS=EPAEDPMDCELBNKIFFAOBANCC; BIGipServerPool_ANBSPCLD-WEB02_SSL=204005386.47873.0000; __utmc=234609614; ASPSESSIONIDQERTABBS=AGIEBLJAIJCJIDFDMAGNJHIF; ADRUM=s=1600824064219&r=https%3A%2F%2Fwww.anbima.com.br%2Fpt_br%2Finformar%2Fcurvas-de-juros-fechamento.htm%3F0; ASPSESSIONIDQEQSACAS=MIMLNOPCEFHKDAAGGPIPKOIB; lumUserSessionId=B4tPso7KCTkjL1kYGbLSLm0DCrrLgz9h; lumUserName=Guest; lumIsLoggedUser=false; _gid=GA1.3.1033678900.1601057272; _gat_UA-18261922-22=1; _gat_UA-18261922-23=1; __utmb=234609614.2.10.1601057272; __utmt_UA-18261922-8=1; _dc_gtm_UA-18261922-14=1"
	    "Upgrade-Insecure-Requests" => "1"
	]
	str_dt = Dates.format(dt, "dd%2Fmm%2Fyyyy")
	body = "Idioma=PT&Dt_Ref=$str_dt&saida=csv"
	r = HTTP.post(url, header, body)

    response_body = String(r.body)
    filedate, out = _parse_ettj_result(response_body)
    @assert dt == filedate "Wrong date: expected $dt, got $filedate"
    return out
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
