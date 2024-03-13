# Redacted Dockerfile
FROM node:18-alpine AS deps
RUN apk add --no-cache --repository="http://dl-cdn.alpinelinux.org/alpine/edge/main" libc6-compat

WORKDIR /app
COPY tools/ca-certificates.crt tools/ca-certificates.crt
COPY package.json yarn.lock .yarnrc.yml /app/
COPY .yarn/ .yarn/
COPY mock/ mock/
RUN cd mock && yarn install
RUN cd .. && yarn install --immutable

FROM node:18-alpine as builder

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN yarn build

FROM node:18-alpine as runner
ENV PORT 3000
ENV HOSTNAME "0.0.0.0"
WORKDIR /app

EXPOSE 3000

RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

USER nextjs

# CMD [ "node", "server.js"]
CMD [ "node", "ssl-server.js"]