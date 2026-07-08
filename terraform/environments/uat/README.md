# uat environment — not yet wired

This directory is reserved for the `uat` environment. It intentionally
contains no `.tf` files yet.

Per the phased build plan for this platform, only `dev` (see
[../dev](../dev)) is fully wired in the current phase. `qa`, `uat`, and
`prod` will be filled in during a later phase by copying the `dev`
module wiring (`main.tf`, `variables.tf`, `outputs.tf`, `backend.tf`,
`providers.tf`, `versions.tf`) and adjusting `terraform.tfvars` for
this environment's own CIDR range, instance sizing, and
`single_nat_gateway = false` (qa/uat/prod should use per-AZ NAT
Gateways for fault isolation, unlike dev).

Do not add resources here until that phase begins — an empty,
documented stub is preferable to a half-wired environment that looks
complete but silently drifts from `dev`.
