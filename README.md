<p align="center">
  <h1 align="center">rules_nogo</h1>
  <p align="center">
    Batteries-included Go static analysis for Bazel
    <br />
    <strong>170 analyzers &middot; zero boilerplate &middot; one line to enable</strong>
  </p>
</p>

---

> **The problem:** Every Go Bazel project re-invents the same nogo glue code &mdash;
> wrapper `.go` files, `tools.go` build-tag imports, hand-written JSON configs,
> staticcheck `lint.Analyzer` unwrapping. That's 200&ndash;500 lines of
> boilerplate per repo, duplicated across every project.
>
> **The fix:** `rules_nogo` ships pre-built analyzer targets, curated bundles,
> and a Starlark config macro. Five lines of BUILD replaces hundreds of glue code.

## Quick start

```starlark
# MODULE.bazel
bazel_dep(name = "rules_go", version = "0.60.0")
bazel_dep(name = "rules_nogo", version = "0.1.0")

go_sdk = use_extension("@rules_go//go:extensions.bzl", "go_sdk")
go_sdk.download(version = "1.26.2")
go_sdk.nogo(nogo = "//:my_nogo")
```

```starlark
# BUILD.bazel
load("@rules_nogo//nogo:defs.bzl", "nogo", "nogo_config", "BUNDLE_CORRECTNESS")

nogo_config(
    name = "config",
    exclude_generated = True,
)

nogo(
    name = "my_nogo",
    config = ":config",
    deps = BUNDLE_CORRECTNESS,
)
```

That's it. No `tools.go`. No wrapper Go files. No hand-written JSON.
Every `go_library`, `go_binary`, and `go_test` in your repo is now
analyzed at build time.

## Bundles

Pick a starting point and grow from there.

### `BUNDLE_SAFETY` &mdash; 5 analyzers

Prevent crashes, data races, and resource leaks. Start here.

| Analyzer | Catches |
|----------|---------|
| **errcheck** | Unchecked error returns &rarr; panics in production |
| **ineffassign** | Dead assignments hiding real bugs |
| **copylock** | Copying `sync.Mutex` &rarr; data races |
| **errorsas** | Wrong `errors.As` target &rarr; silent failures |
| **lostcancel** | Leaked context &rarr; goroutine/resource leaks |

### `BUNDLE_CORRECTNESS` &mdash; 13 analyzers

Everything in SAFETY plus deeper bug detection. Recommended for production.

| Analyzer | Catches |
|----------|---------|
| _all of SAFETY_ | |
| **exhaustive** | Non-exhaustive `switch` &rarr; missed cases |
| **noctx** | HTTP without context &rarr; can't cancel/trace |
| **nilaway** | Nil pointer flow analysis &rarr; prevent nil panics |
| **nilness** | Nil dereference paths |
| **httpresponse** | Using response before checking error |
| **stringintconv** | `string(int)` gotcha (rune vs digit) |
| **unreachable** | Dead code after return/panic |
| **unsafeptr** | `unsafe.Pointer` misuse &rarr; memory corruption |

### `BUNDLE_STYLE` &mdash; 6 analyzers

Code quality. Independent of CORRECTNESS &mdash; add alongside it.

| Analyzer | Catches |
|----------|---------|
| **bodyclose** | Unclosed HTTP response bodies |
| **structtag** | Malformed struct tags &rarr; silent json/db bugs |
| **unmarshal** | Wrong unmarshal targets |
| **unusedresult** | Discarded pure-function returns |
| **stdmethods** | Wrong signatures on `Error()` / `String()` |
| **sigchanyzer** | Unbuffered `os.Signal` channel &rarr; missed signals |

### `BUNDLE_STATICCHECK` &mdash; ~145 analyzers

The full [honnef.co/go/tools](https://staticcheck.dev/) suite.

| Category | Codes | Focus |
|----------|-------|-------|
| **SA** | `sa1000`&ndash;`sa9009` (~80) | Correctness &amp; performance |
| **S1** | `s1000`&ndash;`s1040` (~35) | Code simplification |
| **ST** | `st1000`&ndash;`st1023` (~18) | Style conventions |

### `BUNDLE_ALL` &mdash; ~170 analyzers

Everything above plus `unused`.

Compose bundles with `+` and cherry-pick individual analyzers:

```starlark
deps = BUNDLE_CORRECTNESS + BUNDLE_STYLE + [
    "@rules_nogo//analyzers/unused",
]
```

### Staticcheck cherry-picking

Select specific staticcheck codes or exclude noisy ones:

```starlark
load("@rules_nogo//nogo:defs.bzl", "staticcheck_analyzers", "SA_CODES")

# All SA codes except sa4023
deps = BUNDLE_CORRECTNESS + staticcheck_analyzers(SA_CODES + ["-sa4023"])
```

## Configuration

### `nogo_config()` &mdash; Starlark-native config

No more hand-written JSON. The `nogo_config` macro generates the config
file from structured Starlark:

```starlark
nogo_config(
    name = "config",
    exclude_generated = True,       # *.pb.go, *.sql.go, gen/, vendor/, mocks/, ...
    exclude_patterns = {
        "^third_party/": "vendored code",
    },
    analyzer_config = {
        "exhaustive": {
            "analyzer_flags": {
                "default-signifies-exhaustive": "true",
            },
        },
    },
)
```

<details>
<summary><code>exclude_generated = True</code> covers these patterns</summary>

| Pattern | Description |
|---------|-------------|
| `\.pb\.go$` | Protobuf generated |
| `\.pb\.gw\.go$` | gRPC-gateway generated |
| `\.connect\.go$` | Connect-RPC generated |
| `\.sql\.go$` | sqlc generated |
| `_gen\.go$` | Code-generated files |
| `^gen/` | Generated output directory |
| `/mock_[^/]*\.go$` | Mock files |
| `/mocks/` | Mock directory |
| `^vendor/` | Vendored dependencies |
| `^external/` | Bazel external dependencies |

</details>

### `//nolint` inline suppression

nogo supports inline suppression directives:

```go
x := unsafeOp()  //nolint:gosec         // legacy code, tracked in #1234
y := mayFail()   //nolint:errcheck      // error intentionally ignored
z := thing()     //nolint               // suppress all analyzers
```

## Custom analyzers

### Third-party analyzer (no Go code needed)

```starlark
load("@rules_nogo//nogo:defs.bzl", "nogo_analyzer")

nogo_analyzer(
    name = "depguard",
    analyzer = "github.com/OpenPeeDeeP/depguard/v2.Analyzer",
    importpath = "myproject/nogo/depguard",
    go_deps = ["@com_github_openpeeDeeP_depguard_v2//:depguard"],
)

nogo(
    name = "my_nogo",
    deps = BUNDLE_CORRECTNESS + [":depguard"],
)
```

### Project-specific analyzer

Write a standard `go/analysis` analyzer and add it directly:

```starlark
nogo(
    name = "my_nogo",
    deps = BUNDLE_CORRECTNESS + ["//tools/nogo/mycheck"],
)
```

## Auto-fix

Many analyzers produce `SuggestedFixes`. nogo collects them as patches:

```bash
# Collect fix patches without failing the build
bazel build --output_groups=nogo_fix --norun_validations --keep_going //...

# Apply them
find $(bazel info bazel-bin) -name nogo.patch \
  -exec patch -p1 -N --reject-file=/dev/null -i {} \;
```

## Dependency management

rules_nogo ships its own `go.mod` declaring all analyzer dependencies.
The gazelle `go_deps` extension resolves them automatically via MVS
alongside your project's own Go deps.

**You do NOT need to:**
- Add analyzer packages to your `go.mod`
- Write a `tools.go` with build-tag imports
- Add `use_repo(go_deps, ...)` for analyzer repos

## rules_go patches

nogo has [known limitations](PATCHING.md) in rules_go. This ruleset
ships optional patches you can apply:

<details>
<summary><strong>Warning mode</strong> &mdash; findings without failing the build</summary>

Adds a `"severity"` field to the nogo config. Analyzers with
`"severity": "warning"` emit findings to stderr but exit 0.

```json
{ "nilaway": { "severity": "warning" } }
```

See [PATCHING.md](PATCHING.md) for how to apply. Patches live in your
repo, not in rules_nogo (Bazel requires the root module to own patches).

</details>

<details>
<summary><strong>Repeated flags</strong> &mdash; multi-value analyzer flags</summary>

Allows `analyzer_flags` values to be JSON arrays for analyzers with
repeated flags (e.g., `importas --alias`).

```json
{
  "importas": {
    "analyzer_flags": {
      "alias": ["k8s.io/api/core/v1:corev1", "k8s.io/api/apps/v1:appsv1"]
    }
  }
}
```

</details>

## Requirements

| Bazel | Go | rules_go |
|-------|----|----------|
| 9.0+ | 1.26+ | 0.60.0+ |

## Individual analyzers

<details>
<summary>All 170 analyzer targets</summary>

**Direct analyzers**
```
@rules_nogo//analyzers/errcheck
@rules_nogo//analyzers/exhaustive
@rules_nogo//analyzers/ineffassign
@rules_nogo//analyzers/noctx
@rules_nogo//analyzers/nilaway
@rules_nogo//analyzers/bodyclose
@rules_nogo//analyzers/unused
```

**Stdlib passes**
```
@rules_nogo//analyzers/stdlib/copylock
@rules_nogo//analyzers/stdlib/errorsas
@rules_nogo//analyzers/stdlib/httpresponse
@rules_nogo//analyzers/stdlib/lostcancel
@rules_nogo//analyzers/stdlib/nilness
@rules_nogo//analyzers/stdlib/printf
@rules_nogo//analyzers/stdlib/sigchanyzer
@rules_nogo//analyzers/stdlib/stdmethods
@rules_nogo//analyzers/stdlib/stringintconv
@rules_nogo//analyzers/stdlib/structtag
@rules_nogo//analyzers/stdlib/unmarshal
@rules_nogo//analyzers/stdlib/unreachable
@rules_nogo//analyzers/stdlib/unsafeptr
@rules_nogo//analyzers/stdlib/unusedresult
```

**Staticcheck** (`@rules_nogo//analyzers/staticcheck:<code>`)
```
SA: sa1000–sa9009  (~80 codes)    Correctness & performance
S1: s1000–s1040   (~35 codes)    Code simplification
ST: st1000–st1023 (~18 codes)    Style conventions
```

</details>

## License

Apache-2.0
