import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing configuration from key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Load Google Maps API keys from local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "org.ciclable.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "org.ciclable.app"
        // Minimum supported is Android 5.0 (API 21)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Default Google Maps API key (debug) - will be overridden by build types
        manifestPlaceholders["googleMapsApiKey"] = localProperties.getProperty("google.maps.key.debug") 
            ?: "AIzaSyAYm01FS25gOr_GWqxKIklWwJ2ZZt4PTc0" // fallback to existing key
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Use debug Google Maps API key
            manifestPlaceholders["googleMapsApiKey"] = localProperties.getProperty("google.maps.key.debug")
                ?: "AIzaSyAYm01FS25gOr_GWqxKIklWwJ2ZZt4PTc0" // fallback
        }
        
        release {
            // Use release signing if key.properties exists, otherwise use debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Use release Google Maps API key
            manifestPlaceholders["googleMapsApiKey"] = localProperties.getProperty("google.maps.key.release")
                ?: localProperties.getProperty("google.maps.key.debug") // fallback to debug key
                ?: "AIzaSyAYm01FS25gOr_GWqxKIklWwJ2ZZt4PTc0" // final fallback
            
            // Enable code shrinking and obfuscation for smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
