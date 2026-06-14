# Quick Start Guide - Russian DevOps Mentor

## Installation

1. Copy the `subagents/russian-devops-mentor` directory to your project
2. Load `system-prompt.md` as your agent's system message
3. Configure your LLM with Russian language preference

## First Test

Try this simple test to verify the agent is working correctly:

**Test Input:**
```
Как посмотреть список Docker контейнеров?
```

**Expected Output:**
```
docker ps -a

Показать все контейнеры (включая остановленные)
```

## Verification Checklist

After setup, verify these behaviors:

### ✅ Language Check
- [ ] Agent responds in Russian
- [ ] Technical terms are appropriate
- [ ] Grammar and syntax are correct

### ✅ Format Check
- [ ] Code/command appears FIRST
- [ ] Explanation is 1-2 lines maximum (if present)
- [ ] No unnecessary alternatives offered

### ✅ Step-by-Step Check
- [ ] Agent provides only ONE step at a time
- [ ] Waits for confirmation before next step
- [ ] Doesn't overwhelm with multi-step instructions

### ✅ Uncertainty Handling
- [ ] Asks clarifying questions when needed
- [ ] Doesn't guess or assume
- [ ] Requests exact error text for debugging

### ✅ Internal Process
- [ ] NO internal reasoning visible in output
- [ ] NO "let me think" or "I should check" in responses
- [ ] Only final verified answer is shown

## Common Use Cases

### 1. Troubleshooting
```
User: Kubernetes pod не запускается
Agent: kubectl describe pod <pod-name> -n <namespace>

Пришлите полный вывод, особенно секцию Events
```

### 2. Code Review
```
User: Проверь этот код
Agent: [Provides improved code first]

[Short explanation if critical]
```

### 3. Architecture Advice
```
User: Какую базу данных выбрать?
Agent: Какие требования к масштабируемости и консистентности?
```

## Troubleshooting Setup Issues

### Problem: Agent responds in English
**Solution:** Ensure system prompt is loaded correctly and temperature is set low (0.2-0.4)

### Problem: Agent provides multiple alternatives
**Solution:** Reinforce Rule 3 in system prompt - "NO ALTERNATIVES"

### Problem: Agent shows internal reasoning
**Solution:** Check that "INTERNAL ONLY REASONING" rule is enforced

### Problem: Agent gives long explanations
**Solution:** Remind about "FORMAT PRIORITY" rule - code first, minimal explanation

## Performance Tuning

### For Better Precision
- Lower temperature: 0.2-0.3
- Increase top_p: 0.9-0.95
- Use greedy decoding if available

### For Faster Responses
- Reduce max_tokens if not needed
- Use faster inference backend
- Cache common responses

## Integration Examples

### OpenAI API
```python
from openai import OpenAI

client = OpenAI()

with open("system-prompt.md", "r", encoding="utf-8") as f:
    system_prompt = f.read()

response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": "Как создать Docker образ?"}
    ],
    temperature=0.3,
    max_tokens=500
)

print(response.choices[0].message.content)
```

### Anthropic Claude
```python
import anthropic

client = anthropic.Anthropic()

with open("system-prompt.md", "r", encoding="utf-8") as f:
    system_prompt = f.read()

response = client.messages.create(
    model="claude-3-opus-20240229",
    max_tokens=500,
    temperature=0.3,
    system=system_prompt,
    messages=[
        {"role": "user", "content": "Как настроить CI/CD?"}
    ]
)

print(response.content[0].text)
```

## Next Steps

1. Test with various technical scenarios
2. Collect user feedback
3. Refine based on edge cases
4. Add domain-specific examples
5. Monitor quality metrics

## Support

For issues or questions, refer to:
- `README.md` - Complete documentation
- `agent-config.json` - Configuration reference
- `examples/interaction-examples.md` - Usage patterns
