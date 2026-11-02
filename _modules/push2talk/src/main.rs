use std::collections::HashSet;
use std::env;
use std::fs::{self, File};
use std::io::{self, Read};
use std::mem::size_of;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

const EV_KEY: u16 = 0x01;
const RESCAN_INTERVAL: Duration = Duration::from_secs(2);

#[repr(C)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct InputEvent {
    tv_sec: isize,
    tv_usec: isize,
    event_type: u16,
    code: u16,
    value: i32,
}

impl InputEvent {
    fn from_ne_bytes(buf: &[u8; size_of::<Self>()]) -> Self {
        let word = size_of::<isize>();
        let tv_sec = isize::from_ne_bytes(buf[0..word].try_into().unwrap());
        let tv_usec = isize::from_ne_bytes(buf[word..2 * word].try_into().unwrap());
        let event_type = u16::from_ne_bytes(buf[2 * word..2 * word + 2].try_into().unwrap());
        let code = u16::from_ne_bytes(buf[2 * word + 2..2 * word + 4].try_into().unwrap());
        let value = i32::from_ne_bytes(buf[2 * word + 4..2 * word + 8].try_into().unwrap());
        Self {
            tv_sec,
            tv_usec,
            event_type,
            code,
            value,
        }
    }
}

fn parse_key_code(name: &str) -> Result<u16, String> {
    let trimmed = name.trim();
    if let Some(hex) = trimmed.strip_prefix("0x").or_else(|| trimmed.strip_prefix("0X")) {
        return u16::from_str_radix(hex, 16).map_err(|e| format!("Invalid hex keycode '{name}': {e}"));
    }
    if let Ok(num) = trimmed.parse::<u16>() {
        return Ok(num);
    }
    match trimmed.to_ascii_uppercase().as_str() {
        "BTN_LEFT" | "MOUSE1" => Ok(0x110),
        "BTN_RIGHT" | "MOUSE2" => Ok(0x111),
        "BTN_MIDDLE" | "MOUSE3" => Ok(0x112),
        "BTN_SIDE" | "MOUSE8" => Ok(0x113),
        "BTN_EXTRA" | "MOUSE9" => Ok(0x114),
        "BTN_FORWARD" => Ok(0x115),
        "BTN_BACK" => Ok(0x116),
        "BTN_TASK" => Ok(0x117),
        "KEY_SPACE" => Ok(57),
        "KEY_CAPSLOCK" => Ok(58),
        "KEY_F1" => Ok(59),
        "KEY_F2" => Ok(60),
        "KEY_F3" => Ok(61),
        "KEY_F4" => Ok(62),
        "KEY_F5" => Ok(63),
        "KEY_F6" => Ok(64),
        "KEY_F7" => Ok(65),
        "KEY_F8" => Ok(66),
        "KEY_F9" => Ok(67),
        "KEY_F10" => Ok(68),
        "KEY_F11" => Ok(87),
        "KEY_F12" => Ok(88),
        "KEY_KPEQUAL" | "KEY_KP_EQUAL" => Ok(117),
        "KEY_LEFTCTRL" => Ok(29),
        "KEY_LEFTALT" => Ok(56),
        "KEY_LEFTMETA" => Ok(125),
        "KEY_RIGHTCTRL" => Ok(97),
        "KEY_RIGHTALT" => Ok(100),
        "KEY_RIGHTMETA" => Ok(126),
        "KEY_F13" => Ok(183),
        "KEY_F14" => Ok(184),
        "KEY_F15" => Ok(185),
        "KEY_F16" => Ok(186),
        "KEY_F17" => Ok(187),
        "KEY_F18" => Ok(188),
        "KEY_F19" => Ok(189),
        "KEY_F20" => Ok(190),
        "KEY_F21" => Ok(191),
        "KEY_F22" => Ok(192),
        "KEY_F23" => Ok(193),
        "KEY_F24" => Ok(194),
        _ => Err(format!("Unsupported key/button name: {name}")),
    }
}

fn capabilities_has_key(cap_str: &str, code: u16) -> bool {
    let bits_per_word = usize::BITS as usize;
    let word_index = (code as usize) / bits_per_word;
    let bit_index = (code as usize) % bits_per_word;

    cap_str
        .split_whitespace()
        .rev()
        .nth(word_index)
        .and_then(|word| usize::from_str_radix(word, 16).ok())
        .is_some_and(|val| (val & (1usize << bit_index)) != 0)
}

fn device_supports_key(event_name: &str, code: u16) -> bool {
    let cap_path = Path::new("/sys/class/input")
        .join(event_name)
        .join("device/capabilities/key");
    fs::read_to_string(cap_path)
        .map(|s| capabilities_has_key(&s, code))
        .unwrap_or(false)
}

fn device_display_name(dev_path: &Path) -> String {
    if let Some(event_name) = dev_path.file_name().and_then(|n| n.to_str()) {
        let name_path = Path::new("/sys/class/input")
            .join(event_name)
            .join("device/name");
        if let Ok(name) = fs::read_to_string(name_path) {
            let trimmed = name.trim();
            if !trimmed.is_empty() {
                return format!("{} ({trimmed})", dev_path.display());
            }
        }
    }
    dev_path.display().to_string()
}

fn discover_devices(device_spec: &str, target_code: u16) -> Vec<PathBuf> {
    let is_all = matches!(
        device_spec.trim().to_ascii_lowercase().as_str(),
        "" | "all" | "mice" | "*"
    );

    let mut resolved = Vec::new();
    let mut seen = HashSet::new();

    let mut add_path = |path: PathBuf| {
        if let Ok(canon) = fs::canonicalize(&path) {
            if seen.insert(canon.clone()) {
                resolved.push(canon);
            }
        }
    };

    if !is_all {
        let path = PathBuf::from(device_spec);
        if path.exists() {
            add_path(path);
        }
        return resolved;
    }

    for dir in ["/dev/input/by-id", "/dev/input/by-path"] {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path
                    .file_name()
                    .and_then(|n| n.to_str())
                    .is_some_and(|name| name.ends_with("-event-mouse"))
                {
                    add_path(path);
                }
            }
        }
    }

    if let Ok(entries) = fs::read_dir("/dev/input") {
        for entry in entries.flatten() {
            let path = entry.path();
            if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                if name.starts_with("event") && device_supports_key(name, target_code) {
                    add_path(path);
                }
            }
        }
    }

    resolved.sort();
    resolved
}

fn set_mute(source: &str, mute: bool) -> io::Result<()> {
    let status = Command::new("wpctl")
        .args(["set-mute", source, if mute { "1" } else { "0" }])
        .status()?;

    if !status.success() {
        return Err(io::Error::other(format!(
            "wpctl set-mute {source} exited with {status}"
        )));
    }
    Ok(())
}

struct Config {
    device: String,
    key: String,
    source: String,
}

fn parse_args<I: IntoIterator<Item = String>>(args: I) -> Result<Config, String> {
    let mut iter = args.into_iter();
    let device = iter
        .next()
        .ok_or_else(|| "Usage: push2talk <device|all> <key> [source]".to_string())?;
    let key = iter
        .next()
        .ok_or_else(|| "Usage: push2talk <device|all> <key> [source]".to_string())?;
    let source = iter
        .next()
        .unwrap_or_else(|| "@DEFAULT_AUDIO_SOURCE@".to_string());

    if iter.next().is_some() {
        return Err("Usage: push2talk <device|all> <key> [source]".to_string());
    }

    Ok(Config {
        device,
        key,
        source,
    })
}

enum WorkerEvent {
    Key { device: PathBuf, pressed: bool },
    Disconnected { device: PathBuf },
}

fn spawn_device_reader(
    device: PathBuf,
    mut file: File,
    target_code: u16,
    tx: mpsc::Sender<WorkerEvent>,
) {
    thread::spawn(move || {
        let mut buf = [0u8; size_of::<InputEvent>()];
        loop {
            if let Err(e) = file.read_exact(&mut buf) {
                eprintln!(
                    "push2talk: stopped watching {}: {e}",
                    device.display()
                );
                let _ = tx.send(WorkerEvent::Disconnected { device });
                break;
            }

            let event = InputEvent::from_ne_bytes(&buf);
            if event.event_type != EV_KEY || event.code != target_code {
                continue;
            }

            let pressed = match event.value {
                1 => true,
                0 => false,
                _ => continue,
            };

            if tx
                .send(WorkerEvent::Key {
                    device: device.clone(),
                    pressed,
                })
                .is_err()
            {
                break;
            }
        }
    });
}

fn sync_devices(
    cfg: &Config,
    target_code: u16,
    active_devices: &mut HashSet<PathBuf>,
    tx: &mpsc::Sender<WorkerEvent>,
) {
    for dev_path in discover_devices(&cfg.device, target_code) {
        if active_devices.contains(&dev_path) {
            continue;
        }
        match File::open(&dev_path) {
            Ok(file) => {
                eprintln!(
                    "push2talk: watching {} for {} (code 0x{target_code:03x}), controlling {}",
                    device_display_name(&dev_path),
                    cfg.key,
                    cfg.source
                );
                active_devices.insert(dev_path.clone());
                spawn_device_reader(dev_path, file, target_code, tx.clone());
            }
            Err(e) => {
                eprintln!(
                    "push2talk: failed to open input device '{}': {e}",
                    dev_path.display()
                );
            }
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = parse_args(env::args().skip(1))?;
    let target_code = parse_key_code(&cfg.key)?;

    let (tx, rx) = mpsc::channel();
    let mut active_devices = HashSet::new();
    let mut pressed_devices = HashSet::new();
    let mut is_muted = true;

    sync_devices(&cfg, target_code, &mut active_devices, &tx);

    loop {
        match rx.recv_timeout(RESCAN_INTERVAL) {
            Ok(WorkerEvent::Key { device, pressed }) => {
                if pressed {
                    pressed_devices.insert(device);
                } else {
                    pressed_devices.remove(&device);
                }
            }
            Ok(WorkerEvent::Disconnected { device }) => {
                active_devices.remove(&device);
                pressed_devices.remove(&device);
                sync_devices(&cfg, target_code, &mut active_devices, &tx);
            }
            Err(mpsc::RecvTimeoutError::Timeout) => {
                sync_devices(&cfg, target_code, &mut active_devices, &tx);
                continue;
            }
            Err(mpsc::RecvTimeoutError::Disconnected) => break,
        }

        let should_mute = pressed_devices.is_empty();
        if should_mute != is_muted {
            if let Err(e) = set_mute(&cfg.source, should_mute) {
                eprintln!("push2talk: failed to set mute={should_mute}: {e}");
            } else {
                is_muted = should_mute;
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_args() {
        assert!(parse_args(Vec::<String>::new()).is_err());
        assert!(parse_args(vec!["/dev/input/event0".to_string()]).is_err());

        let cfg = parse_args(vec![
            "/dev/input/event0".to_string(),
            "BTN_EXTRA".to_string(),
        ])
        .unwrap();
        assert_eq!(cfg.device, "/dev/input/event0");
        assert_eq!(cfg.key, "BTN_EXTRA");
        assert_eq!(cfg.source, "@DEFAULT_AUDIO_SOURCE@");

        let cfg_custom = parse_args(vec![
            "all".to_string(),
            "BTN_EXTRA".to_string(),
            "50".to_string(),
        ])
        .unwrap();
        assert_eq!(cfg_custom.device, "all");
        assert_eq!(cfg_custom.source, "50");

        assert!(parse_args(vec![
            "a".to_string(),
            "b".to_string(),
            "c".to_string(),
            "d".to_string(),
        ])
        .is_err());
    }

    #[test]
    fn test_parse_key_code() {
        assert_eq!(parse_key_code("BTN_EXTRA").unwrap(), 0x114);
        assert_eq!(parse_key_code("btn_side").unwrap(), 0x113);
        assert_eq!(parse_key_code("0x114").unwrap(), 0x114);
        assert_eq!(parse_key_code("276").unwrap(), 276);
        assert!(parse_key_code("UNKNOWN_KEY").is_err());
    }

    #[test]
    fn test_capabilities_has_key() {
        assert!(capabilities_has_key("7f0000 0 0 0 0", 0x114));
        assert!(capabilities_has_key("1f0000 0 0 0 0", 0x114));
        assert!(capabilities_has_key(
            "33eff 0 0 483ffff17aff32d bfd4444600000000 3f0001 130c730b17c007 ffbf7bfad941dfff febeffdfffefffff fffffffffffffffe",
            0x114
        ));
        assert!(!capabilities_has_key(
            "33eff 0 0 483ffff17aff32d bfd4444600000000 1 130c730b17c007 ffbf7bfad941dfff febeffdfffefffff ffffffffffffc002",
            0x114
        ));
        assert!(!capabilities_has_key("1000000000007 ff9f207ac14057ff febeffdfffefffff fffffffffffffffe", 0x114));
    }

    #[test]
    fn test_input_event_decode() {
        let mut raw = [0u8; size_of::<InputEvent>()];
        let word = size_of::<isize>();
        raw[2 * word..2 * word + 2].copy_from_slice(&EV_KEY.to_ne_bytes());
        raw[2 * word + 2..2 * word + 4].copy_from_slice(&0x114u16.to_ne_bytes());
        raw[2 * word + 4..2 * word + 8].copy_from_slice(&1i32.to_ne_bytes());

        let ev = InputEvent::from_ne_bytes(&raw);
        assert_eq!(ev.event_type, EV_KEY);
        assert_eq!(ev.code, 0x114);
        assert_eq!(ev.value, 1);
    }
}
