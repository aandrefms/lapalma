use std::collections::HashMap;

pub fn generate_elements() -> HashMap<String, String> {
    let microservices: HashMap<String, String> = [
        // ("Ping", "https://lapalma.com.br"),
        ("Server", "http://basic-app.apps.svc.cluster.local:5000"),
        ("Consumer", "http://consumer.apps.svc.cluster.local:5001"),
    ].iter().cloned().map(|(k, v)| (k.to_string(), v.to_string())).collect();
    microservices
}
