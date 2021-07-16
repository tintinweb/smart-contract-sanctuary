//SourceUnit: DefiDev.sol

pragma solidity 0.5.10;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns(uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
  
  function take(uint256 a, uint256 percents) internal pure returns(uint256) {
    return div(mul(a, percents), 100);
  }
}

contract AccountChangable {
  address supervisor;
  address EMPTY_ADDRESS = address(0);
  mapping(address => address) oldToNew;
  mapping(address => address) newToOld;
  mapping(address => address) requests;

  constructor() public { supervisor = msg.sender; }

  function getOriginalAddress(address someAddress) public view returns(address) {
    if (newToOld[someAddress] != EMPTY_ADDRESS) return newToOld[someAddress];
    return someAddress;
  }
  
  function isReplaced(address oldAddress) internal view returns(bool) {
    return oldToNew[oldAddress] != EMPTY_ADDRESS;
  }

  function isNewAddress(address newAddress) public view returns(bool) {
    return newToOld[newAddress] != EMPTY_ADDRESS;
  }

  function getCurrentAddress(address someAddress) internal view returns(address) {
    if (oldToNew[someAddress] != EMPTY_ADDRESS) return oldToNew[someAddress];
    return someAddress;
  }

  function requestUpdateAddress(address newAddress) public {
    requests[msg.sender] = newAddress;
  }

  function accept(address oldAddress, address newAddress) public {
    require(msg.sender == supervisor, 'ONLY SUPERVISOR');
    require(newAddress != EMPTY_ADDRESS, 'NEW ADDRESS MUST NOT BE EMPTY');
    require(requests[oldAddress] == newAddress, 'INCORRECT NEW ADDRESS');
    requests[oldAddress] = EMPTY_ADDRESS;
    oldToNew[oldAddress] = newAddress;
    newToOld[newAddress] = oldAddress;
  }
}

contract Defi is AccountChangable {

  using SafeMath for uint256;

  string public version = '0.1.1';
  uint256 ONE_DAY = 86400;

  uint256[] directCommissionRates = [0, 5, 3, 2, 2, 2, 2, 1, 1, 1, 1];

  mapping(address => uint256) systemRates;
  address rootAdmin;
  uint256 ROOT_LEVEL = 1;
  uint256 LEADER_LEVEL = 2;

  // @WARNING remove 'public' this on production
  uint256 public investmentCount = 0;
  uint256 public withdrawalCount = 0;
  uint256 public skippedTime = 0;
  mapping(uint256 => Investment) public investments;
  mapping(address => Investor) public investors;

  modifier mustNotBeReplacedAddress() {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    _;
  }

  modifier mustBeRootAdmin() {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    require(getOriginalAddress(msg.sender) == rootAdmin, 'ONLY ADMIN');
    _;
  }

  event CreateInvestor(address investorAddress, address presenterAddress, uint256 level, uint256 createdAt);

  struct Investor {
    address investorAddress;
    address presenterAddress;
    uint256 level;
    uint256 deposited;
    uint256 withdrew;
    uint256 commission;
    uint256[] investments;
  }

  event CreateInvestment(uint256 investmentId, address investorAddress, uint256 amount, uint256 createdAt);
  event CreateWithdrawal(uint256 withdrawalId, address investorAddress, uint256 amount, uint256 createdAt);

  struct Investment {
    uint256 investmentId;
    address investorAddress;
    uint256 amount;
    uint256 createdAt;
  }

  constructor(address rootAddress) public {
    rootAdmin = rootAddress;
    uint256 FIRST_LEVEL = 1;
    createInvestor(rootAddress, EMPTY_ADDRESS, FIRST_LEVEL);
  }

  // @WARNING @remove
  function addFund() public payable {}

  // @WARNING @remove
  function skip(uint256 numberOfday) public {
    skippedTime = skippedTime.add(numberOfday.mul(ONE_DAY));
  }

  // @WARNING @remove
  function setInvestor(address investorAddress, uint256 deposited, uint256 withdrew, uint256 commission) public {
    Investor storage investor = investors[investorAddress];
    investor.deposited = deposited;
    investor.withdrew = withdrew;
    investor.commission = commission;
  }

  function createInvestor(address investorAddress, address presenterAddress, uint256 level) internal {
    investors[investorAddress] = Investor({
      investorAddress: investorAddress,
      presenterAddress: presenterAddress,
      level: level,
      deposited: 0,
      withdrew: 0,
      commission: 0,
      investments: new uint256[](0)
    });
    emit CreateInvestor(investorAddress, presenterAddress, level, getNow());
  }

  function createInvestment(uint256 index, address investorAddress, uint256 amount, uint256 createdAt) internal {
    uint256 investmentId = index;
    investments[investmentId] = Investment({
      investmentId: investmentId,
      investorAddress: investorAddress,
      amount: amount,
      createdAt: createdAt
    });
    investors[investorAddress].investments.push(investmentId);
    emit CreateInvestment(investmentId, investorAddress, amount, createdAt);
  }

  function payDirectCommission(address investorAddress, uint256 depositAmount) internal {
    uint256 maxLoopTime = directCommissionRates.length.sub(1);
    address childAddress = investorAddress;
    for (uint256 count = 1; count <= maxLoopTime; count = count.add(1)) {
      address presenterAddress = investors[childAddress].presenterAddress;
      Investor memory presenter = investors[presenterAddress];
      uint256 percents = directCommissionRates[count];
      pay(presenterAddress, depositAmount.take(percents));
      childAddress = presenter.investorAddress;
    }
  }

  function paySystemCommission(address investorAddress, uint256 depositAmount) internal {
    uint256 MAX_SYSTEM_COMMISSION_RATE = 5;
    uint256 MAX_COMMISSION = depositAmount.take(MAX_SYSTEM_COMMISSION_RATE);

    address leaderAddress = getLeader(investorAddress);
    uint256 systemRate = systemRates[leaderAddress];
    uint256 commissionForLeader = MAX_COMMISSION.take(systemRate);
    pay(leaderAddress, commissionForLeader);
    pay(rootAdmin, MAX_COMMISSION - commissionForLeader);
  }

  function getDailyIncome(address investorAddress) internal view returns(uint256) {
    uint256[] memory investmentIds = investors[investorAddress].investments;
    uint256 length = investmentIds.length;
    uint256 result = 0;
    for (uint256 index = 0; index < length; index = index.add(1)) {
      Investment memory investment = investments[investmentIds[index]];
      uint256 dayCount = getNow().sub(investment.createdAt).div(ONE_DAY);
      result = result.add(investment.amount.take(dayCount));
    }
    return result;
  }

  function getLeader(address investorAddress) internal view returns(address) {
    address currentAddress = investorAddress;
    while (true) {
      if (isLeader(currentAddress)) return currentAddress;
      if (!isInvestorExists(currentAddress)) return EMPTY_ADDRESS;
      currentAddress = investors[currentAddress].presenterAddress;
    }
  }

  function verifyDeposit(address investorAddress, uint256 value) internal view {
    uint256 MAX = 50 trx;
    uint256 MIN = 1 trx;
    require(MIN <= value && value <= MAX, 'INVALID DEPOSIT VALUE');
    require(isInvestorExists(investorAddress), 'PLEASE REGISTER FIRST');
  }

  function hasReadPermissionOnAddress(address targetedAddress) internal view returns(bool) {
    address originalAddress = getOriginalAddress(msg.sender);
    bool isRootAdmin = originalAddress == rootAdmin;
    bool isMyAccount = originalAddress == targetedAddress;
    return isRootAdmin || isMyAccount;
  }

  function withdraw(uint256 amount) public mustNotBeReplacedAddress {
    address investorAddress = getOriginalAddress(msg.sender);
    require(getWithdrawable(investorAddress) >= amount, 'AMOUNT IS BIGGER THAN WITHDRAWABLE');
    Investor storage investor = investors[investorAddress];
    investor.withdrew = investor.withdrew.add(amount);

    uint256 FEE = 50 trx;
    uint160 toAddress = uint160(address(getCurrentAddress(investorAddress)));
    require(amount > FEE, 'TOO SMALL AMOUNT');
    address(toAddress).transfer(amount.sub(FEE));
    investors[rootAdmin].commission = investors[rootAdmin].commission.add(FEE);
    withdrawalCount = withdrawalCount.add(1);
    emit CreateWithdrawal(
      withdrawalCount,
      investorAddress,
      amount,
      getNow()
    );
  }

  function getNow() internal view returns(uint256) {
    return skippedTime.add(now);
  }

  function deposit() public payable {
    uint256 value = msg.value;
    address investorAddress = msg.sender;
    verifyDeposit(investorAddress, value);
    payDirectCommission(investorAddress, value);
    paySystemCommission(investorAddress, value);

    investmentCount = investmentCount.add(1);
    createInvestment(investmentCount, investorAddress, value, getNow());
    investors[investorAddress].deposited = investors[investorAddress].deposited.add(value);
  }

  function register(address presenterAddress) public payable {
    address investorAddress = msg.sender;
    require(isInvestorExists(presenterAddress), 'PRESENTER DOES NOT EXISTS');
    require(!isInvestorExists(investorAddress), 'ADDRESS IS USED');
    require(!isNewAddress(investorAddress), 'ADDRESS IS USED');
    createInvestor(
      investorAddress,
      presenterAddress,
      investors[presenterAddress].level.add(1)
    );
    if (msg.value != 0) deposit();
  }

  function setSystemRate(address leaderAddress, uint256 rate) public mustBeRootAdmin {
    uint256 MAX = 100;
    uint256 MIN = 0;
    require(rate <= MAX && rate >= MIN, 'INVALID RATE');
    require(isLeader(leaderAddress), 'NOT A LEADER');
    systemRates[leaderAddress] = rate;
  }

  function isInvestorExists(address investorAddress) internal view returns(bool) {
    return investors[investorAddress].level != 0;
  }

  function isLeader(address investorAddress) internal view returns(bool) {
    return investors[investorAddress].level == LEADER_LEVEL;
  }

  function getSystemRate(address leader) public view returns(uint256) {
    require(hasReadPermissionOnAddress(leader), 'PERMISSION DENIED');
    return systemRates[leader];
  }

  function pay(address to, uint256 amount) internal {
    bool invested = investors[to].deposited > 0;
    address receiver = invested ? to : rootAdmin;
    investors[receiver].commission = investors[receiver].commission.add(amount);
  }

  function getWithdrawable(address investorAddress) public view returns(uint256) {
    require(hasReadPermissionOnAddress(investorAddress), 'PERMISSION DENIED');
    Investor memory investor = investors[investorAddress];
    uint256 positive = investor.commission.add(getDailyIncome(investorAddress));
    uint256 negative = investor.withdrew;
    if (negative > positive) return 0;
    return positive.sub(negative);
  }
  
  function getInvestor(address investorAddr) public view returns(address investorAddress, address presenterAddress, uint256 level, uint256 deposited, uint256 withdrew, uint256 commission, uint256 withdrawable) {
    require(hasReadPermissionOnAddress(investorAddr), 'PERMISSION DENIED');
    Investor memory investor = investors[investorAddr];
    return (
      investor.investorAddress,
      investor.presenterAddress,
      investor.level,
      investor.deposited,
      investor.withdrew,
      investor.commission,
      getWithdrawable(investorAddr)
    );
  }

  function getInvestors(address[] memory listAddresses) public view returns (address[] memory investorAddresses, uint256[] memory depositeds, uint256[] memory withdrews, uint256[] memory commissions, uint256[] memory withdrawables) {
    uint256 length = listAddresses.length;

    investorAddresses = new address[](length);
    depositeds = new uint256[](length);
    withdrews = new uint256[](length);
    commissions = new uint256[](length);
    withdrawables = new uint256[](length);

    for (uint256 index = 0; index < length; index++) {
      Investor memory investor = investors[listAddresses[index]];
      investorAddresses[index] = investor.investorAddress;
      depositeds[index] = investor.deposited;
      withdrews[index] = investor.withdrew;
      commissions[index] = investor.commission;
      withdrawables[index] = getWithdrawable(listAddresses[index]);
    }
    return (investorAddresses, depositeds, withdrews, commissions, withdrawables);
  }

  function () external payable { deposit(); }
}