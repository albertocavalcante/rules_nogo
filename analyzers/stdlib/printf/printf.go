// Package printf re-exports the printf analyzer for use with rules_go's nogo().
package printf

import "golang.org/x/tools/go/analysis/passes/printf"

// Analyzer is the printf analysis.Analyzer.
var Analyzer = printf.Analyzer
