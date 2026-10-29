# claude-inbox

Adds a new Claude account to the curation fleet, from any computer and any GitHub account.

```bash
curl -fsSL https://raw.githubusercontent.com/valteu/claude-inbox/main/add-account.sh -o add-account.sh
bash add-account.sh
```

Needs Claude Code (`claude`), `openssl`, and the GitHub CLI logged in (`gh auth login`). The script asks you to sign in with the new Claude account, encrypts its token with `cluster.pub.pem`, and sends it:

- with push access to this repo: as a file in `inbox/`; the result appears in `results/`;
- otherwise: through a fork and a pull request; the cluster comments the result and closes the pull request. Pull requests are never merged.

Only GitHub accounts listed in `allowed-users.txt` are processed (`*` accepts anyone). Requests can only add new accounts, never change existing ones.

Only the cluster holds the key that decrypts a request.
