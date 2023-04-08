source /etc/profile

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Kubectl auto-completion and aliases
source <(kubectl completion bash)

export KUBECONFIG=/home/tooling/kubeconfig.yaml

alias k=kubectl
complete -o default -F __start_kubectl k