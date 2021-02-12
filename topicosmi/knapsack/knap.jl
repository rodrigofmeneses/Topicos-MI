using JuMP, Gurobi

# julia -O0 --sysimage my_sysimage.dylib -q knap.jl

function example_knapsack(; verbose = true)
    n = 7
    profit = [6, 5, 8, 9, 6, 7, 3]
    weight = [2, 3, 6, 7, 5, 9, 4]
    capacity = 9

    # Modelo
    model = Model(Gurobi.Optimizer)
    # Viaráveis
    @variable(model, x[1:n], Bin)
    # Restrição
    @constraint(model, weight' * x <= capacity)
    # Função Objetivo
    @objective(model, Max, profit' * x)
    # Optimizador
    optimize!(model)

    if verbose
        println("Objective is: ", objective_value(model))
        println("Solution is:")
        for i in 1:n
            print("x[$i] = ", value(x[i]))
            println(", p[$i]/w[$i] = ", profit[i] / weight[i])
        end
    end

end

example_knapsack()