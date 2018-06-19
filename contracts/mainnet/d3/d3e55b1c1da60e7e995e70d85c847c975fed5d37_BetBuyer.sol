pragma solidity ^0.4.11;

/*

BET Buyer
========================

Buys BET tokens from the DAO.Casino crowdsale on your behalf.
Author: /u/Cintix

*/

// Interface to BET ICO Contract
contract DaoCasinoToken {
  uint256 public CAP;
  uint256 public totalEthers;
  function proxyPayment(address participant) payable;
  function transfer(address _to, uint _amount) returns (bool success);
}

contract BetBuyer {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Store whether or not each account would have made it into the crowdsale.
  mapping (address => bool) public checked_in;
  // Bounty for executing buy.
  uint256 public bounty;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record the time the contract bought the tokens.
  uint256 public time_bought;
  // Emergency kill switch in case a critical bug is found.
  bool public kill_switch;
  
  // Ratio of BET tokens received to ETH contributed
  uint256 bet_per_eth = 2000;
  
  // The BET Token address and sale address are the same.
  DaoCasinoToken public token = DaoCasinoToken(0x2B09b52d42DfB4e0cBA43F607dD272ea3FE1FB9F);
  // The developer address.
  address developer = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
  
  // Allows the developer to shut down everything except withdrawals in emergencies.
  function activate_kill_switch() {
    // Only allow the developer to activate the kill switch.
    if (msg.sender != developer) throw;
    // Irreversibly activate the kill switch.
    kill_switch = true;
  }
  
  // Withdraws all ETH deposited or BET purchased by the sender.
  function withdraw(){
    // If called before the ICO, cancel caller&#39;s participation in the sale.
    if (!bought_tokens) {
      // Store the user&#39;s balance prior to withdrawal in a temporary variable.
      uint256 eth_amount = balances[msg.sender];
      // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
      balances[msg.sender] = 0;
      // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
      msg.sender.transfer(eth_amount);
    }
    // Withdraw the sender&#39;s tokens if the contract has already purchased them.
    else {
      // Store the user&#39;s BET balance in a temporary variable (1 ETHWei -> 2000 BETWei).
      uint256 bet_amount = balances[msg.sender] * bet_per_eth;
      // Update the user&#39;s balance prior to sending BET to prevent recursive call.
      balances[msg.sender] = 0;
      // No fee for withdrawing if the user would have made it into the crowdsale alone.
      uint256 fee = 0;
      // 1% fee if the user didn&#39;t check in during the crowdsale.
      if (!checked_in[msg.sender]) {
        fee = bet_amount / 100;
        // Send any non-zero fees to developer.
        if(!token.transfer(developer, fee)) throw;
      }
      // Send the user their tokens.  Throws if the crowdsale isn&#39;t over.
      if(!token.transfer(msg.sender, bet_amount - fee)) throw;
    }
  }
  
  // Allow developer to add ETH to the buy execution bounty.
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
    // Disallow buying into the crowdsale if kill switch is active.
    if (kill_switch) throw;
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Record the time the contract bought the tokens.
    time_bought = now;
    // Transfer all the funds (less the bounty) to the BET crowdsale contract
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has
    // already completed, preventing loss of funds.
    token.proxyPayment.value(this.balance - bounty)(address(this));
    // Send the caller their bounty for buying tokens for the contract.
    msg.sender.transfer(bounty);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Treat near-zero ETH transactions as check ins and withdrawal requests.
    if (msg.value <= 1 finney) {
      // Check in during the crowdsale.
      if (bought_tokens) {
        // Only allow checking in before the crowdsale has reached the cap.
        if (token.totalEthers() >= token.CAP()) throw;
        // Mark user as checked in, meaning they would have been able to enter alone.
        checked_in[msg.sender] = true;
      }
      // Withdraw funds if the crowdsale hasn&#39;t begun yet or is already over.
      else {
        withdraw();
      }
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