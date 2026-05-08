// Package httpresponse re-exports the httpresponse analyzer for use with rules_go's nogo().
package httpresponse

import "golang.org/x/tools/go/analysis/passes/httpresponse"

// Analyzer is the httpresponse analysis.Analyzer.
var Analyzer = httpresponse.Analyzer
