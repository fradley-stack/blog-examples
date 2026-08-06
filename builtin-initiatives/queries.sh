#!/usr/bin/env bash
# Explore the built-in catalogue and read the compliance results.
# Needs: az login, and (for the summarize call) an assignment that has had
# ~30 minutes to produce its first evaluation.

# Every built-in initiative in the Regulatory Compliance category
az policy set-definition list \
  --query "[?policyType=='BuiltIn' && metadata.category=='Regulatory Compliance'].displayName" \
  -o tsv | sort

# Assign one in audit mode without touching Terraform (CIS shown here)
az policy assignment create \
  --name cis-v3-audit \
  --display-name "CIS Azure Foundations v3.0.0 (audit)" \
  --policy-set-definition "$(az policy set-definition list \
      --query "[?displayName=='CIS Azure Foundations v3.0.0'].name | [0]" -o tsv)"

# Compliance roll-up for the subscription, per assignment
az policy state summarize \
  --query "policyAssignments[].{assignment:policyAssignmentId, nonCompliant:results.nonCompliantResources}" \
  -o table
