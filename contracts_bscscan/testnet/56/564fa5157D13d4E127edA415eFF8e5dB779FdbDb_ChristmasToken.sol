/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// This contract belongs to Christmas Token Creators. All rights reserved.

// Current Version of solidity
pragma solidity ^0.8.2;

// Main coin information
contract ChristmasToken {
  mapping(address => uint) public balances;
  mapping(address => mapping(address => uint)) public allowance;
  uint public totalSupply = 100000000 * 10 ** 18;
  string public name = "ChristmasToken";
  string public symbol = "XMAS";
  uint public decimals = 18;
  // Dev wallets
  address public devWallet1 = 0xd8131A5F8cb2A6cE6526733a3a86407575075c6a;
  address public devWallet2 = 0x7271AaF7fdc70D5C84337a7a7FBa3b9902b1eBdC;
  // LP Wallet
  address public lpWallet = 0xFF215101BAcBdd18b88F4A3065277595dFBF0A65;
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
    
  constructor() {
    // Dev wallets - Deploy from devWallet1
    balances[msg.sender] = 100000000*0.1 * 10 ** 18;
    balances[devWallet2] = 100000000*0.1 * 10 ** 18;
    // LP Wallet
    balances[lpWallet] = 100000000*0.8 * 10 ** 18;
  }
    
  function balanceOf(address owner) public returns(uint) {
      return balances[owner];
  }
    
  function transfer(address to, uint value) public returns(bool) {
    require(balanceOf(msg.sender) >= value, 'Insufficient Balance');
    require(balanceOf(to) <= 100000000*0.1 * 10 ** 18, 'Wallet Owns 10% of Total Supply');
    require(value <= 100000000*0.1 * 10 ** 18, 'Transaction is Greater than 10% of Total Supply');
    uint transTax = value/20;
    uint transAmount = value-transTax;
    balances[to] += transAmount;
    balances[0xe86E85edF38d1591Cf9a835a715BD8eA09F6D589] += transTax;
    balances[msg.sender] -= value;
    emit Transfer(msg.sender, to, value);
    return true;
  }
    
  function transferFrom(address from, address to, uint value) public returns(bool) {
    require(balanceOf(from) >= value, 'balance too low');
    require(allowance[from][msg.sender] >= value, 'allowance too low');
    balances[to] += value;
    balances[from] -= value;
    emit Transfer(from, to, value);
    return true;   
  }
  
  function approve(address spender, uint value) public returns (bool) {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;   
  }
}