{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs =
    { ... }:
    {
      nixosModules.nixplus = nixos: {
        options.nixplus = {
          dnwu.enable = nixos.lib.options.mkOption {
            default = false;
            type = nixos.lib.types.bool;
          };
          echm.enable = nixos.lib.options.mkOption {
            default = false;
            type = nixos.lib.types.bool;
          };
          nvidia.enable = nixos.lib.options.mkOption {
            default = false;
            type = nixos.lib.types.bool;
          };
        };
        config = {
          environment = {
            pathsToLink =
              nixos.lib.modules.mkIf
                (
                  nixos.config.nixplus.echm.enable
                  && builtins.any (user: user.xdg.portal.enable) (builtins.attrValues nixos.config.home-manager.users)
                )
                [
                  "/share/applications"
                  "/share/xdg-desktop-portal"
                ];
            variables = nixos.lib.modules.mkIf nixos.config.nixplus.nvidia.enable {
              "NVD_BACKEND" = "direct";
              "WLR_NO_HARDWARE_CURSORS" = "1";
            };
          };
          hardware.opengl.enable = nixos.lib.modules.mkIf (
            nixos.config.nixplus.echm.enable
            && builtins.any (user: user.wayland.windowManager.hyprland.enable) (
              builtins.attrValues nixos.config.home-manager.users
            )
          ) true;
          home-manager.sharedModules = [
            (home-manager: {
              options.nixplus = {
                cohm = home-manager.lib.options.mkOption { default = null; };
                metadata.wsl = home-manager.lib.options.mkOption {
                  default = nixos.config.wsl.enable or false;
                };
                hyprland = {
                  autoRun.enable = home-manager.lib.options.mkOption {
                    default = false;
                    type = home-manager.lib.types.bool;
                  };
                  portal.enable = home-manager.lib.options.mkOption {
                    default = false;
                    type = home-manager.lib.types.bool;
                  };
                };
                myshell = home-manager.lib.options.mkOption {
                  default = null;
                  type = home-manager.lib.types.nullOr home-manager.lib.types.package;
                };
                ssv.enable = home-manager.options.mkOption {
                  default = false;
                  type = home-manager.types.bool;
                };
              };
              config = {
                home.stateVersion = home-manager.modules.mkIf home-manager.nixplus.ssv.enable nixos.config.system.stateVersion;
                programs.bash = home-manager.lib.modules.mkMerge [
                  (home-manager.lib.modules.mkIf
                    (
                      home-manager.config.wayland.windowManager.hyprland.enable
                      && home-manager.config.nixplus.hyprland.autoRun.enable
                    )
                    {
                      enable = true;
                      initExtra =
                        home-manager.lib.modules.mkOrder 10100
                          "[[ $(tty) = /dev/tty* ]] && exec ${home-manager.config.wayland.windowManager.hyprland.finalPackage}/bin/${home-manager.config.wayland.windowManager.hyprland.finalPackage.meta.mainProgram}";
                    }
                  )
                  (home-manager.lib.modules.mkIf (home-manager.config.nixplus.myshell != null) {
                    enable = true;
                    initExtra =
                      let
                        sh = "${home-manager.config.nixplus.myshell}${home-manager.config.nixplus.myshell.shellPath}";
                      in
                      home-manager.lib.modules.mkOrder 10200
                        "[ \${MYSHELL_FORCE_BASH:-0} != 1 ] && SHELL=${sh} exec ${sh}";
                  })
                ];
                xdg.portal =
                  home-manager.lib.modules.mkIf
                    (
                      home-manager.config.wayland.windowManager.hyprland.enable
                      && home-manager.config.nixplus.hyprland.portal.enable
                    )
                    {
                      configPackages = [ home-manager.config.wayland.windowManager.hyprland.finalPackage ];
                      enable = true;
                      extraPortals = [
                        (home-manager.pkgs.xdg-desktop-portal-hyprland.override {
                          hyprland = home-manager.config.wayland.windowManager.hyprland.finalPackage;
                        })
                      ];
                    };
              };
            })
          ];
          security.polkit.enable = nixos.lib.modules.mkIf (
            nixos.config.nixplus.echm.enable
            && builtins.any (user: user.wayland.windowManager.hyprland.enable) (
              builtins.attrValues nixos.config.home-manager.users
            )
          ) true;
          services.udev = {
            extraRules = nixos.lib.modules.mkIf nixos.config.nixplus.dnwu.enable ''
              ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="disabled"
            '';
            xserver.videoDrivers = nixos.lib.modules.mkIf (
              nixos.config.nixplus.nvidia.enable && !nixos.config.hardware.nvidia.datacenter.enable
            ) [ "nvidia" ];
          };
          users.users = builtins.mapAttrs (_: user: user.nixplus.cohm) (
            nixos.lib.attrsets.filterAttrs (_: user: user.nixplus.cohm != null) nixos.config.home-manager.users
          );
        };
      };
    };
}
