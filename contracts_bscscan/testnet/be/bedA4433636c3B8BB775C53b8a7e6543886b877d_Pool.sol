// SPDX-License-Identifier: MIT

pragma solidity 0.5.8;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Pool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 token;
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardPerBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }
    IERC20 rewardToken;
    address public dev;
    PoolInfo[] public pools;
    mapping (uint256 => mapping (address => UserInfo)) public users;
    uint256 constant freeze = 57600; // 48 hours ～ 57600 blocks

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IERC20 _rewardToken) public {
        rewardToken = _rewardToken;
        dev = msg.sender;
    }

    modifier checkPool(uint256 _pid) {
        require(address(pools[_pid].token) != address(0), "pool not exist");
        _;
    }

    function changeDev(address newDev) public {
        require(msg.sender == dev, "Permission denied");
        require(dev != address(0), "invalid address");
        dev = newDev;
    }

    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    function addPool(IERC20 _token, uint256 _startBlock, uint256 _endBlock, uint256 _rewardPerBlock) public onlyOwner {
        for (uint i = 0; i < pools.length; ++i) {
            require(address(pools[i].token) != address(_token), "pool already exist");
        }
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        pools.push(PoolInfo({
            token: _token,
            startBlock: _startBlock,
            endBlock: _endBlock,
            rewardPerBlock: _rewardPerBlock,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0
        }));
    }

    function getTotalReward(PoolInfo storage pool) internal view returns (uint256 reward) {
        if (block.number <= pool.lastRewardBlock) {
            return 0;
        }
        uint256 from = pool.lastRewardBlock;
        uint256 to = block.number < pool.endBlock ? block.number : pool.endBlock;
        if (from >= to) {
            return 0;
        }
        uint256 multiplier = to.sub(from);
        return multiplier.mul(pool.rewardPerBlock);
    }

    function updatePool(uint256 _pid) public checkPool(_pid) {
        PoolInfo storage pool = pools[_pid];
        if (block.number <= pool.lastRewardBlock || pool.lastRewardBlock >= pool.endBlock) {
            return;
        }

        uint256 totalStake = pool.token.balanceOf(address(this));
        if (totalStake == 0) {
            pool.lastRewardBlock = block.number < pool.endBlock ? block.number : pool.endBlock;
            return;
        }
        
        uint256 reward = getTotalReward(pool);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(totalStake));
        pool.lastRewardBlock = block.number < pool.endBlock ? block.number : pool.endBlock;
    }

    function pendingReward(uint256 _pid, address _user) external view checkPool(_pid) returns (uint256) {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 totalStake = pool.token.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && totalStake > 0) {
            uint256 reward = getTotalReward(pool);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(totalStake));
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function deposit(uint256 _pid, uint256 _amount) public checkPool(_pid) {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            require(block.number < pool.endBlock, "pool has closed");
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                uint256 fee;
                if (block.number < pool.startBlock.add(freeze)) {
                    fee = pending.div(5); // 20% fee
                } else {
                    fee = pending.div(20); // 5% fee
                }
                pending = pending.sub(fee);
                if (pending > 0) {
                    safeRewardTransfer(msg.sender, pending);
                }
                if (fee > 0) {
                    safeRewardTransfer(dev, fee);
                }
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public checkPool(_pid) {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: insufficient balance");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            uint256 fee;
            if (block.number < pool.startBlock.add(freeze)) {
                fee = pending.div(5); // 20% fee
            } else {
                fee = pending.div(20); // 5% fee
            }
            pending = pending.sub(fee);
            if (pending > 0) {
                safeRewardTransfer(msg.sender, pending);
            }
            if (fee > 0) {
                safeRewardTransfer(dev, fee);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.transfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        uint256 send = _amount;
        if (_amount > rewardBalance) {
            send = rewardBalance;
        }
        if (send > 0) {
            rewardToken.transfer(_to, send);
        }
    }
}