//SourceUnit: Builder3.sol

pragma solidity ^0.4.25;

contract Builder3 {
  address support = msg.sender;
  address private lastSender;
  address private lastOrigin;
  uint public totalFrozen;
  uint public tokenId = 1002798;
  
  uint public prizeFund;
  bool public prizeReceived;
  address public lastInvestor;
  uint public lastInvestedAt;
  
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalDeposited;
  
  // records registrations
  mapping (address => bool) public registered;
  // records amounts invested
  mapping (address => mapping (uint => uint)) public invested;
  // records blocks at which investments were made
  mapping (address => uint) public atBlock;
  // records referrers
  mapping (address => address) public referrers;
  // records objects
  mapping (address => mapping (uint => uint)) public objects;
  // frozen tokens
  mapping (address => uint) public frozen;
  // upgrades
  mapping (address => uint) public upgrades;
  // investor balances
  mapping (address => uint) public investorBalances;
  // withdrawal balances
  mapping (address => uint) public withdrawalBalances;

  event Registered(address user, address referrer);
  event Buy(address user, uint amount);
 
  modifier notContract() {
    lastSender = msg.sender;
    lastOrigin = tx.origin;
    require(lastSender == lastOrigin);
    _;
  }
  
  modifier onlyOwner() {
    require(msg.sender == support);
    _;
  }

  function _register(address referrerAddress) internal {
    if (!registered[msg.sender]) {   
      if (registered[referrerAddress] && referrerAddress != msg.sender) {
        referrers[msg.sender] = referrerAddress;
      }

      totalInvestors++;
      registered[msg.sender] = true;

      emit Registered(msg.sender, referrerAddress);
    }
  }
  
  function deposit(address referrerAddress) external payable {
    _register(referrerAddress);
    
    investorBalances[msg.sender] += msg.value;
    
    prizeFund += msg.value / 25;
    support.transfer(msg.value * 3 / 25);
    
    if (referrers[msg.sender] != 0x0) {
      referrers[msg.sender].transfer(msg.value / 20);
    }
    
    totalDeposited += msg.value;
    
    lastInvestor = msg.sender;
    lastInvestedAt = block.number;

    msg.sender.transferToken(msg.value * 100, tokenId);

    prizeReceived = false;
  }
  
  function withdraw(uint amount) external {
    getAllProfit();
    
    require(withdrawalBalances[msg.sender] >= amount);
    
    uint amountToTransfer = amount;
    uint max = (address(this).balance - prizeFund) * 9 / 10;
    if (amountToTransfer > max) {
      amountToTransfer = max;
    }
    
    withdrawalBalances[msg.sender] -= amountToTransfer;
    msg.sender.transfer(amountToTransfer);
  }

  function buy(uint amount) external {
    require(amount == 50000000 || amount == 100000000 || amount == 200000000 || amount == 500000000
      || amount == 1000000000 || amount == 5000000000 || amount == 10000000000 || amount == 100000000000);
    
    getAllProfit();
    
    require(investorBalances[msg.sender] + withdrawalBalances[msg.sender] >= amount);
    if (investorBalances[msg.sender] >= amount) {
      investorBalances[msg.sender] -= amount;
    } else {
      withdrawalBalances[msg.sender] -= amount - investorBalances[msg.sender];
      investorBalances[msg.sender] = 0;
    }
    
    objects[msg.sender][amount]++;
    
    invested[msg.sender][amount] += amount;
    totalInvested += amount;
    
    emit Buy(msg.sender, amount);
  }

  function getProfitFrom(address user, uint price, uint percentage) internal view returns (uint) {
    return invested[user][price] * (percentage + upgrades[user]) / 100 * (block.number - atBlock[user]) / 864000;
  }

  function getAllProfitAmount(address user) public view returns (uint) {
    return
      getProfitFrom(user, 50000000, 95) +
      getProfitFrom(user, 100000000, 96) +
      getProfitFrom(user, 200000000, 97) +
      getProfitFrom(user, 500000000, 98) +
      getProfitFrom(user, 1000000000, 99) +
      getProfitFrom(user, 5000000000, 100) +
      getProfitFrom(user, 10000000000, 101) +
      getProfitFrom(user, 100000000000, 102);
  }

  function getAllProfit() internal {
    require(block.number >= 15049244);
    
    if (atBlock[msg.sender] > 0) {
      uint amount = getAllProfitAmount(msg.sender) / 2;
      investorBalances[msg.sender] += amount;
      withdrawalBalances[msg.sender] += amount;
    }

    atBlock[msg.sender] = block.number;
  }

  function allowGetPrizeFund(address user) public view returns (bool) {
    return !prizeReceived && lastInvestor == user && block.number >= lastInvestedAt + 2400 && prizeFund >= 2000000;
  }

  function getPrizeFund() external {
    require(allowGetPrizeFund(msg.sender));
    uint amount = prizeFund / 2;
    msg.sender.transfer(amount);
    prizeFund -= amount;
    prizeReceived = true;
  }

  function register(address referrerAddress) external notContract {
    _register(referrerAddress);
  }

  function freeze(address referrerAddress) external payable {
    require(msg.tokenid == tokenId);
    require(msg.tokenvalue > 0);

    _register(referrerAddress);

    frozen[msg.sender] += msg.tokenvalue;
    totalFrozen += msg.tokenvalue;
  }

  function unfreeze() external {
    totalFrozen -= frozen[msg.sender];
    msg.sender.transferToken(frozen[msg.sender], tokenId);
    frozen[msg.sender] = 0;
  }

  function upgrade(address referrerAddress) external payable {
    require(msg.tokenid == tokenId);
    require(upgrades[msg.sender] == 0 && msg.tokenvalue == 50000000000 ||
      upgrades[msg.sender] == 1 && msg.tokenvalue == 100000000000 ||
      upgrades[msg.sender] == 2 && msg.tokenvalue == 300000000000 ||
      upgrades[msg.sender] == 3 && msg.tokenvalue == 1000000000000 ||
      upgrades[msg.sender] == 4 && msg.tokenvalue == 10000000000000);

    _register(referrerAddress);
    
    getAllProfit();
    
    upgrades[msg.sender]++;
    support.transferToken(msg.tokenvalue, tokenId);
  }
}