/**
 *Submitted for verification at polygonscan.com on 2021-10-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;



// Part: ICompactFactory

interface ICompactFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function feeReceiver() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function vampire() external view returns (address);

    function setVampire(address) external;
}

// Part: ICompactPair

interface ICompactPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimeLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address tokenA, address tokenB) external;

    function addLpIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external;

    function addVolumeIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external;
}

// Part: IERC20

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// Part: Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferInitiated(
        address indexed owner,
        address indexed pendingOwner
    );

    /**
     * @dev Initializes the contract setting a given address as the initial owner.
     */
    constructor(address owner) internal {
        // we do not just use msg.sender because it isn't compatible with using the SingletonDeployer
        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
        @dev Initiates a transfer of ownership. The transfer must be confirmed
        by `_pendingOwner` by calling to `acceptOwnership`.
     */
    function transferOwnership(address _pendingOwner) public onlyOwner {
        pendingOwner = _pendingOwner;
        emit OwnershipTransferInitiated(_owner, _pendingOwner);
    }

    /**
        @dev Accepts a pending transfer of ownership. Splitting the transfer
        across two transactions provides a sanity check in case of an incorrect
        `pendingOwner`. The transaction cannot always easily be simulated, e.g.
        if the owner is a Gnosis safe.
     */
    function acceptOwnership() public {
        require(msg.sender == pendingOwner, "Ownable: caller is not new owner");
        emit OwnershipTransferred(_owner, pendingOwner);
        _owner = pendingOwner;
    }
}

// Part: SafeMath

/// @title a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
}

// Part: MasterVampire

/**
    @title MasterVampire manages a vampire attack against UniswapV2-like exchanges.

    @dev
    Note that it's ownable and the owner wields power over incentives.

    Unlike Sushi's MasterChef...
    - The initial BONUS_MULTIPLIER lasts for 2 days and is only 2x (not 10x).
    - Once the rewards start, the owner has **NO** special power over the protocol.
    - Once the exchange is launched, rewards from this contract end and new deposits are rejected.
    - If you have liquidity staked through the migration, you will instantly get an extra day's worth of bonus tokens!

    Have fun reading it. Hopefully it's bug-free. Vitalik bless.
 */
contract MasterVampire is Ownable {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewards
        // entitled to a user that are pending to be distributed are:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        ICompactPair lpToken; // Address of UniswapV2Pair-like token.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // The last time that reward distribution occured.
        uint256 accRewardPerShare; // Accumulated reward per share, times 1e12. See below.
        uint256 lpMigrated; // Total amount of LP tokens migrated
    }
    // The token that will be given as a reward for staking
    IERC20 public reward;
    // Time when bonus reward period ends.
    uint256 public bonusEndTime;
    // Rewards tokens given per second.
    uint256 public rewardPerSecond;
    // Bonus muliplier for early deposits.
    // Sushi gave 10x, but that seems excessive
    uint256 public constant BONUS_MULTIPLIER = 2;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block time when rewards start.
    uint256 public startTime;
    // The time that the Compact exchange opens.
    uint256 public exchangeOpenTime;
    // The address for the Compact exchange factory.
    ICompactFactory public factory;
    // mapping from (tokenA ^ tokenB) to poolInfo `index + 1`
    // it's +1 because 0 means "not found"
    // this protects us from adding the same pair multiple times and breaking rewards
    mapping(bytes20 => uint256) public tokens;
    // The number of times LP tokens that have been migrated to the new factory
    uint256 public numPoolsMigrated;
    // True once all migrations are complete and the exchange is open
    bool public exchangeOpen;
    // CompactPair.mint uses desiredLiquidity to keep token value similar between old and new factory
    uint256 public desiredLiquidity = uint256(-1);

    // total reward tokens to be distributed to users who remain for the migration
    uint256 public migrationReward;

    uint256 internal constant DAY = 86400;
    uint256 internal constant WEEK = DAY * 7;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        address _owner,
        IERC20 _reward,
        uint256 _startTime
    ) public Ownable(_owner) {
        reward = _reward;

        // StakingRewards must start on the epoch week, so this should too
        startTime = (_startTime / WEEK) * WEEK;
        require(startTime == _startTime, "!epoch week");

        // 2 days of bonus rewards
        bonusEndTime = _startTime + DAY * 2;
        // exchange opens after 1 week of rewards
        exchangeOpenTime = _startTime + WEEK;
        // safety check
        require(startTime < exchangeOpenTime, "bad time");
    }

    /**
        @notice Add rewards to the contract
        @dev Called once by the owner, prior to `startTime`
     */
    function addRewards(uint256 _amount) external onlyOwner {
        require(rewardPerSecond == 0, "already added");
        require(startTime > block.timestamp, "too late");

        // rewards split across 10 days:
        //   7 days of regular rewards
        //  +2 days for 2x rewards
        //  +1 day for the migration bonus
        rewardPerSecond = _amount / (DAY * 10);
        migrationReward = _amount / 10;

        reward.transferFrom(msg.sender, address(this), _amount);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Allow staking another exchange's LP tokens 
    /// @dev Can only be called by the owner before rewards begin.
    function add(
        uint256 _allocPoint,
        ICompactFactory _oldFactory,
        IERC20 _tokenA,
        IERC20 _tokenB
    ) external onlyOwner returns (uint256) {
        require(block.timestamp < startTime, "add: already started");

        // get the LP token from the factory
        ICompactPair lpToken = ICompactPair(
            _oldFactory.getPair(address(_tokenA), address(_tokenB))
        );

        // xor the token addresses so that we don't have to care about order
        bytes20 token_key = bytes20(address(_tokenA)) ^
            bytes20(address(_tokenB));
        if (tokens[token_key] > 0) {
            // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
            revert("dupe");
        }

        // protect us from adding invalid pairs
        require(_tokenA.balanceOf(address(lpToken)) > 0, "no tokenA");
        require(_tokenB.balanceOf(address(lpToken)) > 0, "no tokenB");

        // MasterChef had to "massUpdatePools" here because they could add rewards at any time
        // MasterVampire only allows adding rewards before startTime, so it does not need that

        uint256 lastRewardTime = block.timestamp > startTime
            ? block.timestamp
            : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: lpToken,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accRewardPerShare: 0,
                lpMigrated: 0
            })
        );
        // we do this after pushing to set this to 1 more than the actual index
        // that way fetching 0 means not set
        uint256 length = poolInfo.length;
        tokens[token_key] = length;
        return length;
    }

    /// @notice Migrate another exchange's lp token to our lp contract.
    /// @dev Can be called by anyone post launch.
    /// @dev We trust that migrator contract is good.
    function migrate(uint256 _pid) external returns (ICompactPair newLpToken) {
        require(block.timestamp >= exchangeOpenTime, "exchange not open");
        require(address(factory) != address(0), "factory not set");
        PoolInfo storage pool = poolInfo[_pid];
        ICompactPair oldlLpToken = pool.lpToken;
        if (oldlLpToken.factory() == address(factory)) {
            return oldlLpToken;
        }
        // get the underlying tokens
        address token0 = oldlLpToken.token0();
        address token1 = oldlLpToken.token1();
        // create a new pair with the same tokens
        newLpToken = ICompactPair(factory.getPair(token0, token1));
        if (newLpToken == ICompactPair(address(0))) {
            // factory.createPair will revert if now < factory.launchTime
            newLpToken = ICompactPair(factory.createPair(token0, token1));
        }
        uint256 lpBalance = oldlLpToken.balanceOf(address(this));
        if (lpBalance > 0) {
            // send all of the LP tokens staked with the Vampire to the original pair
            oldlLpToken.transfer(address(oldlLpToken), lpBalance);
            // turn the LP tokens into underlying for the new pair
            oldlLpToken.burn(address(newLpToken));
            // mint LP tokens for the vampire from the migrated underlying tokens
            desiredLiquidity = lpBalance;
            newLpToken.mint(address(this));
            // put desiredLiquidity back
            desiredLiquidity = uint256(-1);
        }
        // migrated another token
        numPoolsMigrated += 1;
        // safety check
        require(
            lpBalance == newLpToken.balanceOf(address(this)),
            "migrate: bad"
        );
        // update the pool so withdraws get the new token
        pool.lpToken = newLpToken;
        // save the amount migrated for calculating the withdraw bonus
        pool.lpMigrated = lpBalance;
    }

    /// @notice One-time owner-only function to set the vampire factory
    function setFactory(ICompactFactory _factory) external onlyOwner {
        require(address(factory) == address(0), "factory can only be set once");
        require(_factory.vampire() == address(this), "wrong vampire");
        factory = _factory;
    }

    /// @notice One-time function to open the factory after liquidity is migrated
    function openExchange() external {
        require(exchangeOpen == false, "factory already open");
        require(address(factory) != address(0), "factory not set");
        require(block.timestamp >= exchangeOpenTime, "early");
        require(numPoolsMigrated > 0, "nothing migrated");
        require(numPoolsMigrated == poolInfo.length, "migrations pending");
        // clear the vampire on the factory to open the factory's createPool function
        factory.setVampire(address(0));
        // the exchange is open! withdrawals will now give a bonus
        exchangeOpen = true;
    }

    /// @notice Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_from >= exchangeOpenTime) {
            // unlike with Sushi's MasterChef, rewards from this contract end once the exchange launches
            return 0;
        }
        if (_to < startTime) {
            // no rewards yet
            return 0;
        }
        if (_from < startTime) {
            // no rewards before start time
            _from = startTime;
        }
        if (_to > exchangeOpenTime) {
            // no rewards after the exchange ends
            _to = exchangeOpenTime;
        }
        if (_to <= bonusEndTime) {
            // all inside the bonus time
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from > bonusEndTime) {
            // all outside the bonus time
            return _to.sub(_from);
        } else {
            // some inside and some outside the bonus time
            return
                bonusEndTime.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndTime)
                );
        }
    }

    /// @notice View function to see pending rewards on the frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256 rewardAmount)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 rewardAmount = multiplier
                .mul(rewardPerSecond)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(
                rewardAmount.mul(1e12).div(lpSupply)
            );
        }
        rewardAmount = user.amount.mul(accRewardPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (block.timestamp >= exchangeOpenTime) {
            require(exchangeOpen, "exchange not open");
            // the exchange has launched. give a bonus for being a part of the liquidity migration
            uint256 migrationBonus = migrationReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            migrationBonus = migrationBonus.mul(user.amount).div(
                pool.lpMigrated
            );
            rewardAmount.add(migrationBonus);
        }
    }

    /// @dev Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardTime,
            block.timestamp
        );
        uint256 rewardAmount = multiplier
            .mul(rewardPerSecond)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            rewardAmount.mul(1e12).div(lpSupply)
        );
        if (multiplier == 0 && block.timestamp >= exchangeOpenTime) {
            // once the multipler is 0, rewards are over
            pool.lastRewardTime = 2**256 - 1;
        } else {
            pool.lastRewardTime = block.timestamp;
        }
    }

    /// @notice Deposit LP tokens to MasterVampire for rewards.
    function deposit(uint256 _pid, uint256 _amount) external {
        require(block.timestamp < exchangeOpenTime, "already launched");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accRewardPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeRewardTransfer(msg.sender, pending);
        }
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function _withdraw(uint256 _pid, uint256 _amount) internal {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        _updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (block.timestamp >= exchangeOpenTime) {
            require(exchangeOpen, "exchange not open");
            // the exchange has launched. give a bonus for being a part of the liquidity migration
            uint256 migrationBonus = migrationReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            migrationBonus = migrationBonus.mul(_amount).div(pool.lpMigrated);
            pending = pending.add(migrationBonus);
        }
        safeRewardTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.lpToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
        @notice Withdraw LP tokens from MasterVampire.
     */
    function withdraw(uint256 _pid, uint256 _amount) public {
        _withdraw(_pid, _amount);
    }

    /**
        @notice Withdraw your full balance of a LP token from MasterVampire.
     */
    function withdrawAll(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount == 0) {
            return;
        }
        _withdraw(_pid, user.amount);
    }

    /**
        @notice Withdraw your full balance of all LP tokens from MasterVampire.
     */
    function massWithdrawAll() external {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            withdrawAll(pid);
        }
    }

    /// @notice Withdraw your LP token deposit and abandon rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.transfer(msg.sender, user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /// @notice Safe reward transfer function, just in case a rounding error causes pool to not have enough rewards.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = reward.balanceOf(address(this));
        if (_amount > rewardBal) {
            reward.transfer(_to, rewardBal);
        } else {
            reward.transfer(_to, _amount);
        }
    }
}

// File: MasterVampireDev.sol

/// @title Development-only version of MasterVampire
contract MasterVampireDev is MasterVampire {
    constructor(
        address _owner,
        IERC20 _reward,
        uint256 _startTime
    ) public MasterVampire(_owner, _reward, _startTime) {}

    /// @notice Development-only function to override timestamps
    function devSetTimes(
        uint256 _startTime,
        uint256 _bonusEndTime,
        uint256 _exchangeOpenTime
    ) external onlyOwner {
        require(_startTime < _bonusEndTime, "bad bonus time");
        require(_bonusEndTime < _exchangeOpenTime, "bad open time");

        startTime = _startTime;
        bonusEndTime = _bonusEndTime;
        exchangeOpenTime = _exchangeOpenTime;
    }
}