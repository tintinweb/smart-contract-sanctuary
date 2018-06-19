pragma solidity ^0.4.13;

/*

Cobinhood Presale Buyer
========================

Buys Cobinhood tokens from the crowdsale on your behalf.
Author: /u/troythus, @troyth
Forked from: /u/Cintix

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract CobinhoodBuyer {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Track whether the contract has received the tokens yet.
  bool public received_tokens;
  // Track whether the contract has sent ETH to the presale contract yet.
  bool public purchased_tokens;
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  // Emergency kill switch in case a critical bug is found.
  bool public kill_switch;

  // SHA3 hash of kill switch password.
  bytes32 password_hash = 0xe3ce8892378c33f21165c3fa9b1c106524b2352e16ea561d943008f11f0ecce0;
  // Latest time contract is allowed to buy into the crowdsale.
  uint256 public latest_buy_time = 1505109600;
  // Maximum amount of user ETH contract will accept.  Reduces risk of hard cap related failure.
  uint256 public eth_cap = 299 ether;
  // Minimum amount of user ETH contract will accept.  Reduces risk of hard cap related failure.
  uint256 public eth_min = 149 ether;
  // The developer address.
  address public developer = 0x0575C223f5b87Be4812926037912D45B31270d3B;
  // The fee claimer&#39;s address.
  address public fee_claimer = 0x9793661F48b61D0b8B6D39D53CAe694b101ff028;
  // The crowdsale address.
  address public sale = 0x0bb9fc3ba7bcf6e5d6f6fc15123ff8d5f96cee00;
  // The token address.  Settable by the developer once Cobinhood announces it.
  ERC20 public token;

  // Allows the developer to set the token address because we don&#39;t know it yet.
  function set_address(address _token) {
    // Only allow the developer to set the token addresses.
    require(msg.sender == developer);
    // Set the token addresse.
    token = ERC20(_token);
  }

  // Developer override of received_tokens to make sure tokens aren&#39;t stuck.
  function force_received() {
      require(msg.sender == developer);
      received_tokens = true;
  }

  // Anyone can call to see if tokens have been received, and then set the flag to let withdrawls happen.
  function received_tokens() {
      if( token.balanceOf(address(this)) > 0){
          received_tokens = true;
      }
  }

  // Allows the developer or anyone with the password to shut down everything except withdrawals in emergencies.
  function activate_kill_switch(string password) {
    // Only activate the kill switch if the sender is the developer or the password is correct.
    require(msg.sender == developer || sha3(password) == password_hash);

    // Irreversibly activate the kill switch.
    kill_switch = true;
  }

  // Withdraws all ETH deposited or tokens purchased by the given user.
  function withdraw(address user){
    // Only allow withdrawals after the contract has had a chance to buy in.
    require(received_tokens || now > latest_buy_time);
    // Short circuit to save gas if the user doesn&#39;t have a balance.
    if (balances[user] == 0) return;
    // If the contract failed to buy into the sale, withdraw the user&#39;s ETH.
    if (!received_tokens || kill_switch) {
      // Store the user&#39;s balance prior to withdrawal in a temporary variable.
      uint256 eth_to_withdraw = balances[user];
      // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
      balances[user] = 0;
      // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
      user.transfer(eth_to_withdraw);
    }
    // Withdraw the user&#39;s tokens if the contract has purchased them.
    else {
      // Retrieve current token balance of contract.
      uint256 contract_token_balance = token.balanceOf(address(this));
      // Disallow token withdrawals if there are no tokens to withdraw.
      require(contract_token_balance != 0);
      // Store the user&#39;s token balance in a temporary variable.
      uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
      // Update the value of tokens currently held by the contract.
      contract_eth_value -= balances[user];
      // Update the user&#39;s balance prior to sending to prevent recursive call.
      balances[user] = 0;
      // 1% fee if contract successfully bought tokens.
      uint256 fee = tokens_to_withdraw / 100;
      // Send the fee to the developer.
      require(token.transfer(fee_claimer, fee));
      // Send the funds.  Throws on failure to prevent loss of funds.
      require(token.transfer(user, tokens_to_withdraw - fee));
    }
  }

  // Send all ETH to the presale contract once total is between [149,299], callable by anyone.
  function purchase(){
    // Short circuit to save gas if the contract has already bought tokens.
    if (purchased_tokens) return;
    // Short circuit to save gas if the earliest buy time hasn&#39;t been reached.
    if (now > latest_buy_time) return;
    // Short circuit to save gas if kill switch is active.
    if (kill_switch) return;
    // Short circuit to save gas if the minimum buy in hasn&#39;t been achieved.
    if (this.balance < eth_min) return;
    // Record that the contract has bought the tokens.
    purchased_tokens = true;
    // Transfer all the funds to the crowdsale address
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has
    // already completed, preventing loss of funds.
    require(sale.call.value(this.balance)());
  }

  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Disallow deposits if kill switch is active.
    require(!kill_switch);
    // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
    require(!purchased_tokens);
    // Only allow deposits that won&#39;t exceed the contract&#39;s ETH cap.
    require(this.balance < eth_cap);
    // Update records of deposited ETH to include the received amount.
    balances[msg.sender] += msg.value;
  }
}