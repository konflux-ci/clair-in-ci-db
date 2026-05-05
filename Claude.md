# Project

This is an repository containing data for creation of clair image. Image is being used within konflux-ci pipelines where it checks for image CVEs. Image is being build on daily basis. Docker image is being build using hermetic approach - no access to the internet.

# Behavior

- Before modifying anything, outline the changes and create PR for them.
- Comment changes, but only for logic that is not obvious.
- If you are given ambiguous task, ask one clarifying question before starting.

# Hard rules

- Never push changes directly to main branch.
- Never make changes that includes sensitive information like API keys, secrets, passwords, etc.
- Always ask for reviews members of this repository when you make changes.

# Codebase Context

- Dockerfile - clair-in-ci-db image definition
- rpms.* files - contains packages that are being build hermetically with their corresponding location
- .tekton/ - pipeline definitions that triggers build for clair-in-ci-db image

# Workflows

TBD
