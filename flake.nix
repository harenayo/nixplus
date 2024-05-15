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
        in lib.modules.mkOrder 10000 "SHELL=${sh} exec ${sh}";
      };
    };
    lib.homeConfiguration = { modules, }: { imports = modules; };
    nixosModules = {
      cohm = { config, lib, options, ... }: {
        options.nixplus.cohm.enable = lib.options.mkOption {
          default = false;
          type = lib.types.bool;
        };
        config = lib.modules.mkIf config.nixplus.cohm.enable {
          home-manager.sharedModules = [
            ({ lib, ... }: {
              options.nixplus.cohm = lib.options.mkOption {
                default = builtins.head options.user.user.getSubModules;
              };
            })
          ];
          users.users = builtins.mapAttrs (_: user: user.nixplus.cohm)
            (lib.attrsets.filterAttrs (_: user: user ? nixplus.cohm)
              config.home-manager.users);
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
