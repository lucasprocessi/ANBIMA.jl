
function read_IMA(dt::Date)

    @assert BusinessDays.isbday(:BRSettlement, dt) "$dt should be a business day in Brazil"

    url = "https://www.anbima.com.br/informacoes/ima/ima-sh-down.asp"
    str_dt = Dates.format(dt, "dd%2Fmm%2Fyyyy")

    header = [
        # POST /informacoes/ima/ima-sh-down.asp HTTP/1.1
        "Host" =>  "www.anbima.com.br"
        "User-Agent" =>  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:80.0) Gecko/20100101 Firefox/80.0"
        "Accept" =>  "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        "Accept-Language" =>  "pt-BR,pt;q=0.8,en-US;q=0.5,en;q=0.3"
        "Accept-Encoding" =>  "gzip, deflate, br"
        "Content-Type" =>  "application/x-www-form-urlencoded"
        "Content-Length" =>  "94"
        "Origin" =>  "https://www.anbima.com.br"
        "Connection" =>  "keep-alive"
        "Referer" =>  "https://www.anbima.com.br/informacoes/ima/ima-sh.asp"
        "Cookie" =>  "lumClientId=8A2AB290749450B201749709905D1504; JSESSIONID=4B569D6B9E949CB734EBD02313131CD1.LumisProdA; lumUserLocale=pt_BR; lumMonUid=GB9v_UzD1CZbwjVzKKYvn0QTc3CJxsuf; AWSELB=359F6F8906C702E7D2BBD3C04A400F8539C6D91FD238C2952FBF4A0F2BB3C549A6A51A2676854C5B9E1FDC2EB533CB8BAA69DCEB7EAD83CF8BAD191790A634B39952D64C276ECAB45E8107BE5B4A03390F9EA29851; ASPSESSIONIDQESTDBAS=BECPHPJAMIHJIAGBHAMGCGCB; BIGipServerPool_ANBSPCLD-WEB02_SSL=204005386.47873.0000; __utma=234609614.893389923.1600261823.1600261823.1600275110.2; __utmc=234609614; __utmz=234609614.1600261823.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); _ga=GA1.3.893389923.1600261823; _gid=GA1.3.220011512.1600261823; _fbp=fb.2.1600261824060.1044754934; _hjTLDTest=1; _hjid=67d810ba-8ef2-40f5-80d2-63d7dbac00b7; __trf.src=encoded_eyJmaXJzdF9zZXNzaW9uIjp7InZhbHVlIjoiMjM0NjA5NjE0LjE2MDAyNjE4MjMuMS4xLnV0bWNzcj1nb29nbGV8dXRtY2NuPShvcmdhbmljKXx1dG1jbWQ9b3JnYW5pY3x1dG1jdHI9KG5vdCBwcm92aWRlZCkiLCJleHRyYV9wYXJhbXMiOnt9fSwiY3VycmVudF9zZXNzaW9uIjp7InZhbHVlIjoiaHR0cHM6Ly93d3cuZ29vZ2xlLmNvbS8iLCJleHRyYV9wYXJhbXMiOnt9fSwiY3JlYXRlZF9hdCI6MTYwMDI2NDEzMjA4OX0=; rdtrk=%7B%22id%22%3A%221d5766e6-4883-442c-930a-d1d22efb296f%22%7D; ADRUM=s=1600275093544&r=https%3A%2F%2Fwww.anbima.com.br%2Fpt_br%2Finformar%2Fprecos-e-indices%2Findices%2Fima.htm%3F0; lumUserSessionId=7yqmdlOCqWvJfHnbGi6641Sq1QT_xFq2; lumUserName=Guest; lumIsLoggedUser=false"
        "Upgrade-Insecure-Requests" =>  "1"
    ]

    # why u not work??
    # body = HTTP.Form(Dict([
    #   "Tipo" => ""
    #   "DataRef" => ""
    #   "Pai" => "ima"
    #   "escolha" => "2"
    #   "Idioma" => "EN"
    #   "saida" => "csv"
    #   "Dt_Ref_Ver" => "20200908"
    #   "Dt_Ref" => "03%2F08%2F2020"
    # ]))

    body = "Tipo=&DataRef=&Pai=ima&escolha=2&Idioma=PT&saida=csv&Dt_Ref_Ver=20200908&Dt_Ref=$str_dt"

    r = HTTP.post(url, header, body)

    response_body = String(r.body)
    out = _parse_ima_result(response_body)
    return out

end

function _parse_ima_result(s::String)
    lines = split(s, "\r\n")
    if length(lines) <= 2
        error("nao ha dados de quadro resumo")
    end
    v_elements = Vector{IMA}()
    for line in lines[3:(end-1)]
        vals = split(line, ";")
        @assert length(vals) == 18 "esperava 18 campos na linha mas recebeu $(length(vals)): $line"
        element = IMA(
            vals[1],
            Date(vals[2], "dd/mm/yyyy"),
            parse_value(Float64, vals[3]),
            parse_value(Float64, vals[4]),
            parse_value(Float64, vals[5]),
            parse_value(Float64, vals[6]),
            parse_value(Float64, vals[7]),
            parse_value(Float64, vals[8]),
            parse_value(Float64, vals[9]),
            parse_value(Float64, vals[10]),
            parse_value(Int64, vals[11]),
            parse_value(Float64, vals[12]),
            parse_value(Float64, vals[13]),
            parse_value(Float64, vals[14]),
            parse_value(Float64, vals[15]),
            parse_value(Float64, vals[16]),
            parse_value(Float64, vals[17]),
            parse_value(Float64, vals[18])
        )
        push!(v_elements, element)
    end
    return IMAResult(v_elements)
end
