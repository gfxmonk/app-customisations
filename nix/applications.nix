{pkgs ? import <nixpkgs> {}}:
with pkgs;
let
	loadSessionVars = "eval \"$(session-vars --all --process gnome-shell --export)\"";
	apps = [
		# {
		# 	name = "Skype";
		# 	exec = "${skype}/bin/skype";
		# 	filename = "skype";
		# }
		# {
		# 	exec = "${calibre}/bin/calibre";
		# 	name = "Calibre";
		# 	filename = "calibre";
		# }

		{
			exec = writeScript "tilda-launch" ''#!${pkgs.bash}/bin/bash
				${loadSessionVars}
				export GTK_THEME='Adwaita:dark'
				export TERM_SOLARIZED=1
				exec ${pkgs.tilda}/bin/tilda
				'';
			name = "Tilda";
			filename = "tilda";
		}

		{
			exec = pkgs.writeScript "desktop-session" ''#!${pkgs.bash}/bin/bash
				reset-input &
				systemctl --user start desktop-session.target &
			'';
			name = "My desktop session";
			filename = "desktop-session";
		}
	];
in
stdenv.mkDerivation {
	name = "desktop-files";
	unpackPhase = "true";
	buildPhase = "true";
	installPhase = with lib; ''
		mkdir -p "$out/share/applications"
		cd "$out/share/applications"
		${
			concatStringsSep "\n" (map ({name, exec, filename ? null}:
				''
				cat > "${if filename == null then name else filename}.desktop" <<"EOF"
[Desktop Entry]
Version=1.0
Name=${name}
GenericName=${name}
Exec=${exec}
Terminal=false
Type=Application
Icon=${name}
EOF
				''
			) apps)
		}
	'';
}
