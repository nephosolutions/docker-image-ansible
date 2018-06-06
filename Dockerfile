#   Copyright 2018 NephoSolutions SPRL, Sebastian Trebitz
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

ARG ALPINE_VERSION=3.7

FROM alpine:${ALPINE_VERSION} as downloader
ENV ANSIBLE_VERSION 2.5.4

RUN apk add --no-cache --update build-base ca-certificates libffi-dev openssl-dev py-pip python-dev
RUN pip install -U ansible==${ANSIBLE_VERSION}


FROM alpine:${ALPINE_VERSION}
LABEL maintainer="sebastian@nephosolutions.com"

RUN apk add --no-cache --update ca-certificates git jq make openssh-client openssl python

COPY --from=downloader /usr/bin/ansible* /usr/bin/
COPY --from=downloader /usr/lib/python2.7 /usr/lib/python2.7

RUN addgroup circleci && \
    adduser -G circleci -D circleci

USER circleci
WORKDIR /home/circleci

