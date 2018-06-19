pragma solidity ^0.4.11;

/*

TenX Buyer
========================

Buys TenX tokens from the crowdsale on your behalf.
Author: /u/Cintix

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
// Well, almost.  PAY tokens throw on transfer failure instead of returning false.
contract ERC20 {
  function transfer(address _to, uint _value);
  function balanceOf(address _owner) constant returns (uint balance);
}

// Interface to TenX ICO Contract
contract MainSale {
  address public multisigVault;
  uint public altDeposits;
  function createTokens(address recipient) payable;
}

contract TenXBuyer {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint) public balances;
  // Bounty for executing buy.
  uint256 public bounty;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record the time the contract bought the tokens.
  uint public time_bought;
  
  // Hard Cap of TenX Crowdsale
  uint hardcap = 200000 ether;
  // Ratio of PAY tokens received to ETH contributed (350 + 20% first-day bonus)
  uint pay_per_eth = 420;
  
  // The TenX Token Sale address.
  MainSale public sale = MainSale(0xd43D09Ec1bC5e57C8F3D0c64020d403b04c7f783);
  // TenX PAY Token Contract address.
  ERC20 public token = ERC20(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280);
  // The developer address.
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
  
  // Withdraws all ETH deposited or PAY purchased by the sender.
  function withdraw(){
    // If called before the ICO, cancel caller&#39;s participation in the sale.
    if (!bought_tokens) {
      // Store the user&#39;s balance prior to withdrawal in a temporary variable.
      uint eth_amount = balances[msg.sender];
      // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
      balances[msg.sender] = 0;
      // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
      msg.sender.transfer(eth_amount);
    }
    // Withdraw the sender&#39;s tokens if the contract has already purchased them.
    else {
      // Store the user&#39;s PAY balance in a temporary variable (1 ETHWei -> 420 PAYWei).
      uint pay_amount = balances[msg.sender] * pay_per_eth;
      // Update the user&#39;s balance prior to sending PAY to prevent recursive call.
      balances[msg.sender] = 0;
      // No fee for withdrawing during the crowdsale.
      uint fee = 0;
      // Determine whether the crowdsale&#39;s hard cap has been reached yet.
      bool cap_reached = (sale.multisigVault().balance + sale.altDeposits() > hardcap);
      // 1% fee for withdrawing after the crowdsale has ended or after the bonus period.
      if (cap_reached || (now > time_bought + 1 days)) {
        fee = pay_amount / 100;
      }
      // Send the funds.  Throws on failure to prevent loss of funds.
      token.transfer(msg.sender, pay_amount - fee);
      token.transfer(developer, fee);
    }
  }
  
  // Allow anyone to contribute to the buy execution bounty.
  function add_to_bounty() payable {
    // Disallow adding to the bounty if contract has already bought the tokens.
    if (bought_tokens) throw;
    // Update bounty to include received amount.
    bounty += msg.value;
  }
  
  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function buy(){
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Record the time the contract bought the tokens.
    time_bought = now;
    // Transfer all the funds (less the bounty) to the TenX crowdsale contract
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has
    // already completed, preventing loss of funds.
    sale.createTokens.value(this.balance - bounty)(address(this));
    // Send the caller their bounty for buying tokens for the contract.
    msg.sender.transfer(bounty);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Treat 0 ETH transactions as withdrawal requests.
    if (msg.value == 0) {
      withdraw();
    }
    // Otherwise, the user is sending funds to buy tokens.
    else {
      // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
      if (bought_tokens) throw;
      // Update records of deposited ETH to include the received amount.
      balances[msg.sender] += msg.value;
    }
  }
  
  function () payable {
    default_helper();
  }
}