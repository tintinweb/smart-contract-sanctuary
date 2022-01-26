/**
 *Submitted for verification at FtmScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File @openzeppelin/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File @openzeppelin/contracts/access/IOwnable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

interface IOwnable {
    function owner() external view returns (address);
    
    function pushOwnership(address newOwner) external;
    
    function pullOwnership() external;
    
    function renounceOwnership() external;
    
    function transferOwnership(address newOwner) external;
}

// File @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract Ownable is IOwnable, Context {
    address private _owner;
    address private _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);
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
    function owner() public view virtual override returns (address) {
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
     * @dev Sets up a push of the ownership of the contract to the specified
     * address which must subsequently pull the ownership to accept it.
     */
    function pushOwnership(address newOwner) public virtual override onlyOwner {
        require( newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner );
        _newOwner = newOwner;
    }

    /**
     * @dev Accepts the push of ownership of the contract. Must be called by
     * the new owner.
     */
    function pullOwnership() public override virtual {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
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

// File contracts/ERC721StakingBasicDrip/ERC721NFTStakingBasicDrip.sol

contract ERC721NFTStakingBasicDrip is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    event Stake(
        address indexed owner,
        address indexed nftContract,
        uint256 indexed tokenId,
        address rewardToken
    );
    event UnStake(
        address indexed owner,
        address indexed nftContract,
        uint256 indexed tokenId,
        address rewardToken
    );
    event RewardWalletChanged(
        address indexed oldRewardWallet,
        address indexed newRewardWallet
    );
    event MinimumStakingTimeChanged(uint256 indexed oldTime, uint256 newTime);
    event PermittedRewardToken(address indexed token, uint256 dripRate);
    event ChangeDripRate(
        address indexed token,
        uint256 oldDripRate,
        uint256 newDripRate
    );
    event DeniedRewardToken(address indexed token, uint256 dripRate);
    event PermittedNFTContract(address indexed nftContract);
    event DeniedNFTContract(address indexed nftContract);
    event ClaimRewards(
        bytes32 indexed stakeId,
        address indexed owner,
        uint256 indexed amount
    );
    event ReceivedERC721(
        address operator,
        address from,
        uint256 tokenId,
        bytes data,
        uint256 gas
    );

    // holds the list of permitted NFTs
    EnumerableSet.AddressSet private permittedNFTs;

    // holds the list of currently permitted reward tokens
    EnumerableSet.AddressSet private permittedRewardTokens;

    // holds the list of all permitted reward tokens (active or not)
    EnumerableSet.AddressSet private allRewardTokens;

    // holds the reward token drip rate
    mapping(address => uint256) public rewardTokenDripRate;

    struct StakedNFT {
        address owner; // the owner of the NFT
        IERC721 nftContract; // the ERC721 contract for which the NFT belongs
        uint256 tokenId; // the token ID staked
        uint256 stakedTimestamp; // the time that the NFT was staked
        uint256 lastClaimTimestamp; // the last time that the user claimed rewards for this NFT
        IERC20 rewardToken; // the token to reward for staking
    }

    struct ClaimableInfo {
        bytes32 stakeId; // the stake id
        address rewardToken; // the token to reward for staking
        uint256 amount; // the amount of the reward for the stake id
    }

    // holds the mapping of stake ids to the staked NFT values
    mapping(bytes32 => StakedNFT) public stakedNFTs;

    // holds the mapping of stakers to their staking ids
    mapping(address => EnumerableSet.Bytes32Set) private userStakes;

    // holds the mapping of the staker's reward payments
    mapping(address => mapping(address => uint256)) private userRewards;

    // holds the number of staked NFTs per reward token
    mapping(address => uint256) public stakesPerRewardToken;

    // holds the amount of rewards paid by reward token for all users
    mapping(address => uint256) public rewardsPaid;

    // holds the address of the wallet that contains the staking rewards
    address public rewardWallet;

    // the minimum amount of time required before claiming rewards via the drip
    uint256 public MINIMUM_STAKING_TIME_FOR_REWARDS;

    constructor(address _rewardWallet) {
        rewardWallet = _rewardWallet;

        MINIMUM_STAKING_TIME_FOR_REWARDS = 24 hours;

        emit RewardWalletChanged(address(0), _rewardWallet);
        emit MinimumStakingTimeChanged(0, MINIMUM_STAKING_TIME_FOR_REWARDS);
    }

    /****** STANDARD OPERATIONS ******/

    /**
     * @dev returns information regarding how long the current rewards for the token
     * in the reward wallet can maintain the current drip rate
     */
    function runway(IERC20 token)
        public
        view
        returns (
            uint256 _balance,
            uint256 _dripRatePerSecond,
            uint256 _stakeCount,
            uint256 _runRatePerSecond,
            uint256 _runRatePerDay,
            uint256 _runwaySeconds,
            uint256 _runwayDays
        )
    {
        _balance = token.balanceOf(rewardWallet);

        _stakeCount = stakesPerRewardToken[address(token)];

        _dripRatePerSecond = rewardTokenDripRate[address(token)];

        _runRatePerSecond = _dripRatePerSecond * _stakeCount;

        _runRatePerDay = _runRatePerSecond * 24 hours;

        _runwaySeconds = _balance / _runRatePerSecond;

        _runwayDays = _runwaySeconds / 24 hours;
    }

    /**
     * @dev returns an array of all staked NFT for the caller
     */
    function staked() public view returns (StakedNFT[] memory) {
        // retrieve all of the stake ids for the caller
        bytes32[] memory ids = stakeIds(_msgSender());

        // construct the temporary staked information
        StakedNFT[] memory stakes = new StakedNFT[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            stakes[i] = stakedNFTs[ids[i]];
        }

        return stakes;
    }

    /**
     * @dev returns a paired set of arrays that gives the history of
     * all rewards paid to the caller regardless of if the contract
     * currently permits the reward token
     */
    function rewardHistory()
        public
        view
        returns (address[] memory _rewardTokens, uint256[] memory _rewardsPaid)
    {
        _rewardTokens = allRewardTokens.values();

        _rewardsPaid = new uint256[](allRewardTokens.length());

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _rewardsPaid[i] = userRewards[_msgSender()][_rewardTokens[i]];
        }
    }

    /**
     * @dev retrieves the stake ids for the specified account
     */
    function stakeIds(address account) public view returns (bytes32[] memory) {
        return userStakes[account].values();
    }

    /**
     * @dev changes the reward wallet
     */
    function setRewardWallet(address wallet) public onlyOwner {
        address old = rewardWallet;
        rewardWallet = wallet;

        emit RewardWalletChanged(old, wallet);
    }

    /**
     * @dev updates the minimum staking time for rewards
     */
    function setMinimumStakingTimeForRewards(uint256 minimumStakingTime)
        public
        onlyOwner
    {
        require(
            minimumStakingTime >= 900,
            "must be at least 900 seconds due to block timestamp variations"
        );

        uint256 old = MINIMUM_STAKING_TIME_FOR_REWARDS;
        MINIMUM_STAKING_TIME_FOR_REWARDS = minimumStakingTime;

        emit MinimumStakingTimeChanged(old, minimumStakingTime);
    }

    /****** STAKING REWARD CLAIMING METHODS ******/

    /**
     * @dev calculates the claimable balance for the given stake ID
     */
    function _claimableBalance(bytes32 stakeId)
        internal
        view
        returns (uint256)
    {
        StakedNFT memory info = stakedNFTs[stakeId];

        // if they haven't staked long enough, their claimable rewards are 0
        if (
            block.timestamp <
            info.stakedTimestamp + MINIMUM_STAKING_TIME_FOR_REWARDS
        ) {
            return 0;
        }

        // calculate how long it's been since the last time they claimed
        uint256 delta = block.timestamp - info.lastClaimTimestamp;

        // calculate how much is claimable based upon the drip rate for the token * the time elapsed
        return rewardTokenDripRate[address(info.rewardToken)] * delta;
    }

    /**
     * @dev returns all of the claimable stakes for the caller
     */
    function claimable() public view returns (ClaimableInfo[] memory) {
        // retrieve all of the stake ids for the caller
        bytes32[] memory ids = stakeIds(_msgSender());

        // construct the temporary claimable information
        ClaimableInfo[] memory claims = new ClaimableInfo[](ids.length);

        // loop through all of the caller's stake ids
        for (uint256 i = 0; i < ids.length; i++) {
            // construct the claimable information structure
            claims[i] = ClaimableInfo({
                stakeId: ids[i],
                rewardToken: address(stakedNFTs[ids[i]].rewardToken),
                amount: _claimableBalance(ids[i])
            });
        }

        return claims;
    }

    /**
     * @dev claims the stake with the given ID
     *
     * Requirements:
     *
     * - Must be owner of the stake id
     */
    function claim(bytes32 stakeId) public {
        _claim(stakeId);
    }

    /**
     * @dev claims all of the available stakes for the caller
     */
    function claimAll() public {
        // retrieve all of the stake ids for the caller
        bytes32[] memory ids = stakeIds(_msgSender());

        // loop through all of the caller's stake ids
        for (uint256 i = 0; i < ids.length; i++) {
            // only try to claim if they have a claimable balance (saves gas)
            if (_claimableBalance(ids[i]) != 0) {
                _claim(ids[i]); // process the claim
            }
        }
    }

    /**
     * @dev internal method called when claiming staking rewards
     */
    function _claim(bytes32 stakeId) internal {
        require(
            stakedNFTs[stakeId].owner == _msgSender(),
            "not the owner of the specified stake id"
        );

        StakedNFT memory info = stakedNFTs[stakeId];

        // get the claimable balance for this stake id
        uint256 _claimableAmount = _claimableBalance(stakeId);

        require(
            info.rewardToken.allowance(rewardWallet, address(this)) >=
                _claimableAmount,
            "contract not authorized for claimable amount, contact the team"
        );

        // update the last claimed timestamp
        stakedNFTs[stakeId].lastClaimTimestamp = block.timestamp;

        // add the reward amount to the total amount for the reward token that we have paid out
        rewardsPaid[address(info.rewardToken)] += _claimableAmount;

        // add the reward amount to the users individual tracking of what we've paid out
        userRewards[_msgSender()][
            address(info.rewardToken)
        ] += _claimableAmount;

        // transfer the claimable rewards to the caller
        info.rewardToken.safeTransferFrom(
            rewardWallet,
            _msgSender(),
            _claimableAmount
        );

        emit ClaimRewards(stakeId, _msgSender(), _claimableAmount);
    }

    /****** STAKING METHODS ******/

    function _generateStakeId(
        address owner,
        address nftContract,
        uint256 tokenId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    owner,
                    nftContract,
                    tokenId,
                    block.timestamp,
                    block.number
                )
            );
    }

    /**
     * @dev allows a user to stake their NFT into the contract
     *
     * Requirements:
     *
     * - contract must be approved to transfer the NFT
     */
    function stake(
        IERC721 nftContract,
        uint256 tokenId,
        IERC20 rewardToken
    ) public returns (bytes32) {
        require(
            permittedNFTs.contains(address(nftContract)),
            "NFT is not permitted to be staked"
        );
        require(
            permittedRewardTokens.contains(address(rewardToken)),
            "Reward token is not permitted"
        );
        require(
            nftContract.getApproved(tokenId) == address(this),
            "not permitted to take ownership of NFT for staking"
        );

        // take ownership of the NFT
        nftContract.safeTransferFrom(_msgSender(), address(this), tokenId);

        // generate the stake ID
        bytes32 stakeId = _generateStakeId(
            _msgSender(),
            address(nftContract),
            tokenId
        );

        // add the stake Id record
        stakedNFTs[stakeId] = StakedNFT({
            owner: _msgSender(),
            nftContract: nftContract,
            tokenId: tokenId,
            stakedTimestamp: block.timestamp,
            lastClaimTimestamp: block.timestamp,
            rewardToken: rewardToken
        });

        // add the stake ID to the user's tracking
        userStakes[_msgSender()].add(stakeId);

        // increment the number of stakes for the given reward token
        stakesPerRewardToken[address(rewardToken)] += 1;

        emit Stake(
            _msgSender(),
            address(nftContract),
            tokenId,
            address(rewardToken)
        );

        return stakeId;
    }

    /**
     * @dev allows the user to unstake their NFT using the specified stake ID
     */
    function unstake(bytes32 stakeId) public {
        require(
            stakedNFTs[stakeId].owner == _msgSender(),
            "not the owner of the specified stake id"
        );

        // pull the staked NFT info
        StakedNFT memory info = stakedNFTs[stakeId];

        // if the user has a claimable balance, claim it upon unstake
        if (_claimableBalance(stakeId) != 0) {
            _claim(stakeId);
        }

        // delete the record
        delete stakedNFTs[stakeId];

        // delete the stake ID from the user's tracking
        userStakes[_msgSender()].remove(stakeId);

        // decrement the number of stakes for the given reward token
        stakesPerRewardToken[address(info.rewardToken)] -= 1;

        // transfer the NFT back to the user
        info.nftContract.safeTransferFrom(
            address(this),
            _msgSender(),
            info.tokenId
        );

        emit UnStake(
            info.owner,
            address(info.nftContract),
            info.tokenId,
            address(info.rewardToken)
        );
    }

    /****** MANAGEMENT OF PERMITTED REWARD TOKENS ******/

    function isPermittedRewardToken(address token) public view returns (bool) {
        return permittedRewardTokens.contains(token);
    }

    /**
     * @dev returns an array of the permitted reward tokens
     */
    function rewardTokens() public view returns (address[] memory) {
        return permittedRewardTokens.values();
    }

    /**
     * @dev adds the specified token as a permitted reward token at the specified drip rate
     *
     * WARNING: amountOfTokenPerDayPerNFT is expressed as the amount of the token to
     *          drip per day per NFT expressed in atomic units (gwei)
     *          ex. FTM has 18 decimals; therefore,
     *          1.0 FTM = 1000000000000000000 atomic units
     *          a dripRate of 1 would drip 0.000000000000000001 a second per NFT
     *
     */
    function permitRewardToken(address token, uint256 amountOfTokenPerDayPerNFT)
        public
        onlyOwner
    {
        require(
            !permittedRewardTokens.contains(token),
            "Reward token is already permitted"
        );

        permittedRewardTokens.add(token);

        // keeps track of all tokens that have been permitted in the past
        // so that we can track all payouts for all rewards tokens for users
        // as such, we only want to add it to the set once in case it is added
        // again later after it has been removed
        if (!allRewardTokens.contains(token)) {
            allRewardTokens.add(token);
        }

        // set the drip rate based upon the amount released per day divided by the seconds in a day
        rewardTokenDripRate[token] = amountOfTokenPerDayPerNFT / 24 hours;

        require(
            rewardTokenDripRate[token] != 0,
            "amountOfTokenPerDayPerNFT results in a zero (0) drip rate"
        );

        emit PermittedRewardToken(token, rewardTokenDripRate[token]);
    }

    /**
     * @dev updates the drip rate for the given token to the specified value
     *
     * WARNING: amountOfTokenPerDayPerNFT is expressed as the amount of the token to
     *          drip per day per NFT expressed in atomic units (gwei)
     *          ex. FTM has 18 decimals; therefore,
     *          1.0 FTM = 1000000000000000000 atomic units
     *          a dripRate of 1 would drip 0.000000000000000001 a second per NFT
     *
     */
    function setRewardTokenDripRate(
        address token,
        uint256 amountOfTokenPerDayPerNFT
    ) public onlyOwner {
        require(
            permittedRewardTokens.contains(token),
            "Reward token is not permitted"
        );

        uint256 old = rewardTokenDripRate[token];

        // set the drip rate based upon the amount released per day divided by the seconds in a day
        rewardTokenDripRate[token] = amountOfTokenPerDayPerNFT / 24 hours;

        require(
            rewardTokenDripRate[token] != 0,
            "amountOfTokenPerDayPerNFT results in a zero (0) drip rate"
        );

        emit ChangeDripRate(token, old, rewardTokenDripRate[token]);
    }

    /**
     * @dev removes the specified token from the permitted reward token list
     *
     * WARNING: If a user still has a staked NFT for the reward token
     *          their selected reward token will not switch to something
     *          else and they will still be able to claim the drip rewards
     *          assuming that the reward wallet has enough of a balance of
     *          the token to do pay it out. This method simply stops letting
     *          users select the reward token as the reward for staking their NFT
     *
     * Requirements:
     *
     * - Token must not be currently used by a staked user
     */
    function denyRewardToken(address token) public onlyOwner {
        require(
            permittedRewardTokens.contains(token),
            "Reward token is not permitted"
        );

        uint256 dripRate = rewardTokenDripRate[token];

        permittedRewardTokens.remove(token);

        emit DeniedRewardToken(token, dripRate);
    }

    /****** MANAGEMENT OF PERMITTED NFTs ******/

    function isPermittedNFT(address nftContract) public view returns (bool) {
        return permittedNFTs.contains(nftContract);
    }

    /**
     * @dev returns an array of the permitted NFTs
     */
    function nfts() public view returns (address[] memory) {
        return permittedNFTs.values();
    }

    /**
     * @dev adds the specified nft contract as an acceptable NFT for staking purposes
     */
    function permitNFT(address nftContract) public onlyOwner {
        require(!permittedNFTs.contains(nftContract), "NFT already permitted");

        permittedNFTs.add(nftContract);

        emit PermittedNFTContract(nftContract);
    }

    /**
     * @dev removes the specified nft contract from being an acceptable NFT for staking purposes
     */
    function denyNFT(address nftContract) public onlyOwner {
        require(permittedNFTs.contains(nftContract), "NFT is not permitted");

        permittedNFTs.remove(nftContract);

        emit DeniedNFTContract(nftContract);
    }

    /**
     * @dev handles IERC721.safeTransferFrom()
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        require(
            operator == address(this),
            "Cannot send tokens to contract directly"
        );

        emit ReceivedERC721(operator, from, tokenId, data, gasleft());

        return IERC721Receiver.onERC721Received.selector;
    }
}