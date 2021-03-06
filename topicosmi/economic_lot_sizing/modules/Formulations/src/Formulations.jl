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

	# println("inst.P: ", inst.P[1:4])
	# println("inst.PR: ", inst.PR[1:4])
	# println("inst.H: ", inst.H[1:4])
	# println("inst.HR: ", inst.HR[1:4])


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

	open("variaveis_std.txt","w") do f
		write(f,"x: $(value.(x)) \n" )
		write(f,"xr: $(value.(xr)) \n")
	end
	
	# println("x: $(value.(x))")
	# println("xr: $(value.(xr))") 
	# println("s: $(value.(s))") 
	# println("sr: $(value.(sr))") 

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

	# Transformação necessária para a modificação da função objetivo!
	P = zeros(Float64, N)
	PR = zeros(Float64, N)
	s = zeros(Float64, N)
	sr = zeros(Float64, N)
	
	# M, é o custo de armazenamento referente ao que foi demandado para produção e o que foi retornado.
	# Visto que a demanda está sendo sempre suprida, é descontado seu custo de armazenamento a priori,
	# a prioridade de armazenamento é para itens retornados, pois todos os itens produzidos suprirão a demanda
	# junto a uma quantidade retornada, fazendo com que a sobra seja apenas itens retornados.
	# Se há itens retornados suficientes para cobrir a demanda, por que produziria itens novos?
	M = sum( inst.HR[t] * sum(inst.R[k] for k in 1:t) - inst.H[t] * sum(inst.D[k] for k in 1:t) for t in 1:N)
	for t=1:N
		# Os custos de produção incluem os custos de armazenamento, que será descontado na constante M, se o item for produzido.
		P[t] = inst.P[t] + sum(inst.H[j] for j in t:N)
		PR[t] = inst.PR[t] + sum(inst.H[j] for j in t:N) - sum(inst.HR[j] for j in t:N)
	end

	println("M: ", M)
	
	# N = 3
	### index ###
	# k = 1:N, periodo inicial.
	# t = 1:N, periodo subsequente.
	### variables ###
	# x_t, quantidade de itens produzidos no periodo t.
	@variable(model,0 <= x[t=1:N] <= Inf)
	# xr_t, quantidade de itens remanufaturados no periodo t.
	@variable(model,0 <= xr[t=1:N] <= Inf)
	# y_t, indica se será permitido produzir no periodo t.
	@variable(model, y[t=1:N], Bin)
	# yr_t, indica se será permitido remanufaturar no periodo t.
	@variable(model, yr[t=1:N], Bin)
	# w_kt, quantidade de itens produzidos em k para atender a demanda em t.
	@variable(model,0 <= w[k=1:N, t=1:N] <= Inf)
	# wr_kt, quantidade de itens remanufaturados em k para atender a demanda em t.
	@variable(model,0 <= wr[k=1:N, t=1:N] <= Inf)
	# or, quantidade de itens que chegaram em k para serem remanufaturados em t.
	@variable(model,0 <= or[k=1:N, t=1:N] <= Inf)

	### objective function ###
	# Soma dos custos modificados com inclusão da constante já comentada anteriormente.
	@objective(model, Min, sum(P[t]*x[t] + inst.F[t]*y[t] for t=1:N) + sum(PR[t]*xr[t] + inst.FR[t]*yr[t] for t=1:N) + M)
	
	### constraints ###
	# 20 itens produzidos e remanufaturados devem suprir a demanda em t.
	@constraint(model, fullfilled[t=1:N], sum(w[k, t] + wr[k, t] for k=1:t) >= inst.D[t])
	# 21 itens remanufaturados em or[k] para atender demanda em t são a mesma quantidade dos remanufaturados em t.
	@constraint(model, returned_real[t=1:N], sum(or[k, t] for k=1:t) == sum(wr[t, k] for k=t:N))
	# 22 itens remanufaturados em or[k] não devem exceder itens retornados em k.
	@constraint(model, exceed[k=1:N], sum(or[k, t] for t=k:N) <= inst.R[k])
	# Nota:
	# podemos interpretar or como um pedido, 'a partir do que voce recebe em k, remanufature para o tempo t'
	# ao invés de simplesmente inst.R[t] que nos diz o total de itens retornados em t. 
	
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
	### solving the optimization problem ###
	# print(model)
	optimize!(model)
	
	# Todo esse trecho comentado usei apenas para analisar os resultados
	open("variaveis_mcd.txt","w") do f
		write(f,"x: $(value.(x)) \n" )
		write(f,"xr: $(value.(xr)) \n")
	end
	# for t=1:N
	# 	s[t] = sum(getvalue(model, x[k]) for k in 1:t) + sum(getvalue(model, xr[k]) for k in 1:t) - sum(inst.D[k] for k in 1:t)
	# 	sr[t] = sum(inst.R[k] for k in 1:t) - sum(getvalue(model, xr[k]) for k in 1:t)
	# end

	# print("\n\n")
	# print("x: ")
	# for i=1:N
	# 	if value.(x[i]) > 0
	# 		print("x[$i]: $(value.(x[i])), ") 
	# 	end
	# end

	# print("\n\n")
	# print("xr: ")
	# for i=1:N
	# 	if value.(xr[i]) > 0
	# 		print("xr[$i]: $(value.(xr[i])), ") 
	# 	end
	# end

	# print("\n\n")
	# print("y: ")
	# for i=1:N
	# 	if value.(y[i]) > 0
	# 		print("y[$i]: $(value.(y[i])), ") 
	# 	end
	# end

	# print("\n\n")
	# print("yr: ")
	# for i=1:N
	# 	if value.(yr[i]) > 0
	# 		print("yr[$i]: $(value.(yr[i])), ") 
	# 	end
	# end

	# print("\n\n")
	# print("w: ")
	# for i=1:N
	# 	for j=1:N
	# 		if value.(w[i, j]) > 0
	# 			print("w[$i, $j]: $(value.(w[i, j])), ")
	# 		end
	# 	end
	# end

	# print("\n\n")
	# print("wr: ")
	# for i=1:N
	# 	for j=1:N
	# 		if value.(wr[i, j]) > 0
	# 			print("wr[$i, $j]: $(value.(wr[i, j])), ")
	# 		end
	# 	end
	# end

	# print("\n\n")
	# print("or: ")
	# for i=1:N
	# 	for j=1:N
	# 		if value.(or[i, j]) > 0
	# 			print("or[$i, $j]: $(value.(or[i, j])), ")
	# 		end
	# 	end
	# end
	# print("\n\n")

	# # println("xr: $(value.(xr[1]))") 
	# # println("w: $(value.(w[1]))")
	# # println("wr: $(value.(wr[1]))")
	# # println("or: $(value.(or)[1])")


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