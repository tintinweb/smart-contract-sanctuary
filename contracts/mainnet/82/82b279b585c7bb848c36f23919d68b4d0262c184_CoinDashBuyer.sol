pragma solidity ^0.4.13;

/*

CoinDash Buyer
========================

Buys CoinDash tokens from the crowdsale on your behalf.
Author: /u/Cintix

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract CoinDashBuyer {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Bounty for executing buy.
  uint256 public bounty;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record the time the contract bought the tokens.
  uint256 public time_bought;
  // Emergency kill switch in case a critical bug is found.
  bool public kill_switch;
  
  // Token Wei received per ETH Wei contributed in this sale
  uint256 tokens_per_eth = 6093;
  // SHA3 hash of kill switch password.
  bytes32 password_hash = 0x1b266c9bad3a46ed40bf43471d89b83712ed06c2250887c457f5f21f17b2eb97;
  // Earliest time contract is allowed to buy into the crowdsale.
  uint256 earliest_buy_time = 1500294600;
  // The developer address.
  address developer = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
  // The crowdsale address.  Settable by the developer.
  address public sale;
  // The token address.  Settable by the developer.
  ERC20 public token;
  
  // Allows the developer to set the crowdsale and token addresses.
  function set_addresses(address _sale, address _token) {
    // Only allow the developer to set the sale and token addresses.
    if (msg.sender != developer) throw;
    // Only allow setting the addresses once.
    if (sale != 0x0) throw;
    // Set the crowdsale and token addresses.
    sale = _sale;
    token = ERC20(_token);
  }
  
  // Allows the developer or anyone with the password to shut down everything except withdrawals in emergencies.
  function activate_kill_switch(string password) {
    // Only activate the kill switch if the sender is the developer or the password is correct.
    if (msg.sender != developer && sha3(password) != password_hash) throw;
    // Irreversibly activate the kill switch.
    kill_switch = true;
  }
  
  // Withdraws all ETH deposited or tokens purchased by the user.
  // "internal" means this function is not externally callable.
  function withdraw(address user, bool has_fee) internal {
    // If called before the ICO, cancel user&#39;s participation in the sale.
    if (!bought_tokens) {
      // Store the user&#39;s balance prior to withdrawal in a temporary variable.
      uint256 eth_to_withdraw = balances[user];
      // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
      balances[user] = 0;
      // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
      user.transfer(eth_to_withdraw);
    }
    // Withdraw the user&#39;s tokens if the contract has already purchased them.
    else {
      // Store the user&#39;s token balance in a temporary variable.
      uint256 tokens_to_withdraw = balances[user] * tokens_per_eth;
      // Update the user&#39;s balance prior to sending to prevent recursive call.
      balances[user] = 0;
      // No fee if the user withdraws their own funds manually.
      uint256 fee = 0;
      // 1% fee for automatic withdrawals.
      if (has_fee) {
        fee = tokens_to_withdraw / 100;
        // Send the fee to the developer.
        if(!token.transfer(developer, fee)) throw;
      }
      // Send the funds.  Throws on failure to prevent loss of funds.
      if(!token.transfer(user, tokens_to_withdraw - fee)) throw;
    }
  }
  
  // Automatically withdraws on users&#39; behalves (less a 1% fee on tokens).
  function auto_withdraw(address user){
    // Only allow automatic withdrawals after users have had a chance to manually withdraw.
    if (!bought_tokens || now < time_bought + 1 hours) throw;
    // Withdraw the user&#39;s funds for them.
    withdraw(user, true);
  }
  
  // Allows developer to add ETH to the buy execution bounty.
  function add_to_bounty() payable {
    // Only allow the developer to contribute to the buy execution bounty.
    if (msg.sender != developer) throw;
    // Disallow adding to bounty if kill switch is active.
    if (kill_switch) throw;
    // Disallow adding to the bounty if contract has already bought the tokens.
    if (bought_tokens) throw;
    // Update bounty to include received amount.
    bounty += msg.value;
  }
  
  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function claim_bounty(){
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    // Short circuit to save gas if kill switch is active.
    if (kill_switch) return;
    // Short circuit to save gas if the earliest buy time hasn&#39;t been reached.
    if (now < earliest_buy_time) return;
    // Disallow buying in if the developer hasn&#39;t set the sale address yet.
    if (sale == 0x0) throw;
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Record the time the contract bought the tokens.
    time_bought = now;
    // Transfer all the funds (less the bounty) to the crowdsale address
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has
    // already completed, preventing loss of funds.
    if(!sale.call.value(this.balance - bounty)()) throw;
    // Send the caller their bounty for buying tokens for the contract.
    msg.sender.transfer(bounty);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Treat near-zero ETH transactions as withdrawal requests.
    if (msg.value <= 1 finney) {
      // No fee on manual withdrawals.
      withdraw(msg.sender, false);
    }
    // Deposit the user&#39;s funds for use in purchasing tokens.
    else {
      // Disallow deposits if kill switch is active.
      if (kill_switch) throw;
      // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
      if (bought_tokens) throw;
      // Update records of deposited ETH to include the received amount.
      balances[msg.sender] += msg.value;
    }
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Delegate to the helper function.
    default_helper();
  }
}