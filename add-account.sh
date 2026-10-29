#!/bin/bash
# Add a new Claude account to the curation fleet, from any computer:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/valteu/claude-inbox/main/add-account.sh)
#
# Needs only Claude Code (`claude`), openssl and curl: no GitHub account, no
# cluster access. You sign in with the new Claude account; its token is
# encrypted with the cluster's public key (only the cluster can read it) and
# posted through ntfy.sh, a public message relay. The cluster picks it up within
# about 10 minutes, adds the account with 4 workers, and the answer appears here.
# Use a Claude account that is not already in the fleet.
set -euo pipefail
SRC=https://raw.githubusercontent.com/valteu/claude-inbox/main
INBOX=ba-claude-inbox-9dd2c905f6b9616f15d5
for c in claude openssl curl; do command -v "$c" >/dev/null || { echo "needs $c"; exit 1; }; done
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$SRC/cluster.pub.pem" -o "$TMP/cluster.pub.pem"

echo "A browser window opens: sign in with a NEW Claude account, one not already in the fleet."
claude setup-token
echo
read -rsp "Paste the token printed above, then press Enter: " TOKEN; echo
[[ -n "$TOKEN" ]] || { echo "no token given"; exit 1; }

# The cluster answers on a topic only this run knows (it travels encrypted).
REPLY_TOPIC="ba-reply-$(openssl rand -hex 12)"
printf 'token=%s\nreply=%s\n' "$TOKEN" "$REPLY_TOPIC" \
    | openssl pkeyutl -encrypt -pubin -inkey "$TMP/cluster.pub.pem" -pkeyopt rsa_padding_mode:oaep \
    | openssl base64 -A > "$TMP/req"
unset TOKEN
curl -fsS -o /dev/null --data-binary @"$TMP/req" "https://ntfy.sh/$INBOX"
echo "Sent. Waiting for the cluster (usually under 10 minutes; Ctrl-C is safe, the request stays queued)..."

for i in $(seq 1 90); do
    answer=$(curl -fsS "https://ntfy.sh/$REPLY_TOPIC/raw?poll=1&since=all" 2>/dev/null || true)
    if [[ -n "$answer" ]]; then echo "$answer"; exit 0; fi
    sleep 20
done
echo "No answer after 30 minutes. The request stays queued for 12 hours; if it never arrives, try again later."
