# Forge

**Forge is a user-local package manager written in C.** It discovers
versioned packages from Git-backed repositories, downloads source
archives and build scripts, verifies source checksums, and installs
software under a user-owned prefix rather than requiring a system-wide
installation.

Forge is designed around one principle: package installation should be
understandable. It shows what it downloads, where files are stored,
which build command runs, and which system dependencies it checks. You
should be able to inspect a package before allowing it to execute.

> **Project status:** Forge is under active development. This README
> describes the current 0.3.x development workflow; some features and
> edge cases may still evolve.

## Contents

-   [Why Forge?](#why-forge)
-   [How it works](#how-it-works)
-   [Build Forge](#build-forge)
-   [First steps](#first-steps)
-   [Command reference](#command-reference)
-   [Package versions](#package-versions)
-   [Transparency and security](#transparency-and-security)
-   [Creating a package repository](#creating-a-package-repository)
-   [Testing Forge](#testing-forge)
-   [Troubleshooting](#troubleshooting)
-   [Contributing](#contributing)

## Why Forge?

Forge is for people who want a lightweight way to install software in
their own user environment and understand what the package manager is
doing.

-   **User-local installs:** the intended prefix is a directory owned by
    the user, commonly `~/.local`.
-   **Versioned packages:** packages can be published in distinct
    version directories and requested by exact version.
-   **Visible operations:** downloads, destinations, dependency checks,
    and the build command are shown during installation.
-   **Checksum verification:** Forge verifies the downloaded source
    archive against the SHA-256 value declared by the package.
-   **Repository-based discovery:** Forge reads package metadata from
    configured repositories; it does not need to clone the entire
    repository to install a package.
-   **System dependency checks:** Forge can check declared system
    dependencies using supported system package managers and check for
    required build tools.
-   **Explicit trust prompt:** Forge warns that package build scripts
    execute as your user and asks you to review and approve before
    proceeding.

Forge is not a sandbox. A user-local install avoids unnecessary
administrator privileges, but a build script still has the permissions
of the user running Forge.

## How it works

A typical installation follows this flow:

1.  Forge looks up the requested package and version in its locally
    synced repository catalog.
2.  It displays package details and asks you to approve execution of the
    package's build script.
3.  It checks declared system dependencies and required build tools.
4.  It downloads the source archive and build script, showing their URLs
    and local destinations.
5.  It verifies the source archive's SHA-256 checksum against the
    manifest.
6.  It runs the declared build command in the package's build directory
    as your user.
7.  It installs the resulting files under the configured user-local
    prefix.

A successful repository sync means Forge could read and index the
repository. It does not prove that every package can build or install
successfully.

## Build Forge

### Requirements

The current source tree uses a C11 compiler and links against libcurl
and OpenSSL. On Arch Linux, the relevant development packages are
typically available through `base-devel`, `curl`, and `openssl`. Other
distributions may use different package names.

### Compile

From the Forge source checkout:

``` sh
make clean
make
```

The build output is `build/forge`. Run it directly:

``` sh
./build/forge --help
```

To make it available in your user-local executable directory (ensure
`~/.local/bin` is on your `PATH`):

``` sh
install -Dm755 build/forge "$HOME/.local/bin/forge"
```

Then check:

``` sh
forge --help
```

## First steps

Read the available commands:

``` sh
forge --help
```

Initialize Forge's local configuration if this is a fresh installation:

``` sh
forge setup
```

Inspect the configuration and installation prefix:

``` sh
forge config
forge config get prefix
```

To change the prefix:

``` sh
forge config set prefix "$HOME/.local"
```

Add a repository using the exact argument syntax shown by `forge --help`
or the relevant command help, then sync it. In these examples,
`official` is the alias configured for the official example repository:

``` sh
forge repo list
forge repo sync official
forge repo validate
```

Search for a package and inspect its information:

``` sh
forge search hello
forge info hello-world
```

Install a specific version:

``` sh
forge install hello-world@v1.0.0
```

The example package installs a `hello` command:

``` sh
hello
```

Expected output:

``` text
Hello from forge!
```

## Command reference

These are commands available in the current development CLI. Consult
`forge --help` for exact syntax and supported options.

  -----------------------------------------------------------------------
  Command                             Purpose
  ----------------------------------- -----------------------------------
  `forge --help`                      Show command help.

  `forge setup`                       Initialize Forge's user
                                      configuration.

  `forge config`                      Inspect configuration.

  `forge config get prefix`           Read the configured installation
                                      prefix.

  `forge config set prefix <path>`    Set the installation prefix.

  `forge repo list`                   List configured repositories.

  `forge repo add ...`                Add a repository; consult CLI help
                                      for the exact argument order.

  `forge repo remove ...`             Remove a configured repository.

  `forge repo sync <alias>`           Fetch and index a repository
                                      catalog.

  `forge repo validate`               Validate synced repository catalog
                                      entries.

  `forge search <query>`              Search package catalogs.

  `forge info <package>`              Display package information.

  `forge install <name>@<version>`    Install a specific package version.

  `forge list`                        List installed packages.

  `forge uninstall <package>`         Uninstall a package.
  -----------------------------------------------------------------------

For reproducible selection, prefer an explicit version:

``` sh
forge install hello-world@v1.0.0
```

In the current implementation, searching for a nonexistent package may
return a non-zero exit status and print that no packages were found.

## Package versions

Forge uses a versioned repository layout. For example:

``` text
packages/
└── hello-world/
    └── v1.0.0/
        ├── forge.pkg
        └── build.sh
```

Each version can have its own manifest, source archive, checksum, and
build script. Use an exact version when you need to select a particular
release:

``` sh
forge install hello-world@v1.0.0
```

Do not assume a package supports `@latest` unless the repository and
installed Forge version explicitly support it.

## Transparency and security

Forge aims to make package installation visible rather than opaque.

### What Forge shows

During installation, Forge can show:

-   package name, version, and description;
-   source archive URL and download destination;
-   download progress and size;
-   SHA-256 checksum verification status;
-   declared system dependencies and whether they are installed;
-   required build tools;
-   build directory and exact build command;
-   target user-local installation prefix.

### What a checksum proves

A matching SHA-256 checksum proves that the downloaded archive matches
the checksum recorded in the manifest. It does **not** independently
prove that the source is safe or that the checksum came from a
trustworthy maintainer. A compromised repository could publish malicious
source and a matching checksum.

Prefer repositories and maintainers you trust. Review package manifests,
source URLs, release artifacts, and build scripts before installation.

### Build scripts execute as your user

Forge warns that it will execute a package's build script as your user.
Such a script can potentially read or modify files your account can
access, use your network connection, or launch other programs. A
user-local prefix is not a security sandbox.

Before approving an installation:

1.  Read the manifest and inspect the source URL.
2.  Review the repository's `build.sh` and any scripts it invokes.
3.  Confirm the declared build command and expected output.
4.  Stop if the download source, checksum, or script looks unexpected.

Do not run Forge with `sudo` to install ordinary user packages. Elevated
privileges would also elevate the permissions available to the build
script.

### System dependencies and repository trust

Forge checks declared system dependencies using supported system package
managers and checks for required build tools. These checks do not
guarantee that every runtime dependency is present or that a build
script is safe.

A repository can control package metadata, source locations, checksums,
and build scripts for the packages it publishes. Adding a repository
means trusting its maintainers to some degree. Check the repository URL
and use repository aliases deliberately.

## Creating a package repository

For the canonical repository-specific instructions and the current
working example, see the [Forge Official Repository
README](https://github.com/ItzSevrus/forgeRepo). Use that repository as
the reference for the expected layout and metadata.

The current example structure is:

``` text
forgeRepo/
├── repository.conf
└── packages/
    └── hello-world/
        └── v1.0.0/
            ├── forge.pkg
            └── build.sh
```

### 1. Create a Git repository

Create a repository on your Git hosting service and clone it:

``` sh
git clone https://github.com/<your-account>/<your-repository>.git
cd <your-repository>
```

### 2. Add repository metadata

The current official example uses `repository.conf` with format 2:

``` ini
[repository]
name = "my-repository"
format = 2
description = "My Forge package repository"
default_branch = "main"
package_layout = "packages///forge.pkg"
```

Keep the metadata consistent with the layout expected by the Forge
version you intend to support. For exact current layout rules, follow
the official repository's README and `repository.conf`.

### 3. Add a versioned package directory

Create a directory for the package and version:

``` sh
mkdir -p packages/example-app/v1.0.0
```

Add:

-   `forge.pkg` --- package metadata consumed by Forge.
-   `build.sh` --- the build/install script that Forge executes after
    download and approval.

The manifest should declare package identity and version, description,
source archive location, SHA-256 checksum, build command, and
dependencies using the schema supported by your Forge version. Use the
[official hello-world
package](https://github.com/ItzSevrus/forgeRepo/tree/master/packages/hello-world)
as the working example rather than guessing field names or types.

### 4. Publish a source archive and checksum

Create a release archive containing the source files expected by the
build script. Publish it as a release asset, then calculate its SHA-256
checksum. For example:

``` sh
sha256sum example-app-1.0.0.tar.gz
```

Copy the resulting digest into the manifest exactly. The checksum must
correspond to the exact archive Forge downloads. If the archive changes,
recalculate and update the checksum.

### 5. Test the package before publishing

Check the archive contents, build script, URLs, checksum, and
dependencies. Test the build in a disposable user account or isolated
environment where possible. Remember that `build.sh` runs with the
installing user's permissions.

### 6. Commit and push

``` sh
git add repository.conf packages/
git commit -m "Add example-app v1.0.0"
git push
```

Make sure the branch and metadata agree. Then sync and validate the
catalog:

``` sh
forge repo sync <your-alias>
forge repo validate
forge search example-app
forge info example-app
```

A catalog that validates is only the first check. Test the actual
install and resulting executable as well.

## Testing Forge

The development checkout includes an integration-test runner named
`test-forge.sh`. From the Forge source directory:

``` sh
chmod +x test-forge.sh
./test-forge.sh
```

This checks the build, basic CLI behavior, repository
listing/validation/sync, package search, and invalid requests. Real
installation is skipped by default.

To include the real `hello-world` installation test:

``` sh
RUN_INSTALL=1 ./test-forge.sh
```

The test may encounter a package that is already installed, in which
case Forge can report that it is already installed instead of installing
it again. This is an integration smoke test, not exhaustive security
testing. Additional isolated tests should cover malformed manifests,
checksum mismatches, missing dependencies, failed downloads,
build-script failures, and uninstall safety.

## Troubleshooting

### `forge` is not found

Check that the executable exists in `~/.local/bin` and that directory is
on your `PATH`:

``` sh
printf '%s\n' "$PATH"
ls -l "$HOME/.local/bin/forge"
```

### The repository has no packages

Sync the repository and validate the catalog:

``` sh
forge repo sync official
forge repo validate
forge search hello
```

If the catalog is still empty, check the repository URL, branch,
`repository.conf`, and versioned package paths.

### A package is already installed

Forge may decline to reinstall the same version and print
`Already installed`. Check the installed-package listing:

``` sh
forge list
```

### Checksum verification fails

Do not bypass the check. Verify that the release asset has not changed
and that the manifest contains the SHA-256 digest for the exact
downloaded file.

### A build fails

Read the build output, confirm the required compiler and system
dependencies are installed, and inspect the build script and source
archive. A successful download does not imply a successful build.

## Contributing

Issues, bug reports, and contributions are welcome. When reporting a
problem, include:

-   Forge version or commit;
-   operating system and architecture;
-   the command you ran;
-   the full relevant output;
-   repository alias and package version, when applicable.

Never include secrets, access tokens, or private data in bug reports.

## License

Add the project's chosen license and copyright details here before
publishing a release.
