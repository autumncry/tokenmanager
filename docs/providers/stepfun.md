# StepFun

Credential: Step Plan API key.

StepFun Step Plan uses provider-compatible base URLs:

```text
OpenAI-compatible:    https://api.stepfun.com/step_plan/v1
Anthropic-compatible: https://api.stepfun.com/step_plan
Model:                step-3.7-flash
```

Use the model above for a minimal validation call. A public remaining-quota endpoint is not documented yet, so TokenManager keeps StepFun catalog-ready and does not display a fake balance.
