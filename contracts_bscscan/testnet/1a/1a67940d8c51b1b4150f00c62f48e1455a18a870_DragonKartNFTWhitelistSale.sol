/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

interface IERC721Mintable {
    function mint(address to, uint256 boxType) external;
}

contract DragonKartNFTWhitelistSale is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct BatchSaleInfo {
        address recipient;
        address paymentToken;
        uint256 hardCap;
        uint256 price;
        uint256 start;
        uint256 end;
        uint256 releaseTime;
    }

    struct ExtraReward {
        address sponsor;
        IERC20 erc20Token;
        uint256 baseAmount;
        uint256 maxVariableAmount;
    }

    IERC721Mintable public nftManager;
    EnumerableSet.UintSet private _whitelistBatches; // batches
    EnumerableSet.UintSet private _supportedBoxTypes; // supported box types

    mapping(uint256 => uint256[]) private _batchToBoxes; // boxes for sale in batch
    mapping(uint256 => BatchSaleInfo) private _batchSaleInfos; // batch info
    mapping(uint256 => EnumerableSet.AddressSet) private _whitelistAddresses; // whitelist can buy in batch
    mapping(uint256 => EnumerableSet.AddressSet) private _paidAddresses; // paid addresses of batch
    mapping(uint256 => EnumerableSet.AddressSet) private _claimedAddresses; // claimed addresses of batch
    mapping(uint256 => ExtraReward[]) private _extraRewards; // extra erc20 token rewards

    event Claimed(uint256 indexed batchNumber, address indexed buyer);
    event Paid(
        uint256 indexed batchNumber,
        address indexed buyer,
        uint256 price
    );
    event WhitelistAddressAdded(
        uint256 indexed batchNumber,
        address indexed buyer
    );
    event ExtraRewardAdded(
        uint256 indexed batchNumber,
        address indexed sponsor,
        address indexed erc20Token,
        uint256 baseAmount,
        uint256 maxVariableAmount
    );

    constructor(address nftManagerAddress_) {
        require(
            nftManagerAddress_ != address(0),
            "DragonKartNFTWhitelistSale: nftManagerAddress_ is zero address"
        );
        nftManager = IERC721Mintable(nftManagerAddress_);
        _supportedBoxTypes.add(101); // Combo characters, cars, weapons
        _supportedBoxTypes.add(102); // Combo characters, cars
    }

    modifier batchExisted(uint256 batchNumber_) {
        require(_whitelistBatches.contains(batchNumber_));
        _;
    }

    modifier onlyPaidAddress(uint256 batchNumber_, address sender_) {
        require(_paidAddresses[batchNumber_].contains(sender_));
        _;
    }

    modifier onlyClaimable(uint256 batchNumber_, address sender_) {
        require(!_claimedAddresses[batchNumber_].contains(sender_));
        require(block.timestamp >= _batchSaleInfos[batchNumber_].releaseTime);
        _;
    }

    modifier onlySupportedBoxType(uint256 boxType_) {
        require(_supportedBoxTypes.contains(boxType_));
        _;
    }

    function _addWhitelistBatch(
        address recipient_,
        uint256 batchNumber_,
        address paymentToken_,
        uint256 hardCap_,
        uint256 price_,
        uint256 start_,
        uint256 end_,
        uint256 releaseTime_
    ) private {
        require(_whitelistBatches.add(batchNumber_));

        BatchSaleInfo storage _info = _batchSaleInfos[batchNumber_];
        _info.recipient = recipient_;
        _info.paymentToken = paymentToken_;
        _info.hardCap = hardCap_;
        _info.price = price_;
        _info.start = start_;
        _info.end = end_;
        _info.releaseTime = releaseTime_;
    }

    function updateNftManager(address newNftManagerAddress_)
        external
        onlyOwner
    {
        require(
            newNftManagerAddress_ != address(0),
            "DragonKartNFTWhitelistSale: newNftManager_ is zero address"
        );
        nftManager = IERC721Mintable(newNftManagerAddress_);
    }

    function addBoxType(uint256 boxType_) external onlyOwner {
        require(_supportedBoxTypes.add(boxType_));
    }

    function addWhitelistBatch(
        address recipient_,
        uint256 batchNumber_,
        address paymentToken_,
        uint256 hardCap_,
        uint256 price_,
        uint256 start_,
        uint256 end_,
        uint256 releaseTime_
    ) external onlyOwner {
        require(
            recipient_ != address(0),
            "DragonKartNFTWhitelistSale: recipient_ is zero address"
        );
        require(
            batchNumber_ > 0,
            "DragonKartNFTWhitelistSale: batchNumber_ is 0"
        );
        require(
            paymentToken_ != address(0),
            "DragonKartNFTWhitelistSale: paymentToken_ is zero address"
        );
        require(hardCap_ > 0, "DragonKartNFTWhitelistSale: hardCap_ is 0");
        require(price_ > 0, "DragonKartNFTWhitelistSale: price_ is 0");
        require(start_ > 0, "DragonKartNFTWhitelistSale: start_ is 0");
        require(
            releaseTime_ >= start_,
            "DragonKartNFTWhitelistSale: releaseTime_ too soon"
        );

        _addWhitelistBatch(
            recipient_,
            batchNumber_,
            paymentToken_,
            hardCap_,
            price_,
            start_,
            end_,
            releaseTime_
        );
    }

    /**
     * Add boxes to whitelist sales
     * This function must be called after add white list batches
     */
    function addBoxTypeToBatch(uint256 batchNumber_, uint256 boxType_)
        external
        onlyOwner
        batchExisted(batchNumber_)
        onlySupportedBoxType(boxType_)
    {
        _batchToBoxes[batchNumber_].push(boxType_);
    }

    function addWhitelistAddressToBatch(
        uint256 batchNumber_,
        address whitelistAddress_
    ) external onlyOwner batchExisted(batchNumber_) {
        require(
            _whitelistAddresses[batchNumber_].length() + 1 <=
                _batchSaleInfos[batchNumber_].hardCap
        );
        require(_whitelistAddresses[batchNumber_].add(whitelistAddress_));
        emit WhitelistAddressAdded(batchNumber_, whitelistAddress_);
    }

    function addWhitelistAddressesToBatch(
        uint256 batchNumber_,
        address[] memory whitelistAddresses_
    ) external onlyOwner batchExisted(batchNumber_) {
        require(whitelistAddresses_.length > 0);
        require(
            _whitelistAddresses[batchNumber_].length() +
                whitelistAddresses_.length <=
                _batchSaleInfos[batchNumber_].hardCap
        );
        for (
            uint256 _index = 0;
            _index < whitelistAddresses_.length;
            _index++
        ) {
            require(
                _whitelistAddresses[batchNumber_].add(
                    whitelistAddresses_[_index]
                )
            );
            emit WhitelistAddressAdded(
                batchNumber_,
                whitelistAddresses_[_index]
            );
        }
    }

    function addExtraReward(
        uint256 batchNumber_,
        address sponsor_,
        address erc20Token_,
        uint256 baseAmount_,
        uint256 maxVariableAmount_
    ) external onlyOwner batchExisted(batchNumber_) {
        require(
            sponsor_ != address(0),
            "DragonKartNFTWhitelistSale: sponsor_ is zero address"
        );
        require(
            erc20Token_ != address(0),
            "DragonKartNFTWhitelistSale: erc20Token_ is zero address"
        );
        require(
            baseAmount_ + maxVariableAmount_ > 0,
            "DragonKartNFTWhitelistSale: bad args"
        );

        IERC20 _erc20Token = IERC20(erc20Token_);
        require(
            _erc20Token.allowance(sponsor_, address(this)) > 0,
            "DragonKartNFTWhitelistSale: sponsor does not approve yet"
        );

        _extraRewards[batchNumber_].push(
            ExtraReward({
                sponsor: sponsor_,
                erc20Token: IERC20(erc20Token_),
                baseAmount: baseAmount_,
                maxVariableAmount: maxVariableAmount_
            })
        );

        emit ExtraRewardAdded(
            batchNumber_,
            sponsor_,
            erc20Token_,
            baseAmount_,
            maxVariableAmount_
        );
    }

    function buy(uint256 batchNumber_) external batchExisted(batchNumber_) {
        require(
            block.timestamp >= _batchSaleInfos[batchNumber_].start,
            "DragonKartNFTWhitelistSale: The sale is not started"
        );
        require(
            _batchSaleInfos[batchNumber_].end == 0 ||
                block.timestamp < _batchSaleInfos[batchNumber_].end,
            "DragonKartNFTWhitelistSale: The sale is end"
        );
        require(
            _whitelistAddresses[batchNumber_].contains(_msgSender()),
            "DragonKartNFTWhitelistSale: Only whitelisted addresses can buy"
        );
        require(
            !_paidAddresses[batchNumber_].contains(_msgSender()),
            "DragonKartNFTWhitelistSale: Cannot buy one more time"
        );

        require(_paidAddresses[batchNumber_].add(_msgSender()));

        IERC20 _paymentToken = IERC20(
            _batchSaleInfos[batchNumber_].paymentToken
        );
        _paymentToken.safeTransferFrom(
            _msgSender(),
            _batchSaleInfos[batchNumber_].recipient,
            _batchSaleInfos[batchNumber_].price
        );

        emit Paid(
            batchNumber_,
            _msgSender(),
            _batchSaleInfos[batchNumber_].price
        );
    }

    function claimMyNFTs(uint256 batchNumber_)
        external
        batchExisted(batchNumber_)
        onlyPaidAddress(batchNumber_, _msgSender())
        onlyClaimable(batchNumber_, _msgSender())
    {
        uint256[] storage boxes = _batchToBoxes[batchNumber_];
        require(_claimedAddresses[batchNumber_].add(_msgSender()));

        for (uint256 _index = 0; _index < boxes.length; _index++) {
            nftManager.mint(_msgSender(), boxes[_index]);
        }

        ExtraReward[] storage _rewards = _extraRewards[batchNumber_];
        for (uint256 _index = 0; _index < _rewards.length; _index++) {
            ExtraReward storage _reward = _rewards[_index];
            uint256 _rewardAmount;
            if (_reward.maxVariableAmount == 0) {
                _rewardAmount = _reward.baseAmount;
            } else {
                _rewardAmount =
                    _reward.baseAmount +
                    (uint256(
                        keccak256(
                            abi.encodePacked(
                                blockhash(block.number - 1),
                                _msgSender()
                            )
                        )
                    ) % _reward.maxVariableAmount) +
                    1;
            }

            _reward.erc20Token.safeTransferFrom(
                _reward.sponsor,
                _msgSender(),
                _rewardAmount
            );
        }

        emit Claimed(batchNumber_, _msgSender());
    }

    function claimable(uint256 batchNumber_) external view returns (bool) {
        if (
            _whitelistBatches.contains(batchNumber_) &&
            _paidAddresses[batchNumber_].contains(_msgSender()) &&
            !_claimedAddresses[batchNumber_].contains(_msgSender()) &&
            block.timestamp >= _batchSaleInfos[batchNumber_].releaseTime
        ) {
            return true;
        } else {
            return false;
        }
    }

    function updateBatchPrice(uint256 batchNumber_, uint256 price_)
        external
        onlyOwner
        batchExisted(batchNumber_)
    {
        require(price_ > 0, "DragonKartNFTWhitelistSale: price_ is 0");
        BatchSaleInfo storage _info = _batchSaleInfos[batchNumber_];
        require(
            block.timestamp < _info.start,
            "DragonKartNFTWhitelistSale: The sale already started"
        );

        _info.price = price_;
    }

    function updateBatchPaymentMethod(
        uint256 batchNumber_,
        address paymentToken_,
        uint256 price_
    ) external onlyOwner batchExisted(batchNumber_) {
        require(
            paymentToken_ != address(0),
            "DragonKartNFTWhitelistSale: paymentToken_ is zero address"
        );
        require(price_ > 0, "DragonKartNFTWhitelistSale: price_ is 0");
        BatchSaleInfo storage _info = _batchSaleInfos[batchNumber_];
        require(
            block.timestamp < _info.start,
            "DragonKartNFTWhitelistSale: The sale already started"
        );

        _info.paymentToken = paymentToken_;
        _info.price = price_;
    }

    function getBoxesInBatch(uint256 batchNumber_)
        external
        view
        returns (uint256[] memory)
    {
        return _batchToBoxes[batchNumber_];
    }

    function batchSaleInfo(uint256 batchNumber_)
        external
        view
        returns (BatchSaleInfo memory)
    {
        return _batchSaleInfos[batchNumber_];
    }

    function supportedBoxTypes() external view returns (uint256[] memory) {
        return _supportedBoxTypes.values();
    }

    function whitelistBatchCount() external view returns (uint256) {
        return _whitelistBatches.length();
    }

    function contains(uint256 batchNumber_, address whitelistAddress_)
        external
        view
        returns (bool)
    {
        return _whitelistAddresses[batchNumber_].contains(whitelistAddress_);
    }

    function extraRewards(uint256 batchNumber_)
        external
        view
        returns (ExtraReward[] memory)
    {
        return _extraRewards[batchNumber_];
    }
}