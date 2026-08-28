"""recording_page.py -- the recording sheet as a readable page.

Same content as recording_sheet.py, built for a screen Kai can keep open while
recording rather than a file in the repo. Generated from barks.py for the same
reason the markdown sheet is: nothing may hold a second copy of the lines.

Usage:
    python recording_page.py
"""

import html
import io
import os
import re

from settings import TRIGGERS, MOMENT_BARKS, BARK_BUDGET
from barks import BARKS
from recording_sheet import DEVICE, WHEN, tags_from_source

HERE = os.path.dirname(os.path.abspath(__file__))

HEAD = """<title>Channel 6 Recording Script</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Oswald:wght@500;700&family=Barlow:ital,wght@0,400;0,600;1,400&family=IBM+Plex+Mono:wght@400;600&display=swap">
<style>
/* A studio prompter commits to one world: bright type on a dark monitor.
   Deliberately single-theme, so every colour is painted rather than inherited. */
:root{
  --ground:#0B0D0C;
  --panel:#141815;
  --panel-2:#1B211C;
  --edge:#2A322B;
  --ink:#E8F0E6;
  --dim:#818E7F;
  --gold:#F2B705;
  --live:#FF3B2F;
  --aud:#5FD3F3;
  --you:#F2B705;
  --turn:#C88BF5;
  --wrap:52rem;
}
*{box-sizing:border-box}
body{
  margin:0;
  background:var(--ground);
  color:var(--ink);
  font-family:"Barlow",system-ui,-apple-system,"Segoe UI",sans-serif;
  font-size:17px;
  line-height:1.55;
  -webkit-font-smoothing:antialiased;
}
/* The scanlines the game's own broadcast card uses. Faint enough to read through. */
body::before{
  content:"";
  position:fixed;
  inset:0;
  pointer-events:none;
  z-index:5;
  background:repeating-linear-gradient(
    to bottom,
    rgba(255,255,255,.035) 0 1px,
    transparent 1px 3px
  );
}
.wrap{max-width:var(--wrap);margin:0 auto;padding:0 1.25rem 5rem}

header{
  padding:3.5rem 0 2rem;
  border-bottom:1px solid var(--edge);
  margin-bottom:2.5rem;
}
.onair{
  display:inline-flex;
  align-items:center;
  gap:.55rem;
  font-family:"Oswald",Impact,sans-serif;
  font-weight:700;
  font-size:.78rem;
  letter-spacing:.22em;
  text-transform:uppercase;
  color:var(--live);
  border:1px solid var(--live);
  padding:.3rem .7rem;
  border-radius:2px;
}
.lamp{
  width:.5rem;height:.5rem;border-radius:50%;
  background:var(--live);
  box-shadow:0 0 8px var(--live);
  animation:blink 1.6s steps(1) infinite;
}
@keyframes blink{0%,55%{opacity:1}56%,100%{opacity:.25}}
@media (prefers-reduced-motion:reduce){.lamp{animation:none}}

h1{
  font-family:"Oswald",Impact,sans-serif;
  font-weight:700;
  font-size:clamp(2.4rem,7vw,4rem);
  line-height:.98;
  letter-spacing:-.01em;
  text-transform:uppercase;
  text-wrap:balance;
  margin:1.1rem 0 .6rem;
}
h1 .thin{font-weight:500;color:var(--dim);display:block;font-size:.44em;letter-spacing:.16em;margin-top:.7rem}
.lede{color:var(--dim);max-width:38rem;margin:0}
.lede strong{color:var(--ink);font-weight:600}

h2{
  font-family:"Oswald",Impact,sans-serif;
  font-weight:500;
  font-size:1.05rem;
  letter-spacing:.2em;
  text-transform:uppercase;
  color:var(--dim);
  margin:0 0 .9rem;
}

.brief{
  display:grid;
  gap:1.25rem;
  padding:1.5rem;
  background:var(--panel);
  border:1px solid var(--edge);
  border-radius:3px;
  margin-bottom:1.25rem;
}
.brief p{margin:0}
.brief p + p{margin-top:.6rem}
.keys{display:flex;flex-wrap:wrap;gap:.5rem}

.tag{
  font-family:"IBM Plex Mono",ui-monospace,monospace;
  font-size:.72rem;
  font-weight:600;
  letter-spacing:.08em;
  padding:.18rem .45rem;
  border-radius:2px;
  border:1px solid currentColor;
  white-space:nowrap;
}
.tag.aud{color:var(--aud)}
.tag.you{color:var(--you)}
.tag.turn{color:var(--turn)}
.keys .tag + span{color:var(--dim);font-size:.92rem}
.keydef{display:flex;align-items:center;gap:.5rem;flex:1 1 15rem}

ol.steps{margin:0;padding-left:1.2rem;color:var(--dim)}
ol.steps li{margin-bottom:.4rem}
ol.steps strong{color:var(--ink);font-weight:600}

section.moment{
  margin-top:2.75rem;
  border:1px solid var(--edge);
  border-radius:3px;
  overflow:hidden;
  background:var(--panel);
}
.slate{
  padding:1rem 1.25rem;
  background:var(--panel-2);
  border-bottom:1px solid var(--edge);
  display:flex;
  flex-wrap:wrap;
  gap:.4rem 1.25rem;
  align-items:baseline;
}
.slate h3{
  font-family:"Oswald",Impact,sans-serif;
  font-weight:700;
  font-size:1.35rem;
  letter-spacing:.05em;
  text-transform:uppercase;
  margin:0;
  flex:1 1 auto;
}
.count{
  font-family:"IBM Plex Mono",ui-monospace,monospace;
  font-size:.8rem;
  color:var(--gold);
  font-variant-numeric:tabular-nums;
}
.slate .meta{flex:1 1 100%;color:var(--dim);font-size:.92rem;margin:0}
.slate .meta code{
  font-family:"IBM Plex Mono",ui-monospace,monospace;
  color:var(--ink);
  font-size:.86em;
  background:rgba(255,255,255,.05);
  padding:.1rem .32rem;
  border-radius:2px;
}

.line{padding:1.25rem;display:grid;gap:.7rem}
.line + .line{border-top:1px solid var(--edge)}
.slug{display:flex;align-items:center;gap:.7rem;flex-wrap:wrap}
.num{
  font-family:"IBM Plex Mono",ui-monospace,monospace;
  font-size:.8rem;
  font-variant-numeric:tabular-nums;
  color:var(--dim);
}
.file{
  font-family:"IBM Plex Mono",ui-monospace,monospace;
  font-size:.84rem;
  font-weight:600;
  color:var(--gold);
}
blockquote{
  margin:0;
  font-size:1.32rem;
  line-height:1.35;
  font-weight:600;
  text-wrap:pretty;
  border-left:2px solid var(--gold);
  padding-left:1rem;
}
footer{
  margin-top:4rem;
  padding-top:1.5rem;
  border-top:1px solid var(--edge);
  color:var(--dim);
  font-size:.9rem;
}
footer code{font-family:"IBM Plex Mono",ui-monospace,monospace;color:var(--ink)}
</style>"""


def esc(text):
    return html.escape(text, quote=False)


def main():
    tags = tags_from_source()
    out = [HEAD, '<div class="wrap">']

    out.append("<header>")
    out.append('<span class="onair"><span class="lamp"></span>On Air</span>')
    out.append("<h1>Channel 6<span class=\"thin\">Announcer Recording Script</span></h1>")
    out.append(
        '<p class="lede"><strong>{} clips.</strong> {} of the host reacting to a moment in the arena, '
        'and {} sponsor reads he drops in when nothing is happening. '
        'Record each one and save it under the filename beside it.</p>'.format(
            BARK_BUDGET, MOMENT_BARKS, BARK_BUDGET - MOMENT_BARKS
        )
    )
    out.append("</header>")

    out.append('<div class="brief">')
    out.append("<div><h2>The voice</h2>")
    out.append(
        "<p>A hyped-up broadcast announcer who is openly making fun of the contestant. "
        "A radio DJ with big lungs and no sympathy. Cheerful on the surface, sarcastic "
        "underneath. He is never on the player's side.</p>"
    )
    out.append(
        "<p><strong>Repeated letters mean hold that sound.</strong> Only nine of the "
        "forty-one stretch a vowel, and never in Dead Air, where the joke is boredom.</p>"
    )
    out.append("</div>")

    out.append("<div><h2>Who he is talking to</h2><div class=\"keys\">")
    for cls, code, text in (
        ("aud", "AUD", "to the home audience, about the player"),
        ("you", "YOU", "straight at the player"),
        ("turn", "TURN", "starts on the audience, turns on the player mid-line"),
    ):
        out.append(
            '<div class="keydef"><span class="tag {}">{}</span><span>{}</span></div>'.format(
                cls, code, text
            )
        )
    out.append("</div></div>")

    out.append("<div><h2>Once the clips exist</h2><ol class=\"steps\">")
    out.append("<li>Import every clip into UEFN.</li>")
    out.append("<li>Make one <strong>MSS Play Random Oneshot</strong> preset per section below, holding that section's clips.</li>")
    out.append("<li>Place ten Audio Player devices, point each at one preset.</li>")
    out.append("<li>Wire each device to the <strong>device field</strong> named in that section.</li>")
    out.append("</ol></div>")
    out.append("</div>")

    number = 0
    for key, _count, _fires in TRIGGERS:
        lines = BARKS.get(key, [])
        out.append('<section class="moment">')
        out.append('<div class="slate">')
        out.append("<h3>{}</h3>".format(esc(key)))
        out.append('<span class="count">{} clip{}</span>'.format(len(lines), "" if len(lines) == 1 else "s"))
        out.append(
            '<p class="meta">Plays when {} &nbsp;&middot;&nbsp; device field <code>{}</code></p>'.format(
                esc(WHEN.get(key, "?")), esc(DEVICE.get(key, "?"))
            )
        )
        out.append("</div>")

        for spot, line in enumerate(lines, start=1):
            number += 1
            tag = tags.get(number, "AUD")
            name = "{}-{:02d}.wav".format(key.lower(), spot)
            out.append('<div class="line">')
            out.append('<div class="slug">')
            out.append('<span class="num">{:02d}</span>'.format(number))
            out.append('<span class="file">{}</span>'.format(esc(name)))
            out.append('<span class="tag {}">{}</span>'.format(tag.lower(), tag))
            out.append("</div>")
            out.append("<blockquote>{}</blockquote>".format(esc(line)))
            out.append("</div>")

        out.append("</section>")

    out.append(
        '<footer>Generated from <code>pipelines/announcer-bark/barks.py</code>, '
        'which holds the only copy of these lines. Re-run '
        '<code>python recording_page.py</code> after any change to them.</footer>'
    )
    out.append("</div>")

    path = os.path.join(HERE, "recording-script.html")
    io.open(path, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("Wrote {} ({} clips).".format(path, number))


if __name__ == "__main__":
    main()
