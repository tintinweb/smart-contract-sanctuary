// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./SafeERC20.sol";
import "./Ownable.sol";


interface ICTTFEE {
    function getFee(uint256 amount) external view returns (uint256);
    function minFee() external view returns(uint256); 
}


// CTTChef is the master of CTT. He can make CTT and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CTT is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract CTTChef is Ownable{
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;      // How many LP tokens the user has provided.
        uint256 rewardDebt;  // Reward debt. See explanation below.
        uint256 reward;
        uint256 depositTime;
        bool isWithdraw;
        //
        // We do some fancy math here. Basically, any point in time, the amount of CTTs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBUSDPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBUSDPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 BUSDPerBlock;
        uint256 lastRewardBlock;  // Last block number that CTTs distribution occurs.
        uint256 accBUSDPerShare;  // Accumulated CTTs per share, times 1e12. See below.
        uint256 depositCTT;
    }
    
    //The CTT TOKEN!
    IERC20 public CTT = IERC20(0x8BD66bB6504DD156ebdb0aC0fD4043a3f410cA9b);
    //BUSD token
    IERC20 public BUSD = IERC20(0x86c4Ffa81B42b00657B9A2693a3e5d74230954Ba);
    //pool Info round => poolInfo
    mapping(uint8 => PoolInfo) public poolInfo;
    //currentRound
    uint8 public currentRound;
    //Info of each user that stakes LP tokens. round => pool => user => info
    mapping(uint8 => mapping(address => UserInfo)) public userInfo;
    //one CTT value;
    uint256 constant ONE_CTT = 10 ** 18;
    // the giver CTT address
    address public giverBUSDAddress;
    
    event NewRound(uint8 round);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event MigrateRound(address user, uint8 round, uint256 value);
    event WithdrawReward(uint8 round, address user, uint256 BUSDamount);
    event Withdraw(uint8 round, address user, uint256 CTTAmount);

    constructor(
        address _giverBUSDAddress
    ){
        giverBUSDAddress = _giverBUSDAddress;     
    }

    function initRound(uint256 _startBlock, uint256 _endBlock, uint256 _perblcokReward) public onlyOwner {
        require(_endBlock > _startBlock, "endblock should greater than startblcok");
        require(block.number < _startBlock, "start block should less than current blcok"); 

        uint256 _lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;

        if(poolInfo[currentRound].endBlock == 0) {
           PoolInfo memory info = PoolInfo({startBlock:_startBlock,endBlock:_endBlock,BUSDPerBlock:_perblcokReward,lastRewardBlock:_lastRewardBlock,accBUSDPerShare:0,depositCTT:0});
           poolInfo[currentRound] = info;
        }else{
           require(block.number > poolInfo[currentRound].endBlock, "wait round finished!");
           currentRound++;
           PoolInfo memory info = PoolInfo({startBlock:_startBlock,endBlock:_endBlock,BUSDPerBlock:_perblcokReward,lastRewardBlock:_lastRewardBlock,accBUSDPerShare:0,depositCTT:0});
           poolInfo[currentRound] = info;
        }

        uint256 blockPass = _endBlock - _lastRewardBlock;

        uint256 value = _perblcokReward * blockPass;

        BUSD.safeTransferFrom(giverBUSDAddress,address(this),value);

        emit NewRound(currentRound);  
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        require(_to >= _from, "invalid block number");

        PoolInfo storage pool = poolInfo[currentRound];

        uint256 endBlock = pool.endBlock;

        if(_to > endBlock) {
            return endBlock - _from;
        }

        if(_from > endBlock) {
            return 0;
        }

        return _to - _from;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint8 round) internal {
        PoolInfo storage pool = poolInfo[round];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        uint256 cttBalance = pool.depositCTT;

        uint256 currentBlock = block.number > pool.endBlock ? pool.endBlock : block.number;

        if (cttBalance == 0) {
            pool.lastRewardBlock = currentBlock;
            return;
        }
         
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, currentBlock);
        uint256 cttReward = multiplier * pool.BUSDPerBlock;
        
        pool.accBUSDPerShare = pool.accBUSDPerShare + (cttReward * 1e12 / cttBalance);
        pool.lastRewardBlock = currentBlock;
    }

    // Deposit CTT tokens to CTTChef for BUSD allocation.
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[currentRound];
        require(block.number < pool.endBlock, "must deposit in round");
        UserInfo storage user = userInfo[currentRound][msg.sender];

        updatePool(currentRound);

        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accBUSDPerShare / 1e12) - user.rewardDebt;  
            user.reward += pending;
        }

        CTT.safeTransferFrom(address(msg.sender), address(this), _amount);

        uint256 subFeeAmount = getSubFeeAmount(_amount);
        pool.depositCTT += subFeeAmount;
        user.amount += subFeeAmount;
        user.rewardDebt = (user.amount * pool.accBUSDPerShare) / 1e12;
        user.depositTime = block.timestamp;

        emit Deposit(msg.sender, currentRound, subFeeAmount);
    }

    function getSubFeeAmount(uint256 _amount) public view returns(uint256) {
        uint256 minFee = ICTTFEE(address(CTT)).minFee();
        require(_amount > minFee,"amount is too small!");
        uint256 fee = ICTTFEE(address(CTT)).getFee(_amount);   

        uint256 realAmount = _amount - fee;

        return realAmount;    
    }

    // View function to see pending CTTs on frontend.
    function pendingCTT(address _user) external view returns(uint256){
        PoolInfo memory pool = poolInfo[currentRound];
        UserInfo memory user = userInfo[currentRound][_user];

        uint256 accBUSDPerShare = pool.accBUSDPerShare;
        
        uint256 roundCttValue = pool.depositCTT;
        
        if (block.number > pool.lastRewardBlock && roundCttValue != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cttReward = multiplier * pool.BUSDPerBlock;
            accBUSDPerShare += cttReward * 1e12 / roundCttValue;
        }

        return (user.amount * accBUSDPerShare / 1e12) - user.rewardDebt;
    }

    function migrateToCurrentRound(uint8 round) public {
        PoolInfo storage beforePool = poolInfo[round]; 
        UserInfo storage beforeUserInfo = userInfo[round][msg.sender];
        uint256 amount = beforeUserInfo.amount;
        require(block.number > beforePool.endBlock,"wait round finished!");
        require(amount > 0, "no ctt for migrate");
        
        if(!beforeUserInfo.isWithdraw) {
            withdrawReward(round);
        }

        beforeUserInfo.amount = 0;
        beforePool.depositCTT -= amount;
    
        PoolInfo storage currentPool = poolInfo[currentRound];
        UserInfo storage user = userInfo[currentRound][msg.sender];
        require(block.number < currentPool.endBlock, "round finished!");

        updatePool(currentRound);

        if(user.amount > 0) {
            uint256 pending = (user.amount * currentPool.accBUSDPerShare / 1e12) - user.rewardDebt;  
            user.reward += pending;
        }

        currentPool.depositCTT += amount;
        user.amount += amount;
        user.rewardDebt = (user.amount * currentPool.accBUSDPerShare) / 1e12;
        user.depositTime = block.timestamp;

        emit MigrateRound(msg.sender, round, amount);   
    }

    function pendingHistoryReward(uint8 round) public view returns(uint256){
        PoolInfo memory beforePool = poolInfo[round];
        UserInfo memory beforeUserInfo = userInfo[round][msg.sender];
        require(block.number > beforePool.endBlock,"wait round finished!");
        require(beforeUserInfo.amount > 0,"amount is 0");
        require(!beforeUserInfo.isWithdraw, "already withdraw reward!");

        uint256 pending = (beforeUserInfo.amount * beforePool.accBUSDPerShare / 1e12) - beforeUserInfo.rewardDebt;  
        uint256 historyReward = beforeUserInfo.reward + pending;

        return historyReward;
    }

    function withdrawReward(uint8 round) public {
        PoolInfo storage beforePool = poolInfo[round];
        UserInfo storage beforeUserInfo = userInfo[round][msg.sender];
        require(block.number > beforePool.endBlock,"wait round finished!");
        require(!beforeUserInfo.isWithdraw, "already withdraw reward!");

        if(beforePool.lastRewardBlock < beforePool.endBlock) {
            updatePool(round);
        }

        uint256 pending = (beforeUserInfo.amount * beforePool.accBUSDPerShare / 1e12) - beforeUserInfo.rewardDebt;  
        beforeUserInfo.reward += pending;
        uint256 BUSDReward = beforeUserInfo.reward;
        beforeUserInfo.reward = 0;
        
        require(BUSDReward > 0, "no reward for withdraw!");
        beforeUserInfo.isWithdraw = true;
        BUSD.safeTransfer(msg.sender,BUSDReward);

        beforeUserInfo.rewardDebt = (beforeUserInfo.amount * beforePool.accBUSDPerShare) / 1e12;

        emit WithdrawReward(round,msg.sender,BUSDReward);
    } 

    function withdraw(uint8 round) public {
        PoolInfo storage beforePool = poolInfo[round];
        UserInfo storage beforeUserInfo = userInfo[round][msg.sender];

        require(block.number > beforePool.endBlock,"wait round finished!");

        if(!beforeUserInfo.isWithdraw) {
            withdrawReward(round);
        }
        
        uint256 cttValue = beforeUserInfo.amount;
        beforeUserInfo.amount = 0;
        require(cttValue > 0, "no ctt for withdraw!");

        CTT.safeTransfer(msg.sender,cttValue);
       
        emit Withdraw(round,msg.sender,cttValue);
    }

    function changeGiver(address newGiver) public onlyOwner {
        giverBUSDAddress = newGiver;
    }

}