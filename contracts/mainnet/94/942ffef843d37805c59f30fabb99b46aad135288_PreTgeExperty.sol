pragma solidity ^0.4.4;

// kovan:   0x722475921ebc15078d4d6c93b4cff43eadf099c2
// mainnet: 0x942ffef843d37805c59f30fabb99b46aad135288

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
  address public whitelistManagerAddr;

  // wallet
  struct Tx {
    address founder;
    address destAddr;
    uint256 amount;
    bool active;
  }
  mapping (address => bool) public founders;
  Tx[] public txs;

  // preTGE constructor
  function PreTgeExperty() public {
    whitelistManagerAddr = 0x8179C4797948cb4922bd775D3BcE90bEFf652b23;
    managerAddr = 0x9B7A647b3e20d0c8702bAF6c0F79beb8E9B58b25;
    founders[0xCE05A8Aa56E1054FAFC214788246707F5258c0Ae] = true;
    founders[0xBb62A710BDbEAF1d3AD417A222d1ab6eD08C37f5] = true;
    founders[0x009A55A3c16953A359484afD299ebdC444200EdB] = true;
  }

  // whitelist address
  function whitelist(address addr) public isWhitelistManager {
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
  function proposeTx(address destAddr, uint256 amount) public isFounder {
    txs.push(Tx({
      founder: msg.sender,
      destAddr: destAddr,
      amount: amount,
      active: true
    }));
  }

  // another founder can approve specified tx and send it to destAddr
  function approveTx(uint8 txIdx) public isFounder {
    assert(txs[txIdx].founder != msg.sender);
    assert(txs[txIdx].active);

    txs[txIdx].active = false;
    txs[txIdx].destAddr.transfer(txs[txIdx].amount);
  }

  // founder who created tx can cancel it
  function cancelTx(uint8 txIdx) {
    assert(txs[txIdx].founder == msg.sender);
    assert(txs[txIdx].active);

    txs[txIdx].active = false;
  }

  // isManager modifier
  modifier isManager() {
    assert(msg.sender == managerAddr);
    _;
  }

  // isWhitelistManager modifier
  modifier isWhitelistManager() {
    assert(msg.sender == whitelistManagerAddr);
    _;
  }

  // check if msg.sender is founder
  modifier isFounder() {
    assert(founders[msg.sender]);
    _;
  }

  // view functions
  function getContributionsCount(address addr) view returns (uint count) {
    count = 0;
    for (uint i = 0; i < contributors.length; ++i) {
      if (contributors[i].addr == addr) {
        ++count;
      }
    }
    return count;
  }

  function getContribution(address addr, uint idx) view returns (uint amount, uint timestamp, bool rejected) {
    uint count = 0;
    for (uint i = 0; i < contributors.length; ++i) {
      if (contributors[i].addr == addr) {
        if (count == idx) {
          return (contributors[i].amount, contributors[i].timestamp, contributors[i].rejected);
        }
        ++count;
      }
    }
    return (0, 0, false);
  }
}