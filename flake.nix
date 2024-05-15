{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }: {
    formatter = builtins.mapAttrs (_: pkgs: pkgs.nixfmt) nixpkgs.legacyPackages;
    homeModules.myshell = { config, lib, ... }: {
      options.nixplus.myshell = {
        enable = lib.options.mkOption {
          default = false;
          type = lib.types.bool;
        };
        package = lib.options.mkOption { type = lib.types.package; };
      };
      config.programs.bash = lib.modules.mkIf config.nixplus.myshell.enable {
        enable = true;
        initExtra = let
          sh =
            "${config.nixplus.myshell.package}${config.nixplus.myshell.package.shellPath}";
        in lib.modules.mkOrder 10200
        "[ $MYSHELL_FORCE_BASH != 1 ] && SHELL=${sh} exec ${sh}";
      };
    };
    lib.homeConfiguration = { modules, }: { imports = modules; };
    nixosModules = {
      cohm = nixosInput: {
        config = {
          home-manager.sharedModules = [
            (homeManagerInput: {
              options.nixplus.cohm = homeManagerInput.lib.options.mkOption {
                type = builtins.head nixosInput.options.user.user.getSubModules;
              };
            })
          ];
          users.users = builtins.mapAttrs (_: user: user.nixplus.cohm)
            (nixosInput.lib.attrsets.filterAttrs (_: user: user ? nixplus.cohm)
              nixosInput.config.home-manager.users);
        };
      };
      nvidia = { config, lib, ... }: {
        options.nixplus.nvidia.enable = lib.options.mkOption {
          default = false;
          type = lib.types.bool;
        };
        config = {
          environment.variables =
            lib.modules.mkIf config.nixplus.nvidia.enable {
              "NVD_BACKEND" = "direct";
              "WLR_NO_HARDWARE_CURSORS" = "1";
            };
          services.xserver.videoDrivers =
            lib.modules.mkIf config.nixplus.nvidia.enable
            && !config.hardware.nvidia.datacenter.enable [ "nvidia" ];
        };
      };
      ssv = nixosInput: {
        config.home-manager.sharedModules = [
          (homeManagerInput: {
            options.nixplus.ssv.enable = homeManagerInput.lib.options.mkOption {
              default = false;
              type = homeManagerInput.lib.types.bool;
            };
            config.home.stateVersion = homeManagerInput.lib.modules.mkIf
              homeManagerInput.config.nixplus.ssv.enable
              nixosInput.config.system.stateVersion;
          })
        ];
      };
    };
  };
}
