// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../utils/Initializable.sol";
import "../utils/Ownable.sol";
import "./StakingPool.sol";

//this is a stakingPool factory to create and register stakingPool, distribute ApeX token according to pools' weight
contract StakingPoolFactory is IStakingPoolFactory, Ownable, Initializable {
    address public override apeX;
    uint256 public override lastUpdateTimestamp;
    uint256 public override secSpanPerUpdate;
    uint256 public override apeXPerSec;
    uint256 public override totalWeight;
    uint256 public override endTimestamp;
    uint256 public override lockTime;
    uint256 public override minRemainRatioAfterBurn; //10k-based
    mapping(address => PoolInfo) public pools;
    mapping(address => address) public override poolTokenMap;

    //upgradableProxy StakingPoolFactory only initialized once
    function initialize(
        address _apeX,
        uint256 _apeXPerSec,
        uint256 _secSpanPerUpdate,
        uint256 _initTimestamp,
        uint256 _endTimestamp,
        uint256 _lockTime
    ) public initializer {
        require(_apeX != address(0), "cpf.initialize: INVALID_APEX");
        require(_apeXPerSec > 0, "cpf.initialize: INVALID_PER_SEC");
        require(_secSpanPerUpdate > 0, "cpf.initialize: INVALID_UPDATE_SPAN");
        require(_initTimestamp > 0, "cpf.initialize: INVALID_INIT_TIMESTAMP");
        require(_endTimestamp > _initTimestamp, "cpf.initialize: INVALID_END_TIMESTAMP");
        require(_lockTime > 0, "cpf.initialize: INVALID_LOCK_TIME");

        owner = msg.sender;
        apeX = _apeX;
        apeXPerSec = _apeXPerSec;
        secSpanPerUpdate = _secSpanPerUpdate;
        lastUpdateTimestamp = _initTimestamp;
        endTimestamp = _endTimestamp;
        lockTime = _lockTime;
    }

    function createPool(
        address _poolToken,
        uint256 _initTimestamp,
        uint256 _weight
    ) external override onlyOwner {
        IStakingPool pool = new StakingPool(address(this), _poolToken, apeX, _initTimestamp);
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

    function unregisterPool(address _pool) external override onlyOwner {
        require(poolTokenMap[_pool] != address(0), "cpf.unregisterPool: POOL_NOT_REGISTERED");
        address poolToken = IStakingPool(_pool).poolToken();

        totalWeight -= pools[poolToken].weight;
        delete pools[poolToken];
        delete poolTokenMap[_pool];

        emit PoolUnRegistered(msg.sender, poolToken, _pool);
    }

    function updateApeXPerSec() external override {
        uint256 currentTimestamp = block.timestamp;

        require(currentTimestamp >= lastUpdateTimestamp + secSpanPerUpdate, "cpf.updateApeXPerSec: TOO_FREQUENT");
        require(currentTimestamp <= endTimestamp, "cpf.updateApeXPerSec: END");

        apeXPerSec = (apeXPerSec * 97) / 100;
        lastUpdateTimestamp = currentTimestamp;

        emit UpdateApeXPerSec(apeXPerSec);
    }

    function transferYieldTo(address _to, uint256 _amount) external override {
        require(poolTokenMap[msg.sender] != address(0), "cpf.transferYieldTo: ACCESS_DENIED");

        IERC20(apeX).transfer(_to, _amount);
        emit TransferYieldTo(msg.sender, _to, _amount);
    }

    function changePoolWeight(address _pool, uint256 _weight) external override onlyOwner {
        address poolToken = poolTokenMap[_pool];
        require(poolToken != address(0), "cpf.changePoolWeight: POOL_NOT_EXIST");

        totalWeight = totalWeight + _weight - pools[poolToken].weight;
        pools[poolToken].weight = _weight;

        emit WeightUpdated(msg.sender, _pool, _weight);
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        require(_lockTime > lockTime, "cpf.setLockTime: INVALID_LOCK_TIME");
        lockTime = _lockTime;

        emit SetYieldLockTime(_lockTime);
    }

    function setMinRemainRatioAfterBurn(uint256 _minRemainRatioAfterBurn) external override onlyOwner {
        require(_minRemainRatioAfterBurn <= 10000, "cpf.setMinRemainRatioAfterBurn: INVALID_VALUE");
        minRemainRatioAfterBurn = _minRemainRatioAfterBurn;
    }

    function calStakingPoolApeXReward(uint256 _lastYieldDistribution, address _poolToken)
        external
        view
        override
        returns (uint256 reward)
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 secPassed = currentTimestamp > endTimestamp
            ? endTimestamp - _lastYieldDistribution
            : currentTimestamp - _lastYieldDistribution;

        reward = (secPassed * apeXPerSec * pools[_poolToken].weight) / totalWeight;
    }

    function shouldUpdateRatio() external view override returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        return currentTimestamp > endTimestamp ? false : currentTimestamp >= lastUpdateTimestamp + secSpanPerUpdate;
    }

    function getPoolAddress(address _poolToken) external view override returns (address) {
        return pools[_poolToken].pool;
    }

    //just for dev use
    function setApeXPerSec(uint256 _apeXPerSec) external onlyOwner {
        apeXPerSec = _apeXPerSec;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockUntil;
    }

    struct Yield {
        uint256 amount;
        uint256 lockFrom;
        uint256 lockUntil;
    }

    struct User {
        uint256 tokenAmount;
        uint256 totalWeight;
        uint256 subYieldRewards;
        Deposit[] deposits;
        Yield[] yields;
    }

    event BatchWithdraw(
        address indexed by,
        uint256[] _depositIds,
        uint256[] _amounts,
        uint256[] _yieldIds,
        uint256[] _yieldAmounts
    );

    event ForceWithdraw(address indexed by, uint256[] yieldIds);

    event Staked(address indexed to, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event YieldClaimed(address indexed by, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event StakeAsPool(
        address indexed by,
        address indexed to,
        uint256 depositId,
        uint256 amountStakedAsPool,
        uint256 yieldAmount,
        uint256 lockFrom,
        uint256 lockUntil
    );

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight, uint256 lastYieldDistribution);

    event UpdateStakeLock(address indexed by, uint256 depositId, uint256 lockFrom, uint256 lockUntil);

    /// @notice Get pool token of this core pool
    function poolToken() external view returns (address);

    function getStakeInfo(address _user)
        external
        view
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        );

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function getYield(address _user, uint256 _yieldId) external view returns (Yield memory);

    function getYieldsLength(address _user) external view returns (uint256);

    /// @notice Process yield reward (apex) of msg.sender
    function processRewards() external;

    /// @notice Stake poolToken
    /// @param amount poolToken's amount to stake.
    /// @param lockUntil time to lock.
    function stake(uint256 amount, uint256 lockUntil) external;

    /// @notice BatchWithdraw poolToken
    /// @param depositIds the deposit index.
    /// @param depositAmounts poolToken's amount to unstake.
    function batchWithdraw(
        uint256[] memory depositIds,
        uint256[] memory depositAmounts,
        uint256[] memory yieldIds,
        uint256[] memory yieldAmounts
    ) external;

    /// @notice force withdraw locked reward and new reward
    /// @param depositIds the deposit index of locked reward.
    function forceWithdraw(uint256[] memory depositIds) external;

    /// @notice Not-apex stakingPool to stake their users' yield to apex stakingPool
    /// @param staker add yield to this staker in apex stakingPool.
    /// @param amount yield apex amount to stake.
    function stakeAsPool(address staker, uint256 amount) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockUntil`
    /// @param depositId the deposit index.
    /// @param lockUntil new lock time.
    function updateStakeLock(uint256 depositId, uint256 lockUntil) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPoolFactory {
    struct PoolInfo {
        address pool;
        uint256 weight;
    }

    event WeightUpdated(address indexed by, address indexed pool, uint256 weight);

    event PoolRegistered(address indexed by, address indexed poolToken, address indexed pool, uint256 weight);

    event PoolUnRegistered(address indexed by, address indexed poolToken, address indexed pool);

    event SetYieldLockTime(uint256 yieldLockTime);

    event UpdateApeXPerSec(uint256 apeXPerSec);

    event TransferYieldTo(address by, address to, uint256 amount);

    function apeX() external view returns (address);

    function lastUpdateTimestamp() external view returns (uint256);

    function secSpanPerUpdate() external view returns (uint256);

    function apeXPerSec() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    /// @notice get the end timestamp to yield, after this, no yield reward
    function endTimestamp() external view returns (uint256);

    function lockTime() external view returns (uint256);

    /// @notice get minimum remain ratio after force withdraw
    function minRemainRatioAfterBurn() external view returns (uint256);

    /// @notice get stakingPool's poolToken
    function poolTokenMap(address pool) external view returns (address);

    /// @notice get stakingPool's address of poolToken
    /// @param poolToken staked token.
    function getPoolAddress(address poolToken) external view returns (address);

    /// @notice check if can update reward ratio
    function shouldUpdateRatio() external view returns (bool);

    /// @notice calculate yield reward of poolToken since lastYieldDistribution
    /// @param poolToken staked token.
    function calStakingPoolApeXReward(uint256 lastYieldDistribution, address poolToken)
        external
        view
        returns (uint256 reward);

    /// @notice update yield reward rate
    function updateApeXPerSec() external;

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

    /// @notice unregister an exist pool
    function unregisterPool(address pool) external;

    /// @notice mint apex to staker
    /// @param _to the staker.
    /// @param _amount apex amount.
    function transferYieldTo(address _to, uint256 _amount) external;

    /// @notice change a pool's weight
    /// @param poolAddr the pool.
    /// @param weight new weight.
    function changePoolWeight(address poolAddr, uint256 weight) external;

    /// @notice set minimum reward ratio when force withdraw locked rewards
    function setMinRemainRatioAfterBurn(uint256 _minRemainRatioAfterBurn) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";

contract StakingPool is IStakingPool, Reentrant {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MAX_TIME_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    address public immutable apex;
    address public immutable override poolToken;
    IStakingPoolFactory public immutable factory;
    uint256 public lastYieldDistribution; //timestamp
    uint256 public yieldRewardsPerWeight;
    uint256 public usersLockingWeight;
    mapping(address => User) public users;

    constructor(
        address _factory,
        address _poolToken,
        address _apex,
        uint256 _initTimestamp
    ) {
        require(_factory != address(0), "cp: INVALID_FACTORY");
        require(_apex != address(0), "cp: INVALID_APEX_TOKEN");
        require(_initTimestamp > 0, "cp: INVALID_INIT_TIMESTAMP");
        require(_poolToken != address(0), "cp: INVALID_POOL_TOKEN");

        apex = _apex;
        factory = IStakingPoolFactory(_factory);
        poolToken = _poolToken;
        lastYieldDistribution = _initTimestamp;
    }

    function stake(uint256 _amount, uint256 _lockUntil) external override nonReentrant {
        require(_amount > 0, "sp.stake: INVALID_AMOUNT");
        uint256 now256 = block.timestamp;
        uint256 lockTime = factory.lockTime();
        require(
            _lockUntil == 0 || (_lockUntil > now256 && _lockUntil <= now256 + lockTime),
            "sp._stake: INVALID_LOCK_INTERVAL"
        );

        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        //if 0, not lock
        uint256 lockFrom = _lockUntil > 0 ? now256 : 0;
        uint256 stakeWeight = (((_lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / lockTime + WEIGHT_MULTIPLIER) * _amount;
        uint256 depositId = user.deposits.length;
        Deposit memory deposit = Deposit({
            amount: _amount,
            weight: stakeWeight,
            lockFrom: lockFrom,
            lockUntil: _lockUntil
        });

        user.deposits.push(deposit);
        user.tokenAmount += _amount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight += stakeWeight;

        emit Staked(_staker, depositId, _amount, lockFrom, _lockUntil);
        IERC20(poolToken).transferFrom(_staker, address(this), _amount);
    }

    function batchWithdraw(
        uint256[] memory depositIds,
        uint256[] memory amounts,
        uint256[] memory yieldIds,
        uint256[] memory yieldAmounts
    ) external override {
        require(depositIds.length == amounts.length, "sp.batchWithdraw: INVALID_DEPOSITS_AMOUNTS");
        require(yieldIds.length == yieldAmounts.length, "sp.batchWithdraw: INVALID_YIELDS_AMOUNTS");
        User storage user = users[msg.sender];
        _processRewards(msg.sender, user);
        emit BatchWithdraw(msg.sender, depositIds, amounts, yieldIds, yieldAmounts);
        uint256 lockTime = factory.lockTime();

        uint256 yieldAmount;
        uint256 stakeAmount;
        uint256 _amount;
        uint256 _id;
        uint256 newWeight;
        uint256 deltaUsersLockingWeight;
        Deposit memory stakeDeposit;
        for (uint256 i = 0; i < depositIds.length; i++) {
            _amount = amounts[i];
            _id = depositIds[i];
            require(_amount != 0, "sp.batchWithdraw: INVALID_DEPOSIT_AMOUNT");
            stakeDeposit = user.deposits[_id];
            require(
                stakeDeposit.lockFrom == 0 || block.timestamp > stakeDeposit.lockUntil,
                "sp.batchWithdraw: DEPOSIT_LOCKED"
            );
            require(stakeDeposit.amount >= _amount, "sp.batchWithdraw: EXCEED_DEPOSIT_STAKED");

            newWeight =
                (((stakeDeposit.lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
                    lockTime +
                    WEIGHT_MULTIPLIER) *
                (stakeDeposit.amount - _amount);

            stakeAmount += _amount;
            deltaUsersLockingWeight += (stakeDeposit.weight - newWeight);

            if (stakeDeposit.amount == _amount) {
                delete user.deposits[_id];
            } else {
                stakeDeposit.amount -= _amount;
                stakeDeposit.weight = newWeight;
                user.deposits[_id] = stakeDeposit;
            }
        }
        user.totalWeight -= deltaUsersLockingWeight;
        usersLockingWeight -= deltaUsersLockingWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;

        Yield memory stakeYield;
        for (uint256 i = 0; i < yieldIds.length; i++) {
            _amount = yieldAmounts[i];
            _id = yieldIds[i];
            require(_amount != 0, "sp.batchWithdraw: INVALID_YIELD_AMOUNT");
            stakeYield = user.yields[_id];
            require(
                stakeYield.lockFrom == 0 || block.timestamp > stakeYield.lockUntil,
                "sp.batchWithdraw: YIELD_LOCKED"
            );
            require(stakeYield.amount >= _amount, "sp.batchWithdraw: EXCEED_YIELD_STAKED");

            yieldAmount += _amount;

            if (stakeYield.amount == _amount) {
                delete user.yields[_id];
            } else {
                stakeYield.amount -= _amount;
                user.yields[_id] = stakeYield;
            }
        }

        if (yieldAmount > 0) {
            user.tokenAmount -= yieldAmount;
            factory.transferYieldTo(msg.sender, yieldAmount);
        }
        if (stakeAmount > 0) {
            user.tokenAmount -= stakeAmount;
            IERC20(poolToken).transfer(msg.sender, stakeAmount);
        }
    }

    function forceWithdraw(uint256[] memory _yieldIds) external override {
        require(poolToken == apex, "sp.forceWithdraw: INVALID_POOL_TOKEN");
        uint256 minRemainRatio = factory.minRemainRatioAfterBurn();
        address _staker = msg.sender;
        uint256 now256 = block.timestamp;
        syncWeightPrice();
        User storage user = users[_staker];

        uint256 deltaTotalAmount;
        uint256 yieldAmount;

        //force withdraw existing rewards
        Yield memory yield;
        for (uint256 i = 0; i < _yieldIds.length; i++) {
            yield = user.yields[_yieldIds[i]];
            deltaTotalAmount += yield.amount;

            if (now256 >= yield.lockUntil) {
                yieldAmount += yield.amount;
            } else {
                yieldAmount +=
                    (yield.amount *
                        (minRemainRatio +
                            ((10000 - minRemainRatio) * (now256 - yield.lockFrom)) /
                            factory.lockTime())) /
                    10000;
            }
            delete user.yields[_yieldIds[i]];
        }

        //force withdraw new reward
        uint256 _yieldRewardsPerWeight = yieldRewardsPerWeight;
        uint256 deltaNewYieldReward = (user.totalWeight * _yieldRewardsPerWeight) /
            REWARD_PER_WEIGHT_MULTIPLIER -
            user.subYieldRewards;
        yieldAmount += ((deltaNewYieldReward * minRemainRatio) / 10000);

        //remaining apeX to boost remaining staker
        uint256 newYieldRewardsPerWeight = _yieldRewardsPerWeight +
            ((deltaTotalAmount + deltaNewYieldReward - yieldAmount) * REWARD_PER_WEIGHT_MULTIPLIER) /
            usersLockingWeight;
        yieldRewardsPerWeight = newYieldRewardsPerWeight;
        user.subYieldRewards = (user.totalWeight * newYieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;

        user.tokenAmount -= deltaTotalAmount;
        if (yieldAmount > 0) {
            factory.transferYieldTo(_staker, yieldAmount);
        }

        emit ForceWithdraw(_staker, _yieldIds);
    }

    //called by other staking pool to stake yield rewards into apeX pool
    function stakeAsPool(address _staker, uint256 _amount) external override {
        require(factory.poolTokenMap(msg.sender) != address(0), "sp.stakeAsPool: ACCESS_DENIED");
        syncWeightPrice();

        User storage user = users[_staker];

        uint256 latestYieldReward = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        uint256 pendingYield = latestYieldReward - user.subYieldRewards;
        user.subYieldRewards = latestYieldReward;

        uint256 yieldAmount = _amount + pendingYield;
        uint256 now256 = block.timestamp;
        uint256 lockUntil = now256 + factory.lockTime();
        uint256 yieldId = user.yields.length;
        Yield memory newYield = Yield({amount: yieldAmount, lockFrom: now256, lockUntil: lockUntil});
        user.yields.push(newYield);

        user.tokenAmount += yieldAmount;

        emit StakeAsPool(msg.sender, _staker, yieldId, _amount, yieldAmount, now256, lockUntil);
    }

    //only can extend lock time
    function updateStakeLock(uint256 _depositId, uint256 _lockUntil) external override {
        uint256 now256 = block.timestamp;
        require(_lockUntil > now256, "sp.updateStakeLock: INVALID_LOCK_UNTIL");

        uint256 lockTime = factory.lockTime();
        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        Deposit storage stakeDeposit = user.deposits[_depositId];
        require(_lockUntil > stakeDeposit.lockUntil, "sp.updateStakeLock: INVALID_NEW_LOCK");

        if (stakeDeposit.lockFrom == 0) {
            require(_lockUntil <= now256 + lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK_PERIOD");
            stakeDeposit.lockFrom = now256;
        } else {
            require(_lockUntil <= stakeDeposit.lockFrom + lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK");
        }

        uint256 oldWeight = stakeDeposit.weight;
        uint256 newWeight = (((_lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
            lockTime +
            WEIGHT_MULTIPLIER) * stakeDeposit.amount;

        stakeDeposit.lockUntil = _lockUntil;
        stakeDeposit.weight = newWeight;
        user.totalWeight = user.totalWeight - oldWeight + newWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight = usersLockingWeight - oldWeight + newWeight;

        emit UpdateStakeLock(_staker, _depositId, stakeDeposit.lockFrom, _lockUntil);
    }

    function processRewards() external override {
        address staker = msg.sender;
        User storage user = users[staker];

        _processRewards(staker, user);
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    function syncWeightPrice() public {
        if (factory.shouldUpdateRatio()) {
            factory.updateApeXPerSec();
        }

        uint256 endTimestamp = factory.endTimestamp();
        uint256 currentTimestamp = block.timestamp;
        if (lastYieldDistribution >= endTimestamp || lastYieldDistribution >= currentTimestamp) {
            return;
        }
        if (usersLockingWeight == 0) {
            lastYieldDistribution = currentTimestamp;
            return;
        }

        uint256 apexReward = factory.calStakingPoolApeXReward(lastYieldDistribution, poolToken);
        yieldRewardsPerWeight += (apexReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        lastYieldDistribution = currentTimestamp > endTimestamp ? endTimestamp : currentTimestamp;

        emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    //update weight price, then if apex, add deposits; if not, stake as pool.
    function _processRewards(address _staker, User storage user) internal {
        syncWeightPrice();

        //if no yield
        if (user.tokenAmount == 0) return;
        uint256 yieldAmount = (user.totalWeight * yieldRewardsPerWeight) /
            REWARD_PER_WEIGHT_MULTIPLIER -
            user.subYieldRewards;
        if (yieldAmount == 0) return;

        //if self is apeX pool, lock the yield reward; if not, stake the yield reward to apeX pool.
        if (poolToken == apex) {
            uint256 now256 = block.timestamp;
            uint256 lockUntil = now256 + factory.lockTime();
            uint256 yieldId = user.yields.length;
            Yield memory newYield = Yield({amount: yieldAmount, lockFrom: now256, lockUntil: lockUntil});
            user.yields.push(newYield);
            user.tokenAmount += yieldAmount;
            emit YieldClaimed(_staker, yieldId, yieldAmount, now256, lockUntil);
        } else {
            address apexStakingPool = factory.getPoolAddress(apex);
            IStakingPool(apexStakingPool).stakeAsPool(_staker, yieldAmount);
        }
    }

    function pendingYieldRewards(address _staker) external view returns (uint256 pending) {
        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight;

        if (block.timestamp > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 apexReward = factory.calStakingPoolApeXReward(lastYieldDistribution, poolToken);
            newYieldRewardsPerWeight += (apexReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        }

        User memory user = users[_staker];
        pending = (user.totalWeight * newYieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER - user.subYieldRewards;
    }

    function getStakeInfo(address _user)
        external
        view
        override
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        )
    {
        User memory user = users[_user];
        return (user.tokenAmount, user.totalWeight, user.subYieldRewards);
    }

    function getDeposit(address _user, uint256 _depositId) external view override returns (Deposit memory) {
        return users[_user].deposits[_depositId];
    }

    function getDepositsLength(address _user) external view override returns (uint256) {
        return users[_user].deposits.length;
    }

    function getYield(address _user, uint256 _yieldId) external view override returns (Yield memory) {
        return users[_user].yields[_yieldId];
    }

    function getYieldsLength(address _user) external view override returns (uint256) {
        return users[_user].yields.length;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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