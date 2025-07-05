{
  description = "a sunny system flake configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      ###########################################################

      username = "yasushi";
      hostname = "sunny"; # = `scutil --get LocalHostName`

      # git
      fullname = "Yasushi Sakai";
      email = "yasushi.accounts@fastmail.com";

      # zk
      zk_directory = "$HOME/Documents/memo/";

      ###########################################################

      configuration =
        { pkgs, ... }:
        {

          # NOTE: List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          nix.settings.experimental-features = "nix-command flakes";

          nix.gc = {
            automatic = true;
            # dates = "weekly"; # if not nix-darwin
            interval = {
              Weekday = 0;
              Hour = 0;
              Minute = 0;
            };
            options = "--delete-older-than 300d";
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          system.stateVersion = 6; # don't change this!
          system.primaryUser = username;

          system.keyboard = {
            enableKeyMapping = true;
            remapCapsLockToControl = true;
          };

          system.activationScripts.postUserActivateion.text = ''
            sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
          '';

          system.defaults = {

            dock = {
              show-recents = false;
              autohide = true;
              mru-spaces = false;
              persistent-apps = [
                { app = "/System/Applications/Messages.app"; }
                { app = "/System/Applications/System Settings.app"; }
              ];
            };

            screencapture.location = "/Users/${username}/Screenshots";

            finder.FXPreferredViewStyle = "Nlsv"; # defaults to list view on finder
            finder.NewWindowTarget = "Home";
            finder.ShowPathbar = true;
            finder.ShowStatusBar = true;

            NSGlobalDomain = {
              AppleShowAllExtensions = true;
              AppleMeasurementUnits = "Centimeters";
              AppleICUForce24HourTime = true;
              NSAutomaticSpellingCorrectionEnabled = false;
            };
          };

          # Touch ID
          security.pam.services.sudo_local.touchIdAuth = true;
          security.pam.services.sudo_local.watchIdAuth = true;

          # Microsoft Office was installed through MIT credentials
          # https://m365.cloud.microsoft/chat/?auth=2

          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config.allowUnfree = true;

          environment.systemPackages = with pkgs; [
            ffmpeg
            pandoc
            imagemagick
            tectonic
            ghostscript
          ];

          programs.zsh = {
            enable = true;
            enableFastSyntaxHighlighting = true;
            enableFzfCompletion = true;
            enableFzfHistory = true;
          };

          fonts = {
            packages = with pkgs; [
              hackgen-nf-font
              cm_unicode
            ];
          };

          homebrew = {
            enable = true;
            onActivation.cleanup = "zap";

            brews = [ "clang-format" ];
            casks = [
              "ghostty"
              "bitwarden"
              "figma"
              "slack"
              "discord"
              "hammerspoon"
              "zoom" # moved from systemPackages, for the alias
              "whatsapp"
              "google-chrome" # fall back browser
              "little-snitch"
              "obs"
              "loopback"
              "font-sf-mono"
              "font-sf-pro"
              "font-new-york"
            ];

            # NOTE: this will not get purged through `onActivation.cleanup`
            masApps = {
              # apple products
              "Final Cut Pro" = 424389933;
              "Logic Pro" = 634148309;
              "Compressor" = 424390742;
              "Keynote" = 409183694;
              "Xcode" = 497799835;
              "Tailscale" = 1475387142; # Tailscale said mas rather than brew
            };
          };

          users.users.${username}.home = "/Users/${username}";

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} =
              { pkgs, ... }:
              {
                home.stateVersion = "24.11"; # don't change this!

                home.packages = with pkgs; [
                  fzf
                  claude-code
                  go
                  tree-sitter
                  # script language runtimes like python and nodejs
                  # should be installed through direnv

                  # *** LSPs ***
                  lua-language-server
                  gopls
                  # The following is configured in neovim
                  # but this should be installed through zk_directorydirenv
                  # pyright
                  # typescript-language-server (ts_ls)

                  # *** formatters ***
                  nixfmt-rfc-style
                  stylua
                  # formatters are exceptions to
                  # python and nodejs
                  ruff # python
                  prettierd # js, ts and md
                ];

                programs.direnv = {
                  enable = true;
                  enableZshIntegration = true;
                  nix-direnv.enable = true;
                };

                programs.neovim = {
                  enable = true;
                  defaultEditor = true;
                  vimAlias = true;
                  vimdiffAlias = true;
                  viAlias = true;
                };

                programs.zsh = {
                  enable = true;
                  autosuggestion.enable = true;
                  shellAliases = {
                    rebuild = "sudo darwin-rebuild switch --flake ~/.config/nix";
                    update = "nix flake update --flake ~/.config/nix";
                    cleanup = "sudo nix-env --delete-generations +5";
                    memo = "zk edit -i";
                    config = "nvim ~/.config/nix/flake.nix";
                    config-nvim = "nvim ~/.config/nix/nvim/init.lua";
                    bib = "nvim ${zk_directory}main.bib";
                  };
                  initContent = ''
                    export ZK_NOTEBOOK_DIR="${zk_directory}";
                  '';
                };

                programs.gh = {
                  enable = true;
                  extensions = with pkgs; [
                    gh-copilot
                  ];
                  settings = {
                    git_protocol = "https";
                    prompt = "enabled";
                  };
                };

                programs.git = {
                  enable = true;
                  userName = fullname;
                  userEmail = email;
                  extraConfig = {
                    init.defaultBranch = "main";
                    pull.rebase = true;
                  };
                  ignores = [ ".DS_Store" ];
                };

                programs.zoxide = {
                  enable = true;
                  enableZshIntegration = true;
                  options = [ "--cmd cd" ];
                };

                # `zk init ~/Documents/memo`
                programs.zk = {
                  enable = true;
                  settings = {
                    notebook.dir = "${zk_directory}";
                    note = {
                      language = "en";
                      filename = "{{slug title}}-{{id}}";
                      extension = "md";
                      id-charset = "alphanum";
                      id-length = 4;
                      id-case = "lower";
                    };
                    extra.author = fullname;
                    format.markdown = {
                      hashtags = true;
                      colon-tags = true;
                    };
                    tool = {
                      editor = "nvim";
                      pandoc.extra-args = [
                        "--bibliography=${zk_directory}main.bib"
                        "--citeproc"
                      ];
                    };
                  };
                };

                # config neovim is left to neovim...
                home.file.".hammerspoon/init.lua".source = ./hammerspoon/init.lua;

                home.file.".config/nvim/init.lua".source = ./nvim/init.lua;

                # NOTE: you will need to back up config.local file too
                home.file.".ssh/config".text = ''
                  	        Include ~/.ssh/config.local
                  	        '';

                home.file.".config/ghostty/config".text = ''
                  font-family = HackGen35 Console NF
                  font-size = 14
                '';

                home.file.".config/stylua/stylua.toml".text = ''
                  indent_type = "Spaces"
                  indent_width = 4
                '';

              };
          }; # home-manager
        };
    in
    {
      # Build darwin flake using:
      # $ sudo darwin-rebuild build --flake ~/.config/nix/
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
        ];
      };
    };
}
