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

FROM alpine:${ALPINE_VERSION} as builder

RUN apk add --no-cache --update \
  build-base \
  ca-certificates \
  libffi-dev \
  openssl-dev \
  py-pip \
  python-dev

RUN pip install --upgrade pip

COPY requirements*.txt /tmp/

ARG REQUIREMENTS
ENV REQUIREMENTS ${REQUIREMENTS:-frozen}

RUN if [ "${REQUIREMENTS}" == "frozen" ]; then \
      pip install --quiet --requirement /tmp/requirements-frozen.txt; \
    else \
      pip install --quiet --upgrade --requirement /tmp/requirements.txt; \
    fi


FROM alpine:${ALPINE_VERSION}
LABEL maintainer="sebastian@nephosolutions.com"

RUN apk add --no-cache --update \
  bash \
  ca-certificates \
  git \
  libc6-compat \
  make \
  openssh-client \
  openssl \
  py-pip \
  python

RUN ln -s /lib /lib64

ARG GIT_CRYPT_VERSION
ENV GIT_CRYPT_VERSION ${GIT_CRYPT_VERSION}

ADD https://raw.githubusercontent.com/sgerrand/alpine-pkg-git-crypt/master/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
ADD https://github.com/sgerrand/alpine-pkg-git-crypt/releases/download/${GIT_CRYPT_VERSION}/git-crypt-${GIT_CRYPT_VERSION}.apk /var/cache/apk/
RUN apk add /var/cache/apk/git-crypt-${GIT_CRYPT_VERSION}.apk

COPY --from=builder /usr/bin/ansible* /usr/bin/
COPY --from=builder /usr/lib/python2.7 /usr/lib/python2.7

RUN mkdir /etc/ansible /usr/share/ansible
RUN /bin/echo -e "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

COPY ansible.cfg  /etc/ansible/ansible.cfg
COPY roles        /etc/ansible/roles
COPY plugins      /usr/share/ansible/plugins
