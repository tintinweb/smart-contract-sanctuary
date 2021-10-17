// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";


contract LarkPool is Ownable {
    // Info of each user.
    struct UserInfo {
        uint256 amounts;    
        uint256 rewardDebt; 
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;        
        uint256 allocPoint;      
        uint256 lastRewardBlock; 
        uint256 rewardsPerShare;  //*1e12
    }

    mapping(uint256 => PoolInfo) public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (uint256 => address[]) public userLists;
    uint256 public poolId = 0;
    
    IERC20 public immutable LARK;
    uint256 public immutable genesisBlock;
    uint256 public totalAllocPoint;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 rewardsOut);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor (IERC20 _lark, uint256 _genesisBlock) {
        LARK = _lark;
        genesisBlock = _genesisBlock;
        totalAllocPoint = 0;
    }

    // deposit LP tokens to the pool
    function deposit(uint256 _pid, uint256 _amount) external {
        require(_amount > 0);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);

        if (user.amounts > 0) {
            uint256 pending = user.amounts * pool.rewardsPerShare / 1e12 - user.rewardDebt;
            if(pending > 0) {
                LARK.transfer(msg.sender, pending);
            }
        }else{
            //when he first deposit
            userLists[_pid].push(msg.sender);
        }
       
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        user.amounts = user.amounts + _amount;
        user.rewardDebt = user.amounts * pool.rewardsPerShare / 1e12;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // withdraw LP tokens
    function withdraw(uint256 _pid, uint256 _amount) external {
        require(_amount > 0);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amounts >= _amount, "no enough amounts!");

        _updatePool(_pid);

        uint256 pending = user.amounts * pool.rewardsPerShare / 1e12 - user.rewardDebt;
        if(pending > 0) {
            LARK.transfer(msg.sender, pending);
        }

        user.amounts = user.amounts - _amount;
        user.rewardDebt = user.amounts * pool.rewardsPerShare / 1e12;
        pool.lpToken.transfer(msg.sender, _amount);
        
        emit Withdraw(msg.sender, _pid, _amount);
    }

    //Calculate the current income in the pool
    function pendingLark(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 currentBlock = block.number;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 _rewardsPerShare = pool.rewardsPerShare;

        if (currentBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 unMintedRewards = _calculateReward(pool.lastRewardBlock + 1, currentBlock);
            uint256 unMintedpoolRewards = unMintedRewards * pool.allocPoint / totalAllocPoint;
            _rewardsPerShare = _rewardsPerShare + unMintedpoolRewards * 1e12 / lpSupply; 
        } 
        return user.amounts * _rewardsPerShare / 1e12 - user.rewardDebt;
    }

    function harvest(uint256 _pid) external returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updatePool(_pid);

        uint256 pending = user.amounts * pool.rewardsPerShare / 1e12 - user.rewardDebt;
        if(pending > 0) {
            LARK.transfer(msg.sender, pending);
            user.rewardDebt = user.amounts * pool.rewardsPerShare / 1e12;

            emit Harvest(msg.sender, _pid, pending);
        }
        return pending;
    }

    // add new pool
    function addPool(uint256 _allocPoint, IERC20 _lpToken) external onlyOwner {
        if(poolId >= 1){
            _massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint + _allocPoint;
      
        poolId += 1;
        poolInfo[poolId].lpToken = _lpToken;
        poolInfo[poolId].allocPoint = _allocPoint;
        poolInfo[poolId].lastRewardBlock = block.number > genesisBlock ? block.number : genesisBlock;
        poolInfo[poolId].rewardsPerShare = 0;
    }

    // reset pool allocPoint
    function setAllocPoint(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        _massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    //Halving parameter
    function rewardsPerBlock() public view returns (uint256) {
        uint256 currentBlock = block.number;
        uint256 BASE_50  = 50 * 1e18;
        uint256 BASE_25  = 25 * 1e18;
        uint256 BASE_12  = 12.5 * 1e18;
        uint256 BASE_6  = 6.25 * 1e18;
        uint256 BASE_3  = 3.125 * 1e18;
        uint256 BASE_1  = 1.5625 * 1e18;
        uint256 BASE_0  = 0.78125 * 1e18;

        if (currentBlock <= (genesisBlock + 4000000)) {
            return BASE_50;
        } else if (currentBlock > (genesisBlock + 4000000) && currentBlock <= (genesisBlock + 17000000)) {
            return BASE_25;
        } else if (currentBlock > (genesisBlock + 17000000) && currentBlock <= (genesisBlock + 30000000)) {
            return BASE_12;
        } else if (currentBlock > (genesisBlock + 30000000) && currentBlock <= (genesisBlock + 43000000)) {
            return BASE_6;
        } else if (currentBlock > (genesisBlock + 43000000) && currentBlock <= (genesisBlock + 56000000)) {
            return BASE_3;
        } else if (currentBlock > (genesisBlock + 56000000) && currentBlock <= (genesisBlock + 69000000)) {
            return BASE_1;
        } else {
            return BASE_0;
        } 
    }

    // calculate rewards between [from, to] block
    function _calculateReward(uint256 from, uint256 to) private view returns (uint256) {
        require(from <= to);
        uint256 rewards = rewardsPerBlock();
        return (to - from + 1) * rewards;
    }

    // all pools update
    function _massUpdatePools() private {
        for (uint256 pid = 1; pid <= poolId; pid ++) {
            _updatePool(pid);
        }
    }

    // update a pool
    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 currentBlock = block.number;
        if (currentBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 totalRewards = _calculateReward(pool.lastRewardBlock + 1, currentBlock);
        uint256 poolRewards = totalRewards * pool.allocPoint / totalAllocPoint;
        LARK.mint(address(this), poolRewards);
        pool.rewardsPerShare = pool.rewardsPerShare + poolRewards * 1e12 / lpSupply;
        pool.lastRewardBlock = currentBlock;
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.transfer(msg.sender, user.amounts);
        emit EmergencyWithdraw(msg.sender, _pid, user.amounts);
        user.amounts = 0;
        user.rewardDebt = 0;
    }


    // Get the list length of a pool users
    function getUserListsLength(uint256 _pid) external view returns(uint256){
        return userLists[_pid].length;
    }

    //get a pool's all users
    function getAllUsers(uint256 _pid) external view returns(address[] memory allUsers){
        allUsers = userLists[_pid];
    }

    //get a pool's all users info
    function getAllUsersInfo(uint256 _pid) external view returns (UserInfo[] memory returnData){
        returnData = new UserInfo[](userLists[_pid].length);
        
        for(uint256 i = 0; i < userLists[_pid].length; i ++){
            returnData[i] = userInfo[_pid][userLists[_pid][i]];
        }
        return returnData;
    }

}