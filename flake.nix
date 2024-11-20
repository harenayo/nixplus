{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs =
    { nixpkgs, ... }:
    {
      lib.homeConfiguration =
        { modules }:
        {
          imports = modules;
        };
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
                metadata = {
                  hostPlatform = home-manager.lib.options.mkOption {
                    # https://github.com/NixOS/nixpkgs/blob/9cd675e112c8e8c38665be029740762e3009b51e/nixos/modules/misc/nixpkgs.nix#L184-L199
                    default = nixos.config.nixpkgs.hostPlatform;
                    type = home-manager.lib.types.either home-manager.lib.types.str home-manager.lib.types.attrs;
                  };
                  system = home-manager.lib.options.mkOption {
                    # https://github.com/NixOS/nixpkgs/blob/9cd675e112c8e8c38665be029740762e3009b51e/nixos/modules/misc/nixpkgs.nix#L283-L327
                    default =
                      if nixos.options.nixpkgs.hostPlatform.isDefined then null else nixos.config.nixpkgs.system;
                    type = home-manager.lib.types.str;
                  };
                  wsl = home-manager.lib.options.mkOption {
                    default = nixos.config.wsl.enable or false;
                    type = home-manager.lib.types.bool;
                  };
                };
                hyprland = {
                  autoRun.enable = home-manager.lib.options.mkOption {
                    default = false;
                    type = home-manager.lib.types.bool;
                  };
                  portal = {
                    enable = home-manager.lib.options.mkOption {
                      default = false;
                      type = home-manager.lib.types.bool;
                    };
                    package = home-manager.lib.options.mkOption {
                      default =
                        nixpkgs.legacyPacakges.${home-manager.config.nixplus.metadata.hostPlatform}.xdg-desktop-portal-hyprland;
                      type = home-manager.lib.types.package;
                    };
                  };
                };
                myshell = home-manager.lib.options.mkOption {
                  default = null;
                  type = home-manager.lib.types.nullOr home-manager.lib.types.package;
                };
                ssv.enable = home-manager.lib.options.mkOption {
                  default = false;
                  type = home-manager.lib.types.bool;
                };
              };
              config = {
                home.stateVersion = home-manager.lib.modules.mkIf home-manager.config.nixplus.ssv.enable nixos.config.system.stateVersion;
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
                        (home-manager.config.nixplus.hyprland.portal.package.override {
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
          services = {
            udev.extraRules = nixos.lib.modules.mkIf nixos.config.nixplus.dnwu.enable ''
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
