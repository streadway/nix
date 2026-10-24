use std::env;
use std::fs::File;
use std::io::{self, Read};
use std::mem::size_of;
use std::process::Command;

const EV_KEY: u16 = 0x01;

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
        .ok_or_else(|| "Usage: push2talk <device> <key> [source]".to_string())?;
    let key = iter
        .next()
        .ok_or_else(|| "Usage: push2talk <device> <key> [source]".to_string())?;
    let source = iter
        .next()
        .unwrap_or_else(|| "@DEFAULT_AUDIO_SOURCE@".to_string());

    if iter.next().is_some() {
        return Err("Usage: push2talk <device> <key> [source]".to_string());
    }

    Ok(Config {
        device,
        key,
        source,
    })
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = parse_args(env::args().skip(1))?;
    let target_code = parse_key_code(&cfg.key)?;

    eprintln!(
        "push2talk: watching {} for {} (code 0x{target_code:03x}), controlling {}",
        cfg.device, cfg.key, cfg.source
    );

    let mut file = File::open(&cfg.device)
        .map_err(|e| format!("Failed to open input device '{}': {e}", cfg.device))?;

    let mut is_muted = true;
    let mut buf = [0u8; size_of::<InputEvent>()];
    loop {
        file.read_exact(&mut buf)?;
        let event = InputEvent::from_ne_bytes(&buf);

        if event.event_type != EV_KEY || event.code != target_code {
            continue;
        }

        let should_mute = match event.value {
            1 => false, // pressed -> unmute
            0 => true,  // released -> mute
            _ => continue,
        };

        if should_mute != is_muted {
            if let Err(e) = set_mute(&cfg.source, should_mute) {
                eprintln!("push2talk: failed to set mute={should_mute}: {e}");
            } else {
                is_muted = should_mute;
            }
        }
    }
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
            "/dev/input/event0".to_string(),
            "BTN_EXTRA".to_string(),
            "50".to_string(),
        ])
        .unwrap();
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
