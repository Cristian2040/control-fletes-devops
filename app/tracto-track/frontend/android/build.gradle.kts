allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val buildDirFile = java.io.File(System.getProperty("java.io.tmpdir"), "tracto_track_build")
val newBuildDir: Directory = objects.directoryProperty().fileValue(buildDirFile).get()
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

val flutterBuildDir = file("../../build")
gradle.buildFinished {
    val srcDir = file("${newBuildDir.asFile}/app/outputs")
    if (srcDir.exists()) {
        copy {
            from(srcDir)
            into(file("$flutterBuildDir/app/outputs"))
        }
    }
}
