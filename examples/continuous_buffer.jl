# SPDX-License-Identifier: MIT OR Apache-2.0
# Run: julia --project=. examples/continuous_buffer.jl

using TemporalFocus

# Sliding temporal buffer with a fixed retention window.
window = 0.30f0
source_buf = TemporalBuffer(window, [
    SpikeEvent(1, 0.50f0, 1.0f0),
    SpikeEvent(2, 0.10f0, 1.0f0),  # older than window once time advances
])
context_buf = TemporalBuffer(window, [
    SpikeEvent(1, 0.35f0, 1.0f0),  # within |dt| of source at t=0.50
    SpikeEvent(1, 0.90f0, 1.0f0),  # outside continuous interaction window
    SpikeEvent(2, 0.05f0, 1.0f0),
])

println("Before prune! — source events: ", length(source_buf.events),
        ", context events: ", length(context_buf.events))

# Drop events older than `window` relative to current_time.
current_time = 0.50f0
prune!(source_buf, current_time)
prune!(context_buf, current_time)

println("After prune!(…, $(current_time)) — source events: ", length(source_buf.events),
        ", context events: ", length(context_buf.events))
println("Source neuron IDs kept: ", [e.neuron_id for e in source_buf.events])
println("Context neuron IDs kept: ", [e.neuron_id for e in context_buf.events])

readout = Float32[
    1 2
    3 4
]

out = spike_attention_continuous(source_buf, context_buf, readout; τ = 0.15f0)
println("Continuous attention readout: ", out)
