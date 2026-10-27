"""Small server-rendered surfaces. No framework or animation loop."""
from html import escape as e

GUIDE = "https://github.com/N3moStudio/Elsepin-Releases/blob/main/docs/CLOUD-GUIDE.md"


def form(action, fields, label, csrf="", secondary=False):
    hidden = f'<input type="hidden" name="csrf" value="{e(csrf)}">' if csrf else ""
    style = ' class="secondary"' if secondary else ""
    return f'<form method="post" action="{action}">{hidden}{fields}<button{style}>{e(label)}</button></form>'


def layout(title, content, *, csrf="", refresh="", scripts=False):
    script = '<script src="/nearby.js" defer></script>' if scripts else ""
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#6336c5">
<meta name="csrf" content="{e(csrf)}">{refresh}<title>Elsepin · {e(title)}</title>
<link rel="manifest" href="/manifest.webmanifest"><link rel="icon" href="/icon.svg" type="image/svg+xml">
<link rel="stylesheet" href="/style.css">{script}</head><body>
<a class="skip" href="#content">Skip to content</a><main id="content">
<header><a class="brand" href="/">Elsepin<span class="brand-dot" aria-hidden="true">.</span></a><span class="muted">Cloud helper</span></header>
<nav aria-label="Helper"><a href="/">Connections</a><a href="/nearby">Nearby alerts</a></nav>
{content}<footer><a href="{GUIDE}" rel="noreferrer">Setup guide on GitHub ↗</a></footer>
</main></body></html>'''


def nearby_page(engine, targets, csrf, error="", draft=None, new=False):
    fields = draft or {}
    notice = f'<p class="notice" role="alert">{e(error)}</p>' if error else ""
    content = '<div class="page-heading"><span class="eyebrow">NEARBY · EXPERIMENTAL</span><h1>Nearby alerts</h1><p class="muted">Get an alert when a shared location crosses your place.</p></div>' + notice
    content += '''<section><div class="section-title"><h2>Notifications</h2><span class="tag">This device</span></div>
<p id="push-status" role="status">Add this website to your Home Screen to enable iPhone alerts.</p>
<div class="actions"><button id="enable-push" type="button">Enable notifications</button>
<button id="test-push" type="button" class="secondary" hidden>Send test</button>
<button id="disable-push" type="button" class="secondary" hidden>Turn off here</button></div>
<noscript><p>Enable JavaScript to set up notifications. Rule controls still work below.</p></noscript></section>'''
    if engine.rules:
        content += '<div class="section-title"><h2>Your places</h2><a class="text-link" href="/nearby">Refresh</a></div>'
        for rule in engine.rules:
            event = rule["alert"]
            alerting = event and not event["acknowledged"] and engine.active(rule)
            status = "Needs your attention" if alerting else engine.status(rule)
            content += f'<section class="rule"><div class="section-title"><h3>{e(rule["name"])}</h3><span class="tag">{e(status)}</span></div>'
            verb = "Enters" if rule["event"] == "enter" else "Leaves"
            content += f'<p>{e(rule["targetName"])} · {verb} {rule["radius"]:g} m</p>'
            repeats = {"once": "Notify once", "5m": "Remind every 5 min", "2m": "Remind every 2 min", "1m": "Remind every minute", "escalate": "Remind after 5, 2, then every 1 min"}
            content += f'<p class="muted">{repeats[rule["repeat"]]}</p>'
            if event:
                from datetime import datetime, timezone
                at = datetime.fromtimestamp(event["at"], timezone.utc).strftime("%d %b, %H:%M UTC")
                content += f'<p class="muted">Last crossing: {at}{" · acknowledged" if event["acknowledged"] else ""}</p>'
            content += '<div class="actions">'
            if alerting:
                content += form('/nearby/stop', f'<input type="hidden" name="id" value="{rule["id"]}">', "Stop this alert", csrf)
            action = "pause" if engine.active(rule) else "resume"
            content += form('/nearby/'+action, f'<input type="hidden" name="id" value="{rule["id"]}">', "Pause rule" if action == "pause" else "Resume rule", csrf, True)
            content += form('/nearby/delete', f'<input type="hidden" name="id" value="{rule["id"]}">', "Delete", csrf, True) + '</div></section>'
        content += form('/nearby/pause-all', '', "Pause all alerts", csrf, True)
    else:
        content += '<section class="empty"><span class="empty-mark" aria-hidden="true">◎</span><h2>No places yet</h2><p class="muted">Add a place to start watching for arrivals or departures.</p></section>'
    if not new:
        if targets:
            content += '<a class="button" href="/nearby/new">Add a place</a>'
        else:
            content += '<p class="muted small">Connect a service first. Find My People is not available yet.</p><a class="button" href="/">Open connections</a>'
        content += '<p class="muted small">Free hosting may pause. After a restart, sign in and resume your rules.</p>'
        return layout("Nearby alerts", content, csrf=csrf, scripts=True)
    content = '<div class="page-heading"><a class="text-link" href="/nearby">← Your places</a><h1>Add a place</h1></div>' + notice
    content += '<section id="new-rule"><h2>New place alert</h2>'
    if not targets:
        content += '<p class="muted">Connect a service first. Find My People is not available yet.</p><a class="button" href="/">Open connections</a>'
    else:
        def options(values, selected):
            return ''.join(f'<option value="{e(value)}"{" selected" if value == selected else ""}>{e(label)}</option>' for value, label in values)
        def field(name, label, fallback, extra):
            return f'<label>{label}<input name="{name}" value="{e(str(fields.get(name, fallback)))}" {extra} required></label>'
        inputs = field("name", "Place name", "", 'maxlength="60" placeholder="Home, work, or a saved spot"')
        inputs += '<label>Shared location<select name="target">' + options([(k, t['name']+(' · Life360' if t['provider']=='life360' else ' · Find My Devices')) for k,t in targets.items()], fields.get('target')) + '</select></label>'
        inputs += '<div class="two-column">' + field('latitude', 'Latitude', '', 'type="number" step="any" min="-90" max="90" inputmode="decimal"') + field('longitude', 'Longitude', '', 'type="number" step="any" min="-180" max="180" inputmode="decimal"') + '</div>'
        inputs += '<p class="muted small">Fixed place coordinates. Your spoofed phone location is not used as “me”.</p>'
        inputs += '<div class="two-column">' + field('radius','Distance (metres)',500,'type="number" min="100" max="50000" step="1" inputmode="numeric"')
        inputs += '<label>Notify when<select name="event">'+options([('enter','Enters'),('leave','Leaves')],fields.get('event','enter'))+'</select></label></div>'
        inputs += '<label>Reminders<select name="repeat">'+options([('once','Only once'),('5m','Every 5 minutes'),('2m','Every 2 minutes'),('1m','Every minute'),('escalate','Gradually more often · 5 → 2 → 1 min')],fields.get('repeat','once'))+'</select></label>'
        inputs += '<label>Monitor for<select name="hours">'+options([('1','1 hour'),('4','4 hours'),('8','8 hours'),('24','24 hours'),('0','Until I pause')],fields.get('hours','1'))+'</select></label>'
        inputs += '<label class="check"><input type="checkbox" name="consent" value="yes" required> This person shares their location with me, and I have permission to use it here.</label>'
        inputs += '<p class="muted small">Repeat reminders stop when you press Stop this alert, pause the rule, or its monitoring time ends.</p>'
        content += form('/nearby/create', inputs, "Start monitoring", csrf)
    content += '</section><p class="muted small">Free hosting may pause. After a restart, sign in and resume your rules.</p>'
    return layout("Nearby alerts", content, csrf=csrf, scripts=False)
