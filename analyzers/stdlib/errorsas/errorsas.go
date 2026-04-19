// Package errorsas re-exports the errorsas analyzer for use with rules_go's nogo().
package errorsas

import "golang.org/x/tools/go/analysis/passes/errorsas"

// Analyzer is the errorsas analysis.Analyzer.
var Analyzer = errorsas.Analyzer
