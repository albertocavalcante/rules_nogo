// Package unused re-exports honnef.co/go/tools/unused analyzer for use with rules_go's nogo().
// The honnef unused package exposes a *lint.Analyzer, not *analysis.Analyzer directly,
// so this wrapper unwraps it to the standard analysis.Analyzer.
package unused

import (
	"golang.org/x/tools/go/analysis"
	honnefunused "honnef.co/go/tools/unused"
)

// Analyzer is the unused analysis.Analyzer.
// It detects unused code (variables, functions, types, etc.).
// Note: nogo runs per-package, so cross-package unused detection may have
// false negatives. Use this to catch within-package unused declarations.
var Analyzer *analysis.Analyzer = honnefunused.Analyzer.Analyzer
