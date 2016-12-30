function debug() {
if [ "$DEBUG" == "true" ]; then
    DEBUG=${DEBUG:-"false"}
    echo "[DEBUG] $1"
fi
}
export -f debug

function warn() {
echo "[WARN] $1"
}
export -f warn

function info() {
echo "[INFO] $1"
}
export -f info
