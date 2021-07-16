//SourceUnit: OpenTronBank.sol

/*
╔═══╗╔═══╗╔═══╗╔═╗─╔╗     ╔════╗╔═══╗╔═══╗╔═╗─╔╗     ╔══╗─╔═══╗╔═╗─╔╗╔╗╔═╗
║╔═╗║║╔═╗║║╔══╝║║╚╗║║     ║╔╗╔╗║║╔═╗║║╔═╗║║║╚╗║║     ║╔╗║─║╔═╗║║║╚╗║║║║║╔╝
║║─║║║╚═╝║║╚══╗║╔╗╚╝║     ╚╝║║╚╝║╚═╝║║║─║║║╔╗╚╝║     ║╚╝╚╗║║─║║║╔╗╚╝║║╚╝╝─
║║─║║║╔══╝║╔══╝║║╚╗║║     ──║║──║╔╗╔╝║║─║║║║╚╗║║     ║╔═╗║║╚═╝║║║╚╗║║║╔╗║─
║╚═╝║║║───║╚══╗║║─║║║     ──║║──║║║╚╗║╚═╝║║║─║║║     ║╚═╝║║╔═╗║║║─║║║║║║╚╗
╚═══╝╚╝───╚═══╝╚╝─╚═╝     ──╚╝──╚╝╚═╝╚═══╝╚╝─╚═╝     ╚═══╝╚╝─╚╝╚╝─╚═╝╚╝╚═╝
*/
pragma solidity ^0.5.12;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }
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
        uint dailyInterest;
        uint term;
        uint maxDailyInterest;
    }
    struct Investor {
        address addr;
        uint referrerEarnings;
        uint availableReferrerEarnings;
        uint referrer;
        uint planCount;
        mapping(uint => Investment) plans;
        uint level1RefCount;
        uint level2RefCount;
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

contract OpenTronBank is Ownable {
    using SafeMath for uint;
    uint private constant INTEREST_CYCLE = 1 days;
    uint private constant DEVELOPER_ENTRY_RATE = 20;
    uint private constant ADMIN_ENTRY_RATE = 90;
    uint private constant REFERENCE_RATE = 60;
    uint private constant DEVELOPER_EXIT_RATE = 10;
    uint private constant ADMIN_EXIT_RATE = 30;


    uint public constant REFERENCE_LEVEL1_RATE = 50;
    uint public constant REFERENCE_LEVEL2_RATE = 10;
    uint public constant MINIMUM = 10000000;
    uint public constant REFERRER_CODE = 6666;

    uint public latestReferrerCode;
    uint private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private referenceAccount_;

    mapping(address => uint) public address2UID;
    mapping(uint => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint amount);
    event onGrant(address grantor, address beneficiary, uint amount);
    event onWithdraw(address investor, uint amount);

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

    function setMarketingAccount(address payable _newMarketingAccount) external onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }

    function getMarketingAccount() external view onlyOwner returns (address) {
        return marketingAccount_;
    }

    function getDeveloperAccount() external view onlyOwner returns (address) {
        return developerAccount_;
    }

    function setReferenceAccount(address payable _newReferenceAccount) external onlyOwner {
        require(_newReferenceAccount != address(0));
        referenceAccount_ = _newReferenceAccount;
    }

    function getReferenceAccount() external view onlyOwner returns (address) {
        return referenceAccount_;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        investmentPlans_.push(Objects.Plan(27, 79*60*60*24,37)); //79 days
        investmentPlans_.push(Objects.Plan(37, 48*60*60*24,47)); //48 days
        investmentPlans_.push(Objects.Plan(47, 28*60*60*24,57)); //28 days
        investmentPlans_.push(Objects.Plan(57, 20*60*60*24,67)); //20 days
    }

    function getCurrentPlans() external view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        uint[] memory ids = new uint[](investmentPlans_.length);
        uint[] memory interests = new uint[](investmentPlans_.length);
        uint[] memory terms = new uint[](investmentPlans_.length);
        uint[] memory maxInterests = new uint[](investmentPlans_.length);
        for (uint i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            interests[i] = plan.dailyInterest;
            maxInterests[i] = plan.maxDailyInterest;
            terms[i] = plan.term;
        }
        return ( ids, interests, maxInterests, terms );
    }

    function getTotalInvestments() external view returns (uint){
        return totalInvestments_;
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) external view returns (uint) {
        return address2UID[_addr];
    }

    function getInvestorInfoByUID(uint _uid) external view returns (uint, uint, uint, uint, uint, uint, uint[] memory, uint[] memory) {
        if (msg.sender != owner) {
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
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                }
            }
        }
        return ( investor.referrerEarnings, investor.availableReferrerEarnings, investor.referrer, investor.level1RefCount, investor.level2RefCount, investor.planCount, currentDividends, newDividends );
    }

    function getInvestmentPlanByUID(uint _uid) external view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory,uint[] memory, bool[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint[] memory planIds = new  uint[](investor.planCount);
        uint[] memory investmentDates = new  uint[](investor.planCount);
        uint[] memory investments = new  uint[](investor.planCount);
        uint[] memory currentDividends = new  uint[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);
        uint[] memory newDividends = new uint[](investor.planCount);
        uint[] memory interests = new uint[](investor.planCount);

        for (uint i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            planIds[i] = investor.plans[i].planId;
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
                newDividends[i] = 0;
                interests[i] = investmentPlans_[investor.plans[i].planId].dailyInterest;
            } else {
                isExpireds[i] = false;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                        isExpireds[i] = true;
                        interests[i] = investmentPlans_[investor.plans[i].planId].dailyInterest;
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                        uint numberOfDays =  (block.timestamp - investor.plans[i].lastWithdrawalDate) / INTEREST_CYCLE ;
                        interests[i] = (numberOfDays < 10) ? investmentPlans_[investor.plans[i].planId].dailyInterest + numberOfDays : investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                    uint numberOfDays =  (block.timestamp - investor.plans[i].lastWithdrawalDate) / INTEREST_CYCLE ;
                    interests[i] = (numberOfDays < 10) ? investmentPlans_[investor.plans[i].planId].dailyInterest + numberOfDays : investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                }
            }
        }
        return ( planIds, investmentDates, investments, currentDividends, newDividends, interests, isExpireds );
    }

    function _addInvestor(address _addr, uint _referrerCode) private returns (uint) {
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
            uint _ref1 = _referrerCode;
            uint _ref2 = uid2Investor[_ref1].referrer;
            uid2Investor[_ref1].level1RefCount = uid2Investor[_ref1].level1RefCount.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].level2RefCount = uid2Investor[_ref2].level2RefCount.add(1);
            }
        }
        return ( latestReferrerCode );
    }

    function _invest(address _addr, uint _planId, uint _referrerCode, uint _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
        }
        uint planCount = uid2Investor[uid].planCount;
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
        uint developerPercentage = (_amount.mul(DEVELOPER_ENTRY_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint marketingPercentage = (_amount.mul(ADMIN_ENTRY_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        return true;
    }

    function grant(address addr, uint _planId) public payable {
        uint grantorUid = address2UID[msg.sender];
        bool isAutoAddReferrer = true;
        uint referrerCode = 0;
        if (grantorUid != 0 && isAutoAddReferrer) {
            referrerCode = grantorUid;
        }
        if (_invest(addr,_planId,referrerCode,msg.value)) {
            emit onGrant(msg.sender, addr, msg.value);
        }
    }

    function invest(uint _referrerCode, uint _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
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
            uint amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate , plan.maxDailyInterest);
            withdrawalAmount += amount;
            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
        }
        uint developerPercentage = (withdrawalAmount.mul(DEVELOPER_EXIT_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint marketingPercentage = (withdrawalAmount.mul(ADMIN_EXIT_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        msg.sender.transfer(withdrawalAmount.sub(developerPercentage.add(marketingPercentage)));
        if (uid2Investor[uid].availableReferrerEarnings>0) {
            msg.sender.transfer(uid2Investor[uid].availableReferrerEarnings);
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }
        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint _amount, uint _dailyInterestRate, uint _now, uint _start , uint _maxDailyInterest) private pure returns (uint) {
        uint numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint result = 0;
        uint index = 0;
        if(numberOfDays > 0){
            uint secondsLeft = (_now - _start);
            for (index; index < numberOfDays; index++) {
                if(_dailyInterestRate + index <= _maxDailyInterest ){
                    secondsLeft -= INTEREST_CYCLE;
                    result += (_amount * (_dailyInterestRate + index) / 1000 * INTEREST_CYCLE) / (60*60*24);
                } else {
                    break;
                }
            }
            result += (_amount * (_dailyInterestRate + index) / 1000 * secondsLeft) / (60*60*24);
            return result;
        } else {
            return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
        }
    }

    function _calculateReferrerReward(uint _investment, uint _referrerCode) private {
        uint _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint _ref1 = _referrerCode;
            uint _ref2 = uid2Investor[_ref1].referrer;
            uint _refAmount = 0;
            if (_ref1 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
            }
            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
            }
        }
        if (_allReferrerAmount > 0) {
            referenceAccount_.transfer(_allReferrerAmount);
        }
    }
}