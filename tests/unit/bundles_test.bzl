"""Unit tests for analyzer bundles — catch duplicate/missing analyzers."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//nogo/private:bundles.bzl",
    "BUNDLE_ALL",
    "BUNDLE_CORRECTNESS",
    "BUNDLE_SAFETY",
    "BUNDLE_STATICCHECK",
    "BUNDLE_STYLE",
)

# The 5 analyzers that vet=True provides. These must NEVER appear in
# any bundle, or nogo() will fail with "duplicate analyzer".
_VET_ANALYZERS = ["atomic", "bools", "buildtag", "nilfunc", "printf"]

def _no_vet_duplicates_in_safety_test_impl(ctx):
    env = unittest.begin(ctx)
    for dep in BUNDLE_SAFETY:
        for vet in _VET_ANALYZERS:
            asserts.false(
                env,
                dep.endswith("/" + vet) or dep.endswith(":" + vet),
                "BUNDLE_SAFETY contains vet analyzer '{}': {}".format(vet, dep),
            )
    return unittest.end(env)

no_vet_duplicates_in_safety_test = unittest.make(_no_vet_duplicates_in_safety_test_impl)

def _no_vet_duplicates_in_correctness_test_impl(ctx):
    env = unittest.begin(ctx)
    for dep in BUNDLE_CORRECTNESS:
        for vet in _VET_ANALYZERS:
            asserts.false(
                env,
                dep.endswith("/" + vet) or dep.endswith(":" + vet),
                "BUNDLE_CORRECTNESS contains vet analyzer '{}': {}".format(vet, dep),
            )
    return unittest.end(env)

no_vet_duplicates_in_correctness_test = unittest.make(_no_vet_duplicates_in_correctness_test_impl)

def _no_vet_duplicates_in_style_test_impl(ctx):
    env = unittest.begin(ctx)
    for dep in BUNDLE_STYLE:
        for vet in _VET_ANALYZERS:
            asserts.false(
                env,
                dep.endswith("/" + vet) or dep.endswith(":" + vet),
                "BUNDLE_STYLE contains vet analyzer '{}': {}".format(vet, dep),
            )
    return unittest.end(env)

no_vet_duplicates_in_style_test = unittest.make(_no_vet_duplicates_in_style_test_impl)

def _no_vet_duplicates_in_all_test_impl(ctx):
    env = unittest.begin(ctx)
    for dep in BUNDLE_ALL:
        for vet in _VET_ANALYZERS:
            asserts.false(
                env,
                dep.endswith("/" + vet) or dep.endswith(":" + vet),
                "BUNDLE_ALL contains vet analyzer '{}': {}".format(vet, dep),
            )
    return unittest.end(env)

no_vet_duplicates_in_all_test = unittest.make(_no_vet_duplicates_in_all_test_impl)

def _no_internal_duplicates_in_all_test_impl(ctx):
    """BUNDLE_ALL should have no duplicate labels."""
    env = unittest.begin(ctx)
    seen = {}
    for dep in BUNDLE_ALL:
        asserts.false(
            env,
            dep in seen,
            "BUNDLE_ALL has duplicate: {}".format(dep),
        )
        seen[dep] = True
    return unittest.end(env)

no_internal_duplicates_in_all_test = unittest.make(_no_internal_duplicates_in_all_test_impl)

def _safety_is_subset_of_correctness_test_impl(ctx):
    """Every analyzer in SAFETY must also be in CORRECTNESS."""
    env = unittest.begin(ctx)
    correctness_set = {dep: True for dep in BUNDLE_CORRECTNESS}
    for dep in BUNDLE_SAFETY:
        asserts.true(
            env,
            dep in correctness_set,
            "BUNDLE_SAFETY has {} which is not in BUNDLE_CORRECTNESS".format(dep),
        )
    return unittest.end(env)

safety_is_subset_of_correctness_test = unittest.make(_safety_is_subset_of_correctness_test_impl)

def _bundles_are_nonempty_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, len(BUNDLE_SAFETY) > 0, "BUNDLE_SAFETY is empty")
    asserts.true(env, len(BUNDLE_CORRECTNESS) > 0, "BUNDLE_CORRECTNESS is empty")
    asserts.true(env, len(BUNDLE_STYLE) > 0, "BUNDLE_STYLE is empty")
    asserts.true(env, len(BUNDLE_STATICCHECK) > 0, "BUNDLE_STATICCHECK is empty")
    asserts.true(env, len(BUNDLE_ALL) > 0, "BUNDLE_ALL is empty")
    return unittest.end(env)

bundles_are_nonempty_test = unittest.make(_bundles_are_nonempty_test_impl)

def _all_labels_have_rules_nogo_prefix_test_impl(ctx):
    """All bundle labels must reference @rules_nogo//."""
    env = unittest.begin(ctx)
    for dep in BUNDLE_ALL:
        asserts.true(
            env,
            dep.startswith("@rules_nogo//"),
            "Label does not start with @rules_nogo//: {}".format(dep),
        )
    return unittest.end(env)

all_labels_have_rules_nogo_prefix_test = unittest.make(_all_labels_have_rules_nogo_prefix_test_impl)

def bundles_test_suite(name):
    unittest.suite(
        name,
        no_vet_duplicates_in_safety_test,
        no_vet_duplicates_in_correctness_test,
        no_vet_duplicates_in_style_test,
        no_vet_duplicates_in_all_test,
        no_internal_duplicates_in_all_test,
        safety_is_subset_of_correctness_test,
        bundles_are_nonempty_test,
        all_labels_have_rules_nogo_prefix_test,
    )
