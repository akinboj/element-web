# Builder
FROM fhirfactory/pegacorn-base-communicate-app-web:1.0.0 as builder

# Support custom branches of the react-sdk and js-sdk. This also helps us build
# images of riot-web develop.
# ARG USE_CUSTOM_SDKS=false
# ARG REACT_SDK_REPO="https://github.com/matrix-org/matrix-react-sdk.git"
# ARG REACT_SDK_BRANCH="master"
# ARG JS_SDK_REPO="https://github.com/matrix-org/matrix-js-sdk.git"
# ARG JS_SDK_BRANCH="master"

WORKDIR /src

COPY . /src

# Configuring certificate while SSL authentication is true
# RUN yarn config set proxy http://ACTGOV%5CYemi%20Emmanuel:pwd@proxy.test.act.gov.au:9090
# COPY /PRDPKICA.crt /opt
# RUN yarn config set strict-ssl true
# RUN yarn config set cafile /opt/PRDPKICA.crt

# Not required as we are working on our branch that was pulled localy
# This explains why the ARG variables were commented out
# RUN dos2unix /src/scripts/docker-link-repos.sh && bash /src/scripts/docker-link-repos.sh

RUN cd matrix-js-sdk-develop
RUN yarn link
RUN yarn --network-timeout=100000 install
RUN cd ../

RUN cd matrix-react-sdk-develop
#RUN yarn link
RUN yarn link element-web
RUN yarn --network-timeout=100000 install
RUN cd ../

RUN yarn --network-timeout=100000 install
RUN yarn build

# Copy the config now so that we don't create another layer in the app image
RUN cp /src/config.json /src/webapp/config.json

# Ensure we populate the version file
# RUN dos2unix /src/scripts/docker-write-version.sh && bash /src/scripts/docker-write-version.sh

# Date-time build argument
ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

# App
FROM nginx:alpine

COPY --from=builder /src/webapp /app

COPY default.conf /etc/nginx/conf.d/default.conf

# Insert wasm type into Nginx mime.types file so they load correctly.
RUN sed -i '3i\ \ \ \ application/wasm wasm\;' /etc/nginx/mime.types

RUN rm -rf /usr/share/nginx/html \
 && ln -s /app /usr/share/nginx/html
