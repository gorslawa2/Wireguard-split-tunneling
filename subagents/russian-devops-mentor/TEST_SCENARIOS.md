# Test scenarios for Russian DevOps Mentor
# Use these to verify agent behavior after setup

## Test 1: Basic Command Request
**Input:** Как посмотреть логи Kubernetes пода?
**Expected:** kubectl logs <pod-name> -n <namespace>
**Check:** Code first, minimal explanation

## Test 2: Uncertainty Handling
**Input:** Как настроить мониторинг?
**Expected:** Вопрос о платформе/инструментах
**Check:** Asks clarifying question, doesn't guess

## Test 3: Error Debugging
**Input:** Docker build failed
**Expected:** Пришлите точный текст ошибки
**Check:** Requests exact error text

## Test 4: Multi-step Task
**Input:** Как деплоить приложение на AWS?
**Expected:** Первый шаг только (например, настройка credentials)
**Check:** Only ONE step, waits for confirmation

## Test 5: Code Review
**Input:** 
```python
def add(a,b):
    return a+b
```
**Expected:** Improved code with type hints
**Check:** Code first, brief explanation

## Test 6: No Alternatives
**Input:** Какой язык для backend лучше?
**Expected:** Уточняющий вопрос о требованиях
**Check:** Doesn't list multiple languages

## Test 7: Internal Reasoning Hidden
**Input:** Почему мой сайт медленный?
**Expected:** Вопрос о метриках/инструментах
**Check:** NO "давайте подумаем" или internal phrases

## Test 8: Format Priority
**Input:** Команда для очистки Docker
**Expected:** docker system prune -a
**Check:** Command appears BEFORE any explanation

## Test 9: Language Consistency
**Input:** How to check disk space?
**Expected:** Response in Russian despite English input
**Check:** Maintains Russian language

## Test 10: Precision
**Input:** helm install prometheus
**Expected:** Full command with repo add if needed
**Check:** Complete, working command

---

## Scoring Rubric

For each test, score 0-2:
- 2: Perfect compliance
- 1: Minor issue
- 0: Major violation

**Passing Score:** 18/20 (90%)

## Common Failures

❌ Provides multiple steps at once
❌ Shows internal reasoning
❌ Offers alternatives unprompted
❌ Responds in English
❌ Long explanations without request
❌ Guesses instead of asking

## Improvement Actions

If score < 18:
1. Review failing tests
2. Adjust system prompt emphasis
3. Lower temperature further
4. Add more examples to training
5. Re-test after changes
