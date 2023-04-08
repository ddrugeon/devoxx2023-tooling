FROM alpine:latest as builder

ARG ARCH

ARG KUBECTL_VERSION=1.25.8
ARG BOUNDARY_VERSION=0.12.1
ARG HELM_VERSION=3.10.2

RUN case `uname -m` in \
    x86_64) ARCH=amd64 TRIVY_TAR_FILE=trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz KYVERNO_TAR_FILE=kyverno-cli_${KYVERNO_VERSION}_linux_x86_64.tar.gz ;; \
    aarch64) ARCH=arm64 TRIVY_TAR_FILE=trivy_${TRIVY_VERSION}_Linux-ARM64.tar.gz KYVERNO_TAR_FILE=kyverno-cli_${KYVERNO_VERSION}_linux_arm64.tar.gz ;; \
    *) echo "un-supported arch, exit ..."; exit 1; ;; \
    esac && \
    echo "export ARCH=$ARCH" > /envfile && \
    echo "export TRIVY_TAR_FILE=${TRIVY_TAR_FILE}" >> /envfile && \
    echo "export KYVERNO_TAR_FILE=${KYVERNO_TAR_FILE}" >> /envfile && \
    cat /envfile

RUN apk add --update --no-cache curl ca-certificates openssl openssh yq

# Install kubectl
RUN . /envfile && echo $ARCH && \
    curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl && \
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

RUN . /envfile && echo $ARCH \
&& curl -sLO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" \
&& tar xfz helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz \
&& rm helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz \
&& mv linux-${ARCH}/helm /usr/bin \
&& rm -Rf linux-${ARCH} \
&& chmod +x /usr/bin/helm

# Install boundary
RUN . /envfile && echo $ARCH \
  && curl -sLO "https://releases.hashicorp.com/boundary/${BOUNDARY_VERSION}/boundary_${BOUNDARY_VERSION}_linux_${ARCH}.zip"  \
  && unzip boundary_${BOUNDARY_VERSION}_linux_${ARCH}.zip \
  && rm boundary_${BOUNDARY_VERSION}_linux_${ARCH}.zip \
  && mv boundary /usr/bin/boundary \
  && chmod +x /usr/bin/boundary

# Install linkerd
RUN . /envfile && echo $ARCH \
&& curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh \
&& mv /root/.linkerd2/bin/linkerd-stable-2.12.4 /usr/bin/linkerd

FROM alpine:latest

LABEL org.opencontainers.image.source https://github.com/ddrugeon/devoxx2023-tooling

ENV USER_ID=1000
ENV GROUP_ID=1000
ENV USER_NAME=tooling
ENV GROUP_NAME=tooling

RUN apk add --update --no-cache ca-certificates bash bash-completion jq git bind-tools vim 
RUN addgroup -g $GROUP_ID $GROUP_NAME \
    && adduser --shell /bin/bash --disabled-password -h /home/$USER_NAME --uid $USER_ID  \
    --ingroup $GROUP_NAME $USER_NAME 


COPY --chown=$USER_NAME .bashrc .bash_profile /home/$USER_NAME/

COPY --from=builder /usr/bin/yq \
   /usr/bin/kubectl \
   /usr/bin/boundary \
   /usr/bin/linkerd \
   /usr/bin/helm \
   /usr/bin/

USER $USER_NAME

WORKDIR /apps
ENTRYPOINT [ "/bin/bash" ]
