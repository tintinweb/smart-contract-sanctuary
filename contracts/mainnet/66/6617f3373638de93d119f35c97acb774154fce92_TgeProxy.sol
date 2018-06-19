pragma solidity ^0.4.4;

// TGE (ICO) Proxy
contract TgeProxy {

  address[] public managers;
  mapping (address => address) votesAddr;

  bool locked = false;

  function TgeProxy() {
    // any number of managers can be added in constructor
    managers.push(0xCE05A8Aa56E1054FAFC214788246707F5258c0Ae);
    managers.push(0xBb62A710BDbEAF1d3AD417A222d1ab6eD08C37f5);
    managers.push(0x009A55A3c16953A359484afD299ebdC444200EdB);
  }

  // gateway for tge contributions
  // this function will start accepting ETH, when ico/tge address
  // will be confirmed by all contract managers
  function() payable isLocked {
    votesAddr[managers[0]].transfer(msg.value);
  }

  // this function allows ico/tge manager to set final ico/tge address
  // it can be overwritten until contract address is locked
  function setTgeAddr(address addr) isManager isUnlocked {
    votesAddr[msg.sender] = addr;
    lockAttemp();
  }
  
  function lockAttemp() private {
    address addr = votesAddr[managers[0]];
    bool lock = true;
    for (uint8 i = 0; i < managers.length; ++i) {
      if (votesAddr[managers[i]] == 0x0) {
        lock = false;
        break;
      }
      if (votesAddr[managers[i]] != addr) {
        lock = false;
        break;
      }
    }
    if (lock) {
      locked = true;
    }
  }
  
  // only for contract managers
  modifier isManager() {
    for (uint8 i = 0; i < managers.length; ++i) {
      if (managers[i] == msg.sender) {
        _;
      }
    }
  }

  // run code only in unlocked mode
  modifier isUnlocked() {
    assert(!locked);
    _;
  }

  // run code only when tge address is locked
  modifier isLocked() {
    assert(locked);
    _;
  }
  
}