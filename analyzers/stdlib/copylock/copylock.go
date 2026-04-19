// Package copylock re-exports the copylock analyzer for use with rules_go's nogo().
package copylock

import "golang.org/x/tools/go/analysis/passes/copylock"

// Analyzer is the copylock analysis.Analyzer.
var Analyzer = copylock.Analyzer
