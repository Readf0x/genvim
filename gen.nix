{ pkgs, config, lib, ... }: let
  cfg = config.programs.genvim;
in {
  options.programs.genvim = {
    enable = lib.mkEnableOption "nvim symlink generator";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim;
    };

    deployPath = lib.mkOption {
      type = lib.types.string;
      default = ".local/share/nvim/nix-plugins";
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = ''
        symlinked to `deployPath`, which defaults to `~/.local/share/nvim/nix-plugins` and is accessible via `vim.fn.stdpath("data") .. '/nix-plugins'`.
      '';
    };

    lsps = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "added to neovim's path via a wrapper script.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "nvim" ''
        export PATH="${lib.makeBinPath cfg.lsps}:$PATH"
        exec "${cfg.package}/bin/nvim" "$@"
      '')
    ];
    home.file."${cfg.deployPath}".source =
      pkgs.linkFarm "nvim-nix-plugins" (map (p: {
        name = p.pname or p.name;
        path = p;
      }) cfg.plugins);
  };
}
