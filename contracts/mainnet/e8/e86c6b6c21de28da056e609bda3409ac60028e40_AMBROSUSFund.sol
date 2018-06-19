pragma solidity ^0.4.13;

/*

Ambrosus funds pool
========================

Original by: moonlambos
Modified by: dungeon

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract AMBROSUSFund {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  
  // The minimum amount of ETH that must be deposited before the buy-in can be performed.
  // It&#39;s the min AND the max in the same time, since we must deposit exactly 300 ETH.
  uint256 constant public min_required_amount = 300 ether;
  
  // The first block after which buy-in is allowed. Set in the contract constructor.
  uint256 public min_buy_block = 4224446;
  
  // The crowdsale address.
  address constant public sale = 0x54e80390434b8BFcaBC823E9656c57d018C1dc77;

  
  // Allows any user to withdraw his tokens.
  // Takes the token&#39;s ERC20 address as argument as it is unknown at the time of contract deployment.
  //When the devs will send the tokens, you will have to call this function and pass the ERC20 token address of AMBROSUS
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
    if (bought_tokens) throw;

    // Store the user&#39;s balance prior to withdrawal in a temporary variable.
    uint256 eth_to_withdraw = balances[msg.sender];
      
    // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
    balances[msg.sender] = 0;
      
    // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
    msg.sender.transfer(eth_to_withdraw);
  }
  
  // Buy the tokens. Sends ETH to the presale wallet and records the ETH amount held in the contract.
  function buy_the_tokens() {
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    
    // Throw if the contract balance is less than the minimum required amount
    if (this.balance != min_required_amount) throw;
    
    // Throw if the minimum buy-in block hasn&#39;t been reached
    if (block.number < min_buy_block) throw;
    
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    
    // Record the amount of ETH sent as the contract&#39;s current value.
    contract_eth_value = this.balance;

    // Transfer all the funds to the crowdsale address.
    sale.transfer(contract_eth_value);
  }

  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    if (bought_tokens) throw;
    
    uint256 deposit = msg.value;
    if (this.balance > min_required_amount) {
      uint256 refund = this.balance - min_required_amount;
      deposit -= refund;
      msg.sender.transfer(refund);
    }
    balances[msg.sender] += deposit;
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Delegate to the helper function.
    default_helper();
  }
}