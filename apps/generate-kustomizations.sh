#!/bin/sh -e
# Generates kubernetes kustomizations for given directories or all subdirectories
if test $# -gt 0
then for dir; do
	{ echo 'apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:'
	find $dir -maxdepth 1 -type f -name "*.yaml" -not -name "kustomization.yaml" -printf "  - %f\n"; } | tee $dir/kustomization.yaml
	done
else
	find -mindepth 1 -maxdepth 1 -type d | while read dir
		do echo "[4m$dir[0m"
			$0 "$dir"
		done
fi
