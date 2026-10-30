-- Hyprland config
-- "cmd" = Super.
--
-- Workspaces:
--   1-5  -> external TV (matched by description, not connector name)
--   6-10 -> eDP-1 (laptop display; 10 is the 0 key)

----------------
-- MONITORS   --
----------------

-- The DP connector number changes depending on which USB-C port/dock tunnel
-- is used, so match the panel by its (stable) description instead.
local external_monitor = "desc:Sceptre Tech Inc X322BV-HDR 0x01010101"

-- Internal 4K panel: 2560x1440 logical at 1.5x.
hl.monitor({ output = "eDP-1", mode = "3840x2160@60", position = "0x0", scale = 1.5 })

-- External TV: its EDID-preferred mode is 1360x768, which looks huge.
-- Force 1080p instead. Its 2560x1440 logical size sits to the right of eDP-1.
hl.monitor({ output = external_monitor, mode = "1920x1080@60", position = "2560x0", scale = 0.75 })

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

hl.workspace_rule({ workspace = "6", monitor = "eDP-1", default = true, persistent = true })
for i = 7, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", persistent = true })
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
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up eDP-1 5"),    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down eDP-1 5"),  { locked = true, repeating = true })

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
