plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ch.flohulo.jublapp"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ch.flohulo.jublapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Fester Release-Schlüssel: Android installiert Updates nur, wenn die Signatur
    // gleich bleibt. Der Keystore kommt in der CI aus GitHub-Secrets (siehe
    // .github/workflows/app-build.yml) und liegt nie im Repository.
    val releaseKeystore = file("release.keystore")
    val releaseSigningAvailable =
        releaseKeystore.exists() &&
            !System.getenv("ANDROID_KEYSTORE_PASSWORD").isNullOrEmpty() &&
            !System.getenv("ANDROID_KEY_ALIAS").isNullOrEmpty() &&
            !System.getenv("ANDROID_KEY_PASSWORD").isNullOrEmpty()

    signingConfigs {
        if (releaseSigningAvailable) {
            create("release") {
                storeFile = releaseKeystore
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Ohne Keystore (lokal, Pull-Requests ohne Secrets) mit dem Debug-Schlüssel
            // signieren, damit `flutter run --release` weiter funktioniert. Solche
            // APKs lassen sich nicht als Update über eine Release-APK installieren.
            signingConfig =
                if (releaseSigningAvailable) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
