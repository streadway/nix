{pkgs, ...}: let
  nothingToSay = pkgs.gnomeExtensions.nothing-to-say.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace extension.js \
          --replace-fail \
            '"notify::muted",
              () => {
                this._panel_button.icon.icon_name = get_icon_name(
                  this._microphone.muted,
                );
              },' \
            '"notify::muted",
              () => {
                const muted = this._microphone.muted;
                this._panel_button.icon.icon_name = get_icon_name(muted);
                if (this._microphone.stream) {
                  if (this._last_muted !== undefined && this._last_muted !== muted) {
                    this._show_mute_feedback(
                      muted,
                      this._settings.get_boolean("show-osd"),
                    );
                  }
                  this._last_muted = muted;
                }
              },' \
          --replace-fail \
            '_set_mute(mute, give_feedback) {
            this._microphone.muted = mute;
            this._show_mute_feedback(mute, give_feedback);
          }' \
            '_set_mute(mute, _give_feedback) {
            this._microphone.muted = mute;
          }'
      '';
  });
in {
  environment.systemPackages = [
    nothingToSay
  ];
}
