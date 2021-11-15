// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "interfaces/IChildFarm.sol";
import "interfaces/IRewardManager.sol";

// Farm is the major distributor of YGN to the community. He gives juicy YGN rewards as per user's stake.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once YGN is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Farm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of YGNs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accYGNPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accYGNPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool.YGNs to distribute per block.
        uint256 lastRewardBlock; // Last block number that YGNs distribution occurs.
        uint256 accYGNPerShare; // Accumulated YGNs per share, times 1e12. See below.
        uint16 withdrawalFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        IChildFarm childFarm; //Address of the child farm.
        uint256 childPoolId; //id of the pool in the child farm (associated with our pool)
        uint16 childPoolFeeBP; // Deposit fee for child pool in basis points,
        IERC20 childFarmToken; //child farm main token
    }

    // The YGN TOKEN!
    IERC20 public ygn;
    // Block number when bonus YGN period ends.
    uint256 public bonusEndBlock;
    // YGN tokens created per block.
    uint256 public ygnPerBlock;
    // Deposit Fee address
    address public feeAddress;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;
    // Max deposit fee: 10%.
    uint16 public constant MAXIMUM_WITHDRAWAL_FEE_BP = 1000;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // Bonus muliplier for early ygn makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(address => mapping(address => bool)) public whiteListedHandlers;

    mapping(address => bool) public activeLpTokens;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when YGN mining starts.
    uint256 public startBlock;

    //Trigger for RewardManager mode
    bool public isRewardManagerEnabled;

    address public rewardManager;

    event PoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken,
        uint16 withdrawalFeeBP,
        uint256 harvestInterval,
        IChildFarm indexed childFarm,
        uint256 childPoolId,
        uint16 childPoolFeeBP,
        IERC20 childFarmToken
    );
    event UpdatedPoolAlloc(
        uint256 indexed pid,
        uint256 allocPoint,
        uint16 withdrawalFeeBP,
        uint256 harvestInterval
    );
    event UpdatedPoolAllocPoint(uint256 indexed pid, uint256 allocPoint);
    event UpdatedPoolWithdrawalFeeBP(uint256 indexed pid, uint256 withdrawalFeeBP);
    event UpdatedPoolHarvestInterval(uint256 indexed pid, uint256 harvestInterval);
    event UpdatedChildPoolFeeBP(uint256 indexed pid, uint256 childPoolFeeBP);
    event UpdatedChildPoolFarmToken(uint256 indexed pid, IERC20 childFarmToken);
    event AddedChildFarm(
        uint256 indexed pid,
        IChildFarm indexed childFarm,
        uint256 childPoolId,
        uint16 childPoolFeeBP,
        IERC20 childFarmToken
    );
    event UpdatedChildFarm(
        uint256 indexed pid,
        IChildFarm indexed childFarm,
        uint256 childPoolId,
        uint16 childPoolFeeBP,
        IERC20 childFarmToken
    );
    event RemovedChildFarm(uint256 indexed pid, IChildFarm indexed childFarm);
    event PoolUpdated(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 lpSupply,
        uint256 accYGNPerShare
    );
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed _devAddress);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event BonusMultiplierUpdated(uint256 _bonusMultiplier);
    event BlockRateUpdated(uint256 _blockRate);
    event UserWhitelisted(address _primaryUser, address _whitelistedUser);
    event UserBlacklisted(address _primaryUser, address _blacklistedUser);

    constructor(
        IERC20 _ygn,
        uint256 _ygnPerBlock,
        address _feeAddress,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        ygn = _ygn;
        ygnPerBlock = _ygnPerBlock;
        feeAddress = _feeAddress;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        isRewardManagerEnabled = false;
        rewardManager = address(0);
    }

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    function updateBonusMultiplier(uint256 multiplierNumber) external onlyOwner {
        massUpdatePools();
        BONUS_MULTIPLIER = multiplierNumber;
        emit BonusMultiplierUpdated(BONUS_MULTIPLIER);
    }

    function updateBlockRate(uint256 _ygnPerBlock) external onlyOwner {
        massUpdatePools();
        ygnPerBlock = _ygnPerBlock;
        emit BlockRateUpdated(ygnPerBlock);
    }

    function updateRewardManagerMode(bool _isRewardManagerEnabled) external onlyOwner {
        massUpdatePools();
        isRewardManagerEnabled = _isRewardManagerEnabled;
    }

    function updateRewardManager(address _rewardManager) external onlyOwner {
        require(_rewardManager != address(0), "Reward Manager address is zero");
        massUpdatePools();
        rewardManager = _rewardManager;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getLpTokenValue(uint256 _pid) external view validatePoolByPid(_pid) returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply;
        if (address(pool.childFarm) != address(0)) {
            (uint256 amount, ) = pool.childFarm.userInfo(pool.childPoolId, address(this));
            lpSupply = amount;
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
        return lpSupply;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _withdrawalFeeBP,
        uint256 _harvestInterval,
        IChildFarm _childFarm, //enter zero address if normal pool
        uint256 _childPoolId, //enter 0 if no child pool
        uint16 _childPoolFeeBP, //enter 0 if no child pool,
        IERC20 _childFarmToken, //child farm main token, enter zero address if normal pool
        bool _withUpdate
    ) external onlyOwner nonReentrant {
        require(
            _withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE_BP,
            "add: invalid deposit fee basis points"
        );
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        require(activeLpTokens[address(_lpToken)] == false, "Reward Token already added");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accYGNPerShare: 0,
                withdrawalFeeBP: _withdrawalFeeBP,
                harvestInterval: _harvestInterval,
                childFarm: _childFarm,
                childPoolId: _childPoolId,
                childPoolFeeBP: _childPoolFeeBP,
                childFarmToken: _childFarmToken
            })
        );

        activeLpTokens[address(_lpToken)] = true;

        emit PoolAddition(
            poolInfo.length.sub(1),
            _allocPoint,
            _lpToken,
            _withdrawalFeeBP,
            _harvestInterval,
            _childFarm,
            _childPoolId,
            _childPoolFeeBP,
            _childFarmToken
        );
    }

    function updatePoolAllocPoint(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        emit UpdatedPoolAllocPoint(_pid, _allocPoint);
    }

    function updatePoolWithdrawalFeeBP(
        uint256 _pid,
        uint16 _withdrawalFeeBP,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        require(
            _withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE_BP,
            "set: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        poolInfo[_pid].withdrawalFeeBP = _withdrawalFeeBP;
        emit UpdatedPoolWithdrawalFeeBP(_pid, _withdrawalFeeBP);
    }

    function updatePoolHarvestInterval(
        uint256 _pid,
        uint256 _harvestInterval,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        poolInfo[_pid].harvestInterval = _harvestInterval;
        emit UpdatedPoolHarvestInterval(_pid, _harvestInterval);
    }

    // Update the given pool's YGN allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _withdrawalFeeBP,
        uint256 _harvestInterval,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        require(
            _withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE_BP,
            "set: invalid deposit fee basis points"
        );
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].withdrawalFeeBP = _withdrawalFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;

        emit UpdatedPoolAlloc(_pid, _allocPoint, _withdrawalFeeBP, _harvestInterval);
    }

    // Links a child farm to pool which has not been associated with a farm
    function addChildFarmToPool(
        uint256 _pid,
        IChildFarm _childFarm,
        uint256 _childPoolId,
        uint16 _childPoolFeeBP,
        IERC20 _childFarmToken,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        require(
            address(poolInfo[_pid].childFarm) == address(0),
            "Child Farm already added to pool"
        );
        require(address(_childFarm) != address(0), "Child Farm address cannot be zero address");
        require(
            address(_childFarmToken) != address(0),
            "Child Farm token address cannot be zero address"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        uint256 amount = pool.lpToken.balanceOf(address(this));
        if (amount > 0) {
            IERC20(address(pool.lpToken)).approve(address(_childFarm), amount);
            _childFarm.deposit(_childPoolId, amount);
        }
        pool.childFarm = _childFarm;
        pool.childPoolId = _childPoolId;
        pool.childPoolFeeBP = _childPoolFeeBP;
        pool.childFarmToken = _childFarmToken;

        emit AddedChildFarm(_pid, _childFarm, _childPoolId, _childPoolFeeBP, _childFarmToken);
    }

    // Removes a child farm from pool
    // //to-do. Need to test if a pool with child can be converted to normal pool
    function removeChildFarmFromPool(uint256 _pid, bool _withUpdate)
        external
        onlyOwner
        validatePoolByPid(_pid)
        nonReentrant
    {
        require(
            address(poolInfo[_pid].childFarm) != address(0),
            "Child Farm address cannot be zero address"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        //we are unlinking child farm
        //call withdraw for existing LPs
        PoolInfo storage pool = poolInfo[_pid];
        IChildFarm childFarm = pool.childFarm;
        //to-doshould be correct but test this part
        (uint256 amount, ) = childFarm.userInfo(pool.childPoolId, address(this));
        if (amount > 0) {
            childFarm.withdraw(pool.childPoolId, amount);
            drain(_pid);
        }
        pool.childFarm = IChildFarm(address(0));
        pool.childPoolId = 0;
        pool.childPoolFeeBP = 0;
        pool.childFarmToken = IERC20(address(0));

        emit RemovedChildFarm(_pid, childFarm);
    }

    // Updates a child farm for pool
    //make sure the LP tokens for the new is the same as old
    function updateChildFarmInPool(
        uint256 _pid,
        IChildFarm _newChildFarm,
        uint256 _newChildPoolId,
        uint16 _newChildPoolFeeBP,
        IERC20 _newChildFarmToken,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        require(
            address(poolInfo[_pid].childFarm) != address(0),
            "Child Farm address cannot be zero address"
        );
        require(address(_newChildFarm) != address(0), "Child Farm address cannot be zero address");
        require(
            address(_newChildFarmToken) != address(0),
            "Child Farm token address cannot be zero address"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        //we are unlinking old child farm
        //call withdraw for existing LPs
        //link new farm
        // deposit LPs to new farm
        PoolInfo storage pool = poolInfo[_pid];
        IChildFarm childFarm = pool.childFarm;
        (uint256 amount, ) = childFarm.userInfo(pool.childPoolId, address(this));
        if (amount > 0) {
            childFarm.withdraw(pool.childPoolId, amount);
            drain(_pid);
            IERC20(address(pool.lpToken)).approve(address(_newChildFarm), amount);
            _newChildFarm.deposit(_newChildPoolId, amount);
        }
        pool.childFarm = _newChildFarm;
        pool.childPoolId = _newChildPoolId;
        pool.childPoolFeeBP = _newChildPoolFeeBP;
        pool.childFarmToken = _newChildFarmToken;

        emit UpdatedChildFarm(
            _pid,
            _newChildFarm,
            _newChildPoolId,
            _newChildPoolFeeBP,
            _newChildFarmToken
        );
    }

    function updateChildPoolFeeBP(
        uint256 _pid,
        uint16 _childPoolFeeBP,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        require(
            address(poolInfo[_pid].childFarm) != address(0),
            "Child Farm address cannot be zero address"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        poolInfo[_pid].childPoolFeeBP = _childPoolFeeBP;
        emit UpdatedChildPoolFeeBP(_pid, _childPoolFeeBP);
    }

    //confirm if this is needed
    function updateChildPoolFarmToken(
        uint256 _pid,
        IERC20 _childFarmToken,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid) nonReentrant {
        require(
            address(poolInfo[_pid].childFarm) != address(0),
            "Child Farm address cannot be zero address"
        );
        require(
            address(_childFarmToken) != address(0),
            "Child Farm token address cannot be zero address"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        updatePool(_pid);
        drain(_pid);
        poolInfo[_pid].childFarmToken = _childFarmToken;
        emit UpdatedChildPoolFarmToken(_pid, _childFarmToken);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending YGNs on frontend.
    function pendingYGN(uint256 _pid, address _user)
        external
        view
        validatePoolByPid(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accYGNPerShare = pool.accYGNPerShare;
        uint256 lpSupply;
        if (address(pool.childFarm) != address(0)) {
            (uint256 amount, ) = pool.childFarm.userInfo(pool.childPoolId, address(this));
            lpSupply = amount;
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ygnReward = multiplier.mul(ygnPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
            accYGNPerShare = accYGNPerShare.add(ygnReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accYGNPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest ygn's.
    function canHarvest(uint256 _pid, address _user)
        public
        view
        validatePoolByPid(_pid)
        returns (bool)
    {
        UserInfo memory user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // View function to see if user harvest until time.
    function getHarvestUntil(uint256 _pid, address _user)
        external
        view
        validatePoolByPid(_pid)
        returns (uint256)
    {
        UserInfo memory user = userInfo[_pid][_user];
        return user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply;
        if (address(pool.childFarm) != address(0)) {
            (uint256 amount, ) = pool.childFarm.userInfo(pool.childPoolId, address(this));
            lpSupply = amount;
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ygnReward = multiplier.mul(ygnPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accYGNPerShare = pool.accYGNPerShare.add(ygnReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
        emit PoolUpdated(_pid, pool.lastRewardBlock, lpSupply, pool.accYGNPerShare);
    }

    // Deposit LP tokens to Farm for YGN allocation.
    function deposit(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) nonReentrant {
        _deposit(_pid, _amount, msg.sender);
    }

    // Deposit LP tokens to Farm for YGN allocation.
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external validatePoolByPid(_pid) nonReentrant {
        _deposit(_pid, _amount, _user);
    }

    function _deposit(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        whiteListedHandlers[_user][_user] = true;

        updatePool(_pid);
        payOrLockupPendingYGN(_pid, _user, _user);

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (address(pool.childFarm) != address(0)) {
                IERC20(address(pool.lpToken)).approve(address(pool.childFarm), _amount);
                pool.childFarm.deposit(pool.childPoolId, _amount);
                if (pool.childPoolFeeBP > 0) {
                    uint256 depositFees = _amount.mul(pool.childPoolFeeBP).div(10000);
                    user.amount = user.amount.add(_amount).sub(depositFees);
                } else {
                    user.amount = user.amount.add(_amount);
                }
            } else {
                user.amount = user.amount.add(_amount);
            }
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }
        //AskAkki - Confirm this line
        user.rewardDebt = user.amount.mul(pool.accYGNPerShare).div(1e12);
        emit Deposit(_user, _pid, _amount);
    }

    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) nonReentrant {
        _withdraw(_pid, _amount, msg.sender, msg.sender);
    }

    // Withdraw LP tokens from Farm.
    function withdrawFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external validatePoolByPid(_pid) nonReentrant {
        require(whiteListedHandlers[_user][msg.sender], "not whitelisted");
        _withdraw(_pid, _amount, _user, msg.sender);
    }

    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        address _user,
        address _withdrawer
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        payOrLockupPendingYGN(_pid, _user, _withdrawer);

        if (_amount > 0) {
            if (address(pool.childFarm) != address(0)) {
                pool.childFarm.withdraw(pool.childPoolId, _amount);
            }
            user.amount = user.amount.sub(_amount);
            if (pool.withdrawalFeeBP > 0) {
                uint256 withdrawalFee = _amount.mul(pool.withdrawalFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, withdrawalFee);
                pool.lpToken.safeTransfer(address(_withdrawer), _amount.sub(withdrawalFee));
            } else {
                pool.lpToken.safeTransfer(address(_withdrawer), _amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accYGNPerShare).div(1e12);
        emit Withdraw(_user, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external validatePoolByPid(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (address(pool.childFarm) != address(0)) {
            pool.childFarm.withdraw(pool.childPoolId, user.amount);
        }
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        //emergency withdraw for us
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
    }

    function addUserToWhiteList(address _user) external {
        whiteListedHandlers[msg.sender][_user] = true;
        emit UserWhitelisted(msg.sender, _user);
    }

    function removeUserFromWhiteList(address _user) external {
        whiteListedHandlers[msg.sender][_user] = false;
        emit UserBlacklisted(msg.sender, _user);
    }

    function isUserWhiteListed(address _owner, address _user) external view returns (bool) {
        return whiteListedHandlers[_owner][_user];
    }

    // Pay or lockup pending ygn.
    function payOrLockupPendingYGN(
        uint256 _pid,
        address _user,
        address _withdrawer
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        //drain and get farm tokens to us and send to converter
        drain(_pid);
        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accYGNPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, _user)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send rewards
                if (isRewardManagerEnabled == true) {
                    safeYGNTransfer(rewardManager, totalRewards);
                    IRewardManager(rewardManager).handleRewardsForUser(
                        _withdrawer,
                        totalRewards,
                        block.timestamp,
                        _pid,
                        user.rewardDebt
                    );
                } else {
                    safeYGNTransfer(_withdrawer, totalRewards);
                }
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(_user, _pid, pending);
        }
    }

    // Update fee address by the previous fee address.
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "setFeeAddress: invalid address");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function withdrawYGN(uint256 _amount) external onlyOwner {
        ygn.transfer(msg.sender, _amount);
    }

    //does this need to be made internal
    function drain(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.childFarmToken) != address(0) && address(pool.childFarm) != address(0)) {
            //get harvest tokens
            pool.childFarm.withdraw(pool.childPoolId, 0);
            uint256 childFarmTokenBal = pool.childFarmToken.balanceOf(address(this));
            if (childFarmTokenBal > 0) {
                pool.childFarmToken.safeTransfer(feeAddress, childFarmTokenBal);
            }
        }
    }

    // Safe ygn transfer function, just in case if rounding error causes pool to not have enough YGNs.
    function safeYGNTransfer(address _to, uint256 _amount) internal {
        uint256 ygnBal = ygn.balanceOf(address(this));
        if (_amount > ygnBal) {
            ygn.transfer(_to, ygnBal);
        } else {
            ygn.transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IChildFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IRewardManager {
    function handleRewardsForUser(
        address user,
        uint256 rewardAmount,
        uint256 timestamp,
        uint256 pid,
        uint256 rewardDebt
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

