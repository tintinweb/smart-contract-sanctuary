pragma solidity ^0.4.16;

// Original author: Cintix
// Modified by: Moonlambos, yakois


// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract RequestSale {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  // Maximum amount of user ETH contract will accept.
  uint256 public eth_cap = 300 ether;
  // The minimum amount of ETH that must be deposited before the buy-in can be performed.
  uint256 constant public min_required_amount = 60 ether;
  // The developer address.
  address public owner;
  // The crowdsale address. Settable by the owner.
  address public sale;
  // The token address. Settable by the owner.
  ERC20 public token;
  
  //Constructor. Sets the sender as the owner of the contract.
  function RequestSale() {
    owner = msg.sender;
  }

  // Allows the owner to set the crowdsale and token addresses.
  function set_addresses(address _sale, address _token) {
    // Only allow the owner to set the sale and token addresses.
    require(msg.sender == owner);
    // Only allow setting the addresses once.
    require(sale == 0x0);
    // Set the crowdsale and token addresses.
    sale = _sale;
    token = ERC20(_token);
  }
  
  // Allows any user to withdraw his tokens.
  function perform_withdraw() {
    // Tokens must be bought
    require(bought_tokens);
    // Retrieve current token balance of contract
    uint256 contract_token_balance = token.balanceOf(address(this));
    // Disallow token withdrawals if there are no tokens to withdraw.
    require(contract_token_balance == 0);
    // Store the user&#39;s token balance in a temporary variable.
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
    // Update the value of tokens currently held by the contract.
    contract_eth_value -= balances[msg.sender];
    // Update the user&#39;s balance prior to sending to prevent recursive call.
    balances[msg.sender] = 0;
    // Send the funds.  Throws on failure to prevent loss of funds.
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }
  
  // Allows any caller to get his eth refunded.
  function refund_me() {
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
    require(!bought_tokens);
    // The pre-sale address has to be set.
    require(sale != 0x0);
    // Throw if the contract balance is less than the minimum required amount.
    require(this.balance >= min_required_amount);
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Record the amount of ETH sent as the contract&#39;s current value.
    contract_eth_value = this.balance;
    // Transfer all the funds to the crowdsale address.
    require(sale.call.value(contract_eth_value)());
  }

  function upgrade_cap() {
    // Only the owner can raise the cap.
    if (msg.sender == owner) {
          // Raise the cap.
          eth_cap = 800 ether;
    }
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
    require(!bought_tokens);
    // Only allow deposits that won&#39;t exceed the contract&#39;s ETH cap.
    require(this.balance + msg.value < eth_cap);
    // Update records of deposited ETH to include the received amount.
    balances[msg.sender] += msg.value;
  }
}