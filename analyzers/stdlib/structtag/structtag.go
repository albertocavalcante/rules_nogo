// Package structtag re-exports the structtag analyzer for use with rules_go's nogo().
package structtag

import "golang.org/x/tools/go/analysis/passes/structtag"

// Analyzer is the structtag analysis.Analyzer.
var Analyzer = structtag.Analyzer
