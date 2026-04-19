# Contributing

## Adding an analyzer

```
analyzers/<name>/<name>.go      # var Analyzer = pkg.Analyzer
analyzers/<name>/BUILD.bazel    # go_library with importpath + deps
```

Add it to the right bundle in `nogo/private/bundles.bzl`. New Go dep:
`go get`, `go mod tidy`, `bazel mod tidy`.

For staticcheck codes: add to the list in `analyzers/staticcheck/BUILD.bazel`
and `nogo/private/bundles.bzl`. The x_defs comprehension handles the rest.

## Updating rules_go patches

Create `patches/rules_go/<version>/`, rebase each patch, verify with
`patch --dry-run`, update the compatibility table in `PATCHING.md`.

## Verifying

```bash
bazel build //analyzers/...
bazel test //tests/...
go build ./...
```
