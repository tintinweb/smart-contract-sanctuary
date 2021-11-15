// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./interfaces/IStakingPoolRewarder.sol";
import "../interfaces/IMinersNFTs.sol";


/**
 * @title StakingPools
 *
 * @dev A contract for staking NFT tokens earn rewards.
 *
 */
contract StakingPools is Ownable, ERC1155Receiver{
    using SafeMath for uint256;

    event PoolCreated(
        uint256 indexed poolId,
        uint256 indexed nftTypeId,
        uint256 startBlock,
        uint256 endBlock,
        uint256 rewardPerBlock
    );
    event PoolEndBlockExtended(uint256 indexed poolId, uint256 oldEndBlock, uint256 newEndBlock);
    event PoolRewardRateChanged(uint256 indexed poolId, uint256 oldRewardPerBlock, uint256 newRewardPerBlock);
    event RewarderChanged(address oldRewarder, address newRewarder);
    event Staked(uint256 indexed poolId, address indexed staker, uint256 nftTypeId, uint256 amount);
    event Unstaked(uint256 indexed poolId, address indexed staker, uint256 nftTypeId, uint256 amount);
    event RewardRedeemed(uint256 indexed poolId, address indexed staker, address rewarder, uint256 amount);

    /**
     * @param startBlock the block from which reward accumulation starts
     * @param endBlock the block from which reward accumulation stops
     * @param rewardPerBlock total amount of token to be rewarded in a block
     * @param poolToken token to be staked
     */
    struct PoolInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardPerBlock;
        uint256 nftTypeId;
        bool    unstakeBeforeEndBlock;
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


    uint256 public lastPoolId; // The first pool has ID of 1

    IStakingPoolRewarder public rewarder;
    IMinersNFTs public minersNFTs;

    mapping(uint256 => PoolInfo) public poolInfos;
    mapping(uint256 => PoolData) public poolData;
    mapping(uint256 => mapping(address => UserData)) public userData;

    uint256 private constant ACCU_REWARD_MULTIPLIER = 10**20; // Precision loss prevention


    // `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    bytes4 private constant ONERC1155RECEIVED_SELECTOR = 0xf23a6e61;
    // `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    bytes4 private constant ONERC1155BATCHRECEIVED_SELECTOR = 0xbc197c81;

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
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
        )
        external
        override
        returns(bytes4)
        {
            return ONERC1155RECEIVED_SELECTOR;
        }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
        )
        external
        override
        returns(bytes4)
        {
            return ONERC1155BATCHRECEIVED_SELECTOR;
        }

    constructor(address _minersNFTs){
        require(_minersNFTs != address(0), "StakingPools: zero address");

        minersNFTs = IMinersNFTs(_minersNFTs);
    }

    function createPool(
        uint256 nftTypeId,
        uint256 startBlock,
        uint256 endBlock,
        uint256 rewardPerBlock,
        bool    unstakeBeforeEndBlock
    ) external onlyOwner {
        require(nftTypeId >0, "StakingPools: zero tpye id");
        require(
            startBlock > block.number && endBlock > startBlock,
            "StakingPools: invalid block range"
        );
        require(rewardPerBlock > 0, "StakingPools: reward must be positive");

        uint256 newPoolId = ++lastPoolId;

        poolInfos[newPoolId] = PoolInfo({
            startBlock: startBlock,
            endBlock: endBlock,
            rewardPerBlock: rewardPerBlock,
            nftTypeId: nftTypeId,
            unstakeBeforeEndBlock: unstakeBeforeEndBlock
        });
        poolData[newPoolId] = PoolData({totalStakeAmount: 0, accuRewardPerShare: 0, accuRewardLastUpdateBlock: startBlock});

        emit PoolCreated(newPoolId, nftTypeId, startBlock, endBlock, rewardPerBlock);
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


    function setPoolReward(uint256 poolId, uint256 newRewardPerBlock)
        external
        onlyOwner
        onlyPoolExists(poolId)
        onlyPoolNotEnded(poolId)
    {
        // "Settle" rewards up to this block
        _updatePoolAccuReward(poolId);

        // We're deliberately allowing setting the reward rate to 0 here. If it turns
        // out this, or even changing rates at all, is undesirable after deployment, the
        // ownership of this contract can be transferred to a contract incapable of making
        // calls to this function.
        uint256 currentRewardPerBlock = poolInfos[poolId].rewardPerBlock;
        poolInfos[poolId].rewardPerBlock = newRewardPerBlock;

        emit PoolRewardRateChanged(poolId, currentRewardPerBlock, newRewardPerBlock);
    }

    function setRewarder(address newRewarder) external onlyOwner {
        require(newRewarder != address(0), "StakingPools: zero address");

        address oldRewarder = address(rewarder);
        rewarder = IStakingPoolRewarder(newRewarder);

        emit RewarderChanged(oldRewarder, newRewarder);
    }
    // need setApprovalForAll
    function stake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) onlyPoolActive(poolId) {
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        _stake(poolId, msg.sender, amount);
    }

    function unstake(uint256 poolId, uint256 amount) external onlyPoolExists(poolId) {
        if(!poolInfos[poolId].unstakeBeforeEndBlock){
            require(block.number >= poolInfos[poolId].endBlock, "StakingPools: not allow unstake before endblock");
        }
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
        _updatePoolAccuReward(poolId);
        _updateStakerReward(poolId, msg.sender);

        require(address(rewarder) != address(0), "StakingPools: rewarder not set");

        uint256 rewardToRedeem = userData[poolId][msg.sender].pendingReward;
        require(rewardToRedeem > 0, "StakingPools: no reward to redeem");

        userData[poolId][msg.sender].pendingReward = 0;

        rewarder.onReward(poolId, msg.sender, rewardToRedeem);

        emit RewardRedeemed(poolId, msg.sender, address(rewarder), rewardToRedeem);
    }

    function _stake(
        uint256 poolId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "StakingPools: cannot stake zero amount");

        userData[poolId][user].stakeAmount = userData[poolId][user].stakeAmount.add(amount);
        poolData[poolId].totalStakeAmount = poolData[poolId].totalStakeAmount.add(amount);

        minersNFTs.safeTransferFrom(user, address(this), poolInfos[poolId].nftTypeId, amount, '');
        emit Staked(poolId, user, poolInfos[poolId].nftTypeId, amount);
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

        minersNFTs.safeTransferFrom(address(this), user, poolInfos[poolId].nftTypeId, amount, '');

        emit Unstaked(poolId, user, poolInfos[poolId].nftTypeId, amount);
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
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
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMinersNFTs is IERC1155 {
    function lastTypeId() external view returns (uint256);
    function mintNFT(address _owner, uint256 _typeId, uint256 _amount) external; 
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

