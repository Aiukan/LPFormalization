module LPSolver

using JSON
using JuMP
using GLPK
using Logging
import MathOptInterface
MOI = MathOptInterface

"""
    parse_lp(raw::String)

Парсит строку-формулировку ЛП в компоненты:
- vars::Vector{String}
- types::Vector{String}
- c::Vector{Float64}
- sense::Symbol (:Max или :Min)
- A::Vector{Vector{Float64}}
- dirs::Vector{String}
- b::Vector{Float64}
"""
function parse_lp(raw::String)
    normalized = replace(raw, r"\]\s*\[" => "]\n[")
    lines = split(normalized, '\n')
    vars   = strip.(split(replace(lines[1], ['[', ']']=>""), ","))
    types  = strip.(split(replace(lines[2], ['[', ']']=>""), ","))
    obj    = strip.(split(replace(lines[3], ['[', ']']=>""), ","))
    c      = parse.(Float64, obj[1:end-1])
    sense  = obj[end] == "Maximize" ? :Max : :Min

    A = Vector{Vector{Float64}}()
    b = Float64[]
    dirs = String[]
    for line in lines[4:end]
        items = strip.(split(replace(line, ['[', ']']=>""), ","))
        coeffs = parse.(Float64, items[1:end-2])
        dir    = items[end-1]
        rhs    = parse(Float64, items[end])
        push!(A, coeffs)
        push!(dirs, dir)
        push!(b, rhs)
    end
    return vars, types, c, sense, A, dirs, b
end

"""
    solve_lp_string(raw::String) -> Dict

Решает задачу ЛП, заданную строкой raw.
Возвращает Dict:
  "objective_value" => Float64,
  "variables"      => Dict{String,Float64}
"""
function solve_lp_string(raw::String)
    @info("Парсинг и решение LP из строки...")
    vars, types, c, sense, A, dirs, b = parse_lp(raw)

    model = Model(GLPK.Optimizer)
    @variables(model, begin x[i=1:length(vars)] >= 0 end)
    for (i, t) in enumerate(types)
        if t == "Integer"
            set_integer(x[i])
        end
    end

    for (i, coeffs) in enumerate(A)
        expr = sum(coeffs[j] * x[j] for j in 1:length(vars))
        if dirs[i] == "<="
            @constraint(model, expr <= b[i])
        elseif dirs[i] == ">="
            @constraint(model, expr >= b[i])
        elseif dirs[i] == "=="
            @constraint(model, expr == b[i])
        else
            error("Неизвестный тип ограничения: $(dirs[i])")
        end
    end

    if sense == :Max
        @objective(model, Max, sum(c[j] * x[j] for j in 1:length(vars)))
    else
        @objective(model, Min, sum(c[j] * x[j] for j in 1:length(vars)))
    end

    optimize!(model)
    status = termination_status(model)
    if status != MOI.OPTIMAL
        @warn("Состояние оптимизации: $status")
    end

    sol = Dict(vars[i] => value(x[i]) for i in 1:length(vars))
    return Dict(
        "objective_value" => objective_value(model),
        "variables"      => sol
    )
end

end # module
