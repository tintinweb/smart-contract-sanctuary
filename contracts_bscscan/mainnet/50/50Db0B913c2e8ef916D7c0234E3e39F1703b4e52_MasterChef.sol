// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";

interface IMICRO {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address recipient, uint256 amount) external;
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// MasterChef is the master of MICRO. He can make MICRO and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MICRO is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of MICROs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMICROPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMICROPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. MICROs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that MICROs distribution occurs.
        uint256 accMICROPerShare;   // Accumulated MICROs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The MICRO TOKEN!
    IMICRO public micro;
    // Dev address.
    address public devaddr;
    // MICRO tokens created per block.
    uint256 public microPerBlock;
    // Bonus muliplier for early micro makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Liquidity fee address
    address public liqAddress;
    // Default fee for liquididy: 20%
    uint16 liqRate = 20;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MICRO mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IMICRO _micro,
        address _devaddr,
        address _feeAddress,
        address _liqAddress,
        uint256 _microPerBlock,
        uint256 _startBlock
    ) public {
        micro = _micro;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        liqAddress = _liqAddress;
        microPerBlock = _microPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accMICROPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    function approve(address _spender, uint256 _amount) public onlyOwner returns(bool){
        micro.approve(_spender, _amount);
        return true;
    }

    // Update the given pool's MICRO allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Update the given pool's reward start block number. Can only be called by the owner.
    function updatePoolLastRewardBlock(uint256 _pid, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo[_pid].lastRewardBlock = lastRewardBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending MICROs on frontend.
    function pendingMICRO(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMICROPerShare = pool.accMICROPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 microReward = multiplier.mul(microPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMICROPerShare = accMICROPerShare.add(microReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMICROPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
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
        if (block.number <= startBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 microReward = multiplier.mul(microPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        micro.mint(devaddr, microReward.div(10));
        micro.mint(address(this), microReward);
        pool.accMICROPerShare = pool.accMICROPerShare.add(microReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for MICRO allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMICROPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 liqFeeAmount = pending.mul(liqRate).div(100);
                uint256 rewardAmount = pending.sub(liqFeeAmount);
                require(pending == liqFeeAmount + rewardAmount, "Micro::transfer: Liq value invalid");

                safeMICROTransfer(msg.sender, liqFeeAmount);
                safeMICROTransfer(liqAddress, rewardAmount);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMICROPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMICROPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeMICROTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMICROPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe micro transfer function, just in case if rounding error causes pool to not have enough MICROs.
    function safeMICROTransfer(address _to, uint256 _amount) internal {
        uint256 microBal = micro.balanceOf(address(this));
        if (_amount > microBal) {
            micro.transfer(_to, microBal);
        } else {
            micro.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function updateDevAddress(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Update fee address by the previous fee address.
    function updateFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    // Update liquidity fee address by the previous liquidity fee address.
    function updateLiqAddress(address _liqAddress) public{
        require(msg.sender == liqAddress, "setLiqAddress: FORBIDDEN");
        liqAddress = _liqAddress;
    }

    // Update liq rate by the owner.
    function updateLiqRate(uint16 _liqRate) public onlyOwner {
        liqRate = _liqRate;
    }

    //Update perBlock amount
    function updateEmissionRate(uint256 _microPerBlock) public onlyOwner {
        microPerBlock = _microPerBlock;
    }

    //Update start reward block
    function updateStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }
}