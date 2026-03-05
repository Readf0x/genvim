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
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/nvim";
    };

    manageLazy = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    lua-plugin = lib.mkEnableOption "genvim lua helper";

    plugins = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = ''
        symlinked to `''${deployPath}/nix-plugins`, which defaults to `~/.local/share/nvim/nix-plugins` and is accessible via `vim.fn.stdpath("data") .. '/nix-plugins'`.
      '';
    };

    treesitter-grammars = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = ''
        symlinked to `''${deployPath}/site`.
      '';
    };

    lsps = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "added to neovim's path via a wrapper script.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = let
      lua_pkgs = with pkgs; [ lua51Packages.lua luajit luajitPackages.luarocks ];
    in [
      (pkgs.writeShellScriptBin "nvim" ''
        export PATH="${lib.makeBinPath (cfg.lsps ++ lua_pkgs)}:$PATH"
        ${lib.concatStrings (map (pkg: ''
          export LUA_PATH="${pkg}/share/lua/5.1/?.lua;${pkg}/share/lua/5.1/?/init.lua;$LUA_PATH"
          export LUA_CPATH="${pkg}/lib/lua/5.1/?.so;$LUA_CPATH"
        '') lua_pkgs)}
        exec "${cfg.package}/bin/nvim" \
          ${if cfg.manageLazy then ''--cmd "set rtp^=${cfg.deployPath}/lazy/lazy.nvim" \'' else ""}
          "$@"
      '')
    ];
    home.file."${cfg.deployPath}/lazy/lazy.nvim" = lib.mkIf cfg.manageLazy { source = pkgs.vimPlugins.lazy-nvim; };
    home.file."${cfg.deployPath}/site".source = pkgs.symlinkJoin {
      name = "nvim-treesitter-parsers";
      paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (_: cfg.treesitter-grammars)).dependencies;
    };
    home.file.".config/nvim/lua/genvim.lua" =
      lib.mkIf cfg.lua-plugin { text = ''
        local M = {}

        M.plugins = vim.fn.stdpath("data") .. "/nix-plugins"

        function M.inject_dirs(specs)
          base = base or M.plugins

          for _, spec in ipairs(specs) do
            if type(spec) == "table"
              and spec.name
              and not spec.dir
            then
              spec.dir = base .. "/" .. spec.name
            end
          end

          return specs
        end

        return M
      '';};
    home.file."${cfg.deployPath}/nix-plugins".source =
      pkgs.linkFarm "nvim-nix-plugins" (map (p: {
        name = p.pname or p.name;
        path = p;
      }) cfg.plugins);
  };
}
