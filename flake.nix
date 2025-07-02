{
  description = "a sunny system flake configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    ###########################################################

    username = "yasushi";
    hostname = "sunny"; # = `scutil --get LocalHostName`

    # git 
    fullname = "Yasushi Sakai";
    email = "yasushi.accounts@fastmail.com";

    ###########################################################

    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

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

	finder.FXPreferredViewStyle = "Nlsv"; # defaults to list view on finder
	finder.NewWindowTarget = "Home";
	finder.ShowPathbar = true;
	finder.ShowStatusBar = true;

	NSGlobalDomain = {
          AppleShowAllExtensions = true;
          AppleMeasurementUnits = "Centimeters";
          AppleICUForce24HourTime = true;
	};
      };

      # Touch ID
      security.pam.services.sudo_local.touchIdAuth = true;
      
      # Microsoft Office was installed through MIT credentials
      # https://m365.cloud.microsoft/chat/?auth=2

      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [ 
        ffmpeg 
        pandoc
	imagemagick
      ];

      programs.zsh = {
        enable = true;
        enableFastSyntaxHighlighting = true;
        enableFzfCompletion = true;
        enableFzfHistory = true;
      };
      
      homebrew = {
      	enable = true;
	onActivation.cleanup= "zap";

	brews = [];
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
        users.${username} = { pkgs, ... }: {
          home.stateVersion = "24.11"; # don't change this!

	  home.packages = with pkgs; [
	    fzf
    	    claude-code
	  ];

          programs.neovim = {
            enable = true;
            defaultEditor = true;
	    vimAlias = true;
	    vimdiffAlias = true;
	    viAlias = true;
          };

	  programs.zsh = {
            enable = true;
            shellAliases = {
              rebuild = "sudo darwin-rebuild switch --flake ~/.config/nix";
	      memo = "zk edit -i";
            };
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
	      notebook.dir = "~/Documents/memo";
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
	      };
	    };
	  };

          home.file.".hammerspoon/init.lua".source = ./hammerspoon/init.lua;
	  # NOTE: you will need to back config.local file too 
	  home.file.".ssh/config".text = ''
	  Include ~/.ssh/config.local
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
