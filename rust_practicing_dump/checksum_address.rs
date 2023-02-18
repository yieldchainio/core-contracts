
use crypto::sha3::Sha3;
use crypto::digest::Digest;

 fn validate_eth_address(address: &str) -> bool {
    let check = eth_checksum_encode(&address);
    if check == address {
        return true;
    }
    eth_checksum_encode(&check) == check
}

 pub fn eth_checksum_encode(address: &str) -> String {
    let input = String::from(address.to_ascii_lowercase().trim_start_matches("0x"));
    let mut hasher = Sha3::keccak256();
    hasher.input_str(&input);
    let hex = hasher.result_str();
    let mut ret = String::with_capacity(42);
    ret.push_str("0x");
    for i in 0..40 {
        if u32::from_str_radix(&hex[i..i+1], 16).unwrap() > 7 {
            ret.push_str(&address[i+2..i+3].to_ascii_uppercase()); 
        } else {
            ret.push_str(&address[i+2..i+3]);
        }
    }
    ret
}