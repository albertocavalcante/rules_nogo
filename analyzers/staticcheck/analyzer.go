// Package staticcheck provides per-code staticcheck analyzer targets via the x_defs pattern.
// The name variable is stamped at link time by Bazel's x_defs mechanism, selecting
// the specific check (e.g., "sa1000", "s1000", "st1000") from the full staticcheck suite.
package staticcheck

import (
	"golang.org/x/tools/go/analysis"

	"github.com/bazel-contrib/rules_nogo/analyzers/staticcheck/util"
)

// name is injected by Bazel at link time via x_defs.
// Each go_library target in BUILD.bazel stamps a different check code here.
var name string

// Analyzer is the analysis.Analyzer for the check code stamped into name.
// It is resolved at init time from the full staticcheck suite.
var Analyzer *analysis.Analyzer

func init() {
	if name != "" {
		Analyzer = util.FindAnalyzerByName(name)
	}
}
