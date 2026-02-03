# Privacy Policy URL on Your Server

**Target URL:** **http://burhaniguardspune.baawan.com/privacy**

Your PWA is hosted at `burhaniguardspune.baawan.com`. To make `/privacy` work (and stop the 404), do both steps below.

---

## 1. Deploy `privacy.html` with your PWA

When you run `flutter build web`, the file **`build/web/privacy.html`** is created.  
Upload the **entire** `build/web` folder to your server (same place as your PWA). That way `privacy.html` is in the same directory as `index.html`.

---

## 2. Add a URL rewrite so `/privacy` serves `privacy.html`

The server must serve `privacy.html` when someone opens **/privacy** (without `.html`). Use the config that matches your server.

### IIS (Windows Server) — "404 - File or directory not found" usually means IIS

- Copy **`web.config`** from this folder into your **site root** (the same folder where `index.html` and `privacy.html` are on the server).
- If you already have a `web.config`, open it and add the **&lt;rule&gt;** block named "Privacy Policy" inside **&lt;rules&gt;** (before any catch‑all rule).
- Ensure **URL Rewrite** is installed (IIS → Server → URL Rewrite). If not, install the [IIS URL Rewrite module](https://www.iis.net/downloads/microsoft/url-rewrite).

### Apache

- Copy **`.htaccess`** from this folder into your **site root**, or add the `RewriteRule ^privacy/?$ privacy.html [L]` line to your existing `.htaccess`.
- Ensure `mod_rewrite` is enabled.

### Nginx

- Add the rules from **`nginx-privacy.conf`** into your server block for `burhaniguardspune.baawan.com`, then reload nginx.

---

After this, **http://burhaniguardspune.baawan.com/privacy** should open the privacy policy page. Use this URL in the Google Play Console as your app’s Privacy Policy URL if needed.
