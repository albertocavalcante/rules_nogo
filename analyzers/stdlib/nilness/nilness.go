// Package nilness re-exports the nilness analyzer for use with rules_go's nogo().
package nilness

import "golang.org/x/tools/go/analysis/passes/nilness"

// Analyzer is the nilness analysis.Analyzer.
var Analyzer = nilness.Analyzer
