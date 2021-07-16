//SourceUnit: TronDoublerV2.sol

pragma solidity 0.4.25;

/*
------------------------------------
x2Card project
 Website:  https://x100tron.com  
 Project Website :  https://x100tron.com/x2card
 Chanel :  https://t.me/x100tronofficial
------------------------------------ 
 CONTRACT MANAGEMENT:
------------------------------------
10% direct referral 👨 
8% referred level 2 👨🏽👨🏽
5% referred level 3 👨🏽👨�
*/

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Objects {
    struct InvestmentData {
        uint256 planId;
        uint256 investmentIdList;
        uint256 investmentUID;
        uint256 investmentDate;
        uint256 investmentLimit;
        uint256 investmentSum;
        uint256 lastWithdrawLimit;
        uint256 TicketsCount;
        uint256 investmentProfit;
        uint256 investIsFinish;
    }
        
    struct Limits {
        uint256 limitId;
        uint256 limitCountTickets;
        uint256 limitAlreadyBuy;
        uint256 limitIsClosed;
    }

    struct Plan {
        uint256 OptionPlan;
        uint256 PriceOneTicket;
        uint256 LimitsCount;
        mapping(uint256 => Limits) limits;
        uint256 MaxPercentFromSum;
    }

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 TicketsEarnings;
        uint256 refferertoWithdraw;
        uint256 allWithdraw;
        uint256 lastWithdrawDate;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => InvestmentData) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
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

contract TronX2Card is Ownable {
    using SafeMath for uint256;
    uint256 public constant MARKETING_RATE = 100; // - 10%
    uint256 private constant REFERENCE_RATE = 230; // - 23%
    uint256 public constant REFERENCE_LEVEL1_RATE = 100; // 10%
    uint256 public constant REFERENCE_LEVEL2_RATE = 80; // 8%
    uint256 public constant REFERENCE_LEVEL3_RATE = 50; // 5%
    uint256 private constant REFERRER_CODE = 1000;
    uint256 private constant DATE_START = 1608883200; // START DATE TIME 25.12.2020 00:00

    uint256 private latestReferrerCode;
    uint256 private totalTurnover_;
    
    address private marketingAccount_;
    address private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.InvestmentData[] private InvestmentsList_;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor() public {
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {

        } else {
           // invest(0, 0); //default to buy plan 0, no referrer
        }
    }


    // Метод модифицирует адрес Marketing Account
    function setMarketingAccount(address _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }

    // Метод отдает Основные Адреса Контракта
    function getContractAccounts() public view onlyOwner returns (address,address) {
        return (marketingAccount_,referenceAccount_);
    }
     
    // Метод модифицирует адрес референс аккаунта
    function setReferenceAccount(address _newReferenceAccount) public onlyOwner {
        require(_newReferenceAccount != address(0));
        referenceAccount_ = _newReferenceAccount;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        
        //investmentPlans_.push(Objects.Plan(0, 1000000, 0, 200));
    }
    
    
    // Метод добавляет план
    function addNewPlan(uint256 _planId, uint256 _PriceOneTicket, uint256 _MaxPercentFromSum) public onlyOwner{
        investmentPlans_.push(Objects.Plan(_planId, _PriceOneTicket, 0, _MaxPercentFromSum));
    }
    
        // Метод дает возможность администратору указывать количество билетов в последнем лимите
function editPlanLastLimit(uint256 _planId, uint256 _countTickets) public onlyOwner returns (bool) {
    Objects.Limits storage limits = investmentPlans_[_planId].limits[_getlastlimitinplan(_planId)];
    require(limits.limitAlreadyBuy < _countTickets, "There are more tickets already purchased than you indicated");
    limits.limitCountTickets = _countTickets;
    if(limits.limitAlreadyBuy >= _countTickets) { limits.limitIsClosed = block.timestamp; } else { limits.limitIsClosed = 0; }
    return true;
}
        
    // Метод добавляет лимит
    function addNewLimitToPlan(uint256 _planId, uint256 _countTickets) public onlyOwner {
        Objects.Plan storage plan = investmentPlans_[_planId];
        Objects.Limits storage limits = investmentPlans_[_planId].limits[_getlastlimitinplan(_planId)];
        require(limits.limitIsClosed > 0 || limits.limitCountTickets <= 0, "You cannot create a new limit in this plan until the previous one is closed");
        plan.limits[plan.LimitsCount].limitId = investmentPlans_[_planId].LimitsCount;
        plan.limits[plan.LimitsCount].limitCountTickets = _countTickets;
        plan.limits[plan.LimitsCount].limitAlreadyBuy = 0;
        plan.limits[plan.LimitsCount].limitIsClosed = 0;
        plan.LimitsCount = plan.LimitsCount.add(1);
    }
    
    // Метод удаляет план
function removePlan(uint256 _planId) public onlyOwner returns (uint256){
        for (uint256 i = _planId; i<investmentPlans_.length-1; i++){
            investmentPlans_[i] = investmentPlans_[i+1];
        }
        delete investmentPlans_[investmentPlans_.length-1];
        investmentPlans_.length--;
}
    
    // Метод отдает матричные планы
    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory idplan = new uint256[](investmentPlans_.length);
        uint256[] memory LimitsCount = new uint256[](investmentPlans_.length);
        uint256[] memory ticketprice = new uint256[](investmentPlans_.length);
        uint256[] memory maxpercsum = new uint256[](investmentPlans_.length);
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            idplan[i] = plan.OptionPlan;
            LimitsCount[i] = plan.LimitsCount;
            ticketprice[i] = plan.PriceOneTicket;
            maxpercsum[i] = plan.MaxPercentFromSum;
        }
        return
        (
        ids,
        idplan,
        LimitsCount,
        ticketprice,
        maxpercsum
        );
    }

    // Метод отдает общее количество инвестированныйх средств
    function getTotalTurnover() public view returns (uint256){
        return totalTurnover_;
    }

    // метод отдает количество средст на балансе
    function getBalance() private view returns (uint256) {
        return address(this).balance;
    }

    // метод отдает
    function getUIDByAddress(address _addr) private view returns (uint256) {
        return address2UID[_addr];
    }

    function getUserInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        
        return
        (
        investor.referrerEarnings,
        investor.TicketsEarnings,
        investor.refferertoWithdraw,
        investor.allWithdraw,
        investor.lastWithdrawDate,
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        investor.planCount
        );
    }


       
function getLimitsByPlan(uint256 _planId) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
Objects.Plan storage plan = investmentPlans_[_planId];
        uint256[] memory limitId = new  uint256[](plan.LimitsCount);
        uint256[] memory limitCountTickets = new  uint256[](plan.LimitsCount);
        uint256[] memory limitAlreadyBuy = new  uint256[](plan.LimitsCount);
        uint256[] memory limitMaxProfutPerc = new  uint256[](plan.LimitsCount);
        uint256[] memory limitIsClosed = new  uint256[](plan.LimitsCount);

        for (uint256 i = 0; i < plan.LimitsCount; i++) {
            limitId[i] = plan.limits[i].limitId;
            limitCountTickets[i] = plan.limits[i].limitCountTickets;
            limitAlreadyBuy[i] = plan.limits[i].limitAlreadyBuy;
            limitMaxProfutPerc[i] = plan.MaxPercentFromSum;
            limitIsClosed[i] = plan.limits[i].limitIsClosed;
        }

        return
        (
        limitId,
        limitCountTickets,
        limitAlreadyBuy,
        limitMaxProfutPerc,
        limitIsClosed
        );
}
        
    function getInvestPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentLimit = new  uint256[](investor.planCount);
        uint256[] memory toEarn = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory investIsFinish = new  uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong position date");
            planIds[i] = investor.plans[i].planId;
            investmentLimit[i] = investor.plans[i].investmentLimit;
            toEarn[i] = _getprofitbypocket(investor.plans[i].investmentIdList);
            investments[i] = investor.plans[i].investmentSum;
            investIsFinish[i] = investor.plans[i].investIsFinish;
        }

        return
        (
        planIds,
        investmentLimit,
        investments,
        toEarn,
        investIsFinish
        );
    }
  

function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        address addrs_ = msg.sender;
        uint256 uid = address2UID[addrs_];
        Objects.Investor storage investor = uid2Investor[uid];
        require(uid != 0, "Can not withdraw because no any positions");
        uint256 withdrawalAmount = 0;
        withdrawalAmount = withdrawalAmount.add(_collectsum(uid));
        investor.TicketsEarnings = investor.TicketsEarnings.add(withdrawalAmount);
        if(investor.refferertoWithdraw > 0) {
        withdrawalAmount = withdrawalAmount.add(investor.refferertoWithdraw);
        investor.refferertoWithdraw = 0;
        }
        require(withdrawalAmount > 0, "Your balance is empty");
        investor.lastWithdrawDate = block.timestamp;
        investor.allWithdraw = investor.allWithdraw.add(withdrawalAmount);
        addrs_.transfer(withdrawalAmount);
        withdrawalAmount = 0;
        emit onWithdraw(addrs_, withdrawalAmount);
  }



    function invest(uint256 _referrerCode, uint256 _planId, uint256 _countTickets) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, _countTickets)) {
            emit onInvest(msg.sender, msg.value);
        }
    }
    
    
    function _Registration(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uid2Investor[_ref1].level1RefCount = uid2Investor[_ref1].level1RefCount.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].level2RefCount = uid2Investor[_ref2].level2RefCount.add(1);
            }
            if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].level3RefCount = uid2Investor[_ref3].level3RefCount.add(1);
            }
        }
        return (latestReferrerCode);
    }
    
    function _getlastlimitinplan(uint256 _planId) private view returns(uint256) {
    Objects.Plan storage plan = investmentPlans_[_planId];
    uint256 selectedlimit = 0;
    uint256 i2 = 0;
  for (uint256 i = 0; i < plan.LimitsCount; i++) {
      if(plan.limits[i].limitIsClosed == 0) {
          selectedlimit = i;
          break;
      }
      i2 = i;
  }
  if(selectedlimit == 0) { selectedlimit = i2; }
  return selectedlimit;
    }
    
    function _getlastfulllimitinplan(uint256 _planId) private view returns(uint256) {
    Objects.Plan storage plan = investmentPlans_[_planId];
    uint256 selectedlimit = 0;
    uint256 i2 = 0;
  for (uint256 i = 0; i < plan.LimitsCount; i++) {
      if(plan.limits[i].limitIsClosed == 0) {
          selectedlimit = i2;
          break;
      }
      i2 = i;
  }
  if(selectedlimit == 0) { selectedlimit = i2; }
  return selectedlimit;
    }
    
    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _countTickets) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong position plan id");
        uint256 amounttopay_ = msg.value;
        uint256 _amount = _countTickets.mul(investmentPlans_[_planId].PriceOneTicket);
        require(_amount == amounttopay_, "You paid less than specified in the contract count Tickets");
        uint256 uid = address2UID[_addr];
        //require(uid != 0, "You are not register");
        if (uid == 0) {
            uid = _Registration(_addr, _referrerCode);
            //new user
        } else {
            //old user
            //do nothing, referrer is permanent
        }
        uint256 lastlimitPlan = _getlastlimitinplan(_planId);
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        Objects.Limits storage limits = investmentPlans_[_planId].limits[lastlimitPlan];
        require(limits.limitAlreadyBuy.add(_countTickets) <= limits.limitCountTickets && limits.limitIsClosed == 0, "You are trying to buy more tickets than are issued");
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentIdList = InvestmentsList_.length;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].investmentLimit = lastlimitPlan;
        investor.plans[planCount].investmentSum = _amount;
        investor.plans[planCount].TicketsCount = _countTickets;
        investor.plans[planCount].investIsFinish = 0;
        limits.limitAlreadyBuy = limits.limitAlreadyBuy.add(_countTickets);
        if(limits.limitAlreadyBuy >= limits.limitCountTickets) { limits.limitIsClosed = block.timestamp; }
        InvestmentsList_.push(Objects.InvestmentData(_planId, InvestmentsList_.length, uid, block.timestamp, lastlimitPlan, _amount, 0, _countTickets, 0, 0)); 
        
        investor.planCount = investor.planCount.add(1);
        _calculateReferrerReward(_amount, investor.referrer);
        totalTurnover_ = totalTurnover_.add(_amount);
   
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        if(limits.limitId == 0) { marketingPercentage = marketingPercentage.add((_amount.mul(670)).div(1000));  } 
        marketingAccount_.transfer(marketingPercentage);
        
        
        return true;
    }
    
    
    function _getprofitbypocket(uint256 _investmentId) private view returns (uint256) {
     
    Objects.InvestmentData storage UserInvestment = InvestmentsList_[_investmentId];
    if (msg.sender != owner) {
    require(address2UID[msg.sender] == UserInvestment.investmentUID, "only owner or self can check the investment plan profit info.");
    }
    uint256 AllSumProfit = 0;
    uint256 TicketsalltoPay = 0;
    uint256 TicketsalltoPayAlready = 0;
    uint256 TicketsByLimits = 0;
    uint256 LastLimit = 0;

 for (uint256 i = 0; i < InvestmentsList_.length; i++) {
    Objects.InvestmentData storage investment = InvestmentsList_[i];
    Objects.Limits storage limits = investmentPlans_[UserInvestment.planId].limits[investment.investmentLimit];
    if(UserInvestment.investIsFinish > 0) {
    break;
    }
if(investment.planId == UserInvestment.planId && limits.limitIsClosed > 0) {
    if(UserInvestment.investmentLimit < limits.limitId && UserInvestment.lastWithdrawLimit < limits.limitId) {
      if(LastLimit != investment.investmentLimit) {
       TicketsByLimits = TicketsalltoPay;
       LastLimit = investment.investmentLimit;
      }
      
        if(TicketsByLimits > 0) {
        AllSumProfit = AllSumProfit.add((investment.investmentSum).div(TicketsByLimits.sub(TicketsalltoPayAlready)));
        } else {
        AllSumProfit = AllSumProfit.add(investment.investmentSum);
        } 

    }
    if(investment.investIsFinish == 0 || investment.investIsFinish > 0 && investment.investIsFinish > UserInvestment.investmentDate) {
    TicketsalltoPay = TicketsalltoPay.add(investment.TicketsCount);
    if(investment.investIsFinish > 0 && (investment.investIsFinish < block.timestamp && UserInvestment.investmentUID == investment.investmentUID || UserInvestment.investmentUID != investment.investmentUID) && investment.lastWithdrawLimit <= UserInvestment.lastWithdrawLimit ) { TicketsalltoPayAlready = TicketsalltoPayAlready.add(investment.TicketsCount);}
    } 
}   
  }
 if(AllSumProfit > 0) { 
    return AllSumProfit.mul(UserInvestment.TicketsCount).mul(670).div(1000);
       } else {
    return 0;
       } 
       
    }
    

    
// Считает сколько нужно выплатить пользователю
function _collectsum(uint256 _userId) private returns (uint256) {
    if (msg.sender != owner) {
            require(address2UID[msg.sender] == _userId, "only owner or self can check the withdraw sum info.");
    }
    Objects.Investor storage investor = uid2Investor[_userId];
    uint256 CollecuSum = 0;
    uint256 ProfitAdd = 0;
    
  for (uint256 i = 0; i < investor.planCount; i++) {
        require(investor.plans[i].investmentDate!=0,"wrong position date");
        
      if(investor.plans[i].investIsFinish == 0) { 
        Objects.InvestmentData storage investmentInList = InvestmentsList_[investor.plans[i].investmentIdList];
        Objects.InvestmentData storage investmentUser = investor.plans[i];
        ProfitAdd = ProfitAdd.add(_getprofitbypocket(investmentInList.investmentIdList));
        uint lastfulllimitplan = _getlastfulllimitinplan(investmentInList.planId);
if(ProfitAdd > 0) {
    uint256 ifmaxsum = (investmentUser.investmentSum.mul(investmentPlans_[investmentUser.planId].MaxPercentFromSum)).div(100);
    if((investmentUser.investmentProfit.add(ProfitAdd)) < ifmaxsum ) {
    CollecuSum = CollecuSum.add(ProfitAdd);  
    investmentUser.investmentProfit = investmentUser.investmentProfit.add(ProfitAdd);
    investmentInList.investmentProfit = investmentInList.investmentProfit.add(ProfitAdd);
    investmentUser.lastWithdrawLimit = lastfulllimitplan;
    investmentInList.lastWithdrawLimit = lastfulllimitplan;
    } else {
        if( ifmaxsum.sub(investmentUser.investmentProfit) > 0 ) {
  uint256 referenceprofit = ProfitAdd.sub(ifmaxsum.sub(investmentUser.investmentProfit));
   if(referenceprofit > 0) { referenceAccount_.transfer(referenceprofit); }
    CollecuSum = CollecuSum.add(ifmaxsum.sub(investmentUser.investmentProfit)); 
    investmentUser.investmentProfit = ifmaxsum;   
    investmentUser.investIsFinish = block.timestamp;
    investmentUser.lastWithdrawLimit = lastfulllimitplan;
    investmentInList.investmentProfit = ifmaxsum;
    investmentInList.investIsFinish = block.timestamp;
    investmentInList.lastWithdrawLimit = lastfulllimitplan;
    
        }
    } 
}

       }
     ProfitAdd = 0;

  }


return CollecuSum;
}

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        
        if (_referrerCode != 0 && _referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _refAmount = 0;
            _allReferrerAmount = 0;

            if (_ref1 > 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                uid2Investor[_ref1].referrerEarnings = uid2Investor[_ref1].referrerEarnings.add(_refAmount);
                uid2Investor[_ref1].refferertoWithdraw = uid2Investor[_ref1].refferertoWithdraw.add(_refAmount);
            } else {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.add(_refAmount);
            }

            if (_ref2 > 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                uid2Investor[_ref2].referrerEarnings = uid2Investor[_ref2].referrerEarnings.add(_refAmount);
                uid2Investor[_ref2].refferertoWithdraw = uid2Investor[_ref2].refferertoWithdraw.add(_refAmount);
            } else {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.add(_refAmount);
            }

            if (_ref3 > 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                uid2Investor[_ref3].referrerEarnings = uid2Investor[_ref3].referrerEarnings.add(_refAmount);
                uid2Investor[_ref3].refferertoWithdraw = uid2Investor[_ref3].refferertoWithdraw.add(_refAmount);
            } else {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.add(_refAmount);
            }
        }

        if (_allReferrerAmount > 0) {
            referenceAccount_.transfer(_allReferrerAmount);
        }
    }
}