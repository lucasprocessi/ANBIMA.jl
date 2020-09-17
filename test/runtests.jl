
using ANBIMA
using Dates
using BusinessDays

dt = Date(2020,9,1)

resumo = ANBIMA.read_IMA(dt)
@info "IMA $dt"
for (k,v) in resumo.elements
    println("$k: $(v.index)")
end

dt = BusinessDays.advancebdays(:BRSettlement, Dates.today(), -1)
resumo = ANBIMA.read_IDA(dt)
@info "IDA $dt"
for (k,v) in resumo.elements
    println("$k: $(v.index)")
end
