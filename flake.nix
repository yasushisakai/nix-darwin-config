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

          #####################
          # GLOBAL packages
          #####################
          environment.systemPackages = with pkgs; [
            htop
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

            #####################
            # Homebrew packages
            #####################
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

                #####################
                # Home Manger packages
                #####################
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
                  enableZshIntegration = false; # We'll handle this manually
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
                  enableCompletion = false; # We'll handle this manually
                  shellAliases = {
                    rebuild = "sudo darwin-rebuild switch --flake ~/.config/nix";
                    update = "nix flake update --flake ~/.config/nix";
                    cleanup = "sudo nix-env --delete-generations +5";
                    memo = "zk edit -i";
                    config = "nvim ~/.config/nix/flake.nix";
                    config-nvim = "nvim ~/.config/nix/nvim/init.lua";
                    bib = "nvim ${zk_directory}main.bib";
                  };
                  history = {
                    append = true;
                    expireDuplicatesFirst = true;
                    findNoDups = true;
                    ignoreAllDups = true;
                    ignorePatterns = [
                      "cd *"
                      "rm *"
                    ];
                    saveNoDups = true;
                  };
                  initExtra = ''
                    export ZK_NOTEBOOK_DIR="${zk_directory}";

                    bindkey -v
                    bindkey '^R' fzf-history-widget
                    bindkey -M viins 'jk' vi-cmd-mode
                    bindkey -M viins '^?' backward-delete-char
                    bindkey -M viins '^H' backward-delete-char

                    # Store compdef calls until compinit is loaded
                    typeset -ga _DEFERRED_COMPDEFS
                    compdef() {
                      if [[ -z "$_COMPINIT_LOADED" ]]; then
                        _DEFERRED_COMPDEFS+=("$*")
                      else
                        command compdef "$@"
                      fi
                    }

                    # Apply deferred compdefs after loading
                    _apply_deferred_compdefs() {
                      local args
                      for args in "''${_DEFERRED_COMPDEFS[@]}"; do
                        eval "compdef $args"
                      done
                      unset _DEFERRED_COMPDEFS
                      unfunction compdef
                      unfunction _apply_deferred_compdefs
                    }

                    # Lazy load compinit
                    _lazy_load_compinit() {
                      if [[ -z "$_COMPINIT_LOADED" ]]; then
                        autoload -Uz compinit
                        compinit -C
                        _COMPINIT_LOADED=1
                        bindkey '^I' expand-or-complete
                        if [[ -n "''${_DEFERRED_COMPDEFS}" ]]; then
                          _apply_deferred_compdefs
                        fi
                      fi
                    }

                    # Trigger compinit on first tab completion attempt
                    _first_tab() {
                      _lazy_load_compinit
                      zle expand-or-complete
                    }
                    zle -N _first_tab
                    bindkey '^I' _first_tab

                    # Lazy load direnv
                    _lazy_load_direnv() {
                      if [[ -z "$_DIRENV_LOADED" ]]; then
                        eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
                        _DIRENV_LOADED=1
                        # After loading, call the real direnv hook
                        _direnv_hook
                      fi
                    }

                    # Override cd to check for direnv
                    cd() {
                      builtin cd "$@"
                      # Check if we need direnv after changing directory
                      if [[ -f .envrc ]] || [[ -f .env ]] || [[ -f shell.nix ]] || [[ -f flake.nix ]]; then
                        _lazy_load_direnv
                      elif command -v _direnv_hook &> /dev/null; then
                        # If direnv is already loaded, run its hook
                        _direnv_hook
                      fi
                    }

                    # Also check for .envrc in current directory on startup
                    if [[ -f .envrc ]] || [[ -f .env ]] || [[ -f shell.nix ]] || [[ -f flake.nix ]]; then
                      _lazy_load_direnv
                    fi

                    # Add profiling function to measure startup time
                    zsh-startup-time() {
                      for i in $(seq 1 10); do
                        time zsh -i -c exit
                      done
                    }
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
