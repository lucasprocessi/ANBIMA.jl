
using ANBIMA
using Dates
using BusinessDays

dt = Date(2020,9,1)
@info "Lendo IMAs em $dt"
resumo = ANBIMA.read_IMA(dt)
for (k,v) in resumo.elements
    println("$k: $(v.index)")
end

dt = BusinessDays.advancebdays(:BRSettlement, Dates.today(), -2)
@info "Lendo IDAs em $dt"
resumo = ANBIMA.read_IDA(dt)
for (k,v) in resumo.elements
    println("$k: $(v.index)")
end
