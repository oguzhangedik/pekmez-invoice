{ lib, stdenv, pkgs, writeShellApplication, ... }:

let
  isWindows = builtins.match ".*-windows" stdenv.hostPlatform.system != null;

  program = if isWindows then
    pkgs.writeShellApplication {
      name = "pekmez-invoice.ps1";
      runtimeInputs = with pkgs; [ typst ];

      text = ''
        param (
          [string] $date = "",
          [string] $number = "",
          [string] $output = "invoice.pdf",
          [string] $config = "$Env:XDG_CONFIG_HOME\\pekmez-invoice\\details.yaml",
          [array] $items = @()
        )

        function Show-Usage {
          Write-Host "Usage: pekmez-invoice.ps1 --date <date> --number <number> [--output <file>] [--config <file>] item --desc <desc> --price <price>"
          exit 1
        }

        # Parse args manually for 'item' entries and parameters
        $parsedArgs = @{ date=""; number=""; output="invoice.pdf"; config="$Env:XDG_CONFIG_HOME\\pekmez-invoice\\details.yaml"; items = @() }

        $i = 0
        while ($i -lt $args.Count) {
          switch ($args[$i]) {
            '--date' { $i++; $parsedArgs.date = $args[$i] }
            '--number' { $i++; $parsedArgs.number = $args[$i] }
            '--output' { $i++; $parsedArgs.output = $args[$i] }
            '--config' { $i++; $parsedArgs.config = $args[$i] }
            'item' {
              $i++
              $desc = ""
              $price = ""

              while ($i -lt $args.Count) {
                switch ($args[$i]) {
                  '--desc' { $i++; $desc = $args[$i] }
                  '--price' { $i++; $price = $args[$i] }
                  default { break }
                }
                $i++
              }

              if ([string]::IsNullOrEmpty($desc) -or [string]::IsNullOrEmpty($price)) {
                Write-Error "item requires --desc and --price"
                exit 1
              }

              $itemObj = @{ description = $desc; price = $price }
              $parsedArgs.items += $itemObj
              continue
            }
            default {
              Write-Error "Unknown argument: $($args[$i])"
              Show-Usage
            }
          }
          $i++
        }

        if ([string]::IsNullOrEmpty($parsedArgs.date)) {
          Write-Error "Missing --date"
          Show-Usage
        }
        if ([string]::IsNullOrEmpty($parsedArgs.number)) {
          Write-Error "Missing --number"
          Show-Usage
        }
        if ($parsedArgs.items.Count -eq 0) {
          Write-Error "Missing items"
          Show-Usage
        }

        $itemsJson = $parsedArgs.items | ConvertTo-Json -Depth 5

        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

        typst compile `
          --root / `
          --input config="$(Resolve-Path $parsedArgs.config)" `
          --input date="$($parsedArgs.date)" `
          --input number="$($parsedArgs.number)" `
          --input items="$itemsJson" `
          "$scriptDir\..\lib\template.typ" "$parsedArgs.output"
      '';
    }
  else
    writeShellApplication {
      name = "pekmez-invoice";
      runtimeInputs = with pkgs; [ typst jq coreutils ];

      text = ''
        declare -A args=(
          ["date"]=""
          ["number"]=""
          ["output"]="invoice.pdf"
          ["config"]="''${XDG_CONFIG_HOME:-$HOME/.config}/pekmez-invoice/details.yaml"
          ["items"]="[]"
        )

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --date|-d) args["date"]="$2"; shift 2 ;;
            --number|-n) args["number"]="$2"; shift 2 ;;
            --output|-o) args["output"]="$2"; shift 2 ;;
            --config|-c) args["config"]="$2"; shift 2 ;;
            item)
              shift
              declare -A item_args=( ["desc"]="" ["price"]="" )
              while [[ $# -gt 0 && $1 =~ --desc|-d|--price|-p ]]; do
                case "$1" in
                  --desc|-l) item_args["desc"]="$2"; shift 2 ;;
                  --price|-p) item_args["price"]="$2"; shift 2 ;;
                  *) break ;;
                esac
              done

              item_json=$(jq --null-input \
                --arg desc "''${item_args["desc"]}" \
                --arg price "''${item_args["price"]}" \
                '{"description": $desc, "price": $price}')

              args["items"]=$(echo "''${args["items"]}" | jq --argjson item "$item_json" '. + [$item]')
              ;;
            *) echo "Unknown option: $1"; exit 1 ;;
          esac
        done

        [[ -z "''${args["date"]}" ]] && echo "Missing --date" && exit 1
        [[ -z "''${args["number"]}" ]] && echo "Missing --number" && exit 1
        [[ "''${args["items"]}" == "[]" ]] && echo "Missing items" && exit 1

        SCRIPT_DIR=$(cd -- "$(dirname -- "''${BASH_SOURCE[0]}")" &> /dev/null && pwd)

        typst compile \
          --root / \
          --input config="$(realpath "''${args["config"]}")" \
          --input date="''${args["date"]}" \
          --input number="''${args["number"]}" \
          --input items="''${args["items"]}" \
          "$SCRIPT_DIR/../lib/template.typ" "''${args["output"]}"
      '';
    };

in
stdenv.mkDerivation (final: {
  pname = "pekmez-invoice";
  version = "0.1.0";
  src = ./src;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -D -m 755 ${lib.getExe program} -t $out/bin/
    install -D -m 644 ${final.src}/lib/template.typ -t $out/lib/
    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/Deliganli/pekmez-invoice";
    description = "Minimalistic CLI friendly invoice generator";
    license = lib.licenses.gpl3;
    mainProgram = "pekmez-invoice";
  };
})
