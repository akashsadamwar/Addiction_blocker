# Fix GitHub connection (Gj4 project)

Your Git remote is: `https://github.com/akashsadamwar/gj_blocker.git`

Follow these steps in order.

---

## Step 1: Create the repo on GitHub (if you haven’t)

1. Open: **https://github.com/new**
2. **Repository name:** `gj_blocker` (exactly)
3. **Public**
4. Do **not** check "Add a README"
5. Click **Create repository**

---

## Step 2: Create a Personal Access Token (for password)

GitHub no longer accepts your account password for Git. Use a token instead.

1. Open: **https://github.com/settings/tokens**
2. Click **Generate new token** → **Generate new token (classic)**
3. **Note:** e.g. `Cursor Gj4`
4. **Expiration:** 90 days or No expiration
5. Check **repo** (full control)
6. Click **Generate token**
7. **Copy the token** (starts with `ghp_...`) and save it somewhere safe. You won’t see it again.

---

## Step 3: Push from terminal using the token

Open **PowerShell** or **Terminal** in Cursor and run:

```powershell
cd "c:\Users\akash\OneDrive\Documents\Jeremy\Gj4"
git push -u origin main
```

When it asks:

- **Username:** `akashsadamwar`
- **Password:** paste your **token** (the `ghp_...` one), not your GitHub password

Windows may save these credentials so you don’t have to enter them every time.

---

## Step 4: If it still says "repository not found"

- Confirm the repo exists: open **https://github.com/akashsadamwar/gj_blocker** in a browser (logged in as akashsadamwar). If you get 404, create the repo as in Step 1.
- Confirm the remote URL:

```powershell
git remote -v
```

You should see:

```
origin  https://github.com/akashsadamwar/gj_blocker.git (fetch)
origin  https://github.com/akashsadamwar/gj_blocker.git (push)
```

If the URL is wrong:

```powershell
git remote set-url origin https://github.com/akashsadamwar/gj_blocker.git
git push -u origin main
```

---

## Step 5: Optional – sign in to GitHub in Cursor

1. In Cursor press **Ctrl+Shift+P**
2. Run: **GitHub: Sign in**
3. Complete login in the browser

After that, Source Control (Ctrl+Shift+G) may use this login for push/pull.

---

## Quick checklist

- [ ] Repo `gj_blocker` exists at https://github.com/akashsadamwar/gj_blocker
- [ ] You created a Personal Access Token with **repo** scope
- [ ] When pushing, you used the **token** as the password, not your GitHub password
- [ ] Username is exactly `akashsadamwar`
