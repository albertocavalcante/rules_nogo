// Package bodyclose re-exports the bodyclose analyzer for use with rules_go's nogo().
package bodyclose

import "github.com/timakin/bodyclose/passes/bodyclose"

// Analyzer is the bodyclose analysis.Analyzer.
// It checks whether HTTP response bodies are closed.
var Analyzer = bodyclose.Analyzer
