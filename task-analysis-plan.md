# Task Analysis & Plan - Fix Kyverno GeneratingPolicy for Linkerd Rules

The goal is to fix the `GeneratingPolicy` named `gen-linkerd-rules` which is failing to apply due to CEL compilation errors. The policy is intended to generate Linkerd `Server`, `HTTPRoute`, and `AuthorizationPolicy` resources when a new namespace with `linkerd.io/injection: enabled` is created.

## Analysis of Errors
The `kubectl get kustomization` output showed several CEL compilation errors:
1. `expected type 'string' but found 'map(string, string)'` at `metadata`.
2. `expected type 'string' but found 'map(string, dyn)'` at `spec`.
3. `expected type 'map(string, map(dyn, dyn))' but found 'string'` at `port: "http"`.
4. `expected type 'map(string, string)' but found 'list(dyn)'` at `requiredAuthenticationRefs: []`.

These errors suggest that the CEL compiler in Kyverno v1.17.0 is misinterpreting the object literals or the expected schema of the target resources. Specifically, it seems to be confusing types (e.g., expecting a string where a map is provided, or vice versa).

## Proposed Changes
1.  **Refactor GeneratingPolicy to Cluster Scope**: Since `GeneratingPolicy` is a cluster-scoped CRD, I will remove the `namespace: kyverno` from its metadata to avoid any potential confusion, although the metadata namespace usually doesn't affect cluster-scoped resources, it's cleaner.
2.  **Use Variables for Resource Templates**: Instead of passing a large list of object literals directly to `generator.Apply`, I will define each resource as a variable. This can sometimes help the CEL compiler with type inference.
3.  **Fix Type Mismatches**:
    *   For the `port: "http"` issue in the `Server` resource, I will ensure it matches the `int-or-string` expectation.
    *   For the `requiredAuthenticationRefs: []` issue in `AuthorizationPolicy`, I will try to provide it in a way that satisfies the compiler, potentially by ensuring it's treated as a list of maps.
4.  **Simplify CEL Expressions**: Break down the `generator.Apply` call to be more readable and easier for the compiler to digest.

## Implementation Plan
1.  **Modify `flux/networking/kyverno-policies/gen-linkerd-rules.yaml`**:
    *   Remove `namespace: kyverno`.
    *   Move the resource definitions into the `variables` section.
    *   Update the `generate[0].expression` to use these variables.
2.  **Verify**:
    *   Wait for Flux to reconcile or manually trigger a reconciliation.
    *   Check `kubectl get kustomizations.kustomize.toolkit.fluxcd.io -n flux-system networking-services` for status.
    *   If successful, verify that creating a test namespace triggers the generation.

## Task-Analysis-Plan
1. Read the current policy file.
2. Prepare the refactored YAML with variables.
3. Apply the changes using `replace`.
4. Monitor Flux reconciliation.
