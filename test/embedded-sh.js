// node test/embedded-sh.js <outdir>
//
// Writes each shell script embedded in the QML (a `readonly property string
// <name>: [ ...lines ].join("\n")`) to <outdir>/<file>-<name>.sh, so the lint
// check can run `sh -n` and shellcheck on the code that writes users' files.
// Fails if a listed script is missing, so a rename can't drop it silently.

const fs = require("fs")
const path = require("path")

const SCRIPTS = [
  ["BoundedRead.qml", "script"],
  ["SafeWriter.qml", "script"],
  ["Service.qml", "installScript"],
  ["Panel.qml", "hookScript"],
]

const root = path.join(__dirname, "..")
const out = process.argv[2]
if (!out) { console.error("usage: node test/embedded-sh.js <outdir>"); process.exit(2) }
fs.mkdirSync(out, { recursive: true })

let missing = 0
for (const [file, name] of SCRIPTS) {
  const src = fs.readFileSync(path.join(root, file), "utf8")
  const m = src.match(new RegExp("readonly property string " + name + ": \\[([\\s\\S]*?)\\]\\.join"))
  if (!m) { console.error(`missing: ${file} ${name}`); missing++; continue }
  // The array literal is this repo's own source; comments are stripped first.
  const lines = eval("[" + m[1].replace(/^\s*\/\/.*$/gm, "") + "]")
  const dest = path.join(out, `${file}-${name}.sh`)
  fs.writeFileSync(dest, "#!/bin/sh\n" + lines.join("\n") + "\n")
  console.log("wrote " + dest)
}
process.exit(missing ? 1 : 0)
