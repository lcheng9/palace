# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

using CSV
using DataFrames
using Measures
using Plots
using PyPlot: matplotlib

"""
    generate_coplanar_waveguide_data(; num_processors::Integer=1)

Generate the data for the coplanar wave guide example

# Arguments

  - num_processors - number of processors to use for the simulation
"""
function generate_coplanar_waveguide_data(; num_processors::Integer=1)
    # Call the solver, discarding the terminal output
    cpw_dir = @__DIR__
    for sim ∈ ["lumped", "wave"]
        for mode ∈ ["adaptive", "uniform"]
            call_command = `palace -np $num_processors -wdir $cpw_dir cpw_$sim\_$mode.json`
            run(call_command)
        end
    end

    """
        Helper function for generating plots
    """
    function helper(pp, f1, data1, lbl1, f2, data2, lbl2, f3, data3, lbl3, f4, data4, lbl4)
        mkrsz = 8
        mkr1 = (:circle, mkrsz, stroke(0))
        mkr2 = (:utriangle, mkrsz, stroke(0))
        plot!(pp, f1, data1, label=lbl1)
        plot!(pp, f3, data3, label=lbl3)
        plot!(pp, f2, data2, label=lbl2, marker=mkr1, linewidth=0)
        return plot!(pp, f4, data4, label=lbl4, marker=mkr2, linewidth=0)
    end

    # Parse simulation data
    postpro_dir = joinpath(@__DIR__, "postpro")

    file = joinpath(postpro_dir, "lumped_adaptive", "port-S.csv")
    data_lumped_adaptive = CSV.File(file, header=1) |> DataFrame |> Matrix
    f_adaptive = data_lumped_adaptive[:, 1]
    data_lumped_adaptive = data_lumped_adaptive[:, 2:end]
    n_p = size(data_lumped_adaptive, 2) ÷ 2

    file = joinpath(postpro_dir, "wave_adaptive", "port-S.csv")
    data_wave_adaptive = CSV.File(file, header=1) |> DataFrame |> Matrix
    data_wave_adaptive = data_wave_adaptive[:, 2:end]

    file = joinpath(postpro_dir, "lumped_uniform", "port-S.csv")
    data_lumped_uniform = CSV.File(file, header=1) |> DataFrame |> Matrix
    f_uniform = data_lumped_uniform[:, 1]
    data_lumped_uniform = data_lumped_uniform[:, 2:end]

    file = joinpath(postpro_dir, "wave_uniform", "port-S.csv")
    data_wave_uniform = CSV.File(file, header=1) |> DataFrame |> Matrix
    data_wave_uniform = data_wave_uniform[:, 2:end]

    # Wrap phases
    for p = 1:n_p
        idx = (data_lumped_adaptive[:, 2 * p] .< 0.0)
        data_lumped_adaptive[idx, 2 * p] = data_lumped_adaptive[idx, 2 * p] .+ 180.0

        idx = (data_wave_adaptive[:, 2 * p] .< 0.0)
        data_wave_adaptive[idx, 2 * p] = data_wave_adaptive[idx, 2 * p] .+ 180.0

        idx = (data_lumped_uniform[:, 2 * p] .< 0.0)
        data_lumped_uniform[idx, 2 * p] = data_lumped_uniform[idx, 2 * p] .+ 180.0

        idx = (data_wave_uniform[:, 2 * p] .< 0.0)
        data_wave_uniform[idx, 2 * p] = data_wave_uniform[idx, 2 * p] .+ 180.0
    end

    # Plot settings
    pyplot()
    rcParams = PyPlot.PyDict(matplotlib["rcParams"])
    plotsz = (800, 400)
    fntsz = 12
    fnt = font(fntsz)
    rcParams["mathtext.fontset"] = "stix"
    default(
        size=plotsz,
        palette=:Set1_9,
        dpi=300,
        tickfont=fnt,
        guidefont=fnt,
        legendfontsize=fntsz - 2,
        margin=10mm
    )

    # Make plots
    xlim = (minimum(f_uniform) - 1.0, maximum(f_uniform) + 1.0)
    xlbl = "Frequency  (GHz)"

    ## Reflection
    p = 1

    # Magnitude
    ylbl = string("Reflection: abs(\$S_{11}\$)  (dB)")
    p1a = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomright)

    helper(
        p1a,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p - 1],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p - 1],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p - 1],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p - 1],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p1a, ylims=(first(ylims(p1a)) - 20, 0))
    savefig(p1a, joinpath(postpro_dir, "figure1a.png"))
    display(p1a)

    # Phase
    ylbl = string("Reflection: arg(\$S_{11}\$)  (deg.)")
    p1b = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomright)

    helper(
        p1b,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p1b, ylims=(first(ylims(p1b)) - 100, last(ylims(p1b)) + 0))
    savefig(p1b, joinpath(postpro_dir, "figure1b.png"))
    display(p1b)

    ## Transmission
    p = 2

    # Magnitude
    ylbl = string("Transmission: abs(\$S_{21}\$)  (dB)")
    p2a = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomleft)

    helper(
        p2a,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p - 1],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p - 1],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p - 1],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p - 1],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p2a, ylims=(first(ylims(p2a)) - 20, 2))
    savefig(p2a, joinpath(postpro_dir, "figure2a.png"))
    display(p2a)

    # Phase
    ylbl = string("Transmission: arg(\$S_{21}\$)  (deg.)")
    p2b = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomleft)

    helper(
        p2b,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p2b, ylims=(first(ylims(p2b)) - 60, last(ylims(p2b)) + 0))
    savefig(p2b, joinpath(postpro_dir, "figure2b.png"))
    display(p2b)

    ## NEXT
    p = 3

    # Magnitude
    ylbl = string("NEXT: abs(\$S_{31}\$)  (dB)")
    p3a = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomleft)

    helper(
        p3a,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p - 1],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p - 1],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p - 1],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p - 1],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p3a, ylims=(first(ylims(p3a)) - 30, 0))
    savefig(p3a, joinpath(postpro_dir, "figure3a.png"))
    display(p3a)

    # Phase
    ylbl = string("NEXT: arg(\$S_{31}\$)  (deg.)")
    p3b = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomright)

    helper(
        p3b,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p3b, ylims=(first(ylims(p3b)) - 100, last(ylims(p3b)) + 0))
    savefig(p3b, joinpath(postpro_dir, "figure3b.png"))
    display(p3b)

    ## FEXT
    p = 4

    # Magnitude
    ylbl = string("FEXT: abs(\$S_{41}\$)  (dB)")
    p4a = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomright)

    helper(
        p4a,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p - 1],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p - 1],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p - 1],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p - 1],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p4a, ylims=(first(ylims(p4a)) - 40, 0))
    savefig(p4a, joinpath(postpro_dir, "figure4a.png"))
    display(p4a)

    # Phase
    ylbl = string("FEXT: arg(\$S_{41}\$)  (deg.)")
    p4b = plot(xlims=xlim, xlabel=xlbl, ylabel=ylbl, legend=:bottomright)

    helper(
        p4b,
        f_adaptive,
        data_lumped_adaptive[:, 2 * p],
        string("Adaptive, Lumped Port ", string(p)),
        f_uniform,
        data_lumped_uniform[:, 2 * p],
        string("Uniform, Lumped Port ", string(p)),
        f_adaptive,
        data_wave_adaptive[:, 2 * p],
        string("Adaptive, Wave Port ", string(p)),
        f_uniform,
        data_wave_uniform[:, 2 * p],
        string("Uniform, Wave Port ", string(p))
    )

    plot!(p4b, ylims=(first(ylims(p4b)) - 120, last(ylims(p4b)) + 0))
    savefig(p4b, joinpath(postpro_dir, "figure4b.png"))
    return display(p4b)
end

"""
    cpw_impedance(;w,s,h,ϵᵣ)

Compute the characteristic impedance of a coplanar wave guide.
See p259 of
H. J. Visser, Antenna Theory and Applications, Wiley, Hoboken, NJ, 2012

# Arguments

    - w width of trace [μm]
    - s separation of trace [μm]
    - h height of substrate [μm]
    - ϵᵣ relative permittivity in surface normal direction
"""
function cpw_impedance(; w=30, s=18, h=500, ϵᵣ)
    k = w / (w + 2 * s)
    k₁ = sinh(π * w / (4 * h)) / sinh(π * (w + 2 * s) / (4 * h))

    k′ = sqrt(1 - k^2)
    k₁′ = sqrt(1 - k₁^2)

    function KoverK′(t, t′)
        s =
            x ->
                log(2 * (sqrt(1 + x) + (4 * x)^(1 // 4)) / (sqrt(1 + x) - (4 * x)^(1 // 4)))
        if t >= 1.0 / sqrt(2)
            return s(t) / (2 * π)
        else
            return 2 * π / s(t′)
        end
    end

    koverk′ = KoverK′(k, k′)
    k₁overk₁′ = KoverK′(k₁, k₁′)

    ϵ_eff = 1 + ((ϵᵣ - 1) / 2) * k₁overk₁′ / koverk′

    return Z₀ = 30 * π / (koverk′ * sqrt(ϵ_eff))
end
