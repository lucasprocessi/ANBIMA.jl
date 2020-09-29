# ANBIMA.jl

[![License][license-img]](LICENSE)
[![travis][travis-img]][travis-url]
[![codecov][codecov-img]][codecov-url]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
[travis-img]: https://img.shields.io/travis/lucasprocessi/ANBIMA.jl/master.svg?logo=travis&label=Linux&style=flat-square
[travis-url]: https://travis-ci.org/lucasprocessi/ANBIMA.jl
[codecov-img]: https://img.shields.io/codecov/c/github/lucasprocessi/ANBIMA.jl/master.svg?label=codecov&style=flat-square
[codecov-url]: http://codecov.io/github/lucasprocessi/ANBIMA.jl?branch=master

ANBIMA data reader for Julia

### Example

```julia
using ANBIMA
using Dates
using BusinessDays

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

@info "Reading credit spread curves on $dt"
data = ANBIMA.read_credit_spread_data(dt)
curves = ANBIMA.calibrate_credit_spread_curves(dt)
for (k,v) in curves
	println("$k => $v")
end

```