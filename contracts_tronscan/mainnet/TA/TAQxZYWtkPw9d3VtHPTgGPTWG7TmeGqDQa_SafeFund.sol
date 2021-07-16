//SourceUnit: safefund.sol

pragma solidity ^0.4.25;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
  
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a < b) {
      return a;
    }else {
      return b;
    }
  }
  
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a < b) {
      return b;
    }else {
      return a;
    }
  }
}

contract Ownable {
  address public owner;
  event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit onOwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract SafeFund is Ownable{
  using SafeMath for uint256;
  struct FundInfo {
    uint256 investCount;
    uint256 totalInvestment;
    uint256 withdrawReferaValue;
    uint256 totalGuaranteedAmount;
  }
  
  struct Investor{
    address addr;
    address ref;
    uint256 investment;
    uint256 currInvestment;
    uint256 vipLevel;
    uint256 refEarnings;
    uint inviteCount;
    uint256 guaranteedRefRate;
    uint256 guaranteedVipRate;
    uint256 totalGuaranteedAmount;
    uint256 remainGuaranteedAmount;
    uint256 receivedAmount;
    uint256 currReceivedAmount;
    uint256 investTime;
  }

  struct Rank{
    address addr;
    uint256 refEarnings;
  }

  uint256 public roundId = 1;
  uint256 public constant DIV_BASE = 10000;
  uint256 public constant MINIMUM = 500*1000000;
  uint256 public constant DAILY_DIVIDEND_RATE = 600;
  uint256 public constant GUARANTEED_SUBSCRIBE_RATE = 1000;
  uint256 public constant GUARANTEED_REF_GROWTH_RATE = 100;
  uint256 public constant GUARANTEED_INVITEE_GROWTH_RATE = 200;
  uint256 public constant GUARANTEED_VIP_GROWTH_RATE = 300;
  uint256 public constant GUARANTEED_REF_UPPER_LIMIT_RATE = 7000;
  uint256 public constant GUARANTEED_VIP_UPPER_LIMIT_RATE = 8000;
  uint256 public constant GUARANTEED_LOWER_LIMIT_RATE = 5000;
  uint256 public constant VIP_LEVEL_UPPER_LIMIT = 10;
  uint256 public constant REFERRER_EARNINGS_RATE = 100;
  uint256 public constant VIP_LEVEL_INCRE_PER_AMOUNT = 100000*1000000;
  uint256 private _Stime = 1562927469;
  uint256 private _totalInvestments = 0;
  address private _developerAccount;
  mapping(address => Investor) public investorInfo;
  mapping(uint256 => FundInfo) public fundInfo;
  mapping(uint256 => address) public addressOrder;
  mapping(uint256 => Rank) public refEarningsRank;
  event onInvest(address indexed investor,uint256 amount);
  constructor() public {
    _init();
  }
    
  function _init() private {
    FundInfo storage thisRound = fundInfo[roundId];
    thisRound.totalInvestment = 0;
    thisRound.withdrawReferaValue = 0;
    thisRound.investCount = 0;
    thisRound.totalGuaranteedAmount = 0;
  }
  
  function setDeveloperAccount(address _newDeveloperAccount) public onlyOwner {
    require(_newDeveloperAccount != address(0));
    _developerAccount = _newDeveloperAccount;
  }

  function getDeveloperAccount() public view onlyOwner returns (address) {
    return _developerAccount;
  }
  
  function setStartTime(uint _t) public onlyOwner {
    require(fundInfo[roundId].totalInvestment == 0);
    _Stime = _t;
  }
  
  function subscribe(address ref) public {
    require(now<_Stime,"The booking period has expired");
    Investor storage investor = investorInfo[msg.sender];
    require(investor.addr==address(0),"Already subscribed!");
    investor.addr = msg.sender;
    if(investorInfo[ref].addr == address(0)){
      investor.ref = address(0);
      investor.guaranteedRefRate = GUARANTEED_LOWER_LIMIT_RATE.add(GUARANTEED_SUBSCRIBE_RATE);
    }else{
      if(investorInfo[ref].addr != ref){
        investor.ref = ref;
        investorInfo[ref].inviteCount = investorInfo[ref].inviteCount.add(1);
        investorInfo[ref].guaranteedRefRate = investorInfo[ref].guaranteedRefRate.add(GUARANTEED_REF_GROWTH_RATE);
        investor.guaranteedRefRate = GUARANTEED_LOWER_LIMIT_RATE.add(GUARANTEED_SUBSCRIBE_RATE).add(GUARANTEED_INVITEE_GROWTH_RATE);
      }else{
        investor.guaranteedRefRate = GUARANTEED_LOWER_LIMIT_RATE.add(GUARANTEED_SUBSCRIBE_RATE);
      }
    }
    investor.guaranteedVipRate = GUARANTEED_LOWER_LIMIT_RATE;
  }
  
  function invest(address ref) public payable {
    require(now>_Stime,"Comming soon");
    require(msg.value >= MINIMUM, "Less than the minimum amount of deposit requirement");
    if (_invest(msg.sender, msg.value,ref)) {
      emit onInvest(msg.sender, msg.value);
    }
  }
  
  function _invest(address _addr,uint256 _amount,address _ref) private returns(bool){
    address refAddr = _ref;
    if(_ref!=address(0)){
      if(investorInfo[refAddr].addr == address(0)){
        refAddr = address(0);
      }
    }
    if(_addr == _ref) refAddr = address(0);
    _developerAccount.transfer(_amount.mul(400).div(DIV_BASE));
    _handleInvestor(_addr,_amount,refAddr);
    return true;
  }

  function _handleInvestor(address _addr,uint256 _amount,address _ref) private {
    Investor storage investor = investorInfo[_addr];
    uint256 gAmount = 0;
    investor.vipLevel = _calVipLevel(investor.currInvestment,_amount);
    investor.guaranteedVipRate = investor.vipLevel.mul(GUARANTEED_VIP_GROWTH_RATE).add(GUARANTEED_LOWER_LIMIT_RATE).min(GUARANTEED_VIP_UPPER_LIMIT_RATE);
    uint256 refGrowthRate = 0;
    if(investorInfo[_ref].addr!=address(0)){
      _handleReferrerInfo(_addr,_amount,_ref);
      refGrowthRate = GUARANTEED_INVITEE_GROWTH_RATE;
    }
    if(investor.addr==address(0)){
      investor.addr = _addr;
      investor.ref = _ref;
      investor.investment = _amount;
      investor.currInvestment = _amount;
      investor.guaranteedRefRate = GUARANTEED_LOWER_LIMIT_RATE.add(refGrowthRate);
      investor.refEarnings = 0;
      investor.inviteCount = 0;
      gAmount = investor.guaranteedVipRate.max(investor.guaranteedRefRate).mul(_amount).div(DIV_BASE);
      investor.totalGuaranteedAmount = gAmount;
      investor.remainGuaranteedAmount = gAmount;
      investor.receivedAmount = 0;
      investor.investTime = now;
    }else{
      if(investor.ref!=address(0)){
        refGrowthRate = 0;
      }
      if(investor.ref == address(0))
        investor.ref = _ref;
      if(investor.investment == 0)
        investor.investTime = now;
      investor.investment = investor.investment.add(_amount);
      investor.currInvestment = investor.currInvestment.add(_amount);
      investor.guaranteedRefRate = refGrowthRate.add(investor.guaranteedRefRate).min(GUARANTEED_REF_UPPER_LIMIT_RATE);
      gAmount = investor.guaranteedVipRate.max(investor.guaranteedRefRate).mul(investor.currInvestment).div(DIV_BASE).sub(investor.totalGuaranteedAmount);
      investor.totalGuaranteedAmount = investor.totalGuaranteedAmount.add(gAmount);
      investor.remainGuaranteedAmount = investor.remainGuaranteedAmount.add(gAmount);
    }
    _handleFundInfo(_amount,gAmount,_addr);
  }

  function _calVipLevel(uint256 _investment,uint256 _amount) private pure returns(uint256){
    return _investment.add(_amount).div(VIP_LEVEL_INCRE_PER_AMOUNT).min(VIP_LEVEL_UPPER_LIMIT);
  }
  
  function _handleReferrerInfo(address _addr,uint256 _amount,address _ref) private {
    Investor storage investor = investorInfo[_ref];
    if(investor.addr!=address(0)){
      _ref.transfer(_amount.mul(REFERRER_EARNINGS_RATE).div(DIV_BASE));
      if (investorInfo[_addr].ref == address(0)){
        investor.inviteCount = investor.inviteCount.add(1);
        investor.guaranteedRefRate = investor.guaranteedRefRate.add(GUARANTEED_REF_GROWTH_RATE).min(GUARANTEED_REF_UPPER_LIMIT_RATE);
      }
      investor.refEarnings = investor.refEarnings.add(_amount.mul(REFERRER_EARNINGS_RATE).div(DIV_BASE));
      bool hasThisAddress = false;
      for(uint i = 1; i <= 10; i++){
        if(refEarningsRank[i].addr == _ref){
          hasThisAddress = true;
          refEarningsRank[i].refEarnings = investor.refEarnings;
          break;
        }
      }
      if(!hasThisAddress){
        uint minIndex = 1;
        uint256 min = refEarningsRank[1].refEarnings;
        for(i = 1; i <= 10; i++){
          if(min>refEarningsRank[i].refEarnings){
            min = refEarningsRank[i].refEarnings;
            minIndex = i;
          }
        }
        refEarningsRank[minIndex].refEarnings = investor.refEarnings;
        refEarningsRank[minIndex].addr = _ref;
      }
      uint256 increAmount = investor.guaranteedRefRate.max(investorInfo[_ref].guaranteedVipRate).mul(investor.currInvestment).div(DIV_BASE).sub(investor.totalGuaranteedAmount);
      investor.totalGuaranteedAmount = investor.totalGuaranteedAmount.add(increAmount);
      investor.remainGuaranteedAmount = investor.remainGuaranteedAmount.add(increAmount);
      _handleFundInfo(0,increAmount,_addr);
    }
  }
  
  function _handleFundInfo(uint256 _amount,uint256 _guaranteedIncreAmount,address _addr) private {
    FundInfo storage thisRound = fundInfo[roundId];
    thisRound.totalInvestment = thisRound.totalInvestment.add(_amount);
    if(_amount>0){
      thisRound.investCount = thisRound.investCount.add(1);
      addressOrder[thisRound.investCount] = _addr;
    }
    thisRound.withdrawReferaValue = thisRound.withdrawReferaValue.add(_amount);
    thisRound.totalGuaranteedAmount = thisRound.totalGuaranteedAmount.add(_guaranteedIncreAmount);
  }
  
  function getFundInfo() public view returns (uint256,uint256,uint256,uint256){
    return (
      fundInfo[roundId].investCount,
      fundInfo[roundId].totalInvestment,
      fundInfo[roundId].withdrawReferaValue,
      fundInfo[roundId].totalGuaranteedAmount
    );
  }
  
  function getRankInfo() public view returns (address[]){
    address[] memory rankArr = new address[](10);
    for(uint i = 1; i <= 10; i++){
     rankArr[i-1] = refEarningsRank[i].addr;
    }
    return rankArr;
  }
  
  function _divPollSwitchOn() private view returns (bool) {
    return address(this).balance > fundInfo[roundId].totalGuaranteedAmount;
  }
  
  function withdraw() public payable {
    Investor storage investor = investorInfo[msg.sender];
    FundInfo storage thisRound = fundInfo[roundId];
    require(investor.investment > 0, "Can not withdraw because no any investments");
    uint256 divAmount = _calculateDividends(investor.currInvestment,now,investor.investTime);
    divAmount = divAmount.sub(investor.currReceivedAmount);
    uint256 withdrawValue = 0;
    if(_divPollSwitchOn()){
      if(divAmount.add(investor.currReceivedAmount)>=investor.currInvestment.mul(2)){
        withdrawValue = investor.currInvestment.mul(2).sub(investor.currReceivedAmount);
        thisRound.totalGuaranteedAmount = thisRound.totalGuaranteedAmount.sub(investor.remainGuaranteedAmount);
        investor.currInvestment = 0;
        investor.totalGuaranteedAmount = 0;
        investor.remainGuaranteedAmount = 0;
        investor.investTime = 0;
        investor.currReceivedAmount = 0;
      }else if (divAmount<=investor.remainGuaranteedAmount){
        withdrawValue = divAmount;
        investor.remainGuaranteedAmount = investor.remainGuaranteedAmount.sub(withdrawValue);
        investor.currReceivedAmount = investor.currReceivedAmount.add(withdrawValue);
        thisRound.totalGuaranteedAmount = thisRound.totalGuaranteedAmount.sub(withdrawValue);
      }else{
        withdrawValue = divAmount;
        if(divAmount>investor.investment){
          thisRound.totalGuaranteedAmount = thisRound.totalGuaranteedAmount.sub(investor.remainGuaranteedAmount);
          investor.currInvestment = 0;
          investor.totalGuaranteedAmount = 0;
          investor.remainGuaranteedAmount = 0;
          investor.investTime = 0;
          investor.currReceivedAmount = 0;
        }else{
          investor.remainGuaranteedAmount = investor.remainGuaranteedAmount.sub(withdrawValue);
          investor.currReceivedAmount = investor.currReceivedAmount.add(withdrawValue);
          thisRound.totalGuaranteedAmount = thisRound.totalGuaranteedAmount.sub(withdrawValue);
        }
      }
    }else{
      withdrawValue = investor.remainGuaranteedAmount;
      thisRound.totalGuaranteedAmount = thisRound.totalGuaranteedAmount.sub(withdrawValue);
      investor.remainGuaranteedAmount = 0;
    }
    if(withdrawValue.add(investor.receivedAmount)>investor.currInvestment){
      uint256 profit = withdrawValue+investor.receivedAmount.sub(investor.currInvestment);
      uint256 dropAmount = profit.mul(10).div(100).div(5);
      _last5InvestorAirDrop(dropAmount);
    }
    investor.receivedAmount = investor.receivedAmount.add(withdrawValue);
    thisRound.withdrawReferaValue = thisRound.withdrawReferaValue.sub(withdrawValue);
    msg.sender.transfer(withdrawValue);
  }
  
  function quit() public payable {
    Investor storage investor = investorInfo[msg.sender];
    FundInfo storage thisRound = fundInfo[roundId];
    require(investor.currInvestment > 0);
    uint256 divAmount = _calculateDividends(investor.currInvestment,now,investor.investTime);
    divAmount = divAmount.sub(investor.currReceivedAmount);
    uint256 transferValue = 0;
    if(divAmount <= investor.remainGuaranteedAmount)
      transferValue = investor.remainGuaranteedAmount;
    else
      transferValue = divAmount.min(investor.currInvestment.mul(2).sub(investor.currReceivedAmount));
    thisRound.totalGuaranteedAmount = thisRound.totalGuaranteedAmount.sub(investor.remainGuaranteedAmount);
    investor.currInvestment = 0;
    investor.totalGuaranteedAmount = 0;
    investor.remainGuaranteedAmount = 0;
    investor.investTime = 0;
    investor.currReceivedAmount = 0;
    investor.receivedAmount = investor.receivedAmount.add(transferValue);
    msg.sender.transfer(transferValue);
  }
  
  function getInvestorInfo(address addr) public view returns (address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
    Investor storage investor = investorInfo[addr];
    require(investor.addr!=address(0),"No investor info!");
    return
    (
      investor.ref,
      investor.investment,
      investor.currInvestment,
      investor.refEarnings,
      investor.inviteCount,
      investor.guaranteedRefRate,
      investor.guaranteedVipRate,
      investor.totalGuaranteedAmount,
      investor.remainGuaranteedAmount,
      investor.receivedAmount,
      investor.investTime,
      _calculateDividends(investor.currInvestment,now,investor.investTime)
    );
  }
  
  function _calculateDividends(uint256 _amount, uint256 _now, uint256 _start) private pure returns (uint256) {
    if(_now<_start||_start==0){
      return 0;
    }
    return _amount.mul(DAILY_DIVIDEND_RATE).div(DIV_BASE).mul(_now - _start).div(60*60*24);
  }
    
  function _last5InvestorAirDrop(uint256 _amount) private {
    for (uint256 i = fundInfo[roundId].investCount-4; i <= fundInfo[roundId].investCount; i++) {
      addressOrder[i].transfer(_amount);
    }
  }
  
  function getLast5Investor() public view returns(address,address,address,address,address){
    uint256 investCount = fundInfo[roundId].investCount;
    return (
      addressOrder[investCount],
      addressOrder[investCount-1],
      addressOrder[investCount-2],
      addressOrder[investCount-3],
      addressOrder[investCount-4]
    );
  }
  
  function getStartTime() public view returns(uint256){
    return _Stime;
  }
}