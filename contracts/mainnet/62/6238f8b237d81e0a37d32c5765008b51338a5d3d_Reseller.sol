pragma solidity ^0.4.11;

/*

TenX Reseller
========================

Resells TenX tokens from the crowdsale before transfers are enabled.
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
  function createTokens(address recipient) payable;
}

contract Reseller {
  // Store the amount of PAY claimed by each account.
  mapping (address => uint256) public pay_claimed;
  // Total claimed PAY of all accounts.
  uint256 public total_pay_claimed;
  
  // The TenX Token Sale address.
  MainSale public sale = MainSale(0xd43D09Ec1bC5e57C8F3D0c64020d403b04c7f783);
  // TenX Token (PAY) Contract address.
  ERC20 public token = ERC20(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280);
  // The developer address.
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;

  // Buys PAY for the contract with user funds.
  function buy() payable {
    // Transfer received funds to the TenX crowdsale contract to buy tokens.
    sale.createTokens.value(msg.value)(address(this));
  }
  
  // Withdraws PAY claimed by the user.
  function withdraw() {
    // Store the user&#39;s amount of claimed PAY as the amount of PAY to withdraw.
    uint256 pay_to_withdraw = pay_claimed[msg.sender];
    // Update the user&#39;s amount of claimed PAY first to prevent recursive call.
    pay_claimed[msg.sender] = 0;
    // Update the total amount of claimed PAY.
    total_pay_claimed -= pay_to_withdraw;
    // Send the user their PAY.  Throws on failure to prevent loss of funds.
    token.transfer(msg.sender, pay_to_withdraw);
  }
  
  // Claims PAY at a price determined by the block number.
  function claim() payable {
    // Verify ICO is over.
    if(block.number < 3930000) throw;
    // Calculate current sale price (PAY per ETH) based on block number.
    uint256 pay_per_eth = (block.number - 3930000) / 10;
    // Calculate amount of PAY user can purchase.
    uint256 pay_to_claim = pay_per_eth * msg.value;
    // Retrieve current PAY balance of contract.
    uint256 contract_pay_balance = token.balanceOf(address(this));
    // Verify the contract has enough remaining unclaimed PAY.
    if((contract_pay_balance - total_pay_claimed) < pay_to_claim) throw;
    // Update the amount of PAY claimed by the user.
    pay_claimed[msg.sender] += pay_to_claim;
    // Update the total amount of PAY claimed by all users.
    total_pay_claimed += pay_to_claim;
    // Send the funds to the developer instead of leaving them in the contract.
    developer.transfer(msg.value);
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // If the user sent a 0 ETH transaction, withdraw their PAY.
    if(msg.value == 0) {
      withdraw();
    }
    // If the user sent ETH, claim PAY with it.
    else {
      claim();
    }
  }
}