// Package unmarshal re-exports the unmarshal analyzer for use with rules_go's nogo().
package unmarshal

import "golang.org/x/tools/go/analysis/passes/unmarshal"

// Analyzer is the unmarshal analysis.Analyzer.
var Analyzer = unmarshal.Analyzer
