include("../src/ValueIterationVehicleRouting.jl")
using .ValueIterationVehicleRouting
using BenchmarkTools
using Statistics
using Plots
using LaTeXStrings

# Propterties of plots
gr(titleloc = :right,titlefont = font(15),linewidth = 2,markersize = 6)
labels = ["Line","Clusters","Evenly Distributed"]

# Variables used:
# T:   Time period availabe
# I:   Geographical locations with I[1] = start depot and I[end] = end depot
# IA:  Advance customer locations
# P_C: Cancellation costs
# P_R: Reactivation costs
# α:   Probability of customer requesting

@info "Benchmarking Value Iteration for different instances of the Service Vehicle Routing Problem"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@info "Varying number of customers"

# Result arrays
b1_results = []
b1_benchmarks = []

# Constants for this test case
T = 10; IA = [2]; P_C = 0.2; P_R = 0.1; α = 0.5

# I is varied in this test case
I_VARIANTS = [
    # Customers placed on a line
    [(0.0, 0.0), (1.0, 0.0), (10.0, 0.0)], # 1 Customer
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (10.0, 0.0)], # 2 Customers
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (10.0, 0.0)], # 3 Customers
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (10.0, 0.0)], # 4 Customers
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (5.0, 0.0), (10.0, 0.0)], # 5 Customers
    # Customers placed in clusters
    [(0.0, 0.0), (1.0, 3.0), (2.0, 2.0)], # 1 Customer
    [(0.0, 0.0), (1.0, 3.0), (3.0, 1.0), (2.0, 2.0)], # 2 Customers
    [(0.0, 0.0), (1.0, 3.0), (1.0, 2.5), (3.0, 1.0), (2.0, 2.0)], # 3 Customers
    [(0.0, 0.0), (1.0, 3.0), (1.0, 2.5), (2.5, 1.0), (3.0, 1.0), (2.0, 2.0)], # 4 Customers
    [(0.0, 0.0), (1.0, 1.0), (1.0, 3.0), (1.0, 2.5), (2.5, 1.0), (3.0, 1.0), (2.0, 2.0)], # 5 Customers
    # Evenly distributed customers
    [(0.0, 0.0), (0.5, 1.0), (2.0, 2.0)], # 1 Customer
    [(0.0, 0.0), (0.5, 1.0), (1.0, 0.5), (2.0, 2.0)], # 2 Customers
    [(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (2.0, 2.0)], # 3 Customers
    [(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (2.0, 0.5), (2.0, 2.0)], # 4 Customers
    [(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (1.5, 1.5), (2.0, 0.5), (2.0, 2.0)] # 5 Customers
]

for I in I_VARIANTS
    push!(b1_results, ValueIterationVehicleRouting.value_iteration(T, I, IA, P_C, P_R, α))
    push!(b1_benchmarks, @benchmark ValueIterationVehicleRouting.value_iteration($T, $I, $IA, $P_C, $P_R, $α))
end

# No of customers
x = map(I -> length(I) - 2,I_VARIANTS)[1:5]

y_contribution = reshape(map(r -> r.expected_contribution, b1_results), (5, 3))
y_no_states = reshape(map(r -> r.number_pre_decision_states, b1_results), (5, 3))
y_mem_usage = reshape(map(b -> b.memory / 1000^3, b1_benchmarks), (5, 3))
y_runtime = reshape(map(b -> mean(b.times) / 1000^3, b1_benchmarks), (5, 3))

xlabel = L"|\mathcal{I}^c|"

contribution = plot(x,y_contribution,xlabel=xlabel,ylabel=L"C^\pi",shape=:circle,label=labels,legend=:topleft,title="(a)")
no_states = plot(x,y_no_states,xlabel=xlabel,ylabel=L"|\mathcal{S}|",shape=:circle,label=labels,legend=:topleft,title="(b)")
runtime = plot(x,y_runtime,xlabel=xlabel,ylabel="Mean Runtime (s)",shape=:circle,label=labels,legend=:topleft,title="(c)")
mem_usage = plot(x,y_mem_usage,xlabel=xlabel,ylabel="Estimated Memory Usage (GB)",shape=:circle,label=labels,legend=:topleft,title="(d)")

savefig(contribution,"b1-contribution.pdf")
savefig(no_states,"b1-no_states.pdf")
savefig(mem_usage,"b1-mem_usage.pdf")
savefig(runtime,"b1-runtime.pdf")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@info "Varying exogenous processes - α"

# Result arrays
b2_results = []
b2_benchmarks = []

# Constants for this test case
T = 10; IA = [2]; P_C = 0.2; P_R = 0.1

# α is varied in this test case for different variants of customer placements
Α = [0.1:0.1:0.9;]
I_VARIANTS = [
    # Customers placed on a line
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (5.0, 0.0), (10.0, 0.0)], # 5 Customers
    # Customers placed in clusters
    [(0.0, 0.0), (1.0, 1.0), (1.0, 3.0), (1.0, 2.5), (2.5, 1.0), (3.0, 1.0), (2.0, 2.0)], # 5 Customers
    # Evenly distributed customers
    [(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (1.5, 1.5), (2.0, 0.5), (2.0, 2.0)] # 5 Customers
]

for I in I_VARIANTS
    for α in Α
        push!(b2_results, ValueIterationVehicleRouting.value_iteration(T, I, IA, P_C, P_R, α))
        push!(b2_benchmarks, @benchmark ValueIterationVehicleRouting.value_iteration($T, $I, $IA, $P_C, $P_R, $α))
    end
end

y_contribution = reshape(map(r -> r.expected_contribution, b2_results), (9, 3))
y_no_states = reshape(map(r -> r.number_pre_decision_states, b2_results), (9, 3))
y_mem_usage = reshape(map(b -> b.memory / 1000^3, b2_benchmarks), (9, 3))
y_runtime = reshape(map(b -> mean(b.times) / 1000^3, b2_benchmarks), (9, 3))

xlabel=L"\alpha"

contribution = plot(Α,y_contribution,xlabel=xlabel,ylabel=L"C^\pi",shape=:circle,label=labels,legend=:bottomright,title="(a)")
no_states = plot(Α,y_no_states,xlabel=xlabel,ylabel=L"|\mathcal{S}|",shape=:circle,label=labels,legend=:bottomright,title="(b)")
runtime = plot(Α,y_runtime,xlabel=xlabel,ylabel="Mean Runtime (s)",shape=:circle,label=labels,legend=:bottomright,title="(c)")
mem_usage = plot(Α,y_mem_usage,xlabel=xlabel,ylabel="Estimated Memory Usage (GB)",shape=:circle,label=labels,legend=:bottomright,title="(d)")

savefig(contribution,"b2-contribution.pdf")
savefig(no_states,"b2-no_states.pdf")
savefig(mem_usage,"b2-mem_usage.pdf")
savefig(runtime,"b2-runtime.pdf")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@info "Test case: Varying exogenous processes - IA"

# Result arrays
b3_results = []
b3_benchmarks = []

# Constants for this test case
T = 10; P_C = 0.2; P_R = 0.1; α = 0.5

# IA is varied in this test case for different variants of customer placements
IA_VARIANTS = [
    # Nearest customer locations added first
    [2],
    [2,3],
    [2,3,4],
    [2,3,4,5],
    # Furthest customer locations added first
    [5],
    [5,4],
    [5,4,3],
    [5,4,3,2]
]
I_VARIANTS = [
    # Customers placed on a line
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (5.0, 0.0), (10.0, 0.0)], # 5 Customers
    # Customers placed in clusters
    [(0.0, 0.0), (1.0, 1.0), (1.0, 3.0), (1.0, 2.5), (2.5, 1.0), (3.0, 1.0), (2.0, 2.0)], # 5 Customers
    # Evenly distributed customers
    [(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (1.5, 1.5), (2.0, 0.5), (2.0, 2.0)] # 5 Customers
]

for I in I_VARIANTS
    for IA in IA_VARIANTS
        push!(b3_results, ValueIterationVehicleRouting.value_iteration(T, I, IA, P_C, P_R, α))
        push!(b3_benchmarks, @benchmark ValueIterationVehicleRouting.value_iteration($T, $I, $IA, $P_C, $P_R, $α))
    end
end

# No of advance customers
x = map(I -> length(I),IA_VARIANTS)[1:4]

y_contribution = reshape(map(r -> r.expected_contribution, b3_results), (4, 6))
y_no_states = reshape(map(r -> r.number_pre_decision_states, b3_results), (4, 6))
y_mem_usage = reshape(map(b -> b.memory / 1000^3, b3_benchmarks), (4, 6))
y_runtime = reshape(map(b -> mean(b.times) / 1000^3, b3_benchmarks), (4, 6))

xlabel = L"|\mathcal{I}^{ca}|"

contribution1 = plot(x,y_contribution[:,1:3],xlabel=xlabel,ylabel=L"C^\pi",shape=:circle,label=labels,legend=:bottomright,title="(a.1)")
contribution2 = plot(x,y_contribution[:,4:6],xlabel=xlabel,ylabel=L"C^\pi",shape=:circle,label=labels,legend=:bottomright,title="(a.2)")

no_states1 = plot(x,y_no_states[:,1:3],xlabel=xlabel,ylabel=L"|\mathcal{S}|",shape=:circle,label=labels,legend=:bottomright,title="(b.1)")
no_states2 = plot(x,y_no_states[:,4:6],xlabel=xlabel,ylabel=L"|\mathcal{S}|",shape=:circle,label=labels,legend=:bottomright,title="(b.2)")

runtime1 = plot(x,y_runtime[:,1:3],xlabel=xlabel,ylabel="Mean Runtime (s)",shape=:circle,label=labels,legend=:bottomright,title="(c.1)")
runtime2 = plot(x,y_runtime[:,4:6],xlabel=xlabel,ylabel="Mean Runtime (s)",shape=:circle,label=labels,legend=:bottomright,title="(c.2)")

mem_usage1 = plot(x,y_mem_usage[:,1:3],xlabel=xlabel,ylabel="Estimated Memory Usage (GB)",shape=:circle,label=labels,legend=:bottomright,title="(d.1)")
mem_usage2 = plot(x,y_mem_usage[:,4:6],xlabel=xlabel,ylabel="Estimated Memory Usage (GB)",shape=:circle,label=labels,legend=:bottomright,title="(d.2)")

savefig(contribution1,"b3-contribution1.pdf")
savefig(contribution2,"b3-contribution2.pdf")
savefig(no_states1,"b3-no_states1.pdf")
savefig(no_states2,"b3-no_states2.pdf")
savefig(mem_usage1,"b3-mem_usage1.pdf")
savefig(mem_usage2,"b3-mem_usage2.pdf")
savefig(runtime1,"b3-runtime1.pdf")
savefig(runtime2,"b3-runtime2.pdf")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@info "Test case: Varying punitive costs"

# Result arrays
b4_results = []
b5_results = []

# Constants for this test case
T = 10; IA = [2]; α = 0.5

# P_C is varied in this test case for different variants of customer placements
P_C_VARIANTS = [0.0:0.2:3.0;]
P_R_VARIANTS = [0.0:0.1:1.5;]
I_VARIANTS = [
    # Customers placed on a line
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (5.0, 0.0), (10.0, 0.0)], # 5 Customers
    # Customers placed in clusters
    [(0.0, 0.0), (1.0, 1.0), (1.0, 3.0), (1.0, 2.5), (2.5, 1.0), (3.0, 1.0), (2.0, 2.0)], # 5 Customers
    # Evenly distributed customers
    [(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (1.5, 1.5), (2.0, 0.5), (2.0, 2.0)] # 5 Customers
]

P_R = 0.1
for I in I_VARIANTS
    for P_C in P_C_VARIANTS
        push!(b4_results, ValueIterationVehicleRouting.value_iteration(T, I, IA, P_C, P_R, α))
    end
end

P_C = 0.2
for I in I_VARIANTS
    for P_R in P_R_VARIANTS
        push!(b5_results, ValueIterationVehicleRouting.value_iteration(T, I, IA, P_C, P_R, α))
    end
end

y_contribution1 = reshape(map(r -> r.expected_contribution, b4_results), (16, 3))
y_contribution2 = reshape(map(r -> r.expected_contribution, b5_results), (16, 3))

contribution1 = plot(P_C_VARIANTS,y_contribution1,xlabel=L"p^c",ylabel=L"C^\pi",shape=:circle,label=labels,legend=:best,title="(a.1)")
contribution2 = plot(P_C_VARIANTS,y_contribution2,xlabel=L"p^r",ylabel=L"C^\pi",shape=:circle,label=labels,legend=:best,title="(a.2)")

savefig(contribution1,"b4-contribution1.pdf")
savefig(contribution2,"b4-contribution2.pdf")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
@info "Test case: Varying T"

# Result arrays
b6_results = []
b6_benchmarks = []

# Constants for this test case
IA = [2]; P_C = 0.2; P_R = 0.1; α = 0.5

# T is varied in this test case for different variants of customer placements
T_VARIANTS = [2:10;]
I_VARIANTS = [
    # Customers placed on a line
    [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (5.0, 0.0), (6.0, 0.0)], # 5 Customers
    # Customers placed in clusters
    [(0.0, 0.0), (1.0, 1.0), (1.0, 3.0), (1.0, 2.5), (2.5, 1.0), (3.0, 1.0), (2.0, 2.0)], # 5 Customers
    # Evenly distributed customers
    [(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (1.5, 1.5), (2.0, 0.5), (2.0, 2.0)] # 5 Customers
]

for I in I_VARIANTS
    for T in T_VARIANTS
        push!(b6_results, ValueIterationVehicleRouting.value_iteration(T, I, IA, P_C, P_R, α))
        push!(b6_benchmarks, @benchmark ValueIterationVehicleRouting.value_iteration($T, $I, $IA, $P_C, $P_R, $α))
    end
end

y_contribution = reshape(map(r -> r.expected_contribution, b6_results), (9, 3))
y_no_states = reshape(map(r -> r.number_pre_decision_states, b6_results), (9, 3))
y_mem_usage = reshape(map(b -> b.memory / 1000^3, b6_benchmarks), (9, 3))
y_runtime = reshape(map(b -> mean(b.times) / 1000^3, b6_benchmarks), (9, 3))

xlabel=L"T"

contribution = plot(T_VARIANTS,y_contribution,xlabel=xlabel,ylabel=L"C^\pi",shape=:circle,label=labels,legend=:bottomright,title="(a)")
no_states = plot(T_VARIANTS,y_no_states,xlabel=xlabel,ylabel=L"|\mathcal{S}|",shape=:circle,label=labels,legend=:topleft,title="(b)")
runtime = plot(T_VARIANTS,y_runtime,xlabel=xlabel,ylabel="Mean Runtime (s)",shape=:circle,label=labels,legend=:topleft,title="(c)")
mem_usage = plot(T_VARIANTS,y_mem_usage,xlabel=xlabel,ylabel="Estimated Memory Usage (GB)",shape=:circle,label=labels,legend=:topleft,title="(d)")

savefig(contribution,"b6-contribution.pdf")
savefig(no_states,"b6-no_states.pdf")
savefig(mem_usage,"b6-mem_usage.pdf")
savefig(runtime,"b6-runtime.pdf")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Scatterplots of customer placements
savefig(scatter([(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0), (5.0, 0.0), (10.0, 0.0)], color=[:green,:blue,:blue,:blue,:blue,:blue,:red], shape=[:utriangle,:circle,:circle,:circle,:circle,:circle,:pentagon],legend=false,xlabel=L"x",ylabel=L"y",title="(a)",xlims = (-0.5,10.5),xticks = 0:1:10,ylims = (-0.5,5.5),yticks = 0:1:5),"line.pdf")
savefig(scatter([(0.0, 0.0), (1.0, 1.0), (1.0, 3.0), (1.0, 2.5), (2.5, 1.0), (3.0, 1.0), (2.0, 2.0)], color=[:green,:blue,:blue,:blue,:blue,:blue,:red], shape=[:utriangle,:circle,:circle,:circle,:circle,:circle,:pentagon],legend=false,xlabel=L"x",ylabel=L"y",title="(b)",xlims = (-0.5,10.5),xticks = 0:1:10,ylims = (-0.5,5.5),yticks = 0:1:5),"clusters.pdf")
savefig(scatter([(0.0, 0.0), (0.5, 1.0), (0.5, 2.0), (1.0, 0.5), (1.5, 1.5), (2.0, 0.5), (2.0, 2.0)], color=[:green,:blue,:blue,:blue,:blue,:blue,:red], shape=[:utriangle,:circle,:circle,:circle,:circle,:circle,:pentagon],legend=false,xlabel=L"x",ylabel=L"y",title="(c)",xlims = (-0.5,10.5),xticks = 0:1:10,ylims = (-0.5,5.5),yticks = 0:1:5),"evenly.pdf")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
