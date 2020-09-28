
function read_credit_spread_data(dt::Date)

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

function calibrate_credit_spread_curves(dt::Date)
	data = read_credit_spread_data(dt)
	return Dict([k => _do_calibrate(v) for (k,v) in data])
end

function _do_calibrate(d::Vector{Pair{Float64,Float64}}; best_of=3)
	v_taus = [Int64(round(252*first(x))) for x in d] # convert to bdays
	v_rates = [last(x) for x in d]

	function get_curve(x)
		@assert length(x) == 3
		β1 = x[1]
		β2 = x[2]
		β3 = 0.0  # no curvature
		λ = x[3]
		cv = NelsonSiegelCurve(β1, β2, β3, λ)
		return cv
	end

	function f_optim(x)
		cv = get_curve(x)
		model_rates = [zerorate(cv, t) for t in v_taus]
		return 100*sum((100*model_rates - 100*v_rates).^2)
	end

	best_minimum = Inf
	solution = nothing
	for i in 1:best_of
		#@info "Solution $i/$best_of"
		this_solution = Evolutionary.optimize(
			f_optim,
			rand(3),
			Evolutionary.GA(
				populationSize = 1000,
				crossoverRate=0.5,
				mutationRate=0.5,
				ɛ=0.1,
				selection = susinv,
				crossover = discrete,
				mutation = domainrange(ones(3))
			),
			Evolutionary.Options(
				show_trace=false,
				show_every=100)
		)
		if Evolutionary.converged(this_solution)
			this_min = Evolutionary.minimum(this_solution)
			if this_min < best_minimum
				#@info "BEST!"
				best_minimum = this_min
				solution = this_solution
			end
		end
	end

	if solution == nothing
		error("could not solve spread curve minimization")
	end
	x_optim = Evolutionary.minimizer(solution)
	curve_optim = get_curve(x_optim)

	# debug
	# err = Vector{Float64}(undef, length(v_taus))
	# for i in 1:length(v_taus)
	# 	tau = v_taus[i]
	# 	rate = v_rates[i]
	# 	model_rate = zerorate(curve_optim, tau)
	# 	err[i] = 100*abs(model_rate - rate)
	# end
	# @show maximum(err)
	# end debug

	return curve_optim

end
