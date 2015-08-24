{pkgs ? import <nixpkgs> {}}:
let packagesExt = import ./packages { inherit pkgs; }; in
with packagesExt;
let
	isDarwin = stdenv.isDarwin;
	isLinux = stdenv.isLinux;
	bash = "#!${pkgs.bash}/bin/bash";
	wrapper = script: writeScript "wrapper" script;
	wrappers = {
		# ALL

	} // (if isLinux then {
		# LINUX only...
		"mount.ssh" = wrapper ''${bash}
			if [ "$#" -lt 2 ]; then
				echo "usage: mount.ssh [opts] remote local-dir"
				exit 2
			fi
			if [ ! -e "$2" ]; then
				echo "Making directory: $2"
				mkdir -p "$2"
			fi

			${sshfsFuse}/bin/sshfs "$@"
		'';
	} else {});
	tools = lib.remove null [
		git
		gsel
		ctags
		fish
		direnv
		silver-searcher
		gup
		vim_watch
		vim
		pythonPackages.ipythonLight
	];
	dirs = "bin etc share/man";
	system = import ./system.nix { pkgs = packagesExt; };
	applications = import ./applications.nix {inherit pkgs; };
in
stdenv.mkDerivation {
	name = "local";
	unpackPhase = "true";
	buildPhase = "true";
	installPhase = with lib; ''
		mkdir "$out"
		cd "$out"
		mkdir -p ${dirs}
		${
			# TODO: link all man files, too
			concatStringsSep "\n" (map (base:
				''
				for d in ${dirs}; do
					if [ -d "${base}/$d" ]; then
						echo "linking ${base}/$d ..."
						${pkgs.xlibs.lndir}/bin/lndir "${base}/$d" "$d"
					fi
				done
				''
			) tools)
		}

		${
			concatStringsSep "\n" (mapAttrsToList (name: script:
				"ln -sfn ${script} bin/${name}"
			) wrappers)
		}

		${
			if isLinux then ''
				mkdir -p share/systemd
				ln -s "${system.config.system.build.standalone-user-units}" share/systemd/user
				ln -s "${applications}" share/applications
			'' else ""
		}
	'';

	passthru.pkgs = packagesExt;
}
