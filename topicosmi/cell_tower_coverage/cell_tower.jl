using JuMP, Gurobi

orcamento = 20
# numero de regioes
n = 9
regioes = 1:n
# Numero de torres
m = 6
torres = 1:m

populacao = [523 690 420 1010 1200 850 400 1008 950]
cobertura = [[0 1 5], [0 7 8], [2 3 4 6], [2 5 6], [0 2 6 7 8], [3 4 8]]
custo = [4.2 6.1 5.2 5.5 4.8 9.2]

# Criação do modelo
cobertura_telefonica = Model(Gurobi.Optimizer)

# Variáveis Binárias
# Se a região Yi é atendida
@variable(cobertura_telefonica, y[regioes], Bin)
# Se a torre Xj é construída
@variable(cobertura_telefonica, x[torres], Bin)

# Função Objetivo
@objective(cobertura_telefonica, Max, populacao' * y)

# Restrição orçamental
@constraint(cobertura_telefonica, custo' * x <= orcamento)