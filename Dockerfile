#   Copyright 2019 NephoSolutions SPRL, Sebastian Trebitz
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ARG ALPINE_VERSION
ARG PYTHON_VERSION

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} as builder

RUN apk add --no-cache --update \
  build-base \
  ca-certificates \
  libffi-dev \
  openssl-dev

RUN pip install --upgrade pip

COPY requirements*.txt /tmp/

ARG REQUIREMENTS
ENV REQUIREMENTS ${REQUIREMENTS:-frozen}

RUN if [ "${REQUIREMENTS}" == "frozen" ]; then \
      pip install --quiet --requirement /tmp/requirements-frozen.txt; \
    else \
      pip install --quiet --upgrade --requirement /tmp/requirements.txt; \
    fi

WORKDIR /tmp

ARG GCLOUD_SDK_VERSION
ENV GCLOUD_SDK_VERSION ${GCLOUD_SDK_VERSION}

ADD https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz
RUN tar -xzf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}
LABEL maintainer="sebastian@nephosolutions.com"

RUN apk add --no-cache --update \
  bash \
  ca-certificates \
  git \
  libc6-compat \
  make \
  openssh-client \
  openssl

RUN ln -s /lib /lib64

ARG GIT_CRYPT_VERSION
ENV GIT_CRYPT_VERSION ${GIT_CRYPT_VERSION}

ADD https://raw.githubusercontent.com/sgerrand/alpine-pkg-git-crypt/master/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
ADD https://github.com/sgerrand/alpine-pkg-git-crypt/releases/download/${GIT_CRYPT_VERSION}/git-crypt-${GIT_CRYPT_VERSION}.apk /var/cache/apk/
RUN apk add /var/cache/apk/git-crypt-${GIT_CRYPT_VERSION}.apk

COPY --from=builder /usr/local/bin/ansible* /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.8 /usr/local/lib/python3.8

COPY --from=builder /tmp/google-cloud-sdk /opt/google/cloud-sdk

RUN mkdir /etc/ansible /usr/share/ansible
RUN /bin/echo -e "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

COPY ansible.cfg  /etc/ansible/ansible.cfg
COPY plugins      /usr/share/ansible/plugins

RUN addgroup alpine && \
    adduser -G alpine -D alpine

COPY --chown=alpine:alpine roles /etc/ansible/roles

USER alpine
ENV USER alpine

WORKDIR /home/alpine

ENV PATH $PATH:/opt/google/cloud-sdk/bin
