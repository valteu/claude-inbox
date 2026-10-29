#!/bin/bash
# Add a new Claude account to the curation fleet, from any computer and any GitHub account.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/valteu/claude-inbox/main/add-account.sh)
#
# Needs: Claude Code (`claude`), openssl, and the GitHub CLI (`gh`, logged in
# with `gh auth login`). The token is encrypted with the cluster's public key:
# only the cluster can read it. With push access to valteu/claude-inbox the
# request goes in directly; otherwise through a fork and a pull request, which
# the cluster reads and closes (never merges).
set -euo pipefail
UPSTREAM=valteu/claude-inbox
for c in claude openssl gh; do command -v "$c" >/dev/null || { echo "needs $c"; exit 1; }; done
gh auth status >/dev/null 2>&1 || { echo "log in to GitHub first: gh auth login"; exit 1; }
ME=$(gh api user --jq .login)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
curl -fsSL "https://raw.githubusercontent.com/$UPSTREAM/main/cluster.pub.pem" -o "$TMP/cluster.pub.pem"

echo "A browser window opens: sign in with a NEW Claude account, one not already in the fleet."
claude setup-token
echo
read -rsp "Paste the token printed above, then press Enter: " TOKEN; echo
[[ -n "$TOKEN" ]] || { echo "no token given"; exit 1; }
printf 'token=%s\n' "$TOKEN" \
    | openssl pkeyutl -encrypt -pubin -inkey "$TMP/cluster.pub.pem" -pkeyopt rsa_padding_mode:oaep \
    | openssl base64 -A > "$TMP/req"
unset TOKEN
NAME="$(date -u +%Y%m%dT%H%M%SZ)-$RANDOM"
CONTENT=$(openssl base64 -A < "$TMP/req")

if [[ "$(gh api "repos/$UPSTREAM" --jq .permissions.push 2>/dev/null)" == true ]]; then
    gh api -X PUT "repos/$UPSTREAM/contents/inbox/$NAME.enc" \
        -f message="account request" -f content="$CONTENT" >/dev/null
    echo "Sent. Within about 10 minutes the result appears at"
    echo "  https://github.com/$UPSTREAM/blob/main/results/$NAME.txt"
else
    gh repo fork "$UPSTREAM" --clone=false >/dev/null 2>&1 || true
    for i in $(seq 1 30); do gh api "repos/$ME/claude-inbox" >/dev/null 2>&1 && break; sleep 2; done
    SHA=$(gh api "repos/$ME/claude-inbox/git/ref/heads/main" --jq .object.sha)
    BRANCH="account-$NAME"
    gh api "repos/$ME/claude-inbox/git/refs" -f ref="refs/heads/$BRANCH" -f sha="$SHA" >/dev/null
    gh api -X PUT "repos/$ME/claude-inbox/contents/inbox/$NAME.enc" \
        -f message="account request" -f content="$CONTENT" -f branch="$BRANCH" >/dev/null
    URL=$(gh pr create --repo "$UPSTREAM" --head "$ME:$BRANCH" --title "account request" \
        --body "Encrypted account request. The cluster processes it and closes this pull request.")
    echo "Sent as $URL"
    echo "Within about 10 minutes the cluster comments the result there and closes it."
fi
