// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IStakingPoolMigrator.sol";
import "./interfaces/IStakingPoolRewarder.sol";

/**
 * @title StakingPools
 *
 * @dev A contract for staking Uniswap LP tokens in exchange for locked CONV rewards.
 * No actual CONV tokens will be held or distributed by this contract. Only the amounts
 * are accumulated.
 *
 * @dev The `migrator` in this contract has access to users' staked tokens. Any changes
 * to the migrator address will only take effect after a delay period specified at contract
 * creation.
 *
 * @dev This contract interacts with token contracts via `safeApprove`, `safeTransfer`,
 * and `safeTransferFrom` instead of the standard Solidity interface so that some non-ERC20-
 * compatible tokens (e.g. Tether) can also be staked.
 */
contract StakingPools is Ownable {
    using SafeMath for uint256;

    event PoolCreated(
        uint256 indexed poolId,
        address indexed token,
        uint256 startBlock,
        uint256 endBlock,
        uint256 migrationBlock,
        uint256 rewardPerBlock
    );
    event PoolEndBlockExtended(uint256 indexed poolId, uint256 oldEndBlock, uint256 newEndBlock);
    event PoolMigrationBlockExtended(uint256 indexed poolId, uint256 oldMigrationBlock, uint256 newMigrationBlock);
    event PoolRewardRateChanged(uint256 indexed poolId, uint256 oldRewardPerBlock, uint256 newRewardPerBlock);
    event MigratorChangeProposed(address newMigrator);
    event MigratorChanged(address oldMigrator, address newMigrator);
    event RewarderChanged(address oldRewarder, address newRewarder);
    event PoolMigrated(uint256 indexed poolId, address oldToken, address newToken);
    event Staked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);
    event Unstaked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);
    event RewardRedeemed(uint256 indexed poolId, address indexed staker, address rewarder, uint256 amount);

    /**
     * @param startBlock the block from which reward accumulation starts
     * @param endBlock the block from which reward accumulation stops
     * @param migrationBlock the block since which LP token migration can be triggered
     * @param rewardPerBlock total amount of token to be rewarded in a block
     * @param poolToken token to be staked
     */
    struct PoolInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 migrationBlock;
        uint256 rewardPerBlock;
        address poolToken;
    }
    /**
     * @param totalStakeAmount total amount of staked tokens
     * @param accuRewardPerShare accumulated rewards for a single unit of token staked, multiplied by `ACCU_REWARD_MULTIPLIER`
     * @param accuRewardLastUpdateBlock the block number at which the `accuRewardPerShare` field was last updated
     */
    struct PoolData {
        uint256 totalStakeAmount;
        uint256 accuRewardPerShare;
        uint256 accuRewardLastUpdateBlock;
    }
    /**
     * @param stakeAmount amount of token the user stakes
     * @param pendingReward amount of reward to be redeemed by the user up to the user's last action
     * @param entryAccuRewardPerShare the `accuRewardPerShare` value at the user's last stake/unstake action
     */
    struct UserData {
        uint256 stakeAmount;
        uint256 pendingReward;
        uint256 entryAccuRewardPerShare;
    }
    /**
     * @param proposeTime timestamp when the change is proposed
     * @param newMigrator new migrator address
     */
    struct PendingMigratorChange {
        uint64 proposeTime;
        address newMigrator;
    }

    uint256 public lastPoolId; // The first pool has ID of 1

    IStakingPoolMigrator public migrator;
    uint256 public migratorSetterDelay;
    PendingMigratorChange public pendingMigrator;

    IStakingPoolRewarder public rewarder;

    mapping(uint256 => PoolInfo) public poolInfos;
    mapping(uint256 => PoolData) public poolData;
    mapping(uint256 => mapping(address => UserData)) public userData;

    uint256 private constant ACCU_REWARD_MULTIPLIER = 10**20; // Precision loss prevention

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));
    bytes4 private constant TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    modifier onlyPoolExists(uint256 poolId) {
        require(poolInfos[poolId].endBlock > 0, "StakingPools: pool not found");
        _;
    }

    modifier onlyPoolActive(uint256 poolId) {
        require(
            block.number >= poolInfos[poolId].startBlock && block.number < poolInfos[poolId].endBlock,
            "StakingPools: pool not active"
        );
        _;
    }

    modifier onlyPoolNotEnded(uint256 poolId) {
        require(block.number < poolInfos[poolId].endBlock, "StakingPools: pool ended");
        _;
    }

    function getReward(uint256 poolId, address staker) external view returns (uint256) {
        UserData memory currentUserData = userData[poolId][staker];
        PoolInfo memory currentPoolInfo = poolInfos[poolId];
        PoolData memory currentPoolData = poolData[poolId];

        uint256 latestAccuRewardPerShare =
            currentPoolData.totalStakeAmount > 0
                ? currentPoolData.accuRewardPerShare.add(
                    Math
                        .min(block.number, currentPoolInfo.endBlock)
                        .sub(currentPoolData.accuRewardLastUpdateBlock)
                        .mul(currentPoolInfo.rewardPerBlock)
                        .mul(ACCU_REWARD_MULTIPLIER)
                        .div(currentPoolData.totalStakeAmount)
                )
                : currentPoolData.accuRewardPerShare;

        return
            currentUserData.pendingReward.add(
                currentUserData.stakeAmount.mul(latestAccuRewardPerShare.sub(currentUserData.entryAccuRewardPerShare)).div(
                    ACCU_REWARD_MULTIPLIER
                )
            );
    }

    constructor(uint256 _migratorSetterDelay) {
        require(_migratorSetterDelay > 0, "StakingPools: zero setter delay");

        migratorSetterDelay = _migratorSetterDelay;
    }

    function createPool(
        address token,
        uint256 startBlock,
        uint256 endBlock,
        uint256 migrationBlock,
        uint256 rewardPerBlock
    ) external onlyOwner {
        require(token != address(0), "StakingPools: zero address");
        require(
            startBlock > block.number && endBlock > startBlock && migrationBlock > startBlock,
            "StakingPools: invalid block range"
        );
        require(rewardPerBlock > 0, "StakingPools: reward must be positive");

        uint256 newPoolId = ++lastPoolId;

        poolInfos[newPoolId] = PoolInfo({
            startBlock: startBlock,
            endBlock: endBlock,
            migrationBlock: migrationBlock,
            rewardPerBlock: rewardPerBlock,
            poolToken: token
        });
        poolData[newPoolId] = PoolData({totalStakeAmount: 0, accuRewardPerShare: 0, accuRewardLastUpdateBlock: startBlock});

        emit PoolCreated(newPoolId, token, startBlock, endBlock, migrationBlock, rewardPerBlock);
    }

    function extendEndBlock(uint256 poolId, uint256 newEndBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        uint256 currentEndBlock = poolInfos[poolId].endBlock;
        require(newEndBlock > currentEndBlock, "StakingPools: end block not extended");

        poolInfos[poolId].endBlock = newEndBlock;

        emit PoolEndBlockExtended(poolId, currentEndBlock, newEndBlock);
    }

    function extendMigrationBlock(uint256 poolId, uint256 newMigrationBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        uint256 currentMigrationBlock = poolInfos[poolId].migrationBlock;
        require(newMigrationBlock > currentMigrationBlock, "StakingPools: migration block not extended");

        poolInfos[poolId].migrationBlock = newMigrationBlock;

        emit PoolMigrationBlockExtended(poolId, currentMigrationBlock, newMigrationBlock);
    }

    function setPoolReward(uint256 poolId, uint256 newRewardPerBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        if ( block.number >= poolInfos[poolId].startBlock) {
            // "Settle" rewards up to this block 
             _updatePoolAccuReward(poolId);
        }


        // We're deliberately allowing setting the reward rate to 0 here. If it turns
        // out this, or even changing rates at all, is undesirable after deployment, the
        // ownership of this contract can be transferred to a contract incapable of making
        // calls to this function.
        uint256 currentRewardPerBlock = poolInfos[poolId].rewardPerBlock;
        poolInfos[poolId].rewardPerBlock = newRewardPerBlock;

        emit PoolRewardRateChanged(poolId, currentRewardPerBlock, newRewardPerBlock);
    }

    function proposeMigratorChange(address newMigrator) external onlyOwner {
        pendingMigrator = PendingMigratorChange({proposeTime: uint64(block.timestamp), newMigrator: newMigrator});

        emit MigratorChangeProposed(newMigrator);
    }

    function executeMigratorChange() external {
        require(pendingMigrator.proposeTime > 0, "StakingPools: migrator change proposal not found");
        require(
            block.timestamp >= uint256(pendingMigrator.proposeTime).add(migratorSetterDelay),
            "StakingPools: migrator setter delay not passed"
        );

        address oldMigrator = address(migrator);
        migrator = IStakingPoolMigrator(pendingMigrator.newMigrator);

        // Clear storage
        pendingMigrator = PendingMigratorChange({proposeTime: 0, newMigrator: address(0)});

        emit MigratorChanged(oldMigrator, address(migrator));
    }

    function setRewarder(address newRewarder) external onlyOwner {
        address oldRewarder = address(rewarder);
        rewarder = IStakingPoolRewarder(newRewarder);

        emit RewarderChanged(oldRewarder, newRewarder);
    }

    function migratePool(uint256 poolId) external onlyPoolExists(poolId) {
        require(address(migrator) != address(0), "StakingPools: migrator not set");

        PoolInfo memory currentPoolInfo = poolInfos[poolId];
        PoolData memory currentPoolData = poolData[poolId];
        require(block.number >= currentPoolInfo.migrationBlock, "StakingPools: migration block not reached");

        safeApprove(currentPoolInfo.poolToken, address(migrator), currentPoolData.totalStakeAmount);

        // New token balance is not validated here since the migrator can do whatever
        // it wants anyways (including providing a fake token address with fake balance).
        // It's the migrator contract's responsibility to ensure tokens are properly migrated.
        address newToken =
            migrator.migrate(poolId, address(currentPoolInfo.poolToken), uint256(currentPoolData.totalStakeAmount));
        require(newToken != address(0), "StakingPools: zero new token address");

        poolInfos[poolId].poolToken = newToken;

        emit PoolMigrated(poolId, currentPoolInfo.poolToken, newToken);
    }

    function stake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) onlyPoolActive(poolId) {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _stake(poolId, msg.sender, amount);
    }

    function unstake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _unstake(poolId, msg.sender, amount);
    }

    function emergencyUnstake(uint256 poolId) external onlyPoolExists(poolId) {
        _unstake(poolId, msg.sender, userData[poolId][msg.sender].stakeAmount);

        // Forfeit user rewards to avoid abuse
        userData[poolId][msg.sender].pendingReward = 0;
    }

    function redeemRewards(uint256 poolId) external onlyPoolExists(poolId) {

        redeemRewardsByAddress(poolId, msg.sender);
    }

    function redeemRewardsByAddress(uint256 poolId, address user) public onlyPoolExists(poolId) {

        require(user != address(0), "StakingPools: zero address");

        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, user);

        require(address(rewarder) != address(0), "StakingPools: rewarder not set");

        uint256 rewardToRedeem = userData[poolId][user].pendingReward;
        require(rewardToRedeem > 0, "StakingPools: no reward to redeem");

        userData[poolId][user].pendingReward = 0;

        rewarder.onReward(poolId, user, rewardToRedeem);

        emit RewardRedeemed(poolId, user, address(rewarder), rewardToRedeem);
    }

    function _stake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "StakingPools: cannot stake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.add(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.add(amount);

        safeTransferFrom(poolInfos[poolId].poolToken, user, address(this), amount);

        emit Staked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    function _unstake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "StakingPools: cannot unstake zero amount");

        // No sufficiency check required as sub() will throw anyways
        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.sub(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.sub(amount);

        safeTransfer(poolInfos[poolId].poolToken, user, amount);

        emit Unstaked(poolId, user, poolInfos[poolId].poolToken, amount);
    }

    function _updatePoolAccuReward(uint256 poolId) private {
        PoolInfo storage currentPoolInfo = poolInfos[poolId];
        PoolData storage currentPoolData = poolData[poolId];

        uint256 appliedUpdateBlock = Math.min(block.number, currentPoolInfo.endBlock);
        uint256 durationInBlocks = appliedUpdateBlock.sub(currentPoolData.accuRewardLastUpdateBlock);

        // This saves tx cost when being called multiple times in the same block
        if (durationInBlocks > 0) {
            // No need to update the rate if no one staked at all
            if (currentPoolData.totalStakeAmount > 0) {
                currentPoolData.accuRewardPerShare = currentPoolData.accuRewardPerShare.add(
                    durationInBlocks.mul(currentPoolInfo.rewardPerBlock).mul(ACCU_REWARD_MULTIPLIER).div(
                        currentPoolData.totalStakeAmount
                    )
                );
            }
            currentPoolData.accuRewardLastUpdateBlock = appliedUpdateBlock;
        }
    }

    function _updateStakerReward(uint256 poolId, address staker) private {
        UserData storage currentUserData = userData[poolId][staker];
        PoolData storage currentPoolData = poolData[poolId];

        uint256 stakeAmount = currentUserData.stakeAmount;
        uint256 stakerEntryRate = currentUserData.entryAccuRewardPerShare;
        uint256 accuDifference = currentPoolData.accuRewardPerShare.sub(stakerEntryRate);

        if (accuDifference > 0) {
            currentUserData.pendingReward = currentUserData.pendingReward.add(
                stakeAmount.mul(accuDifference).div(ACCU_REWARD_MULTIPLIER)
            );
            currentUserData.entryAccuRewardPerShare = currentPoolData.accuRewardPerShare;
        }
    }

    function safeApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: approve failed");
    }

    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, sender, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "StakingPools: transferFrom failed");
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
pragma solidity ^0.7.6;

interface IStakingPoolMigrator {
    function migrate(
        uint256 poolId,
        address oldToken,
        uint256 amount
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IStakingPoolRewarder {
    function onReward(
        uint256 poolId,
        address user,
        uint256 amount
    ) external;
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

