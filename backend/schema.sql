-- ============================================================
-- SCHÉMA POSTGRESQL COMPLET — Studio Photo Management
-- À exécuter dans Supabase SQL Editor
-- ============================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE : users (membres de l'équipe)
-- ============================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nom VARCHAR(255) NOT NULL,
    telephone VARCHAR(50),
    role VARCHAR(50) NOT NULL DEFAULT 'photographe'
        CHECK (role IN ('admin', 'manager', 'photographe', 'assistant', 'retoucheur', 'commercial')),
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    fcm_token VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : materials (catalogue matériel photo)
-- ============================================================
CREATE TABLE materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(255) NOT NULL,
    marque VARCHAR(255),
    modele VARCHAR(255),
    numero_serie VARCHAR(255) UNIQUE,
    categorie VARCHAR(100) NOT NULL DEFAULT 'appareil'
        CHECK (categorie IN ('appareil', 'objectif', 'eclairage', 'trepied', 'drone', 'studio', 'accessoire', 'autre')),
    etat VARCHAR(50) NOT NULL DEFAULT 'disponible'
        CHECK (etat IN ('disponible', 'loue', 'maintenance', 'hors_service')),
    tarif_journalier NUMERIC(12, 2) DEFAULT 0,
    tarif_hebdomadaire NUMERIC(12, 2) DEFAULT 0,
    tarif_mensuel NUMERIC(12, 2) DEFAULT 0,
    photos JSONB DEFAULT '[]'::jsonb,
    date_acquisition DATE,
    qr_code_data VARCHAR(500),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : rentals (contrats de location)
-- ============================================================
CREATE TABLE rentals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    client_nom VARCHAR(255) NOT NULL,
    client_telephone VARCHAR(50),
    client_email VARCHAR(255),
    date_debut DATE NOT NULL,
    date_fin_prevue DATE NOT NULL,
    date_retour DATE,
    caution NUMERIC(12, 2) DEFAULT 0,
    montant_total NUMERIC(12, 2) NOT NULL,
    etat_retour VARCHAR(100),
    photos_dommages JSONB DEFAULT '[]'::jsonb,
    statut VARCHAR(50) NOT NULL DEFAULT 'active'
        CHECK (statut IN ('active', 'terminee', 'en_retard')),
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : maintenances (suivi maintenance matériel)
-- ============================================================
CREATE TABLE maintenances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    date_debut DATE NOT NULL,
    date_fin DATE,
    cout NUMERIC(12, 2) DEFAULT 0,
    prestataire VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : albums (albums photo par séance)
-- ============================================================
CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titre VARCHAR(255) NOT NULL,
    date_seance DATE,
    client_nom VARCHAR(255),
    client_email VARCHAR(255),
    photographe_id UUID REFERENCES users(id),
    statut VARCHAR(50) NOT NULL DEFAULT 'brouillon'
        CHECK (statut IN ('brouillon', 'livre', 'archive')),
    watermark_text VARCHAR(255) DEFAULT 'Studio Photo',
    watermark_position VARCHAR(50) DEFAULT 'center',
    watermark_opacity NUMERIC(3, 2) DEFAULT 0.5,
    nombre_photos INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : photos
-- ============================================================
CREATE TABLE photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    album_id UUID NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    url_originale VARCHAR(500) NOT NULL,
    url_miniature VARCHAR(500),
    url_watermark VARCHAR(500),
    public_id VARCHAR(255),
    filename VARCHAR(255),
    tags JSONB DEFAULT '[]'::jsonb,
    favori_client BOOLEAN DEFAULT FALSE,
    taille_bytes BIGINT DEFAULT 0,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : gallery_tokens (accès galerie client sans compte)
-- ============================================================
CREATE TABLE gallery_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    album_id UUID NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expiration TIMESTAMP WITH TIME ZONE,
    unlocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : tasks (tâches assignées aux membres)
-- ============================================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titre VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES users(id),
    type_tache VARCHAR(50) NOT NULL DEFAULT 'seance'
        CHECK (type_tache IN ('seance', 'retouche', 'verification', 'livraison', 'autre')),
    priorite VARCHAR(20) NOT NULL DEFAULT 'normale'
        CHECK (priorite IN ('basse', 'normale', 'haute', 'urgente')),
    statut VARCHAR(50) NOT NULL DEFAULT 'a_faire'
        CHECK (statut IN ('a_faire', 'en_cours', 'terminee', 'annulee')),
    date_echeance DATE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : schedules (planning des séances)
-- ============================================================
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titre VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES users(id),
    date_seance DATE NOT NULL,
    heure_debut TIME,
    heure_fin TIME,
    lieu VARCHAR(255),
    type_seance VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : attendance (pointage check-in / check-out)
-- ============================================================
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    date_pointage DATE NOT NULL DEFAULT CURRENT_DATE,
    check_in TIMESTAMP WITH TIME ZONE,
    check_out TIMESTAMP WITH TIME ZONE,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    total_heures NUMERIC(5, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : invoices (factures)
-- ============================================================
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_facture VARCHAR(50) UNIQUE NOT NULL,
    client_nom VARCHAR(255) NOT NULL,
    client_email VARCHAR(255),
    client_telephone VARCHAR(50),
    type_facture VARCHAR(50) NOT NULL DEFAULT 'location'
        CHECK (type_facture IN ('location', 'seance', 'autre')),
    reference_id UUID,
    montant_total NUMERIC(12, 2) NOT NULL,
    montant_paye NUMERIC(12, 2) DEFAULT 0,
    statut VARCHAR(50) NOT NULL DEFAULT 'non_paye'
        CHECK (statut IN ('non_paye', 'partiel', 'paye')),
    date_emission DATE NOT NULL DEFAULT CURRENT_DATE,
    date_echeance DATE,
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : payments (paiements reçus)
-- ============================================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    montant NUMERIC(12, 2) NOT NULL,
    date_paiement DATE NOT NULL DEFAULT CURRENT_DATE,
    mode VARCHAR(50) NOT NULL DEFAULT 'cash'
        CHECK (mode IN ('cash', 'virement', 'mobile_money')),
    reference VARCHAR(255),
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : expenses (dépenses du studio)
-- ============================================================
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    description VARCHAR(500) NOT NULL,
    montant NUMERIC(12, 2) NOT NULL,
    date_depense DATE NOT NULL DEFAULT CURRENT_DATE,
    categorie VARCHAR(100) DEFAULT 'autre'
        CHECK (categorie IN ('materiel', 'deplacement', 'location_local', 'salaire', 'marketing', 'autre')),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TABLE : salary_configs (taux horaires par membre)
-- ============================================================
CREATE TABLE salary_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    taux_horaire NUMERIC(10, 2) NOT NULL DEFAULT 0,
    devise VARCHAR(10) NOT NULL DEFAULT 'BIF',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- INDEX pour performances
-- ============================================================
CREATE INDEX idx_materials_etat ON materials(etat);
CREATE INDEX idx_materials_categorie ON materials(categorie);
CREATE INDEX idx_rentals_material_id ON rentals(material_id);
CREATE INDEX idx_rentals_statut ON rentals(statut);
CREATE INDEX idx_rentals_date_fin ON rentals(date_fin_prevue);
CREATE INDEX idx_photos_album_id ON photos(album_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_statut ON tasks(statut);
CREATE INDEX idx_attendance_user_date ON attendance(user_id, date_pointage);
CREATE INDEX idx_invoices_statut ON invoices(statut);
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_schedules_user_date ON schedules(user_id, date_seance);
CREATE INDEX idx_gallery_tokens_token ON gallery_tokens(token);

-- ============================================================
-- Admin par défaut (mot de passe : admin123 — à changer !)
-- Hash bcrypt de 'admin123'
-- ============================================================
INSERT INTO users (email, password_hash, nom, role, telephone)
VALUES (
    'admin@studio.com',
    '$2b$12$LJ3m4ys3Lk0TSwHjYW8oNuGxvP8XLJQzBGE3Nv1x6F7K4jKbVy/u6',
    'Administrateur',
    'admin',
    '+257 79 000 000'
);
