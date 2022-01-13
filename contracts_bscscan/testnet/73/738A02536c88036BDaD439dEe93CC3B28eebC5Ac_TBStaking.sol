// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract TBStaking is Ownable {
    using SafeERC20 for IERC20;

    struct UserData {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolData {
        IERC20 stakingToken;
        uint256 lastRewardBlock;  
        uint256 accRewardPerShare;
    }

    IERC20 public rewardToken;
    uint256 public rewardPerBlock = 1 * 1e18; // 1 token
    uint public totalStaked;
    uint256 public endBlock;
    uint count;

    PoolData public liquidityMining;
    mapping(address => UserData) public userData;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    function updateRewardToken(IERC20 _newRewadToken) external onlyOwner {
        rewardToken = _newRewadToken;
    }

    function setPoolData(IERC20 _rewardToken, IERC20 _stakingToken) external onlyOwner {
        require(address(rewardToken) == address(0) && address(liquidityMining.stakingToken) == address(0), 'Token is already set');
        rewardToken = _rewardToken;
        liquidityMining = PoolData({stakingToken : _stakingToken, lastRewardBlock : 0, accRewardPerShare : 0});
    }

    function startMining(uint256 startBlock) external onlyOwner {
        require(liquidityMining.lastRewardBlock == 0, 'Mining already started');
        liquidityMining.lastRewardBlock = startBlock;
    }

    function endMining(uint256 _endBlock) external onlyOwner {
        endBlock = _endBlock;
    }

 
    function updatePool() internal { 
        if (endBlock != 0) {
            require(endBlock > block.number, 'Mining has been ended');
        }       
        require(liquidityMining.lastRewardBlock > 0 && block.number >= liquidityMining.lastRewardBlock, 'Mining not yet started');
        if (block.number <= liquidityMining.lastRewardBlock) {
            return;
        }
        uint256 stakingTokenSupply = totalStaked;
        if (stakingTokenSupply == 0) {
            liquidityMining.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - liquidityMining.lastRewardBlock;
        uint256 tokensReward = multiplier * rewardPerBlock;
        liquidityMining.accRewardPerShare = liquidityMining.accRewardPerShare + (tokensReward * 1e18 / stakingTokenSupply);
        liquidityMining.lastRewardBlock = block.number;
    }

    function deposit(uint256 amount) external {
        if (endBlock != 0) {
            require(endBlock > block.number, 'Mining has been ended');
        }
        UserData storage user = userData[msg.sender];
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare / 1e18) - user.rewardDebt;
            if (pending > 0) {
                user.pendingRewards = user.pendingRewards + pending;
            }
        }
        if (amount > 0) {
            liquidityMining.stakingToken.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amount = user.amount + amount;
        }
        totalStaked = totalStaked + amount;
        
        user.rewardDebt = user.amount * accRewardPerShare / 1e18;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (endBlock != 0) {
            require(endBlock > block.number, 'Mining has been ended');
        }
        UserData storage user = userData[msg.sender];
        require(user.amount >= amount, "Withdrawing amount is more than staked amount");
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        uint256 pending = (user.amount * accRewardPerShare / 1e18) - user.rewardDebt;
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards + pending;
        }
        if (amount > 0) {
            user.amount = user.amount - amount;
            liquidityMining.stakingToken.safeTransfer(address(msg.sender), amount);
        }
        totalStaked = totalStaked - amount;
        user.rewardDebt = user.amount * accRewardPerShare / 1e18;
        emit Withdraw(msg.sender, amount);
    }

    function claim() external {
        if (endBlock != 0) {
            require(endBlock > block.number, 'Mining has been ended');
        }
        UserData storage user = userData[msg.sender];
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        uint256 pending = (user.amount * accRewardPerShare / 1e18) - user.rewardDebt;
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards + pending;
            uint256 claimedAmount = safeRewardTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, claimedAmount);
            user.pendingRewards = user.pendingRewards - claimedAmount;
        }
        user.rewardDebt = user.amount * accRewardPerShare / 1e18;
    }

    function safeRewardTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(this));
        require(amount > 0, 'Reward amount must be more than zero');
        require(balance > 0, 'Insufficient reward tokens for this transfer');
        if (amount > balance) {
            rewardToken.transfer(to, balance);
            return balance;
        }
        rewardToken.transfer(to, amount);
        return amount;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_rewardPerBlock > 0, "Reward per block must be more than zero");
        rewardPerBlock = _rewardPerBlock;
    }

    
    function pendingRewards(address _user) external view returns (uint256) {
        if (endBlock != 0) {
            require(endBlock > block.number, 'Mining has been ended');
        }
        if (liquidityMining.lastRewardBlock == 0 || block.number < liquidityMining.lastRewardBlock) {
            return 0;
        }

        UserData storage user = userData[_user];
        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;
        uint256 stakingTokenSupply = totalStaked;

        if (block.number > liquidityMining.lastRewardBlock && stakingTokenSupply != 0) {
            uint256 perBlock = rewardPerBlock;
            uint256 multiplier = block.number - liquidityMining.lastRewardBlock;
            uint256 reward = multiplier * perBlock;
            accRewardPerShare = accRewardPerShare + (reward * 1e18 / stakingTokenSupply);
        }

        return (user.amount * accRewardPerShare / 1e18) - user.rewardDebt + user.pendingRewards;
    }

    function extraTokensWithdraw(IERC20 token, address to, uint256 amount) external onlyOwner {
        require(endBlock != 0, 'Set end block');
        require(block.number > endBlock, 'Mining still in progress');
        token.transfer(to,amount);
        totalStaked = totalStaked - amount;
    }

// Function which are getting executed after the end block

    function lateWithdraw(uint256 amount) external {
        require(endBlock != 0, 'Mining has to end');
        require(endBlock < block.number, 'Mining has to end');
        UserData storage user = userData[msg.sender];
        require(user.amount >= amount, "Withdrawing amount is more than staked amount");
        if (amount > 0) {
            user.amount = user.amount - amount;
            liquidityMining.stakingToken.safeTransfer(address(msg.sender), amount);
        }
        totalStaked = totalStaked - amount;
        emit Withdraw(msg.sender, amount);
    }

}