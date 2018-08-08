pragma solidity ^0.4.15;

/*

Ripio funds pool
========================

Original by: moonlambos
Modified by: dungeon

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract RipioFUND {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Store the number of times the voters individually voted.
  mapping (address => bool) public voters;
  // Keep track of the "for" votes for the address
  uint256 public for_votes = 0;
  // Keep track of the "agaisnt" votes for the address
  uint256 public agaisnt_votes = 0;


  // hash of the password required for voting or changing the sale address
  bytes32 hash_pwd = 0xad7b2f5d7e4850232ccfe2fe22d050eb6c444db4fe374207f901daab8fb7a3a8;
  
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  
  // The minimum amount of ETH that must be deposited before the buy-in can be performed.
  uint256 constant public min_required_amount = 150 ether;
  // The maximum amount of ETH allowed
  uint256 constant public max_amount = 12750 ether;
  
  // The crowdsale address.
  address public sale = 0x0;

  // Address of the creator
  address constant public creator = 0x9C728ff3Ef531CD2E46aF97c59a809761Ad5c987;
  
  // Allows any user to withdraw his tokens.
  // Takes the token&#39;s ERC20 address as argument as it is unknown at the time of contract deployment.
  //When the devs will send the tokens, you will have to call this function and pass the ERC20 token address of AMBROSUS
  function perform_withdraw(address tokenAddress) {
    // Disallow withdraw if tokens haven&#39;t been bought yet.
    require(bought_tokens);
    
    // Retrieve current token balance of contract.
    ERC20 token = ERC20(tokenAddress);
    uint256 contract_token_balance = token.balanceOf(address(this));
      
    // Disallow token withdrawals if there are no tokens to withdraw.
    require(contract_token_balance != 0);
      
    // Store the user&#39;s token balance in a temporary variable.
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      
    // Update the value of tokens currently held by the contract.
    contract_eth_value -= balances[msg.sender];
      
    // Update the user&#39;s balance prior to sending to prevent recursive call.
    balances[msg.sender] = 0;

    // Send the funds.  Throws on failure to prevent loss of funds.
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }
  
  // Allows any user to get his eth refunded before the purchase is made or after approx. 20 days in case the devs refund the eth.
  function refund_me() {
    require(!bought_tokens);

    // Store the user&#39;s balance prior to withdrawal in a temporary variable.
    uint256 eth_to_withdraw = balances[msg.sender];
      
    // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
    balances[msg.sender] = 0;
      
    // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
    msg.sender.transfer(eth_to_withdraw);
  }
  
  // Buy the tokens. Sends ETH to the presale wallet and records the ETH amount held in the contract.
  function buy_the_tokens(string password) {
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;

    require(hash_pwd == keccak256(password));
    // We need at least 51% of the votes for the proposed sale address in order to buy
    require (for_votes > agaisnt_votes);
    // Throw if the contract balance isn&#39;t between these two limits
    require(this.balance >= min_required_amount);
    require(this.balance <= max_amount);

    // Disallow buying in if the developer hasn&#39;t set the sale address yet.
    require(sale != 0x0);
    
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    
    // Record the amount of ETH sent as the contract&#39;s current value.
    contract_eth_value = this.balance;

    // Transfer all the funds to the crowdsale address.
    sale.transfer(contract_eth_value);
  }

  function change_sale_address(address _sale) {
    require(!bought_tokens);
    require(msg.sender == creator);
    sale = _sale;
    //reset the votes, in case a wrong addy was previously given
    for_votes = 0;
    agaisnt_votes = 0;
  }

  function vote_proposed_address(string string_vote) {
    require(!bought_tokens);
    // The voter musn&#39;t have voted before
    require(!voters[msg.sender]);
    // Disallow voting for the "void" address
    require(sale != 0x0);
    // Store the fact that the addy voted
    voters[msg.sender] = true;
    if (keccak256(string_vote) == keccak256("yes")){
      for_votes += 1;
    }
    if (keccak256(string_vote) == keccak256("no")){
      agaisnt_votes += 1;
    }
  }

  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    require(!bought_tokens);
    balances[msg.sender] += msg.value;
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Delegate to the helper function.
    default_helper();
  }
}