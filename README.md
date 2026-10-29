This is how to contribute a claude plan for data construction:
1. Open a browser and sign into a claude account with a max subscription
2. Run this command:
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/valteu/claude-inbox/main/add-account.sh)
```
3. Click authenticate and paste the key printed in orange in the terminal. The account will be used within 10 minutes of sharing

If the command failed, please check if `openssl`, and `claude-code` are installed (not necessarily authenticated)

The answer (`ok: added as account N with 4 workers`) appears in the terminal within about 10 minutes. No need to await it.

The token is always encrypted with `cluster.pub.pem`.
