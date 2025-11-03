<div align="center">

# asdf-roc [![Build](https://github.com/eratio08/asdf-roc/actions/workflows/build.yml/badge.svg)](https://github.com/eratio08/asdf-roc/actions/workflows/build.yml) [![Lint](https://github.com/eratio08/asdf-roc/actions/workflows/lint.yml/badge.svg)](https://github.com/eratio08/asdf-roc/actions/workflows/lint.yml)

[roc](https://www.roc-lang.org) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).

# Install

Plugin:

```shell
asdf plugin add roc https://github.com/eratio08/asdf-roc.git
```

roc:

```shell
# Show all installable versions
asdf list-all roc

# Install specific version
asdf install roc latest

# Set a version globally (on your ~/.tool-versions file)
asdf global roc latest

# Now roc commands are available
roc -V
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to install & manage versions.
