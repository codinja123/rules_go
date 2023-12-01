# Copyright 2014 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Once nested repositories work, this file should cease to exist.

load("//go/private:common.bzl", "MINIMUM_BAZEL_VERSION")
load("//go/private:skylib/lib/versions.bzl", "versions")
load("//go/private:nogo.bzl", "DEFAULT_NOGO", "go_register_nogo")
load("//proto:gogo.bzl", "gogo_special_proto")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def go_rules_dependencies(is_rules_go = False):
    """Declares workspaces the Go rules depend on. Workspaces that use
    rules_go should call this.

    See https://github.com/bazelbuild/rules_go/blob/master/go/dependencies.rst#overriding-dependencies
    for information on each dependency.

    Instructions for updating this file are in
    https://github.com/bazelbuild/rules_go/wiki/Updating-dependencies.

    PRs updating dependencies are NOT ACCEPTED. See
    https://github.com/bazelbuild/rules_go/blob/master/go/dependencies.rst#overriding-dependencies
    for information on choosing different versions of these repositories
    in your own project.
    """
    if getattr(native, "bazel_version", None):
        versions.check(MINIMUM_BAZEL_VERSION, bazel_version = native.bazel_version)

    # Repository of standard constraint settings and values.
    # Bazel declares this automatically after 0.28.0, but it's better to
    # define an explicit version.
    _maybe(
        http_archive,
        name = "platforms",
        strip_prefix = "platforms-681f1ee032566aa2d443cf0335d012925d9c58d4",
        # master, as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/archive/681f1ee032566aa2d443cf0335d012925d9c58d4.zip",
            "https://github.com/bazelbuild/platforms/archive/681f1ee032566aa2d443cf0335d012925d9c58d4.zip",
        ],
        sha256 = "ae95e4bfcd9f66e9dc73a92cee0107fede74163f788e3deefe00f3aaae75c431",
    )

    # Needed by rules_go implementation and tests.
    # We can't call bazel_skylib_workspace from here. At the moment, it's only
    # used to register unittest toolchains, which rules_go does not need.
    _maybe(
        http_archive,
        name = "bazel_skylib",
        # 1.0.2, latest as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        ],
        sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
    )

    # Needed for nogo vet checks and go/packages.
    _maybe(
        http_archive,
        name = "org_golang_x_tools",
        # master, as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/golang/tools/archive/c024452afbcdebb4a0fbe1bb0eaea0d2dbff835b.zip",
            "https://github.com/golang/tools/archive/c024452afbcdebb4a0fbe1bb0eaea0d2dbff835b.zip",
        ],
        sha256 = "5b330e3bd29a52c235648457e1aa899d948cb1eb90a8b5caa0ac882be75572db",
        strip_prefix = "tools-c024452afbcdebb4a0fbe1bb0eaea0d2dbff835b",
        patches = [
            # deletegopls removes the gopls subdirectory. It contains a nested
            # module with additional dependencies. It's not needed by rules_go.
            "@io_bazel_rules_go//third_party:org_golang_x_tools-deletegopls.patch",
            # gazelle args: -repo_root . -go_prefix golang.org/x/tools -go_naming_convention import_alias
            "@io_bazel_rules_go//third_party:org_golang_x_tools-gazelle.patch",
        ],
        patch_args = ["-p1"],
    )

    _maybe(
        git_repository,
        name = "org_golang_google_grpc",
        remote = "https://github.com/grpc/grpc-go",
        patches = [
            "@io_bazel_rules_go//third_party:org_golang_google_grpc-crosscompile.patch",
        ],
        patch_args = ["-p1"],
        shallow_since = "1551206709 -0800",
        # gazelle args: -go_prefix google.golang.org/grpc -proto disable
    )

    # Needed by golang.org/x/tools/go/packages
    _maybe(
        http_archive,
        name = "org_golang_x_xerrors",
        # master, as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/golang/xerrors/archive/5ec99f83aff198f5fbd629d6c8d8eb38a04218ca.zip",
            "https://github.com/golang/xerrors/archive/5ec99f83aff198f5fbd629d6c8d8eb38a04218ca.zip",
        ],
        sha256 = "cd9de801daf63283be91a76d7f91e8a9541798c5c0e8bcfb7ee804b78a493b02",
        strip_prefix = "xerrors-5ec99f83aff198f5fbd629d6c8d8eb38a04218ca",
        patches = [
            # gazelle args: -repo_root -go_prefix golang.org/x/xerrors -go_naming_convention import_alias
            "@io_bazel_rules_go//third_party:org_golang_x_xerrors-gazelle.patch",
        ],
        patch_args = ["-p1"],
    )

    # Needed for additional targets declared around binaries with c-archive
    # and c-shared link modes.
    _maybe(
        http_archive,
        name = "rules_cc",
        # master, as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_cc/archive/02becfef8bc97bda4f9bb64e153f1b0671aec4ba.zip",
            "https://github.com/bazelbuild/rules_cc/archive/02becfef8bc97bda4f9bb64e153f1b0671aec4ba.zip",
        ],
        sha256 = "fa42eade3cad9190c2a6286a6213f07f1a83d26d9f082d56f526d014c6ea7444",
        strip_prefix = "rules_cc-02becfef8bc97bda4f9bb64e153f1b0671aec4ba",
    )

    # Proto dependencies
    # These are limited as much as possible. In most cases, users need to
    # declare these on their own (probably via go_repository rules generated
    # with 'gazelle update-repos -from_file=go.mod). There are several
    # reasons for this:
    #
    # * com_google_protobuf has its own dependency macro. We can't load
    #   the macro here.
    # * rules_proto also has a dependency macro. It's only needed by tests and
    #   by gogo_special_proto. Users will need to declare it anyway.
    # * org_golang_google_grpc has too many dependencies for us to maintain.
    # * In general, declaring dependencies here confuses users when they
    #   declare their own dependencies later. Bazel ignores these.
    # * Most proto repos are updated more frequently than rules_go, and
    #   we can't keep up.

    # Go protobuf runtime library and utilities.
    _maybe(
        http_archive,
        name = "org_golang_google_protobuf",
        sha256 = "62992b0f5864aee2077a6cffa57a2d2bd30e7af4b6745eebd816dcde3526002f",
        # v1.25.0, latest as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/protocolbuffers/protobuf-go/archive/v1.25.0.zip",
            "https://github.com/protocolbuffers/protobuf-go/archive/v1.25.0.zip",
        ],
        strip_prefix = "protobuf-go-1.25.0",
        patches = [
            # gazelle args: -repo_root . -go_prefix google.golang.org/protobuf -go_naming_convention import_alias -proto disable_global
            "@io_bazel_rules_go//third_party:org_golang_google_protobuf-gazelle.patch",
        ],
        patch_args = ["-p1"],
    )

    # Legacy protobuf compiler, runtime, and utilities.
    # We still use protoc-gen-go because the new one doesn't support gRPC, and
    # the gRPC compiler doesn't exist yet.
    # We need to apply a patch to enable both go_proto_library and
    # go_library with pre-generated sources.
    _maybe(
        http_archive,
        name = "com_github_golang_protobuf",
        # v1.4.2, latest as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/golang/protobuf/archive/v1.4.2.zip",
            "https://github.com/golang/protobuf/archive/v1.4.2.zip",
        ],
        sha256 = "d661b447b6780ab0efd22011b963459dde08ae1f7fa782ab48809a66dcfd7c4c",
        strip_prefix = "protobuf-1.4.2",
        patches = [
            # gazelle args: -repo_root . -go_prefix github.com/golang/protobuf -go_naming_convention import_alias -proto disable_global
            "@io_bazel_rules_go//third_party:com_github_golang_protobuf-gazelle.patch",
        ],
        patch_args = ["-p1"],
    )

    # Extra protoc plugins and libraries.
    # Doesn't belong here, but low maintenance.
    _maybe(
        http_archive,
        name = "com_github_mwitkow_go_proto_validators",
        # v0.3.2, latest as of 2020-08-11
        urls = [
            "https://mirror.bazel.build/github.com/mwitkow/go-proto-validators/archive/v0.3.2.zip",
            "https://github.com/mwitkow/go-proto-validators/archive/v0.3.2.zip",
        ],
        sha256 = "d8697f05a2f0eaeb65261b480e1e6035301892d9fc07ed945622f41b12a68142",
        strip_prefix = "go-proto-validators-0.3.2",
        # Bazel support added in v0.3.0, so no patches needed.
    )

    _maybe(
        http_archive,
        name = "com_github_gogo_protobuf",
        # v1.3.1, latest as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/gogo/protobuf/archive/v1.3.1.zip",
            "https://github.com/gogo/protobuf/archive/v1.3.1.zip",
        ],
        sha256 = "2056a39c922c7315530fc5b7a6ce10cc83b58c844388c9b2e903a0d8867a8b66",
        strip_prefix = "protobuf-1.3.1",
        patches = [
            # gazelle args: -repo_root . -go_prefix github.com/gogo/protobuf -go_naming_convention import_alias -proto legacy
            "@io_bazel_rules_go//third_party:com_github_gogo_protobuf-gazelle.patch",
        ],
        patch_args = ["-p1"],
    )

    _maybe(
        gogo_special_proto,
        name = "gogo_special_proto",
    )

    # go_library targets with pre-generated sources for Well Known Types
    # and Google APIs.
    # Doesn't belong here, but it would be an annoying source of errors if
    # this weren't generated with -proto disable_global.
    _maybe(
        http_archive,
        name = "org_golang_google_genproto",
        # master, as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/googleapis/go-genproto/archive/f69a88009b70a94c67e3910bf1663f5df9fbfc6d.zip",
            "https://github.com/googleapis/go-genproto/archive/f69a88009b70a94c67e3910bf1663f5df9fbfc6d.zip",
        ],
        sha256 = "22d99299278eb992d27a426350c290dfd272818104d02f244162127886ba25d7",
        strip_prefix = "go-genproto-f69a88009b70a94c67e3910bf1663f5df9fbfc6d",
        patches = [
            # gazelle args: -repo_root . -go_prefix google.golang.org/genproto -go_naming_convention import_alias -proto disable_global
            "@io_bazel_rules_go//third_party:org_golang_google_genproto-gazelle.patch",
        ],
        patch_args = ["-p1"],
    )

    # go_proto_library targets for gRPC and Google APIs.
    # TODO(#1986): migrate to com_google_googleapis. This workspace was added
    # before the real workspace supported Bazel. Gazelle resolves dependencies
    # here. Gazelle should resolve dependencies to com_google_googleapis
    # instead, and we should remove this.
    _maybe(
        http_archive,
        name = "go_googleapis",
        # master, as of 2020-08-24
        urls = [
            "https://mirror.bazel.build/github.com/googleapis/googleapis/archive/079e09a64813291f71759d0e1b5f14b0794dc345.zip",
            "https://github.com/googleapis/googleapis/archive/079e09a64813291f71759d0e1b5f14b0794dc345.zip",
        ],
        sha256 = "bba8988a57dc1d259d8e032f3858b52e9708fb863cd378322e703c79582bd064",
        strip_prefix = "googleapis-079e09a64813291f71759d0e1b5f14b0794dc345",
        patches = [
            # find . -name BUILD.bazel -delete
            "@io_bazel_rules_go//third_party:go_googleapis-deletebuild.patch",
            # set gazelle directives; change workspace name
            "@io_bazel_rules_go//third_party:go_googleapis-directives.patch",
            # gazelle args: -repo_root .
            "@io_bazel_rules_go//third_party:go_googleapis-gazelle.patch",
        ],
        patch_args = ["-E", "-p1"],
    )

    # This may be overridden by go_register_toolchains, but it's not mandatory
    # for users to call that function (they may declare their own @go_sdk and
    # register their own toolchains).
    _maybe(
        go_register_nogo,
        name = "io_bazel_rules_nogo",
        nogo = DEFAULT_NOGO,
    )

    go_name_hack(
        name = "io_bazel_rules_go_name_hack",
        is_rules_go = is_rules_go,
    )

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)

def _go_name_hack_impl(ctx):
    ctx.file("BUILD.bazel")
    content = "IS_RULES_GO = {}".format(ctx.attr.is_rules_go)
    ctx.file("def.bzl", content)

go_name_hack = repository_rule(
    implementation = _go_name_hack_impl,
    attrs = {
        "is_rules_go": attr.bool(),
    },
    doc = """go_name_hack records whether the main workspace is rules_go.

See documentation for _filter_transition_label in
go/private/rules/transition.bzl.
""",
)
