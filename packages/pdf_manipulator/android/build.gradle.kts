group = "com.deepanshuchaudhary.pdf_manipulator"
version = "1.0-SNAPSHOT"

buildscript {
    extra["kotlin_version"] = "2.1.0"
    val kotlin_version: String by extra
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://repo.itextsupport.com/android")
        }
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://repo.itextsupport.com/android")
        }
    }
}

plugins {
    id("com.android.library")
    kotlin("android")
}

android {
    namespace = "com.deepanshuchaudhary.pdf_manipulator"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        minSdk = 21
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("org.slf4j:slf4j-api:1.7.36")
    implementation("com.itextpdf.android:kernel-android:7.2.4")
    implementation("com.itextpdf.android:layout-android:7.2.4")
}
