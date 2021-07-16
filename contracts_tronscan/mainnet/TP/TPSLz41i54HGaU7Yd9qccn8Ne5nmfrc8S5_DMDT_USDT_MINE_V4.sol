//SourceUnit: A007_diamond_usdt_mine_v3.sol

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

contract Ownable {
    using Address for address;
    address payable public Owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(Owner, _newOwner);
        Owner = _newOwner.toPayable();
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

library SafeTRC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract());

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)));
        }
    }
}

interface IDICEInfo {
    function playerInfo(address player) external view returns (uint count, uint amount);
}

contract Mine is Ownable {
    using SafeMath for uint;
    using Address for address;
    using SafeTRC20 for ITRC20;
    
    ITRC20 public rewardToken = ITRC20(0x411bab47bed72f31464a963bfaf7d76eaf4b44d9d3);
    
    uint public round;
    uint public minedAmount;
    bool public mineFlag = true;
    
    uint public minePrice = 800 * 1e6; // round 0: 400, round 1: 500: round 2: 625 .....
    uint public DURATION = 1 days;
   
    uint public PriceStageBase = 100;
    uint public PriceStageDelta = 80;
    
    uint public mineStage;
    uint public MineStageMax = 5000 * 1e18;
    uint public MineStageDelta = 500 * 1e18;

    constructor() public {
        incMinedAmount(0);
    }
    
    function setRewardToken(address addr) public onlyOwner {
        require(address(0) != addr, "invalid address");
        require(addr.isContract(), "token address should be contract");
        rewardToken = ITRC20(addr);
        mineFlag = true;
    }
    
    function setMinePrice(uint val) public onlyOwner {
        minePrice = val;
    }
    
    function setPriceStage(uint base, uint stage, uint delta) public onlyOwner {
        require(base >= stage && base > 0 && base >= delta);
        PriceStageBase = base;
        // PriceStage = stage;
        PriceStageDelta = delta;
    }
    
    function setMineStage(uint max, uint delta) public onlyOwner {
        MineStageMax = max;
        MineStageDelta = delta;
    }
    
    function updateMinePrice() internal {
        if (minedAmount >= MineStageMax) {
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
    
    function sendRewardToken(address to, uint amount) internal returns (uint) {
        if (address(0) == address(rewardToken)) {
            return 0;
        }

        if (mineFlag == false) {
            return 0;
        }
        
        uint maxReward = rewardToken.balanceOf(address(this));
        if (amount > maxReward) {
            amount = maxReward;
        }
        
        if (amount > 0) {
            rewardToken.transfer(to, amount);
            return amount;
        }
        return 0;
    }
    
    function calReward(uint amount, uint calTime) internal view returns (uint) {
        uint reward = amount.mul(1e18).div(minePrice).div(DURATION).mul(calTime);
        if (minedAmount.add(reward) >= mineStage) {
            reward = mineStage.sub(minedAmount); // cut reward to mine stage limit
        }
        return reward;
    }
    
}

contract DMDT_USDT_MINE_V4 is Mine {
    using SafeMath for uint;
    using Address for address;
    
    IDICEInfo public diceCtx;
    
    ITRC20 usdtToken = ITRC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);
    
    uint public totalSupply;
    
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint transferAmount, uint fee, uint rate);
    event RewardPaid(address indexed user, uint reward);
    
    uint public pauseStart = 1605182400; // 12:00:00 11/12/2020 UTC
    uint public pauseEnd = 1605268800; // 12:00:00 11/13/2020 UTC
    
    struct StakeInfo {
        uint lastWithdrawTime;
        uint withdrawableReward;
        uint withdrawedReward;
        uint amount;
        
        address inviter;
        uint level1_invitee_cnt;
        uint level1_invitee_investAmount;
        uint level1_reward;
        uint level2_invitee_cnt;
        uint level2_invitee_investAmount;
        uint level2_reward;
        uint level3_invitee_cnt;
        uint level3_invitee_investAmount;
        uint level3_reward;
    }
    
    mapping (address => StakeInfo) public records;
    mapping (uint => address) public uids;
    uint public maxUID;
    
    constructor() public {
    }
    
    function balance() public view returns (uint) {
        return usdtToken.balanceOf(address(this));
    }
    
    function inviteRecord(address invitee, uint investAmount, address inviter) internal {
        if (records[invitee].inviter == address(0) && inviter != invitee && records[inviter].amount > 0) {
            records[invitee].inviter = inviter;
            
            records[inviter].level1_invitee_cnt = records[inviter].level1_invitee_cnt.add(1);
            records[inviter].level1_invitee_investAmount = records[inviter].level1_invitee_investAmount.add(investAmount);
            
            if (records[inviter].inviter != address(0)) {
                inviter = records[inviter].inviter;
                records[inviter].level2_invitee_cnt = records[inviter].level2_invitee_cnt.add(1);
                records[inviter].level2_invitee_investAmount = records[inviter].level2_invitee_investAmount.add(investAmount);
                
                if (records[inviter].inviter != address(0)) {
                    inviter = records[inviter].inviter;
                    records[inviter].level3_invitee_cnt = records[inviter].level3_invitee_cnt.add(1);
                    records[inviter].level3_invitee_investAmount = records[inviter].level3_invitee_investAmount.add(investAmount);
                }
            }
        }
    }
    
    function sendInviteReward(address user, uint amount) internal {
        if (address(0) == user || amount == 0) {
            return;
        }
        uint reward = amount.mul(5).div(100);
        address inviter = records[user].inviter;
        if (address(0) != inviter) {
            records[inviter].level1_reward = records[inviter].level1_reward.add(reward);
            records[inviter].withdrawableReward = records[inviter].withdrawableReward.add(reward);
            incMinedAmount(reward);
            
            reward = amount.mul(3).div(100);
            inviter = records[inviter].inviter;
            if (address(0) != inviter) {
                records[inviter].level2_reward = records[inviter].level2_reward.add(reward);
                records[inviter].withdrawableReward = records[inviter].withdrawableReward.add(reward);
                incMinedAmount(reward);
                
                reward = amount.mul(2).div(100);
                inviter = records[inviter].inviter;
                if (address(0) != inviter) {
                    records[inviter].level3_reward = records[inviter].level3_reward.add(reward);
                    records[inviter].withdrawableReward = records[inviter].withdrawableReward.add(reward);
                    incMinedAmount(reward);
                }
            }
        }
    }
    
    function setDiceCtx(address addr) public onlyOwner {
        require(address(0) != addr, "invalid reward token address");
        require(addr.isContract() == true, "reward token should be a contract");
        diceCtx = IDICEInfo(addr);
    }
    
    modifier pause {
        require(block.timestamp < pauseStart || block.timestamp > pauseEnd, "pause");
        _;
    }

    uint public minStakeAmount = 1 * 1e6;
    
    function setMinStakeAmount(uint val) public onlyOwner {
        minStakeAmount = val;
    }

    uint public minDiceCount = 0;

    function setMinDiceCount(uint val) public onlyOwner {
        minDiceCount = val;
    }

    function stake(address inviter, uint amount) public payable pause returns (bool) {
        require(amount >= minStakeAmount, "invalid stake amount");
        usdtToken.transferFrom(msg.sender, address(this), amount);
        
        if (address(0) != address(diceCtx) && minDiceCount > 0) {
            (uint diceCnt, ) = diceCtx.playerInfo(msg.sender);
            require(diceCnt >= minDiceCount, "play dice first");
        }
        
        StakeInfo storage info = records[msg.sender];
        if (info.lastWithdrawTime == 0) {
            uids[maxUID] = msg.sender;
            maxUID = maxUID.add(1);
        }
        
        if (info.lastWithdrawTime > 0 && block.timestamp > info.lastWithdrawTime) {
            uint calTime = block.timestamp.sub(info.lastWithdrawTime);
            uint reward = calReward(info.amount, calTime);
            info.withdrawableReward = info.withdrawableReward.add(reward);
            incMinedAmount(reward);
        }
        info.lastWithdrawTime = block.timestamp;
        
        info.amount = info.amount.add(amount);
        totalSupply = totalSupply.add(amount);
        
        emit Staked(msg.sender, amount);
        
        usdtToken.transfer(Owner, amount.mul(8).div(100));
        inviteRecord(msg.sender, amount, inviter);

        return true;
    }
    
    function _withdraw() internal returns (bool) {
        StakeInfo storage info = records[msg.sender];
        uint amount = info.amount;
        if (amount == 0) {
            return false;
        }

        if (info.lastWithdrawTime > 0 && block.timestamp > info.lastWithdrawTime) {
            uint calTime = block.timestamp.sub(info.lastWithdrawTime);
            uint reward = calReward(info.amount, calTime);
            info.withdrawableReward = info.withdrawableReward.add(reward);
            incMinedAmount(reward);
        }
        info.lastWithdrawTime = block.timestamp;
        info.amount = info.amount.sub(amount);
        
        uint rate = 800;
        if (address(0) != address(diceCtx) && amount > 0) {
            (, uint diceAmount) = diceCtx.playerInfo(msg.sender);
            if (diceAmount > amount) {
                diceAmount = amount;
            }

            rate = uint(4).mul(uint(200).sub(diceAmount.mul(100).div(amount)));
        }
        uint fee = amount.mul(rate).div(10000);
        uint withdrawAmount = amount.sub(fee);
        if (withdrawAmount > balance()) {
            withdrawAmount = balance();
        }
        
        usdtToken.transfer(msg.sender, withdrawAmount);
        
        emit Withdrawn(msg.sender, amount, withdrawAmount, fee, rate);
        
        totalSupply = totalSupply.sub(amount);

        return true;
    }

    function withdraw() external pause returns (bool) {
        _withdraw();
        _getReward();
        
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
    
    function _getReward() internal returns (bool) {
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
        
        uint amount = info.withdrawableReward;
        info.withdrawableReward = 0;
        info.withdrawedReward = info.withdrawedReward.add(amount);
        amount = sendRewardToken(msg.sender, amount);
        
        sendInviteReward(msg.sender, amount);
        
        return true;
    }
    
    function rescue(address to, ITRC20 token, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(token != usdtToken, "can't rescue USDT");
        require(token.balanceOf(address(this)) >= amount, "insufficient token balance");

        token.transfer(to, amount);
    }
    
    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(address(this).balance >= amount, "insufficient balance");

        to.transfer(amount);
    }
}