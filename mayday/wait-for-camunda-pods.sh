#!/bin/bash

# Namespace to check
NAMESPACE=${1:-camunda}

# Time to wait between checks (in seconds)
SLEEP_INTERVAL=5

# Max attempts (fails after MAX_ATTEMPTS * SLEEP_INTERVAL seconds)
MAX_ATTEMPTS=60

echo "⏳ Waiting for all Camunda 8 pods to be Running in namespace: $NAMESPACE"

attempt=0
while true; do
  NOT_READY_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -vE 'Running|Completed' | wc -l)
  TOTAL_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)

  echo "🔍 $((TOTAL_PODS - NOT_READY_PODS))/$TOTAL_PODS pods are Running..."

  if [[ "$NOT_READY_PODS" -eq 0 && "$TOTAL_PODS" -gt 0 ]]; then
    echo "✅ All Camunda 8 pods are up and running!"
    exit 0
  fi

  attempt=$((attempt + 1))
  if [[ $attempt -ge $MAX_ATTEMPTS ]]; then
    echo "❌ Timeout: Some pods are still not ready after $((MAX_ATTEMPTS * SLEEP_INTERVAL)) seconds."
    kubectl get pods -n "$NAMESPACE"
    exit 1
  fi

  sleep "$SLEEP_INTERVAL"
done
