module Formulations

using JuMP
using Gurobi
using Data
using Parameters

mutable struct stdFormVars
	x
	y
	s
	xr
	yr
	sr
end

export standardFormulation, stdFormVars, multicommodityFormulation

function standardFormulation(inst::InstanceData, params::ParameterData)

	N = inst.N

	### select solver ###
	if params.solver == "Gurobi"
		model = Model(Gurobi.Optimizer)
		set_optimizer_attribute(model, "TimeLimit", params.maxtime) # Time limit
		set_optimizer_attribute(model, "MIPGap", params.tolgap) # Relative MIP optimality gap
		set_optimizer_attribute(model, "NodeLimit", params.maxnodes) # MIP node limit
		set_optimizer_attribute(model, "Cuts", 3) # Global cut aggressiveness setting. 

	else
		println("No solver selected")
		return 0
	end

	### variables ###
	@variable(model,0 <= x[t=1:N] <= Inf)
	@variable(model,0 <= xr[t=1:N] <= Inf)
	@variable(model, y[t=1:N], Bin)
	@variable(model, yr[t=1:N], Bin)
	@variable(model,0 <= s[t=1:N] <= Inf)
	@variable(model,0 <= sr[t=1:N] <= Inf)

	### objective function ###
	@objective(model, Min, sum(inst.P[t]*x[t] + inst.H[t]*s[t] + inst.F[t]*y[t] for t=1:N) + sum(inst.PR[t]*xr[t] + inst.HR[t]*sr[t] + inst.FR[t]*yr[t] for t=1:N))

	### constraints ###
	# Suprir as demandas e remanufaturas de cada periodo
	# D
	@constraint(model, balance0, x[1] + xr[1] - s[1] == inst.D[1])
	@constraint(model, balance[t=2:N], s[t-1] + x[t] + xr[t] - s[t] == inst.D[t])
	# R
	@constraint(model, balanceR0, -xr[1] - sr[1] == - inst.R[1])
	@constraint(model, balanceR[t=2:N], sr[t-1] - xr[t] - sr[t] == - inst.R[t])

	# Ativar as variáveis de setup
	@constraint(model, setup[t=1:N], x[t] <= sum(inst.D[k] for k in t:inst.N)*y[t])
	# 
	@constraint(model, setupR[t=1:N], xr[t] <= min(sum(inst.D[k] for k in t:N),sum(inst.R[k] for k in 1:t))*yr[t])
	

	#write_to_file(model,"modelo.lp")

	### solving the optimization problem ###
	optimize!(model)

	if termination_status(model) == MOI.OPTIMAL    
		println("status = ", termination_status(model))
	else
		#error("O modelo não foi resolvido corretamente!")
		println("status = ", termination_status(model))
		return 0
	end
		
	### get solutions ###
	bestsol = objective_value(model)
	if params.mip == 1
		bestbound = objective_bound(model)
		numnodes = node_count(model)
		gap = MOI.get(model, MOI.RelativeGap())
	end
	time = solve_time(model) 
	
	### print solutions ###
	open("saida.txt","a") do f
		if params.mip == 1
			write(f,";$(params.form);$bestbound;$bestsol;$gap;$time;$numnodes;$(params.disablesolver) \n")
		else
			write(f,";$(params.form);$bestsol;$time;$(params.disablesolver) \n")
		end
	end
	
end #function standardFormulation()

function multicommodityFormulation(inst::InstanceData, params::ParameterData)
	N = inst.N

	### select solver ###
	if params.solver == "Gurobi"
		model = Model(Gurobi.Optimizer)
		set_optimizer_attribute(model, "TimeLimit", params.maxtime) # Time limit
		set_optimizer_attribute(model, "MIPGap", params.tolgap) # Relative MIP optimality gap
		set_optimizer_attribute(model, "NodeLimit", params.maxnodes) # MIP node limit
		set_optimizer_attribute(model, "Cuts", 3) # Global cut aggressiveness setting. 

	else
		println("No solver selected")
		return 0
	end

	# N = 4
	### variables ###
	@variable(model,0 <= x[t=1:N] <= Inf)
	@variable(model,0 <= xr[t=1:N] <= Inf)
	@variable(model, y[t=1:N], Bin)
	@variable(model, yr[t=1:N], Bin)
	# qtd novos itens produzidos em k para atender a demanda em t
	@variable(model,0 <= w[k=1:N, t=1:N] <= Inf)
	# qtd de itens remanufaturados em k para atender a demanda em t
	@variable(model,0 <= wr[k=1:N, t=1:N] <= Inf)
	# qtd itens remanufaturados no periodo k para atender a demanda no periodo t
	@variable(model,0 <= or[k=1:N, t=1:N] <= Inf)

	### objective function ###
	@objective(model, Min, sum(inst.P[t]*x[t] + inst.F[t]*y[t] for t=1:N) + sum(inst.PR[t]*xr[t] + inst.FR[t]*yr[t] for t=1:N ))

	### constraints ###
	# 20 itens produzidos e remanufaturados devem suprir a demanda em t
	@constraint(model, fullfilled[t=1:N], sum(w[k, t] + wr[k, t] for k=1:t) >= inst.D[t])
	# 21 itens remanufaturados em or[k] para atender demanda em t são a mesma quantidade dos remanufaturados em t.
	@constraint(model, returned_real[t=1:N], sum(or[k, t] for k=1:t) == sum(wr[t, k] for k=t:N))
	# 22 itens remanufaturados em or[k] não devem exceder itens retornados em k
	@constraint(model, exceed[k=1:N], sum(or[k, t] for t=k:N) <= inst.R[k])
	
	# Ativar as variáveis de setup
	# 23 produção
	@constraint(model, setup[k=1:N, t=k:N], w[k, t] <= inst.D[t]*y[k])
	# 24 remanufaturação
	@constraint(model, setupR[k=1:N, t=k:N], wr[k, t] <= min(sum(inst.R[j] for j in 1:k), inst.D[t]) * yr[k])
	# 25 remanufaturação or
	@constraint(model, setupOR[k=1:N, t=k:N], or[k, t] <= inst.R[k]*yr[t])

	# 26 - 27 Por fim, associar as variaveis de multicommodity com as originais do problema
	@constraint(model, varX[t=1:N], x[t] == sum(w[t, k] for k in t:N))
	@constraint(model, varXR[t=1:N], xr[t] == sum(wr[t, k] for k in t:N))
	# print(model)
	# write_to_file(model,"modelo.lp")

	### solving the optimization problem ###
	optimize!(model)

	if termination_status(model) == MOI.OPTIMAL    
		println("status = ", termination_status(model))
	else
		#error("O modelo não foi resolvido corretamente!")
		println("status = ", termination_status(model))
		return 0
	end
		
	### get solutions ###
	bestsol = objective_value(model)
	if params.mip == 1
		bestbound = objective_bound(model)
		numnodes = node_count(model)
		gap = MOI.get(model, MOI.RelativeGap())
	end
	time = solve_time(model) 
	
	### print solutions ###
	open("saida.txt","a") do f
		if params.mip == 1
			write(f,";$(params.form);$bestbound;$bestsol;$gap;$time;$numnodes;$(params.disablesolver) \n")
		else
			write(f,";$(params.form);$bestsol;$time;$(params.disablesolver) \n")
		end
	end

end

end

# julia -O0 --sysimage ecls.dylib -q ecls.jl