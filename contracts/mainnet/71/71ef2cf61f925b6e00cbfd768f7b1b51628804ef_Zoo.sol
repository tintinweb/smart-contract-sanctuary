// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//
//
//                    ┌─┐       ┌─┐ + +
//                    ┌──┘ ┴───────┘ ┴──┐++
//                    │                 │
//                    │       ───       │++ + + +
//                    ███████───███████ │+
//                    │                 │+
//                    │       ─┴─       │
//                    │                 │
//                    └───┐         ┌───┘
//                    │         │
//                    │         │   + +
//                    │         │
//                    │         └──────────────┐
//                    │                        │
//                    │                        ├─┐
//                    │                        ┌─┘
//                    │                        │
//                    └─┐  ┐  ┌───────┬──┐  ┌──┘  + + + +
//                    │ ─┤ ─┤       │ ─┤ ─┤
//                    └──┴──┘       └──┴──┘  + + + +
//                    神兽保佑
//                    代码无BUG!

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";

import "./ZooToken.sol";

// MasterChef is the master of Lyptus. He can make Lyptus and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once LYPTUS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Zoo is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 stakeAmount;         // How many LP tokens the user has provided.
        uint256 balance;
        uint256 pledgeTime;
        bool isExist;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 poolToken;           // Address of LP token contract.
        uint256 zooRewardRate;
        uint256 totalStakeAmount;
        uint256 openTime;
        bool isOpen;
    }

    struct KeyFlag {
        address key;
        bool isExist;
    }

    // The ZOO TOKEN!
    ZooToken public zoo;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event CancelStake(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _zooTokenAddress
    ) public {
        zoo = ZooToken(_zooTokenAddress);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(address _poolAddress, uint256 _zooRewardRate, uint256 _openTime, bool _isOpen) public onlyOwner {
        IBEP20 _poolToken = IBEP20(_poolAddress);
        poolInfo.push(PoolInfo({
        poolToken: _poolToken,
        zooRewardRate: _zooRewardRate,
        totalStakeAmount: 0,
        openTime: _openTime,
        isOpen: _isOpen
        }));
    }

    function updatePool(uint256 _pid, uint256 _zooRewardRate, uint256 _openTime, bool _isOpen) public onlyOwner {
        poolInfo[_pid].zooRewardRate = _zooRewardRate;
        poolInfo[_pid].openTime = _openTime;
        poolInfo[_pid].isOpen = _isOpen;
    }


    function addUser(uint256 _pid, uint256 _amount) private {
        userInfo[_pid][msg.sender] = UserInfo(
            _amount,
            0,
            block.timestamp,
            true
        );
    }

    function stake(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.poolToken.transferFrom(address(msg.sender), address(this), _amount);

        if(user.isExist == false){
            addUser(_pid, _amount);
        }else{
            user.stakeAmount = user.stakeAmount.add(_amount);
            uint256 profit = getUserProfit(_pid, false);

            if (profit > 0) {
                user.balance = user.balance.add(profit);
            }

            user.pledgeTime = block.timestamp;
        }
        
        pool.totalStakeAmount = pool.totalStakeAmount.add(_amount);

        emit Stake(msg.sender, _pid, _amount);
    }

    function cancelStake(uint256 _pid) public payable {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.isExist) {
            if (user.stakeAmount > 0) {
                uint256 stakeAmount = user.stakeAmount;
                uint256 profitAmount = getUserProfit(_pid, true);

                user.stakeAmount = 0;
                user.balance = 0;
                pool.totalStakeAmount = pool.totalStakeAmount.sub(stakeAmount);

                pool.poolToken.safeTransfer(address(msg.sender), stakeAmount);

                if (profitAmount > 0) {
                    safeZooTransfer(address(msg.sender), profitAmount);
                }

                emit CancelStake(msg.sender, _pid, msg.value);
            }
        }
    }

    function withdraw(uint256 _pid) public {
        uint256 profitAmount = getUserProfit(_pid, true);
        require(profitAmount > 0,"profit must gt 0");
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.pledgeTime = block.timestamp;
        user.balance = 0;
        safeZooTransfer(address(msg.sender), profitAmount);
        emit Withdraw(msg.sender, _pid, profitAmount);
    }


    function getUserProfit(uint256 _pid, bool _withBalance) private view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 profit = 0;

        if (user.stakeAmount > 0) {
            uint256 totalStakeAmount = pool.totalStakeAmount;
            if (totalStakeAmount > 0) {
                uint256 time = block.timestamp;
                uint256 hour = time.sub(user.pledgeTime).div(3600);

                if (hour >= 1) {
                    uint256 rate = user.stakeAmount.mul(1e18).div(totalStakeAmount);
                    uint256 profitAmount = rate.mul(pool.zooRewardRate).mul(hour).div(1e18);
                    if (profitAmount > 0) {
                        profit = profit.add(profitAmount);
                    }
                }
            }
        }

        if (_withBalance) {
            profit = profit.add(user.balance);
        }

        return profit;
    }

    function getProfit(uint256 _pid) public view returns (uint256) {
        uint256 profit = getUserProfit(_pid, true);
        return profit;
    }

    function getPoolStake(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.totalStakeAmount;
    }

    function getUserStake(uint256 _pid) public view returns (uint256){
        UserInfo storage user = userInfo[_pid][msg.sender];
        return user.stakeAmount;
    }

    function safeZooTransfer(address _to, uint256 _amount) internal {
        uint256 zooBalance = zoo.balanceOf(address(this));
        if (_amount > zooBalance) {
            zoo.transfer(_to, zooBalance);
        } else {
            zoo.transfer(_to, _amount);
        }
    }
}