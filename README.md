# ğchange desktop packager

## Test a release

This script will run ğchange desktop, taking care of installing ğchange + Nw.js if necessary.

    ./run.sh 

## Produce new release

**Requires your GITHUB token with full access to `repo`** to be stored in clear in `$HOME/.config/duniter-gchange/.github` text file.

> You can create such a token at https://github.com/settings/tokens > "Generate a new token". Then copy the token and paste it in the file.

This script will produce for a given `TAG`:

* check that the `TAG` exists on remote GitHub repository
* eventually create the pre-release if it does not exist
* produce Linux and Windows releases of ğchange desktop and upload them

To produce `TAG` 0.5.2:

    ./release.sh 0.5.2
    