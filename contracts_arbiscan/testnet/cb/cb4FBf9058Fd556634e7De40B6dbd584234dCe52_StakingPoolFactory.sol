// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../utils/Initializable.sol";
import "../utils/Ownable.sol";
import "./StakingPool.sol";

contract StakingPoolFactory is IStakingPoolFactory, Ownable, Initializable {
    address public apeX;
    uint256 public blocksPerUpdate;
    uint256 public apeXPerBlock;
    uint256 public totalWeight;
    uint256 public override endBlock;
    uint256 public lastUpdateBlock;
    uint256 public override yieldLockTime;
    mapping(address => PoolInfo) public pools;
    mapping(address => address) public override poolTokenMap;

    function initialize(
        address _apeX,
        uint256 _apeXPerBlock,
        uint256 _blocksPerUpdate,
        uint256 _initBlock,
        uint256 _endBlock
    ) public initializer {
        require(_apeX != address(0), "cpf.initialize: INVALID_APEX");
        require(_apeXPerBlock > 0, "cpf.initialize: INVALID_PER_BLOCK");
        require(_blocksPerUpdate > 0, "cpf.initialize: INVALID_UPDATE_SPAN");
        require(_initBlock > 0, "cpf.initialize: INVALID_INIT_BLOCK");
        require(_endBlock > _initBlock, "cpf.initialize: INVALID_ENDBLOCK");

        owner = msg.sender;
        apeX = _apeX;
        apeXPerBlock = _apeXPerBlock;
        blocksPerUpdate = _blocksPerUpdate;
        lastUpdateBlock = _initBlock;
        endBlock = _endBlock;
    }

    function createPool(
        address _poolToken,
        uint256 _initBlock,
        uint256 _weight
    ) external override onlyOwner {
        IStakingPool pool = new StakingPool(address(this), _poolToken, apeX, _initBlock);
        registerPool(address(pool), _weight);
    }

    function registerPool(address _pool, uint256 _weight) public override onlyOwner {
        require(poolTokenMap[_pool] == address(0), "cpf.registerPool: POOL_REGISTERED");
        address poolToken = IStakingPool(_pool).poolToken();
        require(poolToken != address(0), "cpf.registerPool: ZERO_ADDRESS");

        pools[poolToken] = PoolInfo({pool: _pool, weight: _weight});
        poolTokenMap[_pool] = poolToken;
        totalWeight += _weight;

        emit PoolRegistered(msg.sender, poolToken, _pool, _weight);
    }

    function updateApeXPerBlock() external override {
        uint256 blockNumber = block.number;

        require(
            blockNumber <= endBlock && blockNumber >= lastUpdateBlock + blocksPerUpdate,
            "cpf.updateApeXPerBlock: TOO_FREQUENT"
        );

        apeXPerBlock = (apeXPerBlock * 97) / 100;
        lastUpdateBlock = block.number;
    }

    function transferYieldTo(address _to, uint256 _amount) external override {
        require(poolTokenMap[msg.sender] != address(0), "cpf.transferYieldTo: ACCESS_DENIED");

        IERC20(apeX).transfer(_to, _amount);
    }

    function changePoolWeight(address _pool, uint256 _weight) external override onlyOwner {
        address poolToken = poolTokenMap[_pool];
        require(poolToken != address(0), "cpf.changePoolWeight: POOL_NOT_EXIST");

        totalWeight = totalWeight + _weight - pools[poolToken].weight;
        pools[poolToken].weight = _weight;

        emit WeightUpdated(msg.sender, _pool, _weight);
    }

    function setYieldLockTime(uint256 _yieldLockTime) external onlyOwner {
        require(_yieldLockTime > yieldLockTime, "cpf.setYieldLockTime: INVALID_YIELDLOCKTIME");
        yieldLockTime = _yieldLockTime;

        emit SetYieldLockTime(_yieldLockTime);
    }

    function calStakingPoolApeXReward(uint256 _lastYieldDistribution, address _poolToken)
        external
        view
        override
        returns (uint256 reward)
    {
        uint256 blockNumber = block.number;
        uint256 blocksPassed = blockNumber > endBlock
            ? endBlock - _lastYieldDistribution
            : blockNumber - _lastYieldDistribution;
        //@audit - if no claim, shrinking reward make sense?
        reward = (blocksPassed * apeXPerBlock * pools[_poolToken].weight) / totalWeight;
    }

    function shouldUpdateRatio() external view override returns (bool) {
        uint256 blockNumber = block.number;
        return blockNumber > endBlock ? false : blockNumber >= lastUpdateBlock + blocksPerUpdate;
    }

    function getPoolAddress(address _poolToken) external view override returns (address) {
        return pools[_poolToken].pool;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStakingPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockUntil;
        bool isYield;
    }

    struct User {
        uint256 tokenAmount;
        uint256 totalWeight;
        uint256 subYieldRewards;
        Deposit[] deposits;
    }

    event Staked(address indexed by, address indexed from, uint256 amount);

    event YieldClaimed(address indexed by, address indexed to, uint256 amount);

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight, uint256 lastYieldDistribution);

    event UpdateStakeLock(address indexed by, uint256 depositId, uint256 lockFrom, uint256 lockUntil);

    /// @notice Get pool token of this core pool
    function poolToken() external view returns (address);

    /// @notice Process yield reward (apex) of msg.sender
    function processRewards() external;

    /// @notice Stake poolToken
    /// @param amount poolToken's amount to stake.
    /// @param lockUntil time to lock.
    function stake(uint256 amount, uint256 lockUntil) external;

    /// @notice UnstakeBatch poolToken
    /// @param depositIds the deposit index.
    /// @param amounts poolToken's amount to unstake.
    function unstakeBatch(uint256[] memory depositIds, uint256[] memory amounts) external;

    /// @notice Not-apex stakingPool to stake their users' yield to apex stakingPool
    /// @param staker add yield to this staker in apex stakingPool.
    /// @param amount yield apex amount to stake.
    function stakeAsPool(address staker, uint256 amount) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockUntil`
    /// @param depositId the deposit index.
    /// @param lockUntil new lock time.
    function updateStakeLock(uint256 depositId, uint256 lockUntil) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStakingPoolFactory {
    struct PoolInfo {
        address pool;
        uint256 weight;
    }

    event WeightUpdated(address indexed _by, address indexed pool, uint256 weight);

    event PoolRegistered(address indexed _by, address indexed poolToken, address indexed pool, uint256 weight);

    event SetYieldLockTime(uint256 _yieldLockTime);

    /// @notice get the endBlock number to yield, after this, no yield reward
    function endBlock() external view returns (uint256);

    function yieldLockTime() external view returns (uint256);

    /// @notice get stakingPool's poolToken
    function poolTokenMap(address pool) external view returns (address);

    /// @notice get stakingPool's address of poolToken
    /// @param poolToken staked token.
    function getPoolAddress(address poolToken) external view returns (address);

    function shouldUpdateRatio() external view returns (bool);

    /// @notice calculate yield reward of poolToken since lastYieldDistribution
    /// @param poolToken staked token.
    function calStakingPoolApeXReward(uint256 lastYieldDistribution, address poolToken)
        external
        view
        returns (uint256 reward);

    /// @notice update yield reward rate
    function updateApeXPerBlock() external;

    /// @notice create a new stakingPool
    /// @param poolToken stakingPool staked token.
    /// @param initBlock when to yield reward.
    /// @param weight new pool's weight between all other stakingPools.
    function createPool(
        address poolToken,
        uint256 initBlock,
        uint256 weight
    ) external;

    /// @notice register an exist pool to factory
    /// @param pool the exist pool.
    /// @param weight pool's weight between all other stakingPools.
    function registerPool(address pool, uint256 weight) external;

    /// @notice mint apex to staker
    /// @param _to the staker.
    /// @param _amount apex amount.
    function transferYieldTo(address _to, uint256 _amount) external;

    /// @notice change a pool's weight
    /// @param poolAddr the pool.
    /// @param weight new weight.
    function changePoolWeight(address poolAddr, uint256 weight) external;
}

pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";

contract StakingPool is IStakingPool, Reentrant {
    uint256 internal constant ONE_YEAR = 365 days;
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    address public immutable apex;
    address public immutable override poolToken;
    IStakingPoolFactory public immutable factory;
    uint256 public lastYieldDistribution;
    uint256 public yieldRewardsPerWeight;
    uint256 public usersLockingWeight;
    mapping(address => User) public users;

    constructor(
        address _factory,
        address _poolToken,
        address _apex,
        uint256 _initBlock
    ) {
        require(_factory != address(0), "cp: INVALID_FACTORY");
        require(_apex != address(0), "cp: INVALID_APEX_TOKEN");
        require(_initBlock > 0, "cp: INVALID_INIT_BLOCK");
        require(_poolToken != address(0), "cp: INVALID_POOL_TOKEN");

        apex = _apex;
        factory = IStakingPoolFactory(_factory);
        poolToken = _poolToken;
        lastYieldDistribution = _initBlock;
    }

    function stake(uint256 _amount, uint256 _lockUntil) external override nonReentrant {
        address _staker = msg.sender;
        require(_amount > 0, "cp._stake: INVALID_AMOUNT");
        uint256 now256 = block.timestamp;
        require(
            _lockUntil == 0 || (_lockUntil > now256 && _lockUntil <= now256 + ONE_YEAR),
            "cp._stake: INVALID_LOCK_INTERVAL"
        );

        User storage user = users[_staker];
        _processRewards(_staker, user);

        uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
        IERC20(poolToken).transferFrom(msg.sender, address(this), _amount);
        uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
        uint256 addedAmount = newBalance - previousBalance;
        //if 0, not lock
        uint256 lockFrom = _lockUntil > 0 ? now256 : 0;
        uint256 stakeWeight = (((_lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / ONE_YEAR + WEIGHT_MULTIPLIER) *
            addedAmount;

        Deposit memory deposit = Deposit({
            amount: addedAmount,
            weight: stakeWeight,
            lockFrom: lockFrom,
            lockUntil: _lockUntil,
            isYield: false
        });

        user.deposits.push(deposit);
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
        usersLockingWeight += stakeWeight;

        emit Staked(msg.sender, _staker, _amount);
    }

    function unstakeBatch(uint256[] memory _depositIds, uint256[] memory _amounts) external override {
        require(_depositIds.length == _amounts.length, "cp.unstakeBatch: INVALID_DEPOSITS_AMOUNTS");
        address _staker = msg.sender;
        uint256 now256 = block.timestamp;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        uint256 yieldAmount;
        uint256 stakeAmount;
        uint256 _amount;
        uint256 _depositId;
        uint256 previousWeight;
        uint256 newWeight;
        uint256 deltaUsersLockingWeight;
        Deposit memory stakeDeposit;
        for (uint256 i = 0; i < _depositIds.length; i++) {
            _amount = _amounts[i];
            _depositId = _depositIds[i];
            require(_amount > 0, "cp.unstakeBatch: INVALID_AMOUNT");
            stakeDeposit = user.deposits[_depositId];
            require(stakeDeposit.lockFrom == 0 || now256 > stakeDeposit.lockUntil, "cp.unstakeBatch: DEPOSIT_LOCKED");
            require(stakeDeposit.amount >= _amount, "cp.unstakeBatch: EXCEED_STAKED");

            previousWeight = stakeDeposit.weight;
            //tocheck if lockTime is not 1 year?
            newWeight =
                (((stakeDeposit.lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
                    ONE_YEAR +
                    WEIGHT_MULTIPLIER) *
                (stakeDeposit.amount - _amount);
            if (stakeDeposit.isYield) {
                yieldAmount += _amount;
            } else {
                stakeAmount += _amount;
            }
            if (stakeDeposit.amount == _amount) {
                delete user.deposits[_depositId];
            } else {
                stakeDeposit.amount -= _amount;
                stakeDeposit.weight = newWeight;
            }

            user.deposits[_depositId] = stakeDeposit;
            user.tokenAmount -= _amount;
            user.totalWeight -= (previousWeight - newWeight);
            user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
            deltaUsersLockingWeight += (previousWeight - newWeight);
        }
        usersLockingWeight -= deltaUsersLockingWeight;

        if (yieldAmount > 0) {
            factory.transferYieldTo(msg.sender, yieldAmount);
        }
        if (stakeAmount > 0) {
            IERC20(poolToken).transfer(msg.sender, stakeAmount);
        }
    }

    function stakeAsPool(address _staker, uint256 _amount) external override {
        require(factory.poolTokenMap(msg.sender) != address(0), "cp.stakeAsPool: ACCESS_DENIED");
        syncWeightPrice(); //need sync apexStakingPool

        User storage user = users[_staker];

        uint256 pendingYield = weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
        uint256 yieldAmount = _amount + pendingYield;
        uint256 yieldWeight = yieldAmount * YEAR_STAKE_WEIGHT_MULTIPLIER;
        uint256 now256 = block.timestamp;
        Deposit memory newDeposit = Deposit({
            amount: yieldAmount,
            weight: yieldWeight,
            lockFrom: now256,
            lockUntil: now256 + factory.yieldLockTime(),
            isYield: true
        });
        user.deposits.push(newDeposit);

        user.tokenAmount += yieldAmount;
        user.totalWeight += yieldWeight;
        usersLockingWeight += yieldWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
    }

    function updateStakeLock(uint256 _depositId, uint256 _lockUntil) external override {
        uint256 now256 = block.timestamp;
        require(_lockUntil > now256, "cp.updateStakeLock: INVALID_LOCK_UNTIL");

        address _staker = msg.sender;
        User storage user = users[_staker];
        Deposit storage stakeDeposit = user.deposits[_depositId];
        require(_lockUntil > stakeDeposit.lockUntil, "cp.updateStakeLock: INVALID_NEW_LOCK");

        if (stakeDeposit.lockFrom == 0) {
            require(_lockUntil <= now256 + ONE_YEAR, "cp.updateStakeLock: EXCEED_MAX_LOCK_PERIOD");
            stakeDeposit.lockFrom = now256;
        } else {
            require(_lockUntil <= stakeDeposit.lockFrom + ONE_YEAR, "cp.updateStakeLock: EXCEED_MAX_LOCK");
        }

        stakeDeposit.lockUntil = _lockUntil;
        uint256 newWeight = (((stakeDeposit.lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
            ONE_YEAR +
            WEIGHT_MULTIPLIER) * stakeDeposit.amount;
        uint256 previousWeight = stakeDeposit.weight;
        stakeDeposit.weight = newWeight;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;
        emit UpdateStakeLock(_staker, _depositId, stakeDeposit.lockFrom, _lockUntil);
    }

    function processRewards() external override {
        User storage user = users[msg.sender];

        _processRewards(msg.sender, user);
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
    }

    function syncWeightPrice() public {
        if (factory.shouldUpdateRatio()) {
            factory.updateApeXPerBlock();
        }

        uint256 endBlock = factory.endBlock();
        uint256 blockNumber = block.number;
        if (lastYieldDistribution >= endBlock || lastYieldDistribution >= blockNumber) {
            return;
        }
        if (usersLockingWeight == 0) {
            lastYieldDistribution = blockNumber;
            return;
        }
        //@notice: if nobody sync this stakingPool for a long time, this stakingPool reward shrink
        uint256 apexReward = factory.calStakingPoolApeXReward(lastYieldDistribution, poolToken);
        yieldRewardsPerWeight += deltaWeightPrice(apexReward, usersLockingWeight);
        lastYieldDistribution = blockNumber > endBlock ? endBlock : blockNumber;

        emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    //update weight price, then if apex, add deposits; if not, stake as pool.
    function _processRewards(address _staker, User storage user) internal {
        syncWeightPrice();

        //if no yield
        if (user.tokenAmount == 0) return;
        uint256 yieldAmount = weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
        if (yieldAmount == 0) return;

        if (poolToken == apex) {
            uint256 yieldWeight = yieldAmount * YEAR_STAKE_WEIGHT_MULTIPLIER;
            uint256 now256 = block.timestamp;
            Deposit memory newDeposit = Deposit({
                amount: yieldAmount,
                weight: yieldWeight,
                lockFrom: now256,
                lockUntil: now256 + factory.yieldLockTime(),
                isYield: true
            });
            user.deposits.push(newDeposit);
            user.tokenAmount += yieldAmount;
            user.totalWeight += yieldWeight;
            usersLockingWeight += yieldWeight;
        } else {
            address apexStakingPool = factory.getPoolAddress(apex);
            IStakingPool(apexStakingPool).stakeAsPool(_staker, yieldAmount);
        }

        emit YieldClaimed(msg.sender, _staker, yieldAmount);
    }

    function pendingYieldRewards(address _staker) external view returns (uint256 pending) {
        uint256 blockNumber = block.number;
        uint256 newYieldRewardsPerWeight;

        if (blockNumber > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 apexReward = factory.calStakingPoolApeXReward(lastYieldDistribution, poolToken);
            newYieldRewardsPerWeight = deltaWeightPrice(apexReward, usersLockingWeight) + yieldRewardsPerWeight;
        } else {
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        User memory user = users[_staker];
        pending = weightToReward(user.totalWeight, newYieldRewardsPerWeight) - user.subYieldRewards;
    }

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory) {
        return users[_user].deposits[_depositId];
    }

    function getDepositsLength(address _user) external view returns (uint256) {
        return users[_user].deposits.length;
    }

    function weightToReward(uint256 _weight, uint256 _rewardPerWeight) public pure returns (uint256) {
        return (_weight * _rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    function deltaWeightPrice(uint256 _deltaReward, uint256 _usersLockingWeight) public pure returns (uint256) {
        return (_deltaReward * REWARD_PER_WEIGHT_MULTIPLIER) / _usersLockingWeight;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}