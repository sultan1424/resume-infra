#!/bin/bash
# ─────────────────────────────────────────
# Resume AI — Auto Test Script
# Run this after terraform apply finishes
# ─────────────────────────────────────────

echo ""
echo "========================================="
echo "   Resume AI — System Test"
echo "========================================="

# Step 1 — Get ALB URL from Terraform
echo ""
echo ">>> Getting ALB URL..."
ALB_URL=$(aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query "LoadBalancers[0].DNSName" \
  --output text)

echo "    ALB URL: http://$ALB_URL"

# Step 2 — Wait for service to be healthy
echo ""
echo ">>> Waiting for service to be ready..."
for i in {1..20}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_URL/health)
  if [ "$STATUS" == "200" ]; then
    echo "    Service is healthy! ✅"
    break
  fi
  echo "    Attempt $i/20 — waiting 10 seconds..."
  sleep 10
done

# Step 3 — Test health endpoint
echo ""
echo ">>> Testing health endpoint..."
curl -s http://$ALB_URL/health | python3 -m json.tool

# Step 4 — Upload CV
echo ""
echo ">>> Uploading CV..."
UPLOAD_RESPONSE=$(curl -s -X POST http://$ALB_URL/upload \
  -F "file=@/Users/sultanalatawi/Desktop/Jobs/Sultan_Alatawi_CV.pdf")

echo "    Response: $UPLOAD_RESPONSE"

CV_ID=$(echo $UPLOAD_RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['cv_id'])")
echo "    CV ID: $CV_ID"

# Step 5 — Wait for results
echo ""
echo ">>> Waiting for AI analysis to complete..."
for i in {1..15}; do
  sleep 5
  RESULT=$(curl -s http://$ALB_URL/results/$CV_ID)
  STATUS=$(echo $RESULT | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null)
  echo "    Attempt $i — Status: $STATUS"
  if [ "$STATUS" == "completed" ]; then
    echo ""
    echo ">>> Analysis Complete! ✅"
    echo ""
    echo "$RESULT" | python3 -m json.tool
    break
  fi
done

echo ""
echo "========================================="
echo "   Website URL:"
echo "   http://$(aws s3api get-bucket-website \
  --bucket resume-analyzer-frontend-prod \
  --region us-east-1 \
  --query 'RoutingRules' 2>/dev/null || \
  echo "resume-analyzer-frontend-prod.s3-website-us-east-1.amazonaws.com")"
echo "========================================="
echo ""
