// Package unreachable re-exports the unreachable analyzer for use with rules_go's nogo().
package unreachable

import "golang.org/x/tools/go/analysis/passes/unreachable"

// Analyzer is the unreachable analysis.Analyzer.
var Analyzer = unreachable.Analyzer
