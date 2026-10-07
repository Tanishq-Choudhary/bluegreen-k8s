FROM nginxinc/nginx-unprivileged:1.27-alpine

ARG VERSION=v1
ARG COLOR=blue

USER root
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
RUN sed -i "s/__VERSION__/${VERSION}/g; s/__COLOR__/${COLOR}/g" /usr/share/nginx/html/index.html \
    && printf '%s %s\n' "${COLOR}" "${VERSION}" > /usr/share/nginx/html/version.txt
USER 101

EXPOSE 8080
