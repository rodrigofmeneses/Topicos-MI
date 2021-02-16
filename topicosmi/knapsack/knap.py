# Imports
from gurobipy import *
import numpy as np
import os
import time

# Read Data
def read_instance(path):
    with open(path) as r:
        num_itens = int(r.readline()) 
        r.readline() # empty line between data
        profits = [int(x) for x in r.readline().split()]
        r.readline()
        capacity = int(r.readline())
        r.readline()
        weights = [int(x) for x in r.readline().split()]

    return num_itens, profits, capacity, weights

def relaxed_dantzig(num_itens, profits, capacity, weights):
    '''
        Ordene em ordem não-crescente os itens de acordo com a relação pi/wi
        Insira itens na mochila tal forma que não exceda a capacidade.
        
        a solução relaxada não é inteira, é apenas [0, 1] logo
        x = [0, 0.4, 0, 1], por exemplo

        K é o conjunto de itens na mochila tal que
        o somatório para todo i pertencente a K, wi <= c
        
        definimos xh como item de parada, tal que
        (o somatório para todo i pertencente a K, wi) + wk > c 
        
        xk pertence a (0, 1)
    '''
    # values of itens is relation pi/wi
    values = [profits[i] / weights[i] for i in range(num_itens)]
    # Sort index in reversed order
    arg_sort_reversed = np.argsort(np.array(values))[::-1]

    # initialization of variables
    K = np.zeros(num_itens)
    x = np.zeros(num_itens)
    curr_capacity = 0

    # Fill Knapsack
    for i in arg_sort_reversed:
        # If knapsack has capacity to iten, put on
        if weights[i] + curr_capacity <= capacity:
            K[i] = 1
            x[i] = 1
            curr_capacity += weights[i]
        # Else, put on maximum possible 
        else:
            x[i] = (capacity - curr_capacity) / weights[i]
    # Calculate the cost of solution
    obj_value = x @ np.array(profits)
    return x, obj_value

def viable_dantzig(num_itens, profits, capacity, weights):
    '''
        Similar to relaxed dantzing, but the solution is binary,
        for garantee the viability.
    '''
    # Relaxed dantzig solution
    x, _ = relaxed_dantzig(num_itens, profits, capacity, weights) 
    
    # Transform all index in integer
    x = np.floor(x)
    # Calculate the cost of solution
    obj_value = x @ np.array(profits)



    return x, obj_value

def gurobi_knapsack(num_itens, profits, capacity, weights, verbose=False):
    # Create a model
    knap = Model()
    # Supress output log
    knap.setParam('OutputFlag', 0)
    # Add variables to model, relaxed [0, 1]
    # x = knap.addVars(num_itens, lb=0, ub=1, name='x')
    x = knap.addVars(num_itens, vtype=GRB.BINARY, name='x')
    # Add capacity constrain to model
    knap.addConstr((x.prod(weights)) <= capacity, name='knapsack')
    # Set a objective function to model, as Maximize the profit
    knap.setObjective(x.prod(profits), GRB.MAXIMIZE)
    # Solve the model
    knap.optimize()

    if verbose:
        print("Objective is: ", knap.ObjVal)
        print("Solution is:")
        for i in range(num_itens):
            print(f'x[{i}] = {knap.X[i]}')

    return knap.X, knap.ObjVal

def experiments_with(file_path, method):
    num_itens, profits, capacity, weights = read_instance(file_path)

    if method == 'relaxed_dantzig':
        x, obj_value = relaxed_dantzig(num_itens, profits, capacity, weights)
    elif method == 'viable_dantzig':
        x, obj_value = viable_dantzig(num_itens, profits, capacity, weights)
    elif method == 'gurobi_knapsack':
        x, obj_value = gurobi_knapsack(num_itens, profits, capacity, weights)
    else:
        print('Invalid Method')
        return False
    
    return x, obj_value

def run():
    folders = os.listdir('data/instances_knapsack')

    result = open(f'experiments/knapsack/results{time.strftime("%d%b%Y_%H_%M_%S", time.gmtime())}.txt', 'w')
    result.write('instance_name,relaxed_cost,viable_cost,gurobi_cost')
    
    methods = ['relaxed_dantzig', 'viable_dantzig', 'gurobi_knapsack']
    
    for folder in folders:
        for instance in os.listdir(f'data/instances_knapsack/{folder}'):
            file_path = f'data/instances_knapsack/{folder}/{instance}'
            result.write('\n' + instance)
            for method in methods:
                _, cost = experiments_with(file_path, method)
                result.write(',' + str(cost))
    result.close()

if __name__ == "__main__":
    num_itens, profits, capacity, weights = read_instance('data/instances_knapsack/10/10_100_1.txt')
    
    x, obj_value = relaxed_dantzig(num_itens, profits, capacity, weights)
    print('x :', list(x))
    print('Objetive Function Value :', obj_value)

    x, obj_value = viable_dantzig(num_itens, profits, capacity, weights)
    print('x :', list(x))
    print('Objetive Function Value :', obj_value)

    x, obj_value = gurobi_knapsack(num_itens, profits, capacity, weights)
    print('x :', list(x))
    print('Objetive Function Value :', obj_value)

    run()