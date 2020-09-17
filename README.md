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

dt = Date(2020,9,1)

resumo = ANBIMA.read_IMA(dt)
@info "IMA $dt"
for (k,v) in resumo.elements
    println("$k: $(v.index)")
end

resumo = ANBIMA.read_IDA(dt)
@info "IDA $dt"
for (k,v) in resumo.elements
    println("$k: $(v.index)")
end
```