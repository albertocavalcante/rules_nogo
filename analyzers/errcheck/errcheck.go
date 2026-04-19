// Package errcheck re-exports the errcheck analyzer for use with rules_go's nogo().
package errcheck

import "github.com/kisielk/errcheck/errcheck"

// Analyzer is the errcheck analysis.Analyzer.
// It checks that error return values are used.
var Analyzer = errcheck.Analyzer
