{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }: {
    formatter = builtins.mapAttrs (_: pkgs: pkgs.nixfmt) nixpkgs.legacyPackages;
    homeModules = {
      hyprland = { config, lib, pkgs, ... }: {
        options.nixplus.hyprland = {
          autoRun.enable = lib.options.mkOption {
            default = false;
            type = lib.types.bool;
          };
          portal.enable = lib.options.mkOption {
            default = false;
            type = lib.types.bool;
          };
        };
        config = lib.modules.mkIf config.wayland.windowManager.hyprland.enable {
          programs.bash =
            lib.modules.mkIf config.nixplus.hyprland.autoRun.enable {
              enable = true;
              initExtra = lib.modules.mkOrder 10100
                "[[ $(tty) = /dev/tty* ]] && exec ${config.wayland.windowManager.hyprland.finalPackage}/bin/${config.wayland.windowManager.hyprland.finalPackage.meta.mainProgram}";
            };
          xdg.portal = lib.modules.mkIf config.nixplus.hyprland.portal.enable {
            configPackages =
              [ config.wayland.windowManager.hyprland.finalPackage ];
            enable = true;
            extraPortals = [
              (pkgs.xdg-desktop-portal-hyprland.override {
                hyprland = config.wayland.windowManager.hyprland.finalPackage;
              })
            ];
          };
        };
      };
      myshell = { config, lib, ... }: {
        options.nixplus.myshell =
          lib.options.mkOption { type = lib.types.package; };
        config.programs.bash = lib.modules.mkIf (config ? nixplus.myshell) {
          enable = true;
          initExtra = let
            sh = "${config.nixplus.myshell}${config.nixplus.myshell.shellPath}";
          in lib.modules.mkOrder 10200
          "[ $MYSHELL_FORCE_BASH != 1 ] && SHELL=${sh} exec ${sh}";
        };
      };
    };
    lib.homeConfiguration = { modules, }: { imports = modules; };
    nixosModules = {
      cohm = nixosInput: {
        config = {
          home-manager.sharedModules = [
            (homeManagerInput: {
              options.nixplus.cohm = homeManagerInput.lib.options.mkOption {
                type = nixosInput.options.users.users.type.nestedTypes.elemType;
              };
            })
          ];
          users.users = builtins.mapAttrs (_: user: user.nixplus.cohm)
            (nixosInput.lib.attrsets.filterAttrs (_: user: user ? nixplus.cohm)
              nixosInput.config.home-manager.users);
        };
      };
      dnwu = { config, lib, ... }: {
        options.nixplus.dnwu.enable = lib.options.mkOption {
          default = false;
          type = lib.types.bool;
        };
        config.services.udev.extraRules =
          lib.modules.mkIf config.nixplus.dnwu.enable ''
            ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="enabled"
          '';
      };
      echm = { config, lib, ... }: {
        options.nixplus.echm.enable = lib.options.mkOption {
          default = false;
          type = lib.types.bool;
        };
        config = lib.modules.mkIf config.nixplus.echm.enable
          (lib.modules.mkMerge [
            (lib.modules.mkIf (builtins.any (user: user.xdg.portal.enable)
              (builtins.attrValues config.home-manager.users)) {
                environment.pathsToLink =
                  [ "/share/applications" "/share/xdg-desktop-portal" ];
              })
            (lib.modules.mkIf
              (builtins.any (user: user.wayland.windowManager.hyprland.enable)
                (builtins.attrValues config.home-manager.users)) {
                  hardware.opengl.enable = true;
                  security.polkit.enable = true;
                })
          ]);
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
          services.xserver.videoDrivers = lib.modules.mkIf
            (config.nixplus.nvidia.enable
              && !config.hardware.nvidia.datacenter.enable) [ "nvidia" ];
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
