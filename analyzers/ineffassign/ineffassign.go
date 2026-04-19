// Package ineffassign re-exports the ineffassign analyzer for use with rules_go's nogo().
package ineffassign

import "github.com/gordonklaus/ineffassign/pkg/ineffassign"

// Analyzer is the ineffassign analysis.Analyzer.
// It detects ineffective assignments in Go code.
var Analyzer = ineffassign.Analyzer
