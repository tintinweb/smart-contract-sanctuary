pragma solidity ^0.4.4;

contract ThreesigWallet {

  mapping (address => bool) public founders;

  struct Tx {
    address founder;
    address destAddr;
    bool active;
  }
  
  Tx[] public txs;
  
  // constructor made of 3 independent wallets
  function ThreesigWallet() {
    founders[0xCE05A8Aa56E1054FAFC214788246707F5258c0Ae] = true;
    founders[0xBb62A710BDbEAF1d3AD417A222d1ab6eD08C37f5] = true;
    founders[0x009A55A3c16953A359484afD299ebdC444200EdB] = true;
  }
  
  // preICO contract will send ETHers here
  function() payable {}
  
  // one of founders can propose destination address for ethers
  function proposeTx(address destAddr) isFounder {
    txs.push(Tx({
      founder: msg.sender,
      destAddr: destAddr,
      active: true
    }));
  }
  
  // another founder can approve specified tx and send it to destAddr
  function approveTx(uint8 txIdx) isFounder {
    assert(txs[txIdx].founder != msg.sender);
    assert(txs[txIdx].active);
    
    txs[txIdx].active = false;
    txs[txIdx].destAddr.transfer(this.balance);
  }

  // cancel tx
  function cancelTx(uint8 txIdx) isFounder {
    assert(txs[txIdx].founder == msg.sender);
    txs[txIdx].active = false;
  }
  
  // check if msg.sender is founder
  modifier isFounder() {
    require(founders[msg.sender]);
    _;
  }

}