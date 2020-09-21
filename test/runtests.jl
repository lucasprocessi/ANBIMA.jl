
using ANBIMA
using Dates
using BusinessDays

dt = Date(2020,9,1)
@info "Lendo IMAs em $dt"
resumo = ANBIMA.read_IMA(dt)
for (k,v) in resumo.elements
    println("  $k: $(v.index)")
end

dt = BusinessDays.advancebdays(:BRSettlement, Dates.today(), -2)
@info "Lendo IDAs em $dt"
resumo = ANBIMA.read_IDA(dt)
for (k,v) in resumo.elements
    println("  $k: $(v.index)")
end

@info "LENDO ETTJs em $dt"
dados = ANBIMA.read_ettj(dt)
vertices = [1, 252,504, 10000]
for (k,v) in dados
	taxas = [t => 100*ANBIMA.zerorate(v, t) for t in vertices]
	println("  $k")
	for x in taxas
		t = first(x)
		r = last(x)
		println("    $t: $r")
	end
end
