{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      hello = pkgs.hello;

      kas = pkgs.python3.pkgs.buildPythonApplication {
        pname = "kas";
        version = "unstable-0555188";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "siemens";
          repo = "kas";
          rev = "055518846c3963114efbd0107bf3f2e59b4b3ba5";
          hash = "sha256-2a8LqOaCOXiINqtjU5DN2Z5AEA2+GmzXlrGvVJ9FhIA=";
        };

        build-system = [ pkgs.python3.pkgs.setuptools ];

        dependencies = with pkgs.python3.pkgs; [
          setuptools # pkg_resources is imported at runtime
          kconfiglib
          jsonschema
          distro
          pyyaml
          gitpython
          colorlog
        ];

        # Tests clone repos and need network
        doCheck = false;

        pythonImportsCheck = [ "kas" ];

        meta = {
          homepage = "https://github.com/siemens/kas";
          description = "Setup tool for bitbake based projects";
          license = pkgs.lib.licenses.mit;
          mainProgram = "kas";
        };
      };

      default = inputs.self.packages.${system}.hello;
    }) inputs.nixpkgs.legacyPackages;

    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        packages = [
          pkgs.pipx
          pkgs.git
        ];
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
