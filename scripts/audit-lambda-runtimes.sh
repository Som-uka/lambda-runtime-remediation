#!/bin/bash
# audit-lambda-runtimes.sh
# Lists all Lambda functions grouped by runtime, flagging deprecated and EOL versions
# Usage: bash audit-lambda-runtimes.sh [--region us-east-1]

REGION=${1:-us-east-1}

# Runtime status reference (as of 2025)
CURRENT_RUNTIMES=("nodejs20.x" "nodejs22.x" "python3.12" "python3.13" "java21")
DEPRECATED_RUNTIMES=("nodejs16.x" "python3.8" "python3.9" "java11" "dotnet6")
EOL_RUNTIMES=("nodejs14.x" "nodejs12.x" "nodejs10.x" "nodejs8.10" "nodejs6.10" "python2.7" "python3.6" "python3.7")

echo "======================================"
echo " Lambda Runtime Audit"
echo " Region: $REGION"
echo " Date: $(date)"
echo "======================================"

echo ""
echo "--- All Lambda functions and their runtimes ---"
aws lambda list-functions \
  --region "$REGION" \
  --query 'Functions[*].{Name:FunctionName,Runtime:Runtime,Modified:LastModified}' \
  --output table

echo ""
echo "--- Functions on DEPRECATED runtimes ---"
for RT in "${DEPRECATED_RUNTIMES[@]}"; do
  COUNT=$(aws lambda list-functions \
    --region "$REGION" \
    --query "length(Functions[?Runtime=='$RT'])" \
    --output text)
  if [ "$COUNT" -gt "0" ]; then
    echo ""
    echo "  [$RT] — $COUNT function(s):"
    aws lambda list-functions \
      --region "$REGION" \
      --query "Functions[?Runtime=='$RT'].FunctionName" \
      --output text
  fi
done

echo ""
echo "--- Functions on EOL runtimes ---"
for RT in "${EOL_RUNTIMES[@]}"; do
  COUNT=$(aws lambda list-functions \
    --region "$REGION" \
    --query "length(Functions[?Runtime=='$RT'])" \
    --output text)
  if [ "$COUNT" -gt "0" ]; then
    echo ""
    echo "  [$RT] EOL — $COUNT function(s):"
    aws lambda list-functions \
      --region "$REGION" \
      --query "Functions[?Runtime=='$RT'].FunctionName" \
      --output text
  fi
done

echo ""
echo "--- Runtime summary ---"
aws lambda list-functions \
  --region "$REGION" \
  --query 'Functions[*].Runtime' \
  --output text | tr '\t' '\n' | sort | uniq -c | sort -rn

echo ""
echo "Audit complete."
