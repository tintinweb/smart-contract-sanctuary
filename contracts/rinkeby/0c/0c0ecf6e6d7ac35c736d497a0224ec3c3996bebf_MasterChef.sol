// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./TARGToken.sol";

// MasterChef is the master of Targ. He can make Targ and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once TARG is sufficiently
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
        // We do some fancy math here. Basically, any point in time, the amount of TARGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTargPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTargPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256 startTimeStamp;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. TARGs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that TARGs distribution occurs.
        uint256 accTargPerShare;   // Accumulated TARGs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The TARG TOKEN!
    TArgToken public targ;
    // Dev address.
    address public devaddr;
    // TARG tokens created per block.
    uint256 public targPerBlock;
    uint256 public startTime;
    uint256 public unitTime;
    // Bonus muliplier for early targ makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee addresses
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when TARG mining starts.
    uint256 public startBlock;
    uint256 public minStakingTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        TArgToken _targ,
        address _devaddr,
        address _feeAddress,
        uint256 _startBlock,
        uint256 _minStakingTime
    ) public {
        targ = _targ;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        targPerBlock = 380517503805175038;
        startBlock = _startBlock;
        startTime = now;
        unitTime = 5 minutes;
        minStakingTime = _minStakingTime;
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
            accTargPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's TARG allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending TARGs on frontend.
    function pendingTarg(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTargPerShare = pool.accTargPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            
            uint256 calcTargPerBlock = targPerBlock;
            uint256 secondYear = startTime + unitTime;
            uint256 thirdYear = startTime + unitTime.mul(2);
            uint256 forthYear = startTime + unitTime.mul(3);
            
            if (now < secondYear) {
                calcTargPerBlock = targPerBlock;
            } else if (now < thirdYear) {
                calcTargPerBlock = targPerBlock.div(2);
            } else if (now < forthYear) {
                calcTargPerBlock = targPerBlock.div(4);
            } else {
                calcTargPerBlock = targPerBlock.div(8);
            }
            
            uint256 targReward = multiplier.mul(calcTargPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTargPerShare = accTargPerShare.add(targReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTargPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 calcTargPerBlock = targPerBlock;
        uint256 secondYear = startTime + unitTime;
        uint256 thirdYear = startTime + unitTime.mul(2);
        uint256 forthYear = startTime + unitTime.mul(3);
        
        if (now < secondYear) {
            calcTargPerBlock = targPerBlock;
        } else if (now < thirdYear) {
            calcTargPerBlock = targPerBlock.div(2);
        } else if (now < forthYear) {
            calcTargPerBlock = targPerBlock.div(4);
        } else {
            calcTargPerBlock = targPerBlock.div(8);
        }

        uint256 targReward = multiplier.mul(calcTargPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        targ.mint(devaddr, targReward.div(10));
        targ.mint(address(this), targReward.div(10).mul(90));
        pool.accTargPerShare = pool.accTargPerShare.add(targReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for TARG allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.startTimeStamp = now;
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTargPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTargTransfer(msg.sender, pending);
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
        user.rewardDebt = user.amount.mul(pool.accTargPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        
        uint256 stakingTime = now - user.startTimeStamp;
        
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accTargPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if (stakingTime >= minStakingTime) {
                safeTargTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (stakingTime >= minStakingTime) {
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            } else {
                uint256 feeAmount = _amount.mul(3).div(100);
                uint256 useAmount = _amount.mul(97).div(100);
                pool.lpToken.safeTransfer(address(this), feeAmount);
                pool.lpToken.safeTransfer(address(msg.sender), useAmount);                
            }
        }
        user.rewardDebt = user.amount.mul(pool.accTargPerShare).div(1e12);
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

    // Safe targ transfer function, just in case if rounding error causes pool to not have enough TARGs.
    function safeTargTransfer(address _to, uint256 _amount) internal {
        uint256 targBal = targ.balanceOf(address(this));
        if (_amount > targBal) {
            targ.transfer(_to, targBal);
        } else {
            targ.transfer(_to, _amount);
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

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _targPerBlock) public onlyOwner {
        massUpdatePools();
        targPerBlock = _targPerBlock;
    }
    
    function getCurrentPerBlock() public view returns (uint256) {
        uint256 calcTargPerBlock = targPerBlock;
        uint256 secondYear = startTime + unitTime;
        uint256 thirdYear = startTime + unitTime.mul(2);
        uint256 forthYear = startTime + unitTime.mul(3);
        
        if (now < secondYear) {
            calcTargPerBlock = targPerBlock;
        } else if (now < thirdYear) {
            calcTargPerBlock = targPerBlock.div(2);
        } else if (now < forthYear) {
            calcTargPerBlock = targPerBlock.div(4);
        } else {
            calcTargPerBlock = targPerBlock.div(8);
        }

        return calcTargPerBlock;
    }

    function setMinStakingTime(uint256 _stakingTime) public onlyOwner{
        minStakingTime = _stakingTime;
    }
    
    function getMinStakingTime() public view returns (uint256) {
        return minStakingTime;
    }
}