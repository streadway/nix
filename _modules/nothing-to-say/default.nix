{pkgs, ...}: let
  nothingToSay = pkgs.gnomeExtensions.nothing-to-say.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace extension.js \
          --replace-fail \
            'import * as Main from "resource:///org/gnome/shell/ui/main.js";' \
            'import * as Main from "resource:///org/gnome/shell/ui/main.js";
        import * as Volume from "resource:///org/gnome/shell/ui/status/volume.js";' \
          --replace-fail \
            '    this.active = null;
            this.stream = null;
            this.mixer_control = new Gvc.MixerControl({ name: "Nothing to say" });
            this.mixer_control.open();' \
            '    this.active = false;
            this.stream = null;
            this._active_timeout_id = null;
            this._active_target = null;
            this.mixer_control = Volume.getMixerControl();' \
          --replace-fail \
            '    let was_active = this.active;
            this.active = false;
            this.stream = this.mixer_control.get_default_source();
            if (this.stream) {
              this.stream.connectObject(
                "notify::is-muted",
                () => {
                  this.notify_muted();
                },
                this,
              );
              let recording_apps = this.mixer_control.get_source_outputs();
              for (let i = 0; i < recording_apps.length; i++) {
                let output_stream = recording_apps[i];
                let application_id = output_stream.get_application_id();
                if (EXCLUDED_APPLICATION_IDS.includes(application_id)) continue;
                this.active = true;
              }
            }
            this.notify_muted();
            if (this.active != was_active) {
              this.emit("notify::active");
            }' \
            '    this.stream = this.mixer_control.get_default_source();
            let is_active = false;
            if (this.stream) {
              this.stream.connectObject(
                "notify::is-muted",
                () => {
                  this.notify_muted();
                  this.refresh();
                },
                "notify::state",
                () => {
                  this.refresh();
                },
                this,
              );
              if (this.stream.state === Gvc.MixerStreamState.RUNNING) {
                let recording_apps = this.mixer_control.get_source_outputs();
                for (let i = 0; i < recording_apps.length; i++) {
                  let output_stream = recording_apps[i];
                  let application_id = output_stream.get_application_id();
                  if (EXCLUDED_APPLICATION_IDS.includes(application_id)) continue;
                  is_active = true;
                }
              }
            }
            this.notify_muted();
            if (is_active === this.active) {
              if (this._active_timeout_id) {
                GLib.Source.remove(this._active_timeout_id);
                this._active_timeout_id = null;
                this._active_target = null;
              }
            } else if (this._active_target !== is_active) {
              if (this._active_timeout_id) {
                GLib.Source.remove(this._active_timeout_id);
              }
              this._active_target = is_active;
              this._active_timeout_id = GLib.timeout_add(
                GLib.PRIORITY_DEFAULT,
                500,
                () => {
                  this._active_timeout_id = null;
                  this._active_target = null;
                  if (this.active !== is_active) {
                    this.active = is_active;
                    this.emit("notify::active");
                  }
                  return GLib.SOURCE_REMOVE;
                },
              );
            }' \
          --replace-fail \
            '  destroy() {
            if (this.stream) {
              this.stream.disconnectObject(this);
              this.stream = null;
            }
            this.mixer_control.disconnectObject(this);
            this.mixer_control.close();
          }' \
            '  destroy() {
            if (this._active_timeout_id) {
              GLib.Source.remove(this._active_timeout_id);
              this._active_timeout_id = null;
              this._active_target = null;
            }
            if (this.stream) {
              this.stream.disconnectObject(this);
              this.stream = null;
            }
            this.mixer_control.disconnectObject(this);
          }' \
          --replace-fail \
            '      this.icon = new St.Icon({
                icon_name: get_icon_name(false),
                style_class: "system-status-icon",
              });' \
            '      this.icon = new St.Icon({
                icon_name: get_icon_name(extension._microphone.muted),
                style_class: "system-status-icon",
              });' \
          --replace-fail \
            '    this._initialised = false; // flag to avoid notifications on startup' \
            '    this._initialised = true;
            this._ready_time = GLib.get_monotonic_time() + 1000000;
            this._patchQuickSettingsInput();' \
          --replace-fail \
            '    this._panel_button = new MicrophonePanelButton(this);' \
            '    this._last_muted = this._microphone.stream
              ? this._microphone.muted
              : undefined;
            this._panel_button = new MicrophonePanelButton(this);' \
          --replace-fail \
            '        if (this._microphone.active) {
                  this._panel_button.icon.add_style_class_name(
                    MICROPHONE_ACTIVE_STYLE_CLASS,
                  );
                } else {
                  this._panel_button.icon.remove_style_class_name(
                    MICROPHONE_ACTIVE_STYLE_CLASS,
                  );
                }
                this._panel_button.visible = this._icon_should_be_visible();
                if (
                  this._settings.get_boolean("show-osd") &&
                  (this._initialised || this._microphone.active)
                )' \
            '        this._update_active_style();
                this._panel_button.visible = this._icon_should_be_visible();
                if (
                  this._settings.get_boolean("show-osd") &&
                  !this._microphone.muted &&
                  GLib.get_monotonic_time() >= (this._ready_time ?? 0) &&
                  (this._initialised || this._microphone.active)
                )' \
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
                this._update_active_style();
                if (this._microphone.stream) {
                  const now = GLib.get_monotonic_time();
                  if (
                    this._last_muted !== undefined &&
                    this._last_muted !== muted &&
                    now >= (this._ready_time ?? 0)
                  ) {
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
          }' \
          --replace-fail \
            '    Main.panel._rightBox.remove_child(this._panel_button);' \
            '    this._unpatchQuickSettingsInput();
            this._last_muted = undefined;
            this._ready_time = 0;' \
          --replace-fail \
            '  disable() {' \
            '  _update_active_style() {
            if (!this._panel_button || !this._microphone) return;
            if (this._microphone.active && !this._microphone.muted) {
              this._panel_button.icon.add_style_class_name(
                MICROPHONE_ACTIVE_STYLE_CLASS,
              );
            } else {
              this._panel_button.icon.remove_style_class_name(
                MICROPHONE_ACTIVE_STYLE_CLASS,
              );
            }
          }

          _patchQuickSettingsInput() {
            const patch = (inputSlider) => {
              if (!inputSlider || inputSlider._nts_orig_maybeShowInput) return;
              inputSlider._nts_orig_maybeShowInput = inputSlider._maybeShowInput;
              inputSlider._nts_show_timeout_id = null;
              inputSlider._nts_show_target = null;
              inputSlider._maybeShowInput = function () {
                let showInput = false;
                if (this._stream) {
                  showInput =
                    this._control
                      .get_sources()
                      .some((s) => s.state === Gvc.MixerStreamState.RUNNING) &&
                    this._control
                      .get_source_outputs()
                      .some(
                        (o) =>
                          !EXCLUDED_APPLICATION_IDS.includes(
                            o.get_application_id(),
                          ),
                      );
                }
                if (this._showInput === undefined) {
                  this._showInput = showInput;
                  this._sync();
                  return;
                }
                if (showInput === this._showInput) {
                  if (this._nts_show_timeout_id) {
                    GLib.Source.remove(this._nts_show_timeout_id);
                    this._nts_show_timeout_id = null;
                    this._nts_show_target = null;
                  }
                } else if (this._nts_show_target !== showInput) {
                  if (this._nts_show_timeout_id) {
                    GLib.Source.remove(this._nts_show_timeout_id);
                  }
                  this._nts_show_target = showInput;
                  this._nts_show_timeout_id = GLib.timeout_add(
                    GLib.PRIORITY_DEFAULT,
                    500,
                    () => {
                      this._nts_show_timeout_id = null;
                      this._nts_show_target = null;
                      if (this._showInput !== showInput) {
                        this._showInput = showInput;
                        this._sync();
                      }
                      return GLib.SOURCE_REMOVE;
                    },
                  );
                }
              };
              inputSlider._maybeShowInput();
            };
            const qs = Main.panel.statusArea.quickSettings;
            if (qs?._volumeInput?._input) {
              patch(qs._volumeInput._input);
            } else {
              this._qs_wait_id = GLib.timeout_add(
                GLib.PRIORITY_DEFAULT,
                100,
                () => {
                  const slider =
                    Main.panel.statusArea.quickSettings?._volumeInput?._input;
                  if (slider) {
                    this._qs_wait_id = null;
                    patch(slider);
                    return GLib.SOURCE_REMOVE;
                  }
                  return GLib.SOURCE_CONTINUE;
                },
              );
            }
          }

          _unpatchQuickSettingsInput() {
            if (this._qs_wait_id) {
              GLib.Source.remove(this._qs_wait_id);
              this._qs_wait_id = null;
            }
            const slider =
              Main.panel.statusArea.quickSettings?._volumeInput?._input;
            if (slider?._nts_orig_maybeShowInput) {
              if (slider._nts_show_timeout_id) {
                GLib.Source.remove(slider._nts_show_timeout_id);
                slider._nts_show_timeout_id = null;
                slider._nts_show_target = null;
              }
              slider._maybeShowInput = slider._nts_orig_maybeShowInput;
              delete slider._nts_orig_maybeShowInput;
              slider._maybeShowInput();
            }
          }

          disable() {'
      '';
  });
in {
  environment.systemPackages = [
    nothingToSay
  ];
}
