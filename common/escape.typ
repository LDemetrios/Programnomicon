

#let try-catch(lbl, key, try, catch) = locate(loc => {
  let path-label = label(lbl)
  let first-time = query(locate(_ => { }).func(), loc).len() == key
  if first-time or query(path-label, loc).len() > 0 {
    [#try()#path-label]
  } else {
    catch()
  }
})

#let escape-keys = state("escape-keys", 0)

#let escape(
  current: none,
  setup: (:),
  ..commands,
  output-file: auto,
  handler: it => [#it],
  replacement: [`Missing information`],
) = {
  assert(current != none or output-file != auto)
  escape-keys.display(key => {
    let file = if output-file == auto {
      current + str(key) + ".typesc"
    } else {
      output-file
    }
    [
      #metadata((
        setup: setup,
        commands: commands.pos(),
        output: file,
      )) #label("typst-key-" + str(key))
    ]
    if sys.inputs.at("typst-escape-working", default: "false") == "true" {
      []
    } else {
      handler(eval(read(file)))
    }
  })
  escape-keys.update(it => it + 1)
}

#let command(..entries, output: none, error: none) = (
  command: entries.pos(),
  output-spec: output,
  error-spec: error,
)

#let file-format(format, color: "000000") = (
  format: format,
  color: color,
)

#let finish-escape() = escape-keys.display(it => [
  #metadata(
    range(it).map(jt => "typst-key-" + str(jt)),
  ) <typst-escape-keys>
])

//// Example:
//
//#escape(
//  setup: (
//    "build.gradle.kts": build.text,
//    "settings.gradle.kts": settings.text,
//    "src/main/kotlin/Main.kt": code.text,
//  ),
//  command("gradle", "assemble"),
//  command(
//    ..("java", "-jar", "build/libs/untitled-1.0-SNAPSHOT.jar"),
//    output: file-format("conjoined-raw"),
//    error: file-format("conjoined-raw", color: "ff0000"),
//  ),
//  handler: it => it.at(1).output
//)
//
//#finish-escape()

