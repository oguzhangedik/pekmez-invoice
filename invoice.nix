{
  lib,
  stdenv,
  pkgs,
  writeShellApplication,
  ...
}:
let
  program = writeShellApplication {
    name = "pekmez-invoice";
    runtimeInputs = with pkgs; [
      typst
      coreutils
    ];

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
          --date|-d)
            args["date"]="$2"
            shift 2
            ;;
          --number|-n)
            args["number"]="$2"
            shift 2
            ;;
          --output|-o)
            args["output"]="$2"
            shift 2
            ;;
          --config|-c)
            args["config"]="$2"
            shift 2
            ;;
          item)
            shift 1

            declare -A item_args=(
              ["desc"]=""
              ["price"]=""
            )

            while [[ $# -gt 0 && $1 =~ --desc|-d|--price|-p ]]; do
              case "$1" in
                --desc|-l)
                  item_args["desc"]="$2"
                  shift 2
                  ;;
                --price|-p)
                  item_args["price"]="$2"
                  shift 2
                  ;;
                *)
                  break
                  ;;
              esac
            done

            if [[ -z "''${item_args["desc"]}" ]]; then
              echo "Missing required argument: --desc"
              exit 1
            elif [[ -z "''${item_args["price"]}" ]]; then
              echo "Missing required argument: --price"
              exit 1
            fi

            item_json=$(jq --null-input \
              --arg desc "''${item_args["desc"]}" \
              --arg price "''${item_args["price"]}" \
              '{"description": $desc, "price": $price}')

            args["items"]=$(echo "''${args["items"]}" | jq \
              --argjson item "$item_json" \
              '. + [$item]')
            ;;
          *)
            echo "$@"
            echo "Unknown option: $1"
            exit 1
            ;;
        esac
      done

      if [[ -z "''${args["date"]}" ]]; then
        echo "Missing required argument: --date"
        exit 1
      elif [[ -z "''${args["number"]}" ]]; then
        echo "Missing required argument: --number"
        exit 1
      elif [[ "''${args["items"]}" = [] ]]; then
        echo "Missing required command: item"
        exit 1
      fi

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
