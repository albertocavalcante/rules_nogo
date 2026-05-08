// Package util provides helpers for the staticcheck x_defs integration.
package util

import (
	"strings"

	"golang.org/x/tools/go/analysis"
	"honnef.co/go/tools/analysis/lint"
	"honnef.co/go/tools/quickfix"
	"honnef.co/go/tools/simple"
	"honnef.co/go/tools/staticcheck"
	"honnef.co/go/tools/stylecheck"
)

// allAnalyzers returns all lint.Analyzer values from the staticcheck suite.
// This includes SA (staticcheck), S1 (simple), ST (stylecheck), and QF (quickfix) checks.
func allAnalyzers() []*lint.Analyzer {
	var all []*lint.Analyzer
	all = append(all, staticcheck.Analyzers...)
	all = append(all, simple.Analyzers...)
	all = append(all, stylecheck.Analyzers...)
	all = append(all, quickfix.Analyzers...)
	return all
}

// FindAnalyzerByName looks up a staticcheck analyzer by its check code.
// The lookup is case-insensitive: "sa1000" and "SA1000" both work.
// Bazel x_defs stamps lowercase codes (e.g., "sa1000"); staticcheck uses
// uppercase names (e.g., "SA1000") in analysis.Analyzer.Name.
// It panics if the code is not found — this is intentional because the code
// list in BUILD.bazel must be kept in sync with the actual staticcheck release.
func FindAnalyzerByName(name string) *analysis.Analyzer {
	upper := strings.ToUpper(name)
	for _, a := range allAnalyzers() {
		if strings.ToUpper(a.Analyzer.Name) == upper {
			return a.Analyzer
		}
	}
	panic("rules_nogo: unknown staticcheck analyzer: " + name)
}
