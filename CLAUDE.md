# nixos-artifacts-agenix

An [agenix](https://github.com/ryantm/agenix) backend implementation for
[nixos-artifacts](https://github.com/mrVanDalo/nixos-artifacts), providing
encrypted secret management for both NixOS and Home Manager configurations.

## Purpose

This project bridges `nixos-artifacts` with `agenix`, enabling encrypted secret
serialization and deserialization using age encryption. It provides a
standardized way to manage secrets across NixOS machines and Home Manager user
configurations.

## Architecture

### Core Components

- **backend_agenix.nix**: Backend implementation providing serialization scripts
  - `check_configuration`: Validates environment and configuration prerequisites
  - `check_serialization`: Verifies encrypted secrets exist at expected paths
  - `serialize`: Encrypts plaintext artifacts using age and stores them
  - `deserialize`: Placeholder (agenix handles decryption at runtime)

- **modules/**: NixOS module definitions
  - `config.nix`: Configuration options for agenix backend (NixOS)
  - `store.nix`: Maps `artifacts.store` to `age.secrets` for NixOS
  - `default.nix`: Entry point importing both modules

- **modules/hm/**: Home Manager module definitions
  - `config.nix`: Configuration options for agenix backend (Home Manager)
  - `store.nix`: Maps `artifacts.store` to `age.secrets` for Home Manager
  - `default.nix`: Entry point importing both modules

### Directory Structure

```
secrets/
├── per-machine/
│   └── <machine-name>/
│       └── <artifact-name>/
│           └── <file>.age
└── per-user/
    └── <username>/
        └── <artifact-name>/
            └── <file>.age
```

## Key Features

### Dual Context Support

**NixOS Context:**

- Requires `machine` environment variable
- Uses `publicHostKey` + optional `publicUserKeys` for encryption
- Secrets stored under `secrets/per-machine/<machine>/`

**Home Manager Context:**

- Requires `username` environment variable
- Uses `publicUserKeys` for encryption
- Secrets stored under `secrets/per-user/<username>/`
- Requires `identityPaths` for runtime decryption

### Configuration Options

#### NixOS (`artifacts.config.agenix`)

| Option           | Type         | Description                     | Default                      |
| ---------------- | ------------ | ------------------------------- | ---------------------------- |
| `storeDir`       | string       | Path to secrets store           | `"secrets"`                  |
| `flakeStoreDir`  | path         | Flake path to encrypted secrets | -                            |
| `machineName`    | string       | Machine identifier              | `config.networking.hostName` |
| `publicHostKey`  | string       | SSH public key for host         | -                            |
| `publicUserKeys` | list[string] | SSH public keys for users       | `[]`                         |

#### Home Manager (`artifacts.config.agenix`)

| Option           | Type         | Description                          | Default                |
| ---------------- | ------------ | ------------------------------------ | ---------------------- |
| `storeDir`       | string       | Path to secrets store                | `"secrets"`            |
| `flakeStoreDir`  | path         | Flake path to encrypted secrets      | -                      |
| `username`       | string       | User identifier                      | `config.home.username` |
| `identityPaths`  | list[string] | SSH private key paths for decryption | -                      |
| `publicUserKeys` | list[string] | SSH public keys for encryption       | `[]`                   |

## Usage Examples

### NixOS Configuration

```nix
{
  imports = [
    inputs.nixos-artifacts.nixosModules.default
    inputs.nixos-artifacts-agenix.nixosModules.default
  ];

  artifacts.default.backend.serialization = "agenix";
  artifacts.config.agenix = {
    storeDir = "./secrets";
    flakeStoreDir = ./secrets;
    publicHostKey = "ssh-ed25519 AAAA...";
    publicUserKeys = [
      "ssh-ed25519 AAAA..."
      "age1yubikey1q0..."
    ];
  };
}
```

### Home Manager Configuration

```nix
{
  imports = [
    inputs.nixos-artifacts.homeModules.default
    inputs.nixos-artifacts-agenix.homeModules.default
  ];

  artifacts.default.backend.serialization = "agenix";
  artifacts.config.agenix = {
    username = "my-user";
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    storeDir = "./secrets";
    flakeStoreDir = ./secrets;
    publicUserKeys = [
      "ssh-ed25519 AAAA..."
      "age1yubikey1q0..."
    ];
  };
}
```

## Module Variants

- `nixosModules.default`: Includes agenix NixOS module
- `nixosModules.without-agenix`: Only nixos-artifacts integration
- `homeModules.default`: Includes agenix Home Manager module
- `homeModules.without-agenix`: Only nixos-artifacts integration

## Dependencies

- [agenix](https://github.com/ryantm/agenix): Age encryption integration
- [nixos-artifacts](https://github.com/mrVanDalo/nixos-artifacts): Artifact
  abstraction framework
- [home-manager](https://github.com/nix-community/home-manager): User
  environment management
- [flake-parts](https://github.com/hercules-ci/flake-parts): Flake structure
- [devshell](https://github.com/numtide/devshell): Development environment
- [treefmt-nix](https://github.com/numtide/treefmt-nix): Code formatting

## Technical Details

### Serialization Process

1. **Validation**: `check_configuration` ensures required environment variables
   and config fields exist
2. **Verification**: `check_serialization` verifies all expected encrypted files
   are present
3. **Encryption**: `serialize` script:
   - Generates agenix rules file with appropriate public keys
   - Encrypts each artifact file with armor encoding
   - Stores encrypted files in context-specific directory structure
   - Provides progress feedback (🕛 processing, 💾 saved, ✅ verified, ❌
     missing)

### Runtime Decryption

Deserialization is handled by agenix itself:

- NixOS: Uses host SSH keys automatically
- Home Manager: Uses `identityPaths` configuration

### Key Discovery

- **Host Keys**: Retrieved via `ssh-keyscan <host>`
- **User Keys**: From `~/.ssh/id_ed25519.pub` or similar
- **YubiKey**: Via `age-plugin-yubikey --list`

## Development

The flake provides:

- Development shells via `devshell`
- Formatting via `treefmt-nix`
- Example configurations for both NixOS and Home Manager
- Serialization/deserialization test packages

## Documentation

The project uses [Antora](https://antora.org/) for documentation, structured
following the Antora component specification.

### Documentation Structure

```
docs/
├── antora.yml              # Component descriptor
└── modules/
    └── ROOT/               # Root module
        ├── nav.adoc        # Navigation menu
        └── pages/          # Documentation pages
            ├── index.adoc
            ├── how-to-use-agenix-backend.adoc
            ├── how-to-configure-artifacts-cli.adoc
            ├── directory_layout.adoc
            └── options.adoc
```

### Component Configuration (antora.yml)

- **Component Name**: `nixos-artifacts-agenix`
- **Title**: "NixOS Artifacts Agenix"
- **Version**: `latest`
- **Format**: AsciiDoc

### Documentation Pages

1. **index.adoc**: Main landing page
   - Overview of the project
   - Quick links to key documentation sections
   - Explains dual purpose (NixOS module + CLI backend)

2. **how-to-use-agenix-backend.adoc**: Integration guide
   - Flake input configuration
   - Module imports for NixOS
   - Configuration examples with annotated code blocks
   - Cross-references to options documentation

3. **how-to-configure-artifacts-cli.adoc**: CLI setup guide
   - Quick start using `nix shell`
   - Overriding the artifacts-cli package
   - Examples for both flake-parts and plain flakes
   - Backend injection patterns

4. **directory_layout.adoc**: Storage structure
   - Documents the `per-machine` and `per-user` directory hierarchy
   - Path patterns for encrypted `.age` files

5. **options.adoc**: Configuration reference (auto-generated)
   - Generated from NixOS module option definitions via `nix/options.nix`
   - Includes types, defaults, examples, and descriptions
   - Uses AsciiDoc attributes for formatting (e.g., `{zwsp}` for zero-width
     spaces)

### Navigation Structure

The `nav.adoc` file defines the documentation menu:

- Home (index)
- Integrate Backend in Your Flake
- Configure artifacts command
- Directory Layout
- Options

### Documentation Features

- **Cross-references**: Uses Antora's `xref:` syntax for internal links
- **Code examples**: Annotated with callouts (`<1>`, `<2>`, etc.)
- **Formatted options**: Uses special character entities for proper rendering
- **Semantic markup**: Distinguishes between code, paths, and configuration

### Generating Options Documentation

The `options.adoc` file is automatically generated from the NixOS module
definitions using a multi-step process defined in `nix/options.nix`:

1. **Evaluate modules**: Uses NixOS's `eval-config.nix` to evaluate
   `modules/config.nix`
2. **Extract to JSON**: Generates option metadata using `nixosOptionsDoc`
3. **Clean JSON**: Removes internal `.declarations` fields with `gojq`
4. **Convert to AsciiDoc**: Uses `nixos-render-docs` to create formatted
   documentation
5. **Write file**: Outputs to `docs/modules/ROOT/pages/options.adoc`

To regenerate the options documentation:

```bash
nix run .#build-docs-options
```

This ensures the documentation stays synchronized with the actual module option
definitions in `modules/config.nix`.

### Building Documentation

The documentation is designed to be built as part of an Antora site. To include
it in an Antora documentation site, add this repository as a content source in
your Antora playbook:

```yaml
content:
  sources:
    - url: https://github.com/mrVanDalo/nixos-artifacts-agenix
      start_path: docs
```

### Testing Documentation Locally

For local documentation development and testing, use the following commands:

**Build documentation once:**

```bash
nix run .#build-docs
```

This builds the Antora site to `build/site/`.

**Build and serve documentation:**

```bash
nix run .#serve-docs
```

This builds the site and starts a local HTTP server at `http://localhost:8000`.
Press Ctrl+C to stop.

**Watch for changes:**

```bash
nix run .#watch-docs
```

This watches the `docs/` folder for changes to `.adoc`, `.yml`, and `.yaml`
files, automatically rebuilding the documentation when changes are detected.
Press Ctrl+C to stop.

**Note:** The `docs/antora-playbook.yml` file is only used for local
documentation testing and preview. Production documentation sites should
reference this repository as a content source in their own playbook
configuration.

## License

MIT License
