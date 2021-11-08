// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.6;
pragma abicoder v2;

import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MerkleProofUpgradeable as MerkleProof} from "@openzeppelin/contracts-upgradeable/cryptography/MerkleProofUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * Inspired by:
 * - https://github.com/pie-dao/vested-token-migration-app
 * - https://github.com/Uniswap/merkle-distributor
 * - https://github.com/balancer-labs/erc20-redeemable
 *
 * @title  MerkleDistributor contract.
 * @notice Allows an owner to distribute any reward ERC20 to claimants according to Merkle roots. The owner can specify
 *         multiple Merkle roots distributions with customized reward currencies.
 * @dev    The Merkle trees are not validated in any way, so the system assumes the contract owner behaves honestly.
 */
contract MerkleDistributor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // A Window maps a Merkle root to a reward token address.
    struct Window {
        // Merkle root describing the distribution.
        bytes32 merkleRoot;
        // Currency in which reward is processed.
        IERC20 rewardToken;
        // IPFS hash of the merkle tree. Can be used to independently fetch recipient proofs and tree. Note that the canonical
        // data type for storing an IPFS hash is a multihash which is the concatenation of  <varint hash function code>
        // <varint digest size in bytes><hash function output>. We opted to store this in a string type to make it easier
        // for users to query the ipfs data without needing to reconstruct the multihash. to view the IPFS data simply
        // go to https://cloudflare-ipfs.com/ipfs/<IPFS-HASH>.
        string ipfsHash;
    }

    // Represents an account's claim for `amount` within the Merkle root located at the `windowIndex`.
    struct Claim {
        uint256 windowIndex;
        uint256 amount;
        uint256 accountIndex; // Used only for bitmap. Assumed to be unique for each claim.
        address account;
        bytes32[] merkleProof;
    }

    // Windows are mapped to arbitrary indices.
    mapping(uint256 => Window) public merkleWindows;

    // Index of next created Merkle root.
    uint256 public nextCreatedIndex;

    // Track which accounts have claimed for each window index.
    // Note: uses a packed array of bools for gas optimization on tracking certain claims. Copied from Uniswap's contract.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    // Block until when the distributor is locked
    uint256 public lockBlock;

    /****************************************
     *                EVENTS
     ****************************************/
    event Claimed(
        address indexed caller,
        uint256 windowIndex,
        address indexed account,
        uint256 accountIndex,
        uint256 amount,
        address indexed rewardToken
    );
    event CreatedWindow(
        uint256 indexed windowIndex,
        uint256 rewardsDeposited,
        address indexed rewardToken,
        address owner
    );
    event WithdrawRewards(address indexed owner, uint256 amount, address indexed currency);
    event DeleteWindow(uint256 indexed windowIndex, address owner);
    event LockSet(uint256 indexed lockBlock);

    /****************************
     *      MODIFIERS
     ****************************/

    modifier notLocked() {
        require(lockBlock == 0 || lockBlock < block.number, "Distributor is Locked");

        _;
    }

    /****************************
     *      ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Initializer for the contract. This contract should be behind a PieProxy.
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Set merkle root for the next available window index and seed allocations.
     * @notice Callable only by owner of this contract. Caller must have approved this contract to transfer
     *      `rewardsToDeposit` amount of `rewardToken` or this call will fail. Importantly, we assume that the
     *      owner of this contract correctly chooses an amount `rewardsToDeposit` that is sufficient to cover all
     *      claims within the `merkleRoot`. Otherwise, a race condition can be created. This situation can occur
     *      because we do not segregate reward balances by window, for code simplicity purposes.
     *      (If `rewardsToDeposit` is purposefully insufficient to payout all claims, then the admin must
     *      subsequently transfer in rewards or the following situation can occur).
     *      Example race situation:
     *          - Window 1 Tree: Owner sets `rewardsToDeposit=100` and insert proofs that give claimant A 50 tokens and
     *            claimant B 51 tokens. The owner has made an error by not setting the `rewardsToDeposit` correctly to 101.
     *          - Window 2 Tree: Owner sets `rewardsToDeposit=1` and insert proofs that give claimant A 1 token. The owner
     *            correctly set `rewardsToDeposit` this time.
     *          - At this point contract owns 100 + 1 = 101 tokens. Now, imagine the following sequence:
     *              (1) Claimant A claims 50 tokens for Window 1, contract now has 101 - 50 = 51 tokens.
     *              (2) Claimant B claims 51 tokens for Window 1, contract now has 51 - 51 = 0 tokens.
     *              (3) Claimant A tries to claim 1 token for Window 2 but fails because contract has 0 tokens.
     *          - In summary, the contract owner created a race for step(2) and step(3) in which the first claim would
     *            succeed and the second claim would fail, even though both claimants would expect their claims to succeed.
     * @param rewardsToDeposit amount of rewards to deposit to seed this allocation.
     * @param rewardToken ERC20 reward token.
     * @param merkleRoot merkle root describing allocation.
     * @param ipfsHash hash of IPFS object, conveniently stored for clients
     */
    function setWindow(
        uint256 rewardsToDeposit,
        address rewardToken,
        bytes32 merkleRoot,
        string memory ipfsHash
    ) external onlyOwner {
        uint256 indexToSet = nextCreatedIndex;
        nextCreatedIndex = indexToSet.add(1);

        _setWindow(indexToSet, rewardsToDeposit, rewardToken, merkleRoot, ipfsHash);
    }

    /**
     * @notice Set block to lock the contract
     * @dev Callable only by owner.
     * @param _lock block number until when the contract should be locked
     */
    function setLock(uint256 _lock) external onlyOwner {
        lockBlock = _lock;
        emit LockSet(_lock);
    }

    /**
     * @notice Delete merkle root at window index.
     * @dev Callable only by owner. Likely to be followed by a withdrawRewards call to clear contract state.
     * @param windowIndex merkle root index to delete.
     */
    function deleteWindow(uint256 windowIndex) external onlyOwner {
        delete merkleWindows[windowIndex];
        emit DeleteWindow(windowIndex, msg.sender);
    }

    /**
     * @notice Emergency method that transfers rewards out of the contract if the contract was configured improperly.
     * @dev Callable only by owner.
     * @param rewardCurrency rewards to withdraw from contract.
     * @param amount amount of rewards to withdraw.
     */
    function withdrawRewards(address rewardCurrency, uint256 amount) external onlyOwner {
        IERC20(rewardCurrency).safeTransfer(msg.sender, amount);
        emit WithdrawRewards(msg.sender, amount, rewardCurrency);
    }

    /****************************
     *    NON-ADMIN FUNCTIONS
     ****************************/

    /**
     * @notice Batch claims to reduce gas versus individual submitting all claims. Method will fail
     *         if any individual claims within the batch would fail.
     * @dev    Optimistically tries to batch together consecutive claims for the same account and same
     *         reward token to reduce gas. Therefore, the most gas-cost-optimal way to use this method
     *         is to pass in an array of claims sorted by account and reward currency.
     * @param claims array of claims to claim.
     */
    function claimMulti(Claim[] memory claims) external notLocked {
        uint256 batchedAmount = 0;
        uint256 claimCount = claims.length;
        for (uint256 i = 0; i < claimCount; i++) {
            Claim memory _claim = claims[i];
            _verifyAndMarkClaimed(_claim);
            batchedAmount = batchedAmount.add(_claim.amount);

            // If the next claim is NOT the same account or the same token (or this claim is the last one),
            // then disburse the `batchedAmount` to the current claim's account for the current claim's reward token.
            uint256 nextI = i + 1;
            address currentRewardToken = address(merkleWindows[_claim.windowIndex].rewardToken);
            if (
                nextI == claimCount ||
                // This claim is last claim.
                claims[nextI].account != _claim.account ||
                // Next claim account is different than current one.
                address(merkleWindows[claims[nextI].windowIndex].rewardToken) != currentRewardToken
                // Next claim reward token is different than current one.
            ) {
                IERC20(currentRewardToken).safeTransfer(_claim.account, batchedAmount);
                batchedAmount = 0;
            }
        }
    }

    /**
     * @notice Claim amount of reward tokens for account, as described by Claim input object.
     * @dev    If the `_claim`'s `amount`, `accountIndex`, and `account` do not exactly match the
     *         values stored in the merkle root for the `_claim`'s `windowIndex` this method
     *         will revert.
     * @param _claim claim object describing amount, accountIndex, account, window index, and merkle proof.
     */
    function claim(Claim memory _claim) public notLocked {
        _verifyAndMarkClaimed(_claim);
        merkleWindows[_claim.windowIndex].rewardToken.safeTransfer(_claim.account, _claim.amount);
    }

    /**
     * @notice Returns True if the claim for `accountIndex` has already been completed for the Merkle root at
     *         `windowIndex`.
     * @dev    This method will only work as intended if all `accountIndex`'s are unique for a given `windowIndex`.
     *         The onus is on the Owner of this contract to submit only valid Merkle roots.
     * @param windowIndex merkle root to check.
     * @param accountIndex account index to check within window index.
     * @return True if claim has been executed already, False otherwise.
     */
    function isClaimed(uint256 windowIndex, uint256 accountIndex) public view returns (bool) {
        uint256 claimedWordIndex = accountIndex / 256;
        uint256 claimedBitIndex = accountIndex % 256;
        uint256 claimedWord = claimedBitMap[windowIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @notice Returns True if leaf described by {account, amount, accountIndex} is stored in Merkle root at given
     *         window index.
     * @param _claim claim object describing amount, accountIndex, account, window index, and merkle proof.
     * @return valid True if leaf exists.
     */
    function verifyClaim(Claim memory _claim) public view returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(_claim.account, _claim.amount, _claim.accountIndex));
        return MerkleProof.verify(_claim.merkleProof, merkleWindows[_claim.windowIndex].merkleRoot, leaf);
    }

    /****************************
     *     PRIVATE FUNCTIONS
     ****************************/

    // Mark claim as completed for `accountIndex` for Merkle root at `windowIndex`.
    function _setClaimed(uint256 windowIndex, uint256 accountIndex) private {
        uint256 claimedWordIndex = accountIndex / 256;
        uint256 claimedBitIndex = accountIndex % 256;
        claimedBitMap[windowIndex][claimedWordIndex] =
            claimedBitMap[windowIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    // Store new Merkle root at `windowindex`. Pull `rewardsDeposited` from caller to seed distribution for this root.
    function _setWindow(
        uint256 windowIndex,
        uint256 rewardsDeposited,
        address rewardToken,
        bytes32 merkleRoot,
        string memory ipfsHash
    ) private {
        Window storage window = merkleWindows[windowIndex];
        window.merkleRoot = merkleRoot;
        window.rewardToken = IERC20(rewardToken);
        window.ipfsHash = ipfsHash;

        emit CreatedWindow(windowIndex, rewardsDeposited, rewardToken, msg.sender);

        window.rewardToken.safeTransferFrom(msg.sender, address(this), rewardsDeposited);
    }

    // Verify claim is valid and mark it as completed in this contract.
    function _verifyAndMarkClaimed(Claim memory _claim) private {
        // Check claimed proof against merkle window at given index.
        require(verifyClaim(_claim), "Incorrect merkle proof");
        // Check the account has not yet claimed for this window.
        require(!isClaimed(_claim.windowIndex, _claim.accountIndex), "Account has already claimed for this window");

        // Proof is correct and claim has not occurred yet, mark claimed complete.
        _setClaimed(_claim.windowIndex, _claim.accountIndex);
        emit Claimed(
            msg.sender,
            _claim.windowIndex,
            _claim.account,
            _claim.accountIndex,
            _claim.amount,
            address(merkleWindows[_claim.windowIndex].rewardToken)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.7.0;

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