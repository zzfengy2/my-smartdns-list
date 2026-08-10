# SmartDNS Workflow Hardening Design

## Goal

Keep the repository's daily automatic updates while preventing third-party code from running with repository write credentials and preventing invalid generated lists from reaching `main`.

## Build Design

- Checkout this repository with a pinned `actions/checkout` commit.
- Checkout `felixonmars/dnsmasq-china-list` as data only with credentials disabled.
- Convert the four known upstream files with commands owned by this repository instead of running the upstream `Makefile`.
- Generate `proxy-domains.smartdns.conf` from the repository-owned workflow definition.
- Copy or generate only the five documented output files.

## Validation And Publishing

- Require all five output files to exist and be non-empty.
- Enforce conservative minimum line counts for the large upstream-derived lists.
- Validate every non-comment, non-blank line against its expected SmartDNS directive.
- Reject duplicate domain rules in generated domain lists.
- Stage only the five generated files.
- Treat an empty staged diff as a successful no-op without masking other commit failures.
- Add workflow concurrency so scheduled and manual runs cannot race while pushing.

## Proxy Coverage

Retain the existing proxy rules and add the first-party auxiliary domains required for the documented services, especially ChatGPT/OpenAI and GitHub static content. The list remains intentionally curated rather than attempting to duplicate a complete firewall allowlist.

## Documentation

- Close the README code fence.
- Document a concrete download/update method.
- Explain that `cn` and `gw` server groups must already exist.
- State that the files are generated and should not be edited directly.

## Verification

- Parse the workflow as YAML.
- Run the conversion and validation logic against a fresh upstream checkout.
- Confirm exactly the five expected configuration files are staged.
- Confirm the generated files contain only supported directive shapes.
- Confirm a second unchanged run exits successfully without creating a commit.

## Non-Goals

- Managing the user's SmartDNS installation remotely.
- Maintaining a complete domain inventory for every third-party service.
- Publishing or pushing changes without an explicit request.
