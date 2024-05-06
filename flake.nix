{
  outputs = {
    ...
  }: {
    homeModules.cohm = {
      lib,
      options,
      ...
    }: {
      options.core = lib.options.mkOption {
        default = {};
        type = builtins.head options.users.users.getSubModules;
      };
    };
    nixosModules.cohm = {
      config,
      lib,
      ...
    }: {
      options.nixplus.cohm.enable = lib.options.mkOption {
        default = false;
        type = lib.types.bool;
      };
      config.users.users = lib.modules.mkIf config.nixplus.cohm.enable (builtins.mapAttrs (_: user: user.core) config.home-manager.users);
    };
  };
}
