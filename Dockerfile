FROM node:20-bookworm

LABEL org.opencontainers.image.source="https://github.com/GuionAI/browser"

RUN apt-get update \
    && apt-get install -y --no-install-recommends fonts-noto-cjk fonts-wqy-zenhei fonts-wqy-microhei xvfb x11-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund \
    && npx -y playwright@1.52.0 install chromium --with-deps

COPY server.js entrypoint.sh LICENSE ./
RUN chmod +x entrypoint.sh

EXPOSE 3000
CMD ["./entrypoint.sh"]
