
function read_IDA(dt::Date)

    @assert BusinessDays.isbday(:BRSettlement, dt) "$dt should be a business day in Brazil"

    url = "https://www.anbima.com.br/informacoes/ida/IDA_down.asp"
    str_dt = Dates.format(dt, "dd%2Fmm%2Fyyyy")
    str_month = Dates.format(dt, "mm%2Fyyyy")

    header = [
        "Host" => "www.anbima.com.br"
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:80.0) Gecko/20100101 Firefox/80.0"
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        "Accept-Language" => "pt-BR,pt;q=0.8,en-US;q=0.5,en;q=0.3"
        "Accept-Encoding" => "gzip, deflate, br"
        "Content-Type" => "application/x-www-form-urlencoded"
        "Content-Length" => "73"
        "Origin" => "https://www.anbima.com.br"
        "Connection" => "keep-alive"
        "Referer" => "https://www.anbima.com.br/informacoes/ida/IDA_result.asp"
        "Cookie" => "lumClientId=8A2AB290749450B201749709905D1504; JSESSIONID=23564884E50B8DB92E68D45AC216EDB1.LumisProdA; lumUserLocale=pt_BR; lumMonUid=GB9v_UzD1CZbwjVzKKYvn0QTc3CJxsuf; AWSELB=359F6F8906C702E7D2BBD3C04A400F8539C6D91FD23AB4870C6F06E79BBF1036E517A60EF149A503B53EBF4D8862B25DAA307E36A36717521B34D32279CC0AF98F016EE242940E4EDC29638DEB2407933C4CE9B519; ASPSESSIONIDQESTDBAS=BEEEIPJAJGLADHHNEKBGLKPE; BIGipServerPool_ANBSPCLD-WEB02_SSL=204005386.47873.0000; __utma=234609614.893389923.1600261823.1600275110.1600302962.3; __utmc=234609614; __utmz=234609614.1600261823.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); _ga=GA1.3.893389923.1600261823; _gid=GA1.3.220011512.1600261823; _fbp=fb.2.1600261824060.1044754934; _hjTLDTest=1; _hjid=67d810ba-8ef2-40f5-80d2-63d7dbac00b7; __trf.src=encoded_eyJmaXJzdF9zZXNzaW9uIjp7InZhbHVlIjoiMjM0NjA5NjE0LjE2MDAyNjE4MjMuMS4xLnV0bWNzcj1nb29nbGV8dXRtY2NuPShvcmdhbmljKXx1dG1jbWQ9b3JnYW5pY3x1dG1jdHI9KG5vdCBwcm92aWRlZCkiLCJleHRyYV9wYXJhbXMiOnt9fSwiY3VycmVudF9zZXNzaW9uIjp7InZhbHVlIjoiaHR0cHM6Ly93d3cuYW5iaW1hLmNvbS5ici9wdF9ici9pbmZvcm1hci9wcmVjb3MtZS1pbmRpY2VzL2luZGljZXMvaW1hLmh0bSIsImV4dHJhX3BhcmFtcyI6e319LCJjcmVhdGVkX2F0IjoxNjAwMzAzMTYwMDUwfQ==; rdtrk=%7B%22id%22%3A%221d5766e6-4883-442c-930a-d1d22efb296f%22%7D; ADRUM=s=1600303155552&r=https%3A%2F%2Fwww.anbima.com.br%2Fpt_br%2Finformar%2Fprecos-e-indices%2Findices%2Fida.htm%3F660476728; __utmb=234609614.15.10.1600302962; __utmt=1; __utmt_UA-18261922-8=1; lumUserSessionId=uwNfY6_NU9CN6CE6PJEs_Hn6FrkezUxJ; lumUserName=Guest; lumIsLoggedUser=false; _gat_UA-18261922-22=1; _gat_UA-18261922-23=1; _dc_gtm_UA-18261922-14=1"
        "Upgrade-Insecure-Requests" => "1"
    ]

    body = "DataIniD=$str_dt&DataIniM=$str_month&indice=GERAL&tipo=qr&saida=csv"

    r = HTTP.post(url, header, body)

    response_body = String(r.body)
    out = _parse_ida_result(response_body)
    for (k, ida) in out.elements
        @assert ida.date == dt "Invalid date for $(k): expected $(dt) got $(ida.date)"
    end
    return out

end

function _parse_ida_result(s::String)
    lines = split(s, "\r\n")
    if length(lines) <= 3
        error("nao ha dados de quadro resumo")
    end
    v_elements = Vector{IDA}()
    for line in lines[4:(end-1)]
        vals = split(line, ";")
        @assert length(vals) == 11 "esperava 11 campos na linha mas recebeu $(length(vals)): $line"
        element = IDA(
            vals[1],
            Date(vals[2], "dd/mm/yyyy"),
            parse_value(Float64, vals[3]),
            parse_value(Float64, vals[4]),
            parse_value(Float64, vals[5]),
            parse_value(Float64, vals[6]),
            parse_value(Float64, vals[7]),
            parse_value(Float64, vals[8]),
            parse_value(Int64, vals[9]),
            parse_value(Float64, vals[10]),
            parse_value(Float64, vals[11])
        )
        push!(v_elements, element)
    end
    return IDAResult(v_elements)
end
