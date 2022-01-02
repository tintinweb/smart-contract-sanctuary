// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./interfaces/IMerkleVesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MerkleVesting is IMerkleVesting, Multicall, Ownable {
    address public immutable token;
    bytes32 public lastEndingCohort;

    mapping(bytes32 => Cohort) internal cohorts;

    constructor(address token_) {
        token = token_;
    }

    function getCohort(bytes32 cohortId) external view returns (CohortData memory) {
        return cohorts[cohortId].data;
    }

    function getClaimableAmount(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 fullAmount
    ) public view returns (uint256) {
        Cohort storage cohort = cohorts[cohortId];
        uint256 claimedSoFar = cohort.claims[account];
        uint256 vestingEnd = cohort.data.vestingEnd;
        uint256 vestingStart = vestingEnd - cohort.data.vestingPeriod;
        uint256 cliff = vestingStart + cohort.data.cliffPeriod;
        if (isDisabled(cohortId, index)) revert NotInVesting(cohortId, account);
        if (block.timestamp < cliff) revert CliffNotReached(cliff, block.timestamp);
        else if (block.timestamp < vestingEnd)
            return (fullAmount * (block.timestamp - vestingStart)) / cohort.data.vestingPeriod - claimedSoFar;
        else return fullAmount - claimedSoFar;
    }

    function getClaimed(bytes32 cohortId, address account) public view returns (uint256) {
        return cohorts[cohortId].claims[account];
    }

    function isDisabled(bytes32 cohortId, uint256 index) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word = cohorts[cohortId].disabledState[wordIndex];
        uint256 mask = (1 << bitIndex);
        return word & mask == mask;
    }

    function setDisabled(bytes32 cohortId, uint256 index) external onlyOwner {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        cohorts[cohortId].disabledState[wordIndex] = cohorts[cohortId].disabledState[wordIndex] | (1 << bitIndex);
    }

    function addCohort(
        bytes32 merkleRoot,
        uint256 distributionDuration,
        uint64 vestingPeriod,
        uint64 cliffPeriod
    ) external onlyOwner {
        if (
            merkleRoot == bytes32(0) ||
            distributionDuration == 0 ||
            vestingPeriod == 0 ||
            distributionDuration < vestingPeriod ||
            distributionDuration < cliffPeriod ||
            vestingPeriod < cliffPeriod
        ) revert InvalidParameters();
        if (cohorts[merkleRoot].data.merkleRoot != bytes32(0)) revert MerkleRootCollision();

        uint256 distributionEnd = block.timestamp + distributionDuration;
        if (distributionEnd > cohorts[lastEndingCohort].data.distributionEnd) lastEndingCohort = merkleRoot;

        cohorts[merkleRoot].data.merkleRoot = merkleRoot;
        cohorts[merkleRoot].data.distributionEnd = uint64(distributionEnd);
        cohorts[merkleRoot].data.vestingEnd = uint64(block.timestamp + vestingPeriod);
        cohorts[merkleRoot].data.vestingPeriod = vestingPeriod;
        cohorts[merkleRoot].data.cliffPeriod = cliffPeriod;

        emit CohortAdded(merkleRoot);
    }

    function claim(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (cohorts[cohortId].data.merkleRoot == bytes32(0)) revert CohortDoesNotExist();
        Cohort storage cohort = cohorts[cohortId];
        uint256 distributionEndLocal = cohort.data.distributionEnd;
        if (block.timestamp > distributionEndLocal) revert DistributionEnded(block.timestamp, distributionEndLocal);

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, cohort.data.merkleRoot, node)) revert InvalidProof();

        // Calculate the claimable amount and update the claimed amount on storage.
        uint256 claimableAmount = getClaimableAmount(cohortId, index, account, amount);
        cohort.claims[account] += claimableAmount;

        // Send the token.
        if (!IERC20(token).transfer(account, claimableAmount)) revert TransferFailed(token, address(this), account);

        emit Claimed(cohortId, account, claimableAmount);
    }

    function withdraw(address recipient) external onlyOwner {
        uint256 distributionEndLocal = cohorts[lastEndingCohort].data.distributionEnd;
        if (block.timestamp <= distributionEndLocal) revert DistributionOngoing(block.timestamp, distributionEndLocal);
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert AlreadyWithdrawn();
        if (!IERC20(token).transfer(recipient, balance)) revert TransferFailed(token, address(this), recipient);
        emit Withdrawn(recipient, balance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title Allows anyone to claim a token if they exist in a merkle root, but only over time.
interface IMerkleVesting {
    /// @notice The struct holding a specific cohort's data and the individual claim statuses.
    /// @param data The struct holding a specific cohort's data.
    /// @param claims Stores the amount of claimed funds per address.
    /// @param disabledState A packed array of booleans. If true, the individual user cannot claim anymore.
    struct Cohort {
        CohortData data;
        mapping(address => uint256) claims;
        mapping(uint256 => uint256) disabledState;
    }

    /// @notice The struct holding a specific cohort's data.
    /// @param merkleRoot The merkle root of the merkle tree containing account balances available to claim.
    /// @param distributionEnd The unix timestamp that marks the end of the token distribution.
    /// @param vestingEnd The unix timestamp that marks the end of the vesting period.
    /// @param vestingPeriod The length of the vesting period in seconds.
    /// @param cliffPeriod The length of the cliff period in seconds.
    struct CohortData {
        bytes32 merkleRoot;
        uint64 distributionEnd;
        uint64 vestingEnd;
        uint64 vestingPeriod;
        uint64 cliffPeriod;
    }

    /// @notice Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    /// @notice Returns the id/Merkle root of the cohort ending at the latest.
    function lastEndingCohort() external view returns (bytes32);

    /// @notice Returns the parameters of a specific cohort.
    /// @param cohortId The Merkle root of the cohort.
    function getCohort(bytes32 cohortId) external view returns (CohortData memory);

    /// @notice Returns the amount of funds an account can claim at the moment.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    /// @param account The address of the account to query.
    /// @param fullAmount The full amount of funds the account can claim.
    function getClaimableAmount(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 fullAmount
    ) external view returns (uint256);

    /// @notice Returns the amount of funds an account has claimed.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address of the account to query.
    function getClaimed(bytes32 cohortId, address account) external view returns (uint256);

    /// @notice Check if the address in a cohort at the index is excluded from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    function isDisabled(bytes32 cohortId, uint256 index) external view returns (bool);

    /// @notice Exclude the address in a cohort at the index from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    function setDisabled(bytes32 cohortId, uint256 index) external;

    /// @notice Allows the owner to add a new cohort.
    /// @param merkleRoot The Merkle root of the cohort. It will also serve as the cohort's ID.
    /// @param distributionDuration The length of the token distribtion period in seconds.
    /// @param vestingPeriod The length of the vesting period of the tokens in seconds.
    /// @param cliffPeriod The length of the cliff period in seconds.
    function addCohort(
        bytes32 merkleRoot,
        uint256 distributionDuration,
        uint64 vestingPeriod,
        uint64 cliffPeriod
    ) external;

    /// @notice Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list (so the full amount).
    /// @param merkleProof A an array of values from the generated input list.
    function claim(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Allows the owner to reclaim the tokens after the distribution has ended.
    /// @param recipient The address receiving the tokens.
    function withdraw(address recipient) external;

    /// @notice This event is triggered whenever a call to #addCohort succeeds.
    /// @param cohortId The Merkle root of the cohort.
    event CohortAdded(bytes32 cohortId);

    /// @notice This event is triggered whenever a call to #claim succeeds.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address that claimed the tokens.
    /// @param amount The amount of tokens the address received.
    event Claimed(bytes32 cohortId, address account, uint256 amount);

    /// @notice This event is triggered whenever a call to #withdraw succeeds.
    /// @param account The address that received the tokens.
    /// @param amount The amount of tokens the address received.
    event Withdrawn(address account, uint256 amount);

    /// @notice Error thrown when there's nothing to withdraw.
    error AlreadyWithdrawn();

    /// @notice Error thrown when a cohort with the provided id does not exist.
    error CohortDoesNotExist();

    /// @notice Error thrown when the distribution period ended.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ended.
    error DistributionEnded(uint256 current, uint256 end);

    /// @notice Error thrown when the cliff period is not over yet.
    /// @param cliff The time when the cliff period ends.
    /// @param timestamp The current timestamp.
    error CliffNotReached(uint256 cliff, uint256 timestamp);

    /// @notice Error thrown when the distribution period did not end yet.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ends.
    error DistributionOngoing(uint256 current, uint256 end);

    /// @notice Error thrown when the Merkle proof is invalid.
    error InvalidProof();

    /// @notice Error thrown when a transfer failed.
    /// @param token The address of token attempted to be transferred.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address token, address from, address to);

    /// @notice Error thrown when a function receives invalid parameters.
    error InvalidParameters();

    /// @notice Error thrown when a cohort with an already existing merkle tree is attempted to be added.
    error MerkleRootCollision();

    /// @notice Error thrown when the input address has been excluded from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address that does not satisfy the requirements.
    error NotInVesting(bytes32 cohortId, address account);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
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
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}