pragma solidity ^0.4.4;

contract ThreesigWallet {

  mapping (address => bool) public founders;

  struct Tx {
    address founder;
    address destAddr;
  }
  
  Tx[] public txs;
  
  uint256 balance;
  
  // constructor made of 3 independent wallets
  function ThreesigWallet() {
    founders[0x005A9c91CA71f9f69a4b3ad38c4B582E13595805] = true;
    founders[0x009A55A3c16953A359484afD299ebdC444200EdB] = true;
    founders[0xB94a9Db26b59AC66E5bE7510636BE8b189BD184D] = true;
  }
  
  // preICO contract will send ETHers here
  function() payable {
    balance += msg.value;
  }
  
  // one of founders can propose destination address for ethers
  function proposeTx(address destAddr) isFounder {
    txs.push(Tx({
      founder: msg.sender,
      destAddr: destAddr
    }));
  }
  
  // another founder can approve specified tx and send it to destAddr
  function approveTx(uint8 txIdx) isFounder {
    assert(txs[txIdx].founder != msg.sender);
    
    txs[txIdx].destAddr.transfer(balance);
    balance = 0;
  }
  
  // check if msg.sender is founder
  modifier isFounder() {
    require(founders[msg.sender]);
    _;
  }

}