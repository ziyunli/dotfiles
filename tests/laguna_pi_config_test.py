#!/usr/bin/env python3
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
path = root / "devices/Ziyuns-M5-MBP/.pi/agent/models.json"
data = json.loads(path.read_text())
provider = data["providers"]["laguna-local"]
model = provider["models"][0]

assert provider["baseUrl"] == "http://127.0.0.1:8000/v1"
assert provider["api"] == "openai-completions"
assert provider["apiKey"] == "local"
assert provider["compat"] == {
    "supportsDeveloperRole": False,
    "supportsReasoningEffort": False,
    "maxTokensField": "max_tokens",
    "requiresReasoningContentOnAssistantMessages": True,
    "thinkingFormat": "chat-template",
    "chatTemplateKwargs": {
        "enable_thinking": {"$var": "thinking.enabled"}
    },
}
assert model == {
    "id": "laguna-s-2.1",
    "name": "Laguna S 2.1 Q4_K_M (Local)",
    "reasoning": True,
    "thinkingLevelMap": {
        "minimal": None,
        "low": None,
        "medium": None,
        "high": None,
        "xhigh": None,
        "max": "max",
    },
    "input": ["text"],
    "contextWindow": 32768,
    "maxTokens": 16384,
    "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
}
print("ok - Laguna Pi model configuration checks passed")
