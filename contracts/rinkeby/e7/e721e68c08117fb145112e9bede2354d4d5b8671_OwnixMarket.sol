/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol



pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity ^0.8.0;


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

// File: contracts/OwnixNFT/IOwnixERC1155.sol



pragma solidity =0.8.7;



/**
 * @title Interface for contracts conforming to Ownix ERC155
 */
interface IOwnixERC1155 is IERC1155 {
  function getFirstTimeOwner(uint256 _tokenId) external view returns (address);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/OwnixToken/IOwnixERC20.sol



pragma solidity =0.8.7;


/**
 * @title Interface for contracts conforming to Ownix ERC-20
 */
interface IOwnixERC20 is IERC20 {
  function mint(address account, uint256 amount) external;
}

// File: contracts/OwnixMarket/IOwnixMarket.sol



pragma solidity =0.8.7;




interface IOwnixMarket {
  struct Auction {
    // nft owner address
    address nftOwner;
    // ERC1155 address
    IOwnixERC1155 nft;
    // ERC1155 token id
    uint256 tokenId;
    // Amount
    uint256 amount;
    // NFT Index
    uint32 index;
    // Reserve price for the list in wei
    uint256 reservePrice;
    // List duration
    uint32 duration;
    // Time when this list expires at
    uint256 expiresAt;
    // Bidder address
    address bidder;
    // Price for the bid in wei
    uint256 bidPrice;
    // Time when this bid create at
    uint256 bidCreatedAt;
  }

  // EVENTS
  event NFTListed(
    address indexed _owner,
    IOwnixERC1155 indexed _nft,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint256 _index,
    uint256 _reservePrice,
    uint256 _expiresAt
  );

  event NFTUnlisted(
    address indexed _owner,
    IOwnixERC1155 indexed _nft,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint256 _index
  );

  event ReservePriceChanged(
    address indexed _owner,
    IOwnixERC1155 indexed _nft,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint32 _index,
    uint256 _reservePrice
  );

  event BidCreated(
    IOwnixERC1155 indexed _nft,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint32 _index,
    address indexed _bidder,
    uint256 _price,
    uint256 bidCreatedAt
  );

  event AuctionExtended(
    address indexed _owner,
    IOwnixERC1155 indexed _nft,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint32 _index,
    uint256 _reservePrice,
    uint256 _expiresAt
  );

  event AuctionStarted(
    address _owner,
    IOwnixERC1155 _nft,
    uint256 _tokenId,
    uint256 _amount,
    uint32 _index,
    uint256 _reservePrice,
    uint256 _expiresAt
  );

  event BidAccepted(
    IOwnixERC1155 indexed _nft,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint256 _index,
    address _bidder,
    address indexed _seller,
    uint256 _price
  );

  event InflationPerMillionChanged(uint256 _inflationFeePerMillion);
  event BidFeePerMillionChanged(uint256 _bidFeePerMillion);
  event OwnerSharePerMillionChanged(uint256 _ownerSharePerMillion);
  event BidMinimumRaisePerMillionChanged(uint256 _bidMinimumRaisePerMillion);
  event BidMinimumRaiseAmountChanged(uint256 _bidMinimumRaiseAmount);
  event RoyaltiesPerMillionChanged(uint256 _royaltiesPerMillion);
  event MinimumAuctionDurationChanged(uint256 _minimumAuctionDuration);
  event FeeCollectorChanged(address _feeCollector);
  event InflationCollectorChanged(address _inflationCollector);

  /**
   * @dev List NFT
   * @param _tokenId - The token id
   * @param _amount The amount of tokens being transferred
   * @param _reservePrice The reserve price
   * @param _duration The auction duration in seconds
   */
  function listNFT(uint256 _tokenId, uint256 _amount, uint256 _reservePrice, uint32 _duration) external;

  /**
   * @dev Unlist NFT
   * @param _tokenId - The token id
   * @param _index The index of tokens being transferred
   */
  function unlistNFT(uint256 _tokenId, uint32 _index) external;

   /**
   * @dev Change reserve price
   * @param _tokenId - The token id
   * @param _index - The index of tokens being transferred
   * @param _reservePrice - The new reserve price
   */
  function changeReservePrice(uint256 _tokenId, uint32 _index, uint256 _reservePrice) external;

  /**
   * @dev Place a bid for an ERC1155 token.
   * @notice Tokens can have multiple bids by different users.
   * Users can have only one bid per token.
   * If the user places a bid and has an active bid for that token,
   * the older one will be replaced with the new one.
   * @param _tokenId - The  token id
   * @param _index - The index of tokens being transferred
   * @param _price - The price for the bid
   */
  function placeBid(uint256 _tokenId, uint32 _index, uint256 _price) external;

  /**
   * @dev Place a bid for an ERC1155 token.
   * @notice Tokens can have multiple bids by different users.
   * Users can have only one bid per token.
   * If the user places a bid and has an active bid for that token,
   * the older one will be replaced with the new one.
   * @param _bidder - The bidder address 
   * @param _tokenId - The token id
   * @param _index - The index of tokens being transferred
   * @param _price - The price for the bid
   * @param _deadline A timestamp, the current blocktime must be less than or equal to this timestamp
   * @param _v - Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param _r - Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param _s - Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function placeBidWithPermit(address _bidder, uint256 _tokenId, uint32 _index, uint256 _price, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
  
 /**
  * @dev Finish auction
  * @param _tokenId - The token id
  * @param _index - The index of tokens being transferred
  */
  function finishAuction(uint256 _tokenId, uint32 _index) external;

   /**
   * @dev Sets the inflation that's we mint every transfer
   * @param _inflationPerMillion - The inflation amount from 0 to 999,999
   */
  function setInflationPerMillion(uint256 _inflationPerMillion) external;

   /**
   * @dev Sets the bid fee that's charged to users to bid
   * @param _bidFeePerMillion - The fee amount from 0 to 999,999
   */
  function setBidFeePerMillion(uint256 _bidFeePerMillion) external;

   /**
   * @dev Sets the share Share for the owner of the contract that's
   * charged to the seller on a successful sale
   * @param _ownerSharePerMillion - The amount, from 0 to 999,999
   */
  function setOwnerSharePerMillion(uint256 _ownerSharePerMillion) external;

  /**
   * @dev Sets bid minimum raise percentage value
   * @param _bidMinimumRaisePerMillion - amount, from 0 to 999,999
   */
  function setBidMinimumRaisePerMillion(uint256 _bidMinimumRaisePerMillion) external;

  /**
   * @dev Sets bid minimum raise token amount value
   * @param _bidMinimumRaiseAmount - The raise token amount, bigger then 0
   */
  function setBidMinimumRaiseAmount(uint256 _bidMinimumRaiseAmount) external;

  /**
   * @dev Sets the fee collector address
   * @param _feeCollector - The fee collector address
   */
  function setFeeCollector(address _feeCollector) external;

   /**
   * @dev Sets the inflation collector address
   * @param _inflationCollector - The fee collector address
   */
  function setInflationCollector(address _inflationCollector) external;

   /**
   * @dev Sets royalties percentage value
   * @param _royaltiesPerMillion - The royalties amount, from 0 to 999,999
   */
  function setRoyaltiesPerMillion(uint256 _royaltiesPerMillion) external;

  /**
   * @dev Sets minimum auction duration
   * @param _minimumAuctionDuration - The minimum auction duration, bigger then 0
   */
  function setMinimumAuctionDuration(uint256 _minimumAuctionDuration) external;
  
   /**
   * @dev withdraw the erc20 tokens from the contract
   * @param _withdrawAddress - The withdraw address
   * @param _amount - The withdrawal amount
   */
  function withdrawERC20(address _withdrawAddress, uint256 _amount) external;

  /**
   * @dev withdraw the erc1155 tokens from the contract
   * @param _tokenAddress - The address of the ERC1155 token
   * @param _tokenId - The token id
   * @param _withdrawAddress - The withdraw address
   * @param _amount - The withdrawal amount
   */
  function withdrawERC1155(address _tokenAddress, uint256 _tokenId, address _withdrawAddress, uint256 _amount) external;

  /**
   * @dev Get auction by token id and index
   * @param _tokenId - The token id
   * @param _index - token index
   * @return auction
   */
  function getAuction(uint256 _tokenId, uint32 _index) external returns (Auction memory);

  /**
    * @dev Triggers stopped state.
    *
    * Requirements:
    *
    * - The contract must not be paused.
    */
  function pause() external;

  /**
    * @dev Returns to normal state.
    *
    * Requirements:
    *
    * - The contract must be paused.
    */
  function unpause() external;
}

// File: contracts/OwnixMarket/OwnixMarket.sol



pragma solidity =0.8.7;
pragma abicoder v2;










contract OwnixMarket is ERC1155Holder, Ownable, Pausable, IOwnixMarket, ReentrancyGuard {
  using Address for address;

  uint256 public constant ONE_MILLION = 1 * 10**6;

   // The ERC20 ownix token
  IOwnixERC20 immutable public ownixToken;

  // The ERC1155 ownix token
  IOwnixERC1155 immutable public ownixNFTToken;

   // The fee collector address
  address public feeCollector;
  
  // The inflation collector address
  address public inflationCollector;

  // Auctions by token token id => index => auction
  mapping(uint256 => mapping (uint256 => Auction)) private auctions;

  uint256 public inflationPerMillion;
  uint256 public bidFeePerMillion;
  uint256 public ownerSharePerMillion;
  uint256 public bidMinimumRaisePerMillion;
  uint256 public bidMinimumRaiseAmount;
  uint256 public royaltiesPerMillion;
  uint256 public minimumAuctionDuration;

  /**
   * @dev Constructor of the contract.
   * @param _ownixToken - address of the Ownix token
   * @param _ownixNFTToken - address of the Ownix NFT token
   * @param _owner - address of the owner for the contract
   * @param _feeCollector - address of the fee collector address
   * @param _inflationCollector - address of the inflation collector address
   */
  constructor(
    address _ownixToken,
    address _ownixNFTToken,
    address _owner,
    address _feeCollector,
    address _inflationCollector,
    uint256 _minimumAuctionDuration
  ) Ownable() Pausable() {
    require(_ownixToken != address(0), "Can't be zero address");
    require(_ownixNFTToken != address(0), "Can't not be zero address");
    require(_owner != address(0), "Can't be zero address");
    require(_feeCollector != address(0), "Can't be zero address");
    require(_inflationCollector != address(0), "Can't be zero address");
    require(_minimumAuctionDuration > 0, "Minimum auction duration can't be zero");

    ownixToken = IOwnixERC20(_ownixToken);
    ownixNFTToken = IOwnixERC1155(_ownixNFTToken);

    // Set owner
    transferOwnership(_owner);
    // Set fee collector address
    feeCollector = _feeCollector;
    // Set inflation fee collector address
    inflationCollector = _inflationCollector;
    // Set the minimum auction duration
    minimumAuctionDuration = _minimumAuctionDuration;
  }

  function listNFT(uint256 _tokenId, uint256 _amount, uint256 _reservePrice, uint32 _duration) override external nonReentrant() whenNotPaused() {
    require(_tokenId > 0, "token id can't be zero");
    require(_amount > 0, "amount can't be zero");
    require(_reservePrice > 0, "reservePrice id can't be zero");
    require(_duration >= minimumAuctionDuration, "duration must be bigger the minimum uction duration");

    for (uint32 i=0; i < _amount; ++i) {
      uint32 index = i;
      require(auctions[_tokenId][index].tokenId == 0, "auction with the same token id is already exists");
      
      auctions[_tokenId][index] = Auction({
        nftOwner: msg.sender,
        nft: ownixNFTToken,
        tokenId: _tokenId,
        amount: _amount,
        index: index,
        reservePrice: _reservePrice,
        duration: _duration,
        expiresAt: 0,
        bidder: address(0),
        bidPrice: 0,
        bidCreatedAt: 0
      });

      emit NFTListed(
        msg.sender,
        ownixNFTToken,
        _tokenId,
        _amount,
        index,
        _reservePrice,
        0
      );
     }
     

    ownixNFTToken.safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      _amount,
      ""
    );
  }

  function unlistNFT(uint256 _tokenId, uint32 _index) override external nonReentrant() whenNotPaused() {
    Auction memory auction = auctions[_tokenId][_index];
    require(auction.expiresAt == 0, "Can't unlist NFT after auction started");
    require(auction.nftOwner == msg.sender,  "Must be nft owner unlist NFT");
   
    emit NFTUnlisted(
     auction.nftOwner,
     ownixNFTToken, 
     _tokenId, 
     1,
     _index);

    ownixNFTToken.safeTransferFrom(
      address(this),
     auction.nftOwner,
      _tokenId,
      1,
      ""
    );

    delete auctions[_tokenId][_index];
  }

  function changeReservePrice(uint256 _tokenId, uint32 _index, uint256 _reservePrice) override external whenNotPaused() {
    Auction memory auction = auctions[_tokenId][_index];
    require(auction.expiresAt == 0, "Can't change reserve price after auction started");
    require(auction.nftOwner == msg.sender, "Must be nft owner to change reserve");

    auction.reservePrice = _reservePrice;

    auctions[_tokenId][_index] = auction;

    emit ReservePriceChanged(
      msg.sender,
      ownixNFTToken,
      _tokenId,
      1,
      _index,
      _reservePrice
    );
  }

  function placeBid(uint256 _tokenId, uint32 _index, uint256 _price) override external whenNotPaused() nonReentrant() { 
      _placeBid(msg.sender, _tokenId, _index, _price);
  }

  function placeBidWithPermit(
    address _bidder,
    uint256 _tokenId, 
    uint32 _index, 
    uint256 _price,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s) override external whenNotPaused() nonReentrant() {
     
      IERC20Permit(address(ownixToken)).permit(_bidder, address(this), _price, _deadline, _v, _r, _s);
      _placeBid(_bidder, _tokenId, _index, _price);
  }

  function finishAuction(uint256 _tokenId, uint32 _index) override external nonReentrant() whenNotPaused() {
   
    Auction memory auction = auctions[_tokenId][_index];

    require(auction.bidder != address(0), "Can't finish Auction without any bids");
    require(auction.expiresAt < block.timestamp, "Can't finish Auction before it been ended");

    uint256 saleShareAmount;
    if (ownerSharePerMillion > 0) {
      // Calculate sale share
      saleShareAmount = auction.bidPrice * ownerSharePerMillion / ONE_MILLION;
      // Transfer share amount to the bid contract
      require(
        ownixToken.transfer(feeCollector, saleShareAmount),
        "Transferring the share failed"
      );
    }

    uint256 royaltiesAmount;
    if (royaltiesPerMillion > 0) {
       address firstTimeOwner = ownixNFTToken.getFirstTimeOwner(auction.tokenId);
       if(firstTimeOwner != auction.nftOwner) {
        // Calculate royalties
        royaltiesAmount = auction.bidPrice * royaltiesPerMillion / ONE_MILLION;
        // Transfer royalties Owner
        require(
          ownixToken.transfer(firstTimeOwner, royaltiesAmount),
          "Transferring the royalties failed"
        );
      }
    }

    // Transfer ownixToken from bidder to seller
    require(
      ownixToken.transfer(auction.nftOwner, auction.bidPrice - (saleShareAmount + royaltiesAmount)),
      "Transferring ownixToken to nft owner failed"
    );

    if (inflationPerMillion > 0) {
      // Calculate mint tokens
      uint256 mintShareAmount = auction.bidPrice * inflationPerMillion / ONE_MILLION;
      // Mint the new ownix tokens to the inflationCollector
      ownixToken.mint(inflationCollector, mintShareAmount);
    }

    delete auctions[_tokenId][_index];
    
    // Transfer token to bidder
    ownixNFTToken.safeTransferFrom(
      address(this),
      auction.bidder,
      _tokenId,
      1,
      "");

    emit BidAccepted(
      ownixNFTToken,
      _tokenId,
      1,
      auction.index,
      auction.bidder,
      auction.nftOwner,
      auction.bidPrice
    );
  }

  function setInflationPerMillion(uint256 _inflationPerMillion) override external onlyOwner {
    require(
      _inflationPerMillion < ONE_MILLION,
      "The inflation should be between 0 and 999,999"
    );

    inflationPerMillion = _inflationPerMillion;
    emit InflationPerMillionChanged(inflationPerMillion);
  }

  function setBidFeePerMillion(uint256 _bidFeePerMillion) override external onlyOwner {
    require(
      _bidFeePerMillion < ONE_MILLION,
      "The bid fee should be between 0 and 999,999"
    );

    bidFeePerMillion = _bidFeePerMillion;
    emit BidFeePerMillionChanged(bidFeePerMillion);
  }

  function setOwnerSharePerMillion(uint256 _ownerSharePerMillion) override external onlyOwner {
    require(
      _ownerSharePerMillion < ONE_MILLION,
      "The owner share should be between 0 and 999,999"
    );

    ownerSharePerMillion = _ownerSharePerMillion;
    emit OwnerSharePerMillionChanged(ownerSharePerMillion);
  }

  function setBidMinimumRaisePerMillion(uint256 _bidMinimumRaisePerMillion) override external onlyOwner {
    require(
      _bidMinimumRaisePerMillion < ONE_MILLION,
      "bid minimum raise should be between 0 and 999,999"
    );

    bidMinimumRaisePerMillion = _bidMinimumRaisePerMillion;
    emit BidMinimumRaisePerMillionChanged(bidMinimumRaisePerMillion);
  }

  function setBidMinimumRaiseAmount(uint256 _bidMinimumRaiseAmount) override external onlyOwner {
    require(
      _bidMinimumRaiseAmount > 0,
      "bid minimum raise should be bigger then 0"
    );

    bidMinimumRaiseAmount = _bidMinimumRaiseAmount;
    emit BidMinimumRaiseAmountChanged(_bidMinimumRaiseAmount);
  }

  function setFeeCollector(address _feeCollector) override external onlyOwner {
    require(_feeCollector != address(0), "address can't be the zero address");

    feeCollector = _feeCollector;
    emit FeeCollectorChanged(_feeCollector);
  }

  function setInflationCollector(address _inflationCollector) override external onlyOwner {
    require(
      _inflationCollector != address(0),
      "address can't be the zero address"
    );

    inflationCollector = _inflationCollector;
    emit InflationCollectorChanged(_inflationCollector);
  }

  function setRoyaltiesPerMillion(uint256 _royaltiesPerMillion) override external onlyOwner {
    require(
      _royaltiesPerMillion < ONE_MILLION,
      "bid minimum raise should be between 0 and 999,999"
    );

    royaltiesPerMillion = _royaltiesPerMillion;
    emit RoyaltiesPerMillionChanged(_royaltiesPerMillion);
  }

  function setMinimumAuctionDuration(uint256 _minimumAuctionDuration) override external onlyOwner {
    require(
      _minimumAuctionDuration > 0,
      "Minimum auction duration should be bigger then 0"
    );

    minimumAuctionDuration = _minimumAuctionDuration;
    emit MinimumAuctionDurationChanged(_minimumAuctionDuration);
  }

  function withdrawERC20(address _withdrawAddress, uint256 _amount) override external onlyOwner {
    require(
      _withdrawAddress != address(0),
      "address can't be the zero address"
    );

    require(
      ownixToken.transfer(_withdrawAddress, _amount),
      "Withdraw failed"
    );
  }

  function withdrawERC1155(
    address _tokenAddress,
    uint256 _tokenId,
    address _withdrawAddress,
    uint256 _amount) override external onlyOwner {
    require(
      _withdrawAddress != address(0),
      "address can't be the zero address"
    );

    IERC1155(_tokenAddress).safeTransferFrom(
      address(this),
      _withdrawAddress,
      _tokenId,
      _amount,
      ""
    );
  }

  function getAuction(uint256 _tokenId, uint32 _index) override external view returns (Auction memory)  {
    return auctions[_tokenId][_index];
  }

  function pause() override external onlyOwner {
    _pause();
  }

  function unpause() override external onlyOwner {
    _unpause();
  }


  /**
   * @dev Place a bid for an ERC1155 token.
   * @notice Tokens can have multiple bids by different users.
   * Users can have only one bid per token.
   * If the user places a bid and has an active bid for that token,
   * the older one will be replaced with the new one.
   * @param _bidder - address the bidder address
   * @param _tokenId - uint256 of the token id
   * @param _index The index of tokens being transferred
   * @param _price - of the price for the bid
   */
  function _placeBid(address _bidder, uint256 _tokenId, uint32 _index, uint256 _price) private whenNotPaused() {
    Auction memory auction = auctions[_tokenId][_index];

    require(auctions[_tokenId][_index].tokenId != 0, "auction must be listed first");
    require(auction.expiresAt == 0 || auction.expiresAt > block.timestamp,
      "List has been ended, Can't place bid"
    );

    require(
      (_price >= (auction.bidPrice + bidMinimumRaiseAmount) ||
        _price >= auction.bidPrice + (auction.bidPrice * bidMinimumRaisePerMillion / ONE_MILLION)) &&
        _price >= auction.reservePrice,
      "Price should be bigger than highest bid and reserve price"
    );

    
    if(auction.bidder == address(0)) {
      auction.expiresAt = block.timestamp + auction.duration;
      auctions[_tokenId][_index] = auction;

        emit AuctionStarted(
          auction.nftOwner,
          ownixNFTToken,
          _tokenId,
          auction.amount,
          auction.index,
          auction.reservePrice,
          auction.expiresAt);
    } else {
      require(ownixToken.transfer(auction.bidder, auction.bidPrice), "Refund failed");
    }

    // check if place bid in the last minimum auction duration
    if (auction.expiresAt - block.timestamp <= minimumAuctionDuration) {
      auction.expiresAt = block.timestamp + minimumAuctionDuration;

      emit AuctionExtended(
        auction.nftOwner,
        ownixNFTToken,
        _tokenId,
        auction.amount,
        _index,
        auction.reservePrice,
        auction.expiresAt
      );
    }

    // Transfer tokens to the market
    require(
      ownixToken.transferFrom(_bidder, address(this), _price),
      "Transferring the bid amount to the marketplace failed"
    );

    // Check if there's a bid fee and transfer the amount to marketplace owner
    if (bidFeePerMillion > 0) {
      // Calculate sale share
      uint256 feeAmount  = _price * bidFeePerMillion / ONE_MILLION;
      require(
        ownixToken.transferFrom(_bidder, feeCollector, feeAmount),
        "Transferring the bid fee to the marketplace owner failed"
      );
    }

    uint256 bidCreatedAt = block.timestamp;

    // Save Bid
    auction.bidder = _bidder;
    auction.bidPrice = _price;
    auction.bidCreatedAt = bidCreatedAt;

    auctions[_tokenId][_index] = auction;

    emit BidCreated(
      ownixNFTToken,
      _tokenId,
      1,
      _index,
      _bidder,
      _price,
      bidCreatedAt
    );
  }
}