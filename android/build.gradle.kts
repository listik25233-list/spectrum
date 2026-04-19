allprojects {
    repositories {
        google()
        mavenCentral()
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

// Этот блок исправляет проблему с Namespace в старых библиотеках (таких как isar_flutter_libs)
subprojects {
    plugins.configureEach {
        if (this is com.android.build.gradle.api.AndroidBasePlugin || this.javaClass.name.startsWith("com.android.build.gradle")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.let {
                it.buildToolsVersion = "34.0.0"
                it.ndkVersion = "28.2.13676358"
                if (it.namespace == null) {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val xml = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]+)\"").find(xml)
                        if (packageMatch != null) {
                            it.namespace = packageMatch.groupValues[1]
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
