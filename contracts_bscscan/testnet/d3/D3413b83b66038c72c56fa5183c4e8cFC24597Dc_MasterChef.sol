// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./TACHI.sol";

// MasterChef is the master of Egg. He can make Egg and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once EGG is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of EGGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accEggPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accEggPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. EGGs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that EGGs distribution occurs.
        uint256 accEggPerShare;   // Accumulated EGGs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // Block from which rewards will start.
    uint256 public rewardStartBlock;
    // Block till which rewards reduction will happen
    uint256 public rewardEndBlock;
    // The EGG TOKEN!
    tachiToken public TACHI;
    // Dev address.
    address public devaddr;
    // EGG tokens created per block.
    uint256 public TACHIPerBlock;
    // Bonus muliplier for early TACHI makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // consistency of 2 rewards per block after rewardEndBlock
    uint256 baseValue = 2000000000000000000;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        tachiToken _TACHI,
        address _devaddr,
        address _feeAddress,
        uint256 _TACHIPerBlock,
        uint256 _rewardStartBlock,
        uint256 _rewardEndBlock
    ) public {
        TACHI = _TACHI;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        TACHIPerBlock = _TACHIPerBlock;
        rewardStartBlock = _rewardStartBlock;
        rewardEndBlock = _rewardEndBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, address _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "Max deposit fee = 4%");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > rewardStartBlock ? block.number : rewardStartBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accEggPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's EGG allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "Max deposit fee = 4%");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending EGGs on frontend.
    function pendingEgg(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accEggPerShare = pool.accEggPerShare;
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {

            if (block.number >= rewardEndBlock) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 TACHIReward = multiplier.mul(baseValue).mul(pool.allocPoint).div(totalAllocPoint);
                accEggPerShare = accEggPerShare.add(TACHIReward.mul(1e12).div(lpSupply));
            } else {
                uint256 numerator = rewardEndBlock.sub(block.number);
                uint256 denominator = rewardEndBlock.sub(rewardStartBlock);
                uint256 newRewardPerBlock = numerator.mul(TACHIPerBlock).div(denominator);
                if (newRewardPerBlock <= baseValue) { 
                    newRewardPerBlock = baseValue; 
                }
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 TACHIReward = multiplier.mul(newRewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
                accEggPerShare = accEggPerShare.add(TACHIReward.mul(1e12).div(lpSupply));
            }
        }
        return user.amount.mul(accEggPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        if (block.number >= rewardEndBlock) {
            if (TACHIPerBlock != baseValue) {
                TACHIPerBlock = baseValue;
            }
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 TACHIReward = multiplier.mul(TACHIPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            TACHI.mint(devaddr, TACHIReward.div(20));
            TACHI.mint(address(this), TACHIReward);
            pool.accEggPerShare = pool.accEggPerShare.add(TACHIReward.mul(1e12).div(lpSupply));
            pool.lastRewardBlock = block.number;
        } else {
            uint256 numerator = rewardEndBlock.sub(block.number);
            uint256 denominator = rewardEndBlock.sub(rewardStartBlock);
            uint256 newRewardPerBlock = numerator.mul(TACHIPerBlock).div(denominator);
            if (newRewardPerBlock <= baseValue) {
                TACHIPerBlock = baseValue;
            } else {
                TACHIPerBlock = newRewardPerBlock;
            }
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 TACHIReward = multiplier.mul(TACHIPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            TACHI.mint(devaddr, TACHIReward.div(20));
            TACHI.mint(address(this), TACHIReward);
            pool.accEggPerShare = pool.accEggPerShare.add(TACHIReward.mul(1e12).div(lpSupply));
            pool.lastRewardBlock = block.number;
        }
    }

    // Deposit LP tokens to MasterChef for EGG allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accEggPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeEggTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            IERC20(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                IERC20(pool.lpToken).safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accEggPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accEggPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeEggTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20(pool.lpToken).safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accEggPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe TACHI transfer function, just in case if rounding error causes pool to not have enough EGGs.
    function safeEggTransfer(address _to, uint256 _amount) internal {
        uint256 TACHIBal = TACHI.balanceOf(address(this));
        if (_amount > TACHIBal) {
            TACHI.transfer(_to, TACHIBal);
        } else {
            TACHI.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

}