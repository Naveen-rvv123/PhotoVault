CREATE TABLE vaults (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    admin_pass_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    pin_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE member_permissions (
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    permission VARCHAR(30) NOT NULL,
    PRIMARY KEY (member_id, permission)
);

CREATE TABLE folders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_by UUID REFERENCES members(id),
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    folder_id UUID NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
    file_name VARCHAR(255),
    storage_key VARCHAR(500),
    storage_url VARCHAR(1000),
    size_bytes BIGINT,
    uploaded_by UUID REFERENCES members(id),
    uploaded_at TIMESTAMP DEFAULT now()
);
