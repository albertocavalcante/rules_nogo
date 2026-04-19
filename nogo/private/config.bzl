"nogo_config() macro — generate nogo JSON config from Starlark."

# Default patterns for excluding generated code from nogo analysis.
# Used when exclude_generated = True in nogo_config().
DEFAULT_GENERATED_EXCLUDES = {
    "\\.pb\\.go$": "protobuf generated",
    "\\.pb\\.gw\\.go$": "grpc-gateway generated",
    "\\.connect\\.go$": "connect-rpc generated",
    "\\.sql\\.go$": "sqlc generated",
    "_gen\\.go$": "code-generated files",
    "^gen/": "generated output directory",
    "/mock_[^/]*\\.go$": "mock files",
    "/mocks/": "mock directory",
    "^vendor/": "vendored dependencies",
    "^external/": "bazel external dependencies",
}

def nogo_config(
        name,
        exclude_generated = False,
        exclude_patterns = {},
        analyzer_config = {},
        visibility = None):
    """Generate a nogo JSON config file from structured Starlark.

    The output is a JSON file compatible with rules_go's nogo() config format.
    Pass it as `config = ":name"` to nogo().

    Args:
        name: Target name. The output file will be `name.json`.
        exclude_generated: If True, automatically exclude common generated
            code patterns (*.pb.go, *.sql.go, gen/, mock_*, vendor/, etc.).
        exclude_patterns: Additional regex→description dict of file patterns
            to exclude globally (merged with exclude_generated patterns).
            Keys are Go regexp patterns, values are human-readable reasons.
        analyzer_config: Per-analyzer configuration dict. Keys are analyzer
            names; values are dicts with optional keys:
            - "exclude_files": {pattern: reason} to exclude specific files
              from this analyzer only
            - "only_files": {pattern: reason} to restrict this analyzer to
              specific files
            - "analyzer_flags": {flag: value} for analyzer-specific flags
        visibility: Standard Bazel visibility attribute.

    Example:
        nogo_config(
            name = "my_config",
            exclude_generated = True,
            exclude_patterns = {"^vendor/": "vendored code"},
            analyzer_config = {
                "exhaustive": {
                    "analyzer_flags": {
                        "default-signifies-exhaustive": "true",
                    },
                },
            },
        )
    """
    config = {}

    # Build the _base section from defaults + user excludes
    base_excludes = {}
    if exclude_generated:
        base_excludes.update(DEFAULT_GENERATED_EXCLUDES)
    base_excludes.update(exclude_patterns)
    if base_excludes:
        config["_base"] = {"exclude_files": base_excludes}

    # Per-analyzer config
    config.update(analyzer_config)

    # Escape $ as $$ for genrule shell (Bazel interprets bare $ as Make variables).
    json_content = json.encode_indent(config, indent = "  ").replace("$", "$$")

    native.genrule(
        name = name,
        outs = [name + ".json"],
        cmd = "cat > $@ << 'ENDOFNOGOCONFIG'\n{}\nENDOFNOGOCONFIG".format(json_content),
        visibility = visibility,
    )
