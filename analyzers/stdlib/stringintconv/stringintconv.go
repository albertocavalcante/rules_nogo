// Package stringintconv re-exports the stringintconv analyzer for use with rules_go's nogo().
package stringintconv

import "golang.org/x/tools/go/analysis/passes/stringintconv"

// Analyzer is the stringintconv analysis.Analyzer.
var Analyzer = stringintconv.Analyzer
