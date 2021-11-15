/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/interfaces/ICorePool.sol

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


// File contracts/interfaces/ICorePoolFactory.sol



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


// File contracts/interfaces/IERC20.sol



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


// File contracts/utils/Reentrant.sol



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


// File contracts/libraries/ERC20Aware.sol


pragma solidity ^0.8.0;


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


// File contracts/pools/CorePool.sol


pragma solidity ^0.8.0;




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
        require(address(_factory) != address(0), "cp: INVALID_FACTORY");
        require(_poolToken != address(0), "cp: INVALID_POOL_TOKEN");
        require(_initBlock > 0, "cp: INVALID_INIT_BLOCK");
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
    ) internal {
        uint256 now256 = block.timestamp;
        require(_amount > 0, "cp._stake: INVALID_AMOUNT");
        require(
            _lockUntil == 0 || (_lockUntil > now256 && _lockUntil <= now256 + ONE_YEAR),
            "cp._stake: INVALID_LOCK_INTERVAL"
        );

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
    ) internal {
        require(_amount > 0, "cp._unstake: INVALID_AMOUNT");
        uint256 now256 = block.timestamp;
        User storage user = users[_staker];
        Deposit storage stakeDeposit = user.deposits[_depositId];
        require(stakeDeposit.lockFrom == 0 || now256 > stakeDeposit.lockUntil, "cp._unstake: DEPOSIT_LOCKED");
        require(stakeDeposit.amount >= _amount, "cp._unstake: EXCEED_STAKED");
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
        require(factory.poolTokenMap(msg.sender) != address(0), "cp.stakeAsPool: ACCESS_DENIED");
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