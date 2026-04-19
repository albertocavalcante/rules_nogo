// Package unusedresult re-exports the unusedresult analyzer for use with rules_go's nogo().
package unusedresult

import "golang.org/x/tools/go/analysis/passes/unusedresult"

// Analyzer is the unusedresult analysis.Analyzer.
var Analyzer = unusedresult.Analyzer
