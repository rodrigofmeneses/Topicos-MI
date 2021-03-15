using PackageCompiler

create_sysimage([:JuMP,:Gurobi]; sysimage_path="knap_img.dylib", precompile_execution_file="knap.jl")