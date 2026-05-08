// Package noctx re-exports the noctx analyzer for use with rules_go's nogo().
package noctx

import "github.com/sonatard/noctx"

// Analyzer is the noctx analysis.Analyzer.
// It detects http.Request passed without context.Context.
var Analyzer = noctx.Analyzer
