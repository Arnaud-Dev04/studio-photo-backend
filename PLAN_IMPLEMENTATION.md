# Application de Gestion de Studio Photo — Plan d'Implémentation Complet

Application complète (Flask + Flutter + Supabase + Cloudinary) pour un photographe freelance au Burundi.
**5 modules**, **7 phases**, interface entièrement en français.

---

## Phase 1 : Fondation Backend Flask — MODULE 1 Locations

### Fichiers de configuration

#### [NEW] requirements.txt
Toutes les dépendances : Flask, SQLAlchemy, psycopg2-binary, cloudinary, PyJWT, APScheduler, Flask-Mail, Flask-CORS, Celery, redis, ReportLab, gunicorn, qrcode, Pillow, python-dotenv.

#### [NEW] Procfile
`web: gunicorn app:app` pour Render.com.

#### [NEW] render.yaml
Configuration Render avec variables d'environnement.

#### [NEW] .env.example
Template des variables d'environnement.

---

### Application Core

#### [NEW] app/__init__.py
Factory pattern : init SQLAlchemy, JWT, CORS, Cloudinary, APScheduler. Enregistre tous les blueprints.

#### [NEW] app/config.py
Config depuis env vars : `DATABASE_URL`, `CLOUDINARY_URL`, `JWT_SECRET_KEY`, `MAIL_*`, `REDIS_URL`.

#### [NEW] schema.sql
Schéma PostgreSQL complet — **toutes les tables** :
- `users` — membres de l'équipe (rôles, hash mot de passe)
- `materials` — catalogue matériel (état, tarifs, photos JSON, QR)
- `rentals` — contrats de location (client, dates, caution, statut)
- `maintenances` — suivi maintenance matériel
- `albums` — albums photo par séance
- `photos` — photos avec URLs Cloudinary (originale + miniature)
- `gallery_tokens` — tokens d'accès galerie client
- `tasks` — tâches assignées aux membres
- `schedules` — planning des séances
- `attendance` — pointage check-in/check-out
- `invoices` — factures
- `payments` — paiements reçus (cash/virement/mobile money)
- `expenses` — dépenses du studio
- `salary_configs` — taux horaires par membre

---

### Modèles SQLAlchemy

#### [NEW] app/models/__init__.py
Exports de tous les modèles.

#### [NEW] app/models/user.py
`User` : id, email, password_hash (bcrypt), nom, role (admin/manager/photographe/assistant/retoucheur/commercial), téléphone, actif, created_at.

#### [NEW] app/models/material.py
`Material` : id, nom, marque, modèle, numéro_série, catégorie (appareil/objectif/éclairage/trépied/drone/studio), état (disponible/loué/maintenance/hors_service), tarif_journalier/hebdo/mensuel, photos (JSON), date_acquisition, qr_code_data. Relations → Rental, Maintenance.

#### [NEW] app/models/rental.py
`Rental` : id, material_id (FK), client_nom/telephone/email, date_debut, date_fin_prevue, date_retour, caution, montant_total, etat_retour, photos_dommages (JSON), statut (active/terminée/en_retard), created_by (FK user).

#### [NEW] app/models/maintenance.py
`Maintenance` : id, material_id (FK), date_debut, date_fin, coût, prestataire, description.

#### [NEW] app/models/album.py
`Album` : id, titre, date_seance, client_nom/email, photographe_id (FK), statut (brouillon/livré/archivé), watermark_config (JSON), created_at.

#### [NEW] app/models/photo.py
`Photo` : id, album_id (FK), url_originale, url_miniature, url_watermark, tags (JSON), favori_client, uploaded_at.

#### [NEW] app/models/gallery_token.py
`GalleryToken` : id, album_id (FK), token (unique), expiration, unlocked (watermark retiré).

#### [NEW] app/models/task.py
`Task` : id, titre, description, assigned_to (FK), type (séance/retouche/vérification), priorité, statut, date_echeance.

#### [NEW] app/models/schedule.py
`Schedule` : id, titre, user_id (FK), date, heure_debut, heure_fin, lieu, type_seance, notes.

#### [NEW] app/models/attendance.py
`Attendance` : id, user_id (FK), date, check_in, check_out, latitude, longitude, total_heures.

#### [NEW] app/models/invoice.py
`Invoice` : id, numero_facture, client_nom/email/telephone, type (location/séance), reference_id, montant_total, montant_payé, statut (non_payé/partiel/payé), date_emission, date_echeance.

#### [NEW] app/models/payment.py
`Payment` : id, invoice_id (FK), montant, date, mode (cash/virement/mobile_money), reference, notes.

#### [NEW] app/models/expense.py
`Expense` : id, description, montant, date, catégorie, created_by (FK).

#### [NEW] app/models/salary_config.py
`SalaryConfig` : id, user_id (FK), taux_horaire, devise.

---

### Utilitaires

#### [NEW] app/utils/cloudinary_helper.py
`upload_image(file, folder)`, `delete_image(public_id)`, `get_thumbnail_url(url)`, `add_watermark_overlay(url, text, position, opacity)`.

#### [NEW] app/utils/qr_generator.py
`generate_qr_code(data)` → retourne PNG bytes via bibliothèque `qrcode`.

#### [NEW] app/utils/jwt_helpers.py
`create_token(user)`, `decode_token(token)`, décorateurs `@jwt_required`, `@role_required(roles)`.

#### [NEW] app/utils/mailer.py
`send_gallery_link(email, album_title, link, expiration)`, `send_invoice_email(email, invoice, pdf_bytes)`.

#### [NEW] app/utils/watermark.py
`apply_watermark(cloudinary_url, text, position, opacity)` — génère URL Cloudinary avec overlay.

#### [NEW] app/utils/pdf_generator.py
`generate_invoice_pdf(invoice)` — ReportLab, retourne bytes PDF.

---

### Blueprint Auth

#### [NEW] app/blueprints/auth/__init__.py
- `POST /auth/register` — inscription (admin only)
- `POST /auth/login` — connexion → retourne JWT avec claim `role`
- `GET /auth/me` — profil de l'utilisateur connecté
- `PATCH /auth/password` — changer mot de passe

---

### Blueprint Rentals (MODULE 1)

#### [NEW] app/blueprints/rentals/__init__.py
- `GET /materials` — liste avec filtres (état, catégorie, recherche)
- `POST /materials` — ajouter un matériel
- `PATCH /materials/<id>` — modifier
- `DELETE /materials/<id>` — supprimer
- `POST /materials/<id>/photo` — upload photo → Cloudinary
- `GET /materials/<id>/qrcode` — générer QR code PNG
- `POST /rentals` — créer contrat de location
- `GET /rentals` — liste locations (filtres : actives/retard/terminées)
- `GET /rentals/<id>` — détail location
- `PATCH /rentals/<id>/return` — enregistrer retour + état + photos dommages
- `GET /rentals/overdue` — locations en retard
- `POST /maintenances` — ajouter maintenance
- `GET /maintenances` — liste maintenances
- `GET /ping` — anti-veille Render

#### [NEW] app/scheduler.py
APScheduler : chaque matin 8h, vérifie locations en retard → envoie notification FCM.

---

## Phase 2 : Frontend Flutter — MODULE 1 Locations

### Core

#### [NEW] pubspec.yaml
Dépendances : `http`, `flutter_riverpod`, `go_router`, `image_picker`, `mobile_scanner`, `qr_flutter`, `cached_network_image`, `flutter_secure_storage`, `intl`, `google_fonts`, `flutter_staggered_grid_view`, `photo_manager`, `flutter_image_compress`, `hive`, `firebase_messaging`, `fl_chart`.

#### [NEW] lib/main.dart
Point d'entrée : ProviderScope, MaterialApp.router, thème sombre, locale fr.

#### [NEW] lib/core/config/app_config.dart
`API_URL` depuis `--dart-define`.

#### [NEW] lib/core/theme/app_theme.dart
Material 3, thème sombre premium studio, Google Fonts (Inter/Outfit), gradients, couleurs harmonieuses.

#### [NEW] lib/core/router/app_router.dart
GoRouter : toutes les routes, guards par rôle, redirection login.

#### [NEW] lib/core/services/api_service.dart
Client HTTP : headers JWT, gestion erreurs, retry.

#### [NEW] lib/core/services/auth_service.dart
Login, logout, stockage token sécurisé, état utilisateur.

#### [NEW] lib/core/services/notification_service.dart
Firebase Cloud Messaging : init, permission, token device, écoute notifications.

---

### Feature Auth

#### [NEW] lib/features/auth/screens/login_screen.dart
Écran login premium : animations, gestion états (chargement/erreur/succès), design sombre studio.

---

### Feature Rentals

#### [NEW] lib/features/rentals/models/material_model.dart
Classe `MaterialItem` avec `fromJson`/`toJson`.

#### [NEW] lib/features/rentals/models/rental_model.dart
Classe `Rental` avec `fromJson`/`toJson`.

#### [NEW] lib/features/rentals/providers/rentals_provider.dart
Riverpod providers : listes matériels/locations, CRUD, filtres.

#### [NEW] lib/features/rentals/screens/dashboard_screen.dart
Dashboard : compteurs animés (disponible, loué, maintenance, retard), accès rapides.

#### [NEW] lib/features/rentals/screens/materials_list_screen.dart
Catalogue : cards matériel, filtres (état/catégorie), indicateurs colorés (vert/rouge/orange/gris), recherche, pull-to-refresh.

#### [NEW] lib/features/rentals/screens/material_detail_screen.dart
Fiche matériel : carrousel photos, infos, QR, historique locations, boutons action.

#### [NEW] lib/features/rentals/screens/material_form_screen.dart
Formulaire ajout/édition avec upload photo (image_picker).

#### [NEW] lib/features/rentals/screens/rental_form_screen.dart
Création contrat : sélection matériel, infos client, dates, calcul tarif auto.

#### [NEW] lib/features/rentals/screens/rental_return_screen.dart
Retour : inspection, état matériel, photos dommages, déduction caution.

#### [NEW] lib/features/rentals/screens/qr_scanner_screen.dart
Scanner QR (mobile_scanner) → navigation fiche matériel.

---

## Phase 3 : MODULE 2 — Galerie Photo + Livraison Client

### Backend — Blueprint Gallery

#### [NEW] app/blueprints/gallery/__init__.py
- `POST /albums` — créer un album
- `GET /albums` — liste des albums (filtres : statut, date, photographe)
- `GET /albums/<id>` — détail album
- `PATCH /albums/<id>` — modifier album
- `DELETE /albums/<id>` — supprimer album
- `POST /photos/upload/chunk` — upload chunked (morceaux de 5 Mo)
- `POST /photos/upload/complete` — finalisation upload
- `DELETE /photos/<id>` — supprimer une photo
- `PATCH /photos/<id>/favorite` — marquer photo favorite (client)
- `GET /gallery/<token>` — accès galerie publique (sans auth)
- `POST /albums/<id>/send` — envoyer lien email (Flask-Mail) + générer token
- `POST /albums/<id>/zip` — générer ZIP asynchrone (Celery + Redis)
- `PATCH /albums/<id>/unlock` — retirer watermark après paiement

#### [NEW] app/celery_tasks/zip_task.py
Tâche Celery : télécharge photos depuis Cloudinary → crée ZIP → upload ZIP → retourne URL.

---

### Frontend — Feature Gallery

#### [NEW] lib/features/gallery/models/album_model.dart + photo_model.dart
Classes `Album`, `Photo` avec sérialisation JSON.

#### [NEW] lib/features/gallery/providers/gallery_provider.dart
Providers Riverpod : albums, photos, upload, envoi client.

#### [NEW] lib/core/services/upload_service.dart
Upload massif : sélection 500+ photos (photo_manager), compression (flutter_image_compress), chunked upload, 3-5 uploads parallèles, reprise auto, barre progression.

#### [NEW] lib/features/gallery/screens/albums_list_screen.dart
Liste albums avec filtres (statut, date, photographe), indicateurs colorés.

#### [NEW] lib/features/gallery/screens/album_detail_screen.dart
Galerie masonry (flutter_staggered_grid_view) + lazy loading 50 par 50 + sélection multiple + bouton "Envoyer au client".

#### [NEW] lib/features/gallery/screens/upload_screen.dart
Upload massif : sélection, compression, progress bar "347/512 photos uploadées", reprise auto.

#### [NEW] lib/features/gallery/screens/photo_viewer_screen.dart
Visionneuse plein écran : swipe, zoom, infos photo.

#### [NEW] lib/features/gallery/screens/public_gallery_screen.dart
Galerie publique client (accès via token, sans login) : photos avec/sans watermark, téléchargement, favoris.

---

## Phase 4 : MODULE 3 — Gestion Équipe

### Backend — Blueprints Tasks, Attendance, Schedules

#### [NEW] app/blueprints/tasks/__init__.py
- `POST /tasks` — créer tâche
- `GET /tasks` — liste (filtres : assigné, statut, type)
- `PATCH /tasks/<id>` — modifier/compléter tâche
- `DELETE /tasks/<id>` — supprimer

#### [NEW] app/blueprints/attendance/__init__.py
- `POST /attendance/checkin` — pointer arrivée (+ géolocalisation optionnelle)
- `POST /attendance/checkout` — pointer départ
- `GET /attendance` — historique (filtres : user, période)
- `GET /attendance/report` — rapport d'activité par membre (semaine/mois)

#### [NEW] app/blueprints/schedules/__init__.py
- `POST /schedules` — créer séance/mission
- `GET /schedules` — planning (filtres : user, semaine)
- `PATCH /schedules/<id>` — modifier
- `DELETE /schedules/<id>` — supprimer

---

### Frontend — Feature Tasks

#### [NEW] lib/features/tasks/models/
`TaskModel`, `ScheduleModel`, `AttendanceModel` avec sérialisation JSON.

#### [NEW] lib/features/tasks/providers/tasks_provider.dart
Providers : tâches, planning, pointage.

#### [NEW] lib/features/tasks/screens/tasks_list_screen.dart
Tâches du jour : liste avec statuts, filtre par type, marquer comme complétée.

#### [NEW] lib/features/tasks/screens/calendar_screen.dart
Calendrier semaine avec séances planifiées, vue jour/semaine.

#### [NEW] lib/features/tasks/screens/attendance_screen.dart
Pointage : bouton check-in/check-out en un tap, historique, géolocalisation optionnelle.

#### [NEW] lib/features/tasks/screens/activity_report_screen.dart
Rapports d'activité par membre : heures travaillées, tâches complétées, semaine/mois.

> Cache offline avec Hive pour tâches et planning.

---

## Phase 5 : MODULE 4 — Finance & Facturation

### Backend — Blueprint Finance

#### [NEW] app/blueprints/finance/__init__.py
- `POST /invoices` — créer facture (auto depuis location ou séance)
- `GET /invoices` — liste factures (filtres : statut, client, période)
- `GET /invoices/<id>` — détail facture
- `GET /invoices/<id>/pdf` — générer PDF (ReportLab)
- `POST /payments` — enregistrer paiement reçu (cash/virement/mobile money)
- `GET /payments` — historique paiements
- `POST /expenses` — enregistrer dépense
- `GET /expenses` — liste dépenses (filtres : catégorie, période)
- `GET /finance/dashboard` — CA du mois, factures en attente, bénéfices
- `GET /finance/salaries` — calcul salaires (heures × taux)
- `PATCH /invoices/<id>/confirm-payment` — confirmer paiement → déclenche retrait watermark

---

### Frontend — Feature Finance

#### [NEW] lib/features/finance/models/
`InvoiceModel`, `PaymentModel`, `ExpenseModel` avec sérialisation.

#### [NEW] lib/features/finance/providers/finance_provider.dart
Providers : factures, paiements, dépenses, dashboard.

#### [NEW] lib/features/finance/screens/finance_dashboard_screen.dart
Dashboard finance : CA mois (graphique fl_chart), factures en attente, bénéfices, compteurs.

#### [NEW] lib/features/finance/screens/invoices_list_screen.dart
Liste factures avec statuts colorés (rouge=non payé, orange=partiel, vert=payé).

#### [NEW] lib/features/finance/screens/invoice_detail_screen.dart
Détail facture : montants, paiements reçus, bouton générer PDF, bouton confirmer paiement.

#### [NEW] lib/features/finance/screens/payment_form_screen.dart
Formulaire paiement : montant, date, mode (cash/virement/mobile money), référence.

#### [NEW] lib/features/finance/screens/expenses_screen.dart
Liste dépenses + formulaire ajout.

#### [NEW] lib/features/finance/screens/salary_screen.dart
Calcul salaires : heures travaillées × taux configuré, par membre, par période.

---

## Phase 6 : MODULE 5 — Permissions & Rôles

### Backend

#### [MODIFY] app/utils/jwt_helpers.py
Renforcer le décorateur `@role_required` : vérifier JWT claim `role` sur chaque endpoint protégé.

#### [MODIFY] Tous les blueprints
Appliquer les restrictions :
- **Admin** : accès total
- **Manager** : locations, albums, tâches, finances (lecture seule)
- **Photographe** : upload photos, ses tâches, son pointage, scanner QR
- **Client** : galerie publique uniquement (token, pas de JWT)

---

### Frontend

#### [MODIFY] lib/core/router/app_router.dart
GoRouter guards : redirection selon rôle, masquer menus non autorisés.

#### [NEW] lib/features/profile/screens/members_management_screen.dart
Gestion membres (admin only) : liste, ajout, modification rôle, désactivation.

#### [NEW] lib/features/profile/screens/profile_screen.dart
Profil utilisateur : infos, changement mot de passe.

---

## Phase 7 : Déploiement

### Backend → Render.com
- Push sur GitHub → deploy auto Render
- Variables d'environnement : `DATABASE_URL`, `CLOUDINARY_URL`, `JWT_SECRET_KEY`, `MAIL_*`, `REDIS_URL`, `FIREBASE_KEY`
- Endpoint anti-veille : `GET /ping` → `{"status": "ok"}`
- UptimeRobot : ping `/ping` toutes les 5 minutes

### Base de données → Supabase
- PostgreSQL gratuit (500 MB)
- Exécuter `schema.sql` via SQL Editor Supabase
- `DATABASE_URL` dans Render

### Stockage → Cloudinary
- 25 GB gratuit, CDN intégré
- Thumbnails auto via transformations URL
- Watermark via overlay

### Frontend Web → Vercel
```bash
flutter build web --release --dart-define=API_URL=https://mon-studio.onrender.com
```
- Deploy `build/web` sur Vercel

### Redis → Redis Cloud
- 30 MB gratuit, pour Celery (tâches async ZIP)

### Mobile → iOS/Android
```bash
flutter build apk --release --dart-define=API_URL=https://mon-studio.onrender.com
flutter build ios --release --dart-define=API_URL=https://mon-studio.onrender.com
```

---

## Ordre d'exécution

| Étape | Phase | Contenu | Statut |
|-------|-------|---------|--------|
| 1 | Phase 1 | Backend Flask : config + schéma SQL + modèles + utils + blueprints auth & rentals | ⬜ À faire |
| 2 | Phase 2 | Frontend Flutter : core + auth + feature rentals complète | ⬜ À faire |
| 3 | Phase 3 | Backend gallery + Frontend galerie + upload massif | ⬜ À faire |
| 4 | Phase 4 | Backend tasks/attendance/schedules + Frontend tâches/planning | ⬜ À faire |
| 5 | Phase 5 | Backend finance + Frontend facturation | ⬜ À faire |
| 6 | Phase 6 | Permissions & rôles (backend + frontend) | ⬜ À faire |
| 7 | Phase 7 | Déploiement Render + Vercel + Supabase + builds mobile | ⬜ À faire |

---

## Verification Plan

### Par phase
- **Backend** : lancer Flask localement, tester chaque endpoint avec curl/Postman
- **Frontend** : `flutter analyze` puis `flutter run -d chrome`, vérifier chaque écran
- **Intégration** : connecter Flutter au backend local, tester flux complets

### Tests automatisés
```bash
# Backend
cd backend && python -m pytest tests/ -v

# Frontend
cd frontend && flutter test
```

### Validation finale
- Build web production + déploiement Vercel
- Build APK Android
- Test end-to-end : login → catalogue → location → retour → facture
