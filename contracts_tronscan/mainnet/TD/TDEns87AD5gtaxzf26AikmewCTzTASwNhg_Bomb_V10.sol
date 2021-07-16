//SourceUnit: bomb_v10.sol

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

contract Managable {
    address payable public owner;

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

contract Rescueable is Managable {
    function rescue(address to, ITRC20 token, uint amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(token.balanceOf(address(this)) >= amount);

        token.transfer(to, amount);
    }
}

library Objects {
    struct Investor {
        address payable addr;
        uint amount;
        uint lastWithdrawTime;
        uint withdrawableAmount;
        uint withdrawedAmount;
                
        InviteInfo inviteInfo;
    }
    
    struct InviteInfo {
        uint inviterID;
        uint[15] inviteeCnt;
        uint[15] inviteeAmount;
        uint[15] reward;
    }
    
    struct Ticket {
        uint uid;
        uint amount;
        uint result;
    }

}

contract Bomb_V10 is Managable, Rescueable {
    using SafeMath for uint;
    
    uint public DEVELOPER_RATE = 100;
    uint public DAILY_RATE = 36;
    uint public DIVIDE_BASE = 1000;
    
    uint public MinInvestAmount = 100 * 1e6;

    uint userCnt_;
    uint totalIn_;
    uint totalReward_;
    uint totalWithdraw_;
    uint totalPlay_;
    uint luckyCnt_;
    uint leaderReward_;
    uint fomoReward_;
    
    address payable public dev_;
    
    uint ProfitCycle = 1 days;

    mapping(address => uint) addr2uid_;
    mapping(uint => Objects.Investor) uid2investor_;
    
    mapping(uint => bool) leaderIDMap_;
    mapping(uint => uint) public leaderIdxMap_;
    uint public leaderCnt;
    uint public leaderTotalAmount;
    
    uint[100] public finalList_;
    uint finalIdx_;
    
    uint[15] public InviteRewardRate;
    
    uint public LeaderAmount = 500000 * 1e6;

    event Invest(address indexed investor, uint amount, uint ticketID);
    event Withdraw(address indexed investor, uint amount);
    event Lucky(address indexed user, uint amount, uint ticketID);
    event LeaderReward(address indexed leaderAddr, uint amount, uint total);
    event FomoReward(address indexed userAddr, uint amount);
    
    mapping(uint => Objects.Ticket) ticketMap_;
    uint ticketIdx_;
    uint ticketOpenIdx_;

    constructor() public {
        dev_ = msg.sender;
        newUser(msg.sender);
        InviteRewardRate[0] = 200;
        InviteRewardRate[1] = 100;
        InviteRewardRate[2] = 50;
        InviteRewardRate[3] = 10;
        InviteRewardRate[4] = 10;
        InviteRewardRate[5] = 10;
        InviteRewardRate[6] = 10;
        InviteRewardRate[7] = 10;
        InviteRewardRate[8] = 10;
        InviteRewardRate[9] = 10;
        InviteRewardRate[10] = 10;
        InviteRewardRate[11] = 10;
        InviteRewardRate[12] = 10;
        InviteRewardRate[13] = 10;
        InviteRewardRate[14] = 10;
    }

    function() external payable {
        //do nothing;
    }
    
    function setMinInvestAmount(uint val) public onlyOwner {
        MinInvestAmount = val;
    }

    function setLeaderAmount(uint amount) public onlyOwner returns (bool) {
        LeaderAmount = amount;
    }
    
    function setInviteRewardRate(uint idx, uint val) public onlyOwner {
        require(idx < InviteRewardRate.length);
        InviteRewardRate[idx] = val;
    }

    function setDev(address payable addr) public onlyOwner {
        require(addr != address(0));
        dev_ = addr;
    }
    
    function setProfitCycle(uint val) public onlyOwner {
        require(val > 0, "invalid val");
        ProfitCycle = val;
    }

    function getTotal() public view returns 
        (uint userCnt, uint totalIn, uint totalReward, uint totalWithdraw, uint totalPlay, 
         uint balance, uint withdrawableAmount, uint leaderPool, uint fomoPool) {
        
        uint leftReward = leaderReward_.add(fomoReward_);
        if (address(this).balance <= leftReward) {
            leftReward = 0;
        } else {
            leftReward = address(this).balance.sub(leftReward);
        }
        
        return (
            userCnt_,
            totalIn_,
            totalReward_,
            totalWithdraw_,
            totalPlay_,
            address(this).balance,
            leftReward,
            leaderReward_,
            fomoReward_
        );
    }
    
    function newUser(address payable addr) internal returns (uint) {
        uint uid = addr2uid_[addr];
        if (uid > 0) {
            return uid;
        }
        userCnt_ = userCnt_ + 1;
        uid = userCnt_;
        uid2investor_[uid].addr = addr;
        addr2uid_[addr] = uid;
        return uid;
    }

    function getUID(address addr) public view returns (uint) {
        return addr2uid_[addr];
    }
    
    function getAddrByUID(uint uid) public view returns (address addr) {
        require(uid > 0 && uid <= userCnt_, "invalid uid");
        return uid2investor_[uid].addr;
    }

    function getInviteInfo(address addr) public view returns (uint inviterID, uint [15] memory inviteeCnt, uint[15] memory inviteeAmount, uint[15] memory inviteeReward) {
        uint uid = addr2uid_[addr];
        require(uid>0, "invalid user");
        
        Objects.Investor storage investorInfo = uid2investor_[uid];
        
        return (
            investorInfo.inviteInfo.inviterID,
            investorInfo.inviteInfo.inviteeCnt,
            investorInfo.inviteInfo.inviteeAmount,
            investorInfo.inviteInfo.reward
        );
    }

    
    function getInvestorInfo(address addr) public view returns (uint userID, address userAddr, uint amount, uint withdrawableReward, uint withdrawedReward, bool isLeader) {
        uint uid = getUID(addr);
        require(uid > 0 && uid <= userCnt_, "invalid user");
        
        Objects.Investor storage investorInfo = uid2investor_[uid];
        
        return (
            uid,
            investorInfo.addr,
            investorInfo.amount,
            investorInfo.withdrawableAmount.add(calcProfit(investorInfo.amount, investorInfo.lastWithdrawTime)),
            investorInfo.withdrawedAmount,
            leaderIDMap_[uid]
        );
    }
    
    function calcProfit(uint amount, uint startTime) internal view returns (uint) {
        uint duration = block.timestamp.sub(startTime);
        if (duration == 0) {
            return 0;
        }
        return amount.mul(DAILY_RATE).mul(duration).div(ProfitCycle).div(DIVIDE_BASE);
    }
    
    function recordFinalUser(uint uid) internal {
        finalList_[finalIdx_] = uid;
        finalIdx_++;
        if (finalIdx_ == 100) {
            finalIdx_ = 0;
        }
    }
    
    function becomeLeader() public payable returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        require(leaderCnt < 50, "leader full");
        require(leaderIDMap_[uid] == false, "your are leader");
        require(uid2investor_[uid].inviteInfo.inviteeAmount[0] >= LeaderAmount, "insufficient amount");
        
        leaderIDMap_[uid] = true;
        leaderIdxMap_[leaderCnt] = uid;
        leaderCnt++;
        
        leaderTotalAmount = leaderTotalAmount.add(uid2investor_[uid].inviteInfo.inviteeAmount[0]);
    }
    
    function invest(uint _inviterID) public payable returns (bool) {
        require(msg.value >= MinInvestAmount, "invalid invest amount");
        uint uid = newUser(msg.sender);
        uint inviterID = _inviterID;
        require(uid > 0, "ivalid user");
        if (inviterID == uid || inviterID == 0) {
            inviterID = 1;
        }
        
        Objects.Investor storage investorInfo = uid2investor_[uid];

        investorInfo.withdrawableAmount = investorInfo.withdrawableAmount.add(calcProfit(investorInfo.amount, investorInfo.lastWithdrawTime));
        investorInfo.amount = investorInfo.amount.add(msg.value);
        investorInfo.lastWithdrawTime = block.timestamp;
        
        totalIn_ += msg.value;
        totalPlay_++;
        
        dev_.transfer(msg.value.mul(DEVELOPER_RATE).div(DIVIDE_BASE));
        
        leaderReward_ = leaderReward_.add(msg.value.mul(8).div(100));
        fomoReward_ = fomoReward_.add(msg.value.mul(2).div(100));
        
        recordFinalUser(uid);
        
        bool isNew = false;
        if (investorInfo.inviteInfo.inviterID == 0 && inviterID > 0) {
            investorInfo.inviteInfo.inviterID = inviterID;
            isNew = true;
        }
        
        if (leaderIDMap_[investorInfo.inviteInfo.inviterID]) {
            leaderTotalAmount = leaderTotalAmount.add(msg.value);
        }
        
        setInviteData(uid, investorInfo.inviteInfo.inviterID, msg.value, isNew);
        
        emit Invest(msg.sender, msg.value, ticketIdx_);
        
        ticketMap_[ticketIdx_].uid = uid;
        ticketMap_[ticketIdx_].amount = msg.value;
        ticketIdx_++;
        
        return true;
    }

    function ticketInfo() public view onlyOwner returns (uint maxIdx, uint curIdx) {
        return (
            ticketIdx_,
            ticketOpenIdx_
        );
    }
    
    function ticketID(uint id) public view onlyOwner returns (uint userID, uint amount, uint result) {
        return (ticketMap_[id].uid, ticketMap_[id].amount, ticketMap_[id].result);
    }
    
    function draw(uint idx, uint val) public onlyOwner returns (bool) {
        require(ticketIdx_ > idx, "invalid idx");
        
        Objects.Ticket storage ticket =  ticketMap_[idx];
        require(ticket.uid > 0, "invalid ticket");
        require(ticket.result == 0, "already open");
        
        ticket.result = val;
        
        if (ticket.result > 92) {
            luckyGuy(ticket.uid, ticket.amount, idx);
        }
        ticketOpenIdx_++;
        
        return true;
    }
    
    uint leaderRewardVal_ = 0;
    uint leaderRewardStart_ = 0;
    uint leaderRewardIdx_;
    bool leaderRewardOngoing_ = false;
    function sendLeaderReward(uint endIdx) public onlyOwner {
        if (leaderRewardOngoing_ == false) {
            require(block.timestamp.sub(leaderRewardStart_) >= 1 days, "invalid leader reward time");
        }
        if (endIdx > leaderCnt || endIdx == 0 || endIdx <= leaderRewardIdx_) {
            endIdx = leaderCnt;
        }
        
        if (leaderRewardOngoing_ == false) {
            leaderRewardStart_ = block.timestamp;
            leaderRewardOngoing_ = true;
            leaderRewardVal_ = leaderReward_.mul(15).div(100);
            leaderRewardIdx_ = 0;
        }

        uint uid = 0;
        uint reward = 0;
        for(uint idx = leaderRewardIdx_; idx < endIdx; idx++) {
            uid = leaderIdxMap_[idx];
            if (uid > 0) {
                reward = leaderRewardVal_.mul(uid2investor_[uid].inviteInfo.inviteeAmount[0]).div(leaderTotalAmount);
                uid2investor_[uid].addr.transfer(reward);
                emit LeaderReward(uid2investor_[uid].addr, reward, leaderRewardVal_);
            }
        }
        leaderRewardIdx_ = endIdx;
        
        if (leaderRewardIdx_ == leaderCnt && leaderRewardOngoing_) {
            leaderRewardOngoing_ = false;
            leaderReward_ = leaderReward_.sub(leaderRewardVal_);
        }
    }
    
    function payLeaderReward(uint idx, uint amount) public onlyOwner returns (bool) {
        require(idx < leaderCnt, "invalid leader idx");
        require(amount <= leaderReward_, "invalid amount");
        
        uid2investor_[leaderIdxMap_[idx]].addr.transfer(amount);
        leaderReward_ = leaderReward_.sub(amount);
        
        return true;
    }
    
    uint fomoRewardVal_ = 0;
    uint fomoStart_ = 0;
    uint fomoStartTime_ = 0;
    bool fomoOngoing_ = false;
    uint fomoRewardIdx_;
    function sendFomoReward(uint endIdx) public onlyOwner {
        if (fomoOngoing_ == false) {
            require(block.timestamp.sub(fomoStartTime_) >= 1 days, "invalid fomo reward time");
        }
        if (endIdx > finalList_.length || endIdx == 0 || endIdx <= fomoRewardIdx_) {
            endIdx = finalList_.length;
        }
        
        if (leaderRewardOngoing_ == false) {
            fomoStartTime_ = block.timestamp;
            fomoOngoing_ = true;
            fomoRewardVal_ = fomoReward_;
            fomoRewardIdx_ = 0;
        }
        
        uint uid = 0;
        uint reward = fomoRewardVal_.div(finalList_.length);
        for(uint idx = fomoRewardIdx_; idx < endIdx; idx++) {
            uid = finalList_[idx];
            if (uid > 0) {
                uid2investor_[uid].addr.transfer(reward);
                emit FomoReward(uid2investor_[uid].addr, reward);
            }
        }
        fomoRewardIdx_ = endIdx;
        
        if (fomoRewardIdx_ == finalList_.length && fomoOngoing_) {
            fomoOngoing_ = false;
            fomoReward_ = fomoReward_.sub(fomoRewardVal_);
        }
    }
    
    function setInviteData(uint inviteeID, uint inviterID, uint amount, bool isNew) internal returns (bool) {

        for(uint idx = 0; idx < InviteRewardRate.length && inviterID > 0 && inviterID != inviteeID; idx++) {
            uid2investor_[inviterID].inviteInfo.inviteeAmount[idx] = uid2investor_[inviterID].inviteInfo.inviteeAmount[idx].add(amount);
            if (isNew) {
                uid2investor_[inviterID].inviteInfo.inviteeCnt[idx] = uid2investor_[inviterID].inviteInfo.inviteeCnt[idx].add(1);
            }
            inviterID = uid2investor_[inviterID].inviteInfo.inviterID;
        }
        return true;
    }
    
    function setInviteRewardData(uint inviteeID, uint inviterID, uint amount) internal returns (bool) {
        for(uint idx = 0; idx < InviteRewardRate.length && inviterID > 0 && inviterID != inviteeID; idx++) {
            uint reward = amount.mul(InviteRewardRate[idx]).div(DIVIDE_BASE);
            totalReward_ = totalReward_.add(reward);
            uid2investor_[inviterID].inviteInfo.reward[idx] = uid2investor_[inviterID].inviteInfo.reward[idx].add(reward);
            uid2investor_[inviterID].withdrawableAmount = uid2investor_[inviterID].withdrawableAmount.add(reward);
            
            inviterID = uid2investor_[inviterID].inviteInfo.inviterID;
        }
        return true;
    }
    
    function luckyGuy(uint uid, uint amount, uint idx) internal {
        luckyCnt_++;
        
        //uid2investor_[uid].withdrawableAmount = uid2investor_[uid].withdrawableAmount.add(amount);
        uid2investor_[uid].addr.transfer(amount);
        emit Lucky(uid2investor_[uid].addr, amount, idx);
    }
    
    function getReward() public payable returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        
        Objects.Investor storage investorInfo = uid2investor_[uid];
        require(investorInfo.withdrawedAmount < investorInfo.amount.mul(2), "user out");
        
        investorInfo.withdrawableAmount = investorInfo.withdrawableAmount.add(calcProfit(investorInfo.amount, investorInfo.lastWithdrawTime));
        investorInfo.lastWithdrawTime = block.timestamp;

        uint maxAmount = investorInfo.amount.mul(2);
        
        uint amount = investorInfo.withdrawableAmount;
        if (amount.add(investorInfo.withdrawedAmount) > maxAmount) {
            amount = maxAmount.sub(investorInfo.withdrawedAmount);
        }
        
        uint leftReward = leaderReward_.add(fomoReward_);
        
        if (address(this).balance > leftReward) {
            if (amount > address(this).balance.sub(leftReward)) {
                amount = address(this).balance.sub(leftReward);
            }
        } else {
            amount = 0;
        }
        
        if (amount > 0) {
            investorInfo.withdrawedAmount = investorInfo.withdrawedAmount.add(amount);
            investorInfo.withdrawableAmount = investorInfo.withdrawableAmount.sub(amount);
            msg.sender.transfer(amount);
                        
            totalWithdraw_ = totalWithdraw_.add(amount);
            
            emit Withdraw(msg.sender, amount);
            
            setInviteRewardData(uid, investorInfo.inviteInfo.inviterID, amount);
        }
        
        return true;
    }
}