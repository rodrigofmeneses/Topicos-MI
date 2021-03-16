module Data

struct InstanceData
    N::Int #number of periods
    H # holding cost
    P # production cost 
    F # setup cost
    HR # holding cost return
    PR # remanufacturing cost
    FR # remanufacturing setup cost
    D # demand cost
    R # return cost
end

export InstanceData, readData

function readData(instanceFile)
    file = open(instanceFile)
    fileText = read(file, String)
    tokens = split(fileText)
    #tokens will have all the tokens of the input file in a single vector. We will get the input token by token

    # read the problem's dimension
    aux = 1
    N = parse(Int, tokens[aux])

    #resize data structures according to N
    H = zeros(Float64,N)
    P = zeros(Float64,N)
    F = zeros(Float64,N)
    HR = zeros(Float64,N)
    PR = zeros(Float64,N)
    FR = zeros(Float64,N)
    D = zeros(Int,N)
    R = zeros(Int,N)
    
      aux = aux+1
    FR[1] = parse(Float64,tokens[aux])
    for t=2:N
    FR[t] = FR[1]
    end

    aux = aux+1
    F[1] = parse(Float64,tokens[aux])
    for t=2:N
    F[t] = F[1]
    end

    aux = aux+1
    HR[1] = parse(Float64,tokens[aux])
    for t=2:N
    HR[t] = HR[1]
    end

    aux = aux+1
    H[1] = parse(Float64,tokens[aux])
    for t=2:N
    H[t] = H[1]
    end

    for t in 1:N
    aux = aux+1
    D[t] = parse(Int,tokens[aux])
    end

    for t in 1:N
    aux = aux+1
    R[t] = parse(Int,tokens[aux])
    end

    close(file)

    open("saida.txt","a") do f
        write(f,"$instanceFile")
    end

    inst = InstanceData(N, H, P, F, HR, PR, FR, D, R)

    return inst
end

end