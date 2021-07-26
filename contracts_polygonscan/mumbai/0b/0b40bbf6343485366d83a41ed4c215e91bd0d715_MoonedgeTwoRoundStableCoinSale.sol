/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

// SPDX-License-Identifier: Unlicensed

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

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TokenVestingInfo {
    using EnumerableSet for EnumerableSet.UintSet;

    event OperationResult(bool result);

    EnumerableSet.UintSet private _set;
    
    constructor(
        uint256 id_,
        uint256 delay_,
        uint256 percentage_
    ) {
        add(id_);
        add(delay_);
        add(percentage_);
    }

    function getId() public view returns (uint) {
        return at(0);
    }

    function getDelay() public view returns (uint) {
        return at(1);
    }

    function getPercentage() public view returns (uint) {
        return at(2);
    }

    function contains(uint256 value) public view returns (bool) {
        return _set.contains(value);
    }

    function add(uint256 value) public {
        bool result = _set.add(value);
        emit OperationResult(result);
    }

    function remove(uint256 value) public {
        bool result = _set.remove(value);
        emit OperationResult(result);
    }

    function length() public view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) public view returns (uint256) {
        return _set.at(index);
    }
}


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


pragma solidity ^0.8.0;

//import "../utils/Context.sol";

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

    constructor() {
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


pragma solidity ^0.8.0;

//import "../IERC20.sol";
//import "../../../utils/Address.sol";

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


pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TokenEscrow is Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    mapping (address => mapping (address => uint256)) private _tokenBalanceOf;
    mapping (address => mapping (address => uint256)) private _initialtokenBalanceOf;

    event TokenDeposited(IERC20 token, address indexed from, uint256 value);
    event TokenWithdrawn(IERC20 token, address indexed to, uint256 value);

    /**
    * @dev Return the total token balance of beneficiary
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposited
    */
    function tokenBalanceOf(IERC20 token, address beneficiary) public view virtual returns (uint256) {
        return _tokenBalanceOf[address(token)][beneficiary];
    }

    /**
    * @dev Return the total token balance of beneficiary but it won't change after withdraw
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposited
    */
    function initialtokenBalanceOf(IERC20 token, address beneficiary) public view virtual returns (uint256) {
        return _initialtokenBalanceOf[address(token)][beneficiary];
    }

    /**
    * @dev Faalback Redeem tokens. The ability to redeem token whe okenst are accidentally sent to the contract
    * @param token Address of the IERC20 token
    * @param to address Recipient of the recovered tokens
    * @param amount Number of tokens to be emitted
    */
    function fallbackRedeem(IERC20 token,  address to, uint256 amount) external {
        _prevalidateFallbackRedeem(token, to, amount);

        _updateFallbackRedeem(token, to, amount);
        
        _processTokenWithdraw(token, to, amount);
        emit TokenWithdrawn(token, to, amount);

        _postValidateFallbackRedeem(token, to, amount);
    }

    /** 
    * @dev Stores the sent amount as credit to be withdrawn.
    * @param token The token address of IERC20 token
    * @param payee The destination address of the funds.
    * @param amount amount of tokens deposit
    */
    function _tokenDeposit(IERC20 token, address payee, uint256 amount) internal virtual {         
        _preValidateTokenDeposit(token, payee, amount);

        _processTokenDeposit(token, payee, amount);
        emit TokenDeposited(token, payee, amount);

        _updateDepositingState(token, payee, amount);
        _postValidateDeposit(token, payee, amount);
    }

    /** 
    * @dev Withdraw amount of token that has beed deposited.
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposited
    * @param amount amount of tokens deposit
    */
    function _tokenWithdraw(IERC20 token, address beneficiary, uint256 amount) internal virtual nonReentrant {
        _preValidateTokenWithdraw(token, beneficiary, amount);

        _updateWithdrawingState(token, msg.sender, amount);    

        _processTokenWithdraw(token, beneficiary, amount);

        emit TokenWithdrawn(token, beneficiary, amount);
        
        _postValidateWithdraw(token, beneficiary, amount);
    }

    /**
    * @dev Validation of an fallback redeem. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from TokenEscrow to extend their validations.
    * Example from TokenEscrow.sol's _prevalidateFallbackRedeem method:
    *     super._prevalidateFallbackRedeem(token, payee, amount);
    *    
    * @param token The token address of IERC20 token
    * @param amount Number of tokens deposit
    * @param to Address performing the token deposit
    *
    * Requirements:
    *
    * - `msg.sender` must be owner.
    * - `token` cannot be the zero address.
    * - `to` cannot be the zero address.
    * - this address must have a token balance of at least `amount`.
    */
    function _prevalidateFallbackRedeem(IERC20 token,  address to, uint256 amount) internal virtual onlyOwner view {
        require(address(token) != address(0), "TokenEscrow: token is the zero address");
        require(to != address(0), "TokenEscrow: cannot recover to zero address");
        require(amount != 0, "TokenEscrow: amount is 0");
        require(token.balanceOf((address(this))) >= amount, "TokenEscrow: withdraw amount exceeds avaiable balance");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Validation of an incoming deposit. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from TokenEscrow to extend their validations.
    * Example from VestingTokenEscrow.sol's _preValidatePurchase method:
    *     super._preValidatePurchase(token, payee, amount);
    *    
    * @param token The token address of IERC20 token
    * @param payee Address performing the token deposit
    * @param amount Number of tokens deposit
    *
    * Requirements:
    *
    * - `token` cannot be the zero address.
    * - `payee` cannot be the zero address.
    * - `amount` cannot be 0.
    * - the caller must have a token balance of at least `amount`.
    */
    function _preValidateTokenDeposit(IERC20 token, address payee, uint256 amount) internal virtual view {
        require(address(token) != address(0), "TokenEscrow: token is the zero address");  
        require(payee != address(0), "TokenEscrow: payee is the zero address");
        require(amount != 0, "TokenEscrow: amount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Validation of an outgoing withdraw. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from TokenEscrow to extend their validations.
    * Example from VestingTokenEscrow.sol's _preValidatePurchase method:
    *     super._preValidatetokenWithdraw(token, beneficiary, amount);
    *     
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposit
    * @param amount Number of tokens deposit
    *
    * Requirements:
    *
    * - `token` cannot be the zero address.
    * - `beneficiary` cannot be the zero address.
    * - `amount` cannot be 0.
    * - this contract have a token balance of at least `amount`.
    * - the caller must have a token balance of at least `amount`.
    */
    function _preValidateTokenWithdraw(IERC20 token, address beneficiary, uint256 amount) internal virtual view {
        require(address(token) != address(0), "TokenEscrow: token is the zero address");  
        require(beneficiary != address(0), "TokenEscrow: beneficiary is the zero address");
        require(amount != 0, "TokenEscrow: amount is 0");
        require(token.balanceOf((address(this))) >= amount, "TokenEscrow: withdraw amount exceeds avaiable balance");
        require(tokenBalanceOf(token, msg.sender) >= amount, "TokenEscrow: withdraw amount exceeds balance of token sender");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Executed when a deposit has been validated and is ready to be executed. Doesn't necessarily emit/send
    * tokens.
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposit
    * @param amount Number of tokens deposit
    */
    function _processTokenDeposit(IERC20 token,address beneficiary, uint256 amount) internal virtual {
        _depositTokens(token, beneficiary, amount);
    }

    /**
    * @dev Executed when a withdraw has been validated and is ready to be executed. Doesn't necessarily emit/send
    * tokens.
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposit
    * @param amount Number of tokens deposit
    */
    function _processTokenWithdraw(IERC20 token,address beneficiary, uint256 amount) internal virtual {
        _deliverTokens(token, beneficiary, amount);
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the tokenvesting ultimately deposit
    * its tokens.
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _depositTokens(IERC20 token, address beneficiary, uint256 tokenAmount) internal virtual {
        require(IERC20(token).transferFrom(beneficiary, address(this), tokenAmount));
    }

    /**
    * @dev Override for extensions that require an internal state to check for validity fallback redeem,
    * etc.)
    * @param token The token address of IERC20 token
    * @param to Address performing the token withdraw
    * @param amount Number of tokens deposit
    */
    function _updateFallbackRedeem(IERC20 token,address to, uint256 amount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
    
    /**
    * @dev Override for extensions that require an internal state to check for validity (current user contributions,
    * etc.)
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposit
    * @param amount Number of tokens deposit
    */
    function _updateDepositingState(IERC20 token,address beneficiary, uint256 amount) internal virtual {
        _tokenBalanceOf[address(token)][beneficiary] += amount;
        _initialtokenBalanceOf[address(token)][beneficiary] += amount;
    }

    /**
    * @dev Override for extensions that require an internal state to check for validity (current user contributions,
    * etc.)
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token withdraw
    * @param amount Number of tokens deposit
    */
    function _updateWithdrawingState(IERC20 token,address beneficiary, uint256 amount) internal virtual {
        _tokenBalanceOf[address(token)][beneficiary] -= amount;
    }

    /**
    * @dev Validation of an executed fallback redeem. Observe state and use revert statements to undo rollback when valid
    * conditions are not met.
    * @param token The token address of IERC20 token
    * @param to Address performing the token deposit
    * @param amount Number of tokens deposit
    */
    function _postValidateFallbackRedeem(IERC20 token, address to, uint256 amount) internal virtual view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
    * @dev Validation of an executed deposit. Observe state and use revert statements to undo rollback when valid
    * conditions are not met.
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposit
    * @param amount Number of tokens deposit
    */
    function _postValidateDeposit(IERC20 token, address beneficiary, uint256 amount) internal virtual view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
    * @dev Validation of an executed withdraw. Observe state and use revert statements to undo rollback when valid
    * conditions are not met.
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token deposit
    * @param amount Number of tokens deposit
    */
    function _postValidateWithdraw(IERC20 token, address beneficiary, uint256 amount) internal virtual view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the tokenescrow ultimately gets and sends
    * its tokens.
    * @param token The token address of IERC20 token
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(IERC20 token, address beneficiary, uint256 tokenAmount) internal virtual {
        token.safeTransfer(beneficiary, tokenAmount);
    }
}


pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


pragma solidity ^0.8.0;

//import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//import "../escrow/TokenEscrow.sol";
//import "./TokenVestingInfo.sol";

/**
 * @title TokenVesting
 * @dev TokenVesting is a base contract for managing a token vesting,
 */
contract TokenVesting is TokenEscrow {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // Address of the ERC20 token
    IERC20 private _token;

    // Counter of vesting rules
    uint256 private _vestingId = 0;
    uint256 private _totalPercentage = 0;

    // Map to track vesting claims
    mapping (address => mapping (uint256 => bool)) private _vestingStatus;

    EnumerableMap.UintToAddressMap private _vestings;

    event VestingAdded(uint256 vestingId_, address tokenVestingInfo);

    constructor(IERC20 token) {
        require(address(token) != address(0), "TokenVesting: token is a zero address");
        _token = token;
    }

    function claim(uint256 vestingId_, IERC20 token, address beneficiary) external returns(bool) {
        _preClaim(msg.sender, vestingId_);

        _updateClaim(beneficiary, vestingId_, token);

        _processClaim(beneficiary, vestingId_, token);

        _postClaim(beneficiary, vestingId_, token);

        return true;
    }

    /**
    * @return The totalPercentage
    */
    function totalPercentage() public view returns (uint256) {
        return _totalPercentage;
    }

    /**
    * @return The tokenVestingInfo address. 
    */
    function vestings(uint256 vestingId_) public view returns (address) {
        return _vestings.get(vestingId_);
    }

    /**
    * @return The token address. 
    */
    function getToken() public view returns (IERC20) {
        return _token;
    }

    function getTokenVestingInfoById(uint256 vestingId_) public view returns (TokenVestingInfo) {
        require(_vestings.contains(vestingId_), "TokenVesting: vestingId not found");
        return TokenVestingInfo(_vestings.get(vestingId_));
    }

    function getVestingTimeById(uint256 vestingId_) public view returns (uint256) {
        require(_vestings.contains(vestingId_), "TokenVesting: vestingId not found");
        return getTokenVestingInfoById(vestingId_).at(1);
    }

    function getVestingPercentageById(uint256 vestingId_) public view returns (uint256) {
        require(_vestings.contains(vestingId_), "TokenVesting: vestingId not found");
        return getTokenVestingInfoById(vestingId_).at(2);
    }

    function getVestingStatus(address beneficiary, uint256 vestingId_) public view returns (bool) {
        return _vestingStatus[beneficiary][vestingId_];
    }

    /**
     * @return The current vestingId count. 
     */
    function currentVestingId() public view returns (uint256) {
        return _vestingId;
    }
    
    /**
    * @dev Adds new vesting rule.
    * @param delay The delay after the listing time
    * @param percentage The percentage of the rule
    */
    function _addVesting(uint256 vestingId_, uint256 delay, uint256 percentage) internal virtual {
        _preAddingVesting(vestingId_, delay, percentage);

        _totalPercentage += percentage;
        require(totalPercentage() <= 1000, "TokenVesting: totalPercentage is greater than 100");

        TokenVestingInfo tokenVestingInfo = new TokenVestingInfo(vestingId_, delay, percentage);

        _processAddingVesting(vestingId_, tokenVestingInfo); 
        emit VestingAdded(vestingId_, address(tokenVestingInfo));

        _updateAddingVesting(vestingId_, delay, percentage);
        _postAddingVesting(vestingId_, delay, percentage);
    }

    /**
    * @dev Validation of adding. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from Crowdsale to extend their validations.
    * Example from CappedCrowdsale.sol's _preValidatePurchase method:
    *     super._preAddingVesting(vestingId_, delay, percentage);
    * @param vestingId_ Address performing the token purchase
    * @param delay openingtime of the claim
    * @param percentage percentage of the claim
    *
    * Requirements:
    *
    * - `vestingId_` must exist.
    * - `delay` time cannot be 0 .
    * - `percentage` time cannot be 0 
    * - max `percentage` is 100 .
    */
    function _preAddingVesting(uint256 vestingId_, uint256 delay, uint256 percentage) internal virtual view {
        require(!_vestings.contains(vestingId_), "TokenVesting: adding existing vestingId");
        require(delay != 0, "TokenVesting: delay is 0");
        require(percentage != 0, "TokenVesting: percentage is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Validation of claim. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from Crowdsale to extend their validations.
    * Example from CappedCrowdsale.sol's _preValidatePurchase method:
    *     super._preClaim(vestingId_, delay, percentage);
    * @param vestingId_ Address performing the token purchase
    * Requirements:
    *
    * - `vestingId_` must exist.
    * - getVestingTimeById `vestingId_` must in open time.
    * - _vestingStatus `vestingId_` must be false (not claimed).
    */
    function _preClaim(address beneficiary, uint256 vestingId_) internal virtual view {
        require(_vestings.contains(vestingId_), "TokenVesting: not existing vestingId");
        require(getVestingTimeById(vestingId_) < block.timestamp, "TokenVesting: not open for claim");
        require(getVestingStatus(beneficiary, vestingId_) == false, "TokenVesting: already claimed");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _processAddingVesting(uint256 vestingId_, TokenVestingInfo tokenVestingInfo) internal virtual {
        _vestings.set(vestingId_, address(tokenVestingInfo));
        _vestingId += 1; 
    }

    function _processClaim(address beneficiary, uint256 vestingId_, IERC20 token) internal virtual {
        uint256 percentage = getVestingPercentageById(vestingId_);
        uint256 amount = initialtokenBalanceOf(token, msg.sender);
        uint256 newAmount = amount * percentage / 1000;
        _vestingStatus[msg.sender][vestingId_] = true;
        super._tokenWithdraw(token, beneficiary, newAmount);
    }

    function _updateAddingVesting(uint256 vestingId_, uint256 delay, uint256 percentage) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _updateClaim( address beneficiary, uint256 vestingId_, IERC20 token) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _postAddingVesting(uint256 vestingId_, uint256 delay, uint256 percentage) internal virtual view {
        // solhint-disable-previous-line no-empty-blocks
    } 

    function _postClaim( address beneficiary, uint256 vestingId_, IERC20 token) internal virtual view {
        // solhint-disable-previous-line no-empty-blocks
    }
}

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/Context.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title CrowdsaleStableCoin
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with stable coin. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract CrowdsaleStableCoin is Context, ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for IERC20;
    
    // The token being sold
    IERC20 private _token;
    IERC20 private _stableCoin;
  
    // Address where funds are collected
    address private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
    * Event for token swap logging
    * @param purchaser who swap for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for swapped
    * @param amount amount of tokens swapped
    */
    event TokensSwapped(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * Event emitted when assets are deposited
    * @param purchaser who deposit for the stablecoin
    * @param to where deposit forward to
    * @param stablecoin IERC20 stablecoin deposited
    * @param amount amount of tokens deposited
    */
    event Deposited(
      address indexed purchaser,
      address indexed to,
      IERC20 stablecoin,
      uint256 amount
    );

    /**
    * @dev The rate is the conversion between wei and the smallest and indivisible
    * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
    * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
    * @param wallet_ Address where collected funds will be forwarded to
    * @param token_ Address of the token being swap
    * @param stableCoin_ Address of the stablecoin being swap
    *
    * Requirements:
    *
    * - `rate_` , `wallet_` and `token_` cannot be the zero address.
    *
    */
    constructor (address wallet_, IERC20 token_, IERC20 stableCoin_) {
        require(wallet_ != address(0), "CrowdsaleStableCoin: wallet is the zero address");
        require(address(token_) != address(0), "CrowdsaleStableCoin: token is the zero address");
        require(address(stableCoin_) != address(0), "CrowdsaleStableCoin: stablecoin is the zero address");

        _wallet = wallet_;
        _token = token_;
        _stableCoin = stableCoin_;
    }

    // This function is called for all messages sent to
    // this contract, except plain Ether transfers
    // (there is no other function except the receive function).
    // Any call with non-empty calldata to this contract will execute
    // the fallback function (even if Ether is sent along with the call).
    fallback() external payable {
        revert();
    }

    // This function is called for plain Ether transfers, i.e. 
    // for every call with empty calldata.
    receive() external payable { 
        revert();
    }

    /**
    * @return the token being sold.
    */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
    * @return the stableCoin being swap.
    */
    function stableCoin() public view returns (IERC20) {
        return _stableCoin;
    }

    /**
    * @return the address where funds are collected.
    */
    function wallet() public view returns (address) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * This function has a non-reentrancy guard, so it shouldn't be called by
    * another `nonReentrant` function.
    * @param beneficiary Recipient of the token purchase
    * @param amount amount of the stable coin swap
    */
    function swapTokens(address beneficiary, uint256 amount) public nonReentrant {
        address operator = _msgSender();

        _preValidateSwapTokens(beneficiary, amount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(amount);

        // update state
        _weiRaised += amount;
        _receiveTokens(operator, amount);
        emit Deposited(operator, wallet(), stableCoin(), amount);
        
        _processSwapTokens(beneficiary, tokens);
        emit TokensSwapped(_msgSender(), beneficiary, amount, tokens);

        _updateSwapTokensState(beneficiary, amount);
        _postValidateSwapTokens(beneficiary, amount);
    }

     /**
    * @dev set the stableCoin being swap.
    */
    function _setRate(uint256 rate_) internal {
        require(rate_ > 0, "CrowdsaleStableCoin: rate is 0");
        _rate = rate_;
    }

    /**
    * @dev Validation of an incoming swap. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from Crowdsale to extend their validations.
    * @param beneficiary Address performing the token purchase
    * @param weiAmount Value in weiinvolved in the purchase
    *
    * Requirements:
    *
    * - `beneficiary` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function _preValidateSwapTokens(address beneficiary, uint256 weiAmount) internal virtual view {
        require(beneficiary != address(0), "CrowdsaleStableCoin: beneficiary is the zero address");
        require(weiAmount != 0, "CrowdsaleStableCoin: amount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
    * conditions are not met.
    * @param beneficiary Address performing the token purchase
    * @param weiAmount Value in wei involved in the purchase
    */
    function _postValidateSwapTokens(address beneficiary, uint256 weiAmount) internal virtual view {
        // solhint-disable-previous-line no-empty-blocks
    }
      
    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
    * its tokens.
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _sendTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        require(_token.transfer(beneficiary, tokenAmount));
    }

    /**
    * @dev SafeTransferFrom beneficiary. Override this method to modify the way in which the crowdsale ultimately gets and sends
    * its tokens.
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _receiveTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        _stableCoin.safeTransferFrom(beneficiary, wallet(), tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
    * tokens.
    * @param beneficiary Address receiving the tokens
    * @param tokenAmount Number of tokens to be purchased
    */
    function _processSwapTokens(address beneficiary, uint256 tokenAmount) internal {
        _sendTokens(beneficiary, tokenAmount);
    }

    /**
    * @dev Override for extensions that require an internal state to check for validity (current user contributions,
    * etc.)
    * @param beneficiary Address receiving the tokens
    * @param amount Value in wei involved in the swap
    */
    function _updateSwapTokensState(address beneficiary, uint256 amount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be swapped with the specified _weiAmount
    */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * _rate;
    }
}



pragma solidity ^0.8.0;

//import "./CrowdsaleStableCoin.sol";

/**
 * @title TimedCappedCrowdsaleStableCoin
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCappedCrowdsaleStableCoin is CrowdsaleStableCoin {
    uint256 private _openingTime;
    uint256 private _closingTime;

    uint256 private _cap;

    /**
      * Event for crowdsale extending
      * @param newClosingTime new closing time
      * @param prevClosingTime old closing time
      */
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
    * @dev Reverts if not in crowdsale time range.
    */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCappedCrowdsaleStableCoin: not open");
        _;
    }

    /**
    * @dev Reverts if not in crowdsale time range.
    */
    modifier onlyWhileClose {
        require(!isOpen(), "TimedCappedCrowdsaleStableCoin: not close");
        _;
    }

    /**
    * @dev Constructor, takes crowdsale opening and closing times.
    * @param openingTime_ Crowdsale opening time
    * @param closingTime_ Crowdsale closing time
    * @param cap_ Max amount of wei to be contributed
    *
    * Requirements:
    *
    * - `openingTime_` cannot before current time.
    * - `closingTime_` cannot before openingTime_ time.
    * - `cap_` cannot be zero .
    *
    */
    constructor (uint256 openingTime_, uint256 closingTime_, uint256 cap_) {
        // solhint-disable-next-line not-rely-on-time
        require(openingTime_ >= block.timestamp, "TimedCappedCrowdsaleStableCoin: opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(closingTime_ > openingTime_, "TimedCappedCrowdsaleStableCoin: closing time is before opening time");
        require(cap_ > 0, "TimedCappedCrowdsaleStableCoin: cap is 0");

        _openingTime = openingTime_;
        _closingTime = closingTime_;
        _cap = cap_;
    }

    /**
    * @dev Sets a total maximum contributions.
    * @param cap_ Wei limit for individual contribution
    */
    function changeCap(uint256 cap_) external {
        _preValidateChangeCap(cap_);
        _cap = cap_;
    }

    /**
    * @return the cap of the crowdsale.
    */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
    * @dev Checks whether the cap has been reached.
    * @return Whether the cap was reached
    */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    /**
    * @return the crowdsale opening time.
    */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
    * @return the crowdsale closing time.
    */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
    * @return true if the crowdsale is open, false otherwise.
    */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed.
    * @return Whether crowdsale period has elapsed
    */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    function _preValidateChangeCap(uint256 cap_) internal virtual view {
        require(cap_ > 0, "TimedCappedCrowdsaleStableCoin: cap is 0");
        require(cap() != cap_, "TimedCappedCrowdsaleStableCoin: cap has same value");
        this;
    }

    /**
    * @dev Extend parent behavior requiring to be within contributing period.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
      */
      function _preValidateSwapTokens(address beneficiary, uint256 weiAmount) internal override virtual view {
          super._preValidateSwapTokens(beneficiary, weiAmount);
          require(weiRaised() + weiAmount <= _cap, "TimedCappedCrowdsaleStableCoin: cap exceeded");
          this;
      }

    /**
    * @dev Extend crowdsale.
    * @param newClosingTime Crowdsale closing time
    *
    * Requirements:
    *
    * - `newClosingTime` cannot before closingTime.
    *  
    */
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCappedCrowdsaleStableCoin: already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "TimedCappedCrowdsaleStableCoin: new closing time is before current closing time");
        
        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}


pragma solidity ^0.8.0;

//import "./TimedCappedCrowdsaleStableCoin.sol";

/**
 * @title TwoRoundsCrowdsaleStableCoin
 * @dev Two rounds Crowdsale accepting contributions only within a time frame.
 */
abstract contract TwoRoundsCrowdsaleStableCoin is TimedCappedCrowdsaleStableCoin {
    uint256 private _openingTimeRoundTwo;
    uint256 private _closingTimeRoundTwo;

    /**
    * @dev Reverts if not in crowdsale time range.
    */
    modifier onlyWhileOpenRoundTwo {
        require(isOpenForRoundTwo(), "TwoRoundsCrowdsaleStableCoin: not open");
        _;
    }

    /**
    * @dev Constructor, takes crowdsale opening and closing times.
    * @param openingTimeRoundTwo_ Crowdsale opening time round 2
    * @param closingTimeRoundTwo_ Crowdsale closing time round 2
    *
    * Requirements:
    *
    * - `openingTimeRound2_` cannot before current time.
    * - `closingTimeRound2_` cannot before openingTime_ time.
    *
    */
    constructor (uint256 openingTimeRoundTwo_, uint256 closingTimeRoundTwo_) {
        // solhint-disable-next-line not-rely-on-time
        require(openingTimeRoundTwo_ >= block.timestamp, "TwoRoundsCrowdsaleStableCoin: opening time is before current time");
        // solhint-disable-next-line not-rely-on-time
        require(openingTimeRoundTwo_ >= super.closingTime(), "TwoRoundsCrowdsaleStableCoin: opening time is before closing time");
        // solhint-disable-next-line max-line-length
        require(closingTimeRoundTwo_ > openingTimeRoundTwo_, "TwoRoundsCrowdsaleStableCoin: closing time is before opening time");

        _openingTimeRoundTwo = openingTimeRoundTwo_;
        _closingTimeRoundTwo = closingTimeRoundTwo_;
    }

    /**
    * @return the crowdsale opening time.
    */
    function openingTimeRoundTwo() public view returns (uint256) {
        return _openingTimeRoundTwo;
    }

    /**
    * @return the crowdsale closing time.
    */
    function closingTimeRoundTwo() public view returns (uint256) {
        return _closingTimeRoundTwo;
    }

    /**
    * @return true if the crowdsale is open, false otherwise.
    */
    function isOpenForRoundTwo() public view returns (bool) {
        if (hasClosed()) { //round one must be closed
            // solhint-disable-next-line not-rely-on-time
            return block.timestamp >= _openingTimeRoundTwo && block.timestamp <= _closingTimeRoundTwo;
        } else {
            return false;
        }
    }

    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed.
    * @return Whether crowdsale period has elapsed
    */
    function hasClosedRoundTwo() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTimeRoundTwo;
    }

    /**
    * @dev Extend parent behavior requiring to be within contributing period.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _preValidateSwapTokens(address beneficiary, uint256 weiAmount) internal override virtual view {
        if (isOpen()) {
            _preValidateSwapTokensRoundOne(beneficiary, weiAmount);
        } else if (isOpenForRoundTwo()) { 
            _preValidateSwapTokensRoundTwo(beneficiary, weiAmount);
        } else {
            revert("TwoRoundsCrowdsaleStableCoin: not open");
        }
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _preValidateSwapTokensRoundOne(address beneficiary, uint256 weiAmount) internal virtual onlyWhileOpen view {
        super._preValidateSwapTokens(beneficiary, weiAmount);
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _preValidateSwapTokensRoundTwo(address beneficiary, uint256 weiAmount) internal virtual onlyWhileOpenRoundTwo view {
        super._preValidateSwapTokens(beneficiary, weiAmount);
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Extend crowdsale.
    * @param newClosingTime Crowdsale closing time
    *
    * Requirements:
    *
    * - `newClosingTime` cannot before closingTime.
    *  
    */
    function _extendTimeRoundTwo(uint256 newClosingTime) internal {
        require(!hasClosedRoundTwo(), "TwoRoundsCrowdsaleStableCoin: still open");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTimeRoundTwo, "TwoRoundsCrowdsaleStableCoin: new closing time is before current closing time");
        
        emit TimedCrowdsaleExtended(_closingTimeRoundTwo, newClosingTime);
        _closingTimeRoundTwo = newClosingTime;
    }
}



pragma solidity ^0.8.0;

//import "./TwoRoundsCrowdsaleStableCoin.sol";

/**
 * @title IndividuallyCappedTwoRoundTimeCrowdsaleStableCoins
 * @dev TimeCrowdsale with per-beneficiary caps.
 */
abstract contract IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin is TwoRoundsCrowdsaleStableCoin {
    uint256 private _totalContributions = 0;
    uint256 private _participationCount = 0;

    mapping(address => uint256) private _contributionsFirstRound;
    mapping(address => uint256) private _contributionsSecondRound;
    mapping(address => uint256) private _caps;
    mapping(address => uint256) private _roundtwoCaps;

    /**
    * @dev Returns the cap of a specific beneficiary.
    * @param beneficiary Address whose cap is to be checked
    * @return Current cap for individual beneficiary
    */
    function getCap(address beneficiary) public view returns (uint256) {
        return _caps[beneficiary];
    }

    /**
    * @dev Returns the second round cap of a specific beneficiary.
    * @param beneficiary Address whose cap is to be checked
    * @return Current round two cap for individual beneficiary
    */
    function getCapSecondRound(address beneficiary) public view returns (uint256) {
        return _roundtwoCaps[beneficiary];
    }

    /**
    * @dev Returns the amount contributed on first round so far by a specific beneficiary.
    * @param beneficiary Address of contributor
    * @return Beneficiary contribution so far
    */
    function getContributionsFirstRound(address beneficiary) public view returns (uint256) {
        return _contributionsFirstRound[beneficiary];
    }

    /**
    * @dev Returns the amount contributed on second round so far by a specific beneficiary.
    * @param beneficiary Address of contributor
    * @return Beneficiary contribution so far
    */
    function getContributionsSecondRound(address beneficiary) public view returns (uint256) {
        return _contributionsSecondRound[beneficiary];
    }

    /**
    * @dev Returns the amount of total contributed of beneficiary so far.
    * @return total contribution for each beneficiary so far
    */
    function getTotalContributionsOf(address beneficiary) public view returns (uint256) {
        return getContributionsFirstRound(beneficiary) + getContributionsSecondRound(beneficiary);
    }

    /**
    * @dev Returns the amount of total contributed so far.
    * @return total contribution so far
    */
    function getTotalContributions() public view returns (uint256) {
        return _totalContributions;
    }

    /**
    * @dev Returns the count total contributor so far.
    * @return total contribution so far
    */
    function participationCount() public view returns (uint256) {
        return _participationCount;
    }

    /**
    * @dev Sets a specific beneficiary's maximum contribution.
    * @param beneficiary Address to be capped
    * @param cap_ Wei limit for individual contribution
    * @param percentage percentage of the second round
    */
    function _setCap(address beneficiary, uint256 cap_, uint256 percentage) internal virtual  {
        _caps[beneficiary] = cap_;
        _roundtwoCaps[beneficiary] = cap_ * percentage / 1000; //Second round cap is % of the round one cap
    }

    /**
    * @dev Extend parent behavior requiring to be within contributing period.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _preValidateSwapTokens(address beneficiary, uint256 weiAmount) internal override virtual view {
        if (isOpen()) {
          _preValidateSwapTokensRoundOne(beneficiary, weiAmount);
        } else if (isOpenForRoundTwo()) { 
          _preValidateSwapTokensRoundTwo(beneficiary, weiAmount);
        } else {
          revert("IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin: not open");
        }
    }  

    /**
    * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _preValidateSwapTokensRoundOne(address beneficiary, uint256 weiAmount) internal virtual override view {
        super._preValidateSwapTokensRoundOne(beneficiary, weiAmount);
        require(_caps[beneficiary] != 0, "IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin: beneficiary's cap is not set");
        // solhint-disable-next-line max-line-length
        require(getContributionsFirstRound(beneficiary) + weiAmount <= getCap(beneficiary), "IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin: beneficiary's cap exceeded");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _preValidateSwapTokensRoundTwo(address beneficiary, uint256 weiAmount) internal virtual override view {
        super._preValidateSwapTokensRoundTwo(beneficiary, weiAmount);
        require(getCapSecondRound(beneficiary) != 0, "IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin: beneficiary's roundtwoCaps is not set");
        // solhint-disable-next-line max-line-length
        require(getContributionsSecondRound(beneficiary) + weiAmount <= getCapSecondRound(beneficiary), "IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin: beneficiary's round two cap exceeded");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev Extend parent behavior to update beneficiary contributions.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _updateSwapTokensState(address beneficiary, uint256 weiAmount) internal virtual override {
        super._updateSwapTokensState(beneficiary, weiAmount);
        if (_contributionsFirstRound[beneficiary] == 0 && _contributionsSecondRound[beneficiary] == 0 ) {
            _participationCount += 1;
        }
        if (isOpen()) {
            _contributionsFirstRound[beneficiary] += weiAmount;     
        } else if (isOpenForRoundTwo()) { 
            _contributionsSecondRound[beneficiary] += weiAmount; 
        }
        _totalContributions += weiAmount;
    }
}


pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


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


pragma solidity ^0.8.0;

//import "./IERC165.sol";

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


pragma solidity ^0.8.0;

//import "../utils/Context.sol";
//import "../utils/Strings.sol";
//import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


pragma solidity ^0.8.0;

//import "../utils/Context.sol";

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
    constructor() {
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

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/AccessControl.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";

//import "./crowdsale/IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin.sol";
//import "./vesting/TokenVesting.sol";

contract MoonedgeTwoRoundStableCoinSale is AccessControl, IndividuallyCappedTwoRoundTimeCrowdsaleStableCoin, Pausable, TokenVesting {
    uint256 private _cap;

    bytes32 public constant CAPPER_ROLE = keccak256("CAPPER_ROLE");
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    
    constructor (
        uint256 rate_,
        address wallet_,
        IERC20 token_,
        IERC20 stablecoin_,
        uint256 openingTime_,
        uint256 closingTime_,
        uint256 openingTimeRoundTwo_,
        uint256 closingTimeRoundTwo_,
        uint256 cap_, 
        address admin, 
        address capper
    )
        TwoRoundsCrowdsaleStableCoin(openingTimeRoundTwo_, closingTimeRoundTwo_)
        TimedCappedCrowdsaleStableCoin(openingTime_, closingTime_, cap_)
        CrowdsaleStableCoin(wallet_, token_, stablecoin_) 
        TokenVesting(token_)
    {
        require(rate_ > 0, "MoonedgeTwoRoundStableCoinSale: rate is 0");
        super._setRate(rate_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(CAPPER_ROLE, _msgSender());
        _setupRole(CAPPER_ROLE, admin);
        _setupRole(CAPPER_ROLE, capper);
    }
  
    /**
    * @dev set whitelisted addresses including caps.
    * @param whitelists array of addresses
    * @param cap_ Wei limit for individual contribution
    * @param percentage_ cap percentage of the second round
    */
    function setCaps(address[] calldata whitelists, uint256 cap_, uint256 percentage_) external {
        require(hasRole(CAPPER_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not a capper");
        require(cap_ != 0, "MoonedgeTwoRoundStableCoinSale: cap is 0");
        require(percentage_ != 0, "MoonedgeTwoRoundStableCoinSale: percentage is 0");
        for (uint256 i = 0; i < whitelists.length; i++) {
            address whitelisted = whitelists[i];
            require(whitelisted != address(0), "MoonedgeTwoRoundStableCoinSale: whitelisted is the zero address");
            super._setCap(whitelisted, cap_, percentage_);
            _setupRole(WHITELISTED_ROLE, whitelisted);
        }
    }

    function addVestings(uint256[] calldata vestingIds, uint256[] calldata delays, uint256[] calldata percentages) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not an admin");
        require(vestingIds.length == delays.length, "MoonedgeTwoRoundStableCoinSale: delay.length not the same as vestingIds.length");
        require(vestingIds.length == percentages.length, "MoonedgeTwoRoundStableCoinSale: percentages.length not the same as vestingIds.length");
        uint256 totalPercentages_;
        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentages_ += percentages[i];
        }
        require(totalPercentages_ == 1000, "MoonedgeTwoRoundStableCoinSale: total percentages not 1000");
        for (uint256 i = 0; i < vestingIds.length; i++) {
            require(delays[i] != 0, "MoonedgeTwoRoundStableCoinSale: delays[i] is 0");
            require(percentages[i] != 0, "MoonedgeTwoRoundStableCoinSale: percentages[i] is 0");
            super._addVesting(vestingIds[i], delays[i], percentages[i]);
        }
    }

    function setRate(uint256 rate_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not an admin");
        super._setRate(rate_);
    }
    
    /**
    * @dev Extend sale period.
    * @param closingTime_ Sale closing time
    */
    function extendTime(uint256 closingTime_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not an admin");
        super._extendTime(closingTime_);
    }

    /**
    * @dev Extend crowdsale.
    * @param newClosingTime Crowdsale closing time
    *
    * Requirements:
    *
    * - `newClosingTime` cannot before closingTime.
    *  
    */
    function extendTimeRoundTwo(uint256 newClosingTime) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not an admin");
        super._extendTimeRoundTwo(newClosingTime);
    }

    function pause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not an admin");
        _pause();
    }

    function unpause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not an admin");
        _unpause();
    }

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from Crowdsale to extend their validations.
    * Example from CappedCrowdsale.sol's _preValidatePurchase method:
    *     super._preValidatePurchase(beneficiary, weiAmount);
    *     require(weiRaised().add(weiAmount) <= cap);
    * @param beneficiary Address performing the token purchase
    * @param weiAmount Value in wei involved in the purchase
    *
    * Requirements:
    *
    * - `beneficiary` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    * - the caller must have WHITELISTED_ROLE role.
    */
    function _preValidateSwapTokens(address beneficiary, uint256 weiAmount) internal virtual override whenNotPaused view {
        super._preValidateSwapTokens(beneficiary, weiAmount);
        require(hasRole(WHITELISTED_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not whitelisted");
    }

    function _preValidateChangeCap(uint256 cap_) internal virtual override view {
        super._preValidateChangeCap(cap_);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not an admin");
    }

    /**
    * @dev We don't send the tokens to beneficiary after swapping
    * Crowdsale._sendTokens
    * instead we add token balance to 
    * TokenEscrow tokenDeposit
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _sendTokens(address beneficiary, uint256 tokenAmount) internal virtual override {
        super._tokenDeposit(token(), beneficiary, tokenAmount);
    }

    /**
    * @dev We don't send the tokens from beneficiary after 
    * TokenEscrow super.tokenDeposit
    * we already have the tokens in this contract, this is only a state change
    * @param token_ The token address of IERC20 token
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _depositTokens(IERC20 token_, address beneficiary, uint256 tokenAmount) internal virtual override {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
    * @dev Validation of claim. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from Crowdsale to extend their validations.
    * Example from CappedCrowdsale.sol's _preValidatePurchase method:
    *     super._preClaim(vestingId_, delay, percentage);
    * @param vestingId_ Address performing the token purchase
    * Requirements:
    *
    * - `vestingId_` must exist.
    * - getVestingTimeById `vestingId_` must in open time.
    * - _vestingStatus `vestingId_` must be false (not claimed).
    */
    function _preClaim(address beneficiary, uint256 vestingId_) internal virtual override view {
        super._preClaim(beneficiary, vestingId_);
        require(hasRole(WHITELISTED_ROLE, _msgSender()), "MoonedgeTwoRoundStableCoinSale: caller is not whitelisted");
    }

    /**
    * @dev Validation of an fallback redeem. Use require statements to revert state when conditions are not met.
    * Use `super` in contracts that inherit from TokenEscrow to extend their validations.
    * Example from TokenEscrow.sol's _prevalidateFallbackRedeem method:
    *     super._prevalidateFallbackRedeem(token, payee, amount);
    *    
    * @param token_ The token address of IERC20 token
    * @param amount Number of tokens deposit
    * @param to Address performing the token deposit
    *
    * Requirements:
    *
    * - `msg.sender` must be owner.
    * - `token` cannot be the zero address.
    * - `to` cannot be the zero address.
    * - this address must have a token balance of at least `amount`.
    */
    function _prevalidateFallbackRedeem(IERC20 token_,  address to, uint256 amount) internal virtual onlyOwner override view {
        super._prevalidateFallbackRedeem(token_, to, amount);
        uint256 newTime = closingTimeRoundTwo() + 2 days;
        require(newTime > block.timestamp, "MoonedgeTwoRoundStableCoinSale: fallbackRedeem time is not open");
    }
}