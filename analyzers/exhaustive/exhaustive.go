// Package exhaustive re-exports the exhaustive analyzer for use with rules_go's nogo().
package exhaustive

import "github.com/nishanths/exhaustive"

// Analyzer is the exhaustive analysis.Analyzer.
// It checks exhaustiveness of enum switches.
var Analyzer = exhaustive.Analyzer
