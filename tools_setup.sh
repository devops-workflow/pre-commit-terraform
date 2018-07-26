
# Install/upgrade all tools scripts depend on

# terraform, tflint, terraform-docs, dot?,

# if mac, brew (what can {create rules for what doesn't exist?})
brew install terraform terraform-docs graphviz
brew tap wata727/tflint
brew install tflint
#terraform_landscape tfenv

apk update
apk add jq wget
# Get latest version of tflint (v0.7.0 test if still need to exclude modules. Any other changes)
pkg_arch=linux_amd64
dl_url=$(curl -s https://api.github.com/repos/wata727/tflint/releases/latest | jq -r ".assets[] | select(.name | test(\"${pkg_arch}\")) | .browser_download_url")
wget ${dl_url}
unzip tflint_linux_amd64.zip
mkdir -p /usr/local/tflint/bin
# Setup PATH for later run steps - ONLY for Bash and not in Bash
#echo 'export PATH=/usr/local/tflint/bin:$PATH' >> $BASH_ENV
echo "Installing tflint..."
install tflint /usr/local/tflint/bin
