// Package unsafeptr re-exports the unsafeptr analyzer for use with rules_go's nogo().
package unsafeptr

import "golang.org/x/tools/go/analysis/passes/unsafeptr"

// Analyzer is the unsafeptr analysis.Analyzer.
var Analyzer = unsafeptr.Analyzer
