{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {

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

        # kas drops PATH from the environment it passes to subprocesses
        # (context.py only whitelists a few vars), so `git` cannot be found
        # on NixOS where there is no /usr/bin/git. Carry PATH over.
        postPatch = ''
          substituteInPlace kas/context.py \
            --replace-fail "'SSH_AUTH_SOCK'," "'SSH_AUTH_SOCK', 'PATH',"
        '';

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

        # kas shells out to git at runtime
        makeWrapperArgs = [
          "--prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git ]}"
        ];

        pythonImportsCheck = [ "kas" ];

        meta = {
          homepage = "https://github.com/siemens/kas";
          description = "Setup tool for bitbake based projects";
          license = pkgs.lib.licenses.mit;
          mainProgram = "kas";
        };
      };

      yaml2qemu = pkgs.python3.pkgs.buildPythonApplication {
        pname = "yaml2qemu";
        version = "0.1.0";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "vikingfacer";
          repo = "yaml2qemu";
          rev = "52e08bf6e1dba61098c004dec9198b68cddf1080";
          hash = "sha256-Wv066qeBdknnG1ZnRcG27thNc18UBk6s+NQuujbq4cY=";
        };

        build-system = [ pkgs.python3.pkgs.setuptools ];

        dependencies = with pkgs.python3.pkgs; [
          pyyaml
        ];

        # yaml2qemu looks up qemu-system-* at runtime.
        makeWrapperArgs = [
          "--prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.qemu ]}"
        ];

        pythonImportsCheck = [ "yaml2qemu" ];

        meta = {
          homepage = "https://github.com/vikingfacer/yaml2qemu";
          description = "Translate a YAML VM description into a QEMU command line";
          license = pkgs.lib.licenses.mit;
          mainProgram = "yaml2qemu";
        };
      };

      # Yocto/bitbake assume an FHS host (/bin/bash, /usr/bin/*). Wrap kas
      # plus the documented Yocto build-host requirements in an FHS sandbox.
      tiny-horse-env = pkgs.buildFHSEnv {
        name = "tiny-horse-env";
        targetPkgs =
          p: with p; [
            inputs.self.packages.${system}.kas
            git
            openssh
            gnumake
            gcc
            binutils
            gawk
            diffstat
            unzip
            zip
            texinfo
            chrpath
            socat
            cpio
            file
            which
            patch
            perl
            wget
            curl
            xz
            zstd
            lz4
            bzip2
            gzip
            gnutar
            python3
            python3Packages.pexpect
            python3Packages.jinja2
            python3Packages.gitpython
            python3Packages.jsonschema
            python3Packages.kconfiglib
            python3Packages.distro
            python3Packages.pyyaml
            python3Packages.colorlog
            iputils
            ncurses
            util-linux
            inetutils
            rpcsvc-proto
            pipx
          ];
        # OE-core's HOSTTOOLS check wants the legacy `lz4c` name, which
        # modern lz4 no longer installs.
        extraBuildCommands = ''
          ln -sf ${pkgs.lz4}/bin/lz4 $out/usr/bin/lz4c
          # Native recipes assume an FHS host with the C library headers in
          # /usr/include. buildFHSEnv only installs the out/lib/bin outputs of
          # targetPkgs, so glibc's dev headers are missing and things that probe
          # the literal path break (e.g. perl's Errno_pm.PL checks
          # /usr/include/errno.h to generate Errno.pm). nixpkgs already appends
          # `-idirafter /usr/include`, so adding the headers here only provides
          # a low-priority fallback.
          mkdir -p $out/usr/include
          cp -a ${pkgs.glibc.dev}/include/. $out/usr/include/
        '';
        profile = ''
          export LANG=C.UTF-8
          export LC_ALL=C.UTF-8
          # `nix develop`/nix-shell export TMPDIR pointing at a volatile
          # per-shell temp dir. Left alone it leaks into bitbake (it is in
          # BB_ENV_PASSTHROUGH_ADDITIONS) and overrides OE's own TMPDIR, so
          # the whole build (and its logs) lands somewhere that is deleted
          # when the shell exits. Drop it here so Yocto falls back to
          # ''${TOPDIR}/tmp (which is also pinned in kas-project.yml).
          unset TMPDIR
        '';
        runScript = "bash";
      };

    }) inputs.nixpkgs.legacyPackages;

    devShells = builtins.mapAttrs (system: pkgs: {
      # Drop straight into the FHS sandbox.
      #default = pkgs.mkShell {
      #  shellHook = ''
      #    exec ${inputs.self.packages.${system}.tiny-horse-env}/bin/tiny-horse-env
      #  '';
      #};

      # Plain shell (no FHS) for non-build kas commands.
      default = pkgs.mkShell {
        packages = [
          inputs.self.packages.${system}.kas
          inputs.self.packages.${system}.yaml2qemu
          pkgs.pipx
          pkgs.git
          pkgs.qemu
        ];
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
