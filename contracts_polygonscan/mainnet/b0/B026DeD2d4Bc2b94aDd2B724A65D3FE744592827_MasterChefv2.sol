// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./PawToken.sol";
import "./IRewardLocker.sol";

// MasterChef is the master of PAW. He can make PAW and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PAW is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
// For any questions contact @macatkevin on Telegram
contract MasterChefv2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;           // How many LP tokens the user has provided.
        uint256 lastPawPerShare;  // Paw per share on last update
        uint256 unclaimed;        // Unclaimed reward in Paw.
        // pending reward = user.unclaimed + (user.amount * (pool.accPawPerShare - user.lastPawPerShare)
        //
        // Whenever a user deposits or withdraws Staking tokens to a pool. Here's what happens:
        //   1. The pool's `accPawPerShare` (and `lastPawBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `lastPawPerShare` gets updated.
        //   4. User's `amount` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PAW to distribute per block.
        uint256 totalDeposited;   // The total deposited by users
        uint256 lastRewardBlock;  // Last block number that PAW distribution occurs.
        uint256 accPawPerShare;   // Accumulated PAW per share, times 1e18. See below.
    }

    // The PAW TOKEN!
    PawToken public immutable paw;
    address public pawTransferOwner;
    address public devAddress;

    // Contract for locking reward
    IRewardLocker public immutable rewardLocker;

    // PAW tokens created per block.
    uint256 public pawPerBlock = 8 ether;
    uint256 public constant MAX_EMISSION_RATE = 1000 ether; // Safety check

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    uint256 public constant MAX_ALLOC_POINT = 100000; // Safety check
    // The block number when PAW mining starts.
    uint256 public immutable startBlock;

    event Add(address indexed user, uint256 allocPoint, IERC20 indexed token, bool massUpdatePools);
    event Set(address indexed user, uint256 pid, uint256 allocPoint);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, bool harvest);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, bool harvest);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event HarvestMultiple(address indexed user, uint256[] _pids, uint256 amount);
    event HarvestAll(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 pawPerBlock);
    event SetPawTransferOwner(address indexed user, address indexed pawTransferOwner);
    event TransferPawOwnership(address indexed user, address indexed newOwner);

    constructor(
        PawToken _paw,
        uint256 _startBlock,
        IRewardLocker _rewardLocker,
        address _devAddress,
        address _pawTransferOwner
    ) public {
        require(_devAddress != address(0), "!nonzero");
        paw = _paw;
        startBlock = _startBlock;

        rewardLocker = _rewardLocker;
        devAddress = _devAddress;
        pawTransferOwner = _pawTransferOwner;
        
        IERC20(_paw).safeApprove(address(_rewardLocker), uint256(0));
        IERC20(_paw).safeIncreaseAllowance(
            address(_rewardLocker),
            uint256(-1)
        );
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
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _massUpdatePools) external onlyOwner nonDuplicated(_lpToken) {
        require(_allocPoint <= MAX_ALLOC_POINT, "!overmax");
        if (_massUpdatePools) {
            massUpdatePools(); // This ensures that massUpdatePools will not exceed gas limit
        }
        _lpToken.balanceOf(address(this)); // Check to make sure it's a token
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            totalDeposited: 0,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPawPerShare: 0
        }));
        emit Add(msg.sender, _allocPoint, _lpToken, _massUpdatePools);
    }

    // Update the given pool's PAW allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        require(_allocPoint <= MAX_ALLOC_POINT, "!overmax");
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        emit Set(msg.sender, _pid, _allocPoint);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending PAW on frontend.
    function pendingPaw(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPawPerShare = pool.accPawPerShare;
        if (block.number > pool.lastRewardBlock && pool.totalDeposited != 0 && totalAllocPoint != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 pawReward = multiplier.mul(pawPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPawPerShare = accPawPerShare.add(pawReward.mul(1e18).div(pool.totalDeposited));
        }
        return user.amount.mul(accPawPerShare.sub(user.lastPawPerShare)).div(1e18).add(user.unclaimed);
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
        if (pool.totalDeposited == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 pawReward = multiplier.mul(pawPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        paw.mint(devAddress, pawReward.div(50)); // 2%
        paw.mint(address(this), pawReward);
        pool.accPawPerShare = pool.accPawPerShare.add(pawReward.mul(1e18).div(pool.totalDeposited));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for PAW allocation.
    function deposit(uint256 _pid, uint256 _amount, bool _shouldHarvest) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updateUserReward(_pid, _shouldHarvest);
        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));
            _amount = afterDeposit.sub(beforeDeposit);

            user.amount = user.amount.add(_amount);
            pool.totalDeposited = pool.totalDeposited.add(_amount);
        }
        emit Deposit(msg.sender, _pid, _amount, _shouldHarvest);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount, bool _shouldHarvest) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        _updateUserReward(_pid, _shouldHarvest);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalDeposited = pool.totalDeposited.sub(_amount);
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount, _shouldHarvest);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.lastPawPerShare = 0;
        user.unclaimed = 0;
        pool.totalDeposited = pool.totalDeposited.sub(amount);
        pool.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
    // Update the rewards of caller, and harvests if needed
    function _updateUserReward(uint256 _pid, bool _shouldHarvest) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount == 0) {
            user.lastPawPerShare = pool.accPawPerShare;
        }
        uint256 pending = user.amount.mul(pool.accPawPerShare.sub(user.lastPawPerShare)).div(1e18).add(user.unclaimed);
        user.unclaimed = _shouldHarvest ? 0 : pending;
        if (_shouldHarvest && pending > 0) {
            _lockReward(msg.sender, pending);
            emit Harvest(msg.sender, _pid, pending);
        }
        user.lastPawPerShare = pool.accPawPerShare;
    }
    
    // Harvest one pool
    function harvest(uint256 _pid) external nonReentrant {
        _updateUserReward(_pid, true);
    }
    
    // Harvest specific pools into one vest
    function harvestMultiple(uint256[] calldata _pids) external nonReentrant {
        uint256 pending = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            updatePool(_pids[i]);
            PoolInfo storage pool = poolInfo[_pids[i]];
            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            if (user.amount == 0) {
                user.lastPawPerShare = pool.accPawPerShare;
            }
            pending = pending.add(user.amount.mul(pool.accPawPerShare.sub(user.lastPawPerShare)).div(1e18).add(user.unclaimed));
            user.unclaimed = 0;
            user.lastPawPerShare = pool.accPawPerShare;
        }
        if (pending > 0) {
            _lockReward(msg.sender, pending);
        }
        emit HarvestMultiple(msg.sender, _pids, pending);
    }
    
    // Harvest all into one vest. Will probably not be used
    // Can fail if pool length is too big due to massUpdatePools()
    function harvestAll() external nonReentrant {
        massUpdatePools();
        uint256 pending = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][msg.sender];
            if (user.amount == 0) {
                user.lastPawPerShare = pool.accPawPerShare;
            }
            pending = pending.add(user.amount.mul(pool.accPawPerShare.sub(user.lastPawPerShare)).div(1e18).add(user.unclaimed));
            user.unclaimed = 0;
            user.lastPawPerShare = pool.accPawPerShare;
        }
        if (pending > 0) {
            _lockReward(msg.sender, pending);
        }
        emit HarvestAll(msg.sender, pending);
    }

    /**
    * @dev Call locker contract to lock rewards
    */
    function _lockReward(address _account, uint256 _amount) internal {
        uint256 pawBal = paw.balanceOf(address(this));
        rewardLocker.lock(paw, _account, _amount > pawBal ? pawBal : _amount);
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "!nonzero");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }
    
    // Should never fail as long as massUpdatePools is called during add
    function updateEmissionRate(uint256 _pawPerBlock) external onlyOwner {
        require(_pawPerBlock <= MAX_EMISSION_RATE, "!overmax");
        massUpdatePools();
        pawPerBlock = _pawPerBlock;
        emit UpdateEmissionRate(msg.sender, _pawPerBlock);
    }

    // Update paw transfer owner. Can only be called by existing pawTransferOwner
    function setPawTransferOwner(address _pawTransferOwner) external {
        require(msg.sender == pawTransferOwner);
        pawTransferOwner = _pawTransferOwner;
        emit SetPawTransferOwner(msg.sender, _pawTransferOwner);
    }

    /**
     * @dev DUE TO THIS CODE THIS CONTRACT MUST BE BEHIND A TIMELOCK (Ideally 7)
     * THIS FUNCTION EXISTS ONLY IF THERE IS AN ISSUE WITH THIS CONTRACT 
     * AND TOKEN MIGRATION MUST HAPPEN
     */
    function transferPawOwnership(address _newOwner) external {
        require(msg.sender == pawTransferOwner);
        paw.transferOwnership(_newOwner);
        emit TransferPawOwnership(msg.sender, _newOwner);
    }
}