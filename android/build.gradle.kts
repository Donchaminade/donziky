import com.android.build.gradle.LibraryExtension
import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import javax.xml.parsers.DocumentBuilderFactory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// AGP 8 exige un namespace. Plusieurs plugins Flutter (dont on_audio_query 2.9)
// ne le déclarent que via l'attribut package du manifeste.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            if (namespace.isNullOrBlank()) {
                val manifest = file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = DocumentBuilderFactory.newInstance()
                        .newDocumentBuilder()
                        .parse(manifest)
                        .documentElement
                        .getAttribute("package")
                    if (pkg.isNotBlank()) {
                        namespace = pkg
                    }
                }
            }
        }
    }
}

// Le JDK 21 pousse Kotlin vers la cible 21 alors que les plugins visent
// Java 8 ou 17. La cible est lue au moment de la compilation, quand elle
// est figée, et javac n'est pas modifié.
subprojects {
    if (name == "app") return@subprojects
    tasks.withType<KotlinCompile>().configureEach {
        val kotlinTaskName = name
        compilerOptions.jvmTarget.set(project.provider {
            val javaName = kotlinTaskName.replace("Kotlin", "JavaWithJavac")
            val raw = (project.tasks.findByName(javaName) as? JavaCompile)?.targetCompatibility
            when (raw) {
                "1.8", "8" -> JvmTarget.JVM_1_8
                "11" -> JvmTarget.JVM_11
                "21" -> JvmTarget.JVM_21
                else -> JvmTarget.JVM_17
            }
        })
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
