FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev \
    && npm cache clean --force

COPY --from=builder --chown=node:node /app .

USER node
EXPOSE 8080
CMD ["npm", "start"]
