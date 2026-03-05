# Genvim

The simplest neovim wrapper I could think of. You should be able to use this
with pretty much anything as long as you can specify absolute paths for plugins.

# Usage

```nix
{ pkgs, ... }: {
  # Know that this will add nvim to your `home.packages`, that's how it adds lsps to the path.
  programs.genvim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      telescope-nvim
      nvim-treesitter
    ];
    lsps = with pkgs; [
      gopls
      ols
    ];
  }
}
```
This will produce the following symlinks:
```
~/
├── .nix-profile/bin/nvim
├── .local/share/nvim/
│   ├── lazy/lazy.nvim -> /nix/store/...
│   ├── nix-plugins/
│   │   ├── plenary.nvim -> /nix/store/...
│   │   ├── telescope.nvim -> /nix/store/...
│   │   ├── nvim-treesitter -> /nix/store/...
```

In your neovim config:
```lua
require("lazy").setup({
  {
    dir = vim.fn.stdpath("data") .. "/nix-plugins",
    lazy = true,
  },
  {
    "telescope.nvim",
    dependencies = { "plenary.nvim" },
    cmd = "Telescope",
  },
})
```

