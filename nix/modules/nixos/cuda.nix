{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Load nvidia_uvm kernel module for CUDA support (others loaded automatically)
  # boot.kernelModules = [ "nvidia_uvm" ];

  # Enable CUDA support globally (best with cachix nix-community)
  nixpkgs.config = {
    cudaSupport = true;
    rocmSupport = false;
  };

  # Enable graphics/OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load NVIDIA driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA hardware configuration
  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;

    # NVIDIA power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern NVIDIA GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Set to true for RTX 20-Series and newer, false for older GPUs
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Speedup CUDA startup
  # hardware.nvidia.nvidiaPersistenced = true;

  # NVIDIA container toolkit for Docker/Podman with CDI as:
  # [x] docker run --gpus all
  # [✓] docker run --device nvidia.com/gpus=all
  hardware.nvidia-container-toolkit.enable = true;

  # CUDA development packages and tools
  # environment.systemPackages = with pkgs; [
  #   cudaPackages.cudatoolkit
  #   cudaPackages.cudnn
  #   nvtopPackages.nvidia
  # ];

  # Environment variables for CUDA development
  environment.variables = {
    # CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    # CUDA_ROOT = "${pkgs.cudaPackages.cudatoolkit}";
    # EXTRA_LDFLAGS = "-L${config.boot.kernelPackages.nvidia_x11}/lib";
  };
}
