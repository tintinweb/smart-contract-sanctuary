//SourceUnit: DefiProd.sol

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

contract IToken {
  function transferFrom(address from, address to, uint value) public;
  function transfer(address to, uint value) public;
}

contract Defi is AccountChangable, Utils {

  using SafeMath for uint256;
  address USDT_CONTRACT_ADDRESS;
  address SHF_CONTRACT_ADDRESS;

  string public version = '1.0.0';
  uint256 ONE_DAY = 86400;

  address rootAdmin;
  address builderFund;
  address lotteryFund;
  uint256 ROOT_LEVEL = 1;

  mapping(address => Investor) investors;

  event CreateInvestor(address investorAddress, address presenterAddress, uint256 level);
  event BalanceChange(address investorAddress, uint256 amount, address tokenAddress, uint256 reason);

  struct Investor {
    address investorAddress;
    address presenterAddress;
    uint256 level;
    uint256 usdtBalance;
    uint256 shfBalance;
    uint256 rank; // default = 0; silver = 1; gold = 2; diamond = 3
    uint256 investedF1;
    uint256 silverF1;
    uint256 goldF1;
    uint256 lastPackageCreatedAt;
  }

  uint256 BALANCE_CHANGE_REASON_DEPOSIT = 0;
  uint256 BALANCE_CHANGE_REASON_WITHDRAW = 1;
  uint256 BALANCE_CHANGE_REASON_BUY_PACKAGE = 2;
  uint256 BALANCE_CHANGE_REASON_SYSTEM_COMMISSION = 3;
  uint256 BALANCE_CHANGE_REASON_DIRECT_COMMISSION = 4;
  uint256 BALANCE_CHANGE_REASON_SEND_TRANSFER = 5;
  uint256 BALANCE_CHANGE_REASON_RECEIVE_TRANSFER = 6;
  uint256 BALANCE_CHANGE_REASON_RECEIVE_WITHDRAW_FEE = 7;
  uint256 BALANCE_CHANGE_REASON_CLAIM = 8;
  uint256 BALANCE_CHANGE_REASON_CLAIM_COMMISSION = 9;
  uint256 BALANCE_CHANGE_REASON_BUILDER_FUND = 10;
  uint256 BALANCE_CHANGE_REASON_LOTTERY_FUND = 11;
  uint256 BALANCE_CHANGE_REASON_SWAP_FROM = 12;
  uint256 BALANCE_CHANGE_REASON_SWAP_TO = 13;
  uint256 BALANCE_CHANGE_REASON_SWAP_FEE = 14;
  uint256 BALANCE_CHANGE_REASON_WITHDRAW_FEE = 15;

  uint256 public startAt;

  constructor(address rootAddress, address usdtAddress, address shfAddress) public {
    USDT_CONTRACT_ADDRESS = usdtAddress;
    SHF_CONTRACT_ADDRESS = shfAddress;
    rootAdmin = rootAddress;
    builderFund = rootAddress;
    lotteryFund = rootAddress;
    uint256 FIRST_LEVEL = 1;
    createInvestor(rootAddress, EMPTY_ADDRESS, FIRST_LEVEL);
    startAt = now;
  }

  modifier mustNotBeReplacedAddress() {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    _;
  }

  modifier mustBeRootAdmin() {
    require(!isReplaced(msg.sender), 'REPLACED ADDRESS');
    require(getOriginalAddress(msg.sender) == rootAdmin, 'ONLY ADMIN');
    _;
  }

  /*
    rate = 1     means 1.000.000 SHF for 1 USDT
    rate = 10    means   100.000 SHF for 1 USDT
    rate = 100   means    10.000 SHF for 1 USDT
    rate = 1.000  means     1.000 SHF for 1 USDT
    rate = 10.000  means      100 SHF for 1 USDT
    rate = 100.000  means      10 SHF for 1 USDT
    rate = 1.000.000  means     1 SHF for 1 USDT
    rate = 10.000.000  means  0.1 SHF for 1 USDT
  */

  uint256 public rate = 150000; 

  event SetRate(uint256 rate);

  function setRate(uint256 newRate) public mustBeRootAdmin {
    rate = newRate;
    emit SetRate(rate);
  }

  function convertUsdtToShf(uint256 usdtAmount) public view returns (uint256) {
    return (10 ** 12) * 1000000 * usdtAmount / rate;
  }

  function convertShfToUsdt(uint256 shfAmount) public view returns (uint256) {
    return shfAmount * rate / (10 ** 12) / 1000000;
  }

  function setInvestor(address investorAddress, uint256 usdtBalance, uint256 shfBalance, uint256 rank, uint256 investedF1, uint256 silverF1, uint256 goldF1, uint256 lastPackageCreatedAt) public {
    Investor storage investor = investors[investorAddress];
    investor.usdtBalance = usdtBalance;
    investor.shfBalance = shfBalance;
    investor.rank = rank;
    investor.investedF1 = investedF1;
    investor.silverF1 = silverF1;
    investor.goldF1 = goldF1;
    investor.lastPackageCreatedAt = lastPackageCreatedAt;
  }

  function createInvestor(address investorAddress, address presenterAddress, uint256 level) internal {
    investors[investorAddress] = Investor({
      investorAddress: investorAddress,
      presenterAddress: presenterAddress,
      level: level,
      usdtBalance: 0,
      shfBalance: 0,
      investedF1: 0,
      silverF1: 0,
      goldF1: 0,
      rank: 0,
      lastPackageCreatedAt: 0
    });
    emit CreateInvestor(investorAddress, presenterAddress, level);
  }

  function hasReadPermissionOnAddress(address targetedAddress) internal view returns(bool) {
    if (isReplaced(msg.sender)) return false;
    address originalAddress = getOriginalAddress(msg.sender);
    bool isRootAdmin = originalAddress == rootAdmin;
    bool isMyAccount = originalAddress == targetedAddress;
    return isRootAdmin || isMyAccount;
  }
  function () external payable {}

  function getNow() internal view returns(uint256) {
    return now;
  }

  function deposit(uint256 amount, bool isUsdt) public {
    address investorAddress = getOriginalAddress(msg.sender);
    require(isInvestor(investorAddress), 'REGISTER_FIRST');
    if (amount == 0) return;
    address tokenAddress = isUsdt ? USDT_CONTRACT_ADDRESS : SHF_CONTRACT_ADDRESS;
    IToken(tokenAddress).transferFrom(msg.sender, address(this), amount);
    increaseBalance(
      investorAddress,
      amount,
      tokenAddress,
      BALANCE_CHANGE_REASON_DEPOSIT
    );
  }

  function increaseBalance(address investorAddress, uint256 value, address tokenAddress, uint256 reason) internal {
    Investor storage investor = investors[investorAddress];
    if (tokenAddress == USDT_CONTRACT_ADDRESS) {
      investor.usdtBalance = investor.usdtBalance.add(value);
    } else {
      investor.shfBalance = investor.shfBalance.add(value);
    }
    emit BalanceChange(investorAddress, value, tokenAddress, reason);
  }

  function decreaseBalance(address investorAddress, uint256 value, address tokenAddress, uint256 reason, string memory errorMessage) internal {
    Investor storage investor = investors[investorAddress];
    if (tokenAddress == USDT_CONTRACT_ADDRESS) {
      investor.usdtBalance = investor.usdtBalance.sub(value, errorMessage);
    } else {
      investor.shfBalance = investor.shfBalance.sub(value, errorMessage);
    }
    emit BalanceChange(investorAddress, value, tokenAddress, reason);
  }

  function register(address presenter, uint256 usdtAmount, uint256 shfAmount) public {
    address investorAddress = getOriginalAddress(msg.sender);
    address presenterAddress = getOriginalAddress(presenter);
    require(!isInvestor(investorAddress), 'ADDRESS_IS_USED');
    createInvestor(
      investorAddress,
      presenterAddress,
      investors[presenterAddress].level.add(1)
    );
    bool isUsdt = true;
    if (usdtAmount != 0) deposit(usdtAmount, isUsdt);
    if (shfAmount != 0) deposit(shfAmount, !isUsdt);
  }

  uint256 public PACKAGE_PRICE_IN_USDT = 135000000;
  uint256 public DIRECT_COMMISSION_RATE = 8;

  function buyPackage(uint256 usdtAmount) public mustNotBeReplacedAddress {
    address originalAddress = getOriginalAddress(msg.sender);
    Investor storage investor = investors[originalAddress];
    bool hasActivePackage = (
      investor.lastPackageCreatedAt != 0 &&
      getNow() - investor.lastPackageCreatedAt <= 30 * ONE_DAY
    );
    require(!hasActivePackage, 'HAS_ACTIVE_PACKAGE');
    require(usdtAmount <= PACKAGE_PRICE_IN_USDT, 'TOO_MUCH_USDT');
    if (usdtAmount != 0) decreaseBalance(
      originalAddress,
      usdtAmount,
      USDT_CONTRACT_ADDRESS,
      BALANCE_CHANGE_REASON_BUY_PACKAGE,
      'NOT_ENOUGH_USDT'
    );

    uint256 shfAmount = convertUsdtToShf(PACKAGE_PRICE_IN_USDT - usdtAmount);
    if (shfAmount != 0) decreaseBalance(
      originalAddress,
      shfAmount,
      SHF_CONTRACT_ADDRESS,
      BALANCE_CHANGE_REASON_BUY_PACKAGE,
      'NOT_ENOUGH_SHF'
    );
    payToFunds();
    payCommissionForPresenters(
      investor.presenterAddress,
      convertUsdtToShf(PACKAGE_PRICE_IN_USDT.take(DIRECT_COMMISSION_RATE)),
      BALANCE_CHANGE_REASON_DIRECT_COMMISSION
    );
    payCommissionForPresenters(
      investors[investor.presenterAddress].presenterAddress,
      convertUsdtToShf(PACKAGE_PRICE_IN_USDT.take(DIRECT_COMMISSION_RATE)),
      BALANCE_CHANGE_REASON_DIRECT_COMMISSION
    );
    paySystemCommission(originalAddress);
    if (investor.lastPackageCreatedAt == 0) updatePresenterRanks(originalAddress);
    createPackage(originalAddress);
  }

  function updatePresenterRanks(address investorAddress) internal {
    address presenterAddress = investors[investorAddress].presenterAddress;
    investors[presenterAddress].investedF1++;
    address next = presenterAddress;
    for (uint256 step = 1; step <= 3; step++) {
      Investor storage investor = investors[next];
      uint256 newRank = getNewRank(investor);
      if (newRank == investor.rank) return;
      investor.rank = newRank;
      next = investor.presenterAddress;
      if (newRank == 1) investors[next].silverF1++;
      if (newRank == 2) investors[next].goldF1++;
    }
  }

  function getNewRank(Investor memory investor) internal pure returns(uint256) {
    if (investor.goldF1 >= 3) return 3;
    if (investor.silverF1 >= 3) return 2;
    if (investor.investedF1 >= 20) return 1;
    return 0;
  }

  uint256[] rewards = [0, 450000, 900000, 1350000];
  function paySystemCommission(address investorAddress) internal {
    uint256 NUMBER_OF_LEVEL = 15;
    uint256 investorLevel = investors[investorAddress].level;
    uint256 steps = investorLevel <= NUMBER_OF_LEVEL ? investorLevel - 1: NUMBER_OF_LEVEL;
    address next = investorAddress;
    for (uint256 step = 1; step <= steps; step++) {
      address presenterAddress = investors[next].presenterAddress;
      Investor memory presenter = investors[presenterAddress];
      next = presenterAddress;
      if (presenter.rank == 0) continue;
      payCommissionForPresenters(
        presenterAddress,
        convertUsdtToShf(rewards[presenter.rank]),
        BALANCE_CHANGE_REASON_SYSTEM_COMMISSION
      );
    }
  }

  function setBuilderFundAdmin(address builderFundAddress) public mustBeRootAdmin {
    require(isInvestor(builderFundAddress), 'BUILDER_ADMIN_MUST_BE_INVESTOR');
    builderFund = builderFundAddress;
  }

  function setLotteryFundFundAdmin(address lotteryFundAddress) public mustBeRootAdmin {
    require(isInvestor(lotteryFundAddress), 'LOTTERY_ADMIN_MUST_BE_INVESTOR');
    lotteryFund = lotteryFundAddress;
  }

  uint256 public FUND_INTEREST = 10;

  function payToFunds() internal {
    uint256 value = convertUsdtToShf(PACKAGE_PRICE_IN_USDT.take(FUND_INTEREST));

    increaseBalance(
      builderFund,
      value,
      SHF_CONTRACT_ADDRESS,
      BALANCE_CHANGE_REASON_BUILDER_FUND
    );
    increaseBalance(
      lotteryFund,
      value,
      SHF_CONTRACT_ADDRESS,
      BALANCE_CHANGE_REASON_BUILDER_FUND
    );
  }

  function payCommissionForPresenters(address presenterAddress, uint256 value, uint256 reason) internal {
    Investor storage investor = investors[getOriginalAddress(presenterAddress)];
    bool isActive = investor.lastPackageCreatedAt + 30 * ONE_DAY > getNow();
    increaseBalance(
      isActive ? presenterAddress: rootAdmin,
      value,
      SHF_CONTRACT_ADDRESS,
      reason
    );
  }

  uint256 public DAILY_PAYOUT_INTEREST = 5;
  mapping (address => uint256) public lastClaimedAt;

  uint256 IN_SKIP_DAY = 1;
  uint256 STILL_IN_FIRST_DAY = 2;
  uint256 ALREADY_CALIMED_TODAY = 3;
  uint256 NO_PACKAGE = 4;
  uint256 EXPIRED_PACKAGE = 5;
  uint256 CAN_CLAIM = 0;

  function canClaim() public view returns(uint256) {
    address originalAddress = getOriginalAddress(msg.sender);
    uint256 lastPackageCreatedAt = investors[originalAddress].lastPackageCreatedAt;
    if (lastPackageCreatedAt == 0) return NO_PACKAGE;
    if (lastPackageCreatedAt + ONE_DAY > getNow()) return STILL_IN_FIRST_DAY;
    uint256 dayPassed = (getNow() - lastPackageCreatedAt) / ONE_DAY;
    if (dayPassed >= 31) return EXPIRED_PACKAGE;
    if (dayPassed % 2 == 0 || dayPassed == 29) return IN_SKIP_DAY;
    bool claimedToday = lastClaimedAt[originalAddress] != 0 && dayPassed == (lastClaimedAt[originalAddress] - lastPackageCreatedAt) / ONE_DAY;
    if (claimedToday) return ALREADY_CALIMED_TODAY;
    return CAN_CLAIM;
  }

  function ensureCanClaim() internal view {
    uint256 claimCase = canClaim();
    require(claimCase != IN_SKIP_DAY, 'IN_SKIP_DAY');
    require(claimCase != STILL_IN_FIRST_DAY, 'STILL_IN_FIRST_DAY');
    require(claimCase != ALREADY_CALIMED_TODAY, 'ALREADY_CALIMED_TODAY');
    require(claimCase != NO_PACKAGE, 'NO_PACKAGE');
    require(claimCase != EXPIRED_PACKAGE, 'EXPIRED_PACKAGE');
  }

  uint256 public DIRECT_CLAIM_COMMISSION_RATE = 2;
  uint256 public IN_DIRECT_CLAIM_COMMISSION_RATE = 1;

  function claim() public mustNotBeReplacedAddress {
    ensureCanClaim();
    address originalAddress = getOriginalAddress(msg.sender);
    Investor storage investor = investors[originalAddress];
    uint256 shfAmount = convertUsdtToShf(PACKAGE_PRICE_IN_USDT.take(DAILY_PAYOUT_INTEREST * 2));
    increaseBalance(
      originalAddress,
      shfAmount,
      SHF_CONTRACT_ADDRESS,
      BALANCE_CHANGE_REASON_CLAIM
    );
    lastClaimedAt[originalAddress] = getNow();
    payCommissionForPresenters(
      investor.presenterAddress,
      shfAmount.take(DIRECT_CLAIM_COMMISSION_RATE),
      BALANCE_CHANGE_REASON_CLAIM_COMMISSION
    );
    payCommissionForPresenters(
      investors[investor.presenterAddress].presenterAddress,
      shfAmount.take(IN_DIRECT_CLAIM_COMMISSION_RATE),
      BALANCE_CHANGE_REASON_CLAIM_COMMISSION
    );
  }

  function swap(uint256 value, bool fromUsdt) public mustNotBeReplacedAddress {
    address investorAddress = getOriginalAddress(msg.sender);
    address fromToken = fromUsdt ? USDT_CONTRACT_ADDRESS : SHF_CONTRACT_ADDRESS;
    address toToken = fromUsdt ? SHF_CONTRACT_ADDRESS : USDT_CONTRACT_ADDRESS;
    uint256 destValue = fromUsdt ? convertUsdtToShf(value) : convertShfToUsdt(value);
    decreaseBalance(
      investorAddress,
      value,
      fromToken,
      BALANCE_CHANGE_REASON_SWAP_FROM,
      fromUsdt ? 'NOT_ENOUGH_USDT' : 'NOT_ENOUGH_SHF'
    );
    increaseBalance(
      investorAddress,
      destValue.take(99),
      toToken,
      BALANCE_CHANGE_REASON_SWAP_TO
    );
    increaseBalance(
      rootAdmin,
      value.take(1),
      fromToken,
      BALANCE_CHANGE_REASON_SWAP_FEE
    );
  }

  function getPeriodIndex() internal view returns(uint256) {
    return (getNow() - startAt) / (10 * ONE_DAY);
  }

  mapping(address => mapping(address => mapping(uint256 => uint256))) withdrewThisPeriod;
  function increaseUsedWithdrawQuota(address investorAddress, address tokenAddress, uint256 value) internal {
    withdrewThisPeriod[investorAddress][tokenAddress][getPeriodIndex()] += value;
  }

  function getCurrentUsedQuota(address investorAddress, address tokenAddress) internal view returns(uint256) {
    return withdrewThisPeriod[investorAddress][tokenAddress][getPeriodIndex()];
  }

  function withdraw(uint256 value, bool isUsdt) public mustNotBeReplacedAddress {
    address investorAddress = getOriginalAddress(msg.sender);
    if (investorAddress != rootAdmin) require(value <= getRemainWithdrawQuota(isUsdt), 'OVER_QUOTA');
    uint256 WITHDRAW_FEE = 10;
    address tokenAddress = isUsdt ? USDT_CONTRACT_ADDRESS : SHF_CONTRACT_ADDRESS;
    decreaseBalance(
      investorAddress,
      value,
      tokenAddress,
      BALANCE_CHANGE_REASON_WITHDRAW,
      isUsdt ? 'NOT_ENOUGH_USDT' : 'NOT_ENOUGH_SHF'
    );
    increaseBalance(
      rootAdmin,
      value.take(WITHDRAW_FEE),
      tokenAddress,
      BALANCE_CHANGE_REASON_WITHDRAW_FEE
    );
    IToken(tokenAddress).transfer(investorAddress, value.take(100 - WITHDRAW_FEE));
    increaseUsedWithdrawQuota(investorAddress, tokenAddress, value);
  }

  uint256 USDT_FACTOR = 10 ** 6;
  uint256 SHF_FACTOR = 10 ** 18;
  uint256[] withdrawQuotaUsdt = [0, 100 * USDT_FACTOR, 150 * USDT_FACTOR, 400 * USDT_FACTOR];
  uint256[] withdrawQuotaShf = [0, 600 * SHF_FACTOR, 900 * SHF_FACTOR, 2700 * SHF_FACTOR];

  function getRemainWithdrawQuota(bool isUsdt) public view returns(uint256) {
    address investorAddress = getOriginalAddress(msg.sender);
    uint256 rank = investors[getOriginalAddress(msg.sender)].rank;
    if (isUsdt) return withdrawQuotaUsdt[rank] - getCurrentUsedQuota(investorAddress, USDT_CONTRACT_ADDRESS);
    return withdrawQuotaShf[rank] - getCurrentUsedQuota(investorAddress, SHF_CONTRACT_ADDRESS);
  }

  function transfer(address receiverAddress, uint256 value, bool isUsdt) public mustNotBeReplacedAddress {
    address senderAddress = getOriginalAddress(msg.sender);
    require(receiverAddress != senderAddress, 'SELF_TRANSFER');
    require(isInvestor(receiverAddress), 'INVALID_RECEIVER');
    require(isOnSameBranch(receiverAddress), 'ONLY_SAME_BRANCH');
    if (!isUsdt) {
      uint256 MIN_SHF_TRANSFER_VALUE = 300 * 10 ** 18;
      require(value >= MIN_SHF_TRANSFER_VALUE, 'MIN_300_SHF');
      require(value % MIN_SHF_TRANSFER_VALUE == 0, 'MULTIPLES_OF_300_SHF');
    }
    decreaseBalance(
      senderAddress,
      value,
      isUsdt ? USDT_CONTRACT_ADDRESS : SHF_CONTRACT_ADDRESS,
      BALANCE_CHANGE_REASON_SEND_TRANSFER,
      isUsdt ? 'NOT_ENOUGH_USDT' : 'NOT_ENOUGH_SHF'
    );
    increaseBalance(
      receiverAddress,
      value,
      isUsdt ? USDT_CONTRACT_ADDRESS : SHF_CONTRACT_ADDRESS,
      BALANCE_CHANGE_REASON_RECEIVE_TRANSFER
    );
  }

  function isOnSameBranch(address receiverAddress) public view returns(bool) {
    Investor memory sender = investors[getOriginalAddress(msg.sender)];
    Investor memory receiver = investors[receiverAddress];
    bool goingUp = sender.level > receiver.level;
    Investor memory from = goingUp ? sender : receiver;
    Investor memory to = goingUp ? receiver : sender;
    uint256 step = from.level - to.level;
    address endAddress = from.investorAddress;
    for (uint256 index = 0; index < step; index++) endAddress = investors[endAddress].presenterAddress;
    return endAddress == to.investorAddress;
  }

  event CreatePackage(address investorAddress, uint256 packageId);

  uint256 packageCount = 0;
  function createPackage(address originalAddress) internal {
    emit CreatePackage(originalAddress, ++packageCount);
    investors[originalAddress].lastPackageCreatedAt = getNow();
  }

  function isInvestor(address investorAddress) public view returns(bool) {
    return investors[getOriginalAddress(investorAddress)].level != 0;
  }

  function getInvestor(address investorAddr) public view returns(uint256 usdtBalance, uint256 shfBalance, uint256 rank, uint256 investedF1, uint256 silverF1, uint256 goldF1, uint256 lastPackageCreatedAt) {
    address originalAddress = getOriginalAddress(investorAddr);
    require(hasReadPermissionOnAddress(originalAddress), 'PERMISSION DENIED');
    Investor memory investor = investors[originalAddress];
    return (
      investor.usdtBalance,
      investor.shfBalance,
      investor.rank,
      investor.investedF1,
      investor.silverF1,
      investor.goldF1,
      investor.lastPackageCreatedAt
    );
  }

  function getInvestors(address[] memory listAddresses) public mustBeRootAdmin view returns (uint256[] memory usdtBalances, uint256[] memory shfBalances, uint256[] memory ranks, uint256[] memory investedF1s, uint256[] memory silverF1s, uint256[] memory goldF1s, uint256[] memory lastPackageCreatedAts) {
    uint256 length = listAddresses.length;

    usdtBalances = new uint256[](length);
    shfBalances = new uint256[](length);
    ranks = new uint256[](length);
    investedF1s = new uint256[](length);
    silverF1s = new uint256[](length);
    goldF1s = new uint256[](length);
    lastPackageCreatedAts = new uint256[](length);

    for (uint256 index = 0; index < length; index++) {
      Investor memory investor = investors[listAddresses[index]];
      usdtBalances[index] = investor.usdtBalance;
      shfBalances[index] = investor.shfBalance;
      ranks[index] = investor.rank;
      investedF1s[index] = investor.investedF1;
      silverF1s[index] = investor.silverF1;
      goldF1s[index] = investor.goldF1;
      lastPackageCreatedAts[index] = investor.lastPackageCreatedAt;
    }
    return (usdtBalances, shfBalances, ranks, investedF1s, silverF1s, goldF1s, lastPackageCreatedAts);
  }
}