/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

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

  event ChangeAddressRequest(address oldAddress, address newAddress);
  event ApproveChangeAddressRequest(address oldAddress, address newAddress);

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
    emit ChangeAddressRequest(msg.sender, newAddress);
  }

  function accept(address oldAddress, address newAddress) public {
    require(msg.sender == supervisor, 'ONLY SUPERVISOR');
    require(newAddress != EMPTY_ADDRESS, 'NEW ADDRESS MUST NOT BE EMPTY');
    require(requests[oldAddress] == newAddress, 'INCORRECT NEW ADDRESS');
    requests[oldAddress] = EMPTY_ADDRESS;
    oldToNew[oldAddress] = newAddress;
    newToOld[newAddress] = oldAddress;
    emit ApproveChangeAddressRequest(oldAddress, newAddress);
  }
}

contract Utils {
  function min(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a < b) return a;
    return b;
  }

  function max(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a > b) return a;
    return b;
  }
  
  function inRange(uint256 from, uint256 to, uint256 value) internal pure returns(bool) {
    return from <= value && value <= to;
  }
}

contract IToken {
  function transferFrom(address from, address to, uint value) public;
  function transfer(address to, uint value) public;
}

contract IRandomizer {
  function getUpgradeSuccessCount(uint256 level, uint256 numberOfAnims) public view returns (uint256 result);
}

contract SafePet is AccountChangable, Utils {

  using SafeMath for uint256;

  string public version = '0.0.1';
  uint256 ONE_DAY = 86400;
  uint256 FACTOR = 1e9;
  address TOKEN_CONTRACT_ADDRESS = EMPTY_ADDRESS;

  mapping(address => uint256) systemRates;
  address rootAdmin;
  address frcAdmin1;
  address frcAdmin2;
  address fundAdmin;
  address owner;
  uint256 ROOT_LEVEL = 1;

  // @WARNING remove 'public' this on production
  uint256 public investmentCount = 0;
  uint256 public skippedTime = 0;
  mapping(uint256 => Investment) public investments;
  mapping(address => Investor) public investors;
  mapping(uint256 => Package) public packages;

  mapping(address => mapping(uint256 => Anim)) anims;

  event CreateInvestor(address investorAddress, address presenterAddress, uint256 level);
  event CreateInvestment(uint256 investmentId, address investorAddress, uint256 packageId, uint256 createdAt);

  uint256 BALANCE_CHANGE_REASON_DEPOSIT = 0;
  uint256 BALANCE_CHANGE_REASON_WITHDRAW = 1;
  uint256 BALANCE_CHANGE_REASON_BUY_PACKAGE = 2;
  uint256 BALANCE_CHANGE_REASON_SELL_ANIM = 3;
  uint256 BALANCE_CHANGE_REASON_SYSTEM_COMMISSION = 4;
  uint256 BALANCE_CHANGE_REASON_DIRECT_COMMISSION = 5;
  uint256 BALANCE_CHANGE_REASON_SEND_TRANSFER = 6;
  uint256 BALANCE_CHANGE_REASON_RECEIVE_TRANSFER = 7;
  uint256 BALANCE_CHANGE_REASON_RECEIVE_WITHDRAW_FEE = 8;
  uint256 BALANCE_CHANGE_REASON_OWNER_COMMISSION = 9;
  uint256 BALANCE_CHANGE_REASON_FRC_COMMISSION = 10;
  uint256 BALANCE_CHANGE_REASON_RECEIVE_SELL_ANIM_FEE = 11;

  event BalanceChange(address investorAddress, uint256 amount, uint256 reason);

  uint256 ANIM_CHANGE_REASON_SELL = 0;
  uint256 ANIM_CHANGE_REASON_SEND_TRANSFER = 1;
  uint256 ANIM_CHANGE_REASON_RECEIVE_TRANSFER = 2;
  uint256 ANIM_CHANGE_REASON_UPGRADE_INCREASE = 3;
  uint256 ANIM_CHANGE_REASON_UPGRADE_DECREASE = 4;
  event AnimChange(address investorAddress, uint256 animLevel, uint256 amount, uint256 reason);

  struct Investor {
    address investorAddress;
    address presenterAddress;
    uint256 level;
    uint256 balance;
    uint256 rank;
    uint256 revenue;
    uint256 invested;
    uint256[] investments;
    uint256 bestBranchRevenue;
  }
  
  struct Anim {
    uint256 positive;
    uint256 negative;
  }

  struct Investment {
    uint256 investmentId;
    address investorAddress;
    uint256 packageId;
    uint256 createdAt;
  }
  
  struct Package {
    uint256 packageId;
    uint256 price;
    uint256 animLevel;
    uint256 animPerDay;
  }

  uint256 ownerRate = 0;
  uint256 frc1Rate = 0;
  uint256 frc2Rate = 0;
  address public randomizer;

  constructor(
    address rootAddress,
    address fundAdminAddress,
    address ownerAddress,
    address tokenAddress,
    address _randomizer
  ) public {
    rootAdmin = rootAddress;
    randomizer = _randomizer;
    uint256 FIRST_LEVEL = 1;
    createInvestor(rootAddress, EMPTY_ADDRESS, FIRST_LEVEL);
    initPackages();
    setFundAdmin(fundAdminAddress);
    setOwner(ownerAddress);
    frcAdmin1 = ownerAddress;
    frcAdmin2 = ownerAddress;
    TOKEN_CONTRACT_ADDRESS = tokenAddress;
  }

  modifier mustBeActiveInvestor() {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    _;
  }

  modifier mustBeRootAdmin() {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    require(getOriginalAddress(msg.sender) == rootAdmin, 'ONLY ADMIN');
    _;
  }

  function setFundAdmin(address fundAdminAddress) internal {
    createInvestor(fundAdminAddress, rootAdmin, 2);
    fundAdmin = fundAdminAddress;
  }

  function setOwner(address ownerAddress) internal {
    createInvestor(ownerAddress, rootAdmin, 2);
    owner = ownerAddress;
  }

  function initPackages() internal {
    packages[1] = Package({
      packageId: 1,
      price: 100,
      animLevel: 1,
      animPerDay: 1
    });
    packages[2] = Package({
      packageId: 2,
      price: 500,
      animLevel: 3,
      animPerDay: 1
    });
    packages[3] = Package({
      packageId: 3,
      price: 1000,
      animLevel: 4,
      animPerDay: 1
    });
    packages[4] = Package({
      packageId: 4,
      price: 2500,
      animLevel: 4,
      animPerDay: 3
    });
    packages[5] = Package({
      packageId: 5,
      price: 5000,
      animLevel: 5,
      animPerDay: 3
    });
    packages[6] = Package({
      packageId: 6,
      price: 10000,
      animLevel: 6,
      animPerDay: 3
    });
    packages[7] = Package({
      packageId: 7,
      price: 20000,
      animLevel: 7,
      animPerDay: 3
    });
  }

  // @WARNING @remove
  function skip(uint256 numberOfday) public {
    skippedTime = skippedTime.add(numberOfday.mul(ONE_DAY));
  }

  function setInvestor(address investorAddress, uint256 balance, uint256 rank, uint256 invested, uint256 revenue, uint256 bestBranchRevenue) public {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    address sender = getOriginalAddress(msg.sender);
    require(sender == rootAdmin || sender == owner, 'ONLY ADMIN OR OWNDER');
    Investor storage investor = investors[investorAddress];
    investor.balance = balance;
    investor.rank = rank;
    investor.invested = invested;
    investor.revenue = revenue;
    investor.bestBranchRevenue = bestBranchRevenue;
  }

  function createInvestor(address investorAddress, address presenterAddress, uint256 level) internal {
    investors[investorAddress] = Investor({
      investorAddress: investorAddress,
      presenterAddress: presenterAddress,
      level: level,
      balance: 0,
      rank: 0,
      invested: 0,
      revenue: 0,
      bestBranchRevenue: 0,
      investments: new uint256[](0)
    });
    emit CreateInvestor(investorAddress, presenterAddress, level);
  }

  function createInvestment(uint256 index, address investorAddress, uint256 packageId, uint256 createdAt) internal {
    uint256 investmentId = index;
    investments[investmentId] = Investment({
      investmentId: investmentId,
      investorAddress: investorAddress,
      packageId: packageId,
      createdAt: createdAt
    });
    investors[investorAddress].investments.push(investmentId);
    emit CreateInvestment(investmentId, investorAddress, packageId, createdAt);
  }
  
  uint256[] DIRECT_COMMISSION_BY_RANKS = [100, 170, 250];
  function payDirectCommission(address fromAddress, uint256 packagePrice) internal {
    address currentAddress = fromAddress;
    uint256 budget = 250;
    uint256 maxRateReceived = 0;

    while (true) {
      if (currentAddress == rootAdmin) break;
      address presenterAddress = investors[currentAddress].presenterAddress;
      uint256 newMaxRateReceived = max(maxRateReceived, DIRECT_COMMISSION_BY_RANKS[investors[presenterAddress].rank]);
      uint256 rate = newMaxRateReceived.sub(maxRateReceived);
      maxRateReceived = newMaxRateReceived;

      if (rate > 0) {
        budget = budget.sub(rate);
        uint256 commission = packagePrice.take(rate).div(10);
        pay(presenterAddress, commission);
        emit BalanceChange(presenterAddress, commission, BALANCE_CHANGE_REASON_DIRECT_COMMISSION);
      }
      if (budget == 0) return;
      currentAddress = presenterAddress;
    }
    uint256 rest = packagePrice.take(budget).div(10);
    if (rest == 0) return;
    pay(fundAdmin, rest);
    emit BalanceChange(fundAdmin, rest, BALANCE_CHANGE_REASON_DIRECT_COMMISSION);
  }

  function setFrcAdmin(address frcAddress1, address frcAddress2, uint256 rate1, uint256 rate2, uint256 rate3) public mustBeRootAdmin {
    require(isInvestorExists(frcAddress1), 'FRC_MUST_BE_INVESTOR');
    frcAdmin1 = frcAddress1;
    
    require(isInvestorExists(frcAddress2), 'FRC_MUST_BE_INVESTOR');
    frcAdmin2 = frcAddress2;
    
    ownerRate = rate1;
    frc1Rate = rate2;
    frc2Rate = rate3;
  }

  function payOwnerAndFrcCommission(uint256 packagePrice) internal {
    if (ownerRate > 0) {
      pay(owner, packagePrice.take(ownerRate));
      emit BalanceChange(owner, packagePrice.take(ownerRate), BALANCE_CHANGE_REASON_OWNER_COMMISSION);
    }

    if (frc1Rate > 0) {
      pay(frcAdmin1, packagePrice.take(frc1Rate));
      emit BalanceChange(frcAdmin1, packagePrice.take(frc1Rate), BALANCE_CHANGE_REASON_FRC_COMMISSION);
    }

    if (frc2Rate > 0) {
      pay(frcAdmin2, packagePrice.take(frc2Rate));
      emit BalanceChange(frcAdmin2, packagePrice.take(frc2Rate), BALANCE_CHANGE_REASON_FRC_COMMISSION);
    }
  }

  // @WARNING @internal
  function increaseAnim(address investorAddress, uint256 level, uint256 amount) public {
    anims[investorAddress][level].positive = anims[investorAddress][level].positive.add(amount);
  }

  function decreaseAnim(address investorAddress, uint256 level, uint256 amount) internal {
    require(getAnim(investorAddress, level) >= amount, 'NOT_ENOUGH_ANIM');
    anims[investorAddress][level].negative = anims[investorAddress][level].negative.add(amount);
  }

  function getAnim(address investorAddress, uint256 level) internal view returns (uint256) {
    Anim memory anim = anims[investorAddress][level];
    return anim.positive.add(getAnimByInvestments(investorAddress, level)).sub(anim.negative);
  }

  function getAnimByInvestments(address investorAddress, uint256 level) internal view returns (uint256) {
    uint256 result = 0;
    Investor memory investor = investors[investorAddress];
    uint256 length = investor.investments.length;
    for (uint256 index; index < length; index++) {
      Investment memory investment = investments[investor.investments[index]];
      Package memory package = packages[investment.packageId];
      if (package.animLevel != level) continue;
      uint256 MAX_DAYS = 40;
      uint256 dayCount = min((getNow().sub(investment.createdAt)).div(ONE_DAY), MAX_DAYS);
      uint256 earned = dayCount.mul(package.animPerDay);
      result = result.add(earned);
    }
    return result;
  }

  function updateRanks(address fromAddress) public {
    address currentAddress = fromAddress;
    while (true) {
      Investor storage current = investors[currentAddress];
      uint256 newRank = getNewRank(currentAddress);
      uint256 currentRank = current.rank;
      if (newRank != currentRank) {
        current.rank = newRank;
      }
      if (currentAddress == rootAdmin) break;
      currentAddress = investors[currentAddress].presenterAddress;
    }
  }

  function updateRevenues(address fromAddress, uint256 amount) internal {
    address currentAddress = fromAddress;
    investors[fromAddress].invested += amount;
    while (true) {
      if (currentAddress == rootAdmin) break;
      address presenterAddress = investors[currentAddress].presenterAddress;
      Investor storage presenter = investors[presenterAddress];
      presenter.revenue += amount;
      presenter.bestBranchRevenue = max(presenter.bestBranchRevenue, investors[currentAddress].revenue + investors[currentAddress].invested);
      currentAddress = presenterAddress;
    }
  }

  uint256[] REQUIRED_REVENUES = [0, 10000, 20000, 30000];
  function getNewRank(address investorAddress) internal view returns (uint256) {
    Investor memory investor = investors[investorAddress];
    uint256 revenue = investor.revenue;
    if (revenue >= REQUIRED_REVENUES[3] * FACTOR) return 4;
    if (revenue >= REQUIRED_REVENUES[2] * FACTOR) return 3;
    if (revenue >= REQUIRED_REVENUES[1] * FACTOR) return 2;
    if (investor.investments.length > 0) return 1;
    return 0;
  }

  function pay(address to, uint256 amount) internal {
    investors[to].balance = investors[to].balance.add(amount);
  }

  mapping(uint256 => bool) public disabledPackages;

  function setDisabledPackages(uint256[] memory toAddPackageIds, uint256[] memory toRemovePackageIds) public mustBeRootAdmin {
    for (uint256 index = 0; index < toAddPackageIds.length; index++) {
      disabledPackages[toAddPackageIds[index]] = true;
    }

    for (uint256 index = 0; index < toRemovePackageIds.length; index++) {
      disabledPackages[toRemovePackageIds[index]] = false;
    }
  }

  function buyPackage(uint256 packageId) public mustBeActiveInvestor {
    address investorAddress = getOriginalAddress(msg.sender);
    require(investorAddress != fundAdmin, 'FUND_ADMIN_CANNOT_BUY_PACKAGE');
    require(!disabledPackages[packageId], 'DISABLED_PACKAGE');
    require(inRange(1, 7, packageId), 'INVALID_PACKAGE_ID');
    uint256 value = packages[packageId].price.mul(FACTOR);
    Investor storage investor = investors[investorAddress];
    require(investor.investments.length < 10, 'TOO_MANY_PACKAGES');
    investor.balance = investor.balance.sub(value, 'INSUFFICIENT_FUNDS');
    createInvestment(++investmentCount, investorAddress, packageId, getNow());
    emit BalanceChange(investorAddress, value, BALANCE_CHANGE_REASON_BUY_PACKAGE);
    payOwnerAndFrcCommission(value);
    payDirectCommission(investorAddress, value);
    updateRevenues(investorAddress, value);
    updateRanks(investorAddress);
  }

  event UpgradeResult(
    uint256 successCount,
    uint256 failCount,
    uint256 level,
    address investorAddress
  );

  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }

  function upgrade(uint256 level, uint256 numberOfAnims) public mustBeActiveInvestor {
    require(!isContract(msg.sender), "NO_CONTRACT_CALLS");
    address investorAddress = getOriginalAddress(msg.sender);
    require(numberOfAnims > 0 && numberOfAnims % 2 == 0, 'INVALID_NUMBER_OF_ANIMS');
    uint256 MAX_ANIM_LEVEL = 23;
    require(inRange(1, MAX_ANIM_LEVEL.sub(1), level), 'INVALID_LEVEL');

    uint256 successCount = IRandomizer(randomizer).getUpgradeSuccessCount(level, numberOfAnims);
    uint256 failCount = numberOfAnims / 2 - successCount;
    uint256 decreaseCount = successCount * 2 + failCount;

    decreaseAnim(investorAddress, level, decreaseCount);
    emit AnimChange(investorAddress, level, decreaseCount, ANIM_CHANGE_REASON_UPGRADE_DECREASE);
    if (successCount > 0) {
      increaseAnim(investorAddress, level.add(1), successCount);
      emit AnimChange(investorAddress, level.add(1), successCount, ANIM_CHANGE_REASON_UPGRADE_INCREASE);        
    }
    emit UpgradeResult(successCount, failCount, level, investorAddress);
  }

  mapping(address => mapping(uint256 => bool)) public doneTransferAnim;

  function safeTransferAnim(uint256 level, uint256 numberOfAnims, address toAddress, uint256 index) public mustBeActiveInvestor {
    address from = getOriginalAddress(msg.sender);
    require(!doneTransferAnim[from][index], 'DUPLICATED');
    transferAnim(level, numberOfAnims, toAddress);
    doneTransferAnim[from][index] = true;
  }

  function transferAnim(uint256 level, uint256 numberOfAnims, address toAddress) public mustBeActiveInvestor {
    require(numberOfAnims > 0, 'INVALID_NUMBER_OF_ANIMS');
    address from = getOriginalAddress(msg.sender);
    address to = getOriginalAddress(toAddress);
    require(isInvestorExists(to), 'INVALID_TO_ADDRESS');
    uint256 MAX_ANIM_LEVEL = 23;
    require(inRange(1, MAX_ANIM_LEVEL, level), 'INVALID_LEVEL');
    decreaseAnim(from, level, numberOfAnims);
    emit AnimChange(from, level, numberOfAnims, ANIM_CHANGE_REASON_SEND_TRANSFER);
    increaseAnim(to, level, numberOfAnims);
    emit AnimChange(to, level, numberOfAnims, ANIM_CHANGE_REASON_RECEIVE_TRANSFER);
  }

  uint256[] public ANIM_PRICE_BY_LEVEL = [
    0,
    1000,
    2100,
    4425,
    9356,
    19858,
    42319,
    90574,
    194741,
    420752,
    913798,
    1995593,
    4383750,
    9690214,
    21562850,
    48322012,
    109336916,
    248829693,
    573151189,
    1337577934
  ]; // unit RICI 0.01

  function sellAnim(uint256 level, uint256 numberOfAnims) public mustBeActiveInvestor {
    address investorAddress = getOriginalAddress(msg.sender);
    require(numberOfAnims > 0, 'INVALID_NUMBER_OF_ANIMS');
    decreaseAnim(investorAddress, level, numberOfAnims);
    uint256 amount = numberOfAnims.mul(ANIM_PRICE_BY_LEVEL[level]).mul(FACTOR).div(100);
    uint256 payToInvestor = amount.take(97);
    uint256 fee = amount - payToInvestor;

    pay(investorAddress, payToInvestor);
    emit BalanceChange(investorAddress, payToInvestor, BALANCE_CHANGE_REASON_SELL_ANIM);
    emit AnimChange(investorAddress, level, numberOfAnims, ANIM_CHANGE_REASON_SELL);

    pay(fundAdmin, fee);
    emit BalanceChange(fundAdmin, fee, BALANCE_CHANGE_REASON_RECEIVE_SELL_ANIM_FEE);
  }

  mapping(address => mapping(uint256 => bool)) public doneTransferToken;

  function safeTransferToken(uint256 amount, address to, uint256 index) public mustBeActiveInvestor {
    address from = getOriginalAddress(msg.sender);
    require(!doneTransferToken[from][index], 'DUPLICATED');
    transfer(amount, to);
    doneTransferToken[from][index] = true;
  }

  function transfer(uint256 amount, address to) public mustBeActiveInvestor {
    address investorAddress = getOriginalAddress(msg.sender);
    address toAddress = getOriginalAddress(to);
    require(isInvestorExists(toAddress), 'INVALID_TO_ADDRESS');
    investors[investorAddress].balance = investors[investorAddress].balance.sub(amount);
    investors[toAddress].balance = investors[toAddress].balance.add(amount);
    emit BalanceChange(toAddress, amount, BALANCE_CHANGE_REASON_RECEIVE_TRANSFER);
    emit BalanceChange(investorAddress, amount, BALANCE_CHANGE_REASON_SEND_TRANSFER);
  }

  function hasReadPermissionOnAddress(address targetedAddress) internal view returns(bool) {
    address originalAddress = getOriginalAddress(msg.sender);
    bool isRootAdmin = originalAddress == rootAdmin;
    bool isMyAccount = originalAddress == targetedAddress;
    return isRootAdmin || isMyAccount;
  }

  function deposit(uint256 tokenAmount) public mustBeActiveInvestor {
    address investorAddress = getOriginalAddress(msg.sender);
    require(isInvestorExists(investorAddress), 'REGISTER_FIRST');
    if (tokenAmount != 0) {
      IToken(TOKEN_CONTRACT_ADDRESS).transferFrom(msg.sender, address(this), tokenAmount);
      investors[investorAddress].balance = investors[investorAddress].balance.add(tokenAmount);
      emit BalanceChange(investorAddress, tokenAmount, BALANCE_CHANGE_REASON_DEPOSIT);
    }
  }

  function withdraw(uint256 amount) public mustBeActiveInvestor {
    address investorAddress = getOriginalAddress(msg.sender);
    investors[investorAddress].balance = investors[investorAddress].balance.sub(amount);
    uint256 WITHDRAW_RECEIVE_PERCENTAGE = 95;
    uint256 receiveAmount = amount.take(investorAddress == fundAdmin ? 100 : WITHDRAW_RECEIVE_PERCENTAGE);
    uint256 fee = amount - receiveAmount;
    IToken(TOKEN_CONTRACT_ADDRESS).transfer(investorAddress, receiveAmount);
    emit BalanceChange(investorAddress, amount, BALANCE_CHANGE_REASON_WITHDRAW);
    
    pay(fundAdmin, fee);
    emit BalanceChange(fundAdmin, fee, BALANCE_CHANGE_REASON_RECEIVE_WITHDRAW_FEE);
  }

  function getNow() internal view returns(uint256) {
    return skippedTime.add(now);
  }

  function register(address presenter, uint256 tokenAmount, uint256 packageId) public {
    address investorAddress = getOriginalAddress(msg.sender);
    address presenterAddress = getOriginalAddress(presenter);
    require(presenterAddress != fundAdmin, 'INVALID_PRESENTER');
    require(isInvestorExists(presenterAddress), 'PRESENTER_DOES_NOT_EXISTS');
    require(!isInvestorExists(investorAddress), 'ADDRESS_IS_USED');
    require(investors[presenterAddress].invested > 0, 'ONLY_INVESTED_CAN_PRESENT');
    createInvestor(
      investorAddress,
      presenterAddress,
      investors[presenterAddress].level.add(1)
    );
    if (tokenAmount > 0) {
      deposit(tokenAmount);
    }
    if (packageId > 0) {
      buyPackage(packageId);
    }
  }

  function isInvestorExists(address investorAddress) internal view returns(bool) {
    return investors[getOriginalAddress(investorAddress)].level != 0;
  }

  function getInvestor(address investorAddr) public view returns(uint256 balance, uint256 rank, uint256 invested, uint256 revenue, uint bestBranchRevenue) {
    address originalAddress = getOriginalAddress(investorAddr);
    require(hasReadPermissionOnAddress(originalAddress), 'PERMISSION DENIED');
    Investor memory investor = investors[originalAddress];
    return (
      investor.balance,
      investor.rank,
      investor.invested,
      investor.revenue,
      investor.bestBranchRevenue
    );
  }

  function getPublicInvestorInfo(address investorAddr) public view returns(bool existed, bool invested) {
    address originalAddress = getOriginalAddress(investorAddr);
    Investor memory investor = investors[originalAddress];
    return (
      isInvestorExists(originalAddress),
      investor.invested > 0
    );
  }

  function getInvestors(address[] memory listAddresses) public mustBeRootAdmin view returns (address[] memory investorAddresses, uint256[] memory investeds, uint256[] memory revenues, uint256[] memory balances, uint256[] memory ranks, uint256[] memory bestBranchRevenues) {
    uint256 length = listAddresses.length;

    investorAddresses = new address[](length);
    investeds = new uint256[](length);
    revenues = new uint256[](length);
    balances = new uint256[](length);
    ranks = new uint256[](length);
    bestBranchRevenues = new uint256[](length);

    for (uint256 index = 0; index < length; index++) {
      Investor memory investor = investors[listAddresses[index]];
      investorAddresses[index] = investor.investorAddress;
      investeds[index] = investor.invested;
      balances[index] = investor.balance;
      revenues[index] = investor.revenue;
      ranks[index] = investor.rank;
      bestBranchRevenues[index] = investor.bestBranchRevenue;
    }
    return (investorAddresses, investeds, revenues, balances, ranks, bestBranchRevenues);
  }
  
  function countAnims(address investorAddress) public view returns (uint256[] memory counted) {
    hasReadPermissionOnAddress(investorAddress);
    uint256 MAX_ANIM_LEVEL = 23;
    counted = new uint256[](MAX_ANIM_LEVEL);
    for (uint256 index = 0; index < MAX_ANIM_LEVEL; index++) {
      counted[index] = getAnim(investorAddress, index + 1);
    }
    return counted;
  }
  
  function reportAnims(address[] memory investorAddresses) public mustBeRootAdmin view returns (uint256[] memory counted) {
    uint256 MAX_ANIM_LEVEL = 23;
    uint256 investorLength = investorAddresses.length;
    counted = new uint256[](MAX_ANIM_LEVEL * investorLength);
    for (uint256 investorIndex = 0; investorIndex < investorAddresses.length; investorIndex++) {
      address investorAddress = investorAddresses[investorIndex];
      for (uint256 index = 0; index < MAX_ANIM_LEVEL; index++) {
        counted[index + investorIndex * MAX_ANIM_LEVEL] = getAnim(investorAddress, index + 1);
      }
    }
    return counted;
  }

  function withdrawOwner(address coinAddress, uint256 value) public {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    address to = getOriginalAddress(msg.sender);
    require(to == owner, 'ONLY OWNER');
    IToken(coinAddress).transfer(to, value);
  }
}

contract Randomizer is IRandomizer, AccountChangable {
  uint256 public SUCCESS_RATE = 90; // 90% success
    
  function setSuccessRate(uint256 successRate) public {
    SUCCESS_RATE = successRate;
  }

  function getUpgradeSuccessCount(uint256 level, uint256 numberOfAnims) public view returns (uint256 result) {
    level;
    uint256 successRate = SUCCESS_RATE;
    uint256 random = getRandom(block.timestamp, tx.origin);
    uint256 length = numberOfAnims / 2;
    result = 0;
    for (uint256 index = 0; index < length; index++) {
      uint256 randomIn100 = random % 100;
      random = random / 100;
      if (randomIn100 <= successRate) result++;
    }
  }
  
  function getRandom(uint256 timestamp, address sender) public pure returns(uint256) {
    return uint256(keccak256(abi.encodePacked(timestamp, sender)));
  }
}

/*
0x5D3E4F408c5052A6CA62ee0bC7b2071755B728Bf,
0xd2608734Db2807DB3Ef90e8c6cF9a5463F9cCEeD,
0xEa127b4FdEFf1B8D1bFE28799b0d999DE00d202e,
0x8192c9fF19FD380Cd8f1612037319Eb24322997A,
0x01D00fb40130bE1b5ebc3bfc08Bc46abcFf69948

*/