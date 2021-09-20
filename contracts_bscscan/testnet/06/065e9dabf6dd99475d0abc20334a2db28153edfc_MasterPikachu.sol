// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./Pikachu.sol";

contract MasterPikachu is SafeMath, Ownable {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        ERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 PikachuPerShare;
    }

    Pikachu public pikachu;

    uint256 PikachuPerBlock;

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 150;

    uint256 startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(Pikachu _pikachu, uint256 _pikachuPerBlock) public {
        pikachu = _pikachu;
        PikachuPerBlock = _pikachuPerBlock;

        poolInfo.push(
            PoolInfo({
                lpToken: _pikachu,
                allocPoint: 150,
                lastRewardBlock: startBlock,
                PikachuPerShare: 1
            })
        );
    }

    function pendingPikachu(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 PikachuPerShare = pool.PikachuPerShare;
        return safeSub(safeMul(user.amount, PikachuPerShare), user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pikachu.balanceOf(address(pool.lpToken));
        uint256 PikachuReward = PikachuPerBlock;
        pikachu._mint(msg.sender, PikachuReward);
        // This is normally where the mint would happen, Bourbon has a fixed supply and does not mint any tokens.
        pool.PikachuPerShare = safeAdd(
            pool.PikachuPerShare,
            safeDiv(PikachuReward, lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = safeSub(
                safeMul(user.amount, pool.PikachuPerShare),
                user.rewardDebt
            );
            if (pending > 0) {
                pikachu.transfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pikachu.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = safeAdd(user.amount, _amount);
        }
        user.rewardDebt = safeMul(user.amount, pool.PikachuPerShare);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterSugar.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = safeSub(
            safeMul(user.amount, pool.PikachuPerShare),
            user.rewardDebt
        );
        if (pending > 0) {
            pikachu.transfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = safeSub(user.amount, _amount);
            pikachu.transfer(address(msg.sender), _amount);
        }
        user.rewardDebt = safeMul(user.amount, pool.PikachuPerShare);
        emit Withdraw(msg.sender, _pid, _amount);
    }
}