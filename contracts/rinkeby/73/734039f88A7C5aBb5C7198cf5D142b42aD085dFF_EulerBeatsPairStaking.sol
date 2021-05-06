// SPDX-License-Identifier: MIT

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
    constructor () {
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./staking/mixins/BalanceTrackingMixin.sol";
import "./staking/mixins/RewardTrackingMixin.sol";
import "./staking/mixins/RestrictedPairsMixin.sol";
import "./staking/ERC1155Staker.sol";

/**
 * @dev Staking contract for ERC1155 tokens which tracks rewards in ether.  All ether sent to this contract will be distributed
 * evenly across all stakers.
 * This contract only accepts whitelisted pairs of tokens to be staked.
 */
contract EulerBeatsPairStaking is
    ERC1155Staker,
    BalanceTrackingMixin,
    RewardTrackingMixin,
    RestrictedPairsMixin,
    ReentrancyGuard,
    Ownable
{
    bool public emergency;
    uint256 public maxPairs;

    event RewardAdded(uint256 amount);
    event RewardClaimed(address indexed account, uint256 amount);

    // on stake/unstake
    event PairStaked(uint256 indexed pairId, address indexed account, uint256 amount);
    event PairUnstaked(uint256 indexed pairId, address indexed account, uint256 amount);

    event EmergencyUnstake(uint256 pairId, address indexed account, uint256 amount);

    /**
     * @dev The token contracts to allow the pairs from.  These address can only be set in the constructor, so make
     * sure you have it right!
     */
    constructor(address tokenAddressA, address tokenAddressB) RestrictedPairsMixin(tokenAddressA, tokenAddressB) {}

    /**
     * @dev Claim the reward for the caller.
     */
    function claimReward() external nonReentrant {
        claimRewardInternal();
    }

    /**
     * @dev Stake amount of tokens for the given pair.  Prior to staking, this will send and pending reward to the caller.
     */
    function stake(uint256 pairId, uint256 amount) external onlyEnabledPair(pairId) nonReentrant {
        require(totalShares + amount <= maxPairs, "Max Pairs Exceeded");
        require(!emergency, "Not allowed");

        // claim any pending reward
        claimRewardInternal();

        // transfer tokens from account to staking contract
        depositPair(pairId, amount);

        // update reward balance
        _addShares(msg.sender, amount);
    }

    /**
     * @dev Unstake one or more tokens.  Prior to unstaking, this will send all pending rewards to the caller.
     */
    function unstake(uint256 pairId, uint256 amount) external nonReentrant {
        // claim any pending reward
        claimRewardInternal();

        // transfer tokens from staking contract to account
        withdrawPair(pairId, amount);

        // update reward balance
        _removeShares(msg.sender, amount);
    }

    /**
     * @dev Unstake the given pair and forfeit any current pending reward.  This is only for emergency use
     * and will mess up this account's ability to unstake any other pairs.
     * If used, the caller should unstake ALL pairs (each pair id one-by-one) using this function.
     */
    function emergencyUnstake(uint256 pairId, uint256 amount) external nonReentrant {
        require(emergency, "Not allowed");
        require(amount > 0, "Invalid amount");

        // reset this account back to 0 rewards
        _resetRewardAccount(msg.sender);

        // trasfers the tokens back to the account
        withdrawPair(pairId, amount);

        emit EmergencyUnstake(pairId, msg.sender, amount);
    }

    /**
     * @dev Add rewards that are immediately split up between stakers
     */
    function addReward() external payable {
        require(msg.value > 0, "No ETH sent");
        require(totalShares > 0, "No stakers");
        _addReward(msg.value);
        emit RewardAdded(msg.value);
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Hooks     //
    ///////////////

    function _beforeDeposit(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override {
        // update deposit balance for the given account
        _depositIntoAccount(account, contractAddress, tokenId, amount);
    }

    function _beforeWithdraw(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override {
        // update deposit balance for the given account.  this will revert if someone
        // is trying to withdraw more than they have deposited.
        _withdrawFromAccount(account, contractAddress, tokenId, amount);
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Getters   //
    ///////////////

    /**
     * @dev Return the current number of staked pairs.
     */
    function numStakedPairs() external view returns (uint256) {
        return totalShares;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Internal  //
    ///////////////

    /**
     * @dev Send any pending reward to msg.sender and update their debt so they
     * no longer have any pending reward.
     */
    function claimRewardInternal() internal {
        uint256 currentReward = accountPendingReward(msg.sender);
        if (currentReward > 0) {
            _updateRewardDebtToCurrent(msg.sender);

            uint256 amount;
            if (currentReward > address(this).balance) {
                // rounding errors
                amount = address(this).balance;
            } else {
                amount = currentReward;
            }
            Address.sendValue(payable(msg.sender), amount);
            emit RewardClaimed(msg.sender, amount);
        }
    }

    function depositPair(uint256 pairId, uint256 amount) internal {
        PairInfo memory pair = pairs[pairId];
        _depositSingle(tokenA, pair.tokenIdA, amount);
        _depositSingle(tokenB, pair.tokenIdB, amount);
        emit PairStaked(pairId, msg.sender, amount);
    }

    function withdrawPair(uint256 pairId, uint256 amount) internal {
        PairInfo memory pair = pairs[pairId];
        _withdrawSingle(tokenA, pair.tokenIdA, amount);
        _withdrawSingle(tokenB, pair.tokenIdB, amount);
        emit PairUnstaked(pairId, msg.sender, amount);
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////////
    // Admin     //
    ///////////////

    /**
     * @dev Add new pairs that can be staked.  Pairs can never be removed after this call, only disabled.
     */
    function addPairs(
        uint256[] memory tokenIdA,
        uint256[] memory tokenIdB,
        bool[] memory enabled
    ) external onlyOwner {
        _addPairs(tokenIdA, tokenIdB, enabled);
    }

    /**
     * @dev Toggle the ability to stake in the given pairIds.  Stakers can always withdraw, regardless of
     * this flag.
     */
    function enablePairs(uint256[] memory pairIds, bool[] memory enabled) external onlyOwner {
        _enablePairs(pairIds, enabled);
    }

    /**
     * @dev Set the maximum number of pairs that can be staked at any point in time.
     */
    function setMaxPairs(uint256 amount) external onlyOwner {
        maxPairs = amount;
    }

    /**

     * @dev Withdraw any unclaimed eth in the contract.  Can only be called if there are no stakers.
     */
    function withdrawUnclaimed() external onlyOwner {
        require(totalShares == 0, "Stakers");
        // send any unclaimed eth to the owner
        if (address(this).balance > 0) {
            Address.sendValue(payable(msg.sender), address(this).balance);
        }
    }

    /**
     * @dev Set the emergency flag
     */
    function setEmergency(bool value) external onlyOwner {
        emergency = value;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @dev Base contract that support ERC1155 token staking.  Any token is allowed to be be staked/unstaked in this base implementation.
 * Concrete implementations should either do validation checks prior to calling deposit/withdraw, or use the provided hooks
 * to do the checks.
 */
abstract contract ERC1155Staker is ERC1155Holder {
    // hooks

    /**
     * @dev Called prior to transfering given token id from account to this contract.  This is good spot to do
     * any checks and revert if the given account should be able to deposit the specified token.
     * Ths hook is ALWAYS called prior to a deposit -- both the single and batch variants.
     */
    function _beforeDeposit(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Called prior to transfering given token from this contract to the account.  This is good spot to do
     * any checks and revert if the given account should be able to withdraw the specified token.
     * Ths hook is ALWAYS called prior to a withdraw -- both the single and batch variants.
     */
    function _beforeWithdraw(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Deposit one or more instance of a single token.
     */
    function _depositSingle(
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "Invalid amount");
        _beforeDeposit(msg.sender, contractAddress, tokenId, amount);
        IERC1155(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
    }

    /**
     * @dev Deposit one or more instances of the spececified tokens.
     * As a convience for the caller, this returns the total number instances of tokens depositied (the sum of amounts).
     */
    function _deposit(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal virtual returns (uint256 totalTokensDeposited) {
        totalTokensDeposited = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(amounts[i] > 0, "Invalid amount");
            _beforeDeposit(msg.sender, contractAddress, tokenIds[i], amounts[i]);
            totalTokensDeposited += amounts[i];
        }

        IERC1155(contractAddress).safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "");
    }

    /**
     * @dev Withdraw one or more instance of a single token.
     * As a convience for the caller, this returns the total number instances of tokens depositied (the sum of amounts).
     */
    function _withdrawSingle(
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "Invalid amount");
        _beforeWithdraw(msg.sender, contractAddress, tokenId, amount);
        IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
    }

    /**
     * @dev Withdraw one or more instances of the spececified tokens.
     */
    function _withdraw(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal virtual returns (uint256 totalTokensWithdrawn) {
        totalTokensWithdrawn = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(amounts[i] > 0, "Invalid amount");
            _beforeWithdraw(msg.sender, contractAddress, tokenIds[i], amounts[i]);
            totalTokensWithdrawn += amounts[i];
        }

        IERC1155(contractAddress).safeBatchTransferFrom(address(this), msg.sender, tokenIds, amounts, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev Tracks amounts deposited and or withdrawn, on a per contract:token basis.  Does not allow an account to
 * withdraw more than it has deposited, and provides balance functions inspired by ERC1155.
 */
abstract contract BalanceTrackingMixin {
    struct DepositBalance {
        // balance of deposits, contract address => (token id => balance)
        mapping(address => mapping(uint256 => uint256)) balances;
    }

    mapping(address => DepositBalance) private accountBalances;

    function _depositIntoAccount(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 newBalance = accountBalances[account].balances[contractAddress][tokenId] + amount;
        accountBalances[account].balances[contractAddress][tokenId] = newBalance;
    }

    function _depositIntoAccount(
        address account,
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        require(tokenIds.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < amounts.length; i++) {
            _depositIntoAccount(account, contractAddress, tokenIds[i], amounts[i]);
        }
    }

    function _withdrawFromAccount(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(accountBalances[account].balances[contractAddress][tokenId] >= amount, "Insufficient balance");
        uint256 newBalance = accountBalances[account].balances[contractAddress][tokenId] - amount;
        accountBalances[account].balances[contractAddress][tokenId] = newBalance;
    }

    function _withdrawFromAccount(
        address account,
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        require(tokenIds.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < amounts.length; i++) {
            _withdrawFromAccount(account, contractAddress, tokenIds[i], amounts[i]);
        }
    }

    function balanceOf(
        address account,
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256 balance) {
        require(account != address(0), "Zero address");
        return accountBalances[account].balances[contractAddress][tokenId];
    }

    function balanceOfBatch(
        address account,
        address[] memory contractAddresses,
        uint256[] memory tokenIds
    ) public view returns (uint256[] memory batchBalances) {
        require(contractAddresses.length == tokenIds.length, "Length mismatch");

        batchBalances = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            batchBalances[i] = balanceOf(account, contractAddresses[i], tokenIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev Mixin to restrict staking to specific contract and tokens.  This intended for contracts where all
 * tokens eligible to stake are known ahead of time.
 */
abstract contract RestrictedPairsMixin {
    struct PairInfo {
        uint256 tokenIdA;
        uint256 tokenIdB;
        bool enabled;
    }

    address public tokenA;
    address public tokenB;

    uint256 public nextPairId;

    // pairId => pair
    mapping(uint256 => PairInfo) public pairs;

    constructor(address tokenAddressA, address tokenAddressB) {
        tokenA = tokenAddressA;
        tokenB = tokenAddressB;
    }

    modifier onlyEnabledPair(uint256 pairId) {
        require(isPairEnabled(pairId), "Not enabled");
        _;
    }

    function isPairEnabled(uint256 pairId) public view returns (bool) {
        return pairs[pairId].enabled;
    }

    function _enablePairs(uint256[] memory pairIds, bool[] memory enabled) internal {
        require(pairIds.length == enabled.length, "Array lengths");

        for (uint256 i = 0; i < pairIds.length; i++) {
            pairs[pairIds[i]].enabled = enabled[i];
        }
    }

    function _addPairs(
        uint256[] memory tokenIdsA,
        uint256[] memory tokenIdsB,
        bool[] memory enabled
    ) internal {
        require(tokenIdsA.length == tokenIdsB.length && tokenIdsB.length == enabled.length, "Array lengths");
        for (uint256 i = 0; i < tokenIdsA.length; i++) {
            pairs[nextPairId] = PairInfo({tokenIdA: tokenIdsA[i], tokenIdB: tokenIdsB[i], enabled: enabled[i]});
            nextPairId = nextPairId + 1;
        }
    }

    function getAllPairs() external view returns (PairInfo[] memory results) {
        results = new PairInfo[](nextPairId);

        for (uint256 i = 0; i < nextPairId; i++) {
            results[i] = pairs[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev Adds fractional reward tracking.  Each share is equally weighted.  This is generic in that
 * it can track anything -- it's not tied to a staked token or ether as the reward (rewards can be ether, ERC20, ...),
 * and this book-keeping should be done outside this contract.
 */
abstract contract RewardTrackingMixin {
    struct AccountInfo {
        uint256 shares;
        uint256 rewardDebt;
    }

    // total number of shares deposited
    uint256 public totalShares;

    // always increasing value
    uint256 private accumulatedRewardPerShare;

    mapping(address => AccountInfo) private accountRewards;

    function _addReward(uint256 amount) internal {
        if (totalShares == 0 || amount == 0) {
            return;
        }

        uint256 rewardPerShare = amount / totalShares;
        accumulatedRewardPerShare += rewardPerShare;
    }

    /**
     * @dev Updates the amount of shares for a user.  Callers must keep track of the share count
     * for a particular user to reduce storage required.
     */
    function _addShares(address account, uint256 amount) internal {
        totalShares += amount;

        accountRewards[account].shares += amount;
        _updateRewardDebtToCurrent(account);
    }

    function _removeShares(address account, uint256 amount) internal {
        require(amount <= accountRewards[account].shares, "Invalid account amount");
        require(amount <= totalShares, "Invalid global amount");

        totalShares -= amount;

        accountRewards[account].shares -= amount;
        _updateRewardDebtToCurrent(account);
    }

    /**
     * @dev Resets the given account to the initial state.  This should be used with caution!
     */
    function _resetRewardAccount(address account) internal {
        uint256 currentShares = accountRewards[account].shares;
        if (currentShares > 0) {
            totalShares -= currentShares;
            accountRewards[account].shares = 0;
            accountRewards[account].rewardDebt = 0;
        }
    }

    function _updateRewardDebtToCurrent(address account) internal {
        accountRewards[account].rewardDebt = accountRewards[account].shares * accumulatedRewardPerShare;
    }

    function accountPendingReward(address account) public view returns (uint256 pendingReward) {
        return accountRewards[account].shares * accumulatedRewardPerShare - accountRewards[account].rewardDebt;
    }

    function accountRewardShares(address account) public view returns (uint256 rewardShares) {
        return accountRewards[account].shares;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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