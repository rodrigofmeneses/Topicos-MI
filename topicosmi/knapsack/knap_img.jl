using PackageCompiler

create_sysimage([:JuMP,:Gurobi]; sysimage_path="my_sysimage.dylib", precompile_execution_file="knap.jl")