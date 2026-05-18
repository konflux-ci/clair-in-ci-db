# Clair-in-CI-DB AI Skills

Repository-specific AI skills for the clair-in-ci-db vulnerability scanner image. These skills are tool-agnostic and can be used with any AI agent (Claude Code, Codex, Goose, etc.) via symlinks to the agent's skill directory.

## Available Skills

| Skill | Description |
|-------|-------------|
| [ci-pipeline-debugging](ci-pipeline-debugging/SKILL.md) | Tekton build pipeline structure, task ordering, resource requirements, security scans, and common failures |
| [hermetic-build-deps](hermetic-build-deps/SKILL.md) | How RPM and artifact dependency files work together with Cachi2 for hermetic builds |
| [pr-definition-of-done](pr-definition-of-done/SKILL.md) | Pre-push checklist: commits, Dockerfile linting, formatting rules, CI checks |
| [daily-db-update](daily-db-update/SKILL.md) | Automated daily vulnerability database update flow and troubleshooting |

## Setup for Claude Code

Skills are symlinked from `.claude/skills/` for automatic discovery:

```
.claude/skills/ci-pipeline-debugging -> ../../skills/ci-pipeline-debugging
.claude/skills/hermetic-build-deps -> ../../skills/hermetic-build-deps
.claude/skills/pr-definition-of-done -> ../../skills/pr-definition-of-done
.claude/skills/daily-db-update -> ../../skills/daily-db-update
```

## Setup for Other Agents

Create symlinks from your agent's skill directory to `skills/`:

```bash
# Example for Codex
ln -s ../../skills/ci-pipeline-debugging .agents/skills/ci-pipeline-debugging
```