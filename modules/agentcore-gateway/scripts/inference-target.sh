#!/usr/bin/env bash
# Manages AgentCore Gateway inference targets with the AWS CLI.
#
# aws_bedrockagentcore_gateway_target has no inference target support yet
# (hashicorp/terraform-provider-aws#48705); invoked from terraform_data
# provisioners in inference.tf until it does.
#
# Inputs (environment):
#   TARGET_REGION  AWS region of the gateway
#   GATEWAY_ID     Gateway identifier
#   TARGET_NAME    Gateway target name
#   REQUEST_JSON   create-gateway-target request payload (create only)
set -euo pipefail

action="${1:?usage: inference-target.sh <create|delete>}"
: "${TARGET_REGION:?TARGET_REGION is required}"
: "${GATEWAY_ID:?GATEWAY_ID is required}"
: "${TARGET_NAME:?TARGET_NAME is required}"

find_target_id() {
  aws bedrock-agentcore-control list-gateway-targets \
    --region "$TARGET_REGION" \
    --gateway-identifier "$GATEWAY_ID" \
    --query "items[?name=='${TARGET_NAME}'].targetId | [0]" \
    --output text
}

target_status() {
  aws bedrock-agentcore-control list-gateway-targets \
    --region "$TARGET_REGION" \
    --gateway-identifier "$GATEWAY_ID" \
    --query "items[?name=='${TARGET_NAME}'].status | [0]" \
    --output text
}

case "$action" in
create)
  : "${REQUEST_JSON:?REQUEST_JSON is required for create}"
  if ! aws bedrock-agentcore-control create-gateway-target \
    --region "$TARGET_REGION" \
    --cli-input-json "$REQUEST_JSON" \
    --output json >/dev/null; then
    echo "create-gateway-target failed for '$TARGET_NAME'." >&2
    echo "If the error mentions unknown parameters in targetConfiguration," >&2
    echo "upgrade the AWS CLI: inference targets need a recent AWS CLI v2." >&2
    exit 1
  fi
  for _ in $(seq 1 60); do
    status="$(target_status)"
    case "$status" in
    READY)
      echo "Inference target '$TARGET_NAME' is ready on gateway $GATEWAY_ID"
      exit 0
      ;;
    *FAILED* | *UNSUCCESSFUL*)
      echo "Inference target '$TARGET_NAME' entered status $status" >&2
      exit 1
      ;;
    esac
    sleep 5
  done
  echo "Timed out waiting for inference target '$TARGET_NAME' to become ready" >&2
  exit 1
  ;;
delete)
  if ! target_id="$(find_target_id)"; then
    echo "Gateway $GATEWAY_ID is not reachable; nothing to delete for '$TARGET_NAME'"
    exit 0
  fi
  if [[ -z "$target_id" || "$target_id" == "None" ]]; then
    echo "Inference target '$TARGET_NAME' not found on gateway $GATEWAY_ID; nothing to delete"
    exit 0
  fi
  aws bedrock-agentcore-control delete-gateway-target \
    --region "$TARGET_REGION" \
    --gateway-identifier "$GATEWAY_ID" \
    --target-id "$target_id" \
    --output json >/dev/null
  for _ in $(seq 1 60); do
    remaining="$(find_target_id || true)"
    if [[ -z "$remaining" || "$remaining" == "None" ]]; then
      echo "Deleted inference target '$TARGET_NAME' from gateway $GATEWAY_ID"
      exit 0
    fi
    sleep 5
  done
  echo "Timed out waiting for inference target '$TARGET_NAME' to delete" >&2
  exit 1
  ;;
*)
  echo "Unknown action '$action' (expected create or delete)" >&2
  exit 1
  ;;
esac
