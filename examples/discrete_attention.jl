# SPDX-License-Identifier: MIT OR Apache-2.0
# Run: julia --project=. examples/discrete_attention.jl

using TemporalFocus

# Build source and context spike trains (coincidence by neuron_id only).
source = SpikeTrain([
    SpikeEvent(1, 0.10f0, 1.0f0),
    SpikeEvent(2, 0.20f0, 1.0f0),
])
context = SpikeTrain([
    SpikeEvent(1, 0.15f0, 1.0f0),
    SpikeEvent(1, 0.25f0, 1.0f0),
    SpikeEvent(3, 0.30f0, 1.0f0),
])

# Readout matrix: rows = neurons, columns = readout dimensions.
readout = Float32[
    1 0
    0 1
    1 1
]

out = spike_attention_discrete(source, context, readout)

println("Discrete attention readout: ", out)
# Neuron 1 has two context coincidences → contribution 2 on dim 1.
# Neuron 2 has none; neuron 3 is never a source → dims: [2, 0].
