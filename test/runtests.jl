
using ANBIMA
using Dates
using BusinessDays
using Test

dt = Date(2020,9,1)
@info "Reading IMAs on $dt"
data = ANBIMA.read_IMA(dt)
for (k,v) in data.elements
    println("  $k: $(v.index)")
end


dt = BusinessDays.advancebdays(:BRSettlement, Dates.today(), -2)
@info "Reading IDAs on $dt"
data = ANBIMA.read_IDA(dt)
for (k,v) in data.elements
    println("  $k: $(v.index)")
end
dt_old = Date(2020,9,1)
@test_throws AssertionError ANBIMA.read_IDA(dt_old)

@info "Reading ETTJs on $dt"
data = ANBIMA.read_ettj(dt)
vertices = [1, 252,504, 10000]
for (k,v) in data
	taxas = [t => 100*ANBIMA.zerorate(v, t) for t in vertices]
	println("  $k")
	for x in taxas
		t = first(x)
		r = last(x)
		println("    $t: $r")
	end
end
@test_throws AssertionError ANBIMA.read_ettj(dt_old)

@info "Reading credit spread curves on $dt"
data = ANBIMA.read_credit_spread_data(dt)
curves = ANBIMA.calibrate_credit_spread_curves(dt)
for (k,v) in curves
	println("$k => $v")
end
