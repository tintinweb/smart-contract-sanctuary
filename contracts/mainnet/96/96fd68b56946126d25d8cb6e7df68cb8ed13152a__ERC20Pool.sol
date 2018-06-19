pragma solidity ^0.4.17;
/*
Author: Vox / 0xPool.io
Description: This smart contract is designed to store mining pool payouts for 
  Ethereum Protocol tokens and allow pool miners to withdraw their earned tokens
  whenever they please. There are several benefits to using a smart contract to
  track mining pool payouts:
    - Increased transparency on behalf of pool owners
    - Allows users more control over the regularity of their mining payouts
    - The pool admin does not need to pay the gas costs of hundreds of 
      micro-transactions every time a block reward is found by the pool.

This contract is the 0xBTC (0xBitcoin) payout account for: http://0xpool.io 

Not heard of 0xBitcoin? Head over to http://0xbitcoin.org
*/

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


contract _ERC20Pool {
  ERC20Interface public tokenContract = ERC20Interface(0xB6eD7644C69416d67B522e20bC294A9a9B405B31);

  address public owner = msg.sender;
  uint32 public totalTokenSupply;
  mapping (address => uint32) minerTokens;
  mapping (address => uint32) minerTokenPayouts;

  // Modifier for important owner only functions
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Require that the caller actually has tokens to withdraw.
  modifier hasTokens(address sentFrom) {
    require(minerTokens[sentFrom] > 0);
    _;
  }

  // Pool software updates the contract when it finds a reward
  function addMinerTokens(uint32 totalTokensInBatch, address[] minerAddress, uint32[] minerRewardTokens) public onlyOwner {
    totalTokenSupply += totalTokensInBatch;
    for (uint i = 0; i < minerAddress.length; i ++) {
      minerTokens[minerAddress[i]] += minerRewardTokens[i];
    }
  }

  // Allow miners to withdraw their earnings from the contract. Update internal accounting.
  function withdraw() public
    hasTokens(msg.sender) 
  {
    uint32 amount = minerTokens[msg.sender];
    minerTokens[msg.sender] = 0;
    totalTokenSupply -= amount;
    minerTokenPayouts[msg.sender] += amount;
    tokenContract.transfer(msg.sender, amount);
  }

  // Fallback function, Ether sent to this contract will be considered as a donation towards the 
  // 0xPool & 0xBitcoin projects unless you get in contact with 0xPool.io within 72 hours. 
  function () public payable {
    owner.transfer(msg.value);
  }

}