# Privacy Policy URL (for Google Play Console)

## Your PWA server (burhaniguardspune.baawan.com)

**Privacy Policy URL:** **http://burhaniguardspune.baawan.com/privacy**

1. Deploy your PWA as usual (`flutter build web`, then upload the contents of `build/web` to your server).
2. Add a server rewrite so `/privacy` serves `privacy.html`. See the **`server-privacy-rewrite`** folder for ready-to-use configs:
   - **IIS:** copy `server-privacy-rewrite/web.config` to your site root (or merge the rule into your existing web.config).
   - **Apache:** use `server-privacy-rewrite/.htaccess` (or add the rule to your existing .htaccess).
   - **Nginx:** add the rules from `server-privacy-rewrite/nginx-privacy.conf` to your server block.

Without the rewrite, visiting `/privacy` will return 404. Details are in `server-privacy-rewrite/README.md`.

---

## Firebase Hosting (optional)

If you also deploy to Firebase:

1. Run: `flutter build web`
2. Run: `firebase deploy`

Privacy Policy URL: **https://bgp-app-f0020.web.app/privacy**

---

Paste your chosen URL in: **Google Play Console → Policy and programs → App content → Privacy Policy → Privacy policy URL**.
