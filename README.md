# claude-inbox

Adds a new Claude account to the curation fleet, from any computer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valteu/claude-inbox/main/add-account.sh)
```

Needs only Claude Code (`claude`), `openssl` and `curl`: no GitHub account, no cluster access. Sign in with the new Claude account when the browser opens and paste the token it prints; the answer (`ok: added as account N with 4 workers`) appears in the terminal within about 10 minutes.

The token is encrypted with `cluster.pub.pem` and posted through [ntfy.sh](https://ntfy.sh), a public message relay; only the cluster holds the key that decrypts it. Requests can only add new accounts. Use a Claude account that is not already in the fleet: the cluster cannot tell from a token which account it belongs to.
