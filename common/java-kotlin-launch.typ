#import "escape.typ": *


#let launch(
  current,
  java-files: (:),
  kotlin-files: (:),
  main: auto,
  libraries: (),
  group: "org.ldemetrios",
  build: auto,
  settings: auto,
  dependencies: (),
  resources: (:),
) = {
  let main = if main != auto {
    main
  } else {
    group + ".MainKt"
  }

  let build = if build != auto {
    build
  } else {
    ```
    plugins {
        kotlin("jvm") version "2.0.0"
        application
    }

    application {
        mainClass = "$$main$$"
    }

    group = "$$group$$"
    version = "1.0"

    repositories {
        mavenCentral()
        mavenLocal()
    }

    tasks.jar {
        manifest {
            attributes["Main-Class"] = "$$main$$"
        }
    }
    dependencies {
        testImplementation(kotlin("test"))
        $$deps$$
    }
    ```.text
  }

  let dependencies = dependencies.map(it => "implementation(\"" + it + "\")").join("\n")
  if (dependencies == none) {
    dependencies = ""
  }
  build = build.replace("$$main$$", main).replace("$$group$$", group).replace("$$deps$$", dependencies)

  let settings = if settings != auto {
    settings
  } else {
    ```
        plugins {
          id("org.gradle.toolchains.foojay-resolver-convention") version "0.5.0"
      }
      rootProject.name = "untitled"
    ```.text
  }
  let setup = (
    "build.gradle.kts": build,
    "settings.gradle.kts": settings,
  )
  for (path, java) in java-files {
    setup.insert("src/main/java/" + path, java)
  }
  for (path, kotlin) in kotlin-files {
    setup.insert("src/main/kotlin/" + path, kotlin)
  }
  for (path, res) in resources {
    setup.insert(path, res)
  }

  escape(
    current: current,
    setup: setup,
    command("gradle", "assemble", error: file-format("raw")),
    command(
      ..("java", "-jar", "build/libs/untitled-1.0.jar"),
      output: file-format("conjoined-raw", color: "000000"),
      error: file-format("conjoined-raw", color: "ff0000"),
    ),
    handler: it => {
      let result = if it.at(0).code != 0 {
        // Compilation error
        let log = it.at(0).output.stderr.text.split("FAILURE: Build failed with an exception").at(0).split(
          regex("[\r\n]"),
        ).map(line => {
          if line.contains("src/main/kotlin") {
            line.split("src/main/kotlin/").at(1)
          } else {
            line
          }
        })
        text(fill: red, log.join("\n"))
      } else {
        // Success
        text(size: 1.25em, it.at(1).output)
      }
      pad(left: 1em, block(stroke: (left: gray), inset: (left: 1em, rest: .5em), result))

    },
  )
}

#let single-file-sample(
  current,
  dependencies: (),
  add-imports: "",
  start-marker: none,
  end-marker: none,
  show-code: true,
) = doc => {
  let code-itself(it) = if show-code {
    let it = it.text + "\n"
    let code = if start-marker != none and end-marker != none {
      it.split(start-marker).slice(1, none).map(part => part.split(end-marker).at(0)).join("\n")
    } else if start-marker != none {
      let arr = it.split(start-marker)
      arr.at(arr.len() - 1)
    } else if end-marker != none {
      it.split(start-marker).at(0)
    } else {
      it
    }
    if (code == none) {
      code = ""
    }
    block(text(size: 1.25em, raw(lang: "java", code)), stroke: black, inset: 1em, width: 100%)
  } else {
    none
  }

  show selector(<code>).and(raw.where(lang: "kt")): it => {
    code-itself(it)

    let imports = it.text.split(regex("[\n\r]")).filter(it => it.starts-with("import"))
    let others = it.text.split(regex("[\n\r]")).filter(it => not imports.contains(it)).join("\n")

    let code = "package org.ldemetrios\n\n" + add-imports + imports.join("\n") + "\nfun main() {\n" + others + "\n}\n"
    launch(
      current,
      kotlin-files: ("org/ldemetrios/Main.kt": code),
      dependencies: dependencies,
    )
  }

  show selector(<file>).and(raw.where(lang: "kt")): it => {
    code-itself(it)

    launch(
      current,
      kotlin-files: ("org/ldemetrios/Main.kt": "package org.ldemetrios\n\n" + it.text),
      dependencies: dependencies,
    )
  }

  show selector(<code>).and(raw.where(lang: "java")): it => {
    code-itself(it)

    let imports = it.text.split(regex("[\n\r]")).filter(it => it.starts-with("import"))
    let others = it.text.split(regex("[\n\r]")).filter(it => not imports.contains(it)).join("\n")

    let code = (
      "package org.ldemetrios;\n",
      add-imports,
      imports.join("\n"),
      "\nclass Main {",
      "    public static void main(String[] args) {",
      others,
      "    }",
      "}",
    ).join("\n")
    launch(
      current,
      main: "org.ldemetrios.Main",
      java-files: ("org/ldemetrios/Main.java": code),
      dependencies: dependencies,
    )
  }

  show selector(<class>).and(raw.where(lang: "java")): it => {
    code-itself(it)

    let imports = it.text.split(regex("[\n\r]")).filter(it => it.starts-with("import"))
    let others = it.text.split(regex("[\n\r]")).filter(it => not imports.contains(it)).join("\n")

    let code = (
      "package org.ldemetrios;\n",
      add-imports,
      imports.join("\n"),
      "\nclass Main {",
      others,
      "}",
    ).join("\n")
    launch(
      current,
      java-files: ("org/ldemetrios/Main.java": code),
      main: "org.ldemetrios.Main",
      dependencies: dependencies,
    )
  }

  doc

  finish-escape()
}

// java -jar ~/Workspace/_artifacts/TypstEscape.jar --delay 5000 --ask-each . --allow gradle --allow java

#show: single-file-sample(
  "/common/java-kotlin-launch.typ",
  add-imports: "import sun.misc.Unsafe;\nimport java.lang.reflect.*;",
)

```kt
val name = "Kotlin"
println("Hello, " + name + "!")

for (i in 1..5) {
    println("i = $i")
    System.err.println("j = $i")
}
``` <code>

```kt
fun a() = "A"
fun main() = println(a())
``` <file>

```java
import java.util.HashMap;

System.out.println("Hello, World");
HashMap<String, String> map = new HashMap<>();
map.put("a", "b");
System.out.println(map.get("a"));
``` <code>
