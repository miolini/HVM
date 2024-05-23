use std::process::Command;
use std::env;

fn main() {
    let cores = num_cpus::get();
    let tpcl2 = (cores as f64).log2().floor() as u32;

    println!("cargo:rerun-if-changed=src/hvm.c");
    println!("cargo:rerun-if-changed=src/hvm.cu");
    println!("cargo:rerun-if-changed=src/hvm.swift");
    println!("cargo:rerun-if-changed=src/main.swift");

    match cc::Build::new()
        .file("src/hvm.c")
        .opt_level(3)
        .warnings(false)
        .define("TPC_L2", &*tpcl2.to_string())
        .try_compile("hvm-c") {
        Ok(_) => println!("cargo:rustc-cfg=feature=\"c\""),
        Err(e) => {
            println!("cargo:warning=\x1b[1m\x1b[31mWARNING: Failed to compile hvm.c:\x1b[0m {}", e);
            println!("cargo:warning=Ignoring hvm.c and proceeding with build. \x1b[1mThe C runtime will not be available.\x1b[0m");
        }
    }

    if Command::new("nvcc").arg("--version").stdout(std::process::Stdio::null()).stderr(std::process::Stdio::null()).status().is_ok() {
        if let Ok(cuda_path) = env::var("CUDA_HOME") {
            println!("cargo:rustc-link-search=native={}/lib64", cuda_path);
        } else {
            println!("cargo:rustc-link-search=native=/usr/local/cuda/lib64");
        }

        cc::Build::new()
            .cuda(true)
            .file("src/hvm.cu")
            .flag("-diag-suppress=177")
            .flag("-diag-suppress=550")
            .flag("-diag-suppress=20039")
            .compile("hvm-cu");

        println!("cargo:rustc-cfg=feature=\"cuda\"");
    } else {
        println!("cargo:warning=\x1b[1m\x1b[31mWARNING: CUDA compiler not found.\x1b[0m \x1b[1mHVM will not be able to run on GPU.\x1b[0m");
    }

    if cfg!(target_os = "macos") {
        println!("Compiling Swift files...");
        let swiftc_status = Command::new("swiftc")
            .args(&["src/hvm.swift", "-emit-library", "-o", "target/libhvm_metal.dylib"])
            .status();

        match swiftc_status {
            Ok(status) if status.success() => {
                println!("Swift files compiled successfully.");
                println!("Checking if target/libhvm_metal.dylib exists...");
                if std::path::Path::new("target/libhvm_metal.dylib").exists() {
                    println!("Library found at target/libhvm_metal.dylib.");
                } else {
                    println!("Library not found at target/libhvm_metal.dylib.");
                }
                println!("cargo:rustc-link-search=native=target");
                println!("cargo:rustc-link-lib=dylib=hvm_metal");
                println!("cargo:rustc-cfg=feature=\"metal\"");
            },
            Ok(status) => {
                println!("cargo:warning=\x1b[1m\x1b[31mWARNING: Failed to compile Swift files with exit status: {}\x1b[0m", status);
            },
            Err(e) => {
                println!("cargo:warning=\x1b[1m\x1b[31mWARNING: Failed to compile Swift files:\x1b[0m {}", e);
            }
        }
    }
}