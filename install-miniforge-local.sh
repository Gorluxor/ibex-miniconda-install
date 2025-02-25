# Define the log file path
log_file="/home/$USER/miniforge_installation.log"

# Function to log messages
log() {
    local message="$1"
    logger -t "Miniforge3 installation" "$message"
    echo "$(date): $message" >> "$log_file"
}

# Initialize the log file if it doesn't exist
touch "$log_file"
log "Miniforge3 installation script started"

# Check if the directory /home/$USER exists     
if [ ! -d "/home/$USER" ]; then
    echo "User account folder not found in local cluster"
    exit 1
fi

# install Miniforge3 in user's WekaIO directory
export PREFIX=/home/$USER

# Check the output of the "which conda" command
conda_path=$(which conda 2>/dev/null)

# Check if conda is installed
if [ -n "$conda_path" ]; then
    grandparent_dir=$(dirname "$(dirname "$conda_path")")
    echo "-----------------------------------------------------------"
    echo "🔍 Detected Conda installation at: ${grandparent_dir}"
    echo "⚡ You can manually clean up your paths and Conda environment by running:"
    if [[ "$conda_path" != /sw/workstations* ]]; then
        echo "   conda clean --all --yes      # Removes unused Conda files in old env"
    fi
    echo "   conda init --reverse --all   # Removes Conda paths if using integrated module loads"
    echo "📝 IMPORTANT: After running the above commands, exit your terminal and log back in."
    echo "⚠️  WARNING: VSCode terminals may cache paths, so if you continue seeing this message,"
    echo "   try running the commands in a fresh terminal or via SSH."
    echo "-----------------------------------------------------------"
    echo "🚀 The following script section will attempt to remove the Conda installation"
    echo ""
    # zsh and bash safe way of doing it
    printf >&2 '%s ' 'Recommended to run commands above, but you should work without it! Continue (y)? (y/n):'
    read ans
    
    # if its not y or Y, exit
    if [[ ! $ans =~ ^[Yy]$ ]]; then
        echo 'Negative confirmation Exiting...'
        log "Negative confirmation Exiting..."
        if [ "$0" = "$BASH_SOURCE" ]; then
            exit 0  # if called by bash script
        else
            return 0  # if called by source script
        fi
    fi
    
    # Check if the conda installation is from /sw/workstations
    if [[ "$conda_path" == /sw/workstations* ]]; then
        log "[INFO] Skipping deletion of default protected Conda from module load at $grandparent_dir"
    else
        log "Backing up old conda envs..."
        cp -r "$grandparent_dir/envs" "$PREFIX/conda_envs_backup"
        echo "Conda environments were backed up to $PREFIX/conda_envs_backup"
        log "Backup done"
        log "Deleting old conda version installed at: $grandparent_dir"
        rm -rf "$grandparent_dir"
    fi
else
    log "No previous conda version installed, resuming..."
fi

#Download and install latest Mambaforge
wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
log "Installing Miniforge..."
bash Miniforge3-Linux-x86_64.sh -b -p $PREFIX/miniforge
source $PREFIX/miniforge/bin/activate
conda deactivate
conda init bash
rm Miniforge3-Linux-x86_64.sh
log "Miniforge3 installation completed."

# Create the conda_cache directory if it doesn't exist
if [ ! -d "$PREFIX/conda_cache" ]; then
    log "Creating conda_cache directory at $PREFIX/conda_cache"
    mkdir -p "$PREFIX/conda_cache"
fi

# Update the CONDA_PKGS_DIRS variable in ~/.bashrc
RELOCATE_CACHE="export CONDA_PKGS_DIRS=${PREFIX}/conda_cache"
if ! grep -qF "$RELOCATE_CACHE" ~/.bashrc; then
  # If the line is not found, append it to ~/.bashrc
  echo "$RELOCATE_CACHE" >> ~/.bashrc
fi

# source ~/.bashrc to load modifications
source ~/.bashrc

# make sure that base environment is not active by default
conda config --set auto_activate_base false

# move the envs installation path to weka, removed because it breaks env naming in terminals
# potential solution at https://github.com/romkatv/powerlevel10k/issues/762#issuecomment-633389123
# conda config --add envs_dirs $PREFIX/.conda/environments

# second source required for update to conda config file to take effect
source ~/.bashrc

log "Miniforge installation script completed."
# Explain the user the steps
echo "Type these two lines to activate miniconda"
# echo "export CONDA_PKGS_DIRS=${PREFIX}/conda_cache"
echo "source ${PREFIX}/miniforge/bin/activate"
