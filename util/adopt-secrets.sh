#!/bin/bash
# Copied from Stackspin with slight adjustment to include all new secrets
set -o errexit
secrets=$(kubectl get -A 'stringsecrets.v1alpha1.secretgenerator.mittwald.de' | tail +2 | awk '{print $2}' | paste -s -d ' ')
for secret in $secrets
do
  echo "Processing secret $secret"
  if currentRefs=$(kubectl get secret -n flux-system $secret -o jsonpath={.metadata.ownerReferences})
  then
    if [ -n "$currentRefs" ]
    then
      echo "There are refs set already, skip."
      continue
    fi

    uid=$(kubectl get stringsecret -n flux-system $secret -o jsonpath={.metadata.uid})
    echo "Patching to add owner reference to StringSecret with uid $uid"
    kubectl patch secret -n flux-system $secret --patch="{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"secretgenerator.mittwald.de/v1alpha1\",\"blockOwnerDeletion\":true,\"controller\":true,\"kind\":\"StringSecret\",\"name\":\"$secret\",\"uid\":\"$uid\"}]}}"
  else
    echo "Secret does not exist; perhaps this is a new install or the app is not installed. Skipping."
  fi
done

secrets="stackspin-alertmanager-basic-auth stackspin-prometheus-basic-auth"
for secret in $secrets
do
  echo "Processing secret $secret"
  if currentRefs=$(kubectl get secret -n stackspin $secret -o jsonpath={.metadata.ownerReferences})
  then
    if [ -n "$currentRefs" ]
    then
      echo "There are refs set already, skip."
      continue
    fi

    uid=$(kubectl get basicauth -n stackspin $secret -o jsonpath={.metadata.uid})
    echo "Patching to add owner reference to BasicAuth with uid $uid"
    kubectl patch secret -n stackspin $secret --patch="{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"secretgenerator.mittwald.de/v1alpha1\",\"blockOwnerDeletion\":true,\"controller\":true,\"kind\":\"BasicAuth\",\"name\":\"$secret\",\"uid\":\"$uid\"}]}}"
  else
    echo "Secret does not exist; perhaps this is a new install or the app is not installed. Skipping."
  fi
done

echo "Done patching secrets."
echo "Restarting secrets controller."
if ! kubectl rollout restart deploy -n secrets-controller secrets-controller-kubernetes-secret-generator
then
  echo "Restarting failed. Possibly this is a new install and the secrets controller is not installed yet. Ignoring."
fi
echo "adopt-secrets completed"
