# getting started in a new machine

1. clone

hint: `barebones` branch

```bash
mkdir -p ~/.config
cd .config
git clone https://github.com/yasushisakai/nix-darwin-config nix
```

2. install Nix through

https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#determinate-nix-installer

`no` to Determinate-nix.

3. install Homebrew

4. change LocalHostName

5. minimal edit to flake.nix

6. login to App Store

7. darwin-rebuild

```bash
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix
```
