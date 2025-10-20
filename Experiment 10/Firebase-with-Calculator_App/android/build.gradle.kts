import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory
plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.4" apply false

}

buildscript {
    repositories {
        google()        // Required for Firebase plugin
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")   // Android Gradle plugin
        classpath("com.google.gms:google-services:4.4.4")    // Google Services plugin
    }
}

// Define new centralized build directory (optional, as you had before)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
