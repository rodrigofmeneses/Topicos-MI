import gurobipy as gp
from gurobipy import GRB

# Cell Tower Coverage 
# Gurobi documentation

# Motivação
'''
Over the last ten years, smartphones have revolutionized 
our lives in ways that go well beyond how we communicate.
Besides calling, texting, and emailing, more than two billion 
people around the world now use these devices to navigate to book cab rides, 
to compare product reviews and prices, to follow the news, to watch movies, 
to listen to music, to play video games,to take photographs, 
to participate in social media, and for numerous other applications.

A cellular network is a network of handheld smartphones in which each phone 
communicates with the telephone network by radio waves through a local antenna 
at a cellular base station (cell tower). One important problem is the placement 
of cell towers to provide signal coverage to the largest number of people.
'''

'''
Nos ultimos dez anos, os smartphones tem revolucionado nossas vidas de maneiras
que vão muito além de como nos comunicamos. Além de ligar, enviar mensagens de texto,
e enviar emails, mais de dois bilhões de pessoas pelo mundo agora usam seus dispositivos
para reservar viagens de taxi, comparar avaliações e preços de produtos, acompanhar notícias,
assistir filmes, escutar música, jogar vídeo games, tirar fotos, participar de midias
sociais, e diversas outras applicações.

Uma rede de celular é uma rede de telefones portáteis que se comunicam a uma rede telefonica
a partir de ondas de rádio através de uma antena local e uma estação telefônica (Cell Tower).
Um problema importante é a localização das torres de celular para fornecer uma cobertura
o maior número de pessoas.
'''

#Descrição do problema

'''
A telecom company needs to x a set of cell towers to provide signal coverage for the
inhabitants of a given city. A number of potential locations where the towers could be built 
have been identified. The towers have a fixed range, and -due to budget constraints- only 
a limited number of them can be built. Given these restrictions, the company wishes to 
provide coverage to the largest percentage of the population possible. 
To simplify the problem, the company has split the area it wishes to cover into a set of regions,
each of which has a known population. The goal is then to choose which of the potential 
locations the company should x cell towers on -in order to provide coverage to as many people as possible.

The Cell Tower Coverage Problem is an instance of the Maximal Covering Location Problem [1]. 
It is also related to the Set Cover Problem. Set covering problems occur in many different fields, 
and very important applications come from the airlines industry. For example, Crew Scheduling and 
Tail Assignment Problem [2].
'''

'''
Uma companhia de telecomunicação precisa construir um grupo de estações de celular para prover uma
cobertura para os habitantes de uma dada cidade. Um número de potenciais candidatos de onde a estação
deve ser construida é identificado. A estação tem um alcance fixo, e uma restrição orçamentar limitando
o número de estações que pode construir. Dada essas restrições, a companhia deseja prover uma cobertura
para a maior porcentagem possível da população.
Para simplificar o problema, a companhia dividiu a area que deseja cobrir em um grupo de regiões,
cada uma com uma população conhecida. O objetivo é escolher as localizações em potencial que a 
companhia possa construir as estações de modo que providencie a cobertura do maior número de pessoas possível.

O problema da cobertura telefônica é uma instancia do problema de cobertura máximo.
Que tambem é relatada como problema de cobertura. Probleas de cobertura ocorrem em diferentes campos,
e tem aplicações importantes para empresas de aviação. Por exemplo, o problema de planejamento de 
tripulação e o de alocação de cauda (?).
'''

# Os valores estão em milhões

# Orçamento
orcamento = 20

# a função multidict retorna n valores
# onde o primeiro são as chaves do dicionário (ou seja, os indices)
# e os proximos n-1 retornos, são dicionarios onde as chaves são sempre os indices
# e os valores são os respectivos elementos da lista argumentada.

# regioes = [conjunto de regioes] 
# populacao = {regiao: populacao da regiao}
regioes, populacao = gp.multidict({
    0: 523, 1: 690, 2: 420,
    3: 1010, 4: 1200, 5: 850,
    6: 400, 7: 1008, 8: 950
})


# torres = [conjunto de torres]
# cobertura = {torre: regioes cobertas}
# custo = {torre: custo de construção}
torres, cobertura, custo = gp.multidict({
    0: [{0,1,5}, 4.2],
    1: [{0,7,8}, 6.1],
    2: [{2,3,4,6}, 5.2],
    3: [{2,5,6}, 5.5],
    4: [{0,2,6,7,8}, 4.8],
    5: [{3,4,8}, 9.2]
})

# Formulação MIP

cobertura_telefonica = gp.Model("cobertura_telefonica")

# Se a região Yi é atendida
y = cobertura_telefonica.addVars(len(regioes), vtype=GRB.BINARY, name="Y")

# Se a torre Xj é construída
x = cobertura_telefonica.addVars(len(torres), vtype=GRB.BINARY, name="X")

# Função Objetivo
cobertura_telefonica.setObjective(y.prod(populacao), GRB.MAXIMIZE)

# Restrição orçamental
cobertura_telefonica.addConstr(x.prod(custo) <= orcamento, name="Orçamento")

# Para cada uma das regiões
for r in regioes:
    # Torres t que podem atender a Região r.
    podem_atender = [x[t] for t in torres if r in cobertura[t]]
    
    # O somatório das Torres t que podem atender r
    # deve ser maior que se a região r é atendida.
    cobertura_telefonica.addConstr(gp.quicksum(podem_atender) >= y[r], name=f"Cobertura_região {r}")

# na documentação toda essa expressão é reduzida na linha seguinte
# cobertura_telefonica.addConstrs((gp.quicksum(x[t] for t in torres if r in cobertura[t]) >= y[r]
#                        for r in regioes), name="construir_para_atender")


# Escrita do LP
cobertura_telefonica.write('models/cobertura_telefonica.lp')
# Resolver
cobertura_telefonica.optimize() 

# Análise

# O Plano!
# Determinar quais torres serão construidas

for torre in x.keys():
    if (abs(x[torre].x) > 1e-6):
        print(f"\n Construir uma torre na localização {torre}.")


# Porcentagem da população coberta

populacao_total = 0

for r in regioes:
    populacao_total += populacao[r]

coberto = round(100*cobertura_telefonica.objVal/populacao_total, 2)

print(f"\n A população coberta por esse plano de construção de torres é: {coberto} %")