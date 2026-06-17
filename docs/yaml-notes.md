# YAML Notes

## What YAML Is

YAML is a clean format used for config files.

It is used in tools like:

* Docker Compose
* GitHub Actions
* Kubernetes
* Ansible
* Cloud/DevOps tools

The main point is like that YAML lets configuration be written in a readable way without loads of brackets and extra symbols.

## Key/Value Pairs

YAML often uses key/value pairs.

Example:

```yaml
name: infra-monitor
version: 1
```

This means:

```text
name = infra-monitor
version = 1
```

Important rule:

```text
There must be a space after the colon.
```

Good:

```yaml
name: infra-monitor
```

Bad:

```yaml
name:infra-monitor
```

## Indentation

YAML uses indentation to show structure.

Example:

```yaml
project:
  name: infra-monitor
  version: 1
```

This means `name` and `version` belong inside `project`.

For THIS project, I will use two spaces per level.

Bad indentation can break the file or make YAML read it wrong.

## Lists

YAML lists use dashes.

Example:

```yaml
tools:
  - Docker
  - Terraform
  - AWS
  - Bash
```

This means `tools` contains a list of values.

## Nested Structure

YAML can mix key/value pairs and lists.

Example:

```yaml
project:
  name: infra-monitor
  version: 1
  tools:
    - Bash
    - Docker
    - Terraform
```

This keeps related config grouped together.

## YAML For infra-monitor

A simple practice YAML file could look like:

```yaml
name: infra-monitor
version: 1
type: containerised monitoring service
tools:
  - Bash
  - Docker
  - Terraform
  - AWS
```

This is not Docker Compose yet.

It is just practice so I understand the structure before using it properly.

## What I Learned

YAML is all about structure.

Main rules:

* Use key/value pairs
* Use spaces for indentation
* Keep indentation consistent
* Use dashes for lists
* Put a space after each colon

This matters because Docker Compose uses YAML, and one small indentation mistake can break the whole thing. painful, but fair.
