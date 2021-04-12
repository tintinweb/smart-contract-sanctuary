// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// BirdFarm is the master of RewardToken. He can make RewardToken and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once REWARD_TOKEN is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

/// @title Farming service for pool tokens
/// @author Bird Money
/// @notice You can use this contract to deposit pool tokens and get rewards
/// @dev Admin can add a new Pool, users can deposit pool tokens, harvestReward, withdraw pool tokens
contract BirdFarm is Ownable {
    using SafeMath for uint256;

    /// @notice user can get reward and unstake after this time only.
    /// @dev No froze time initially, if needed it can be added and informed to community.
    uint256 public unstakeFrozenTime = 0 seconds;

    /// @dev No froze time initially, if needed it can be added and informed to community.
    uint256 public rewardFrozenTime = 0 seconds;

    /// @dev The block number when REWARD_TOKEN distribution starts.
    uint256 public startRewardBlock = 0;

    /// @dev The block number when REWARD_TOKEN distribution stops.
    uint256 public endRewardBlock = MAX_UINT; // MAX UINT

    /// @dev REWARD_TOKEN tokens created per block.
    uint256 public rewardTokenPerBlock = 100;

    /// @dev The REWARD_TOKEN TOKEN!
    IERC20 public rewardToken;

    /// @dev Info of each pool.
    PoolInfo[] public poolInfo;

    /// @dev To prevent a token to added in multiple pools
    mapping(IERC20 => bool) public uniqueTokenInPool;

    /// @dev Info of each user that staked tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice save pending rewards with respect to each pool id
    /// @dev exmaple: user_address  =>  ( pool_id => UsersPendingReward)
    mapping(address => mapping(uint256 => uint256)) public pendingRewardOf;

    /// @dev Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /// @dev max number used to set some variable like reward ending block initially
    uint256 public constant MAX_UINT = type(uint256).max;

    /// @dev deposit tokens in contract to get reward
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /// @dev withdraw deposit tokens in contract to get reward
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @dev harvest tokens from contract to get reward
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

    /// @dev emergeny withdraw of pool tokens from contract
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /// @dev emergeny withdraw of pool tokens from contract
    /// @param _rewardToken the token in which reward will be givenss
    constructor(IERC20 _rewardToken) public {
        rewardToken = _rewardToken;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many pool tokens the user has staked
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 unstakeTime; // user can unstake pool tokens at this time or after this time to get reward
        //
        // We do some fancy math here. Basically, any point in time, the amount of REWARD_TOKENs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws pool tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User pnding reward saved to this contract.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 poolToken; // Address of pool token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. REWARD_TOKENs to distribute per block.
        uint256 lastRewardBlock; // Last block number that REWARD_TOKENs distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated REWARD_TOKENs per share, times 1e12. See below.
    }

    /// @notice Adds a new pool. Can only be called by the owner.
    /// @dev Only adds unique pool token
    /// @param _allocPoint The weight of this pool. The more it is the more percentage of reward per block it will get for its users with respect to other pools. But the total reward per block remains same.
    /// @param _poolToken The Liquidity Pool Token of this pool
    /// @param _withUpdate if true then it updates the reward tokens to be given for each of the tokens staked
    function addPool(
        uint256 _allocPoint,
        IERC20 _poolToken,
        bool _withUpdate
    ) external onlyOwner {
        require(!uniqueTokenInPool[_poolToken], "Token already added");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startRewardBlock ? block.number : startRewardBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                poolToken: _poolToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardTokenPerShare: 0
            })
        );
        uniqueTokenInPool[_poolToken] = true;
        emit PoolAdded(_allocPoint, _poolToken, _withUpdate);
    }

    event PoolAdded(uint256 allocPoint, IERC20 poolToken, bool withUpdate);

    /// @notice Update the given pool's REWARD_TOKEN pool weight. Can only be called by the owner.
    /// @dev it can change weight of pool with repect to other pools
    /// @param _pid pool id
    /// @param _allocPoint The weight of this pool. The more it is the more percentage of reward per block it will get for its users with respect to other pools. But the total reward per block remains same.
    /// @param _withUpdate if true then it updates the reward tokens to be given for each of the tokens staked
    function setAllocPoint(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /// @notice Tells the number of blocks eligible for rewards.
    /// @dev Return reward multiplier over the given _from to _to block
    /// @param _from start block
    /// @param _to end block
    /// @return number of blocks eligible for rewards

    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        uint256 from = _from < startRewardBlock ? startRewardBlock : _from;
        uint256 to = _to > endRewardBlock ? endRewardBlock : _to;
        return to.sub(from);
    }

    /// @notice get reward tokens to show on UI
    /// @dev calculates reward tokens of a user with repect to pool id
    /// @param _pid the pool id
    /// @param _user the user who is calls this function
    /// @return pending reward token of a user
    // View function to see pending REWARD_TOKENs on frontend.
    function pendingRewardToken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 poolSupply = pool.poolToken.balanceOf(address(this));

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardTokenReward =
            multiplier
                .mul(rewardTokenPerBlock)
                .mul(pool.allocPoint)
                .mul(1e12)
                .div(totalAllocPoint);
        accRewardTokenPerShare = accRewardTokenPerShare.add(
            rewardTokenReward.div(poolSupply)
        );

        return
            user.amount.mul(accRewardTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
    }

    /// @notice updates different variables needed for reward calculation for all pools
    /// @dev updates lastRewardBlock and accRewardTokenPerShare of all pools. Be careful of gas spending!
    function massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice updates different variables needed for reward calculation
    /// @dev updates lastRewardBlock and accRewardTokenPerShare of a pool
    /// @param _pid pool id
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number < startRewardBlock || block.number > endRewardBlock) {
            return;
        }

        uint256 poolSupply = pool.poolToken.balanceOf(address(this));
        if (poolSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardTokenReward =
            multiplier
                .mul(rewardTokenPerBlock)
                .mul(pool.allocPoint)
                .mul(1e12)
                .div(totalAllocPoint);
        pool.accRewardTokenPerShare = pool.accRewardTokenPerShare.add(
            rewardTokenReward.div(poolSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    /// @notice deposit tokens to get rewards
    /// @dev deposit pool tokens to BirdFarm for reward tokens allocation.
    /// @param _pid pool id
    /// @param _amount how many tokens you want to stake
    function deposit(uint256 _pid, uint256 _amount) external {
        require(_amount > 0, "Must deposit amount more than ZERO");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            pool.poolToken.balanceOf(msg.sender) >= _amount,
            "Must deposit amount more than ZERO"
        );

        updatePool(_pid);

        uint256 pending =
            user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
        savePendingReward(msg.sender, _pid, pending);
        if (user.amount == 0) user.unstakeTime = now + unstakeFrozenTime;
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(
            1e12
        );
        require(
            pool.poolToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            ),
            "Error in deposit of pool tokens."
        );
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice get the tokens back from BardFarm
    /// @dev withdraw or unstake pool tokens from BidFarm
    /// @param _pid pool id
    /// @param _amount how many pool tokens you want to unstake
    function withdraw(uint256 _pid, uint256 _amount) external {
        require(_amount > 0, "Must withdraw amount more than ZERO");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amount >= _amount,
            "You have less pool tokens available than requested."
        );
        require(now >= user.unstakeTime, "Can not unstake at this time.");

        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
        savePendingReward(msg.sender, _pid, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(
            1e12
        );
        require(
            pool.poolToken.transfer(address(msg.sender), _amount),
            "Error in withdraw pool tokens."
        );
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice harvest reward tokens from BardFarm
    /// @dev harvest reward tokens from BidFarm and update pool variables
    /// @param _pid pool id

    function harvestPendingReward(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            now >= rewardFrozenTime,
            "Can not collect reward at this time."
        );

        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
        savePendingReward(msg.sender, _pid, pending);
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(
            1e12
        );

        uint256 reward = getReward(_pid);
        require(reward > 0, "You have no pending reward.");
        require(
            rewardToken.balanceOf(address(this)) > reward,
            "This contract has not enough balance"
        );

        // User has collected the reward so pending reward is ZERO
        savePendingReward(msg.sender, _pid, 0);

        require(
            rewardToken.transfer(msg.sender, reward),
            "Error in transferring reward."
        );
        emit Harvest(msg.sender, _pid, reward);
    }

    /// @notice get the tokens which user staked. In case of EMERGENCY ONLY.
    /// @dev get the pool tokens back from BardFarm without caring about rewards. EMERGENCY ONLY.
    /// @param _pid pool id
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.amount = 0;
        user.rewardDebt = 0;
        require(
            pool.poolToken.transfer(address(msg.sender), user.amount),
            "Error in emergency withdraw of staked tokens."
        );
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    /// @notice save pending reward tokens
    /// @dev save pending reward tokens so user can harvest reward later when needed
    /// @param _user the user
    /// @param _pid pool id
    /// @param _amount amount of reward tokens
    function savePendingReward(
        address _user,
        uint256 _pid,
        uint256 _amount
    ) internal {
        pendingRewardOf[_user][_pid] = pendingRewardOf[_user][_pid] + _amount;
    }

    /// @notice gets previous rewards of a user
    /// @dev gets the previous rewards of user so that we can add more rewards to it and save
    /// @param _pid pool id
    /// @return saved number of rewards of user
    function getReward(uint256 _pid) internal view returns (uint256) {
        return pendingRewardOf[msg.sender][_pid];
    }

    /// @notice gets previous rewards of a user
    /// @dev gets the previous rewards of user so that we can add more rewards to it and save
    /// @return total number of pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice owner puts reward tokens in contract
    /// @dev owner can add reward token to contract so that it can be distributed to users
    /// @param _amount amount of reward tokens
    function addRewardTokensToContract(uint256 _amount) external onlyOwner {
        require(
            rewardToken.transferFrom(msg.sender, address(this), _amount),
            "Error in adding reward tokens in contract."
        );
        emit AddedRewardTokensToContract(_amount);
    }

    event AddedRewardTokensToContract(uint256 amount);

    /// @notice owner withdraws reward tokens from contract
    /// @dev owner can withdraw reward token from contract
    /// @param _amount amount of reward tokens
    function withdrawRewardTokensFromContract(uint256 _amount)
        external
        onlyOwner
    {
        require(
            rewardToken.transfer(msg.sender, _amount),
            "Error in getting reward tokens from contract."
        );
        emit WithdrawnRewardTokensFromContract(_amount);
    }

    event WithdrawnRewardTokensFromContract(uint256 amount);

    // setters

    /// @notice owner can set multiple values at once
    /// @dev owner can set multiple values at once so it may save gas cost
    /// @param _rewardToken the token in which rewards are given
    /// @param _rewardTokenPerBlock rewards distributed per block to community or users
    /// @param _startRewardBlock the block at which reward token distribution starts
    /// @param _endRewardBlock the block at which reward token distribution ends
    /// @param _unstakeFrozenTime the block at which user can unstake
    /// @param _rewardFrozenTime the block at which user can harvest reward
    function setAll(
        IERC20 _rewardToken,
        uint256 _rewardTokenPerBlock,
        uint256 _startRewardBlock,
        uint256 _endRewardBlock,
        uint256 _unstakeFrozenTime,
        uint256 _rewardFrozenTime
    ) external onlyOwner {
        rewardToken = _rewardToken;
        rewardTokenPerBlock = _rewardTokenPerBlock;
        startRewardBlock = _startRewardBlock;
        endRewardBlock = _endRewardBlock;
        unstakeFrozenTime = _unstakeFrozenTime;
        rewardFrozenTime = _rewardFrozenTime;
        emit ManyValuesChanged(
            _rewardToken,
            _rewardTokenPerBlock,
            _startRewardBlock,
            _endRewardBlock,
            _unstakeFrozenTime,
            rewardFrozenTime
        );
    }

    event ManyValuesChanged(
        IERC20 rewardToken,
        uint256 rewardTokenPerBlock,
        uint256 startRewardBlock,
        uint256 endRewardBlock,
        uint256 unstakeFrozenTime,
        uint256 rewardFrozenTime
    );

    /// @notice owner can change reward token
    /// @dev owner can set reward token
    /// @param _rewardToken the token in which rewards are given

    function setRewardToken(IERC20 _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
        emit RewardTokenChanged(_rewardToken);
    }

    event RewardTokenChanged(IERC20 rewardToken);

    /// @notice owner can change unstake frozen time
    /// @dev owner can set unstake frozen time
    /// @param _unstakeFrozenTime the block at which user can unstake
    function setUnstakeFrozenTime(uint256 _unstakeFrozenTime)
        external
        onlyOwner
    {
        unstakeFrozenTime = _unstakeFrozenTime;
        emit UnstakeFrozenTimeChanged(_unstakeFrozenTime);
    }

    event UnstakeFrozenTimeChanged(uint256 unstakeFrozenTime);

    /// @notice owner can change reward frozen time
    /// @dev owner can set reward frozen time
    /// @param _rewardFrozenTime the block at which user can harvest reward
    function setRewardFrozenTime(uint256 _rewardFrozenTime) external onlyOwner {
        rewardFrozenTime = _rewardFrozenTime;
        emit RewardFrozenTimeChanged(_rewardFrozenTime);
    }

    event RewardFrozenTimeChanged(uint256 rewardFrozenTime);

    /// @notice owner can change reward token per block
    /// @dev owner can set reward token per block
    /// @param _rewardTokenPerBlock rewards distributed per block to community or users
    function setRewardTokenPerBlock(uint256 _rewardTokenPerBlock)
        external
        onlyOwner
    {
        rewardTokenPerBlock = _rewardTokenPerBlock;
        emit RewardTokenPerBlockChanged(_rewardTokenPerBlock);
    }

    event RewardTokenPerBlockChanged(uint256 rewardTokenPerBlock);

    /// @notice owner can change start reward block
    /// @dev owner can set start reward block
    /// @param _startRewardBlock the block at which reward token distribution starts
    function setStartRewardBlock(uint256 _startRewardBlock) external onlyOwner {
        require(
            _startRewardBlock <= endRewardBlock,
            "Start block must be less or equal to end reward block."
        );
        startRewardBlock = _startRewardBlock;
        emit StartRewardBlockChanged(_startRewardBlock);
    }

    event StartRewardBlockChanged(uint256 startRewardBlock);

    /// @notice owner can change end reward block
    /// @dev owner can set end reward block
    /// @param _endRewardBlock the block at which reward token distribution ends

    function setEndRewardBlock(uint256 _endRewardBlock) external onlyOwner {
        require(
            startRewardBlock <= _endRewardBlock,
            "End reward block must be greater or equal to start reward block."
        );
        endRewardBlock = _endRewardBlock;
        emit EndRewardBlockChanged(_endRewardBlock);
    }

    event EndRewardBlockChanged(uint256 endRewardBlock);

    // migrator
    IMigratorChef public migrator;

    /// @notice owner can set a migrator contract
    /// @dev owner can set a migrator contract to migrate pool tokens
    /// @param _migrator the migrator contract
    function setMigrator(IMigratorChef _migrator) external onlyOwner {
        migrator = _migrator;
    }

    /// @notice the migarting logic
    /// @dev  Migrate pool token to another pool token contract. Can be called by anyone. We trust that migrator contract is good.
    /// @param _pid the pool id
    function migrate(uint256 _pid) external {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 poolToken = pool.poolToken;
        uint256 bal = poolToken.balanceOf(address(this));
        poolToken.approve(address(migrator), bal);
        IERC20 newpoolToken = migrator.migrate(poolToken);
        require(bal == newpoolToken.balanceOf(address(this)), "migrate: bad");
        pool.poolToken = newpoolToken;
    }
}

interface IMigratorChef {
    /// @notice the migarting logic
    /// @dev  Migrate pool token to another pool token contract. Can be called by anyone. We trust that migrator contract is good.
    // Perform pool token migration from legacy UniswapV2 to BirdFarm.
    // Take the current pool token address and return the new pool token address.
    // Migrator should have full access to the caller's pool token.
    // Return the new pool token address.
    //
    // Migrator must have allowance access to UniswapV2 LP tokens
    // Bird Money must mint EXACTLY the same amount of BirdMoney BLP tokens
    /// @param token the pool token
    function migrate(IERC20 token) external returns (IERC20);
}

// todo Bird Money BLP Tokens discuss todo

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

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}