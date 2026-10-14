# Patient Portal — mobile app

Standalone Flutter app for the Patient Portal. It talks to the same Laravel API as the website.

Layout on disk:

- Website / API: `/Users/zeeshanahmad/Downloads/patientportal`
- This app: `/Users/zeeshanahmad/Downloads/MOBILE APP`

## Run

From this folder:

```bash
flutter pub get
flutter run
```

On sign-in, open **Clinic / API** and set:

- Portal address: laptop LAN IP plus port, for example `http://192.168.1.20:8010` (not `127.0.0.1` on a physical phone)
- Clinic slug: `riverside` for the demo

Serve the Laravel API so the phone can reach it:

```bash
cd /Users/zeeshanahmad/Downloads/patientportal
php artisan serve --host=0.0.0.0 --port=8010
```

Demo staff: `staff@riverside.example` / `password`.

## Screens

Home, visits, messages, records, care, billing, privacy, intake, and a home vitals reading form. Same email and password as the website.
