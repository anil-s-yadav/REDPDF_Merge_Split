allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://repo.itextsupport.com/android")
        }
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir(rootProject.projectDir.parentFile.resolve("build").absolutePath))

subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.get().dir(name))
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
