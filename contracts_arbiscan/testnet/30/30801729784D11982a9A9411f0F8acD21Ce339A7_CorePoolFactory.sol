// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICorePool.sol";
import "../interfaces/ICorePoolFactory.sol";
import "../libraries/ApexAware.sol";
import "../utils/Ownable.sol";
import "./CorePool.sol";

contract CorePoolFactory is ICorePoolFactory, Ownable, ApexAware {
    uint256 public immutable blocksPerUpdate;

    uint256 public apexPerBlock;

    uint256 public totalWeight;

    uint256 public override endBlock;

    uint256 public lastRatioUpdate;

    mapping(address => PoolInfo) public pools;

    mapping(address => address) public override poolTokenMap;

    constructor(
        address _apex,
        uint256 _apexPerBlock,
        uint256 _blocksPerUpdate,
        uint256 _initBlock,
        uint256 _endBlock
    ) ApexAware(_apex) {
        require(_apexPerBlock > 0, "APEX/block not set");
        require(_blocksPerUpdate > 0, "blocks/update not set");
        require(_initBlock > 0, "init block not set");
        require(_endBlock > _initBlock, "invalid end block: must be greater than init block");

        apexPerBlock = _apexPerBlock;
        blocksPerUpdate = _blocksPerUpdate;
        lastRatioUpdate = _initBlock;
        endBlock = _endBlock;
    }

    function createPool(
        address _poolToken,
        uint256 _initBlock,
        uint256 _weight
    ) external virtual override onlyAdmin {
        ICorePool pool = new CorePool(address(this), _poolToken, apex, _initBlock);
        registerPool(address(pool), _weight);
    }

    function registerPool(address _pool, uint256 _weight) public override onlyAdmin {
        require(poolTokenMap[_pool] == address(0), "this pool is already registered");
        address poolToken = ICorePool(_pool).poolToken();
        require(poolToken != address(0), "address is 0");

        pools[poolToken] = PoolInfo({pool: _pool, weight: _weight});
        poolTokenMap[_pool] = poolToken;
        totalWeight += _weight;

        emit PoolRegistered(msg.sender, poolToken, _pool, _weight);
    }

    function updateApexPerBlock() external override {
        require(shouldUpdateRatio(), "too frequent");

        apexPerBlock = (apexPerBlock * 97) / 100;
        lastRatioUpdate = block.number;
    }

    function mintYieldTo(address _to, uint256 _amount) external override {
        require(poolTokenMap[msg.sender] != address(0), "access denied");

        mintApex(_to, _amount);
    }

    function changePoolWeight(address _pool, uint256 _weight) external override {
        require(msg.sender == admin || poolTokenMap[msg.sender] != address(0));
        address poolToken = poolTokenMap[_pool];
        require(poolToken != address(0), "pool not exist");

        totalWeight = totalWeight + _weight - pools[poolToken].weight;
        pools[poolToken].weight = _weight;

        emit WeightUpdated(msg.sender, _pool, _weight);
    }

    function calCorePoolApexReward(uint256 _lastYieldDistribution, address _poolToken)
        external
        view
        override
        returns (uint256 reward)
    {
        uint256 blockNumber = block.number;
        uint256 blocksPassed = blockNumber > endBlock
            ? endBlock - _lastYieldDistribution
            : blockNumber - _lastYieldDistribution;

        reward = (blocksPassed * apexPerBlock * pools[_poolToken].weight) / totalWeight;
    }

    function shouldUpdateRatio() public view override returns (bool) {
        uint256 blockNumber = block.number;
        return blockNumber > endBlock ? false : blockNumber >= lastRatioUpdate + blocksPerUpdate;
    }

    function getPoolAddress(address _poolToken) external view override returns (address) {
        return pools[_poolToken].pool;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface ICorePool {
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

    function poolToken() external view returns (address);

    function processRewards() external;

    function stake(uint256 amount, uint256 lockUntil) external;

    function unstake(uint256 depositId, uint256 amount) external;

    function stakeAsPool(address staker, uint256 amount) external;

    function updateStakeLock(uint256 depositId, uint256 lockUntil) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface ICorePoolFactory {
    struct PoolInfo {
        address pool;
        uint256 weight;
    }

    event WeightUpdated(address indexed _by, address indexed pool, uint256 weight);

    event PoolRegistered(address indexed _by, address indexed poolToken, address indexed pool, uint256 weight);

    function endBlock() external view returns (uint256);

    function shouldUpdateRatio() external view returns (bool);

    function poolTokenMap(address pool) external view returns (address);

    function getPoolAddress(address poolToken) external view returns (address);

    function calCorePoolApexReward(uint256 lastYieldDistribution, address poolToken)
        external
        view
        returns (uint256 reward);

    function updateApexPerBlock() external;

    function createPool(
        address poolToken,
        uint256 initBlock,
        uint256 weight
    ) external;

    function registerPool(address pool, uint256 weight) external;

    function mintYieldTo(address _to, uint256 _amount) external;

    function changePoolWeight(address poolAddr, uint256 weight) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMintableERC20.sol";
import "../utils/Reentrant.sol";

abstract contract ApexAware is Reentrant {
    address public apex;

    constructor(address _apex) {
        require(_apex != address(0), "apex address not set");
        apex = _apex;
    }

    function transferToken(address _to, uint256 _value) internal nonReentrant {
        IMintableERC20(apex).transferFrom(address(this), _to, _value);
    }

    function mintApex(address _to, uint256 _value) internal nonReentrant {
        IMintableERC20(apex).mint(_to, _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public admin;
    address public pendingAdmin;

    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Ownable: REQUIRE_ADMIN");
        _;
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin {
        require(pendingAdmin != newPendingAdmin, "Ownable: ALREADY_SET");
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin);
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "Ownable: REQUIRE_PENDING_ADMIN");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICorePool.sol";
import "../interfaces/ICorePoolFactory.sol";
import "../interfaces/IERC20.sol";
import "../libraries/ERC20Aware.sol";

contract CorePool is ICorePool, ERC20Aware {
    uint256 internal constant ONE_YEAR = 365 days;

    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    address public immutable apex;

    address public immutable override poolToken;

    ICorePoolFactory public immutable factory;

    uint256 public lastYieldDistribution;

    uint256 public yieldRewardsPerWeight;

    uint256 public usersLockingWeight;

    mapping(address => User) public users;

    constructor(
        address _factory,
        address _poolToken,
        address _apex,
        uint256 _initBlock
    ) ERC20Aware(_poolToken) {
        require(address(_factory) != address(0), "apex Pool fct address not set");
        require(_poolToken != address(0), "pool token address not set");
        require(_initBlock > 0, "init block not set");
        apex = _apex;
        factory = ICorePoolFactory(_factory);
        poolToken = _poolToken;
        lastYieldDistribution = _initBlock;
    }

    function stake(uint256 _amount, uint256 _lockUntil) external override {
        _stake(msg.sender, _amount, _lockUntil);
    }

    function unstake(uint256 _depositId, uint256 _amount) external override {
        _unstake(msg.sender, _depositId, _amount);
    }

    function _stake(
        address _staker,
        uint256 _amount,
        uint256 _lockUntil
    ) internal virtual {
        uint256 now256 = block.timestamp;
        require(_amount > 0, "zero amount");
        require(_lockUntil == 0 || (_lockUntil > now256 && _lockUntil <= now256 + ONE_YEAR), "invalid lock interval");

        User storage user = users[_staker];
        _processRewards(_staker, user);

        uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
        transferTokenFrom(msg.sender, address(this), _amount);
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

    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual {
        require(_amount > 0, "zero amount");
        uint256 now256 = block.timestamp;
        User storage user = users[_staker];
        Deposit storage stakeDeposit = user.deposits[_depositId];
        require(stakeDeposit.lockFrom == 0 || now256 > stakeDeposit.lockUntil, "deposit not yet unlocked");
        require(stakeDeposit.amount >= _amount, "amount exceeds stake");
        _processRewards(_staker, user);

        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight = (((stakeDeposit.lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
            ONE_YEAR +
            WEIGHT_MULTIPLIER) * (stakeDeposit.amount - _amount);
        bool isYield = stakeDeposit.isYield;
        if (stakeDeposit.amount - _amount == 0) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.amount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        if (isYield) {
            factory.mintYieldTo(msg.sender, _amount);
        } else {
            transferTokenFrom(address(this), msg.sender, _amount);
        }
    }

    function stakeAsPool(address _staker, uint256 _amount) external override {
        require(factory.poolTokenMap(msg.sender) != address(0), "access denied");
        syncWeightPrice(); //need sync apexCorePool

        User storage user = users[_staker];

        uint256 pendingYield = weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
        uint256 yieldAmount = _amount + pendingYield;
        uint256 yieldWeight = yieldAmount * YEAR_STAKE_WEIGHT_MULTIPLIER;
        uint256 now256 = block.timestamp;
        Deposit memory newDeposit = Deposit({
            amount: yieldAmount,
            weight: yieldWeight,
            lockFrom: now256,
            lockUntil: now256 + ONE_YEAR,
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
        require(_lockUntil > now256, "lock should be in the future");

        address _staker = msg.sender;
        User storage user = users[_staker];
        Deposit storage stakeDeposit = user.deposits[_depositId];
        require(_lockUntil > stakeDeposit.lockUntil, "invalid new lock");

        if (stakeDeposit.lockFrom == 0) {
            require(_lockUntil <= now256 + ONE_YEAR, "max lock period is 365 days");
            stakeDeposit.lockFrom = now256;
        } else {
            require(_lockUntil <= stakeDeposit.lockFrom + ONE_YEAR, "max lock period is 365 days");
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

    function processRewards() external virtual override {
        User storage user = users[msg.sender];

        _processRewards(msg.sender, user);
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
    }

    function syncWeightPrice() public {
        if (factory.shouldUpdateRatio()) {
            factory.updateApexPerBlock();
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

        uint256 apexReward = factory.calCorePoolApexReward(lastYieldDistribution, poolToken);
        yieldRewardsPerWeight += deltaWeightPrice(apexReward, usersLockingWeight);

        lastYieldDistribution = blockNumber > endBlock ? endBlock : blockNumber;

        emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    //update weight price, then if apex, add deposits; if not, stake as pool.
    function _processRewards(address _staker, User storage user) internal virtual {
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
                lockUntil: now256 + ONE_YEAR,
                isYield: true
            });
            user.deposits.push(newDeposit);
            user.tokenAmount += yieldAmount;
            user.totalWeight += yieldWeight;
            usersLockingWeight += yieldWeight;
        } else {
            address apexCorePool = factory.getPoolAddress(apex);
            ICorePool(apexCorePool).stakeAsPool(_staker, yieldAmount);
        }

        emit YieldClaimed(msg.sender, _staker, yieldAmount);
    }

    function pendingYieldRewards(address _staker) external view returns (uint256 pending) {
        uint256 blockNumber = block.number;
        uint256 newYieldRewardsPerWeight;

        if (blockNumber > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 apexReward = factory.calCorePoolApexReward(lastYieldDistribution, poolToken);
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

import "./IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 value) external;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered = false;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../utils/Reentrant.sol";

abstract contract ERC20Aware is Reentrant {
    address public token;

    constructor(address _token) {
        require(_token != address(0), "token address not set");
        token = _token;
    }

    function transferTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal nonReentrant {
        IERC20(token).transferFrom(_from, _to, _value);
    }
}