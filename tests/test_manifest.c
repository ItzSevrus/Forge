#include "forge.h"
#include <stdio.h>
#include <string.h>

int main(void)
{
    const char *valid =
        "[package]\nname = \"hello-world\"\nversion = \"1.2.3\"\n"
        "description = \"A test package\"\nlicense = \"MIT\"\n"
        "[source]\nurl = \"https://example.org/source.tar.gz\"\nchecksum = \"sha256:0123456789012345678901234567890123456789012345678901234567890123\"\n"
        "[build]\nscript = \"build.sh\"\ncommand = \"./build.sh\"\ncompilers = [\"cc\", \"make\"]\n"
        "[dependencies]\nruntime = [\"lib-example\"]\nbuild = []\n"
        "[dependencies.system]\napt = [\"build-essential\"]\npacman = [\"base-devel\"]\n";
    ForgePackage pkg; char err[256];
    if (forge_manifest_parse(valid, &pkg, err, sizeof(err)) != 0) {
        fprintf(stderr, "valid manifest rejected: %s\n", err); return 1;
    }
    if (strcmp(pkg.name, "hello-world") || strcmp(pkg.version, "1.2.3") ||
        pkg.runtime_dep_count != 1 || strcmp(pkg.runtime_deps[0], "lib-example") ||
        strcmp(pkg.build_command, "./build.sh") || pkg.compiler_count != 2 ||
        strcmp(pkg.compilers[0], "cc") || pkg.apt_dep_count != 1 || pkg.pacman_dep_count != 1) {
        fprintf(stderr, "manifest values parsed incorrectly\n"); return 1;
    }
    const char *bad =
        "[package]\nname = \"../escape\"\nversion = \"1\"\ndescription = \"bad\"\nlicense = \"MIT\"\n"
        "[source]\nurl = \"https://example.org/a.tar.gz\"\n[build]\nscript = \"build.sh\"\n";
    if (forge_manifest_parse(bad, &pkg, err, sizeof(err)) == 0) {
        fprintf(stderr, "invalid package name unexpectedly accepted\n"); return 1;
    }
    puts("Manifest parser tests passed");
    return 0;
}
