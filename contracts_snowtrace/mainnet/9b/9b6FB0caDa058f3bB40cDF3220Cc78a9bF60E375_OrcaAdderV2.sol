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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        return msg.data;
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

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './interfaces/IBank.sol';
import './interfaces/IYakStrategy.sol';
import './interfaces/IPair.sol';
import './interfaces/IWAVAX.sol';
import './lib/DexLibrary.sol';

contract OrcaAdderV2 is Ownable {
  using SafeERC20 for IERC20;

  IERC20 public pod;
  IERC20 private orca;
  IWAVAX private wavax;
  IERC20 private usdc;

  address private orcaLP;
  address private usdcLP;

  address public seafund;
  address public treasury;
  address public dev;

  uint256 public treasuryAmount;
  uint256 public devAmount;
  uint256 public seafundAmount;
  uint256 public podAmount;

  struct Bank {
    address bank;
    address yakStrat;
    address token;
    address swapLP;
  }

  Bank[] public banks;

  /**
   * @notice Initializes the Adder. We are doing proxy here as we might add seperate fees that need to be converted later. Easier than changing treasuries over.
   */
  constructor(
    address _pod,
    address _orca,
    address _wavax,
    address _usdc,
    address _seafund,
    address _treasury,
    address _dev,
    address _orcaLP,
    address _usdcLP
  ) {
    require(_pod != address(0), 'Pod cannot be zero address');
    require(_orca != address(0), 'ORCA cannot be zero address');
    require(_wavax != address(0), 'WAVAX cannot be zero address');
    require(_usdc != address(0), 'USDC cannot be zero address');
    require(_seafund != address(0), 'Seafund cannot be zero address');
    require(_treasury != address(0), 'Treasury cannot be zero address');
    require(_dev != address(0), 'Dev cannot be zero address');
    require(_orcaLP != address(0), 'ORCA LP cannot be zero address');
    require(_usdcLP != address(0), 'USDC LP cannot be zero address');

    pod = IERC20(_pod);
    orca = IERC20(_orca);
    wavax = IWAVAX(_wavax);
    usdc = IERC20(_usdc);

    seafund = _seafund;
    treasury = _treasury;
    dev = _dev;

    devAmount = 500;
    seafundAmount = 1500;
    treasuryAmount = 4000;
    podAmount = 4000;

    orcaLP = _orcaLP;
    usdcLP = _usdcLP;
  }

  modifier onlyEOA() {
    // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
    require(msg.sender == tx.origin, 'OrcaAdder: must use EOA');
    _;
  }

  /**
   * @notice Gets the numbers of banks this account controls
   */
  function getBankCount() public view returns (uint256) {
    return banks.length;
  }

  /**
   * @notice Adds a bank that this can get fees from
   * @param bank The address of the bank
   * @param yak The address of the yaks strat. 0 if not a yak strat
   * @param token The underlying token
   * @param lp The swap lp for the underlying token to avax
   */
  function addBank(
    address bank,
    address yak,
    address token,
    address lp
  ) public onlyOwner {
    require(bank != address(0), 'Cannot add a bank with zero address');
    Bank memory temp = Bank(bank, yak, token, lp);
    banks.push(temp);
  }

  /**
   * @notice removes a bank after being added
   * @param bankIndex The index of the bank
   */
  function removeBank(uint256 bankIndex) public onlyOwner {
    require(bankIndex < getBankCount(), 'Index does not exist');
    for (uint256 i = bankIndex; i < getBankCount() - 1; i++) {
      banks[i] = banks[i + 1];
    }
    banks.pop();
  }

  /**
   * @notice Adds a LP token, to allow transfering
   * @param _seafund The address of the LP token
   */
  function changeSeafund(address _seafund) public onlyOwner {
    require(_seafund != address(0), 'Seafund cannot be zero address');
    seafund = _seafund;
  }

  /**
   * @notice Adds a LP token, to allow transfering
   * @param _dev The address of the LP token
   */
  function changeDev(address _dev) public onlyOwner {
    require(_dev != address(0), 'Dev cannot be zero address');
    dev = _dev;
  }

  /**
   * @notice Adds a LP token, to allow transfering
   * @param _treasury The address of the LP token
   */
  function changeTreasury(address _treasury) public onlyOwner {
    require(_treasury != address(0), 'Treasury cannot be zero address');
    treasury = _treasury;
  }

  /**
   * @notice Changes distribution ratio
   * @param _treasuryAmount The treasury amount
   * @param _devAmount The dev amount
   * @param _seafundAmount The seafund amount
   * @param _podAmount The pod amount
   */
  function changeDistributionRatio(
    uint256 _treasuryAmount,
    uint256 _devAmount,
    uint256 _seafundAmount,
    uint256 _podAmount
  ) public onlyOwner {
    require(
      _treasuryAmount + _devAmount + _seafundAmount + _podAmount == 10000,
      'Must add up to 10000'
    );
    treasuryAmount = _treasuryAmount;
    devAmount = _devAmount;
    seafundAmount = _seafundAmount;
    podAmount = _podAmount;
  }

  /**
   * @notice Safe function to ensure we can emergency remove things
   * @param _to The address to send it to
   * @param _token The token to send
   * @param _amount The amount to send
   */
  function transferToken(
    address _to,
    address _token,
    uint256 _amount
  ) public onlyOwner {
    IERC20(_token).safeTransfer(_to, _amount);
  }

  /**
   * @notice Safe function to ensure we can emergency remove things
   * @param _to The address to send it to
   * @param _amount The amount to send
   */
  function transferAvax(address payable _to, uint256 _amount)
    external
    onlyOwner
  {
    (bool sent, ) = _to.call{value: _amount}('');
    require(sent, 'failed to send avax');
  }

  /**
   * @notice for transfering treasury bank vault. Only use if changing contracts.
   * @param bankIndex The bank id
   * @param vault the vault id
   * @param to who you're transfering it to
   */
  function transferBankVault(
    uint256 bankIndex,
    uint256 vault,
    address to
  ) public onlyOwner {
    require(bankIndex < getBankCount(), 'Bank does not exist');
    require(to != address(0), 'Cannot transfer to zero address');
    IBank(banks[bankIndex].bank).transferVault(vault, to);
  }

  /**
   * @notice For allocating the revenue to the correct locations.
   */
  function allocate() public onlyEOA {
    // Withdraw collaterals from banks
    for (uint256 i = 0; i < getBankCount(); i++) {
      IBank bank = IBank(banks[i].bank);

      if (bank.balanceOf(address(this)) > 0) {
        uint256 vault = bank.tokenOfOwnerByIndex(address(this), 0);
        uint256 collateral = bank.vaultCollateral(vault);
        bank.withdrawCollateral(vault, collateral);
      }

      // Check if yak strat
      if (banks[i].yakStrat != address(0)) {
        IYakStrategy yakStrat = IYakStrategy(banks[i].yakStrat);
        uint256 balance = yakStrat.balanceOf(address(this));
        if (balance > 10000) {
          try yakStrat.withdraw(balance) {} catch {}
        }
      }

      // Swap tokens
      address token = banks[i].token;
      if (token != address(0)) {
        IPair pair = IPair(banks[i].swapLP);
        if (address(pair) != address(0)) {
          uint256 tokenBalance = IERC20(token).balanceOf(address(this));
          if (tokenBalance > 10000) {
            DexLibrary.swap(tokenBalance, token, address(wavax), pair);
          }
        }
      }
    }

    // Convert USDC to wavax if we have any
    if (usdc.balanceOf(address(this)) > 0) {
      // Convert wavax to usdc
      DexLibrary.swap(
        usdc.balanceOf(address(this)),
        address(usdc),
        address(wavax),
        IPair(usdcLP)
      );
    }

    // Convert avax to wavax if we have any
    uint256 avaxBalance = address(this).balance;
    wavax.deposit{value: avaxBalance}();

    // Convert correct amount of WAVAX to ORCA
    uint256 wavaxBalance = wavax.balanceOf(address(this));
    uint256 wavaxToPod = (wavaxBalance * podAmount) / 10000;
    uint256 wavaxToUSDC = (wavaxBalance * (10000 - podAmount)) / 10000;
    require(wavaxToPod > 10000, 'Not enough wavax to trade for orca');
    DexLibrary.swap(wavaxToPod, address(wavax), address(orca), IPair(orcaLP));
    require(wavaxToUSDC > 10000, 'Not enough wavax to trade for usdc');
    // Convert wavax to usdc
    DexLibrary.swap(wavaxToUSDC, address(wavax), address(usdc), IPair(usdcLP));

    // Send off orca
    orca.safeTransfer(address(pod), orca.balanceOf(address(this)));

    // send off usdc
    uint256 usdcBalance = usdc.balanceOf(address(this));

    // Seafund
    usdc.safeTransfer(
      seafund,
      (usdcBalance * seafundAmount) / (10000 - podAmount)
    );

    // Treasury
    usdc.safeTransfer(
      treasury,
      (usdcBalance * treasuryAmount) / (10000 - podAmount)
    );

    // dev
    usdc.safeTransfer(dev, usdc.balanceOf(address(this)));

    // DONE!
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface IBank is IERC721, IERC721Enumerable {
  function vaultCollateral(uint256 vaultID) external view returns (uint256);

  function vaultDebt(uint256 vaultID) external view returns (uint256);

  function transferVault(uint256 vaultID, address to) external;

  function vaultExists(uint256 vaultID) external view returns (bool);

  function depositCollateral(uint256 vaultID, uint256 amount) external;

  function borrowToken(uint256 vaultID, uint256 amount) external;

  function payBackToken(uint256 vaultID, uint256 amount) external;

  function withdrawCollateral(uint256 vaultID, uint256 amount) external;

  function destroyVault(uint256 vaultID) external;

  function getPaid(address user) external;

  function getPriceSource() external view returns (uint256);

  function getPricePeg() external view returns (uint256);

  function changeTreasury(address to) external;

  function setGainRatio(uint256 gainRatio_) external;

  function setDebtRatio(uint256 debtRatio_) external;

  function setDebtCeiling(uint256 debtCeiling_) external;

  function setPriceSource(address priceSource_) external;

  function setTokenPeg(uint256 tokenPeg_) external;

  function setStabilityPool(address stabilityPool_) external;

  function setGateway(address gateway_) external;

  function setClosingFee(uint256 amount) external;

  function setOpeningFee(uint256 amount) external;

  function setTreasury(uint256 treasury_) external;

  function setMinimumDebt(uint256 minimumDebt_) external;

  function setMintingPaused(bool paused_) external;

  function setMinimumCollateralPercentage(uint256 mcp_) external;

  function initialize(
    uint256 minimumCollateralPercentage_,
    address priceSource_,
    string memory name_,
    string memory symbol_,
    address token_,
    address owner
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWAVAX {
  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IYakStrategy is IERC20Metadata {
  function getSharesForDepositTokens(uint256 amount)
    external
    view
    returns (uint256);

  function getDepositTokensForShares(uint256 amount)
    external
    view
    returns (uint256);

  function totalDeposits() external view returns (uint256);

  function estimateReinvestReward() external view returns (uint256);

  function checkReward() external view returns (uint256);

  function estimateDeployedBalance() external view returns (uint256);

  function withdraw(uint256 amount) external;

  function deposit(uint256 amount) external;

  function deposit() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IPair.sol';
import '../interfaces/IWAVAX.sol';

library DexLibrary {
  bytes private constant zeroBytes = new bytes(0);
  IWAVAX private constant WAVAX =
    IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

  /**
   * @notice Swap directly through a Pair
   * @param amountIn input amount
   * @param fromToken address
   * @param toToken address
   * @param pair Pair used for swap
   * @return output amount
   */
  function swap(
    uint256 amountIn,
    address fromToken,
    address toToken,
    IPair pair
  ) internal returns (uint256) {
    (address token0, ) = sortTokens(fromToken, toToken);
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
    uint256 amountOut1 = 0;
    uint256 amountOut2 = getAmountOut(amountIn, reserve0, reserve1);
    if (token0 != fromToken)
      (amountOut1, amountOut2) = (amountOut2, amountOut1);
    safeTransfer(fromToken, address(pair), amountIn);
    pair.swap(amountOut1, amountOut2, address(this), zeroBytes);
    return amountOut2 > amountOut1 ? amountOut2 : amountOut1;
  }

  function checkSwapPairCompatibility(
    IPair pair,
    address tokenA,
    address tokenB
  ) internal view returns (bool) {
    return
      (tokenA == pair.token0() || tokenA == pair.token1()) &&
      (tokenB == pair.token0() || tokenB == pair.token1()) &&
      tokenA != tokenB;
  }

  function estimateConversionThroughPair(
    uint256 amountIn,
    address fromToken,
    address toToken,
    IPair swapPair
  ) internal view returns (uint256) {
    (address token0, ) = sortTokens(fromToken, toToken);
    (uint112 reserve0, uint112 reserve1, ) = swapPair.getReserves();
    if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
    return getAmountOut(amountIn, reserve0, reserve1);
  }

  /**
   * @notice Converts reward tokens to deposit tokens
   * @dev No price checks enforced
   * @param amount reward tokens
   * @return deposit tokens
   */
  function convertRewardTokensToDepositTokens(
    uint256 amount,
    address rewardToken,
    address depositToken,
    IPair swapPairToken0,
    IPair swapPairToken1
  ) internal returns (uint256) {
    uint256 amountIn = amount / 2;
    require(amountIn > 0, 'DexLibrary::_convertRewardTokensToDepositTokens');

    address token0 = IPair(depositToken).token0();
    uint256 amountOutToken0 = amountIn;
    if (rewardToken != token0) {
      amountOutToken0 = DexLibrary.swap(
        amountIn,
        rewardToken,
        token0,
        swapPairToken0
      );
    }

    address token1 = IPair(depositToken).token1();
    uint256 amountOutToken1 = amountIn;
    if (rewardToken != token1) {
      amountOutToken1 = DexLibrary.swap(
        amountIn,
        rewardToken,
        token1,
        swapPairToken1
      );
    }

    return
      DexLibrary.addLiquidity(depositToken, amountOutToken0, amountOutToken1);
  }

  /**
   * @notice Add liquidity directly through a Pair
   * @dev Checks adding the max of each token amount
   * @param depositToken address
   * @param maxAmountIn0 amount token0
   * @param maxAmountIn1 amount token1
   * @return liquidity tokens
   */
  function addLiquidity(
    address depositToken,
    uint256 maxAmountIn0,
    uint256 maxAmountIn1
  ) internal returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IPair(address(depositToken))
      .getReserves();
    uint256 amountIn1 = _quoteLiquidityAmountOut(
      maxAmountIn0,
      reserve0,
      reserve1
    );
    if (amountIn1 > maxAmountIn1) {
      amountIn1 = maxAmountIn1;
      maxAmountIn0 = _quoteLiquidityAmountOut(maxAmountIn1, reserve1, reserve0);
    }

    safeTransfer(IPair(depositToken).token0(), depositToken, maxAmountIn0);
    safeTransfer(IPair(depositToken).token1(), depositToken, amountIn1);
    return IPair(depositToken).mint(address(this));
  }

  /**
   * @notice Add liquidity directly through a Pair
   * @dev Checks adding the max of each token amount
   * @param depositToken address
   * @return amounts of each token returned
   */
  function removeLiquidity(address depositToken)
    internal
    returns (uint256, uint256)
  {
    IPair pair = IPair(address(depositToken));
    require(address(pair) != address(0), 'Invalid pair for removingliquidity');

    safeTransfer(depositToken, depositToken, pair.balanceOf(address(this)));
    (uint256 amount0, uint256 amount1) = pair.burn(address(this));

    return (amount0, amount1);
  }

  /**
   * @notice Quote liquidity amount out
   * @param amountIn input tokens
   * @param reserve0 size of input asset reserve
   * @param reserve1 size of output asset reserve
   * @return liquidity tokens
   */
  function _quoteLiquidityAmountOut(
    uint256 amountIn,
    uint256 reserve0,
    uint256 reserve1
  ) private pure returns (uint256) {
    return (amountIn * reserve1) / reserve0;
  }

  /**
   * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
   * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
   * @param tokenA address
   * @param tokenB address
   * @return sorted tokens
   */
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address, address)
  {
    return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  /**
   * @notice Given an input amount of an asset and pair reserves, returns maximum output amount of the other asset
   * @dev Assumes swap fee is 0.30%
   * @param amountIn input asset
   * @param reserveIn size of input asset reserve
   * @param reserveOut size of output asset reserve
   * @return maximum output amount
   */
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256) {
    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = reserveIn * 1000 + amountInWithFee;
    return numerator / denominator;
  }

  /**
   * @notice Safely transfer using an anonymous ERC20 token
   * @dev Requires token to return true on transfer
   * @param token address
   * @param to recipient address
   * @param value amount
   */
  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    require(
      IERC20(token).transfer(to, value),
      'DexLibrary::TRANSFER_FROM_FAILED'
    );
  }
}