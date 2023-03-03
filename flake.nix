{
  description = "OpenTechLab Docker Example";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
  };

  outputs = { self, nixpkgs }: {
    packages."x86_64-linux" =
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in
      rec {
        dockerImage =
          pkgs.dockerTools.buildLayeredImage (let
            nginxPort = "80";
            nginxConf = pkgs.writeText "nginx.conf" ''
              user nginx nginx;
              daemon off;
              events {}
              http {
                server {
                  listen ${nginxPort};
                  location / {
                    root ${./html};
                  }
                }
              }
            '';

          in rec {
            name = "otl-nix-demo";
            tag = "latest";

            contents = with pkgs; [
              # Set up users and groups
              (writeTextDir "etc/shadow" ''
                root:!x:::::::
                nginx:!:::::::
              '')
              (writeTextDir "etc/passwd" ''
                root:x:0:0::/root:${runtimeShell}
                nginx:x:999:999::/home/nginx:
              '')
              (writeTextDir "etc/group" ''
                root:x:0:
                nginx:x:999:
              '')
              (writeTextDir "etc/gshadow" ''
                root:x::
                nginx:x::
              '')

              # Workaround: create directories required by nginx
              (writeTextDir "var/cache/nginx/.placeholder" "")
              (writeTextDir "var/log/nginx/.placeholder" "")
            ];

            config = {
              Cmd = [ "${pkgs.nginx}/bin/nginx" "-c" nginxConf ];
              ExposedPorts = {
                "${nginxPort}/tcp" = { };
              };
            };
          };
      };
  };
}
