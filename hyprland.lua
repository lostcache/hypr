-- Hyprland config
-- "cmd" = Super.
--
-- Workspaces:
--   1-5  -> external monitor (matched by description, not connector name)
--   6-10 -> internal laptop panel (10 is the 0 key)

----------------
-- MONITORS   --
----------------

-- Connector names change depending on which USB-C port/dock is used, so match
-- the panels by their (stable) descriptions instead.
local internal_monitor = "desc:Sharp Corporation 0x148D"
local external_monitor = "desc:Samsung Electric Company LS32H70xE"

-- Internal 4K panel: 2560x1440 logical at 1.5x.
hl.monitor({ output = internal_monitor, mode = "3840x2160@60", position = "0x0", scale = 1.5 })

-- External 4K panel: native 4K, 2560x1440 logical at 1.5x so its size matches
-- the internal panel.
--
-- 4K60 needs all four DisplayPort lanes. A USB-C hub/dock uses two of the
-- four high-speed lanes for USB 3, leaving only two for DisplayPort, which
-- caps the link at 1440p60; 4K30 is advertised but does not even train.
--
-- This laptop has no DP output. For 4K60, connect a USB-C-to-DP cable (or a
-- USB-C-to-DP adapter plus the existing DP cable) directly to a left-side
-- Thunderbolt 3 port, bypassing the hub. The Dell USB-C-to-HDMI adapter plus
-- an HDMI cable also works if you have it.
hl.monitor({ output = external_monitor, mode = "3840x2160@60", position = "2560x0", scale = 1.5 })

-- On a two-lane port 4K60 cannot be applied. Fall back to the highest mode
-- that actually works so the desktop does not stay in Hyprland's failed-mode
-- fallback (1440p at an auto scale).
local function fallback_external_mode()
    local monitor = hl.get_monitor(external_monitor)
    if monitor and monitor.width < 3840 then
        hl.monitor({
            output = external_monitor,
            mode = "2560x1440@60",
            position = "2560x0",
            scale = 1,
        })
    end
end

-- Run after the monitor rules above have been applied (also on config reload).
hl.timer(fallback_external_mode, { type = "oneshot", timeout = 3000 })

----------------
-- LAYOUT     --
----------------

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
    },
})

----------------
-- ENV        --
----------------

-- Qt apps use their default style; no KDE platform theme.

----------------
-- AUTOSTART  --
----------------

-- Night light: always on at 3500K.
hl.on("hyprland.start", function()
    -- Propagate neutral GTK settings to Xwayland apps.
    hl.exec_cmd("xsettingsd")
    -- Only polkit agent currently installed; replace with hyprpolkitagent when available.
    hl.exec_cmd("/usr/libexec/kf6/polkit-kde-authentication-agent-1")
    hl.exec_cmd("noctalia -d")
end)

-- Apply the same fallback when the external display is hot-plugged.
hl.on("monitor.added", function()
    hl.timer(fallback_external_mode, { type = "oneshot", timeout = 2000 })
end)

-- Noctalia surfaces: use its own animations and blur.
hl.layer_rule({
    name = "noctalia",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
    no_anim = true,
    ignore_alpha = 0.5,
    blur = true,
    blur_popups = true,
})


----------------
-- WORKSPACES --
----------------

hl.workspace_rule({ workspace = "1", monitor = external_monitor, default = true, persistent = true })
for i = 2, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = external_monitor, persistent = true })
end

hl.workspace_rule({ workspace = "6", monitor = internal_monitor, default = true, persistent = true })
for i = 7, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = internal_monitor, persistent = true })
end

----------------
-- KEYBINDS   --
----------------

local mod = "SUPER"

-- Workspaces: Super+1..9, Super+0 for workspace 10.
-- Super+Shift+<num> moves the focused window there.
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Media keys (VIA layer 1 knobs: volume + brightness)
-- Send through Noctalia so its OSD is shown and external/DDC displays are handled.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up 5"),              { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down 5"),            { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),              { locked = true })

-- Noctalia's CLI needs the output name, so resolve it from the panel
-- description instead of hard-coding a connector name.
local brightness_keys_bound = false
local function bind_brightness_keys()
    if brightness_keys_bound then return end
    local monitor = hl.get_monitor(internal_monitor)
    local output = monitor and monitor.name
    if not output then return end
    brightness_keys_bound = true
    hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up " .. output .. " 5"),   { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down " .. output .. " 5"), { locked = true, repeating = true })
end

bind_brightness_keys()
hl.on("hyprland.start", bind_brightness_keys)

-- Launcher
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- Minimal window management
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())

hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Drag/resize with Super + mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
