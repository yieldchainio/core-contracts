use web3::transports::Http;
use web3::{Web3};
use web3::types::{U256, H160, Block, Transaction, BlockId, BlockNumber, U64};
use std::error::Error;

use crate::checksum_address::eth_checksum_encode;
// Import encode_eth_checksum from ./utils/checksum_address
mod checksum_address;

// Get the ETH balance of an address
async fn get_eth_balance(_address: &str) -> Result<(), Box<dyn Error>> {
    // ABI
    // let erc20_abi = File::open("/ABIs/ERC20.json").unwrap();

    // New Http Transport (JSON RPC)
    let transport: Http = Http::new("https://bsc-dataseed1.binance.org/")?;

    // new Web3 Provider using our JSON RPC URL
    let _web3: Web3<Http> = Web3::new(transport);

    // The address of our account
    let address: H160 = _address.parse().unwrap();

    println!("Your account address: {}", address); 

    // Get the ETH balance of our accou 
    let balance: U256 = _web3.eth().balance(address, None).await.unwrap();

    println!("Your ETH balance: {}", balance);
    
    Ok(())
}

// Get address transaction history by block iteration
async fn get_transaction_history(_address: &str, _block_amount: Option<u32>) -> Result<(), Box<dyn std::error::Error>> {
    // Address => Checksum Address
    let address: String = eth_checksum_encode(_address);
    // Our JSON RPC URL
    let http_transport: Http = Http::new("https://bsc-dataseed1.binance.org")?; 

    // New Web3 Provider using our JSON RPC URL
    let provider: Web3<Http> = Web3::new(http_transport);

    // The amount of blocks we will iterate over
    let mut amount_of_blocks: u32 = 1000;

    // If an optional amount of blocks is passed, we will get the history for that number of blocks
    if _block_amount.is_some() {amount_of_blocks = _block_amount.unwrap()};

    let mut i: u32 = 0;
    let starting_block_number: u32 = provider.eth().block_number().await.unwrap().as_u32();

    let mut transaction_history: Vec<Transaction> = Vec::new();


    while i < amount_of_blocks { 
        println!("Iterating Over New Block, iteration: {}", i);
       // Get current block number
       let current_block_number: u32 =  starting_block_number - i;


        // Get current block's details
       let block: Option<Block<Transaction>> = provider.eth().block_with_txs(BlockId::Number(BlockNumber::Number(current_block_number.into()))).await.unwrap();


        // Sufficient check if the block exists
       if let Some(block) = block {
        

        // the block's transactions
           let block_transactions = block.transactions.into_iter();

        // Iterate over all transactions
           for transaction in block_transactions { 
               let from_address = transaction.from;
               let to_address = transaction.to;

            if block.number.unwrap_or(U64::default()) == U64::from(25769807)  {
                println!("From: {:?}, To: {:?}", from_address, to_address);
            }

        // if the transaction's from / to address is the current address, push it into our transaction history array
            if eth_checksum_encode(&*from_address.unwrap_or(H160::default()).to_string()) == address || eth_checksum_encode(&*to_address.unwrap_or(H160::default()).to_string()) == address { 
                   transaction_history.push(transaction);
            }
           }
        }

        // Incremebt I for the loop
        i = i + 1;
    }







    if transaction_history.len() > 0 {
        println!("Transaction History:");
        println!("{:?}", transaction_history);
    } else {
        println!("No Transactions Found :(");
    }



    Ok(())
}

#[tokio::main]
async fn main() { 
   // Run the run function
   get_eth_balance("0x9492c313f500319e87937F1dA86b7938757627AD").await.unwrap();

   // Get Trnsaction history
   get_transaction_history("0x9492c313f500319e87937F1dA86b7938757627AD", Some(100)).await.unwrap();
}

