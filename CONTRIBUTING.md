# Contributing

## Scopes

When you need to use a scope in a commit message, use the directories under `pkg` as a reference
to specify the scope. Some suggestions:

* aws
* gcp
* azure
* ...

## When opening a new PR

* The following **requirements** are checked in a PR:
  * make build
  * make test-unit
  * make test-integration # These requires a real environment (`draios-demo`) and are slower than the others.
  * make test-e2e
  * make test-rules
  * make lint

<!--
* We also use `pre-commit` plugin to automate this step, and **validate/detect** the issues when commiting from your local.
* When opening a PR, **an image will be built** in the [project packages section](https://github.com/orgs/sysdiglabs/packages?repo_name=cloud-connector), with the tag `pr-xxx`
-->

## Testing

It's recommended to use an .envrc file to keep environment variables under control. Check `.envrc.template` for a reference.

## Release

- push a new tag and the Github Action will draft a release (with notes)
