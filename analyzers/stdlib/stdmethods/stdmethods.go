// Package stdmethods re-exports the stdmethods analyzer for use with rules_go's nogo().
package stdmethods

import "golang.org/x/tools/go/analysis/passes/stdmethods"

// Analyzer is the stdmethods analysis.Analyzer.
var Analyzer = stdmethods.Analyzer
