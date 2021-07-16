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

contract TokenHelper {
  address TETHER_CONTRACT_ADDRESS;
  address IMD_CONTRACT_ADDRESS;
  address IDA_CONTRACT_ADDRESS;

  uint256 TETHER_FACTOR = 10 ** 12;

  function deposit(uint256 value, address tokenAddress) internal {
    require(tokenAddress == TETHER_CONTRACT_ADDRESS || tokenAddress == IMD_CONTRACT_ADDRESS);
    if (tokenAddress == TETHER_CONTRACT_ADDRESS) {
      IToken(tokenAddress).transferFrom(msg.sender, address(this), value / TETHER_FACTOR);
    } else {
      IToken(tokenAddress).transferFrom(msg.sender, address(this), value);
    }
  }

  function withdraw(uint256 value, address tokenAddress) internal {
    if (tokenAddress == TETHER_CONTRACT_ADDRESS) {
      IToken(tokenAddress).transfer(msg.sender, value / TETHER_FACTOR);
    } else {
      IToken(tokenAddress).transfer(msg.sender, value);
    }
  }
}

contract IDADefi is AccountChangable, Utils, TokenHelper {

  using SafeMath for uint256;

  string public version = '1.0.0';
  uint256 ONE_DAY = 86400;
   uint256 FACTOR = 10 ** 18;

  mapping(address => uint256) systemRates;
  address rootAdmin;
  uint256 ROOT_LEVEL = 1;

  uint256 investmentCount = 0;
  uint256 withdrawalCount = 0;
  uint256 investorCount = 0;
  
  mapping(uint256 => Investment) investments;
  mapping(address => Investor) investors;
  mapping(uint256 => address) investorIndexToAddress;

  event CreateInvestor(address investorAddress, address presenterAddress, uint256 level);
  event CreateInvestment(uint256 investmentId, address investorAddress, uint256 value, address tokenAddress);
  event CreateWithdrawal(
    uint256 withdrawalId,
    address investorAddress,
    uint256 value,
    address tokenAddress
  );

  struct Investor {
    address investorAddress;
    address presenterAddress;
    uint256 level;
    uint256 balance;
    uint256 rank;
    uint256 invested;
    uint256 agentF1;
    uint256 agentF2;
    uint256 idaWithdrew;
    uint256[] investments;
  }
  
  struct Investment {
    uint256 investmentId;
    address investorAddress;
    uint256 value;
    uint256 createdAt;
  }
  
  uint256 public startAt;

  constructor(address rootAddress, address tetherAddress, address imdAddress, address idaAddress) public {
    TETHER_CONTRACT_ADDRESS = tetherAddress;
    IMD_CONTRACT_ADDRESS = imdAddress;
    IDA_CONTRACT_ADDRESS = idaAddress;
    rootAdmin = rootAddress;
    uint256 FIRST_LEVEL = 1;
    createInvestor(rootAddress, EMPTY_ADDRESS, FIRST_LEVEL);
    startAt = now;
  }
  
  function getPeriodIndex(uint256 time) internal view returns(uint256) {
    return (time - startAt).div(ONE_DAY).div(30);
  }
  
  mapping(uint256 => uint256) rateByPeriodIndex;
  event SetRate(uint256 rate);
  function setRate(uint256 rate) public mustBeRootAdmin {
    rateByPeriodIndex[getPeriodIndex(getNow())] = rate;
    emit SetRate(rate);
  }

  function getRate(uint256 time) public view returns(uint256) {
    uint256 MIN_RATE = 1000;
    return max(rateByPeriodIndex[getPeriodIndex(time)], MIN_RATE);
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

  function setInvestor(address investorAddress, uint256 balance, uint256 rank, uint256 invested, uint256 agentF1, uint256 agentF2, uint256 idaWithdrew) public mustBeRootAdmin {
    Investor storage investor = investors[investorAddress];
    investor.balance = balance;
    investor.rank = rank;
    investor.invested = invested;
    investor.agentF1 = agentF1;
    investor.agentF2 = agentF2;
    investor.idaWithdrew = idaWithdrew;
  }

  function createInvestor(address investorAddress, address presenterAddress, uint256 level) internal {
    investors[investorAddress] = Investor({
      investorAddress: investorAddress,
      presenterAddress: presenterAddress,
      level: level,
      balance: 0,
      rank: 0,
      invested: 0,
      investments: new uint256[](0),
      agentF1: 0,
      agentF2: 0,
      idaWithdrew: 0
    });
    investorIndexToAddress[investorCount++] = investorAddress;
    emit CreateInvestor(investorAddress, presenterAddress, level);
  }

  function createInvestment(uint256 index, address investorAddress, uint256 value, uint256 createdAt, address tokenAddress) internal {
    uint256 investmentId = index;
    investments[investmentId] = Investment({
      investmentId: investmentId,
      investorAddress: investorAddress,
      value: value,
      createdAt: createdAt
    });
    investors[investorAddress].investments.push(investmentId);
    emit CreateInvestment(investmentId, investorAddress, value, tokenAddress);
  }
  
  uint256 MONTHLY_PAYMENT_PAY_SYSTEM_COMMISISON = 1;
  uint256 MONTHLY_PAYMENT_PAY_RANK_COMMISSION = 2;
  uint256 MONTHLY_PAYMENT_COMPLETED = 3;

  mapping (uint256 => MonthlyPayment) public monthlyPayments;
  
  struct MonthlyPayment {
    uint256 state;
    uint256 systemCommissionPaidIndex;
    uint256 rankCommissionPaidIndex;
  }
  
  event StartPaymentPeriod(uint256 periodIndex);
  function startPaymentPeriod() public {
    uint256 periodIndex = getPeriodIndex(getNow()).sub(1);
    require(monthlyPayments[periodIndex].state == 0, 'INVALID_STATE');
    monthlyPayments[periodIndex] = MonthlyPayment({
      state: MONTHLY_PAYMENT_PAY_SYSTEM_COMMISISON,
      systemCommissionPaidIndex: investorCount,
      rankCommissionPaidIndex: investorCount
    });
    emit StartPaymentPeriod(periodIndex);
  }
  
  function paySystemCommission(uint256 maxStep) public {
    uint256 periodIndex = getPeriodIndex(getNow()).sub(1);
    require(monthlyPayments[periodIndex].state == MONTHLY_PAYMENT_PAY_SYSTEM_COMMISISON);
    uint256 paidIndex = monthlyPayments[periodIndex].systemCommissionPaidIndex;
    for (uint256 step = 1; step <= maxStep; step++) {
      if (paidIndex == 0) break;
      address investorAddress = investorIndexToAddress[--paidIndex];
      processSystemCommissionForOneInvestor(investorAddress);
    }
    monthlyPayments[periodIndex].systemCommissionPaidIndex = paidIndex;
    if (paidIndex == 0) goToPayRankCommissionStep();
  }

  function processSystemCommissionForOneInvestor(address investorAddress) internal {
    if (investors[investorAddress].rank != 2) return;
    uint256 revenue = revenues[investorAddress][getPeriodIndex(getNow()) - 1];
    if (revenue < 100000 * FACTOR) return;
    uint256 rate = revenue >= 300000 * FACTOR ? 3 : 2;
    uint256 childReceived = getChildReceived(investorAddress);
    uint256 commission = rate.mul(revenue).div(100).sub(childReceived);
    pay(investorAddress, commission);
    address nextMasterAgent = findNextMasterAgent(investorAddress);
    if (nextMasterAgent == EMPTY_ADDRESS) return;
    increaseChildReceived(nextMasterAgent, commission.add(childReceived));
  }

  function findNextMasterAgent(address fromAddress) internal view returns(address) {
    while (true) {
      address nextParentAddress = investors[fromAddress].presenterAddress;
      if (nextParentAddress == EMPTY_ADDRESS) return EMPTY_ADDRESS;
      if (investors[nextParentAddress].rank == 2) return nextParentAddress;
      fromAddress = nextParentAddress;
    }        
  }

  function goToPayRankCommissionStep() internal {
    uint256 periodIndex = getPeriodIndex(getNow()).sub(1);
    MonthlyPayment storage monthlyPayment = monthlyPayments[periodIndex];
    monthlyPayment.state = MONTHLY_PAYMENT_PAY_RANK_COMMISSION;
  }

  function payRankCommission(uint256 maxStep) public {
    uint256 periodIndex = getPeriodIndex(getNow()).sub(1);
    require(monthlyPayments[periodIndex].state == MONTHLY_PAYMENT_PAY_RANK_COMMISSION);
    uint256 paidIndex = monthlyPayments[periodIndex].rankCommissionPaidIndex;
    for (uint256 step = 1; step <= maxStep; step++) {
      if (paidIndex == 0) break;
      address investorAddress = investorIndexToAddress[--paidIndex];
      processRankCommissionForOneInvestor(investorAddress);
    }
    monthlyPayments[periodIndex].rankCommissionPaidIndex = paidIndex;
    if (paidIndex == 0) finishMonthlyCommission();
  }
  
  mapping(address => mapping(uint256 => uint256)) f1OwnRevenues;
  mapping(address => mapping(uint256 => uint256)) f2OwnRevenues;
  mapping(address => mapping(uint256 => uint256)) f1TotalRevenues;
  
  function processRankCommissionForOneInvestor(address investorAddress) internal {
    if (investors[investorAddress].rank != 2) return;
    uint256 periodIndex = getPeriodIndex(getNow()).sub(1);
    uint256 f1OwnRevenue = f1OwnRevenues[investorAddress][periodIndex];
    uint256 f2OwnRevenue = f2OwnRevenues[investorAddress][periodIndex];
    pay(investorAddress, (f1OwnRevenue.add(f2OwnRevenue)).div(100));

    uint256 revenue = getLastMonthRevenue(investorAddress);
    uint256 ownRevenue = revenue.sub(f1TotalRevenues[investorAddress][periodIndex]);

    address fatherMasterAgentAddress = findNextMasterAgent(investorAddress);
    if (fatherMasterAgentAddress == EMPTY_ADDRESS) return;
    updateRankCommissionInfo(fatherMasterAgentAddress, ownRevenue, revenue, true, periodIndex);
    
    address grandFatherMasterAgentAddress = findNextMasterAgent(fatherMasterAgentAddress);
    if (grandFatherMasterAgentAddress == EMPTY_ADDRESS) return;
    updateRankCommissionInfo(grandFatherMasterAgentAddress, ownRevenue, revenue, false, periodIndex);
  } 
  
  function updateRankCommissionInfo(address presenterAddress, uint256 ownRevenue, uint256 revenue, bool isF1, uint256 periodIndex) internal {
    if (isF1) {
      f1OwnRevenues[presenterAddress][periodIndex] += ownRevenue;
      f1TotalRevenues[presenterAddress][periodIndex] += revenue;
      return;
    }
    f2OwnRevenues[presenterAddress][periodIndex] += ownRevenue;
  }

  event FinishPaymentPeriod(uint256 periodIndex);
  function finishMonthlyCommission() internal {
    uint256 periodIndex = getPeriodIndex(getNow()).sub(1);
    MonthlyPayment storage monthlyPayment = monthlyPayments[periodIndex];
    monthlyPayment.state = MONTHLY_PAYMENT_COMPLETED;
    emit FinishPaymentPeriod(periodIndex);
  }

  function isLastMonthlyPaymentCompleted() internal view returns(bool) {
    uint256 periodIndex = getPeriodIndex(getNow());
    bool isFirstMonth = periodIndex == 0;
    if (isFirstMonth) return true;
    return monthlyPayments[periodIndex.sub(1)].state == MONTHLY_PAYMENT_COMPLETED;
  }
  
  mapping(address => mapping(uint256 => uint256)) revenues;
  mapping(address => mapping(uint256 => uint256)) systemCommissionChildrenReceived;

  function increaseRevenue(address investorAddress, uint256 investedValue) internal {
    revenues[investorAddress][getPeriodIndex(getNow())] += investedValue;
  }
  
  function getLastMonthRevenue(address investorAddress) public view returns(uint256) {
    require(hasReadPermissionOnAddress(investorAddress), 'PERMISSION DENIED');
    return revenues[investorAddress][getPeriodIndex(getNow()) - 1];
  }

  function getRevenue(address investorAddress) public view returns(uint256) {
    require(hasReadPermissionOnAddress(investorAddress), 'PERMISSION DENIED');
    return revenues[investorAddress][getPeriodIndex(getNow())];
  }

  function getChildReceived(address investorAddress) internal view returns(uint256) {
    return systemCommissionChildrenReceived[investorAddress][getPeriodIndex(getNow()) - 1];
  }
  
  function increaseChildReceived(address investorAddress, uint256 value) internal {
    systemCommissionChildrenReceived[investorAddress][getPeriodIndex(getNow()) - 1] += value;
  }

  uint256[3][3] DIRECT_COMMISSION_RATES = [
    [0,  0,  0],
    [0, 10, 20],
    [0,  5, 10]
  ];

  function payDirectCommission(address presenterAddress, uint256 investValue, uint256 distance) internal {
    if (presenterAddress == EMPTY_ADDRESS) return;
    uint256 rate = DIRECT_COMMISSION_RATES[distance][investors[presenterAddress].rank];
    if (rate == 0) return;
    pay(presenterAddress, investValue.mul(rate).div(100));
  }

  function payRebateCommission(address investorAddress, uint256 investValue) internal {
    address nextMasterAgent = findNextMasterAgent(investorAddress);
    if (nextMasterAgent == EMPTY_ADDRESS) return;
    if (investors[investorAddress].level - investors[nextMasterAgent].level <= 2) return;
    pay(nextMasterAgent, investValue.mul(10).div(100));
  }

  uint256 NORMAL_INVESTOR_RANK = 0;

  function updateRanks(address fromAddress) internal {
    Investor storage investor = investors[fromAddress];
    uint256 oldRank = investor.rank;
    uint256 newRank = getNewRank(fromAddress);
    investor.rank = newRank;
    if (oldRank == newRank || newRank != 1) return;

    address presenterAddress = investor.presenterAddress;
    updateParentWhenChildRankUp(presenterAddress, true);
    updateParentWhenChildRankUp(investors[presenterAddress].presenterAddress, false);
  }

  function updateParentWhenChildRankUp(address presenterAddress, bool isF1) internal {
    if (presenterAddress == EMPTY_ADDRESS) return;
    Investor storage presenter = investors[presenterAddress];
    isF1 ? presenter.agentF1++ : presenter.agentF2++;
    uint256 newFatherRank = getNewRank(presenterAddress);
    if (newFatherRank != presenter.rank) presenter.rank = newFatherRank;
  }

  function getNewRank(address investorAddress) internal view returns (uint256) {
    Investor memory investor = investors[investorAddress];
    if (investor.invested < 1000 * FACTOR) return 0; // normal user
    bool isMasterAgent = investor.invested >= 5000 * FACTOR && investor.agentF1 >= 6 && investor.agentF2 >= 36;
    if (isMasterAgent) return 2;
    return 1;
  }

  function pay(address to, uint256 value) internal {
    if (value == 0) return;
    investors[to].balance = investors[to].balance.add(value);
  }

  function hasReadPermissionOnAddress(address targetedAddress) internal view returns(bool) {
    address originalAddress = getOriginalAddress(msg.sender);
    bool isRootAdmin = originalAddress == rootAdmin;
    bool isMyAccount = originalAddress == targetedAddress;
    return isRootAdmin || isMyAccount;
  }

  function invest(uint256 value, bool usingTether) public mustNotBeReplacedAddress {
    require(value >= 1 * FACTOR, 'TOO_SMALL_AMOUNT');
    require(isLastMonthlyPaymentCompleted(), 'PAYING_MONTHLY_COMMISSION');
    address investorAddress = getOriginalAddress(msg.sender);
    require(isInvestorExists(investorAddress), 'REGISTER_FIRST');
    require(investors[investorAddress].investments.length <= 4, 'TOO_MAY_INVESTMENTS');
    address tokenAddress = usingTether ? TETHER_CONTRACT_ADDRESS : IMD_CONTRACT_ADDRESS;
    TokenHelper.deposit(value, tokenAddress);
    investors[investorAddress].invested = investors[investorAddress].invested.add(value);

    createInvestment(++investmentCount, investorAddress, value, getNow(), tokenAddress);
    
    address fatherAddress = investors[investorAddress].presenterAddress;
    payDirectCommission(fatherAddress, value, 1);
    payDirectCommission(investors[fatherAddress].presenterAddress, value, 2);
    payRebateCommission(investorAddress, value);
    updateRanks(investorAddress);

    address revenueReceiverAddress = investorAddress;
    while(revenueReceiverAddress != EMPTY_ADDRESS) {
      increaseRevenue(revenueReceiverAddress, value);
      revenueReceiverAddress = investors[revenueReceiverAddress].presenterAddress;
    }
  }

  function investorWithdrawTether(uint256 value) public mustNotBeReplacedAddress {
    require(value >= 1 * FACTOR, 'INVALID_WITHDRAW_VALUE');
    address investorAddress = getOriginalAddress(msg.sender);
    investors[investorAddress].balance = investors[investorAddress].balance.sub(value);
    TokenHelper.withdraw(value, TETHER_CONTRACT_ADDRESS);
    emit CreateWithdrawal(
      ++withdrawalCount,  
      investorAddress,
      value,
      TETHER_CONTRACT_ADDRESS  
    );
  }

  function investorWithdrawIda(uint256 value) public mustNotBeReplacedAddress {
    require(value >= 1 * FACTOR, 'INVALID_WITHDRAW_VALUE');
    address investorAddress = getOriginalAddress(msg.sender);
    Investor storage investor = investors[investorAddress];
    require(
      getMaturedDailyIncome(investorAddress).sub(investor.idaWithdrew).add(1) >= value,
      'INSUFFICIENT_FUND'
    );
    investor.idaWithdrew = investor.idaWithdrew.add(value);
    TokenHelper.withdraw(value, IDA_CONTRACT_ADDRESS);
    emit CreateWithdrawal(
      ++withdrawalCount,  
      investorAddress,
      value,
      IDA_CONTRACT_ADDRESS  
    );
  }

  function adminWithdrawToken(uint256 value, address tokenAddress) public mustBeRootAdmin {
    emit CreateWithdrawal(
      ++withdrawalCount,  
      EMPTY_ADDRESS,
      value,
      tokenAddress  
    );
    if (tokenAddress == EMPTY_ADDRESS) {
      msg.sender.transfer(value);
      return;
    }
    TokenHelper.withdraw(value, tokenAddress);
  }

  function () external payable {}
  
  function getNow() internal view returns(uint256) {
    return now;
  }

  function register(address presenter, uint256 investAmount, bool usingTether) public {
    address investorAddress = getOriginalAddress(msg.sender);
    address presenterAddress = getOriginalAddress(presenter);
    require(!isContract(investorAddress), 'CONTRACT_CANNOT_REGISTER');
    require(investors[presenterAddress].rank >= 1, 'INVALID_PRESENTER');
    require(!isInvestorExists(investorAddress), 'ADDRESS_IS_USED');
    createInvestor(
      investorAddress,
      presenterAddress,
      investors[presenterAddress].level.add(1)
    );
    if (investAmount > 0) {
      invest(investAmount, usingTether);
    }
  }
  
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
 
  function isInvestorExists(address investorAddress) public view returns(bool) {
    return investors[getOriginalAddress(investorAddress)].level != 0;
  }

  function getDailyIncomeByTime(address investorAddr, uint256 time) internal view returns(uint256) {
    uint256 result = 0;
    uint256 length = investors[investorAddr].investments.length;

    for (uint256 index = 0; index < length; index++) {
      result += getIncomeForInvestment(investors[investorAddr].investments[index], time);
    }
    return result;
  }
  
  function getTotalDailyIncome(address investorAddr) public view returns(uint256) {
    require(hasReadPermissionOnAddress(investorAddr), 'PERMISSION DENIED');
    return getDailyIncomeByTime(investorAddr, getNow());
  }

  function getMaturedDailyIncome(address investorAddr) public view returns(uint256) {
    require(hasReadPermissionOnAddress(investorAddr), 'PERMISSION DENIED');
    uint256 ONE_YEAR = 360 * ONE_DAY;
    return getDailyIncomeByTime(investorAddr, getNow() - ONE_YEAR);
  }

  function getIncomeForInvestment(uint256 investmentId, uint256 time) internal view returns (uint256) {
    uint256[25] memory withdrawableIncomes = getIncomesAt(investmentId, time);
    uint256 result = 0;
    for (uint256 index = 0; index < 25; index++) result += withdrawableIncomes[index];
    return result;
  }

  function getIncomesAt(uint256 investmentId, uint256 time) internal view returns(uint256 [25] memory result) {
    Investment memory investment = investments[investmentId];
    uint256 createdAt = investment.createdAt;
    uint256 INVESTMENT_TIME = 360 * ONE_DAY * 2;
    uint256 value = investment.value;
    uint256 investmentValidUntil = min(time, createdAt + INVESTMENT_TIME);
    for (uint256 index = 0; index < 25; index++) {
      (uint256 periodStart, uint256 periodEnd) = getPeriodForInvestment(index, createdAt);
      uint256 overlap = getOverlap(
        createdAt,
        investmentValidUntil,
        periodStart,
        periodEnd
      );
      result[index] = getIncome(overlap, getRate(periodStart), value);
    }
    return result;
  }

  function getPeriodForInvestment(uint256 index, uint256 investmentCreatedAt) internal view returns(uint256 start, uint256 end) {
    uint256 PERIOD_LONG = ONE_DAY * 30;
    uint256 firstPeriodStartAt = getPeriodIndex(investmentCreatedAt) * PERIOD_LONG + startAt;
    start = firstPeriodStartAt + index * PERIOD_LONG;
    end = start + PERIOD_LONG;
    return (start, end);
  }
  
  function getOverlap(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal pure returns(uint256) {
    uint256 start = max(x1, x2);
    uint256 end = min(y1, y2);
    if (start >= end) return 0;
    return end - start;
  }
  
  function getIncome(uint256 overlap, uint256 rate, uint256 value) internal view returns(uint256) {
    return overlap.mul(value).div(ONE_DAY).mul(3).div(1000).mul(1000000).div(rate);
  }
  
  function getInvestor(address investorAddr) public view returns(uint256 balance, uint256 rank, uint256 invested, uint256 agentF1, uint256 agentF2, uint256 idaWithdrew, uint256 revenue) {
    address originalAddress = getOriginalAddress(investorAddr);
    require(hasReadPermissionOnAddress(originalAddress), 'PERMISSION DENIED');
    Investor memory investor = investors[originalAddress];
    return (
      investor.balance,
      investor.rank,
      investor.invested,
      investor.agentF1,
      investor.agentF2,
      investor.idaWithdrew,
      getRevenue(originalAddress)
    );
  }

  function getInvestors(address[] memory listAddresses) public mustBeRootAdmin view returns (address[] memory investorAddresses, uint256[] memory investeds, uint256[] memory idaWithdrews, uint256[] memory balances, uint256[] memory ranks) {
    uint256 length = listAddresses.length;

    investorAddresses = new address[](length);
    investeds = new uint256[](length);
    idaWithdrews = new uint256[](length);
    balances = new uint256[](length);
    ranks = new uint256[](length);

    for (uint256 index = 0; index < length; index++) {
      Investor memory investor = investors[listAddresses[index]];
      investorAddresses[index] = investor.investorAddress;
      investeds[index] = investor.invested;
      balances[index] = investor.balance;
      idaWithdrews[index] = investor.idaWithdrew;
      ranks[index] = investor.rank;
    }
    return (investorAddresses, investeds, idaWithdrews, balances, ranks);
  }
  
  function getBulkDailyIncomeByTime(address[] memory listAddresses, uint256 time) public mustBeRootAdmin view returns (address[] memory investorAddresses, uint256[] memory incomes) {
    uint256 length = listAddresses.length;

    investorAddresses = new address[](length);
    incomes = new uint256[](length);

    for (uint256 index = 0; index < length; index++) {
      address investorAddress = listAddresses[index];
      investorAddresses[index] = investorAddress;
      incomes[index] = getDailyIncomeByTime(investorAddress, time);
    }
    return (investorAddresses, incomes);
  } 
}