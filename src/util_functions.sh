source src/declarations.sh
source src/fetcher.sh
source src/verifier.sh

function check_and_download_dependencies() {
  mkdir -p "${WORKDIR}"

  # Check for Python requirements
  if ! command -v python3 &> /dev/null; then
    echo -e "Python 3 is required to run this script.\nExiting..."
    exit 1
  fi

  # Check for required tools
  # If they're present, continue with the script
  # Else, download them by checking version from declarations
  local tools=("avbroot" "afsr" "alterinstaller" "custota" "custota-tool" "msd" "bcr" "oemunlockonboot" "my-avbroot-setup")
  for tool in "${tools[@]}"; do
    local flag=$(flag_check "${tool}")
    if [[ "${flag}" == 'false' ]]; then
      echo -e "\`${tool}\` is **NOT** enabled in the configuration.\nSkipping...\n"
      continue
    fi

    local tool_upper_case=$(echo "${tool}" | tr '[:lower:]' '[:upper:]')

    if ! find "${WORKDIR}" -maxdepth 1 -name "${tool}*" -print -quit | grep -q .; then
      download_dependencies "${tool}"
    else
      echo -e "\`${tool}\` is already installed in: \`${WORKDIR}/${tool}\`"
      continue
    fi
    verify_downloads "${tool}"
  done

  if [[ "${ADDITIONALS[ROOT]}" == 'true' ]]; then
    get "magisk" "${MAGISK[URL]}/releases/download/canary-${VERSION[MAGISK]}/app-release.apk"
    verify_downloads "magisk.apk"
  fi
}

function flag_check() {
  local tool="${1}"
  local tool_upper_case=$(echo "${tool}" | tr '[:lower:]' '[:upper:]')

  if [[ "${tool}" == "my-avbroot-setup" ]]; then
    FLAG="${ADDITIONALS[MY_AVBROOT_SETUP]}"
  else
    FLAG="${ADDITIONALS[$tool_upper_case]}"
  fi

  if [[ "${FLAG}" == 'true' ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

function create_and_make_release() {
  create_ota
  release_ota
  push_to_server
}

function create_ota() {
  [[ "${CLEANUP}" != 'true' ]] && trap cleanup EXIT ERR

  # Setup environment variables and paths
  env_setup
  # Patch OTA with avbroot and afsr by leveraging my-avbroot-setup
  patch_ota
}

function cleanup() {
  echo "Cleaning up..."
  rm -rf "${WORKDIR}"
  unset "${KEYS[@]}"
  echo "Cleanup complete."
}

# Generate the AVB and OTA signing keys.
# Has to be called manually.
function generate_keys() {
  local public_key_metadata='avb_pkmd.bin'

  # Generate the AVB and OTA signing keys
  avbroot key generate-key -o "${KEY_AVB}"
  avbroot key generate-key -o "${KEY_OTA}"

  # Convert the public key portion of the AVB signing key to the AVB public key metadata format
  # This is the format that the bootloader requires when setting the custom root of trust
  avbroot key extract-avb -k "${KEY_AVB}" -o "${public_key_metadata}"

  # Generate a self-signed certificate for the OTA signing key
  # This is used by recovery to verify OTA updates when sideloading
  avbroot key generate-cert -k "${KEY_OTA}" -o "${CERT_OTA}"
}

function patch_ota() {
  local ota_zip="${WORKDIR}/${GRAPHENEOS[OTA_TARGET]}"
  local pkmd="${KEYS[PKMD]}"
  local grapheneos_pkmd="extracted/extracts/avb_pkmd.bin"
  local grapheneos_otacert="extracted/ota/META-INF/com/android/otacert"
  local my_avbroot_setup="${WORKDIR}/my-avbroot-setup"

  # Activate the virtual environment
  if -z "${VIRTUAL_ENV}"; then
    enable_venv
  fi

  if [[ ! -e "${grapheneos_pkmd}" || ! -e "${grapheneos_otacert}" ]]; then
    echo "Extracting official keys..."
    extract_official_keys
  fi

  # At present, the script lacks the ability to disable certain modules.
  # Everything is hardcoded to be enabled by default.
  if [[ -e "${ota_zip}.patched.zip" ]]; then
    echo -e "File ${ota_zip}.pathed.zip already exists in local. Patch skipped."
  else
    local args=()

    args+=("--input" "${ota_zip}.zip")
    args+=("--output" "${ota_zip}.patched.zip")

    args+=(--verify-public-key-avb "${grapheneos_pkmd}")
    args+=(--verify-cert-ota "${grapheneos_otacert}")

    args+=(--sign-key-avb "${KEYS[AVB]}")
    args+=(--sign-key-ota "${KEYS[OTA]}")
    args+=(--sign-cert-ota "${KEYS[CERT_OTA]}")

    args+=(--module-custota "${WORKDIR}/modules/custota.zip")
    args+=(--module-msd "${WORKDIR}/modules/msd.zip")
    args+=(--module-bcr "${WORKDIR}/modules/bcr.zip")
    args+=(--module-oemunlockonboot "${WORKDIR}/modules/oemunlockonboot.zip")
    args+=(--module-alterinstaller "${WORKDIR}/modules/alterinstaller.zip")

    python3 ${my_avbroot_setup}/patch.py "${args[@]}"
  fi

  # Deactivate the virtual environment
  deactivate
}

function detect_os() {
  # https://stackoverflow.com/a/68706298

  unameOut=$(uname -a)
  case "${unameOut}" in
    *Microsoft*) OS="WSL" ;;  # must be first since Windows subsystem for linux will have Linux in the name too
    *microsoft*) OS="WSL2" ;; # WARNING: My v2 uses ubuntu 20.4 at the moment slightly different name may not always work
    Linux*) OS="Linux" ;;
    Darwin*) OS="Mac" ;;
    CYGWIN*) OS="Cygwin" ;;
    MINGW*) OS="Windows" ;;
    *Msys) OS="Windows" ;;
    *) OS="UNKNOWN:${unameOut}" ;;
  esac

  echo ${OS}
}

function my_avbroot_setup() {
  local setup_script="${WORKDIR}/my-avbroot-setup/patch.py"
  local magisk_path="${WORKDIR}\/magisk.apk"

  if [[ "${ADDITIONALS[ROOT]}" == 'true' ]]; then
    echo "Magisk is enabled. Modifying the setup script..."
    sed -e "s/\'--rootless\'/\'--magisk\', \'${magisk_path}\',\n\t\t\'--magisk-preinit-device\', \'${MAGISK[PREINIT]}\'/" "${setup_script}" > "${setup_script}.tmp"
    mv "${setup_script}.tmp" "${setup_script}"
  else
    echo "Magisk is not enabled. Skipping..."
  fi
}

function afsr_setup() {
  # This is necessary since the developer chose to not make releases of the tool yet
  local afsr="${WORKDIR}/afsr"

  # By Linux, I mean Ubuntu, a Debian-based distro here
  if [[ $(detect_os) == 'Linux' ]]; then
    if ! dpkg -s e2fsprogs &> /dev/null; then
      echo "e2fsprogs is not installed. Installing..."
      yes | apt-get update
      yes | apt-get install e2fsprogs
    fi
  elif [[ $(detect_os) == 'Mac' ]]; then
    if ! brew list e2fsprogs &> /dev/null; then
      echo "e2fsprogs is not installed. Installing..."
      brew install pkg-config e2fsprogs

      if [[ $(uname -m) == "x86_64" ]]; then
        echo '/usr/local/Cellar/e2fsprogs/1.47.1/lib/pkgconfig' >> ~/.profile
      elif [[ $(uname -m) == "arm64" ]]; then
        echo '/opt/homebrew/Cellar/e2fsprogs/1.47.1/lib/pkgconfig' >> ~/.profile
      fi

      source ~/.profile
    fi
  fi

  cargo build --release --manifest-path "${afsr}/Cargo.toml"
}

function env_setup() {
  my_avbroot_setup
  afsr_setup

  local avbroot="${WORKDIR}/avbroot"
  local afsr="${WORKDIR}/afsr/target/release"
  local custota_tool="${WORKDIR}/custota_tool"
  local my_avbroot_setup="${WORKDIR}/my-avbroot-setup"

  if ! command -v avbroot &> /dev/null && ! command -v afsr &> /dev/null && ! command -v custota-tool &> /dev/null; then
    export PATH="$(realpath ${afsr}):$(realpath ${avbroot}):$(realpath ${custota_tool}):$PATH"
  fi

  enable_venv

  if [[ $(pip list | grep tomlkit &> /dev/null && echo 'true' || echo 'false') == 'false' ]]; then
    echo -e "Python module \`tomlkit\` is required to run this script.\nInstalling..."
    pip3 install tomlkit
  fi
}

function enable_venv() {
  local dir_path='' # Default value is empty string
  local base_path=$(basename "$(pwd)")
  local venv_path=''

  # Check presence of venv
  if [[ "${base_path}" == "my-avbroot-setup" ]]; then
    if [ ! -d "venv" ]; then
      echo -e "Virtual environment not found. Creating..."
      python3 -m venv venv
    fi
  else
    echo -e "The script is not run from the \`my-avbroot-setup\` directory.\nSearching for the directory..."
    dir_path=$(find . -type d -name "my-avbroot-setup" -print -quit)
    if [ ! -d "${dir_path}/venv" ]; then
      echo -e "Virtual environment not found in path ${dir_path}. Creating..."
      python3 -m venv "${dir_path}/venv"
    fi
  fi

  if [ -n "${dir_path}" ]; then
    venv_path="${dir_path}/venv/bin/activate"
  else
    venv_path="venv/bin/activate"
  fi

  # Ensure venv_path is set correctly
  if [ -f "${venv_path}" ]; then
    source "${venv_path}"
  else
    echo -e "Virtual environment activation script not found at ${venv_path}."
  fi
}

function url_constructor() {
  local repository="${1}"
  local automated="${2:-false}"
  local user='chenxiaolong'
  # local arch="x86_64-unknown-linux-gnu" # for Linux
  local arch="universal-apple-darwin" # for macOS
  # local arch="x86_64-pc-windows-msvc" # for Windows

  local repository_upper_case=$(echo "${repository}" | tr '[:lower:]' '[:upper:]')

  echo -e "Constructing URL for \`${repository}\` as \`${repository}\` is non-existent at \`${WORKDIR}\`..."
  if [[ "${repository}" == "afsr" || "${repository}" == "my-avbroot-setup" ]]; then
    URL="${DOMAIN}/${user}/${repository}"
  else
    if [[ "${repository}" == "avbroot" || "${repository}" == "custota-tool" ]]; then
      local suffix="${arch}"
    else
      local suffix="release"
    fi

    URL="${DOMAIN}/${user}/${repository}/releases/download/v${VERSION[${repository_upper_case}]}/${repository}-${VERSION[${repository_upper_case}]}-${suffix}.zip"
    SIGNATURE_URL="${DOMAIN}/${user}/${repository}/releases/download/v${VERSION[${repository_upper_case}]}/${repository}-${VERSION[${repository_upper_case}]}-${suffix}.zip.sig"
  fi

  echo -e "URL for \`${repository}\`: ${URL}"

  if [[ "${automated}" == 'false' ]]; then
    if [[ -e "${WORKDIR}/${repository}" ]]; then
      echo -n "Warning: \`${repository}\` already exists in \`${WORKDIR}\`\nOverwrite? (y/n): "
      read confirm
      if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        rm -rf "${WORKDIR}/${repository}"
      fi
    fi
  fi
  get "${repository}" "${URL}" "${SIGNATURE_URL}"
}

function download_dependencies() {
  local tool="${1}"
  local automated='true'

  if type url_constructor &> /dev/null; then
    url_constructor "${tool}" "${automated}"
  else
    echo "Error: \`url_constructor\` function is not defined."
    exit 1
  fi
}

function extract_official_keys() {
  # https://github.com/chenxiaolong/my-avbroot-setup/issues/1#issuecomment-2270286453
  # AVB: Extract vbmeta.img, run avbroot avb info -i vbmeta.img.
  #   The public_key field is avb_pkmd.bin encoded as hex.
  #   Verify that the key is official by comparing its sha256 checksum with grapheneos.org/articles/attestation-compatibility-guide.
  # OTA: Extract META-INF/com/android/otacert from the OTA.
  #   (Or from otacerts.zip inside system.img or vendor_boot.img. All 3 files are identical.)
  local ota_zip="${WORKDIR}/${GRAPHENEOS[OTA_TARGET]}.zip"

  # Extract OTA
  avbroot ota extract \
    --input "${ota_zip}" \
    --directory extracted/extracts \
    --all

  # Extract vbmeta.img
  # To verify, execute sha256sum avb_pkmd.bin in terminal
  # compare the output with base16-encoded verified boot key fingerprints
  # mentioned at https://grapheneos.org/articles/attestation-compatibility-guide for the respective device
  avbroot avb info -i extracted/extracts/vbmeta.img \
    | grep 'public_key' \
    | sed -n 's/.*public_key: "\(.*\)".*/\1/p' \
    | tr -d '[:space:]' | xxd -r -p > extracted/extracts/avb_pkmd.bin

  # Extract META-INF/com/android/otacert from OTA or otacerts.zip from either vendor_boot.img or system.img
  unzip "${ota_zip}" -d "extracted/ota"
}

function release_ota() {
  local patched_ota="${WORKDIR}/${GRAPHENEOS[OTA_TARGET]}.patched.zip"
  local release_name="${GRAPHENEOS[OTA_TARGET]}-patched.zip"

  if [[ -e "${patched_ota}" ]]; then
    echo "Creating release..."
    mv "${patched_ota}" "${release_name}$(dirty_suffix)"
  else
    echo "Error: Patched OTA not found."
    exit 1
  fi
}

function dirty_suffix() {
  if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
    echo "-dirty"
  else
    echo ""
  fi
}
