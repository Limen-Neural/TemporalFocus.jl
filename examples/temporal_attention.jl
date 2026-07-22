# SPDX-License-Identifier: MIT OR Apache-2.0
# Run: julia --project=. examples/temporal_attention.jl

using TemporalFocus

# Same source/context pair with a non-zero time lag (dt = 0.20).
source = SpikeTrain([SpikeEvent(1, 0.10f0, 1.0f0)])
context = SpikeTrain([SpikeEvent(1, 0.30f0, 1.0f0)])
readout = Float32[
    2 1
    0 3
]

# Small τ decays faster → weaker contribution for the same lag.
out_small_τ = spike_attention_temporal(source, context, readout; τ = 0.05f0)
out_large_τ = spike_attention_temporal(source, context, readout; τ = 1.0f0)

w_small = temporal_weight(0.20f0, 0.05f0)
w_large = temporal_weight(0.20f0, 1.0f0)

println("temporal_weight(dt=0.20, τ=0.05) = ", w_small)
println("temporal_weight(dt=0.20, τ=1.00) = ", w_large)
println("Readout with small τ: ", out_small_τ)
println("Readout with large τ: ", out_large_τ)
println("Large τ preserves more mass: ", abs(out_large_τ[1]) > abs(out_small_τ[1]))
