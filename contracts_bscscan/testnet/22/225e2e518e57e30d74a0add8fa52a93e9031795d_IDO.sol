/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

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

interface IIDOController {
    event NewIDOCreated(address indexed pool, address creator);

    function isOperator(address) external view returns (bool);

    function getMaxAllocationAmount(address user, uint256 baseAmount) external view returns (uint256);

    function getFeeInfo() external view returns (address, uint256);
}

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract IDO is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct User {
        uint256 totalFunded; // total funded amount of user
        uint256 totalSaleToken; // total sale token amount to receive
        uint256 released; // currently released token amount
    }

    IIDOController public controller;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimTime;

    IERC20 public saleToken;
    uint256 public saleTarget;
    uint256 public saleRaised;

    // 0x0 BNB, other: BEP20
    address public fundToken;
    uint256 public fundTarget;
    uint256 public fundRaised;
    uint256 public totalReleased;

    //
    uint256 public baseAmount; // users' max allocation = baseAmount * feeTier.multiplier
    uint256 public minFundAmount;

    mapping(address => User) public funders;
    address[] public funderAddresses;

    // vesting info
    uint256 public cliffTime;
    // 15 = 1.5%, 1000 = 100%
    uint256 public distributePercentAtClaim;
    uint256 public vestingDuration;
    uint256 public vestingPeriodicity;

    // whitelist
    mapping(address => uint256) public whitelistAmount;

    event IDOInitialized(uint256 saleTarget, address fundToken, uint256 fundTarget);

    event IDOBaseDataChanged(
        uint256 startTime,
        uint256 endTime,
        uint256 claimTime,
        uint256 minFundAmount,
        uint256 baseAmount
    );

    event IDOTokenInfoChanged(uint256 saleTarget, uint256 fundTarget);

    event SaleTokenAddressSet(address saleToken);

    event VestingSet(
        uint256 cliffTime,
        uint256 distributePercentAtClaim,
        uint256 vestingDuration,
        uint256 vestingPeriodicity
    );

    event IDOProgressChanged(address buyer, uint256 amount, uint256 fundRaised, uint256 saleRaised);

    event IDOClaimed(address to, uint256 amount);

    modifier isOperatorOrOwner() {
        require(controller.isOperator(msg.sender) || owner() == msg.sender, "Not owner or operator");

        _;
    }

    modifier isNotStarted() {
        require(startTime > block.timestamp, "Already started");

        _;
    }

    modifier isOngoing() {
        require(startTime <= block.timestamp && block.timestamp <= endTime, "Not onging");

        _;
    }

    modifier isEnded() {
        require(block.timestamp >= endTime, "Not ended");

        _;
    }

    modifier isNotEnded() {
        require(block.timestamp < endTime, "Already ended");

        _;
    }

    modifier isClaimable() {
        require(block.timestamp >= claimTime, "Not claimable");

        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "should be EOA");
        _;
    }

    modifier canRaise(address addr, uint256 amount) {
        uint256 maxAllocation = getMaxAllocation(addr);

        require(amount > 0, "Invalid amount");

        require(fundRaised + amount <= fundTarget, "Target hit!");

        uint256 personalTotal = amount + funders[addr].totalFunded;

        require(personalTotal >= minFundAmount, "Low amount");
        require(personalTotal <= maxAllocation, "Too much amount");

        _;
    }

    /**
     * @notice constructor
     *
     * @param _controller {address} Controller address
     * @param _saleTarget {uint256} Total token amount to sell
     * @param _fundToken {address} Fund token address
     * @param _fundTarget {uint256} Total amount of fund Token
     */
    constructor(
        IIDOController _controller,
        uint256 _saleTarget,
        address _fundToken,
        uint256 _fundTarget
    ) {
        require(address(_controller) != address(0), "Invalid controller");
        require(_saleTarget > 0, "Sale Token target can't be zero!");
        require(_fundTarget > 0, "Fund Token target can't be zero!");

        saleTarget = _saleTarget;

        fundToken = _fundToken;
        fundTarget = _fundTarget;

        controller = _controller;

        emit IDOInitialized(saleTarget, fundToken, fundTarget);
    }

    /**
     * @notice setBaseData
     *
     * @param _startTime {uint256}  timestamp of IDO start time
     * @param _endTime {uint256}  timestamp of IDO end time
     * @param _claimTime {uint256}  timestamp of IDO claim time
     * @param _minFundAmount {uint256}  mimimum fund amount of users
     * @param _baseAmount {uint256}  baseAmount of buy
     */
    function setBaseData(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimTime,
        uint256 _minFundAmount,
        uint256 _baseAmount
    ) external isOperatorOrOwner {
        require(_minFundAmount > 0, "_minFundAmount can't be zero!");
        require(_baseAmount > 0, "_baseAmount can't be zero!");

        require(_startTime > block.timestamp, "You can't set past time!");
        require(_startTime < _endTime, "EndTime can't be earlier than startTime");
        require(_endTime < _claimTime, "ClaimTime can't be earlier than endTime");

        startTime = _startTime;
        endTime = _endTime;
        claimTime = _claimTime;
        minFundAmount = _minFundAmount;
        baseAmount = _baseAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, baseAmount);
    }

    function getMaxAllocation(address addr) public view returns (uint256) {
        uint256 privateAmount = whitelistAmount[addr];
        if (privateAmount > 0) {
            return privateAmount;
        }
        return controller.getMaxAllocationAmount(addr, baseAmount);
    }

    function getFundersCount() external view returns (uint256) {
        return funderAddresses.length;
    }

    function setStartTime(uint256 _startTime) external isOperatorOrOwner isNotStarted {
        require(_startTime > block.timestamp, "You can't set past time!");
        startTime = _startTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, baseAmount);
    }

    function setEndTime(uint256 _endTime) external isOperatorOrOwner isNotEnded {
        require(_endTime > block.timestamp, "You can't set past time!");
        require(_endTime > startTime, "EndTime should be greater than startTime");

        endTime = _endTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, baseAmount);
    }

    function setClaimTime(uint256 _claimTime) external isOperatorOrOwner {
        require(_claimTime > block.timestamp, "You can't set past time!");
        require(_claimTime > endTime, "Claim Time should be greater than endTime");

        claimTime = _claimTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, baseAmount);
    }

    function setBaseAmount(uint256 _baseAmount) external isOperatorOrOwner {
        require(_baseAmount > 0, "Invalid baseAmount");

        baseAmount = _baseAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, baseAmount);
    }

    function setMinFundAmount(uint256 _minFundAmount) external isOperatorOrOwner {
        require(_minFundAmount > 0, "Invalid _minFundAmount");

        minFundAmount = _minFundAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, baseAmount);
    }

    function setSaleToken(IERC20 _saleToken) external isOperatorOrOwner {
        require(address(_saleToken) != address(0), "Invalid SaleToken!");

        saleToken = _saleToken;
        emit SaleTokenAddressSet(address(saleToken));
    }

    function setSaleTarget(uint256 _saleTarget) external isOperatorOrOwner {
        require(_saleTarget > 0, "Sale Token target can't be zero!");
        saleTarget = _saleTarget;
        emit IDOTokenInfoChanged(saleTarget, fundTarget);
    }

    function setFundTarget(uint256 _fundTarget) external isOperatorOrOwner {
        require(_fundTarget > 0, "Fund Token target can't be zero!");
        fundTarget = _fundTarget;
        emit IDOTokenInfoChanged(saleTarget, fundTarget);
    }

    function setVestingInfo(
        uint256 _cliffTime,
        uint256 _distributePercentAtClaim,
        uint256 _vestingDuration,
        uint256 _vestingPeriodicity
    ) external isOperatorOrOwner {
        require(_cliffTime > block.timestamp, "CliffTime should be greater than now");
        require(_distributePercentAtClaim <= 1000, "DistributePcercentAtClaim should be less than 1000");
        require(_vestingDuration > 0, "Vesting Duration should be greater than 0");
        require(_vestingPeriodicity > 0, "Vesting Periodicity should be greater than 0");
        require(
            (_vestingDuration - (_vestingDuration / _vestingPeriodicity) * _vestingPeriodicity) == 0,
            "Vesting Duration should be divided by vestingPeriodicity fully!"
        );

        cliffTime = _cliffTime;
        distributePercentAtClaim = _distributePercentAtClaim;
        vestingDuration = _vestingDuration;
        vestingPeriodicity = _vestingPeriodicity;

        emit VestingSet(cliffTime, distributePercentAtClaim, vestingDuration, vestingPeriodicity);
    }

    function withdrawRemainingSaleToken() external isOperatorOrOwner {
        require(block.timestamp > endTime, "IDO has not yet ended");
        saleToken.safeTransfer(msg.sender, saleToken.balanceOf(address(this)) - saleRaised + totalReleased);
    }

    function withdrawFundedBNB() external isOperatorOrOwner isEnded {
        require(fundToken == address(0), "It's not BNB-buy pool!");

        uint256 balance = address(this).balance;

        (address feeRecipient, uint256 feePercent) = controller.getFeeInfo();

        uint256 fee = (balance * (feePercent)) / (1000);
        uint256 restAmount = balance - (fee);

        (bool success, ) = payable(feeRecipient).call{ value: fee }("");
        require(success, "BNB fee pay failed");
        (bool success1, ) = payable(msg.sender).call{ value: restAmount }("");
        require(success1, "BNB withdraw failed");
    }

    function withdrawFundedToken() external isOperatorOrOwner isEnded {
        require(fundToken != address(0), "It's not token-buy pool!");

        uint256 balance = IERC20(fundToken).balanceOf(address(this));

        (address feeRecipient, uint256 feePercent) = controller.getFeeInfo();

        uint256 fee = (balance * feePercent) / 1000;
        uint256 restAmount = balance - fee;

        IERC20(fundToken).safeTransfer(feeRecipient, fee);
        IERC20(fundToken).safeTransfer(msg.sender, restAmount);
    }

    function getClaimableAmount(address addr) public view returns (uint256) {
        require(addr != address(0), "Invalid address!");

        if (block.timestamp < claimTime) return 0;

        uint256 distributeAmountAtClaim = (funders[addr].totalSaleToken * distributePercentAtClaim) / 1000;
        uint256 prevReleased = funders[addr].released;
        if (cliffTime > block.timestamp) {
            return distributeAmountAtClaim - prevReleased;
        }

        if (cliffTime == 0) {
            // vesting info is not set yet
            return 0;
        }

        uint256 finalTime = cliffTime + vestingDuration - vestingPeriodicity;

        if (block.timestamp >= finalTime) {
            return funders[addr].totalSaleToken - prevReleased;
        }

        uint256 lockedAmount = funders[addr].totalSaleToken - distributeAmountAtClaim;

        uint256 totalPeridicities = vestingDuration / vestingPeriodicity;
        uint256 periodicityAmount = lockedAmount / totalPeridicities;
        uint256 currentperiodicityCount = (block.timestamp - cliffTime) / vestingPeriodicity + 1;
        uint256 availableAmount = periodicityAmount * currentperiodicityCount;

        return distributeAmountAtClaim + availableAmount - prevReleased;
    }

    function _claimTo(address to) private onlyEOA {
        require(to != address(0), "Invalid address");
        uint256 claimableAmount = getClaimableAmount(to);
        if (claimableAmount > 0) {
            funders[to].released = funders[to].released + claimableAmount;
            saleToken.safeTransfer(to, claimableAmount);
            totalReleased = totalReleased + claimableAmount;
            emit IDOClaimed(to, claimableAmount);
        }
    }

    function claim() external nonReentrant onlyEOA {
        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "Nothing to claim");
        _claimTo(msg.sender);
    }

    function batchClaim(address[] calldata addrs) external isClaimable nonReentrant {
        for (uint256 index = 0; index < addrs.length; index++) {
            _claimTo(addrs[index]);
        }
    }

    function buyWithBNB() public payable isOngoing canRaise(msg.sender, msg.value) onlyEOA {

        uint256 amount = msg.value;
        uint256 saleTokenAmount = (msg.value * saleTarget) / fundTarget;

        fundRaised = fundRaised + amount;
        saleRaised = saleRaised + saleTokenAmount;

        if (funders[msg.sender].totalFunded == 0) {
            funderAddresses.push(msg.sender);
        }

        funders[msg.sender].totalFunded = funders[msg.sender].totalFunded + amount;
        funders[msg.sender].totalSaleToken = funders[msg.sender].totalSaleToken + saleTokenAmount;

        _claimTo(msg.sender);
        
        emit IDOProgressChanged(msg.sender, amount, fundRaised, saleRaised);
    }

    function buy(uint256 amount) public isOngoing canRaise(msg.sender, amount) onlyEOA {
        require(fundToken != address(0), "It's not token-buy pool!");

        uint256 saleTokenAmount = (amount * saleTarget) / fundTarget;
        fundRaised = fundRaised + amount;
        saleRaised = saleRaised + saleTokenAmount;

        if (funders[msg.sender].totalFunded == 0) {
            funderAddresses.push(msg.sender);
        }

        funders[msg.sender].totalFunded = funders[msg.sender].totalFunded + amount;
        funders[msg.sender].totalSaleToken = funders[msg.sender].totalSaleToken + saleTokenAmount;

        IERC20(fundToken).safeTransferFrom(msg.sender, address(this), amount);

        emit IDOProgressChanged(msg.sender, amount, fundRaised, saleRaised);
    }

    function setWhitelist(address[] calldata addrs, uint256[] calldata amounts) external isOperatorOrOwner {
        require(addrs.length == amounts.length, "Invalid params");

        for (uint256 index = 0; index < addrs.length; index++) {
            whitelistAmount[addrs[index]] = amounts[index];
        }
    }

    receive() external payable {
        revert("Something went wrong!");
    }
}