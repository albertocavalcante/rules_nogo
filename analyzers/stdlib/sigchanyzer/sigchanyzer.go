// Package sigchanyzer re-exports the sigchanyzer analyzer for use with rules_go's nogo().
package sigchanyzer

import "golang.org/x/tools/go/analysis/passes/sigchanyzer"

// Analyzer is the sigchanyzer analysis.Analyzer.
var Analyzer = sigchanyzer.Analyzer
