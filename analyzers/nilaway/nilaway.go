// Package nilaway re-exports the nilaway analyzer for use with rules_go's nogo().
package nilaway

import "go.uber.org/nilaway"

// Analyzer is the nilaway analysis.Analyzer.
// It detects potential nil panics via static analysis.
var Analyzer = nilaway.Analyzer
