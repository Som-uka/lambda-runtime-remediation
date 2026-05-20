# Lambda Runtime Remediation

Systematic upgrade of deprecated AWS Lambda runtimes across a production environment, migrating 100+ functions from end-of-life Node.js runtimes to nodejs20.x.

---

## Overview

This project documents the runtime remediation effort across a Lambda-heavy AWS environment. The environment contained functions across multiple deprecated Node.js runtime versions, with the majority on nodejs16.x and a long tail of older EOL versions.

Left unaddressed, deprecated runtimes result in Lambda functions that can no longer be updated, may be blocked from invocation in future AWS enforcement actions, and represent an unpatched security surface.

---

## Runtime Inventory (Before)

| Runtime | Status | Notes |
|---|---|---|
| `nodejs20.x` | ✅ Current | Target runtime |
| `nodejs16.x` | ⚠️ Deprecated | 111 functions |
| `nodejs14.x` | ❌ EOL | Present |
| `nodejs12.x` | ❌ EOL | Present |
| `nodejs8.10` | ❌ EOL (2019) | Present |
| `nodejs6.10` | ❌ EOL (2019) | Present |

---

## Upgrade Approach

### Step 1: Audit All Functions
```bash
# List all Lambda functions and their runtimes
aws lambda list-functions \
  --query 'Functions[*].{Name:FunctionName,Runtime:Runtime}' \
  --output table

# Filter for deprecated runtimes only
aws lambda list-functions \
  --query 'Functions[?Runtime==`nodejs16.x`].{Name:FunctionName,Runtime:Runtime}' \
  --output table
```

### Step 2: Assess Code Compatibility
- Check for deprecated Node.js APIs in function code
- Review package.json for outdated dependencies
- Test in a dev/staging Lambda alias first

### Step 3: Update Runtime
```bash
# Update a single function's runtime
aws lambda update-function-configuration \
  --function-name <function-name> \
  --runtime nodejs20.x

# Verify the update
aws lambda get-function-configuration \
  --function-name <function-name> \
  --query '{Name:FunctionName,Runtime:Runtime}'
```

### Step 4: Validate
```bash
# Invoke function with test payload
aws lambda invoke \
  --function-name <function-name> \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json && cat response.json
```

---

## Bulk Upgrade Script Pattern

```bash
#!/bin/bash
FUNCTIONS=$(aws lambda list-functions \
  --query 'Functions[?Runtime==`nodejs16.x`].FunctionName' \
  --output text)

for fn in $FUNCTIONS; do
  echo "Upgrading: $fn"
  aws lambda update-function-configuration \
    --function-name "$fn" --runtime nodejs20.x
  echo "Done: $fn"
done
```

---

## Repository Structure

```
lambda-runtime-remediation/
├── README.md
├── findings/
│   └── runtime-inventory.md
├── change-records/
│   ├── CR-nodejs16-batch-upgrade.md
│   └── CR-legacy-runtime-cleanup.md
└── scripts/
    ├── audit-lambda-runtimes.sh
    ├── bulk-upgrade-nodejs16.sh
    └── validate-lambda-invoke.sh
```

---

## Tech Stack

- AWS Lambda, AWS CLI
- Node.js (nodejs20.x target)
- Bash

> All function names and ARNs have been sanitized.
