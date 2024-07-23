use std::collections::HashMap;
use serde_json::json;
mod config;
use std::time::Duration;

#[tokio::main]
async fn main() {
    let microservices: HashMap<String, String> = config::generate_elements();
    let requests = perform_requests(microservices);
    let result: HashMap<String, String> = requests.await.expect("There was a problem with requests");
    // let value = send_slack_message(result.clone()).await;
}

async fn perform_requests(microservices: HashMap<String, String>) -> Result<HashMap<String, String>, Box<dyn std::error::Error>> {
    let mut responses: HashMap<String, String> = HashMap::new();
    let mut failures: HashMap<String, String> = HashMap::new();
    let client = reqwest::Client::builder()
        .use_rustls_tls()
        .build()?;
    for (key, value) in microservices.iter() {
        let resp = client          
            .get(value)
            .send()
            .await;

        match &resp {
            Err(e) => {
                failures.insert(key.to_string(), e.to_string());
            },
            Ok(response) => {
                if response.status().is_success() {
                    responses.insert(key.to_string(), response.status().to_string());
                }
                else {
                    failures.insert(key.to_string(), response.status().to_string());
                }
            }
        }
        
        if key.to_string() == "App" {
            println!("{:?}", resp);
        };
    }

    println! ("successes: {:#?}", responses);
    println! ("failures: {:#?}", failures);
    Ok(failures)
}

