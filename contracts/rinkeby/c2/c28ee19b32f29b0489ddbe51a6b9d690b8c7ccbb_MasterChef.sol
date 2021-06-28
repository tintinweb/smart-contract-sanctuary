// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeBEP20.sol";
import "./McfToken.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy PancakeSwap to CakeSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to PancakeSwap LP tokens.
    // CakeSwap must mint EXACTLY the same amount of CakeSwap LP tokens or
    // else something bad will happen. Traditional PancakeSwap does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of Mcf. He can make Mcf and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MCF is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of MCFs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMcfPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMcfPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. MCFs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that MCFs distribution occurs.
        uint256 accMcfPerShare;   // Accumulated MCFs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    struct LockedInfo {
        uint256 lockedAmount;   // locked MCF amount
        uint256 unlockAmountPerMonth; // user can unlock as much as this amount per a month
        uint unlockedCount;
    }

    // The MCF TOKEN!
    McfToken public mcf;
    // Dev address.
    address public devaddr;
    // Deposit Fee address
    address public feeAddress;
    // MCF tokens created per block.
    uint256 public mcfPerBlock;
    // Bonus muliplier for early mcf makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => LockedInfo) public lockedInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MCF mining starts.
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public startUnlockTime;      // start to unlock since this time (after 3 months)
    uint256 public unlockDuration = 10;  // unlockable 1/10 for each month during 10 months

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);

    uint256 private _currentBlock;

    constructor(
        McfToken _mcf,
        address _devaddr,
        address _feeAddress,
        uint256 _mcfPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) {
        mcf = _mcf;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        mcfPerBlock = _mcfPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        
        // after 3 months since staking start time (Polygon block time: 2 seconds)
        startUnlockTime = (startBlock - _currentBlock) * 2 + 3 * 30 days; 
    }

    function setCurrentBlock(uint256 number) external {
        _currentBlock = number;
    }
    
    function currentBlock() external view returns(uint256){
        return _currentBlock;
    }
    
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = _currentBlock > startBlock ? _currentBlock : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accMcfPerShare : 0,
            depositFeeBP : _depositFeeBP
        }));
    }

    // Update the given pool's MCF allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if(_to > endBlock) {
            return endBlock.sub(_from).mul(BONUS_MULTIPLIER);
        }
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending MCFs on frontend.
    function pendingMcf(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMcfPerShare = pool.accMcfPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_currentBlock > pool.lastRewardBlock && pool.lastRewardBlock < endBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, _currentBlock);
            uint256 mcfReward = multiplier.mul(mcfPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMcfPerShare = accMcfPerShare.add(mcfReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMcfPerShare).div(1e12).sub(user.rewardDebt);
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
        if (_currentBlock <= pool.lastRewardBlock || pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = _currentBlock;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, _currentBlock);
        uint256 mcfReward = multiplier.mul(mcfPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        mcf.mint(devaddr, mcfReward.div(0));
        mcf.mint(address(this), mcfReward);
        pool.accMcfPerShare = pool.accMcfPerShare.add(mcfReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = _currentBlock;
    }

    // Deposit LP tokens to MasterChef for MCF allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMcfPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                LockedInfo storage lockedUser = lockedInfo[msg.sender];
                // 50% is locked and 50% can be used instantly
                if(lockedUser.unlockedCount < unlockDuration) {
                    uint256 _lockAmount = pending.div(2);
                    lockedUser.lockedAmount = lockedUser.lockedAmount.add(_lockAmount);
                    lockedUser.unlockAmountPerMonth = lockedUser.lockedAmount / (unlockDuration - lockedUser.unlockedCount);

                    safeMcfTransfer(msg.sender, pending.div(2));
                } else {
                    safeMcfTransfer(msg.sender, pending);
                }
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMcfPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMcfPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            LockedInfo storage lockedUser = lockedInfo[msg.sender];
            // 50% is locked and 50% can be used instantly
            if(lockedUser.unlockedCount < unlockDuration) {
                uint256 _lockAmount = pending.div(2);
                lockedUser.lockedAmount = lockedUser.lockedAmount.add(_lockAmount);
                lockedUser.unlockAmountPerMonth = lockedUser.lockedAmount / (unlockDuration - lockedUser.unlockedCount);
                
                safeMcfTransfer(msg.sender, pending.div(2));
            } else {
                safeMcfTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMcfPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function unlockAvailable() public view returns(uint256) {
        if(block.timestamp < startUnlockTime) return 0;

        LockedInfo storage user = lockedInfo[msg.sender];
        if(user.lockedAmount <= 0) return 0;

        uint256 pastMonth = (block.timestamp - startUnlockTime) / 30 days;
        if(pastMonth <= user.unlockedCount) return 0;

        if(pastMonth >= 10) {
            return user.lockedAmount;
        } else {
            uint256 available = (pastMonth - user.unlockedCount) * user.unlockAmountPerMonth;
            return available;
        }
    }

    function unlock() external nonReentrant {
        require(block.timestamp > startUnlockTime, "No available to unlock");
        
        uint256 _available = unlockAvailable();
        require(_available > 0, "no unlockable amount");
        
        safeMcfTransfer(msg.sender, _available);

        LockedInfo storage user = lockedInfo[msg.sender];
        user.lockedAmount = user.lockedAmount.sub(_available);
        user.unlockedCount = (block.timestamp - startUnlockTime) / 30 days;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe mcf transfer function, just in case if rounding error causes pool to not have enough MCFs.
    function safeMcfTransfer(address _to, uint256 _amount) internal {
        uint256 mcfBal = mcf.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > mcfBal) {
            transferSuccess = mcf.transfer(_to, mcfBal);
        } else {
            transferSuccess = mcf.transfer(_to, _amount);
        }
        require(transferSuccess, "safeMcfTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
    
    //add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _mcfPerBlock) external onlyOwner {
        massUpdatePools();
        mcfPerBlock = _mcfPerBlock;
        emit UpdateEmissionRate(msg.sender, _mcfPerBlock);
    }

    function updateStartUnlockTime(uint256 _time) external onlyOwner {
        require(block.timestamp < startUnlockTime);
        require(_time > block.timestamp, "time should be greater than current timestamp");
        startUnlockTime = _time;
    }

    function set(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(_currentBlock < startBlock, "You can not change after start staking");
        require(_currentBlock < _startBlock && _startBlock < _endBlock, "Invalid params");

        startBlock = _startBlock;
        endBlock = _endBlock;
        startUnlockTime = (startBlock - _currentBlock) * 2 + 3 * 30 days; 
    }
}