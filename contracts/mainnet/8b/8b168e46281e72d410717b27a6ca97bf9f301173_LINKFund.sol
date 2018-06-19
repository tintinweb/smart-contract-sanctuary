pragma solidity ^0.4.13;

/*

LINK funds pool
========================

Original by: /u/Cintix
Modified by: moonlambos

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract LINKFund {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  
  // The minimum amount of ETH that must be deposited before the buy-in can be performed.
  // In this special case, the minimum has already been met, hence a 1 ETH minimum.
  uint256 constant public min_required_amount = 1 ether;
  
  // The maximum amount of ETH that can be deposited into the contract.
  // The owner in question was allowed 1000 ETH, but 300 has already been
  // contributed, leaving open another 700 ETH for this contract to take.
  uint256 constant public max_raised_amount = 700 ether;
  
  // The first block after which buy-in is allowed. Set in the contract constructor.
  uint256 public min_buy_block;
  
  // The first block after which a refund is allowed. Set in the contract constructor.
  uint256 public min_refund_block;
  
  // The crowdsale address. Address can be verified at: https://link.smartcontract.com/presales/39eb2b34-2dbf-4104-807d-12b9e3179cba
  address constant public sale = 0x7093128612a02e32F1C1aa44cCD7411d84EE09Ac;
  
  // The contract creator. Used to finalize the buying.
  address constant public creator = 0x0b11C7acb647eCa11d510eEc4fb0c17Bfccd6498;
  
  // Constructor. 
  function LINKFund() {
    // Buy-in allowed 3456 blocks (approx. 24 hours) after the contract is deployed.
    min_buy_block = block.number + 3456;
    
    // ETH refund allowed 864000 blocks (approx. 24 days) after the contract is deployed.
    min_refund_block = block.number + 864000;
  }
  
  // Allows any user to withdraw his tokens.
  // Takes the token&#39;s ERC20 address as argument as it is unknown at the time of contract deployment.
  function perform_withdraw(address tokenAddress) {
    // Disallow withdraw if tokens haven&#39;t been bought yet.
    if (!bought_tokens) throw;
    
    // Retrieve current token balance of contract.
    ERC20 token = ERC20(tokenAddress);
    uint256 contract_token_balance = token.balanceOf(address(this));
      
    // Disallow token withdrawals if there are no tokens to withdraw.
    if (contract_token_balance == 0) throw;
      
    // Store the user&#39;s token balance in a temporary variable.
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      
    // Update the value of tokens currently held by the contract.
    contract_eth_value -= balances[msg.sender];
      
    // Update the user&#39;s balance prior to sending to prevent recursive call.
    balances[msg.sender] = 0;

    // Send the funds.  Throws on failure to prevent loss of funds.
    if(!token.transfer(msg.sender, tokens_to_withdraw)) throw;
  }
  
  // Allows any user to get his eth refunded before the purchase is made or after approx. 20 days in case the devs refund the eth.
  function refund_me() {
    if (!bought_tokens) {
      // Only allow refunds when the tokens have been bought if the minimum refund block has been reached.
      if (block.number < min_refund_block) throw;
    }
    
    // Store the user&#39;s balance prior to withdrawal in a temporary variable.
    uint256 eth_to_withdraw = balances[msg.sender];
      
    // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
    balances[msg.sender] = 0;
      
    // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
    msg.sender.transfer(eth_to_withdraw);
  }
  
  // Buy the tokens. Sends ETH to the presale wallet and records the ETH amount held in the contract.
  function buy_the_tokens() {
    // Verify it&#39;s the creator calling.
	if (msg.sender != creator) throw;
	
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    
    // Throw if the contract balance is less than the minimum required amount
    if (this.balance < min_required_amount) throw;
    
    // Throw if the minimum buy-in block hasn&#39;t been reached
    if (block.number < min_buy_block) throw;
    
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    
    // Record the amount of ETH sent as the contract&#39;s current value.
    contract_eth_value = this.balance;

    // Transfer all the funds to the crowdsale address.
    creator.transfer(contract_eth_value);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Throw if the balance is larger than the maximum allowed amount.
    if (this.balance > max_raised_amount) throw;
    
    // Update records of deposited ETH to include the received amount but only if the buy-in hasn&#39;t been done yet.
    // This will handle an eventual refund from the devs while disallowing buy-ins after the deadline.
    if (!bought_tokens) {
      balances[msg.sender] += msg.value;
    }
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Delegate to the helper function.
    default_helper();
  }
}