FROM alpine:3.19

# Required packages (nss-tools for mkcert)
# Versions pinned for reproducible builds
RUN apk add --no-cache \
    bash=5.2.21-r0 \
    curl=8.14.1-r2 \
    jq=1.7.1-r0 \
    yq=4.35.2-r4 \
    git=2.43.7-r0 \
    docker-cli=25.0.5-r1 \
    nss-tools=3.99-r0 \
    shellcheck=0.9.0-r4

# kubectl 
ENV KUBECTL_VERSION=1.34.3
ADD https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# helm
ENV HELM_VERSION=4.1.1
ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz /tmp/helm.tar.gz
RUN tar -xzf /tmp/helm.tar.gz -C /tmp && mv /tmp/linux-amd64/helm /usr/local/bin/ && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# kind
ENV KIND_VERSION=0.31.0
ADD https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-amd64 /usr/local/bin/kind
RUN chmod +x /usr/local/bin/kind

# argocd CLI
ENV ARGOCD_VERSION=3.3.1
ADD https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64 /usr/local/bin/argocd
RUN chmod +x /usr/local/bin/argocd

# mkcert
ENV MKCERT_VERSION=1.4.4
ADD https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-amd64 /usr/local/bin/mkcert
RUN chmod +x /usr/local/bin/mkcert


# TODO Add hash verification for all downloaded binaries

ENV KUBECONFIG=/workspace/.kube/config
WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]
