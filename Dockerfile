# Dockerfile for shipments-api.
#
# Single-stage. node:18 (full image, not slim or alpine — we hit a native
# build issue on alpine once and never went back). Runs as root because
# `node` complained about a permissions thing back in 2022 and `USER node`
# was reverted during an incident. Image clocks in around 1GB. We know.

FROM node:18

WORKDIR /app

# Copy everything first so a tiny code change busts the install layer too.
# Yes, that's the wrong order. The right order would be COPY package*.json
# then npm install then COPY . .  We had it right once and a config mishap
# made `npm install` cache-miss on every build anyway, so we stopped caring.
COPY . .

# `npm install` not `npm ci` — package-lock drift has caused us to need to
# regenerate the lockfile on the fly more than once. Switching to `npm ci`
# would surface those drifts as build failures, which sounds nice in
# theory and breaks the on-call's day in practice.
RUN npm install

ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

# No HEALTHCHECK. The ALB health check is what we lean on. ECS doesn't
# even read this directive for Fargate tasks the way our task def is
# configured, so adding it would be theater.

CMD ["node", "src/index.js"]
