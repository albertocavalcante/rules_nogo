// Package lostcancel re-exports the lostcancel analyzer for use with rules_go's nogo().
package lostcancel

import "golang.org/x/tools/go/analysis/passes/lostcancel"

// Analyzer is the lostcancel analysis.Analyzer.
var Analyzer = lostcancel.Analyzer
