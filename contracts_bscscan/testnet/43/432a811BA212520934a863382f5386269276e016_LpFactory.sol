// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract LpFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 totalAward;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accAwardPerShare;
        uint256 startBlock;
        uint256 finallyBlock;
        uint256 lpNumner;
    }

    uint256 public awardPerBlock;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;

    IERC20 public awardToken;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawLp(address indexed user, uint256 indexed pid, uint256 amount);

    function setAwardPerBlock(uint256 _awardPerBlock) public onlyOwner {
        awardPerBlock = _awardPerBlock;
    }

    function setAwardToken(IERC20 _awardToken) public onlyOwner {
        awardToken = _awardToken;
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _startBlock,
        uint256 _finallyBlock,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > _startBlock
            ? block.number
            : _startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                startBlock: _startBlock,
                finallyBlock: _finallyBlock,
                accAwardPerShare: 0,
                lpNumner: 0
            })
        );
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _startBlock,
        uint256 _finallyBlock,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].startBlock = _startBlock;
        poolInfo[_pid].finallyBlock = _finallyBlock;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[_pid];

        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 blocks = 0;
                if (block.number > pool.finallyBlock) {
                    blocks = pool.finallyBlock.sub(pool.lastRewardBlock);
                } else {
                    blocks = block.number.sub(pool.lastRewardBlock);
                }
                uint256 reward = blocks.mul(awardPerBlock).mul(
                    pool.allocPoint.div(totalAllocPoint)
                );
                pool.accAwardPerShare = pool.accAwardPerShare.add(
                    (reward.mul(1e18).div(lpSupply))
                );
            }
            pool.lastRewardBlock = block.number;
            poolInfo[_pid] = pool;
        }
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.rewardDebt.add(
            _amount.mul(pool.accAwardPerShare) / 1e18
        );

        pool.lpNumner = pool.lpNumner.add(_amount);

        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        poolInfo[_pid] = pool;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 accumulatedAward = user.amount.mul(pool.accAwardPerShare) /
            1e18;
        uint256 _pending = accumulatedAward.sub(user.rewardDebt);

        user.rewardDebt = accumulatedAward.sub(
            _amount.mul(pool.accAwardPerShare) / 1e18
        );
        user.amount = user.amount.sub(_amount);

        user.totalAward = user.totalAward.add(_pending);

        awardToken.safeTransfer(msg.sender, _pending);

        pool.lpToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _pid, _pending);
        emit WithdrawLp(msg.sender, _pid, _amount);
    }

    function harvest(uint256 _pid) public {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 accumulatedAward = user.amount.mul(pool.accAwardPerShare) /
            1e18;
        uint256 _pending = accumulatedAward.sub(user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedAward;

        // Interactions
        if (_pending != 0) {
            user.totalAward = user.totalAward.add(_pending);
            awardToken.safeTransfer(msg.sender, _pending);
        }

        emit Withdraw(msg.sender, _pid, _pending);
    }

    function pending(uint256 _pid) public view returns (uint256 _pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 accAwardPerShare = pool.accAwardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number.sub(pool.lastRewardBlock);
            uint256 reward = blocks.mul(awardPerBlock).mul(pool.allocPoint) /
                totalAllocPoint;
            accAwardPerShare = accAwardPerShare.add(
                reward.mul(1e18) / lpSupply
            );
        }
        _pending = uint256(user.amount.mul(accAwardPerShare) / 1e18).sub(
            user.rewardDebt
        );
    }

    function getPools() public view returns (PoolInfo[] memory) {
        return poolInfo;
    }
}