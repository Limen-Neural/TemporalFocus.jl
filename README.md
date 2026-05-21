# SpikenautAttention.jl

Pure spike-native temporal interaction primitives for the Spikenaut ecosystem.

## Scope

This package is intentionally narrow.

It owns:
- spike events, spike trains, and temporal buffers
- coincidence-based and temporally decayed spike interaction
- synaptic/readout application over spike-derived weights
- local SNN learning hooks such as STDP-style updates

It does not own:
- transformer dimensions
- token embeddings
- gating mechanisms
- projector weights between SNN and LLM spaces
- LLM-side fusion logic

If a feature requires knowledge of tokens, embeddings, dense attention semantics, or model-space projection weights, it belongs outside this repository.


## Interface Contract

Inputs to this package should be pure SNN quantities:

- `SpikeTrain`
- `TemporalBuffer`
- synaptic or readout matrices defined over neuron indices
- reward or neuromodulatory signals used by local plasticity rules

Outputs from this package should remain pure SNN quantities or direct neuron-space readouts:

- spike-derived weight vectors
- neuron-space readout vectors
- updated synaptic weights

## Current API

- `spike_attention_discrete`
- `spike_attention_temporal`
- `spike_attention_continuous`
- `temporal_weight`
- `normalize_l1!`
- `normalize_max!`
- `prune!`

## Migration Note

**STDP and plasticity removed in v0.1.0:**

The `stdp_update!` function has been removed from this package. Synaptic plasticity, including STDP, Hebbian learning, reward-modulated plasticity, and eligibility traces, should be implemented in a dedicated plasticity package such as `plasticity-lab` or a future Julia plasticity adapter.

TemporalFocus.jl focuses exclusively on spike-native temporal attention and does not own learning rules or weight updates.

## Non-Goals

This repository should not accumulate adapter code for:

- tokenization
- embeddings
- transformer attention
- fusion gates
- cross-modal projector training
- hybrid orchestration
