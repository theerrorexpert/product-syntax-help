#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
[[ "${TRACE:-}" ]] && set -x
readonly TMP_DIR="${TMP_DIR:-/tmp}"
readonly EXTRA_COMMANDS_FILE="${EXTRA_COMMANDS_FILE:-extra-commands.cnf}"

usage() {
  echo "USAGE: $0 <product> <command> (Was given the arguments '$@')"
  exit 1
}

[ $# -lt 2 ] && usage "$@"
PRODUCT="$1"
shift
ARGS="$@"

# Verify product is in path
type ${PRODUCT} >/dev/null 2>&1 || (echo "ERROR: ${PRODUCT} not found in path" && exit 1)

TMP_FILE="${TMP_DIR}/${PRODUCT}.tmp.$$"
${PRODUCT} ${ARGS} > ${TMP_FILE}  2>/dev/null || (echo "ERROR: '${PRODUCT} ${ARGS}' is an invalid command" && exit 1)
[ ! -s "${TMP_FILE}" ] && echo "ERROR: '${PRODUCT} ${ARGS}' produced no output" && exit 1


# Varying project cleanup
# - Remove Blank Lines
# - Remove --version 
# - Remove ==> headers (brew)
sed -e "/^$/d;/--version/d;/==>/d;" ${TMP_FILE} > ${EXTRA_COMMANDS_FILE}
rm -f ${TMP_FILE}

echo "Generated '${EXTRA_COMMANDS_FILE}' with '$(cat ${EXTRA_COMMANDS_FILE} | wc -l | tr -d ' ')' entries"

CMD="generate-extra-syntax-help.sh"
type ${CMD} >/dev/null 2>&1 || (echo "ERROR: ${CMD} not found in path" && exit 1)

while read LINE; do
echo "Running ${LINE}"
  ${CMD} ${PRODUCT} ${LINE}
done < <(cat ${EXTRA_COMMANDS_FILE})

exit 0