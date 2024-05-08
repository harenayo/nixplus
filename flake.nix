{
  outputs = {
    ...
  }: {
    homeModules.cohm = {
      lib,
      ...
    }: {
      options.core = lib.options.mkOption {
        default = {};
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
