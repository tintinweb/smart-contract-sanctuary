//SourceUnit: roi.sol

pragma solidity ^0.5.8;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call.value(amount)("");
        require(success);
    }
}

interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Managable {
    address payable public owner;
    mapping(address => uint) public admins;
    bool public locked = false;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
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

    modifier isNotLocked() {
        if (msg.sender != owner) {
            require(!locked);
        }
        _;
    }

    function setLock(bool _value) onlyAdmin public {
        locked = _value;
    }
}

contract Mine is Managable {
    using SafeMath for uint;
    using Address for address;
    
    ITRC20 public rewardToken;
    
    uint public round;
    uint public minedAmount;
    bool public mineFlag;
    
    uint public minePrice =  1000 * 1e6;
    uint public DURATION = 1;
   
    uint public PriceStageBase = 100;
    uint public PriceStageDelta = 80;
    
    uint public mineStage;
    uint public MineStageMax = 600000 * 1e18;
    uint public MineStageDelta = 60000 * 1e18;

    constructor() public {
        incMinedAmount(0);
    }
    
    function setRewardToken(address addr) public onlyOwner {
        require(address(0) != addr, "invalid address");
        require(addr.isContract(), "token address should be contract");
        rewardToken = ITRC20(addr);
    }
    
    function setMineFlag(bool flag) public onlyOwner {
        mineFlag = flag;
        if (mineFlag) {
            require(address(rewardToken) != address(0), "invalid rewardToken");
        }
    }
    
    function setMineBase(uint val) public onlyOwner {
        minePrice = val;
    }
    
    function setPriceStage(uint base, uint delta) public onlyOwner {
        require(base > 0 && delta > 0);
        PriceStageBase = base;
        PriceStageDelta = delta;
    }
    
    function setMineStage(uint max, uint delta) public onlyOwner {
        MineStageMax = max;
        MineStageDelta = delta;
    }
    
    function updateMinePrice() internal {
        if ( minedAmount >= MineStageMax) {
            mineFlag = false;
            minePrice = 0;
            return;
        }

        round = round.add(1);
        minePrice = minePrice.mul(PriceStageBase).div(PriceStageDelta);
    }
    
    function incMinedAmount(uint amount) internal {
        minedAmount = minedAmount.add(amount);
        if (minedAmount >= mineStage) {
            mineStage = mineStage.add(MineStageDelta);
            updateMinePrice();
        }
    }
    
    function sendRewardToken(address to, uint amount) internal {
        if (address(0) == address(rewardToken) || address(0) == to) {
            return;
        }

        if (mineFlag == false) {
            return;
        }
        
        uint maxReward = rewardToken.balanceOf(address(this));
        if (amount > maxReward) {
            amount = maxReward;
        }
        
        if (amount > 0) {
            rewardToken.transfer(to, amount);
        }
    }
    
    function calReward(uint amount, uint calTime) internal view returns (uint) {
        uint reward = amount.mul(1e18).div(minePrice).div(DURATION).mul(calTime);
        if (minedAmount.add(reward) >= mineStage) {
            reward = mineStage.sub(minedAmount); // cut reward to mine stage
        }
        return reward;
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
        uint term;
        bool isActive;
    }

    struct Investor {
        address payable addr;
        uint referrerEarnings;
        uint availableReferrerEarnings;
        uint planCount;
        mapping(uint => Investment) plans;
    }
}

interface IRelationInfo {
    function invite(address inviter, address invitee) external returns (bool);
    function inviter(address invitee) external view returns (address);
}

contract RelationUser is Managable {
    using Address for address;
    using SafeMath for uint;
    
    IRelationInfo public relationCtx;

    struct InviteRelation {
        uint [3] inviteeCnt;
        uint [3] inviteeAmount;
        uint [3] inviteReward;
    }

    mapping (address => InviteRelation) internal inviteInfo;
    
    function getInviteInfo(address addr) public view 
        returns (uint[3] memory inviteeCnt, uint[3] memory inviteeAmount, uint[3] memory inviteReward) {
        return (
            inviteInfo[addr].inviteeCnt,
            inviteInfo[addr].inviteeAmount,
            inviteInfo[addr].inviteReward
            );
    }

    function setRelationCtx(address addr) public onlyOwner {
        require(address(0) != addr, "invalid relation ctx address");
        require(addr.isContract() == true, "relation ctx should be a contract");
        relationCtx = IRelationInfo(addr);        
    }

    function getInviter(address invitee) internal view returns (address) {
        if (address(0) != address(relationCtx)) {
            return relationCtx.inviter(invitee);
        }
        return address(0);
    }
    
    function setRelation(address inviter, address invitee, uint amount, uint [3] memory reward) internal returns (bool) {
        if (address(0) != address(relationCtx)) {
            bool ret = relationCtx.invite(inviter, invitee);

            inviter = invitee;
            for (uint idx = 0; idx < 3; idx = idx.add(1)) {
                inviter = getInviter(inviter);
                
                if (address(0) == inviter) {
                    break;
                }
                
                if (ret) {
                    inviteInfo[inviter].inviteeCnt[idx] = inviteInfo[inviter].inviteeCnt[idx].add(1);
                }
                inviteInfo[inviter].inviteeAmount[idx] = inviteInfo[inviter].inviteeAmount[idx].add(amount);
                inviteInfo[inviter].inviteReward[idx] = inviteInfo[inviter].inviteReward[idx].add(reward[idx]);
            }
            return ret;
        }
        return false;
    }
}

contract Jupiter_ROI is Managable, Mine, RelationUser {
    using SafeMath for uint;
    
    uint constant DEVELOPER_RATE = 100;
    uint constant DIVIDE_BASE = 1000;

    uint constant MINIMUM = 10000000; //minimum investment needed, 10 trx
    uint constant MAX_PLAN_CNT = 200;

    uint startDate;
    uint latestReferrerCode;
    uint totalInvestments_;
    uint totalInvestCnt_;

    address payable developerAccount_;

    mapping(address => uint) address2UID;
    mapping(uint => Objects.Investor) uid2Investor;
    Objects.Plan[] public investmentPlans_;

    event onInvest(address indexed investor, uint amount);
    event onGrant(address indexed grantor, address beneficiary, uint amount);
    event onWithdraw(address indexed investor, uint amount);
    event onReinvest(address indexed investor, uint amount);

    constructor() public {
        developerAccount_ = msg.sender;
        startDate = block.timestamp;
        _init();
    }

    function _init() private {
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].planCount = 0;
        investmentPlans_.push(Objects.Plan(0, 37, 365000 days, true));
        investmentPlans_.push(Objects.Plan(1, 47, 45 days, true));
        investmentPlans_.push(Objects.Plan(2, 67, 25 days, true));
    }

    function() external payable {
        //do nothing;
    }

    function setDeveloperAccount(address payable _newDeveloperAccount) public onlyOwner {
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
    
    function getInvestorReferInfo(uint _uid) external view returns (uint, address, uint, uint, uint, uint, uint, uint) {
        if (msg.sender != owner && admins[msg.sender] != 1) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        
        address parentAddr = getInviter(investor.addr);
        uint parentID = address2UID[parentAddr];
        
        return 
        (
            parentID,
            parentAddr,
            inviteInfo[investor.addr].inviteeCnt[0],
            inviteInfo[investor.addr].inviteReward[0],
            inviteInfo[investor.addr].inviteeCnt[1],
            inviteInfo[investor.addr].inviteReward[1],
            inviteInfo[investor.addr].inviteeCnt[2],
            inviteInfo[investor.addr].inviteReward[2]
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
                uint calTime = block.timestamp;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    calTime = investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term);
                    if (block.timestamp < calTime) {
                        calTime = block.timestamp;
                    }
                }
                newDividends[i] = _calculateDividends(
                    investor.plans[i].investment, 
                    investor.plans[i].planId, 
                    investor.plans[i].investmentDate, 
                    calTime,
                    investor.plans[i].lastWithdrawalDate);
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

    function investStatistic() external view returns (uint, uint, uint, uint) {
        return (
            latestReferrerCode, // invetor count
            totalInvestments_,
            totalInvestCnt_,
            address(this).balance
        );
    }

    function _addInvestor(address payable _addr) private returns (uint) {
        require(address2UID[_addr] == 0, "address is existing");

        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[_addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = _addr;
        uid2Investor[latestReferrerCode].planCount = 0;
        return (latestReferrerCode);
    }

    function _invest(address payable _addr, uint _planId, address payable inviter, uint _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr);
        }
        
        uint planCount = uid2Investor[uid].planCount;
        require(planCount < MAX_PLAN_CNT,"too many invest");
        
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;
        
        investor.planCount = investor.planCount.add(1);

        totalInvestments_ = totalInvestments_.add(_amount);
        totalInvestCnt_ = totalInvestCnt_.add(1);

        uint developerReward = (_amount * DEVELOPER_RATE / DIVIDE_BASE);
        developerAccount_.transfer(developerReward);

        _divideReferReward(_addr, inviter, _amount, _amount.div(10));

        return true;
    }
    
    function _divideReferReward(address invitee, address inviter, uint amount, uint) internal {
        
        uint [3] memory reward;
        reward[0] = amount.mul(5).div(100);
        reward[1] = amount.mul(3).div(100);
        reward[2] = amount.mul(2).div(100);

        if (uid2Investor[address2UID[inviter]].planCount == 0) {
            inviter = invitee;
        }
        setRelation(inviter, invitee, amount, reward);
        
        inviter = invitee;
        for (uint idx = 0; idx < 3; idx = idx.add(1)) {
            inviter = getInviter(inviter);
            if (address(0) == inviter) {
                break;
            }
            if (uid2Investor[address2UID[inviter]].planCount > 0) {
                uid2Investor[address2UID[inviter]].availableReferrerEarnings = uid2Investor[address2UID[inviter]].availableReferrerEarnings.add(reward[idx]);
            }
        }
    }
    
    function invest(uint _planId, address payable inviter) public payable isNotLocked {
        require(_planId < investmentPlans_.length, "invalid invest plan ID");
        if (_invest(msg.sender, _planId, inviter, msg.value)) {
            emit onInvest(msg.sender, msg.value);
            mine(msg.value);
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

    function withdraw() public isNotLocked {
        uint withdrawalAmount = _withdraw();
        if (address(this).balance < withdrawalAmount) {
            withdrawalAmount = address(this).balance;
        }
        if (withdrawalAmount >= 0) {
            msg.sender.transfer(withdrawalAmount);
            emit onWithdraw(msg.sender, withdrawalAmount);
        }
    }

    function _calculateDividends(uint _amount, uint _planId, uint _begin, uint _now, uint _start) private view returns (uint) {
        require(_planId < investmentPlans_.length, "invalid invest plan ID");
        Objects.Plan storage plan = investmentPlans_[_planId];
        
        uint _end = _begin + plan.term;
        if (_start >= _end) {
            return 0;
        }
        
        uint div = 0;
        if (_now > _end) {
            _now = _end;
        }
        uint rewardPerSecond = _amount.mul(plan.dailyInterest).div(1 days).div(DIVIDE_BASE);
        div = _now.sub(_start).mul(rewardPerSecond);
        
        return div;
    }

    function rescue(address to, ITRC20 token, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(token.balanceOf(address(this)) >= amount, "insufficent token balance");
        
        token.transfer(to, amount);
    }

    function mine(uint investAmount) internal {
        if (mineFlag == false) {
            return;
        }

        uint amount = calReward(investAmount, 1);
        incMinedAmount(amount);
        sendRewardToken(msg.sender, amount);
    }
}