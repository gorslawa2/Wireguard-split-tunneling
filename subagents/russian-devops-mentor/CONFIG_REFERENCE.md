# Configuration Reference Guide

## File Structure Overview

```
subagents/russian-devops-mentor/
├── agent-config.json          # Machine-readable configuration
├── system-prompt.md           # LLM system prompt (human-readable)
├── README.md                  # Complete documentation
├── QUICKSTART.md             # Quick start guide
├── TEST_SCENARIOS.md         # Testing framework
├── CREATION_SUMMARY.md       # This creation summary
├── verify_config.py          # Verification script
└── examples/
    └── interaction-examples.md  # Usage examples
```

## Configuration Files Explained

### 1. agent-config.json
**Purpose**: Machine-readable configuration for programmatic access

**Key Sections**:
- `agent`: Name, version, description, persona
- `internal_process`: Expert team, reasoning phrases, workflow
- `output_rules`: Six strict rules with enforcement levels
- `goal`: Core principle and metrics
- `usage_scenarios`: List of applicable use cases
- `response_templates`: Format patterns for different response types

**Usage**: Import in applications that need structured access to agent configuration

### 2. system-prompt.md
**Purpose**: Complete system prompt for LLM integration

**Key Sections**:
- Identity definition
- Internal reasoning process (hidden from users)
- Six output rules with detailed explanations
- Response patterns with examples
- Expertise areas
- Communication style guidelines
- Prohibited behaviors
- Example correct responses

**Usage**: Copy entire content as system message in LLM API calls

### 3. README.md
**Purpose**: Comprehensive documentation for developers

**Contents**:
- Overview and key features
- Internal expert team explanation
- Dual perspective analysis
- Strict output rules detailed
- Integration guides (API and chat platforms)
- Quality metrics
- Customization options
- Best practices

**Usage**: Reference for understanding and customizing the agent

### 4. QUICKSTART.md
**Purpose**: Get started quickly with minimal reading

**Contents**:
- Installation steps (3 steps)
- First test case with expected output
- Verification checklist (5 categories)
- Common use cases (3 examples)
- Troubleshooting setup issues (4 common problems)
- Performance tuning tips
- Integration code examples (OpenAI, Anthropic)

**Usage**: Follow step-by-step for initial setup

### 5. TEST_SCENARIOS.md
**Purpose**: Verify agent behavior after setup

**Contents**:
- 10 test scenarios covering all key behaviors
- Scoring rubric (0-2 per test, passing: 18/20)
- Common failures list
- Improvement actions

**Usage**: Run tests after setup to ensure compliance

### 6. verify_config.py
**Purpose**: Automated configuration verification

**Checks**:
- All required files exist
- JSON configuration is valid
- Required fields present in JSON
- File sizes are reasonable
- UTF-8 encoding correct

**Usage**: Run `python verify_config.py` to validate setup

### 7. examples/interaction-examples.md
**Purpose**: Demonstrate correct agent behavior

**Contents**: Reference to full examples in documentation

**Usage**: Study patterns for training or fine-tuning

## Key Configuration Parameters

### Agent Identity
```json
{
  "name": "Russian DevOps Mentor",
  "name_ru": "Наставник программист и DevOps",
  "language": "ru-RU",
  "communication_style": "minimal_precise_russian"
}
```

### Internal Process
- **Expert Team**: 3 members (critic, designer, analyst)
- **Reasoning Phrases**: 5 Russian phrases for internal use
- **Workflow**: 5-step debate process
- **Dual Perspective**: Professor + Inventor

### Output Rules (Critical)
1. ONE_STEP_AT_A_TIME
2. FORMAT_PRIORITY (code first)
3. NO_ALTERNATIVES
4. ASK_NOT_GUESS
5. ERROR_EXACT_TEXT
6. INTERNAL_ONLY_REASONING

### Performance Settings
- **Temperature**: 0.2-0.4 (recommended)
- **Top_p**: 0.9-0.95
- **Max_tokens**: Adjust based on use case
- **Decoding**: Greedy if available

## Customization Guide

### To Change Expertise Areas
Edit `agent-config.json`:
```json
"expertise": [
  "Your Domain 1",
  "Your Domain 2"
]
```

### To Add New Examples
Create new files in `examples/` directory following existing format

### To Modify Communication Style
Edit `system-prompt.md` section "COMMUNICATION STYLE"

### To Extend Output Rules
Add new rules to both:
- `agent-config.json` → `output_rules.rules`
- `system-prompt.md` → "OUTPUT RULES" section

## Integration Checklist

Before deploying:
- [ ] Run `verify_config.py` - all checks pass
- [ ] Run test scenarios - score >= 18/20
- [ ] Test with real queries in your environment
- [ ] Verify Russian language output
- [ ] Confirm internal reasoning is hidden
- [ ] Check format compliance (code first)
- [ ] Validate step-by-step behavior
- [ ] Test uncertainty handling (ask questions)

## Maintenance

### Regular Checks
- Monitor user feedback for rule violations
- Track quality metrics (word efficiency, precision)
- Update examples based on common queries
- Refine system prompt based on edge cases

### Version Updates
When making changes:
1. Update version in `agent-config.json`
2. Document changes in README.md
3. Add new test scenarios if needed
4. Re-run verification script
5. Update CREATION_SUMMARY.md

## Troubleshooting

### Issue: Agent responds in English
**Fix**: Ensure system prompt loaded correctly, check temperature setting

### Issue: Multiple alternatives provided
**Fix**: Reinforce Rule 3 in system prompt, lower temperature

### Issue: Internal reasoning visible
**Fix**: Check "INTERNAL ONLY REASONING" rule enforcement

### Issue: Long explanations
**Fix**: Emphasize "FORMAT PRIORITY" rule, reduce max_tokens

### Issue: Guesses instead of asking
**Fix**: Strengthen "ASK NOT GUESS" rule, add more examples

## Support Resources

- **Full Documentation**: README.md
- **Quick Setup**: QUICKSTART.md
- **Testing**: TEST_SCENARIOS.md
- **Verification**: verify_config.py
- **Examples**: examples/ directory

---

**Version**: 1.0.0  
**Last Updated**: 2026-06-14  
**Status**: Production Ready
