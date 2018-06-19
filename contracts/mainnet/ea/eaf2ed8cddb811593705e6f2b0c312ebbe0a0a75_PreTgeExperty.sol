pragma solidity ^0.4.4;

contract PreTgeExperty {

  // TGE
  struct Contributor {
    address addr;
    uint256 amount;
    uint256 timestamp;
    bool rejected;
  }
  Contributor[] public contributors;
  mapping(address => bool) public isWhitelisted;
  address public managerAddr;

  // wallet
  struct Tx {
    address founder;
    address destAddr;
    bool active;
  }
  mapping (address => bool) public founders;
  Tx[] public txs;
  
  // preICO constructor
  function PreTgeExperty() public {
    managerAddr = 0x71e2f5362fdf6A48ab726E1D3ef1Cd4B087436fC;
    founders[0xCE05A8Aa56E1054FAFC214788246707F5258c0Ae] = true;
    founders[0xBb62A710BDbEAF1d3AD417A222d1ab6eD08C37f5] = true;
    founders[0x009A55A3c16953A359484afD299ebdC444200EdB] = true;
  }
  
  // whitelist address
  function whitelist(address addr) public isManager {
    isWhitelisted[addr] = true;
  }

  function reject(uint256 idx) public isManager {
    // contributor must exist
    assert(contributors[idx].addr != 0);
    // contribution cant be rejected
    assert(!contributors[idx].rejected);

    // de-whitelist address
    isWhitelisted[contributors[idx].addr] = false;

    // reject contribution
    contributors[idx].rejected = true;

    // return ETH to contributor
    contributors[idx].addr.transfer(contributors[idx].amount);
  }

  // contribute function
  function() public payable {
    // allow to contribute only whitelisted KYC addresses
    assert(isWhitelisted[msg.sender]);

    // save contributor for further use
    contributors.push(Contributor({
      addr: msg.sender,
      amount: msg.value,
      timestamp: block.timestamp,
      rejected: false
    }));
  }

  // one of founders can propose destination address for ethers
  function proposeTx(address destAddr) public isFounder {
    txs.push(Tx({
      founder: msg.sender,
      destAddr: destAddr,
      active: true
    }));
  }

  // another founder can approve specified tx and send it to destAddr
  function approveTx(uint8 txIdx) public isFounder {
    assert(txs[txIdx].founder != msg.sender);
    assert(txs[txIdx].active);
    
    txs[txIdx].active = false;
    txs[txIdx].destAddr.transfer(this.balance);
  }

  // isManager modifier
  modifier isManager() {
    if (msg.sender == managerAddr) {
      _;
    }
  }
  
  // check if msg.sender is founder
  modifier isFounder() {
    require(founders[msg.sender]);
    _;
  }
}