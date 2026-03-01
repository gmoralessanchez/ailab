#!/usr/bin/env python3
"""
Patch openvino_accelerate.py to guard against a None refiner model.

The OpenVINO "Accelerate with OpenVINO" script's refiner dropdown may
default to the only available checkpoint instead of "None".  When the
selected checkpoint is not an SDXL model the refiner pipeline cannot be
created, leaving shared.sd_refiner_model as None and crashing on
attribute access.

This patch adds None-guards so that a missing / invalid refiner is
silently skipped instead of raising an AttributeError.
"""

import sys

path = "scripts/openvino_accelerate.py"

with open(path, "r") as f:
    content = f.read()

# Normalise to LF for reliable matching (file may have CRLF)
content = content.replace("\r\n", "\n")

# --- Fix 1 ---------------------------------------------------------------
# Wrap the refiner model creation in try/except and add a None guard for
# the scheduler assignment.  Loading an SD 1.5 checkpoint as an SDXL
# refiner raises a TypeError; we want to gracefully skip the refiner
# rather than crash the whole request.
content = content.replace(
    "                shared.sd_refiner_model = get_diffusers_sd_refiner_model(model_config, vae_ckpt, sampler_name, enable_caching, openvino_device, mode, is_xl_ckpt, refiner_ckpt, refiner_frac)\n"
    "                shared.sd_refiner_model.scheduler = set_scheduler(shared.sd_refiner_model, sampler_name)\n",
    "                try:\n"
    "                    shared.sd_refiner_model = get_diffusers_sd_refiner_model(model_config, vae_ckpt, sampler_name, enable_caching, openvino_device, mode, is_xl_ckpt, refiner_ckpt, refiner_frac)\n"
    "                except Exception as e:\n"
    '                    print(f"OpenVINO Script: failed to load refiner model, skipping refiner: {e}")\n'
    "                    shared.sd_refiner_model = None\n"
    "                if shared.sd_refiner_model is not None:\n"
    "                    shared.sd_refiner_model.scheduler = set_scheduler(shared.sd_refiner_model, sampler_name)\n",
)

# --- Fix 2 ---------------------------------------------------------------
# Guard the refiner inference call.
content = content.replace(
    '            if refiner_ckpt != "None":\n'
    "                refiner_output = shared.sd_refiner_model(\n",
    '            if refiner_ckpt != "None" and shared.sd_refiner_model is not None:\n'
    "                refiner_output = shared.sd_refiner_model(\n",
)

# --- Fix 3 ---------------------------------------------------------------
# Guard the output selection that uses refiner_output (which only exists
# when the refiner actually ran).
content = content.replace(
    '            if refiner_ckpt != "None":\n'
    "                x_samples_ddim = refiner_output.images\n",
    '            if refiner_ckpt != "None" and shared.sd_refiner_model is not None:\n'
    "                x_samples_ddim = refiner_output.images\n",
)

with open(path, "w") as f:
    f.write(content)

print("patch_openvino.py: refiner None-guard patches applied successfully")
