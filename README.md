# PileUp

Personal finance (NetWorth (WIP)) tracking platform with partial end-to-end encryption (E2EE), comprising a Django REST backend, a Vue 3 (with PWA capability), and a native SwiftUI iOS application (WIP).

## Repository Structure

- `backend/`: Django, REST API, JWT authentication, and PostgreSQL as DB.
- `frontend/`: Vue 3 PWA client with client-side cryptography.
- `pileup-ios/`: ios app in swift, using swiftUI (WIP).
- `terraform/`: Cloud infrastructure config files (WIP).
- `docker-compose.yaml`: selfhosted container configuration.

## System Architecture

### Security and Cryptography
- Partial End-to-End encryption (E2EE) using AES-256-CBC.
- Local cryptographic key and session token persistence via Apple Keychain on iOS.

### Backend (`backend/`)
- Django REST Framework with JWT authentication.
- PostgreSQL database.
- Containerized deployment with Gunicorn and WhiteNoise.

### Web Client (`frontend/`)
- Vue 3, Vite, Pinia, and Tailwind CSS.
- Client-side encryption and decryption.
- Charts with ECharts and PrimeVue components.
- PWA.

### iOS Application (`pileup-ios/`)
- Swift and SwiftUI.
- Biometric unlock (Face ID / Touch ID) with Keychain token storage.

### CI/CD and Operations
- GitHub Actions workflows for Docker images (`pileup-backend`, `pileup-web`).
- Docker Compose for self hosted deployment.

## Deployment and Setup

### Self-Hosted (Docker Compose)

```bash
# Download setup files
curl -sSL "https://raw.githubusercontent.com/riccardo-modina/PileUp/main/install.sh" | bash

# Configure environment
# Edit .env with your credentials

# Start containers
docker compose up -d
```

### Local Development

Backend:
```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
./start.sh
```

Frontend:
```bash
cd frontend
npm install
npm run dev
```

iOS App:
Open `pileup-ios/pileup-ios.xcodeproj` in Xcode.

