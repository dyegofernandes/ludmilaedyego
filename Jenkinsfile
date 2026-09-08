pipeline {
  agent any

  environment {
    COMPOSE = 'docker compose'
    COMPOSE_FILE = 'docker-compose.prod.yml'
    PUBLIC_HOST = 'ludmilaedyego.ddns.net'
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'https://github.com/dyegofernandes/ludmilaedyego.git',
            credentialsId: 'gitHub'
      }
    }

    stage('Deploy') {
      steps {
        sh '''
          set -e
          cat > .env <<EOF
POSTGRES_USER=${POSTGRES_USER:-casamento}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-casamento-change-me}
POSTGRES_DB=${POSTGRES_DB:-casamento}
JWT_SECRET=${JWT_SECRET:-change-me-casamento-jwt}
JWT_EXPIRES_IN=${JWT_EXPIRES_IN:-30d}
PUBLIC_WEB_URL=${PUBLIC_WEB_URL:-https://ludmilaedyego.ddns.net:8087}
BOOTSTRAP_NOIVO_EMAIL=${BOOTSTRAP_NOIVO_EMAIL:-dyego.fernandes.vieira@gmail.com}
BOOTSTRAP_NOIVO_PASSWORD=${BOOTSTRAP_NOIVO_PASSWORD:-123456}
BOOTSTRAP_NOIVO_NOME=${BOOTSTRAP_NOIVO_NOME:-Dyego}
RUN_SEED=${RUN_SEED:-false}
CERTBOT_EMAIL=${CERTBOT_EMAIL:-dyego.fernandes.vieira@gmail.com}
EOF

          mkdir -p certs certbot-www
          ACME_ROOT=/var/www/certbot
          if mkdir -p "$ACME_ROOT" 2>/dev/null && [ -w "$ACME_ROOT" ]; then
            echo "ACME webroot: $ACME_ROOT"
          else
            ACME_ROOT="$PWD/certbot-www"
            echo "ACME webroot (workspace): $ACME_ROOT"
          fi

          if [ -d /etc/nginx/sites-enabled ]; then
            cp deploy/host-nginx-ludmilaedyego.conf /etc/nginx/sites-enabled/ludmilaedyego.ddns.net.conf || true
            nginx -t && nginx -s reload || true
          fi

          obtain_cert() {
            if command -v certbot >/dev/null 2>&1; then
              certbot certonly --webroot -w "$ACME_ROOT" \
                -d "$PUBLIC_HOST" \
                --email "${CERTBOT_EMAIL:-dyego.fernandes.vieira@gmail.com}" \
                --agree-tos --non-interactive --keep-until-expiring || return 1
              LIVE=/etc/letsencrypt/live/$PUBLIC_HOST
            elif command -v docker >/dev/null 2>&1; then
              mkdir -p letsencrypt
              docker run --rm \
                -v "$ACME_ROOT:/var/www/certbot" \
                -v "$PWD/letsencrypt:/etc/letsencrypt" \
                certbot/certbot certonly --webroot -w /var/www/certbot \
                -d "$PUBLIC_HOST" \
                --email "${CERTBOT_EMAIL:-dyego.fernandes.vieira@gmail.com}" \
                --agree-tos --non-interactive --keep-until-expiring || return 1
              LIVE="$PWD/letsencrypt/live/$PUBLIC_HOST"
            else
              return 1
            fi
            if [ -f "$LIVE/fullchain.pem" ] && [ -f "$LIVE/privkey.pem" ]; then
              cp -L "$LIVE/fullchain.pem" certs/fullchain.pem
              cp -L "$LIVE/privkey.pem" certs/privkey.pem
              echo "Certificado Let's Encrypt copiado para certs/"
              return 0
            fi
            return 1
          }

          if [ ! -f certs/fullchain.pem ] || [ ! -f certs/privkey.pem ]; then
            obtain_cert || echo "Certbot indisponível ou falhou — nginx sobe com cert autoassinado"
          else
            obtain_cert || echo "Renovação Let's Encrypt falhou — mantendo certs atuais"
          fi

          ${COMPOSE} -f ${COMPOSE_FILE} -p casamento down --remove-orphans || true
          for p in 3005 8087; do
            ids=$(docker ps -q --filter "publish=${p}" || true)
            if [ -n "$ids" ]; then
              docker stop $ids || true
              docker rm $ids || true
            fi
          done
          grep -q 'ludmilaedyego' /etc/hosts || echo '127.0.0.1 ludmilaedyego ludmilaedyego.com ludmilaedyego.ddns.net' >> /etc/hosts || true
          if ! ${COMPOSE} -f ${COMPOSE_FILE} -p casamento up -d --build --force-recreate; then
            echo "Deploy failed — dumping diagnostics" >&2
            ${COMPOSE} -f ${COMPOSE_FILE} -p casamento ps -a || true
            ${COMPOSE} -f ${COMPOSE_FILE} -p casamento logs api --tail 100 || true
            ${COMPOSE} -f ${COMPOSE_FILE} -p casamento logs nginx --tail 100 || true
            exit 1
          fi
        '''
      }
    }

    stage('Health') {
      steps {
        sh '''
          set -e
          for i in $(seq 1 40); do
            if ${COMPOSE} -f ${COMPOSE_FILE} -p casamento exec -T api node -e "fetch('http://127.0.0.1:3000/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"; then
              echo "Casamento API health ok"
              curl -fsS http://127.0.0.1:3005/api/health || true
              curl -fskS https://127.0.0.1:8087/api/health || true
              exit 0
            fi
            sleep 2
          done
          echo "Casamento API health failed" >&2
          ${COMPOSE} -f ${COMPOSE_FILE} -p casamento ps -a || true
          ${COMPOSE} -f ${COMPOSE_FILE} -p casamento logs api --tail 80 || true
          ${COMPOSE} -f ${COMPOSE_FILE} -p casamento logs nginx --tail 80 || true
          exit 1
        '''
      }
    }
  }
}
