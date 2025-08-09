use tonic_build;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Generate Rust code from protobuf definitions
    tonic_build::configure()
        .build_server(false) // We only need client code for lightwalletd
        .compile(
            &["proto/compact_formats.proto", "proto/service.proto"],
            &["proto"],
        )?;
    
    Ok(())
}