pipeline {
  agent any

  environment {
    COMPOSE = 'docker compose'
    COMPOSE_FILE = 'docker-compose.prod.yml'
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
PUBLIC_WEB_URL=${PUBLIC_WEB_URL:-http://ludmilaedyego}
BOOTSTRAP_NOIVO_EMAIL=${BOOTSTRAP_NOIVO_EMAIL:-dyego.fernandes.vieira@gmail.com}
BOOTSTRAP_NOIVO_PASSWORD=${BOOTSTRAP_NOIVO_PASSWORD:-123456}
BOOTSTRAP_NOIVO_NOME=${BOOTSTRAP_NOIVO_NOME:-Dyego}
RUN_SEED=${RUN_SEED:-false}
EOF

          ${COMPOSE} -f ${COMPOSE_FILE} -p casamento down --remove-orphans || true
          for p in 3005 8087; do
            ids=$(docker ps -q --filter "publish=${p}" || true)
            if [ -n "$ids" ]; then
              docker stop $ids || true
              docker rm $ids || true
            fi
          done
          grep -q 'ludmilaedyego' /etc/hosts || echo '127.0.0.1 ludmilaedyego ludmilaedyego.com' >> /etc/hosts || true
          if ! ${COMPOSE} -f ${COMPOSE_FILE} -p casamento up -d --build --force-recreate; then
            echo "Deploy failed — dumping diagnostics" >&2
            ${COMPOSE} -f ${COMPOSE_FILE} -p casamento ps -a || true
            ${COMPOSE} -f ${COMPOSE_FILE} -p casamento logs api --tail 100 || true
            ${COMPOSE} -f ${COMPOSE_FILE} -p casamento logs nginx --tail 100 || true
            exit 1
          fi

          if ! command -v nginx >/dev/null 2>&1; then
            echo "nginx do host nao encontrado. http://ludmilaedyego exige um vhost na porta 80 apontando para 127.0.0.1:8087." >&2
            echo "Nao vamos publicar a porta 80 no Docker (conflito no VPS). Instale nginx no host e rode o job de novo." >&2
            exit 1
          fi
          mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
          cp deploy/host-nginx-ludmilaedyego.conf /etc/nginx/sites-available/ludmilaedyego.conf
          ln -sf /etc/nginx/sites-available/ludmilaedyego.conf /etc/nginx/sites-enabled/ludmilaedyego.conf
          nginx -t
          if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nginx; then
            systemctl reload nginx
          else
            nginx -s reload
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
              curl -fsS http://127.0.0.1:8087/api/health || true
              curl -fsS -H 'Host: ludmilaedyego' http://127.0.0.1/api/health || true
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
