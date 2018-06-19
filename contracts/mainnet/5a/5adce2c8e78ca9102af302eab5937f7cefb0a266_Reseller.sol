pragma solidity ^0.4.11;

/*

Status Reseller
========================

Resells Status tokens from the crowdsale before transfers are enabled.
Author: /u/Cintix

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Reseller {
  // Store the amount of SNT claimed by each account.
  mapping (address => uint256) public snt_claimed;
  // Total claimed SNT of all accounts.
  uint256 public total_snt_claimed;
  
  // Status Network Token (SNT) Contract address.
  ERC20 public token = ERC20(0x744d70FDBE2Ba4CF95131626614a1763DF805B9E);
  // The developer address.
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
  
  // Withdraws SNT claimed by the user.
  function withdraw() {
    // Store the user&#39;s amount of claimed SNT as the amount of SNT to withdraw.
    uint256 snt_to_withdraw = snt_claimed[msg.sender];
    // Update the user&#39;s amount of claimed SNT first to prevent recursive call.
    snt_claimed[msg.sender] = 0;
    // Update the total amount of claimed SNT.
    total_snt_claimed -= snt_to_withdraw;
    // Send the user their SNT.  Throws on failure to prevent loss of funds.
    if(!token.transfer(msg.sender, snt_to_withdraw)) throw;
  }
  
  // Claims SNT at a price determined by the block number.
  function claim() payable {
    // Verify ICO is over.
    if(block.number < 3915000) throw;
    // Calculate current sale price (SNT per ETH) based on block number.
    uint256 snt_per_eth = (block.number - 3915000) * 2;
    // Calculate amount of SNT user can purchase.
    uint256 snt_to_claim = snt_per_eth * msg.value;
    // Retrieve current SNT balance of contract.
    uint256 contract_snt_balance = token.balanceOf(address(this));
    // Verify the contract has enough remaining unclaimed SNT.
    if((contract_snt_balance - total_snt_claimed) < snt_to_claim) throw;
    // Update the amount of SNT claimed by the user.
    snt_claimed[msg.sender] += snt_to_claim;
    // Update the total amount of SNT claimed by all users.
    total_snt_claimed += snt_to_claim;
    // Send the funds to the developer instead of leaving them in the contract.
    developer.transfer(msg.value);
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // If the user sent a 0 ETH transaction, withdraw their SNT.
    if(msg.value == 0) {
      withdraw();
    }
    // If the user sent ETH, claim SNT with it.
    else {
      claim();
    }
  }
}