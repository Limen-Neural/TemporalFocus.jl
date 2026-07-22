# SPDX-License-Identifier: MIT OR Apache-2.0

"""
TemporalFocus.jl BenchmarkTools suite.

Run from the repository root:

    julia --project=benchmark -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=benchmark benchmark/run_benchmarks.jl

Event counts are capped (small=64, medium=500) to avoid O(n²) blowup in the
pairwise attention kernels. Results print median time and allocations.
"""

using BenchmarkTools
using Random
using TemporalFocus

const RNG_SEED = 42
const N_NEURONS = 32
const N_OUT = 8
const τ = 0.20f0
const WINDOW = 0.50f0
const T_MAX = 1.0f0

# Cap event counts to keep pairwise kernels tractable.
const SCALES = (
    small = 64,
    medium = 500,
)

function _make_events(n_events::Int, n_neurons::Int; t_max::Float32 = T_MAX)
    return SpikeEvent[
        SpikeEvent(rand(1:n_neurons), rand(Float32) * t_max, 1.0f0) for _ in 1:n_events
    ]
end

function _make_train(n_events::Int, n_neurons::Int)
    return SpikeTrain(_make_events(n_events, n_neurons))
end

function _make_buffer(n_events::Int, n_neurons::Int; window::Float32 = WINDOW)
    return TemporalBuffer(window, _make_events(n_events, n_neurons))
end

function _make_readout(n_neurons::Int, n_out::Int = N_OUT)
    return rand(Float32, n_neurons, n_out)
end

function _make_suite()
    suite = BenchmarkGroup()
    suite["attention"] = BenchmarkGroup()
    suite["attention"]["discrete"] = BenchmarkGroup()
    suite["attention"]["temporal"] = BenchmarkGroup()
    suite["attention"]["continuous"] = BenchmarkGroup()
    suite["normalize"] = BenchmarkGroup()
    suite["normalize"]["l1"] = BenchmarkGroup()
    suite["normalize"]["max"] = BenchmarkGroup()
    suite["prune"] = BenchmarkGroup()
    suite["temporal_weight"] = BenchmarkGroup()

    for (scale_name, n_events) in pairs(SCALES)
        Random.seed!(RNG_SEED)
        q = _make_train(n_events, N_NEURONS)
        k = _make_train(n_events, N_NEURONS)
        v = _make_readout(N_NEURONS)
        bq = _make_buffer(n_events, N_NEURONS)
        bk = _make_buffer(n_events, N_NEURONS)

        suite["attention"]["discrete"][string(scale_name)] =
            @benchmarkable spike_attention_discrete($q, $k, $v)
        suite["attention"]["temporal"][string(scale_name)] =
            @benchmarkable spike_attention_temporal($q, $k, $v; τ = $τ)
        suite["attention"]["continuous"][string(scale_name)] =
            @benchmarkable spike_attention_continuous($bq, $bk, $v; τ = $τ)

        # Prune: mix of in-window and expired events so work is non-trivial.
        Random.seed!(RNG_SEED + 1)
        stale = _make_events(n_events ÷ 2, N_NEURONS; t_max = 0.10f0)
        fresh = _make_events(n_events - length(stale), N_NEURONS; t_max = T_MAX)
        prune_events = vcat(stale, fresh)
        # Setup rebuilds the buffer each eval so prune! always has the same input
        # (evals=1 forces setup per evaluation; prune! mutates buf.events).
        suite["prune"][string(scale_name)] = @benchmarkable(
            prune!(buf, $T_MAX),
            setup = (buf = TemporalBuffer($WINDOW, copy($prune_events))),
            evals = 1,
        )
    end

    # Normalization scales with vector length (not event count).
    for (scale_name, n) in ((:small, 64), (:medium, 500), (:large, 10_000))
        Random.seed!(RNG_SEED)
        w = rand(Float32, n)
        suite["normalize"]["l1"][string(scale_name)] =
            @benchmarkable(normalize_l1!(x), setup = (x = copy($w)))
        suite["normalize"]["max"][string(scale_name)] =
            @benchmarkable(normalize_max!(x), setup = (x = copy($w)))
    end

    # Optional micro-benchmark for the decay kernel.
    suite["temporal_weight"]["micro"] =
        @benchmarkable temporal_weight(dt, τ_local) setup = begin
            dt = rand(Float32) - 0.5f0
            τ_local = 0.20f0
        end

    return suite
end

function _print_trial(path::AbstractString, trial::BenchmarkTools.Trial)
    m = median(trial)
    t = BenchmarkTools.prettytime(m.time)
    mem = BenchmarkTools.prettymemory(m.memory)
    allocs = m.allocs
    println(rpad(path, 48), "  median=", rpad(t, 12), "  allocs=", allocs, "  memory=", mem)
end

function _print_results(group::BenchmarkGroup, prefix::String = "")
    for key in sort!(collect(keys(group)); by = string)
        value = group[key]
        path = isempty(prefix) ? string(key) : string(prefix, "/", key)
        if value isa BenchmarkGroup
            _print_results(value, path)
        else
            _print_trial(path, value)
        end
    end
end

function main()
    Random.seed!(RNG_SEED)
    println("TemporalFocus.jl benchmarks")
    println("  seed=", RNG_SEED, "  neurons=", N_NEURONS, "  scales=", SCALES)
    println()

    suite = _make_suite()
    # Warmup / tune parameters, then collect samples.
    tune!(suite; verbose = false)
    results = run(suite; verbose = true)

    println()
    println("Median time and allocations")
    println("-"^80)
    _print_results(results)
    println("-"^80)
    return results
end

main()
