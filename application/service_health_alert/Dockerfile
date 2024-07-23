FROM rust:1.68.2
COPY . .
RUN cargo build --release
CMD ["./target/release/service_health_alert"]