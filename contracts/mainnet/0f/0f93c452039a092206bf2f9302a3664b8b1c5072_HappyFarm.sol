// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IHPFToken.sol";

// HappyFarm is the master of HPF. He can make HPF and he is a fair cat.
//
// Note that it's ownable and the owner wields tremendous power. The owner will set
// the governance contract and will burn its keys once HPF is sufficiently
// distributed.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract HappyFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of HPFs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHPFPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accHPFPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. HPFs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that HPFs distribution occurs.
        uint256 accHPFPerShare; // Accumulated HPFs per share, times 1e12. See below.
    }

    // The HPF TOKEN!
    IHPFToken public HPF;
    // Dev address.
    address public devaddr;
    // Block number when bonus HPF period ends.
    uint256 public bonusEndBlock;
    // HPF tokens created per block.
    uint256 public HPFPerBlock;
    // Bonus muliplier for early HPF makers.
    uint256 public constant BONUS_MULTIPLIER = 12;
    // The governance contract;
    address public governance;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when HPF mining starts.
    uint256 public startBlock;
    // The block number when HPF mining ends.
    uint256 public endBlock;

    // The block number when dev can receive it's fee (1 year vesting)
    // Date and time (GMT): 1 year after deploy
    uint256 public devFeeUnlockTime;
    // If dev has requested its fee
    bool public devFeeDelivered;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IHPFToken _token,
        address _devaddr,
        uint256 _HPFPerBlock, // 100000000000000000000
        uint256 _startBlock, // 10902300 , https://etherscan.io/block/countdown/10902300
        uint256 _bonusEndBlock, //10930000, https://etherscan.io/block/countdown/10930000
        uint256 _endBlock //11240000 (around 50 days of farming), https://etherscan.io/block/countdown/11240000
    ) {
        HPF = _token;
        devaddr = _devaddr;
        HPFPerBlock = _HPFPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        devFeeUnlockTime = block.timestamp + 365 * 1 days;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    modifier onlyOwnerOrGovernance() {
        require(owner() == _msgSender() || governance == _msgSender(), "Caller is not the owner, neither governance");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwnerOrGovernance {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accHPFPerShare: 0
        }));
    }

    // Update the given pool's HPF allocation point. Can only be called by the owner or governance contract.
    function updateAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwnerOrGovernance {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set governance contract. Can only be called by the owner or governance contract.
    function setGovernance(address _governance, bytes memory _setupData) public onlyOwnerOrGovernance {
        governance = _governance;
        (bool success,) = governance.call(_setupData);
        require(success, "setGovernance: failed");
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {

        //HPF minting ocurrs only until endBLock
        if(_to > endBlock){
            _to = endBlock;
        }

        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending HPFs on frontend.
    function pendingHPF(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accHPFPerShare = pool.accHPFPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 HPFReward = multiplier.mul(HPFPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accHPFPerShare = accHPFPerShare.add(HPFReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accHPFPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 HPFReward = multiplier.mul(HPFPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // Dev will have it's 0.5% fee after 1 year, this not necessary
        //HPF.mint(devaddr, HPFReward.div(100));
        HPF.mint(address(this), HPFReward);
        pool.accHPFPerShare = pool.accHPFPerShare.add(HPFReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to HappyFarm for HPF allocation.
    // You can harvest by calling deposit(_pid,0)

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accHPFPerShare).div(1e12).sub(user.rewardDebt);
            safeHPFTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accHPFPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from HappyFarm.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not enough");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accHPFPerShare).div(1e12).sub(user.rewardDebt);
        safeHPFTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accHPFPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe HPF transfer function, just in case if rounding error causes pool to not have enough HPFs.
    function safeHPFTransfer(address _to, uint256 _amount) internal {
        uint256 HPFBal = HPF.balanceOf(address(this));
        if (_amount > HPFBal) {
            HPF.transfer(_to, HPFBal);
        } else {
            HPF.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
    // give dev team its fee. This can ony be called after one year,
    // it's 0.5%

    function devFee() public {
        require(block.timestamp >= devFeeUnlockTime, "devFee: wait until unlock time");
        require(!devFeeDelivered, "devFee: can only be called once");
        HPF.mint(devaddr, HPF.totalSupply().div(200));
        devFeeDelivered=true;
    }
}