//SourceUnit: TronMine.sol

pragma solidity ^0.5.0;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    struct Investment {
        uint256 startInterest;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 lastSettleDate;
        uint256 currentDividends;
        bool isBoost;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 boostInterest;
    }

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
        uint256 lastWithdrawalDate;
    }
}

contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

}

contract TronMine is Ownable {
    using SafeMath for uint256;
  
    uint256 public constant REFERENCE_RATE = 80;
    uint256 public constant REFERENCE_LEVEL1_RATE = 50;
    uint256 public constant REFERENCE_LEVEL2_RATE = 20;
    uint256 public constant REFERENCE_LEVEL3_RATE = 5;
    uint256 public constant REFERENCE_SELF_RATE = 5;
    uint256 public constant MINIMUM = 1000000; //minimum investment needed
    uint256 public constant REFERRER_CODE = 1000; //default
    uint256 public constant timeDivider = 60*60*24; // Production 60*60*24 
    uint256 public constant hourElapse = 3600; // hourly elaposed time in ms
    uint256 public constant _launchDate = 1601722800; 

    uint256 private VAULT_RATE = 10; 
    uint256 private ti_;
    uint256 private tw_;

    uint256 public latestReferrerCode;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);
    event onBoost(address investor, uint256 amount);

    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        _init();
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0); //default to buy plan 0, no referrer
        }
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        investmentPlans_.push(Objects.Plan(1,4)); // regular start rates 0.1%, boost start rates 0.4%
    }

    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory interests = new uint256[](investmentPlans_.length);
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            interests[i] = plan.dailyInterest;
        }
        return
        (
        ids,
        interests
        );
    }

    function getLatestReferrerCode() public view returns (uint256){
        return latestReferrerCode;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getHourlyProduction(uint256 _investment, uint256 _days, bool _isboost) public view returns (uint256) {
    
        uint256 _startInterest = _isboost?investmentPlans_[0].boostInterest :investmentPlans_[0].dailyInterest;
        uint256 bonusRates = _calculateBoostBonusRatesDays(_days);
        uint256 hourlyProduction = _calculateHourlyDividends(_investment, (_startInterest).add(bonusRates));

        return hourlyProduction;
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256 referrerEarnings, uint256 availableReferrerEarnings, uint256 referrer, uint256 level1RefCount, uint256 level2RefCount, uint256 level3RefCount, uint256 planCount,uint256 lastWithdrawalDate,uint256[] memory currentDividends, uint256[] memory newDividends, uint256[] memory hourlyProductions) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        newDividends = new uint256[](investor.planCount);
        currentDividends = new  uint256[](investor.planCount);
        hourlyProductions = new  uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            newDividends[i] = _calculateNewDividends(
                block.timestamp,
                investor.plans[i].investment,
                investor.plans[i].startInterest,
                investor.plans[i].lastWithdrawalDate,
                investor.plans[i].lastSettleDate,
                investor.plans[i].isBoost
                );
            hourlyProductions[i] = _calculateHourlyProduction(
                block.timestamp,
                investor.plans[i].investment,
                investor.plans[i].startInterest,
                investor.plans[i].lastWithdrawalDate,
                investor.plans[i].isBoost
                );
        }

        referrerEarnings= investor.referrerEarnings;
        availableReferrerEarnings= investor.availableReferrerEarnings;
        referrer= investor.referrer;
        level1RefCount= investor.level1RefCount;
        level2RefCount= investor.level2RefCount;
        level3RefCount= investor.level3RefCount;
        planCount= investor.planCount;
        lastWithdrawalDate = investor.lastWithdrawalDate;

    }

    function getInvestorBonusInfoByUID(uint256 _uid) public view returns (uint256 lastWithdrawalDate, uint256 day) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        lastWithdrawalDate= investor.lastWithdrawalDate;
        day = _calculateDays(block.timestamp, lastWithdrawalDate);
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory investmentDates, uint256[] memory investments, uint256[] memory currentDividends, uint256[] memory newDividends, uint256[] memory currentInterests,uint256[] memory daysPassed,bool[] memory isBoosts) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        investmentDates = new  uint256[](investor.planCount);
        investments = new  uint256[](investor.planCount);
        currentDividends = new  uint256[](investor.planCount);
        currentInterests = new  uint256[](investor.planCount);
        daysPassed = new  uint256[](investor.planCount);
        isBoosts = new bool[](investor.planCount);
        newDividends = new uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            isBoosts[i] = investor.plans[i].isBoost;
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            currentInterests[i] =  (investor.plans[i].startInterest).add(_calculateBonusRates(block.timestamp, investor.plans[i].lastWithdrawalDate,investor.plans[i].isBoost));
            daysPassed[i] = _calculateDays(block.timestamp, investor.plans[i].lastWithdrawalDate);
            newDividends[i] = _calculateNewDividends(
                block.timestamp,
                investor.plans[i].investment,
                investor.plans[i].startInterest,
                investor.plans[i].lastWithdrawalDate,
                investor.plans[i].lastSettleDate,
                investor.plans[i].isBoost
                );
        }
    }
    function getLaunchDate() public view returns (uint256 launchDate, bool isOpen) {
        launchDate = _launchDate;
        isOpen = _checkTime();
    }

    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            //require(uid2Investor[_referrerCode].addr != address(0), "Wrong referrer code");
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
        uid2Investor[latestReferrerCode].lastWithdrawalDate = block.timestamp;
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

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount, bool isBoost) private returns (bool) {
        bool validTime = _checkTime();
        if(validTime)
        {
            require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
            require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
            uint256 uid = address2UID[_addr];
            if (uid == 0) {
                uid = _addInvestor(_addr, _referrerCode);
                //new user
            } else {//old user
                //do nothing, referrer is permenant
            }
            uint256 planCount = uid2Investor[uid].planCount;
            Objects.Investor storage investor = uid2Investor[uid];


            
            investor.plans[planCount].startInterest = isBoost?investmentPlans_[_planId].boostInterest :investmentPlans_[_planId].dailyInterest;
            investor.plans[planCount].isBoost = isBoost;
            investor.plans[planCount].investmentDate = block.timestamp;
            investor.plans[planCount].lastWithdrawalDate = block.timestamp;
            investor.plans[planCount].lastSettleDate = block.timestamp;
            investor.plans[planCount].investment = _amount;
            investor.plans[planCount].currentDividends = 0;

            investor.planCount = investor.planCount.add(1);

            _calculateReferrerReward(uid, _amount, investor.referrer);

            ti_ = ti_.add(_amount);

            return true;
        }
    }

    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, 0, _referrerCode, msg.value, false)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function withdraw() public {
        bool validTime = _checkTime();
        if(validTime)
        {
            uint256 withdrawalAmount = _withdraw();
            if (withdrawalAmount >= 0) {
                _updateLastWithdrawalDate();
                msg.sender.transfer(withdrawalAmount);
                emit onWithdraw(msg.sender, withdrawalAmount);
            }
        }
    }

    function boost() public {
        bool validTime = _checkTime();
        if(validTime)
        {
            uint256 withdrawalAmount = _withdraw();
            if (withdrawalAmount >= 0) {
                _updateLastSettleDate();
                if (_invest(msg.sender, 0, 0, withdrawalAmount, true)) {//existing user, _referrerCode is useless, just pass 0
                    emit onBoost(msg.sender, withdrawalAmount);
                }
            }
        }
    }

    function _withdraw() private returns (uint256)  {
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;

        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {

            Objects.Plan storage plan = investmentPlans_[0];

            uint256 withdrawalDate = block.timestamp;
            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastSettleDate);

            uint256 _bonusDailyInterestRate = _calculateBonusRates(block.timestamp, uid2Investor[uid].plans[i].lastWithdrawalDate,uid2Investor[uid].plans[i].isBoost);
                
            if(_bonusDailyInterestRate > 0) 
            {
                uint256 bonus = _calculateDividends(uid2Investor[uid].plans[i].investment, _bonusDailyInterestRate, withdrawalDate, uid2Investor[uid].plans[i].lastSettleDate);
           
                amount = amount.add(bonus);

            }
            
            withdrawalAmount = withdrawalAmount.add(amount);
            uid2Investor[uid].plans[i].currentDividends += amount;
        }
        tw_ = tw_.add(withdrawalAmount);

        if (uid2Investor[uid].availableReferrerEarnings>0) {
            withdrawalAmount = withdrawalAmount.add(uid2Investor[uid].availableReferrerEarnings);
            tw_ = tw_.add(uid2Investor[uid].availableReferrerEarnings);
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;     
        }

        _av(withdrawalAmount);

        return withdrawalAmount;
    }

    function _updateLastWithdrawalDate() private {
        uint256 uid = address2UID[msg.sender];
        uint256 withdrawalDate = block.timestamp;
        uid2Investor[uid].lastWithdrawalDate = withdrawalDate;

        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].lastSettleDate = withdrawalDate;
        }
    }

    function _updateLastSettleDate() private {
        uint256 uid = address2UID[msg.sender];
        uint256 settleDate = block.timestamp;
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            uid2Investor[uid].plans[i].lastSettleDate = settleDate;
        }
    }

    function _av(uint256 amount) private returns (bool) {
        if(amount > 0)
        {
            uint256 vaultFee=  amount.mul(VAULT_RATE).div(100); 
            uid2Investor[REFERRER_CODE].availableReferrerEarnings = vaultFee.add(uid2Investor[REFERRER_CODE].availableReferrerEarnings);
        }

        return true;
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
       
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (timeDivider);

    }

    function _calculateHourlyDividends(uint256 _amount, uint256 _dailyInterestRate) private pure returns (uint256) {
       
        return (_amount * _dailyInterestRate / 1000 * (hourElapse)) / (timeDivider);

    }

    function _calculateDays(uint256 _now, uint256 _start) private pure returns (uint256) {
        

        if(_start>0)
        {
            uint256 dayCount = 0;
            if(_now > _start)
            {
                dayCount = (_now - _start) / (timeDivider);
            }
            return dayCount;
        }else{
            return 0;
        }
        
    }

    function _calculateBonusRates(uint256 _now, uint256 _start, bool _isboost) private pure returns (uint256) {
        uint256 bonusrate = _isboost?_calculateBoostBonusRates(_now,_start):_calculateRegularBonusRates(_now,_start);
        return bonusrate;
    }

    function _calculateRegularBonusRates(uint256 _now, uint256 _start) private pure returns (uint256) {
        if(_start>0)
        {
            uint256 dayCount = 0;
            if(_now > _start)
            {
                dayCount = (_now - _start) / (timeDivider);
            }

            if (dayCount < 5) {
              return 0;
            } else if (dayCount < 10) {
              return 4; 
            } else if (dayCount < 20) {
              return 9; 
            } else if (dayCount < 30) {
              return 19; 
            } else{
              return 32; 
            }

        }else{
            return 0;
        }
    }


    function _calculateBoostBonusRates(uint256 _now, uint256 _start) private pure returns (uint256) {
        if(_start>0)
        {
            uint256 dayCount = 0;
            if(_now > _start)
            {
                dayCount = (_now - _start) / (timeDivider);
            }

            if (dayCount < 5) {
              return 0;
            } else if (dayCount < 10) {
              return 4; 
            } else if (dayCount < 20) {
              return 9; 
            } else if (dayCount < 30) {
              return 19; 
            } else{
              return 32; 
            }

        }else{
            return 0;
        }
    }

    function _calculateBoostBonusRatesDays(uint256 _days) private pure returns (uint256) {
        uint256 dayCount = _days;

        if (dayCount < 5) {
          return 0;
        } else if (dayCount < 10) {
          return 4; 
        } else if (dayCount < 20) {
          return 9; 
        } else if (dayCount < 30) {
          return 19; 
        } else{
          return 32; 
        }
    }

    function _calculateReferrerReward(uint256 _uid, uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
               
            
                _refAmount = (_investment.mul(REFERENCE_SELF_RATE)).div(1000);
                uid2Investor[_uid].availableReferrerEarnings =  _refAmount.add(uid2Investor[_uid].availableReferrerEarnings);

            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);

            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);

            }
        }
    }

    function _calculateNewDividends(uint256 _now, uint256 _investment, uint256 _startInterest, uint256 _lastWithdrawalDate,  uint256 _lastSettleDate, bool _isboost)private pure returns (uint256) {
       
        uint256 bonusRates = _calculateBonusRates(_now, _lastWithdrawalDate, _isboost);
        uint256 newDividends = _calculateDividends(_investment, (_startInterest).add(bonusRates), 
                _now, 
                _lastSettleDate);

        return newDividends;
    }

    function _calculateHourlyProduction(uint256 _now, uint256 _investment, uint256 _startInterest, uint256 _lastWithdrawalDate,  bool _isboost)private pure returns (uint256) {
       
        uint256 bonusRates = _calculateBonusRates(_now, _lastWithdrawalDate, _isboost);
        uint256 newDividends = _calculateHourlyDividends(_investment, (_startInterest).add(bonusRates));

        return newDividends;
    }

    function _checkTime() private view returns (bool) {
        if(block.timestamp>=_launchDate)
        {
            return true;
        }else{ // too early
            return false;
        }
    }
}