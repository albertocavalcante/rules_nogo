# Patching rules_go

nogo has limitations that only upstream [rules_go](https://github.com/bazelbuild/rules_go)
changes can fix. This ruleset ships optional patches. You choose which
to apply — none are required.

> Bazel enforces that only the **root module** can patch dependencies.
> You must copy the patches into your own repo and apply them yourself.

## Available patches

### Warning mode

Per-analyzer severity levels. Analyzers with `"severity": "warning"`
report findings to stderr without failing the build.

```json
{ "nilaway": { "severity": "warning" } }
```

Enables gradual rollout of new analyzers. Without this patch, every
finding is a build failure — there's no middle ground.

**Risk: low.** Touches `nogo_validation.go` (54 lines, 1 change in 8 months).

Relates to [bazelbuild/rules_go#4273](https://github.com/bazelbuild/rules_go/issues/4273).

### Repeated flags

`analyzer_flags` values can be JSON arrays, not just strings. Required
for analyzers like `importas` that take multiple `--alias` flags.

```json
{ "importas": { "analyzer_flags": { "alias": ["k8s.io/api/core/v1:corev1", "k8s.io/api/apps/v1:appsv1"] } } }
```

**Risk: low.** Touches `generate_nogo_main.go` (3 changes in 6 years).
Must be applied after `warning_mode.patch`.

Relates to [bazelbuild/rules_go#4354](https://github.com/bazelbuild/rules_go/issues/4354).

## How to apply

**1.** Copy the patches into your repo:

```bash
mkdir -p .bazel/patches
cp path/to/rules_nogo/patches/rules_go/0.60.0/warning_mode.patch .bazel/patches/
cp path/to/rules_nogo/patches/rules_go/0.60.0/repeated_flags.patch .bazel/patches/  # optional
```

**2.** Override rules_go in your `MODULE.bazel`:

```starlark
archive_override(
    module_name = "rules_go",
    urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.60.0/rules_go-v0.60.0.zip"],
    strip_prefix = "rules_go-0.60.0",
    integrity = "sha256-...",  # from the release page
    patch_strip = 1,
    patches = [
        "//.bazel/patches:warning_mode.patch",
        # "//.bazel/patches:repeated_flags.patch",  # must come after warning_mode
    ],
)
```

**3.** Expose the patches in `.bazel/patches/BUILD.bazel`:

```starlark
exports_files(glob(["*.patch"]))
```

## Compatibility

| Patch | rules_go 0.60.x |
|-------|:---------------:|
| `warning_mode` | Tested |
| `repeated_flags` | Tested (requires warning_mode first) |

New rules_go releases may require rebasing. Check `patches/rules_go/`
for version-specific directories.

## Upstream

When these features merge into rules_go, the patches become unnecessary.
Remove the `archive_override` and go back to a plain `bazel_dep`.
