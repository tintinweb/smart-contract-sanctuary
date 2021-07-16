//SourceUnit: threeM_v6.sol

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
    
    function min(uint a, uint b) internal pure returns (uint) {
        if (a > b) {
            return b;
        }
        return a;
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

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }
}

contract Rescueable is Managable {
    
    function rescue(address payable to, uint amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(address(this).balance >= amount);

        to.transfer(amount);
    }
}

library Objects {
        
    enum InvestStatus {
        Unused,
        WaitPay,
        WaitFullPay,
        WaitUnlock,
        WaitWithdraw,
        Finished,
        Cancelled
    }
    
    struct Investment {
        uint amount;
        uint createTime;
        uint fullPayTime;
        uint unlockTime;
        
        InvestStatus status;
        
        uint unlockOrderID;
        uint unlockRewardAmount;
        
        bool rescue;
        uint rescueTime;
    }
    
    struct InviteInfo {
        address payable inviter;
        uint inviteeCnt;
        uint inviteeAmount;

        uint unlockReward;
        uint lockReward;
        uint withdrawedReward;
        
        uint registerInviteeCnt;
    }

    struct User {
        address payable addr;
        Investment[] orderList;
        uint lastInvestTime;
        uint fullPayOrderCnt;
        uint unlockOrderCnt;
        uint maxInvestAmount;
        uint unlockDays;
        uint minInvestVal;
        uint maxInvestVal;
        
        InviteInfo inviteInfo;
    }
}

contract M3_V6 is Rescueable {
    using SafeMath for uint;
    
    mapping(address => uint) address2ID_;
    mapping(uint => Objects.User) uid2User_;
    
    uint userCnt_;
    uint totalIn_;
    uint totalOut_;
    uint dayIn_;
    uint dayOut_;
    uint totalInvestCnt_;
    uint totalFee_;
    
    ITRC20 usdtToken = ITRC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);
    
    uint uidBase_ = 2020;
    
    address payable[4] dev_;
    
    uint public dayStart;
    
    uint public RegisterFee = 10 * 1e6;
    uint public MinInvestVal = 50 * 1e6;
    uint public MaxInitInvestVal = 1000 * 1e6;
    uint public MaxInvestVal = 10000 * 1e6;
    
    uint public NewUserOrderLimit = 3;
    
    uint public timeUnit = 1 days;

    uint public PrepayDuration = 1 * timeUnit;
    uint public FullPayDelay = 5 * timeUnit;
    uint public FullPayDuration = 3 * timeUnit;
    uint public UnlockDelay = 14 * timeUnit;

    uint public WithdrawDelay = 1 * timeUnit;
    uint public UnlockDayIncVal = 1 * timeUnit;
    uint public MaxUnlockDelay = 40 * timeUnit;
    uint public RescuePayDuration = 8 hours;
    
    uint public OrderInterval = 1 * timeUnit;
    
    uint public ProfitRate = 115;
    uint public FeeRate = 2;
    uint public PrepayRate = 50;
    uint public FullPayRate = 50;
    
    uint[] InviteRewardRate;
    uint[] InviteRewardInviteeRequire;
    uint InviteRewardRateBase = 1000;
    
    bool payLock;
    bool withdrawLock;
    
    event NewOrder(address addr, uint amount);
    event PayOrder(address addr, uint amount, uint payType);
    event Withdraw(address addr, uint amount);
    
    modifier isPayable {
        if (msg.sender != owner) {
            require(!payLock, "pay locked!");
        }
        _;
    }
    
    modifier isWithdrawable {
        if (msg.sender != owner) {
            require(!withdrawLock, "withdraw locked!");
        }
        _;
    }
    
    modifier updateDayStart() {
        if (block.timestamp > dayStart + 1 days) {
            dayIn_ = 0;
            dayOut_ = 0;
            dayStart = dayStart + 1 days;
        }
        _;
    }
    
    function setDayStart(uint val) public onlyOwner {
        dayStart = val;
    }
    
    function setFullPayDelay(uint delay, uint oneTime) public onlyOwner {
        FullPayDelay = delay;
        if (oneTime >= 60) {
            timeUnit = oneTime;

            PrepayDuration = 1 * timeUnit;
            FullPayDelay = 5 * timeUnit;
            FullPayDuration = 3 * timeUnit;
            UnlockDelay = 14 * timeUnit;

            WithdrawDelay = 1 * timeUnit;
            UnlockDayIncVal = 1 * timeUnit;
            MaxUnlockDelay = 40 * timeUnit;

            OrderInterval = 1 * timeUnit;
        }
    }
    
    function setWithdrawDelay(uint delay) public onlyOwner {
        WithdrawDelay = delay;
    }
    
    function setPayLock(bool val) public onlyOwner {
        payLock = val;
    }
    
    function setWithdrawLock(bool val) public onlyOwner {
        withdrawLock = val;
    }
    
    function setDev(uint idx, address payable addr) public onlyOwner {
        require(address(0) != addr, "invalid address");
        dev_[idx] = addr;
    }
    
    function setToken(address token) public onlyOwner {
        usdtToken = ITRC20(token);
    }

    constructor() public {
        dev_[0] = msg.sender;
        dev_[1] = msg.sender;
        dev_[2] = msg.sender;
        dev_[3] = msg.sender;
        
        InviteRewardRate.push(50); // 1
        InviteRewardRate.push(20); // 2
        InviteRewardRate.push(30); // 3
        InviteRewardRate.push(30); // 4
        InviteRewardRate.push(20); // 5
        InviteRewardRate.push(10);  // 6
        InviteRewardRate.push(8);  // 7
        InviteRewardRate.push(6);  // 8
        InviteRewardRate.push(4);  // 9
        InviteRewardRate.push(2);  // 10
        InviteRewardRate.push(1);  // 11
        
        InviteRewardInviteeRequire.push(0); // 1
        InviteRewardInviteeRequire.push(10); // 2
        InviteRewardInviteeRequire.push(10); // 3
        InviteRewardInviteeRequire.push(20); // 4
        InviteRewardInviteeRequire.push(20);  // 5
        InviteRewardInviteeRequire.push(20);  // 6
        InviteRewardInviteeRequire.push(20);  // 7
        InviteRewardInviteeRequire.push(20);  // 8
        InviteRewardInviteeRequire.push(20);  // 9
        InviteRewardInviteeRequire.push(20);  // 10
        InviteRewardInviteeRequire.push(20);  // 11
        
        createUser(msg.sender, 0);

        dayStart = block.timestamp;
    }

    function getUserID(address addr) public view returns (uint) {
        uint uid = getUID(addr);
        if (uid > 0) {
            return uid.add(uidBase_);
        }
    }
    
    function getUserInfo(address addr) public view returns (
        uint userID, address userAddr, uint orderCnt, uint maxInvestAmount, uint lastInvestTime, 
        uint fullPayOrderCnt, uint unlockOrderCnt, uint unlockDays, uint minInvestVal, uint maxInvestVal) {
        uint uid = getUID(addr);
        require(uid > 0, "invalid user");
        
        Objects.User storage user = uid2User_[uid];
        
        return (
            uid.add(uidBase_),
            user.addr,
            user.orderList.length,
            user.maxInvestAmount,
            user.lastInvestTime,
            user.fullPayOrderCnt,
            user.unlockOrderCnt,
            user.unlockDays,
            user.minInvestVal,
            user.maxInvestVal
        );
    }
    
    function getUserInviteInfo(address addr) public view returns (
        uint userID, address userAddr, address inviter, 
        uint registerInviteeCnt, uint inviteeCnt, uint inviteeAmount,
        uint lockReward, uint unlockReward, uint withdrawedReward) {
        uint uid = getUID(addr);
        require(uid > 0, "invalid user");
        
        Objects.User storage user = uid2User_[uid];
        
        return (
            uid.add(uidBase_),
            user.addr,
            user.inviteInfo.inviter,
            user.inviteInfo.registerInviteeCnt,
            user.inviteInfo.inviteeCnt,
            user.inviteInfo.inviteeAmount,
            user.inviteInfo.lockReward,
            user.inviteInfo.unlockReward,
            user.inviteInfo.withdrawedReward
        );  
    }
    
    function getUserOrderByID(address addr, uint orderID) public view returns (uint, uint, uint, Objects.InvestStatus, uint, uint, uint, uint, bool, uint) {
        uint uid = getUID(addr);
        require(uid > 0, "invalid user");
        require(uid2User_[uid].orderList.length >= orderID && orderID > 0, "invalid orderID");
        
        Objects.Investment storage investInfo = uid2User_[uid].orderList[orderID-1];
        
        return (
            orderID,
            investInfo.createTime,
            investInfo.amount,
            investInfo.status,
            investInfo.fullPayTime,
            investInfo.unlockTime,
            investInfo.unlockOrderID,
            investInfo.unlockRewardAmount,
            investInfo.rescue,
            investInfo.rescueTime
        );
    }
    
    function balance() public view returns (uint, uint) {
        return (
            usdtToken.balanceOf(address(this)),
            address(this).balance
        );
    }
    
    function getUserOrders(address addr, uint startID, uint cnt) public view 
        returns (uint[] memory idLists, uint[] memory createTimeList, uint[] memory amountList, 
                 Objects.InvestStatus[] memory statusList, uint [] memory fullPayTimeList, uint[] memory unlockTimeList) {
        require(cnt <= 100, "max cnt is 100");
        if (startID == 0) {
            startID = 1;
        }
        if (cnt == 0) {
            cnt = 100;
        }
        Objects.User storage user = uid2User_[getUID(addr)];
        require(user.addr != address(0), "invalid user");
        require(user.orderList.length >= startID, "invalid startID");
        startID = startID - 1;
        
        if (startID + cnt > user.orderList.length) {
            cnt = user.orderList.length - startID;
        }
        
        idLists         = new uint[](cnt);
        createTimeList  = new uint[](cnt);
        amountList      = new uint[](cnt);
        statusList      = new Objects.InvestStatus[](cnt);
        unlockTimeList  = new uint[](cnt);
        fullPayTimeList  = new uint[](cnt);
        
        for (uint id = 0; id < cnt; id++) {
            idLists[id]         = startID + 1 + id;
            createTimeList[id]  = user.orderList[id.add(startID)].createTime;
            amountList[id]      = user.orderList[id.add(startID)].amount;
            statusList[id]      = user.orderList[id.add(startID)].status;
            unlockTimeList[id]  = user.orderList[id.add(startID)].unlockTime;
            fullPayTimeList[id]  = user.orderList[id.add(startID)].fullPayTime;
        }
        return (
            idLists,
            createTimeList,
            amountList,
            statusList,
            fullPayTimeList,
            unlockTimeList
        );
    }
    
    function getUserOrdersB(address addr, uint startID, uint cnt) public view 
        returns (uint[] memory idList, uint[] memory unlockOrderIDList, uint[] memory unlockRewardList, 
                 bool[] memory rescueList, uint[] memory rescueTimeList) {
        require(cnt <= 100, "max cnt is 100");
        if (startID == 0) {
            startID = 1;
        }
        if (cnt == 0) {
            cnt = 100;
        }
        Objects.User storage user = uid2User_[getUID(addr)];
        require(user.addr != address(0), "invalid user");
        require(user.orderList.length >= startID, "invalid startID");
        startID = startID - 1;
        
        if (startID + cnt > user.orderList.length) {
            cnt = user.orderList.length - startID;
        }
        
        idList              = new uint[](cnt);
        unlockOrderIDList   = new uint[](cnt);
        unlockRewardList    = new uint[](cnt);
        rescueList          = new bool[](cnt);
        rescueTimeList      = new uint[](cnt);
        
        for (uint id = 0; id < cnt; id++) {
            idList[id]              = startID + 1 + id;
            unlockOrderIDList[id]   = user.orderList[id.add(startID)].unlockOrderID;
            unlockRewardList[id]    = user.orderList[id.add(startID)].unlockRewardAmount;
            rescueList[id]          = user.orderList[id.add(startID)].rescue;
            rescueTimeList[id]      = user.orderList[id.add(startID)].rescueTime;
        }
        
        return (
            idList,
            unlockOrderIDList,
            unlockRewardList,
            rescueList,
            rescueTimeList
        );
    }
    
    function total() public view returns (uint userCnt, uint totalIn, uint dayIn, uint dayOut, uint totalOut, uint totalInvestCnt, uint totalFee) {
        return (
            userCnt_,
            totalIn_,
            dayIn_,
            dayOut_,
            totalOut_,
            totalInvestCnt_,
            totalFee_
        );
    }
    
    function getUID(address addr) internal view returns (uint) {
        uint uid = address2ID_[addr];
        return uid;
    }
    
    function createUser(address payable addr, uint inviterID) internal returns (uint) {
        uint uid = getUID(addr);
        if (uid > 0) {
            return uid;
        }
        userCnt_ = userCnt_.add(1);
        uid = userCnt_;
        address2ID_[addr] = uid;
        Objects.User storage user = uid2User_[uid];
        user.addr = addr;
        user.minInvestVal = MinInvestVal;
        user.maxInvestVal = MaxInitInvestVal;
        user.unlockDays = UnlockDelay;
        
        user.inviteInfo.inviter = uid2User_[inviterID].addr;
        uid2User_[inviterID].inviteInfo.registerInviteeCnt = uid2User_[inviterID].inviteInfo.registerInviteeCnt.add(1);
        
        return uid;
    }

    function setInviteReward(address inviteeAddr, uint amount) internal returns (bool) {
        if (address(0) == inviteeAddr) {
            return false;
        }
        Objects.User storage inviterUser = uid2User_[getUID(inviteeAddr)];
        inviterUser.inviteInfo.inviteeAmount = inviterUser.inviteInfo.inviteeAmount.add(amount);
        
        uint reward;
        for (uint idx = 0; idx < InviteRewardRate.length; idx++) {
            inviterUser = uid2User_[getUID(inviteeAddr)];
            
            reward = amount.min(inviterUser.maxInvestAmount).mul(InviteRewardRate[idx]).div(InviteRewardRateBase);
            if (reward > 0 && inviterUser.inviteInfo.inviteeCnt >= InviteRewardInviteeRequire[idx]) {
                if (idx < 3) {
                    inviterUser.inviteInfo.unlockReward = inviterUser.inviteInfo.unlockReward.add(reward);
                } else {
                    inviterUser.inviteInfo.lockReward = inviterUser.inviteInfo.lockReward.add(reward);
                }
            }
            inviteeAddr = inviterUser.inviteInfo.inviter;
            if (address(0) == inviteeAddr) {
                break;
            }
        }
    }
    
    function register(uint _inviterID) public payable returns (uint) {
        require(_inviterID > uidBase_, "invalid inviter ID");
        uint inviterID = _inviterID.sub(uidBase_);
        Objects.User storage inviter = uid2User_[inviterID];
        require(inviter.addr != address(0), "invalid inviter ID");
        
        uint uid = getUID(msg.sender);
        require(uid == 0, "already registered");
        usdtToken.transferFrom(msg.sender, dev_[0], RegisterFee);
        
        uid = createUser(msg.sender, inviterID);
        
        return uid;
    }
    
    function withdraw(uint orderID) public payable isWithdrawable updateDayStart returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid uid");
        
        Objects.User storage user = uid2User_[uid];
        require(orderID > 0 && user.orderList.length >= orderID, "invalid orderID");

        Objects.Investment storage investInfo = user.orderList[orderID-1];
        require(investInfo.status == Objects.InvestStatus.WaitWithdraw, "invalid order status, require WaitWithdraw");
        require(block.timestamp >= investInfo.unlockTime.add(WithdrawDelay), "invalid withdraw time");

        uint outAmount = investInfo.amount.mul(ProfitRate).div(100);
        usdtToken.transfer(user.addr, outAmount);
        totalOut_ = totalOut_.add(outAmount);
        dayOut_ = dayOut_.add(outAmount);
        
        investInfo.status = Objects.InvestStatus.Finished;
        
        emit Withdraw(msg.sender, outAmount);
        
        return true;         
    }
    
    function rescueOrder(uint orderID) public payable returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid uid");
        
        Objects.User storage user = uid2User_[uid];
        require(orderID > 0 && user.orderList.length >= orderID, "invalid orderID");
        
        Objects.Investment storage investInfo = user.orderList[orderID-1];
        require(investInfo.status == Objects.InvestStatus.WaitFullPay, "invalid order status, require WaitFullPay");
        require(investInfo.rescue == false, "order status should be resuable");
        require(block.timestamp > investInfo.fullPayTime.add(FullPayDuration), "rescueOrder should after full pay end time!");
        require(block.timestamp <= investInfo.unlockTime, "rescueOrder should before unlock time!");
        
        investInfo.rescue = true;
        investInfo.rescueTime = block.timestamp;
        investInfo.unlockTime = investInfo.unlockTime.add(block.timestamp.sub(investInfo.fullPayTime.add(FullPayDuration)));
        
        return true;
    }
    
    function payOrder(uint orderID, uint payType) public payable isPayable updateDayStart returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "register first");
        require(payType == 1 || payType == 2, "invalid payType"); // 1: prepay, 2: full pay
        
        Objects.User storage user = uid2User_[uid];
        require(orderID > 0 && user.orderList.length >= orderID, "invalid orderID");
        Objects.Investment storage investInfo = user.orderList[orderID-1];
        uint payRate;
        Objects.InvestStatus nextStatus;
        if (payType == 2) {
            payRate = FullPayRate;
            require(investInfo.status == Objects.InvestStatus.WaitFullPay, "invalid order status, need WaitFullPay");
            if (investInfo.rescue == false) {
                require(block.timestamp >= investInfo.fullPayTime && block.timestamp <= investInfo.fullPayTime.add(FullPayDuration), "invalid full pay time");
            } else {
                require(block.timestamp >= investInfo.rescueTime && block.timestamp <= investInfo.rescueTime.add(RescuePayDuration), "invalid rescue pay time");
            }
            nextStatus = Objects.InvestStatus.WaitUnlock;
            
            if (orderID == 1) { // first order reward
                uint firstOrderReward = investInfo.amount.mul(5).div(100);
                user.inviteInfo.unlockReward = user.inviteInfo.unlockReward.add(firstOrderReward);
            }
            if (investInfo.amount > user.maxInvestAmount) {
                user.maxInvestAmount = investInfo.amount;
            }
            user.fullPayOrderCnt = user.fullPayOrderCnt + 1;
            investInfo.fullPayTime = block.timestamp;
        } else {
            payRate = PrepayRate;
            require(investInfo.status == Objects.InvestStatus.WaitPay, "invalid order status, need WaitPay");
            require(block.timestamp <= investInfo.createTime.add(PrepayDuration), "invalid prepay time");
            
            if (orderID == 1) {
                if (address(0) != user.inviteInfo.inviter) {
                    uid2User_[getUID(user.inviteInfo.inviter)].inviteInfo.inviteeCnt = uid2User_[getUID(user.inviteInfo.inviter)].inviteInfo.inviteeCnt + 1;
                }
            }
            
            nextStatus = Objects.InvestStatus.WaitFullPay;
            unlockOrder(uid, investInfo.unlockOrderID, investInfo.amount, true);
            unlockReward(uid, investInfo.unlockRewardAmount, investInfo.amount, true);
        }
        
        usdtToken.transferFrom(msg.sender, address(this), investInfo.amount.mul(payRate).div(100));
        totalIn_ = totalIn_.add(investInfo.amount.mul(payRate).div(100));
        dayIn_ = dayIn_.add(investInfo.amount.mul(payRate).div(100));
        investInfo.status = nextStatus;

        emit PayOrder(msg.sender, investInfo.amount.mul(payRate).div(100), payType);
        
        return true;
    }
    
    function newOrder(uint fee, uint amount, uint payType, uint unlockOrderID, uint unlockRewardAmount) public payable isPayable updateDayStart returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "register first");
        require(payType == 0 || payType == 1, "invalid payType");
        
        Objects.User storage user = uid2User_[uid];
        
        require(block.timestamp >= user.lastInvestTime.add(OrderInterval), "invalid invest time");
        require(amount >= user.minInvestVal && amount <= user.maxInvestVal, "invalid invest amount");
        require(fee == amount.mul(FeeRate).div(100), "invalid invest fee");
        
        if (user.fullPayOrderCnt == 0) {
            require(user.orderList.length < NewUserOrderLimit, "new user create order limit");
        }
        
        totalInvestCnt_ = totalInvestCnt_.add(1);
        usdtToken.transferFrom(msg.sender, dev_[2], fee.div(8));
        usdtToken.transferFrom(msg.sender, dev_[3], fee.div(8));
        usdtToken.transferFrom(msg.sender, dev_[1], fee.sub(fee.div(4)));
        totalFee_ = totalFee_.add(fee);
        
        emit NewOrder(msg.sender, amount);
        
        unlockOrderID = unlockOrder(uid, unlockOrderID, amount, payType == 1);
        unlockRewardAmount = unlockReward(uid, unlockRewardAmount, amount, payType == 1);
        user.orderList.push(Objects.Investment(amount, block.timestamp, 0, 0, Objects.InvestStatus.Unused, unlockOrderID, unlockRewardAmount, false, 0));
        
        Objects.Investment storage investInfo = user.orderList[user.orderList.length - 1];
        investInfo.fullPayTime = block.timestamp.add(FullPayDelay);
        investInfo.unlockTime = investInfo.createTime.add(user.unlockDays);
        investInfo.unlockOrderID = unlockOrderID;
        investInfo.unlockRewardAmount = unlockRewardAmount;
        
        if (payType == 1) {
            usdtToken.transferFrom(msg.sender, address(this), amount.mul(PrepayRate).div(100));
            totalIn_ = totalIn_.add(amount.mul(PrepayRate).div(100));
            dayIn_ = dayIn_.add(amount.mul(PrepayRate).div(100));
            investInfo.status = Objects.InvestStatus.WaitFullPay;
            emit PayOrder(msg.sender, amount.mul(PrepayRate).div(100), 1);
            if (user.orderList.length == 1) {
                if (address(0) != user.inviteInfo.inviter) {
                    uid2User_[getUID(user.inviteInfo.inviter)].inviteInfo.inviteeCnt = uid2User_[getUID(user.inviteInfo.inviter)].inviteInfo.inviteeCnt + 1;
                }
            }
        } else {
            investInfo.status = Objects.InvestStatus.WaitPay;
        }

        user.lastInvestTime = block.timestamp;
        if (user.unlockDays < MaxUnlockDelay) {
            user.unlockDays = UnlockDelay.add(user.orderList.length.add(1).div(2).mul(UnlockDayIncVal));
        }
        
        if (user.minInvestVal < investInfo.amount) {
            user.minInvestVal = investInfo.amount;
        }
        
        return true;
    }
    
    function unlockOrder(uint uid, uint orderID, uint amount, bool unlock) internal returns (uint) {
        if (orderID == 0 || orderID > uid2User_[uid].orderList.length) {
            return 0;
        }
        Objects.Investment storage investInfo = uid2User_[uid].orderList[orderID-1];
        
        if (investInfo.status == Objects.InvestStatus.WaitUnlock && block.timestamp >= investInfo.unlockTime && amount >= investInfo.amount) {
            if (unlock) {
                investInfo.status = Objects.InvestStatus.WaitWithdraw;
                uid2User_[uid].unlockOrderCnt = uid2User_[uid].unlockOrderCnt.add(1);
                
                setInviteReward(uid2User_[uid].inviteInfo.inviter, investInfo.amount); // multi-level invite reward
                investInfo.unlockTime = block.timestamp;
                
                if (uid2User_[uid].maxInvestVal < MaxInvestVal) { // change max invest amount
                    uid2User_[uid].maxInvestVal = uid2User_[uid].maxInvestVal.mul(2);
                    if (uid2User_[uid].maxInvestVal > MaxInvestVal) {
                        uid2User_[uid].maxInvestVal = MaxInvestVal;
                    }
                }
            }
            return orderID;
        }
        
        return 0;
    }
    
    function unlockReward(uint uid, uint rewardAmount, uint amount, bool unlock) internal returns (uint) {
        Objects.User storage user = uid2User_[uid];
        if (rewardAmount > amount) {
            rewardAmount = amount;
        }
        
        if (rewardAmount > user.inviteInfo.lockReward) {
            rewardAmount = user.inviteInfo.lockReward;
        }
        if (unlock) {
            user.inviteInfo.unlockReward = user.inviteInfo.unlockReward.add(rewardAmount);
            user.inviteInfo.lockReward = user.inviteInfo.lockReward.sub(rewardAmount);
        }
        return rewardAmount;
    }
    
    function getReward(uint amount) public isWithdrawable returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        
        Objects.User storage user = uid2User_[uid];
        
        if (amount > user.inviteInfo.unlockReward) {
            amount = user.inviteInfo.unlockReward;
        }
        user.inviteInfo.unlockReward = user.inviteInfo.unlockReward.sub(amount);
        user.inviteInfo.withdrawedReward = user.inviteInfo.withdrawedReward.add(amount);
        totalOut_ = totalOut_.add(amount);
        dayOut_ = dayOut_.add(amount);
        usdtToken.transfer(msg.sender, amount);
        
        return true;
    }
}