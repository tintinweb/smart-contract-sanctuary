//SourceUnit: SpecialTron.sol

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
        address addr;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
        uint256 level4RefCount;
        uint256 level5RefCount;
        uint256 timer;
        uint256 turnover;
        uint256 currentLevel;
        uint256 bonusEarnings;
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

contract SpecialTron is Ownable {
    using SafeMath for uint256;

    uint256 public constant DEVELOPER_RATE = 60;                  // 6 %
    uint256 public constant MARKETING_RATE = 60;                  // 6 %
    uint256 public constant ADMIN_RATE = 20;                      // 2 %
    uint256 public constant REFERENCE_RATE = 150;                 // 15 % Total
    uint256 public constant REFERENCE_LEVEL1_RATE = 50;           // 5 %
    uint256 public constant REFERENCE_LEVEL2_RATE = 40;           // 4 %
    uint256 public constant REFERENCE_LEVEL3_RATE = 30;           // 3 %
    uint256 public constant REFERENCE_LEVEL4_RATE = 20;           // 2 %
    uint256 public constant REFERENCE_LEVEL5_RATE = 10;           // 1 %
    uint256 public constant ACTIVATION_TIME = 1606845600;

    uint256 public constant MINIMUM = 50000000;                   // Minimum 50 Tron 
    uint256 public constant REFERRER_CODE = 6666;   

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private adminAccount_;
    address payable private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    mapping(uint256 => Objects.Bonus) public bonusLevels;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onGrant(address grantor, address beneficiary, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = address(0xE4b5d489258E6239E6811536A178811ec6f7505b);
        adminAccount_ = address(0xD468596D5F8C4a9f82B98680621ab1022b6c24C5);
        referenceAccount_ = msg.sender;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0, 0); //default to buy plan 0, no referrer
        }
    }

    function checkIn() public {
    }


    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }

    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
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
        investmentPlans_.push(Objects.Plan(100, 12*60*60*24));     // 120 % Return
        investmentPlans_.push(Objects.Plan(150, 10*60*60*24));     // 150 % Return
        investmentPlans_.push(Objects.Plan(200, 8*60*60*24));      // 160 % Return
        investmentPlans_.push(Objects.Plan(280, 7*60*60*24));      // 196 % Return

        bonusLevels[1] = Objects.Bonus(10000*1e6,150*1e6);
        bonusLevels[2] = Objects.Bonus(15000*1e6,350*1e6);
        bonusLevels[3] = Objects.Bonus(50000*1e6,800*1e6);
        bonusLevels[4] = Objects.Bonus(100000*1e6,2000*1e6);
        bonusLevels[5] = Objects.Bonus(500000*1e6,10000*1e6);
        bonusLevels[6] = Objects.Bonus(1000000*1e6,22000*1e6);
        bonusLevels[7] = Objects.Bonus(5000000*1e6,125000*1e6);
        bonusLevels[8] = Objects.Bonus(10000000*1e6,305000*1e6);
        bonusLevels[9] = Objects.Bonus(15000000*1e6,1000000*1e6);


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

     function getTimer(address _addr) public view returns (uint256) {
        return uid2Investor[address2UID[_addr]].timer;
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256,uint256,uint256, uint256, uint256[] memory, uint256[] memory,uint256[] memory) {
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
        investor.availableReferrerEarnings,
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        investor.level4RefCount,
        investor.level5RefCount,
        investor.planCount,
        currentDividends,
        newDividends,
        refStats
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
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uid2Investor[_ref1].level1RefCount = uid2Investor[_ref1].level1RefCount.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].level2RefCount = uid2Investor[_ref2].level2RefCount.add(1);
            }
            if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].level3RefCount = uid2Investor[_ref3].level3RefCount.add(1);
            }
            if (_ref4 >= REFERRER_CODE) {
                uid2Investor[_ref4].level4RefCount = uid2Investor[_ref4].level4RefCount.add(1);
            }
            if (_ref5 >= REFERRER_CODE) {
                uid2Investor[_ref5].level5RefCount = uid2Investor[_ref5].level5RefCount.add(1);
            }
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(ACTIVATION_TIME < now , "NOT_YET_LAUNCHED");
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

    function grant(address addr, uint256 _planId) public payable {
        uint256 grantorUid = address2UID[msg.sender];
        bool isAutoAddReferrer = true;
        uint256 referrerCode = 0;

        if (grantorUid != 0 && isAutoAddReferrer) {
            referrerCode = grantorUid;
        }

        if (_invest(addr,_planId,referrerCode,msg.value)) {
            emit onGrant(msg.sender, addr, msg.value);
        }
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

        require(uid2Investor[uid].timer < now, "withdrawal is available only once every 48 hours");

        uid2Investor[uid].timer = now + 48 hours;

        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }
            }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate);

            withdrawalAmount += amount;
          
            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
        }

        msg.sender.transfer(withdrawalAmount);

        if (uid2Investor[uid].availableReferrerEarnings>0) {
            msg.sender.transfer(uid2Investor[uid].availableReferrerEarnings);
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    function _calculateReferrerReward( uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;

            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
                uid2Investor[_ref1].turnover = _investment.add(uid2Investor[_ref1].turnover);

                if(uid2Investor[_ref1].currentLevel < 9 && bonusLevels[uid2Investor[_ref1].currentLevel + 1].gap <= uid2Investor[_ref1].turnover ){
                    uid2Investor[_ref1].availableReferrerEarnings = bonusLevels[uid2Investor[_ref1].currentLevel + 1].prize.add(uid2Investor[_ref1].availableReferrerEarnings);
                    uid2Investor[_ref1].currentLevel++;
                    uid2Investor[_ref1].bonusEarnings = bonusLevels[uid2Investor[_ref1].currentLevel].prize.add(uid2Investor[_ref1].bonusEarnings);
                }
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
                uid2Investor[_ref2].turnover = (_investment.div(2)).add(uid2Investor[_ref2].turnover);
                if(uid2Investor[_ref2].currentLevel < 9 && bonusLevels[uid2Investor[_ref2].currentLevel + 1].gap <= uid2Investor[_ref2].turnover ){
                    uid2Investor[_ref2].availableReferrerEarnings = bonusLevels[uid2Investor[_ref2].currentLevel + 1].prize.add(uid2Investor[_ref2].availableReferrerEarnings);
                    uid2Investor[_ref2].currentLevel++;
                    uid2Investor[_ref2].bonusEarnings = bonusLevels[uid2Investor[_ref2].currentLevel].prize.add(uid2Investor[_ref2].bonusEarnings);

                }
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
                uid2Investor[_ref3].turnover = (_investment.div(4)).add(uid2Investor[_ref3].turnover);
                if(uid2Investor[_ref3].currentLevel < 9 && bonusLevels[uid2Investor[_ref3].currentLevel + 1].gap <= uid2Investor[_ref3].turnover ){
                    uid2Investor[_ref3].availableReferrerEarnings = bonusLevels[uid2Investor[_ref3].currentLevel + 1].prize.add(uid2Investor[_ref3].availableReferrerEarnings);
                    uid2Investor[_ref3].currentLevel++;
                    uid2Investor[_ref3].bonusEarnings = bonusLevels[uid2Investor[_ref3].currentLevel].prize.add(uid2Investor[_ref3].bonusEarnings);

                }
            }

            if (_ref4 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref4].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref4].availableReferrerEarnings);
                uid2Investor[_ref4].turnover = (_investment.div(10)).add(uid2Investor[_ref4].turnover);
                if(uid2Investor[_ref4].currentLevel < 9 && bonusLevels[uid2Investor[_ref4].currentLevel + 1].gap <= uid2Investor[_ref4].turnover ){
                    uid2Investor[_ref4].availableReferrerEarnings = bonusLevels[uid2Investor[_ref4].currentLevel + 1].prize.add(uid2Investor[_ref4].availableReferrerEarnings);
                    uid2Investor[_ref4].currentLevel++;
                    uid2Investor[_ref4].bonusEarnings = bonusLevels[uid2Investor[_ref4].currentLevel].prize.add(uid2Investor[_ref4].bonusEarnings);
                }
            }

            if (_ref5 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL5_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref5].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref5].availableReferrerEarnings);
                uid2Investor[_ref5].turnover = (_investment.div(20)).add(uid2Investor[_ref5].turnover);
                if(uid2Investor[_ref5].currentLevel < 9 && bonusLevels[uid2Investor[_ref5].currentLevel + 1].gap <= uid2Investor[_ref5].turnover ){
                    uid2Investor[_ref5].availableReferrerEarnings = bonusLevels[uid2Investor[_ref5].currentLevel + 1].prize.add(uid2Investor[_ref5].availableReferrerEarnings);
                    uid2Investor[_ref5].currentLevel++;
                    uid2Investor[_ref5].bonusEarnings = bonusLevels[uid2Investor[_ref5].currentLevel].prize.add(uid2Investor[_ref5].bonusEarnings);
                }
            }
        }

        if (_allReferrerAmount > 0) {
            referenceAccount_.transfer(_allReferrerAmount);
        }
    }

}