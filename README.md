
# Pekmez Invoice

Minimalistic CLI friendly invoice generator

![](./example/myinvoice.png)

Tried to get the looks from the projects in the <a href="#thanks">thanks</a> section.
Removed the complexity I didn't understand myself and added support to call it
from CLI.

## Usage

You need to have a configuration file

### Configuration

Put the config file somewhere, by default it will read from
`$XDG_CONFIG_HOME/pekmez-invoice/details.yaml`, `$XDG_CONFIG_HOME` depends on the
system, but usually `~/.config`.

See [example config file](./src/details.yaml)

### Run

Current possible ways to run is below;

#### Nix

Straightforward to run with [Nix](https://nixos.org/)

```bash
nix run github:Deliganli/pekmez-invoice -- \
    --date 15.09.2025 \
    --number 1234 \
    item -l "Misdirecting witnesses" -p 5000 \
    item -l "Taking forever to deduce the obvious" -p 12999 \
    --output myinvoice.pdf
```

#### Typst

Via [Typst](https://typst.app/)

Typst treats file paths relative to the given `typ` file. So `cd` into
where this code exists.

```bash
typst compile \
    --input config="details.yaml" \
    --input date="15.09.2025" \
    --input number="1234" \
    --input items='[{"description":"Misdirecting witnesses", "price":5000 }, {"description":"Taking forever to deduce the obvious", "price":12999 }]' \
    "./src/lib/template.typ" myinvoice.pdf
```

#### Docker

A bit more args with docker

```bash
docker run \
    -u $(id -u):$(id -g) \
    -v "$HOME/.config/pekmez-invoice:/.config/pekmez-invoice:ro" \
    -v './:/app/out/' \
    ghcr.io/deliganli/pekmez-invoice \
    --date 15.09.2025 \
    --number 1234 \
    item -l "Misdirecting witnesses" -p 5000 \
    item -l "Taking forever to deduce the obvious" -p 12999 \
    --output out/myinvoice.pdf
```

- `-u $(id -u):$(id -g)`: this is to use same file permissions as our current user
- `-v "$HOME/.config/pekmez-invoice:/.config/pekmez-invoice:ro"` : mount the
config file to container so it can access
- `-v './:/app/out/'` : mount the current directory as output

Rest is the same as others. After running, find the `myinvoice.pdf` in the
directory you run this command

### Thanks

<a name="thanks"></a>
Inspired and straight out copied code from below projects

- [tiefletter](https://github.com/Tiefseetauchner/TiefLetter): nice and minimalistic invoice template
- [typst-invoice](https://github.com/erictapen/typst-invoice): minimalistic German invoice template
- [invoice-boilerplate](https://github.com/mrzool/invoice-boilerplate/): simplest yet best looking invoice template
