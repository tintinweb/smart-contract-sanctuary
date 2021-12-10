// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
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
contract StakingPools is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event PoolCreated(
        uint256 indexed poolId,
        address indexed token,
        uint256 startBlock,
        uint256 endBlock,
        uint256 migrationBlock
        );
    event PoolEndBlockExtended(uint256 indexed poolId, uint256 oldEndBlock, uint256 newEndBlock);
    event PoolMigrationBlockExtended(uint256 indexed poolId, uint256 oldMigrationBlock, uint256 newMigrationBlock);
    event MigratorChangeProposed(address newMigrator);
    event MigratorChanged(address oldMigrator, address newMigrator);
    event RewardInfoAdded(uint256 indexed poolId, address rewarder, uint256 rewardRate, uint8 rewarderIdx);
    event RewardInfoChanged(uint256 indexed poolId, address rewarder, uint256 oldRewardRate, uint256 newRewardRate);
    event PoolMigrated(uint256 indexed poolId, address oldToken, address newToken);
    event Staked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);
    event Unstaked(uint256 indexed poolId, address indexed staker, address token, uint256 amount);
    event RewardRedeemed(uint256 indexed poolId, address indexed staker, address rewarder, uint256 amount);

    /**
     * @param startBlock the block from which reward accumulation starts
     * @param endBlock the block from which reward accumulation stops
     * @param migrationBlock the block since which LP token migration can be triggered
     * @param poolToken token to be staked
     */
    struct PoolInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 migrationBlock;
        address poolToken;
    }
    /**
     * @param rewardPerBlock total amount of token to be rewarded in a block( total of reward token)
     * @param rewarder address of rewarder to vest and dispatch token
     * @param accuRewardPerShare accumulated rewards for a single unit of token staked, multiplied by `ACCU_REWARD_MULTIPLIER`
     * @param accuRewardLastUpdateBlock the block number at which the `accuRewardPerShare` field was last updated
     */
    struct RewardInfo {
        uint256 rewardPerBlock;
        address rewarder;
        uint256 accuRewardPerShare;
        uint256 accuRewardLastUpdateBlock;
    }
    /**
     * @param totalStakeAmount total amount of staked tokens
     
     */
    struct PoolData {
        uint256 totalStakeAmount;
        RewardInfo[] rewardInfos;
    }
    /**
     * @param stakeAmount amount of token the user stakes
     * @param pendingReward amount of reward to be redeemed by the user up to the user's last action, by rewarder index
     * @param entryAccuRewardPerShare the `accuRewardPerShare` value at the user's last stake/unstake action, by rewarder index
     */
    struct UserData {
        uint256 stakeAmount;
        uint256[] pendingReward;
        uint256[] entryAccuRewardPerShare;
        uint32 entryTime;
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

    function getRewardInfo(
        uint256 poolId,
        uint8 rewarderIdx
    ) external view returns (uint256, address, uint256, uint256) {
        RewardInfo memory rewardInfo = poolData[poolId].rewardInfos[rewarderIdx];
        return (
            rewardInfo.rewardPerBlock,
            rewardInfo.rewarder,
            rewardInfo.accuRewardPerShare,
            rewardInfo.accuRewardLastUpdateBlock
        );
    }

    function getReward(
        uint256 poolId, 
        address staker, 
        uint8 rewarderIdx
    ) external view returns (uint256) {
        UserData memory currentUserData = userData[poolId][staker];
        PoolData memory currentPoolData = poolData[poolId];
        require(rewarderIdx < poolData[poolId].rewardInfos.length, "StakingPools: Rewarder index out of bound");

        uint256 latestAccuRewardPerShare;
        uint256 entryAccuRewardPerShare = currentUserData.entryAccuRewardPerShare[rewarderIdx];
        RewardInfo memory rewardInfo = poolData[poolId].rewardInfos[rewarderIdx];
        {
            PoolInfo memory currentPoolInfo = poolInfos[poolId];
            uint256 rewardPerBlock = rewardInfo.rewardPerBlock;
            uint256 accuRewardPerShare = rewardInfo.accuRewardPerShare;
            uint256 accuRewardLastUpdateBlock = rewardInfo.accuRewardLastUpdateBlock;

            latestAccuRewardPerShare =
                currentPoolData.totalStakeAmount > 0
                    ? accuRewardPerShare.add(
                        MathUpgradeable
                            .min(block.number, currentPoolInfo.endBlock)
                            .sub(accuRewardLastUpdateBlock)
                            .mul(rewardPerBlock)
                            .mul(ACCU_REWARD_MULTIPLIER)
                            .div(currentPoolData.totalStakeAmount)
                    )
                    : accuRewardPerShare;
        }

        return
            currentUserData.pendingReward[rewarderIdx].add(
                currentUserData.stakeAmount.mul(latestAccuRewardPerShare.sub(entryAccuRewardPerShare)).div(
                    ACCU_REWARD_MULTIPLIER
                )
            );
    }

    function __StakingPools_init(uint256 _migratorSetterDelay) public initializer{
        require(_migratorSetterDelay > 0, "StakingPools: zero setter delay");
        __Ownable_init();

        migratorSetterDelay = _migratorSetterDelay;
    }

    function createPool(
        address token,
        uint256 startBlock,
        uint256 endBlock,
        uint256 migrationBlock
        ) external onlyOwner {
        require(token != address(0), "StakingPools: zero address");
        require(
            startBlock > block.number && endBlock > startBlock && migrationBlock > startBlock,
            "StakingPools: invalid block range"
        );

        uint256 newPoolId = ++lastPoolId;

        poolInfos[newPoolId] = PoolInfo({
            startBlock: startBlock,
            endBlock: endBlock,
            migrationBlock: migrationBlock,
            poolToken: token
        });

        PoolData storage newPoolData;
        newPoolData.totalStakeAmount = 0;
        poolData[newPoolId] = newPoolData;

        emit PoolCreated(newPoolId, token, startBlock, endBlock, migrationBlock);
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

    function addRewardInfo(uint256 poolId, uint256 rewardRate, address rewarder) external onlyOwner onlyPoolExists(poolId) onlyPoolNotEnded(poolId){
        require(rewarder != address(0), "StakingPools: zero address");

        RewardInfo memory rewardInfo = RewardInfo({
            rewardPerBlock: rewardRate,
            rewarder: rewarder,
            accuRewardPerShare: 0,
            accuRewardLastUpdateBlock: poolInfos[poolId].startBlock
        });
        poolData[poolId].rewardInfos.push(rewardInfo);

        emit RewardInfoAdded(poolId, rewarder, rewardRate, uint8(poolData[poolId].rewardInfos.length - 1));
    }

    function changeRewardInfo(uint256 poolId, uint256 rewardRate, uint8 rewardInfoIndex) external onlyOwner onlyPoolExists(poolId) onlyPoolNotEnded(poolId){
        require(rewardInfoIndex < poolData[poolId].rewardInfos.length, "StakingPools: out of index");

        if ( block.number >= poolInfos[poolId].startBlock) {
            // "Settle" rewards up to this block 
            _updatePoolAccuRewardForRewarder(poolId, rewardInfoIndex);
        }

        uint256 oldRewardRate = poolData[poolId].rewardInfos[rewardInfoIndex].rewardPerBlock;
        poolData[poolId].rewardInfos[rewardInfoIndex].rewardPerBlock = rewardRate;

        emit RewardInfoChanged(poolId, poolData[poolId].rewardInfos[rewardInfoIndex].rewarder, oldRewardRate, rewardRate);
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
        for (uint8 i = 0; i < userData[poolId][msg.sender].pendingReward.length; i++){
            userData[poolId][msg.sender].pendingReward[i] = 0;
        }
    }

    function redeemRewards(uint256 poolId) external {
        _redeemRewardsByAddress(poolId, msg.sender);
    }

    function redeemRewardsByAddress(uint256 poolId, address user) external {
        _redeemRewardsByAddress(poolId, user);
    }

    function _redeemRewardsByAddress(uint256 poolId, address user) private onlyPoolExists(poolId) {
        require(user != address(0), "StakingPools: zero address");

        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, user);

        _vestPendingRewards(poolId, user);

        uint256 totalClaimed;
        RewardInfo[] memory rewarderInfos = poolData[poolId].rewardInfos;
        for (uint8 i = 0; i < rewarderInfos.length; i++) {
            address rewarder = rewarderInfos[i].rewarder;
            uint256 claimed = IStakingPoolRewarder(rewarder).claimVestedReward(poolId, user);
            if (claimed > 0) {
                totalClaimed = totalClaimed.add(claimed);
                emit RewardRedeemed(poolId, user, rewarder, claimed);
            }
        }
        require(totalClaimed > 0, "StakingPools: claimable amount is 0");
    }

    function _vestPendingRewards(uint256 poolId, address user) private onlyPoolExists(poolId) {
        uint32 entryTime = userData[poolId][user].entryTime;
        RewardInfo[] memory rewarderInfos = poolData[poolId].rewardInfos;

        for (uint8 i = 0; i < rewarderInfos.length; i++){
            address rewarder = rewarderInfos[i].rewarder;
            uint256 rewardToVest = userData[poolId][user].pendingReward[i];
            userData[poolId][user].pendingReward[i] = 0;
            IStakingPoolRewarder(rewarder).onReward(poolId, user, rewardToVest, entryTime);
        }
    }

    function _stake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(poolData[poolId].rewardInfos[0].rewarder != address(0), "StakingPools: reward info not set");
        require(amount > 0, "StakingPools: cannot stake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.add(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.add(amount);

        safeTransferFrom(poolInfos[poolId].poolToken, user, address(this), amount);

        // settle pending rewards to rewarder with vesting so that entryTime can be updated
        _vestPendingRewards(poolId, user);
        userData[poolId][user].entryTime = (uint32(block.timestamp));

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

    function _updatePoolAccuRewardForRewarder(uint256 poolId, uint8 rewarderIdx) private {
        PoolInfo storage currentPoolInfo = poolInfos[poolId];
        PoolData storage currentPoolData = poolData[poolId];

        uint256 appliedUpdateBlock = MathUpgradeable.min(block.number, currentPoolInfo.endBlock);

        RewardInfo memory rewardInfo = poolData[poolId].rewardInfos[rewarderIdx];
        // This saves tx cost when being called multiple times in the same block
        uint256 durationInBlocks = appliedUpdateBlock.sub(rewardInfo.accuRewardLastUpdateBlock);
        if (durationInBlocks > 0) {
            // No need to update the rate if no one staked at all
            if (currentPoolData.totalStakeAmount > 0) {
                poolData[poolId].rewardInfos[rewarderIdx].accuRewardPerShare = rewardInfo.accuRewardPerShare.add(
                    durationInBlocks.mul(rewardInfo.rewardPerBlock).mul(ACCU_REWARD_MULTIPLIER).div(
                        currentPoolData.totalStakeAmount
                    )
                );
            }
            poolData[poolId].rewardInfos[rewarderIdx].accuRewardLastUpdateBlock = appliedUpdateBlock;
        }
    }

    function _updatePoolAccuReward(uint256 poolId) private {
        for (uint8 i = 0; i < poolData[poolId].rewardInfos.length; i++){
            _updatePoolAccuRewardForRewarder(poolId, i);
        }   
    }

    function _updateStakerReward(uint256 poolId, address staker) private {
        UserData storage currentUserData = userData[poolId][staker];

        uint256 stakeAmount = currentUserData.stakeAmount;

        for (uint8 i = 0; i < poolData[poolId].rewardInfos.length; i++){
            if (poolData[poolId].rewardInfos.length > currentUserData.entryAccuRewardPerShare.length){
                currentUserData.entryAccuRewardPerShare.push(poolData[poolId].rewardInfos[i].accuRewardPerShare);
                currentUserData.pendingReward.push(0);
            } else {
                uint256 stakerEntryRate = currentUserData.entryAccuRewardPerShare[i];
                uint256 accuDifference = poolData[poolId].rewardInfos[i].accuRewardPerShare.sub(stakerEntryRate);
                if (accuDifference > 0) {
                    currentUserData.pendingReward[i] = currentUserData.pendingReward[i].add(
                        stakeAmount.mul(accuDifference).div(ACCU_REWARD_MULTIPLIER)
                    );
                    currentUserData.entryAccuRewardPerShare[i] = poolData[poolId].rewardInfos[i].accuRewardPerShare;
                }
            }
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
library SafeMathUpgradeable {
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
        uint256 amount,
        uint32 entryTime
    ) external;

    function claimVestedReward(
        uint256 poolId,
        address user
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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