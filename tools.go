//go:build tools
// +build tools

package tools

import (
	_ "github.com/gordonklaus/ineffassign/pkg/ineffassign"
	_ "github.com/kisielk/errcheck/errcheck"
	_ "github.com/nishanths/exhaustive"
	_ "github.com/sonatard/noctx"
	_ "github.com/timakin/bodyclose/passes/bodyclose"
	_ "go.uber.org/nilaway"
	_ "golang.org/x/tools/go/analysis/passes/copylock"
	_ "golang.org/x/tools/go/analysis/passes/errorsas"
	_ "golang.org/x/tools/go/analysis/passes/httpresponse"
	_ "golang.org/x/tools/go/analysis/passes/lostcancel"
	_ "golang.org/x/tools/go/analysis/passes/nilness"
	_ "golang.org/x/tools/go/analysis/passes/printf"
	_ "golang.org/x/tools/go/analysis/passes/sigchanyzer"
	_ "golang.org/x/tools/go/analysis/passes/stdmethods"
	_ "golang.org/x/tools/go/analysis/passes/stringintconv"
	_ "golang.org/x/tools/go/analysis/passes/structtag"
	_ "golang.org/x/tools/go/analysis/passes/unmarshal"
	_ "golang.org/x/tools/go/analysis/passes/unreachable"
	_ "golang.org/x/tools/go/analysis/passes/unsafeptr"
	_ "golang.org/x/tools/go/analysis/passes/unusedresult"
	_ "honnef.co/go/tools/analysis/lint"
	_ "honnef.co/go/tools/quickfix"
	_ "honnef.co/go/tools/simple"
	_ "honnef.co/go/tools/staticcheck"
	_ "honnef.co/go/tools/stylecheck"
	_ "honnef.co/go/tools/unused"
)
