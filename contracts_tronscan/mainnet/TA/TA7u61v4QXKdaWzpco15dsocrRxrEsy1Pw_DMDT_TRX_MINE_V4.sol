//SourceUnit: A005_diamond_trx_mine_v4.sol

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
    
    ITRC20 public rewardToken;
    
    uint public round;
    uint public minedAmount;
    bool public mineFlag;
    
    uint public minePrice;
    uint public minePriceBase = 20000 * 1e6; // base minePrice = 20000 TRX
    uint public DURATION = 1 days;
   
    uint public PriceStageBase = 100;
    uint public PriceStage = 100;
    uint public PriceStageDelta = 10;
    
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
    
    function setPriceBase(uint val) public onlyOwner {
        minePriceBase = val;
    }
    
    function setPriceStage(uint base, uint stage, uint delta) public onlyOwner {
        require(base >= stage && base > 0 && base >= delta);
        PriceStageBase = base;
        PriceStage = stage;
        PriceStageDelta = delta;
    }
    
    function setMineStage(uint max, uint delta) public onlyOwner {
        MineStageMax = max;
        MineStageDelta = delta;
    }
    
    function updateMinePrice() internal {
        if (PriceStage == 0 || minedAmount >= MineStageMax) {
            mineFlag = false;
            minePrice = 0;
            return;
        }

        round = round.add(1);
        minePrice = minePriceBase.mul(PriceStageBase).div(PriceStage);
        
        PriceStage = PriceStage.sub(PriceStageDelta);
    }
    
    function incMinedAmount(uint amount) internal {
        minedAmount = minedAmount.add(amount);
        if (minedAmount >= mineStage) {
            mineStage = mineStage.add(MineStageDelta);
            updateMinePrice();
        }
    }
    
    function sendRewardToken(address to, uint amount) internal {
        if (address(0) == address(rewardToken)) {
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
            reward = mineStage.sub(minedAmount); // cut reward to mine stage limit
        }
        return reward;
    }
    
}

contract DMDT_TRX_MINE_V4 is Mine {
    using SafeMath for uint;
    using Address for address;
    
    IDICEInfo public diceCtx;
    
    uint public totalSupply;
    
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint transferAmount, uint fee, uint rate);
    event RewardPaid(address indexed user, uint reward);
    
    struct StakeInfo {
        uint lastWithdrawTime;
        uint withdrawableReward;
        uint withdrawedReward;
        uint amount;
        address inviter;
        uint inviteCount;
        uint inviteAmount;
        uint inviteReward;
    }
    
    mapping (address => StakeInfo) public records;
    
    constructor() public {
    }
    
    function balance() public view returns (uint) {
        return address(this).balance;
    }
    
    function setDiceCtx(address addr) public onlyOwner {
        require(address(0) != addr, "invalid reward token address");
        require(addr.isContract() == true, "reward token should be a contract");
        diceCtx = IDICEInfo(addr);
    }
    
    uint stakeMinDiceCnt = 3;
    function setStakeMinDiceCnt(uint val) public onlyOwner {
        stakeMinDiceCnt = val;
    }

    function stake(address inviter) public payable returns (bool) {
        require(msg.value > 0, "Cannot stake 0");
        uint amount = msg.value;
        
        if (address(0) != address(diceCtx)) {
            (uint diceCnt, ) = diceCtx.playerInfo(msg.sender);
            require(diceCnt >= stakeMinDiceCnt, "play dice first");
        }
        
        StakeInfo storage info = records[msg.sender];
        if (info.lastWithdrawTime > 0 && block.timestamp > info.lastWithdrawTime) {
            uint calTime = block.timestamp.sub(info.lastWithdrawTime);
            uint reward = calReward(info.amount, calTime);
            info.withdrawableReward = info.withdrawableReward.add(reward);
            incMinedAmount(reward);
        }
        info.lastWithdrawTime = block.timestamp;
        
        if (address(0) == info.inviter && address(0) != inviter && records[inviter].amount > 0 && inviter != msg.sender) {
            info.inviter = inviter;
            // inviter count
            records[inviter].inviteCount = records[inviter].inviteCount.add(1);
            records[inviter].inviteAmount = records[inviter].inviteAmount.add(amount);
        } else {
            inviter = info.inviter;
            // inviter amount
            records[inviter].inviteAmount = records[inviter].inviteAmount.add(amount);
        }
        info.amount = info.amount.add(amount);
        totalSupply = totalSupply.add(amount);
        
        emit Staked(msg.sender, amount);
        
        Owner.transfer(amount.div(10));

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
        
        uint amount = info.withdrawableReward;
        info.withdrawableReward = 0;
        info.withdrawedReward = info.withdrawedReward.add(amount);
        sendRewardToken(msg.sender, amount);

        // inviter reward
        uint inviteReward = amount.div(10);
        incMinedAmount(inviteReward);
        if (address(0) != info.inviter && records[info.inviter].amount > 0) {
            sendRewardToken(info.inviter, inviteReward);
            records[info.inviter].inviteReward = records[info.inviter].inviteReward.add(inviteReward);
        } else {
            sendRewardToken(Owner, inviteReward);
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