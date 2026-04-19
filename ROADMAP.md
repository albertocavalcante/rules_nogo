# Roadmap — Beyond Analyzers

This document plans the features that make rules_nogo more than just
a bag of analyzer targets. These are the capabilities that turn nogo
from "the thing that fails my build" into a first-class static analysis
platform.

## 1. GitHub Annotations (`nogo_annotate`)

**Value: HIGH | Effort: LOW | No rules_go patch needed**

nogo findings already land in stderr with a parseable format:
```
file.go:42:3: message (analyzerName)
```

A shell script or Go binary post-processes `nogo.log` files and emits
GitHub Actions annotations:
```
::error file=file.go,line=42,col=3,title=analyzerName::message
```

These appear inline on PR diffs — developers see findings exactly where
they occur, without scrolling through build logs.

### Implementation

Ship a `nogo_annotate.sh` script that CI invokes after `bazel build`:

```bash
bazel build --output_groups=+nogo_fix //... 2>/dev/null || true
find bazel-bin -name nogo.log -exec cat {} \; | while IFS= read -r line; do
  # parse file:line:col: message (analyzer) → ::error annotation
done
```

Or a Go binary at `//tools/nogo2annotations` for robustness.

### User experience

```yaml
# .github/workflows/ci.yml
- run: bazel build //... --output_groups=+nogo_fix
  continue-on-error: true
- run: bazel run @rules_nogo//tools:annotate
```

Findings appear as red annotations on the PR Files tab.

---

## 2. SARIF Report (`nogo_sarif`)

**Value: HIGH | Effort: MEDIUM | No rules_go patch needed**

SARIF (Static Analysis Results Interchange Format) is consumed by:
- GitHub Code Scanning (Security tab, inline PR annotations)
- Azure DevOps
- VS Code SARIF Viewer extension

A Go binary reads all `nogo.log` files from `bazel-bin` and produces
a SARIF 2.1.0 JSON file. Upload via `github/codeql-action/upload-sarif`.

### Benefits over annotations

- Findings persist in GitHub's Security tab across commits
- Deduplicated (same finding on multiple builds = one entry)
- Filterable by analyzer, severity, file path
- Works with branch protection rules ("no new code scanning alerts")

### Implementation

`tools/nogo2sarif/main.go` (~120 lines):
```go
// Reads nogo.log files from bazel-bin, emits SARIF JSON.
// Input:  find bazel-bin -name nogo.log
// Output: nogo-results.sarif
```

---

## 3. Auto-Apply Fixes (`nogo_fix`)

**Value: HIGH | Effort: LOW | Already works (partially)**

nogo already generates fix patches via `--output_groups=nogo_fix`. The
patches land at `bazel-bin/<package>/<name>_nogo/nogo.patch`. Currently
users must find and apply them manually:

```bash
bazel build --output_groups=nogo_fix //...
find bazel-bin -name nogo.patch -exec patch -p1 -i {} \;
```

### What rules_nogo adds

A `nogo_fix` wrapper script that does this automatically:

```bash
bazel run @rules_nogo//tools:fix
# Equivalent to:
#   bazel build --output_groups=nogo_fix //...
#   find bazel-bin -name nogo.patch -exec patch -p1 -i {} \;
```

The script:
1. Runs `bazel build --output_groups=nogo_fix --keep_going //...`
2. Finds all `nogo.patch` files in `bazel-bin`
3. Deduplicates patches (same file patched by multiple packages)
4. Applies them with `patch -p1`
5. Reports what was changed

### Which analyzers produce fixes?

Not all analyzers support `SuggestedFixes`. The ones that do:
- `stringintconv` — replaces `string(x)` with `strconv.Itoa(x)`
- Staticcheck S1 series — simplification rewrites
- Some SA checks with obvious mechanical fixes
- `gofmt` / `goimports` (if registered)

---

## 4. Go Modernize Integration (`BUNDLE_MODERNIZE`)

**Value: HIGH | Effort: LOW | Already possible — public package**

The modernize analyzers live at `golang.org/x/tools/go/analysis/passes/modernize`
— this is a **public** package (NOT `internal`). It exports individual
named `*analysis.Analyzer` vars that can be used with nogo directly via
our standard wrapper pattern.

### Available modernize analyzers (all produce `SuggestedFixes`)

| Analyzer | What it rewrites |
|----------|-----------------|
| `any` | `interface{}` → `any` |
| `fmtappendf` | `append(b, fmt.Sprintf(...)...)` → `fmt.Appendf(b, ...)` |
| `mapsloop` | manual map iteration → `maps.Copy` / `maps.Clone` |
| `minmax` | manual `if a < b { a = b }` → `min(a, b)` / `max(a, b)` |
| `rangeint` | `for i := 0; i < n; i++` → `for i := range n` |
| `slicescontains` | manual loop searching slice → `slices.Contains` |
| `slicessort` | `sort.Slice(s, ...)` → `slices.SortFunc(s, ...)` |
| `stringsbuilder` | `bytes.Buffer` for string building → `strings.Builder` |
| `stringscut` | `strings.Index` + slice → `strings.Cut` |
| `stringscutprefix` | `strings.HasPrefix` + trim → `strings.CutPrefix` |
| `stringsseq` | `strings.Split` loop → `strings.SplitSeq` (Go 1.24+) |
| `testingcontext` | `context.Background()` in tests → `t.Context()` |
| `waitgroup` | manual `wg.Add/Done` → structured patterns |
| `reflecttypefor` | `reflect.TypeOf((*T)(nil)).Elem()` → `reflect.TypeFor[T]()` |
| `omitzero` | `json:",omitempty"` on time/struct → `json:",omitzero"` |

### Implementation: standard wrapper pattern

Each analyzer is a one-file wrapper in `analyzers/modernize/<name>/`:

```go
package any
import "golang.org/x/tools/go/analysis/passes/modernize"
var Analyzer = modernize.AnyAnalyzer
```

No fork, no copy, no drift risk. The `x/tools` dep is already in our
`go.mod` (used by stdlib analyzers).

### Go version gating (safe by design)

Each modernize analyzer internally checks the `go` directive in `go.mod`.
`rangeint` only fires for `go 1.22+`, `stringsseq` only for `go 1.24+`,
etc. Running all of them on any codebase is safe — they no-op when the
Go version is too old.

### Two modes of use

**Mode A — nogo build-time enforcement:**
```starlark
nogo(
    name = "my_nogo",
    deps = BUNDLE_CORRECTNESS + BUNDLE_MODERNIZE,
)
```
Findings fail the build. Use with the `warning_mode.patch` to make
modernize findings advisory instead of blocking.

**Mode B — `go fix` for one-shot codebase modernization:**
```bash
go fix ./...  # applies all modernize + buildtag + hostport + inline
```
This runs the same analyzers outside Bazel. Use for initial cleanup,
then switch to nogo enforcement to prevent regressions.

### Auto-apply via nogo

Since every modernize analyzer produces `SuggestedFixes`, the existing
`--output_groups=nogo_fix` mechanism generates patches automatically:
```bash
bazel build --output_groups=nogo_fix --norun_validations //...
find bazel-bin -name nogo.patch -exec patch -p1 -N {} \;
```

This is the most powerful combination: nogo catches regressions at build
time, and the auto-fix path applies the rewrites mechanically.

---

## 5. HTML Dashboard (`nogo_report`)

**Value: LOW-MEDIUM | Effort: HIGH | Aspirational**

An HTML report aggregating all nogo findings across the repo. Think
SonarQube-lite for Go in Bazel.

### Architecture

1. **Aspect**: `nogo_report_aspect` collects `nogo_fix` output groups
   across all Go targets in the dep graph
2. **Aggregator**: Go binary reads all `nogo.log` files, deduplicates,
   computes stats (findings per analyzer, per package, trends)
3. **Renderer**: Produces a self-contained HTML file with:
   - Summary table (analyzer × finding count)
   - Sortable/filterable finding list
   - Per-file inline code view with highlighted lines

### Why "aspirational"

The `nogo_fix` output group contains directories, not plain files.
Walking them in Starlark requires `ctx.actions.run` with a helper
script. Aggregating across `//...` requires building everything first.
The Bazel aspect approach is feasible but complex (~2-3 days).

A simpler alternative: a standalone Go tool that runs after the build:
```bash
bazel build --output_groups=nogo_fix //...
bazel run @rules_nogo//tools:report > nogo-report.html
```

---

## 6. Analyzer Health Dashboard

**Value: LOW | Effort: LOW | Informational**

A `bazel query` + script that reports:
- How many analyzers are registered
- Which bundles are active
- What percentage of packages have nogo exclusions
- Which analyzers produce the most findings (from historical data)

```bash
bazel run @rules_nogo//tools:health
# Output:
# Analyzers: 28 active (BUNDLE_CORRECTNESS + 14 staticcheck + unused)
# Exclusions: 2 packages excluded (gen/go, internal/infra/postgres/db)
# Config: exclude_generated=true, exhaustive.default-signifies-exhaustive=true
```

---

## Priority Matrix

| Feature | Value | Effort | Dependency |
|---------|-------|--------|-----------|
| Go Modernize Bundle | HIGH | LOW | Already possible (public x/tools pkg) |
| GitHub Annotations | HIGH | LOW | None |
| Auto-Apply Fixes | HIGH | LOW | None (uses existing nogo.patch) |
| SARIF Report | HIGH | MEDIUM | None |
| HTML Dashboard | MEDIUM | HIGH | Complex aspect |
| Analyzer Health | LOW | LOW | None |

### Recommended order

1. **Go Modernize Bundle** — ~15 wrapper files, same pattern as existing
   analyzers. Immediate value: `interface{}` → `any`, `sort.Slice` →
   `slices.SortFunc`, etc. Every fix is auto-applicable.
2. **Auto-Apply Fixes** — ~30 lines wrapping existing `nogo.patch`
3. **GitHub Annotations** — ~50 lines of shell for inline PR findings
4. **SARIF Report** — ~120 lines Go, enables GitHub Code Scanning
5. **HTML Dashboard** — aspirational, do when 1-4 are shipped
