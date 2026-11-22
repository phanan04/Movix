plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.twophim.movix.movix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.twophim.movix.movix"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            val keystorePath = keystoreProperties.getProperty("storeFile") ?: "keystore/movix.jks"
            val keystoreFile = file(keystorePath)
            if (keystoreFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: "movix"
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: "movix123456"
                storeFile = keystoreFile
                storePassword = keystoreProperties.getProperty("storePassword") ?: "movix123456"
            }
        }
    }

    buildTypes {
        release {
            val keystorePath = keystoreProperties.getProperty("storeFile") ?: "keystore/movix.jks"
            val keystoreFile = file(keystorePath)
            if (keystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
