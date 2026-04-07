"""Patch edge-tts 7.x to restore mktimestamp removed in the SubMaker module.

MoneyPrinterTurbo imports `from edge_tts.submaker import mktimestamp`, which was
removed in edge-tts 7.0. This script injects the function back so the app works
with the latest edge-tts (which has updated GEC tokens needed to avoid 403 errors).
"""

import importlib
import math
import edge_tts.submaker as submaker_mod


def mktimestamp(time_unit: float) -> str:
    hour = math.floor(time_unit / 10**7 / 3600)
    minute = math.floor((time_unit / 10**7 / 60) % 60)
    seconds = (time_unit / 10**7) % 60
    return f"{hour:02d}:{minute:02d}:{seconds:06.3f}"


if not hasattr(submaker_mod, "mktimestamp"):
    submaker_mod.mktimestamp = mktimestamp
