if [ -d "/usr/local/cuda" ]; then
  export CUDA_HOME=/usr/local/cuda
  if [[ ":$PATH:" != *":$CUDA_HOME/bin:"* ]]; then
    export PATH=$PATH:$CUDA_HOME/bin
  fi
fi

# Activation function for Bento ML virtualenvs. This will activate the
# virtualenv for the given path and set up LD_LIBRARY_PATH for the proper cuda
# version
ml-activate() {
  local venv_path=$(bento hacks ml-venv-path)
  # If the venv doesn't exist, echo and return
  if [[ ! -d "${venv_path}" ]]; then
    echo "No virtualenv found at ${venv_path}." 
    echo '  Did you run `bento hacks ml-init` to set up your project?'
    return 1
  fi

  source "${venv_path}/bin/activate"
  
  activated_cuda_path=$(bento hacks ml-detect-cuda)
  export LD_LIBRARY_PATH="${activated_cuda_path}:${LD_LIBRARY_PATH}"
  # remove trailing colon if it exists
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH%:}

  # We now have a deactivate function from the venv activate, but we need to
  # wrap it so that we can also undo our LD_LIBRARY_PATH change

  # Rename the original deactivate function to deactivate_minus_cuda
  functions[deactivate_minus_cuda]="${functions[deactivate]}"

  # Create a new deactivate function that calls the original and strips
  # activated_cuda_path out of the LD_LIBRARY_PATH list
  function deactivate() {
    deactivate_minus_cuda
    unset -f deactivate_minus_cuda
    # Note that deactivate_minus_cuda will have already unset deactivate
    export LD_LIBRARY_PATH=$(ruby -e 'puts (ENV["LD_LIBRARY_PATH"].split(":") - [ARGV.first]).join(":")' "$activated_cuda_path")
  }
}
