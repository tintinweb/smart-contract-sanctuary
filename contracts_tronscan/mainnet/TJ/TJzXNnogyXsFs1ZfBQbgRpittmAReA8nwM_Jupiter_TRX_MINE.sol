//SourceUnit: A002_trx_stake_mine_v2.sol

pragma solidity ^0.5.8;

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
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "invalid sub(a, b) as a < b");
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "invalid add as a+b < a");
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
    uint public DURATION = 1 days;
   
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

interface IDICEInfo {
    function playerInfo(address player) external view returns (uint count, uint amount);
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

contract Jupiter_TRX_MINE is Mine, RelationUser {
    using SafeMath for uint;
    using Address for address;
    
    uint public totalSupply;
    
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint transferAmount, uint fee, uint rate);
    event RewardPaid(address indexed user, uint reward);
    
    struct StakeInfo {
        uint lastWithdrawTime;
        uint withdrawableReward;
        uint withdrawedReward;
        uint amount;
    }
    
    mapping (address => StakeInfo) public records;
    
    constructor() public {
        devAddr = msg.sender;
    }
    
    address payable public devAddr;
    
    function setDevAccount (address payable addr) public onlyOwner {
        require(address(0) != addr, "invalid addr");
        devAddr = addr;
    }
    
    function balance() public view returns (uint) {
        return address(this).balance;
    }
    
    IDICEInfo public diceCtx;
    uint minDiceCount = 3;
    function setMinDiceCount(uint val) public onlyOwner {
        minDiceCount = val;
    }
    
    function setDiceCtx(address addr) public onlyOwner {
        require(address(0) != addr, "invalid reward token address");
        require(addr.isContract() == true, "reward token should be a contract");
        diceCtx = IDICEInfo(addr);
    }

    uint minStakeAmount = 1000000;
    
    function setMinStakeAmount (uint val) public onlyOwner returns (bool) {
        minStakeAmount = val;
    }
    
    function stake(address inviter) public payable returns (bool) {
        require(msg.value > minStakeAmount, "invalid stake amount");
        uint amount = msg.value;
        
        if (minDiceCount > 0 && address(0) != address(diceCtx)) {
            (uint diceCnt, ) = diceCtx.playerInfo(msg.sender);
            require(diceCnt >= minDiceCount, "play dice first");
        }
        
        StakeInfo storage info = records[msg.sender];
        if (info.lastWithdrawTime > 0 && block.timestamp > info.lastWithdrawTime) {
            uint calTime = block.timestamp.sub(info.lastWithdrawTime);
            uint reward = calReward(info.amount, calTime);
            info.withdrawableReward = info.withdrawableReward.add(reward);
            incMinedAmount(reward);
        }
        
        info.lastWithdrawTime = block.timestamp;
        info.amount = info.amount.add(amount);
        totalSupply = totalSupply.add(amount);
        
        if (records[inviter].lastWithdrawTime > 0) {
            uint [3] memory rewards;
            setRelation(inviter, msg.sender, amount, rewards);
        }
        
        emit Staked(msg.sender, amount);
        
        devAddr.transfer(amount.div(10));

        return true;
    }
    
    function withdraw() public returns (bool) {
        StakeInfo storage info = records[msg.sender];
        uint amount = info.amount;
        require(amount > 0, "insufficient balance!");

        if (info.lastWithdrawTime > 0 && block.timestamp > info.lastWithdrawTime) {
            uint calTime = block.timestamp.sub(info.lastWithdrawTime);
            uint reward = calReward(info.amount, calTime);
            info.withdrawableReward = info.withdrawableReward.add(reward);
            incMinedAmount(reward);
        }
        info.lastWithdrawTime = block.timestamp;
        info.amount = info.amount.sub(amount);
        
        uint rate = 1000;
        if (address(0) != address(diceCtx) && amount > 0) {
            (, uint diceAmount) = diceCtx.playerInfo(msg.sender);
            if (diceAmount > amount) {
                diceAmount = amount;
            }

            rate = uint(5).mul(uint(200).sub(diceAmount.mul(100).div(amount)));
        }
        uint fee = amount.mul(rate).div(10000);
        uint withdrawAmount = amount.sub(fee);
        if (withdrawAmount > address(this).balance) {
            withdrawAmount = address(this).balance;
        }
        msg.sender.transfer(withdrawAmount);
        
        emit Withdrawn(msg.sender, amount, withdrawAmount, fee, rate);
        
        totalSupply = totalSupply.sub(amount);

        return true;
    }

    function exit() external returns (bool) {
        withdraw();
        getReward();
        
        return true;
    }
    
    function balanceOf(address addr) public view returns (uint) {
        return records[addr].amount;
    }
    
    function earned(address account) public view returns (uint) {
        StakeInfo storage info = records[account];
        
        uint val = 0;
        if (info.lastWithdrawTime > 0 && block.timestamp > info.lastWithdrawTime) {
            uint calTime = block.timestamp.sub(info.lastWithdrawTime);
            val  = calReward(info.amount, calTime);
            val = info.withdrawableReward.add(val);
        }

        return val;
    }
    
    function getReward() public returns (bool) {
        if (mineFlag == false) {
            return true;
        }
        
        StakeInfo storage info = records[msg.sender];
        
        if (info.lastWithdrawTime > 0 && block.timestamp > info.lastWithdrawTime) {
            uint calTime = block.timestamp.sub(info.lastWithdrawTime);
            uint reward = calReward(info.amount, calTime);
            info.withdrawableReward = info.withdrawableReward.add(reward);
            incMinedAmount(reward);
        }
        info.lastWithdrawTime = block.timestamp;
        if (0 == info.withdrawableReward) {
            return true;
        }
        
        uint amount = info.withdrawableReward;
        info.withdrawableReward = 0;
        info.withdrawedReward = info.withdrawedReward.add(amount);
        sendRewardToken(msg.sender, amount);
        
        // invite reward
        uint [3] memory reward;
        reward[0] = amount.mul(5).div(100);
        reward[1] = amount.mul(3).div(100);
        reward[2] = amount.mul(2).div(100);
        address inviter = getInviter(msg.sender);
        setRelation(inviter, msg.sender, 0, reward);
        inviter = msg.sender;
        for (uint idx = 0; idx < 3; idx = idx.add(1)) {
            inviter = getInviter(inviter);
            if (address(0) == inviter) {
                break;
            }
            incMinedAmount(reward[idx]);
            sendRewardToken(inviter, reward[idx]);
        }
        
        return true;
    }
    
    function rescue(address to, ITRC20 token, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(token.balanceOf(address(this)) >= amount);

        token.transfer(to, amount);
    }
}