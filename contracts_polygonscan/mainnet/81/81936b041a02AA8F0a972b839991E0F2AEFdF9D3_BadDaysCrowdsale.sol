/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT
// File: Marvelous/contracts/EIP712Base.sol


pragma solidity ^0.6.12;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
    internal
    initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
        );
    }
}

// File: Marvelous/contracts/ContextMixin.sol


pragma solidity ^0.6.12;

abstract contract ContextMixin {
    function msgSender()
    internal
    view
    returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



pragma solidity >=0.6.0 <0.8.0;

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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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



pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts/math/Math.sol



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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: Marvelous/contracts/NativeMetaTransaction.sol



pragma solidity ^0.6.12;



contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
            });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/AccessControl.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: Marvelous/contracts/AccessControlMixin.sol


pragma solidity ^0.6.6;


contract AccessControlMixin is AccessControl {
    string private _revertMsg;
    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
    }

    modifier only(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            _revertMsg
        );
        _;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;


// File: Marvelous/contracts/Crowdsale.sol



pragma solidity ^0.6.12;








/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate behavior.
 */
contract Crowdsale is Context, AccessControlMixin, ReentrancyGuard {
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 internal _token;

    // Address where funds are collected
    address payable internal _wallet;

    // Address holding the tokens, which has approved allowance to the crowdsale.
    address internal _tokenWallet;
    
    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 internal _rate;

    // Amount of wei raised
    uint256 internal _weiRaised;

    event SetRate(address sender, uint256 rate);
    event SetWallet(address sender, address payable wallet);
    event SetToken(address sender, IERC20 token);
    event SetTokenWallet(address sender, address wallet);

    /**
     * @return the token being sold.
     */
    function getToken() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function getWallet() public view returns (address payable) {
        return _wallet;
    }
    
    function getTokenWallet() public view returns(address) {
        return _tokenWallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function getRate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) virtual internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }
    
    /**
     * @dev Checks the amount of tokens left in the allowance.
     * @return Amount of tokens left in the allowance
     */
    function remainingTokens() public view returns (uint256) {
        return Math.min(_token.balanceOf(_tokenWallet), _token.allowance(_tokenWallet, address(this)));
    }

    function setNewRate(uint256 rate) external only(CREATOR_ROLE) {
        _rate = rate;
        emit SetRate(_msgSender(), rate);
    }
    
    function setNewWallet(address payable wallet) external only(CREATOR_ROLE) {
        _wallet = wallet;
        emit SetWallet(_msgSender(), wallet);
    }
    
    function setNewToken(IERC20 token) external only(CREATOR_ROLE) {
        _token = token;
        emit SetToken(_msgSender(), token);
    }
    
    function setTokenWallet(address wallet) external only(CREATOR_ROLE) {
        _tokenWallet = wallet;
        emit SetTokenWallet(_msgSender(), wallet);
    }

}

// File: Marvelous/contracts/TimedCrowdsale.sol



pragma solidity ^0.6.12;



/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event CrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);
    event CrowdsalePostponed(uint256 prevOpeningTime, uint256 newOpeningTime);
    event CrowdsaleClosingAdjusted(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
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
    
    function overrideClosingTime(uint256 newClosingTime) external only(CREATOR_ROLE) {
        require(newClosingTime > block.timestamp, "TimedCrowdsale: new closing time is before current time");
        require(newClosingTime > _openingTime, "TimedCrowdsale: closing time is before opening time");
        emit CrowdsaleClosingAdjusted(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
    
    function postponeOpening(uint256 newOpeningTime) external only(CREATOR_ROLE) {
        require(newOpeningTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        require(newOpeningTime < _closingTime, "TimedCrowdsale: opening time must be before closing time");
        
        emit CrowdsalePostponed(_openingTime, newOpeningTime);
        _openingTime = newOpeningTime;
    }
    
    function _setPresaleSchedule(uint256 newOpeningTime, uint256 newClosingTime) internal {
        require(newOpeningTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        require(newOpeningTime < newClosingTime, "TimedCrowdsale: opening time must be before closing time");
        
        _openingTime = newOpeningTime;
        _closingTime = newClosingTime;
    }
}

// File: Marvelous/contracts/CappedCrowdsale.sol



pragma solidity ^0.6.12;



/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 internal _cap;
    
    event SetNewCap(uint256 newcap);

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
    
    function setNewCap(uint256 newcap) external only(CREATOR_ROLE) {
         _cap = newcap;
        emit SetNewCap(newcap);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: Marvelous/contracts/WETH.sol



pragma solidity ^0.6.12;


abstract contract WETH is ERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor() public ERC20("Wrapped Ether", "WETH") {}

    function deposit() public virtual payable;

    function withdraw(uint256 wad) public virtual;

    function withdraw(uint256 wad, address user) public virtual;
}

// File: Marvelous/contracts/MaticWETH.sol



pragma solidity ^0.6.12;



abstract contract MaticWETH is WETH {

    function deposit() public payable virtual override {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public virtual override {
        require(balanceOf(msg.sender) >= wad);
        _burn(msg.sender, wad);
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function withdraw(uint256 wad, address user) public virtual override{
        require(balanceOf(msg.sender) >= wad);
        _burn(msg.sender, wad);
        address(uint160(user)).transfer(wad);
        emit Withdrawal(user, wad);
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol



pragma solidity >=0.6.0 <0.8.0;


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
    constructor () internal {
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

// File: Marvelous/contracts/BadDaysCrowdsale.sol



pragma solidity ^0.6.12;









contract BadDaysCrowdsale is Pausable, CappedCrowdsale, TimedCrowdsale, ContextMixin, NativeMetaTransaction {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    string constant name = "BadDaysCrowdsale";
    
    //Whitelisted addresses that can engage in pre-sale 
    mapping(address => bool) internal whitelisted;
    
    //Constant counter for a month = 30 days = 2,592,000 seconds
    uint256 constant oneMonth = 2592000;

    //Contant counter for a day = 86400 seconds
    uint256 constant oneDay = 86400;
    
    //Account -> Category -> Amount Withdrawn after TGE for Category 7 through 11
    mapping(address => mapping(uint256 => uint256)) public claimedTokensAfterTGE;
    
    //Acocunt -> Category -> Day -> Amount
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public claimedTokensForTheDay;
    
    //Override control to enable withdrawal after TGE has been defined and the pre-sale has been closed
    bool internal canWithdraw;
    
    //Override date for the TGE - needs to be manually set
    uint256 public dayOfTGE;
    
    //MNFT token address
    IERC20 internal _maticWeth;
    
    /*
    Categories
    Index from 0 - 12
    0 - Team
    1 - Operations
    2 - Marketing
    3 - Advisors
    4 - Growth Fund
    5 - Escrow Vault
    6 - Play Rewards
    7 - Seed Round
    8 - Strategic Round
    9 - Private Round 1
    10 - Private Round 2
    11 - Public Round
    */
    uint256 public activeCatIndex;
    
    //Holder of category with index
    mapping(uint256 => Category) public fundCategory;
    
    //Holder of the address of the holder of the allocated fund per category (0 - 6)
    mapping(uint256 => address) public accountForCategory;
    
    //total reserved funds of a specific wallet
    mapping(address => uint256) public totalFunds;
    
    //total balance of an address
    mapping(address => uint256) public totalBalanceOfFunds;
    
    //total reserved funds of a specific wallet for a specific category
    mapping(address => mapping(uint256 => uint256)) public totalFundsForCategory;
    
    //balance of a specific address for a specific category
    mapping(address => mapping(uint256 => uint256)) public balanceOfFundsForCategory;
    
    //total balance of the main vault from start to end, across all categories
    uint256 public vaultBalance;
    
    //total balance of the vault of an ongoing sale category
    uint256 public presaleVaultBalance;
    
    //Vault balance for a specific category
    mapping(uint256 => uint256) public raisedVaultBalance;
    
    //Total raised funds across all catagories (7 - 11)
    uint256 public totalRaisedFunds;
    
    //Total raised funds for each category (7 - 11)
    mapping(uint256 => uint256) public raisedFundsForCategory;
    
    //Struct that defines the configurations of each Category
    struct Category {
        string desc;
        uint256 index;
        uint256 periodAfterTGE;
        uint256 percentClaimableAtTGE;
        uint256 vestingPeriodAfterTGE;
    }
    
    event SetPresaleSchedule(address sender, uint256 openingTime, uint256 closingTime, uint256 cap, uint256 rate, uint256 index);
    event WithdrawTokens(address sender, address beneficiary, uint256 amount);
    event TokensPurchased(address indexed purchaser, uint256 index, address indexed beneficiary, uint256 value, uint256 amount);
    event UpdateWhitelist(address sender, address[] accounts, bool mode);
    event ConfigCategory(string desc, uint256 index, uint256 periodAfterTGE, uint256 percentClaimableAtTGE, uint256 vestingPeriodAfterTGE);
    event LockAllocation(string desc, address account, uint256 amount, address sender);
    event SetTGE(address sender, uint256 value);
    event CanWithdraw(address sender, bool canWithdraw);
    event SendFundsAfterTGE(address account, uint256 category, uint256 claimable);
    event AllocateTokensFor(address sender, uint256 index, address account, uint256 amounts);
    
    constructor(
        MaticWETH maticWeth,
        address payable wallet,  // wallet to send Ether
        IERC20 token,            // the token
        address tokenwallet     // tokenWallet of the token
    )
        public
    {
        _setupContractId(name);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, _msgSender());
        _wallet = wallet;
        _tokenWallet = tokenwallet;
        _token = token;
        _maticWeth = maticWeth;
        
        //For Production Live
        //desc, index, periodAfterTGE, percentClaimableAtTGE, vestingPeriodAfterTGE
        _configCategory("Team", 0, 15552000, 0, 1080);
        _configCategory("Operations", 1, 7776000, 0, 690);
        _configCategory("Marketing", 2, 7776000, 0, 690);
        _configCategory("Advisors", 3, 7776000, 0, 720);
        _configCategory("Growth Fund", 4, 15552000, 0, 780);
        _configCategory("Escrow Vault", 5, 2592000, 0, 0);
        _configCategory("Play Rewards", 6, 86400, 0, 630);
        _configCategory("Seed Round", 7, 5184000, 0, 450);
        _configCategory("Strategic Round", 8, 2592000, 0, 360);
        _configCategory("Private Round 1", 9, 1814400, 0, 240);
        _configCategory("Private Round 2", 10, 1209600, 0, 210);
        _configCategory("Public Round", 11, 604800, 15, 120);
        
        _initializeEIP712(name);
    }
    
    function pause() external only(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external only(PAUSER_ROLE) {
        _unpause();
    }

    function _msgSender() internal override view returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
    
    modifier whenCanWithdraw() {
        require(dayOfTGE > 0, "BadDaysCrowdsale: No TGE yet");
        require(hasClosed(), "BadDaysCrowdsale: not closed");
        require(canWithdraw, "BadDaysCrowdsale: Withdrawal is still disabled");
         _;
    }
    
    function isApprovedToSpend(address account) external view returns (uint256) {
        return _maticWeth.allowance(account, address(this));
    }
    
    function setTGE(uint256 value) external only(CREATOR_ROLE) {
        dayOfTGE = value;
        emit SetTGE(_msgSender(), value);
    } 
    
    /// @notice This fuction configures aech category for the token sale
    /// @param desc - name of the category
    /// @param index - base 0 index of the category
    /// @param periodAfterTGE - lock period after TGE in seconds
    /// @param vestingPeriodAfterTGE - total vesting period in days
    function _configCategory(string memory desc, uint256 index, uint256 periodAfterTGE, uint256 percentClaimableAtTGE, uint256 vestingPeriodAfterTGE) internal {
        fundCategory[index] = Category(
            desc,
            index,
            periodAfterTGE,
            percentClaimableAtTGE,
            vestingPeriodAfterTGE
        );
    }
    
    function configCategory(string memory desc, uint256 index, uint256 periodAfterTGE, uint256 percentClaimableAtTGE, uint256 vestingPeriodAfterTGE) 
    external only(CREATOR_ROLE) {
        _configCategory(desc, index, periodAfterTGE, percentClaimableAtTGE, vestingPeriodAfterTGE);
        emit ConfigCategory(desc, index, periodAfterTGE, percentClaimableAtTGE, vestingPeriodAfterTGE);
    }
    
    function getCategoryConfig(uint256 code) external view
    returns (string memory desc, uint256 index, uint256 periodAfterTGE, uint256 percentClaimableAtTGE, uint256 vestingPeriodAfterTGE) {
        Category storage category = fundCategory[code];

        return(category.desc, category.index, category.periodAfterTGE, category.percentClaimableAtTGE, category.vestingPeriodAfterTGE);
    }
    
    /**
     * @notice This opens a new category that will be available for pre-sale. Note that only Categories 7 through 11 could be opened for crowdsale.
     * @param openingTime - Opening time for the specific crowdsale in epoch seconds
     * @param closingTime - Closing time for the specific crowdsale in epoch seconds.
     * @param cap - Total cap in wei for the specific category
     * @param rate - Rate of token per wei
     * @param index - Index of the Category to be opened 
     */
    function setPresaleSchedule(uint256 openingTime, uint256 closingTime, uint256 cap, uint256 rate, uint256 index) external only(CREATOR_ROLE) {
        require(!isOpen(), "BadDaysCrowdsale: not closed");
        require(index > 6 && index < 12, "Invalid crowdsale index");
        
        activeCatIndex = index;
        presaleVaultBalance = 0;
        _weiRaised = 0;
        _cap = cap;
        _rate = rate;
        _setPresaleSchedule(openingTime, closingTime);
        
        emit SetPresaleSchedule(_msgSender(), openingTime, closingTime, cap, rate, index);
    }
    
    function allocateTokensFor(address[] memory accounts, uint256[] memory  amounts, uint256 index) external whenNotPaused only(CREATOR_ROLE) {
        require(index > 6 && index < 12, "BadDaysCrowdsale: No active category for crowdsale");
        require(accounts.length == amounts.length, "BadDaysCrowdsale: Number of accounts must mach number of amounts");

        for (uint256 i = 0; i < accounts.length; i++) {
            require(amounts[i] > 0, "BadDaysCrowdsale: amount must be more than 0");
            require(totalFundsForCategory[accounts[i]][index] == 0, "BadDaysCrowdsale: account already has funds");
            require(accounts[i] != address(0), "Crowdsale: beneficiary is the zero address");

            totalRaisedFunds = totalRaisedFunds.add(amounts[i]);
            raisedFundsForCategory[index] = raisedFundsForCategory[index].add(amounts[i]);
 
            _processPurchase(accounts[i], amounts[i], index);
            emit AllocateTokensFor(_msgSender(), index, accounts[i], amounts[i]);
        }
    }
    
    function buyTokens(address account, uint256 amount) external nonReentrant payable onlyWhileOpen whenNotPaused {
        require(isOpen(), "BadDaysCrowdsale: Still close");
        require(!capReached(), "BadDaysCrowdsale: Cap already reached");
        require(amount > 0, "BadDaysCrowdsale: amount must be more than 0");
        require(activeCatIndex == 11, "BadDaysCrowdsale: No active category for crowdsale");
        require(_maticWeth.balanceOf(_msgSender()) >= amount,"BadDaysCrowdsale: Not enough funds");
        uint256 allowance = _maticWeth.allowance(_msgSender(), address(this));
 	    require(allowance >= amount, "BadDaysCrowdsale: Not enough allowance.");
 	    
 	    require(_weiRaised.add(amount) <= cap(), "BadDaysCrowdsale: Amount will cause to exceed cap");
 	    require(account != address(0), "Crowdsale: beneficiary is the zero address");

        // collect fund
        _maticWeth.safeTransferFrom(_msgSender(), getWallet(), amount);
        
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(amount);

        // update state
        _weiRaised = _weiRaised.add(amount);
        totalRaisedFunds = totalRaisedFunds.add(amount);
        raisedFundsForCategory[activeCatIndex] = raisedFundsForCategory[activeCatIndex].add(amount);

        _processPurchase(account, tokens, activeCatIndex);
        emit TokensPurchased(_msgSender(), activeCatIndex, account, amount, tokens);
    }
    
    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param account - account to receive the tokens
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address account, uint256 tokenAmount, uint256 index) internal {
        uint256 allowance = _token.allowance(_tokenWallet, address(this));
        require(allowance >= tokenAmount, "BadDaysCrowdsale: Not enough allowance for contract.");
        
        _token.safeTransferFrom(_tokenWallet, address(this), tokenAmount);
        totalFunds[account] = totalFunds[account].add(tokenAmount);
        totalBalanceOfFunds[account] = totalBalanceOfFunds[account].add(tokenAmount);
        totalFundsForCategory[account][index] = totalFundsForCategory[account][index].add(tokenAmount);
        balanceOfFundsForCategory[account][index] = balanceOfFundsForCategory[account][index].add(tokenAmount);
        raisedVaultBalance[index] = raisedVaultBalance[index].add(tokenAmount);
        presaleVaultBalance = presaleVaultBalance.add(tokenAmount);
        vaultBalance = vaultBalance.add(tokenAmount);
    }
    
    function _computeClaimableAfterTGE(address account, uint256 index) internal view returns(uint256) {
        Category storage category = fundCategory[index];
        uint256 percentClaimableAtTGE = category.percentClaimableAtTGE;
  
        uint256 claimable;
        if(block.timestamp > dayOfTGE) { 
            if (percentClaimableAtTGE > 0 && claimedTokensAfterTGE[account][index] == 0) {
                claimable = (totalFundsForCategory[account][index].mul(percentClaimableAtTGE)).div(100);
            }
        }   
        return claimable;
    }
    
    function getClaimableAfterTGE(address account, uint256 category) public view whenCanWithdraw returns(uint256) {
        require(totalBalanceOfFunds[account] > 0, "BadDaysCrowdsale: No reserved funds");
        require(category >= 7 && category < 12, "BadDaysCrowdsale: Category must be 7 - 11");
        
        return _computeClaimableAfterTGE(account, category);
    }
    
    function _getDaily(uint256 index, address account) internal view returns (uint256) {
        Category storage category = fundCategory[index];
        uint256 totalPercentForDistribution = 100;
        
        //Compute the actual daily percentage
        if(category.percentClaimableAtTGE > 0) {
            totalPercentForDistribution = totalPercentForDistribution.sub(category.percentClaimableAtTGE);
        }

        uint256 dailyClaimable = (totalFundsForCategory[account][index].mul(totalPercentForDistribution)).div(category.vestingPeriodAfterTGE);
        return dailyClaimable;
    }

    function _getTotalDaily(uint256 index, address account, uint256 periodAfterTGE) internal view returns (uint256) {
        uint256 claimable;
        uint256 lockedDays = (periodAfterTGE.div(oneDay)).add(1);
        if(block.timestamp > (dayOfTGE.add(periodAfterTGE))) {
            if(claimedTokensForTheDay[account][index][getDistributionDay()] == 0) {
                for (uint256 i = lockedDays; i <= getDistributionDay(); i++) {
                    if(claimedTokensForTheDay[account][index][i] == 0) {
                        uint256 dailyClaimable = _getDaily(index, account);
                        claimable = claimable.add(dailyClaimable.div(100));
                    }

                    if(claimable >= balanceOfFundsForCategory[account][index]) {
                        claimable = balanceOfFundsForCategory[account][index];
                        break;
                    }               
                }
            }
        }
        return claimable;
    }
    
    function _getClaimableFunds(address account, uint256 index) internal view returns(uint256) {
        Category storage category = fundCategory[index];
        uint256 periodAfterTGE = category.periodAfterTGE;
        uint256 claimable = _getTotalDaily(index, account, periodAfterTGE);
        //Just in case there will be decimal rounding off results. 
        //To ensure exact values of remaining funds will be claimed.
        if(claimable > balanceOfFundsForCategory[account][index]) {
            claimable = balanceOfFundsForCategory[account][index];
        }
        return claimable;
    }
    
    function getClaimableForCategory(address account, uint256 index) public view returns(uint256) {
        uint256 claimable;
        if(balanceOfFundsForCategory[account][index] > 0) {
            claimable = _getClaimableFunds(account, index);
        }
        return claimable;
    }
    
    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param account Whose tokens will be withdrawn.
     */
    function getClaimable(address account) public view whenCanWithdraw returns(uint256) {
        require(totalBalanceOfFunds[account] > 0, "BadDaysCrowdsale: No reserved funds");
        
        uint256 claimable;
        for (uint256 i = 7; i < 12; i++) {
            claimable = claimable.add(getClaimableForCategory(account, i));
        }
        return claimable;
    }

    function _updateDailyClaimable(uint256 index, address account, uint256 periodAfterTGE) internal returns (uint256) {
        uint256 claimable;
        uint256 lockedDays = (periodAfterTGE.div(oneDay)).add(1);
        if(block.timestamp > (dayOfTGE.add(periodAfterTGE))) {
            if(claimedTokensForTheDay[account][index][getDistributionDay()] == 0) {
                for (uint256 i = lockedDays; i <= getDistributionDay(); i++) {
                    if(claimedTokensForTheDay[account][index][i] == 0) {
                        uint256 dailyClaimable = _getDaily(index, account);
                        claimable = claimable.add(dailyClaimable.div(100));
                        claimedTokensForTheDay[account][index][i] = dailyClaimable;
                    }

                    if(claimable >= balanceOfFundsForCategory[account][index]) {
                        claimable = balanceOfFundsForCategory[account][index];
                        break;
                    }               
                }
            }
        }
        return claimable;
    }
    
    function _updateClaimable(address account) internal {
        uint256 amount;
        uint256 claimable;
        for (uint256 i = 7; i < 12; i++) {
            claimable = 0;
            if(balanceOfFundsForCategory[account][i] > 0) {
                Category storage category = fundCategory[i];
                uint256 periodAfterTGE = category.periodAfterTGE;
            
                //Compute the actual daily percentage
                uint256 percentClaimableAtTGE = category.percentClaimableAtTGE;
                uint256 totalPercentForDistribution = 100;
        
                if(percentClaimableAtTGE > 0) {
                    totalPercentForDistribution = totalPercentForDistribution.sub(percentClaimableAtTGE);
                }
                claimable = claimable.add(_updateDailyClaimable(i, account, periodAfterTGE));
                
                //Just in case there will be decimal rounding off results. 
                //To ensure exact values of remaining funds will be claimed.
                if(claimable > balanceOfFundsForCategory[account][i]) {
                    claimable = balanceOfFundsForCategory[account][i];
                }
                balanceOfFundsForCategory[account][i] = balanceOfFundsForCategory[account][i].sub(claimable);
            }
            amount = amount.add(claimable);
         }
         totalBalanceOfFunds[account] = totalBalanceOfFunds[account].sub(amount);
    }
    
    function sendFundsAfterTGE(address account, uint256 category) external whenCanWithdraw whenNotPaused only(CREATOR_ROLE) {
        require(totalBalanceOfFunds[account] > 0, "BadDaysCrowdsale: No reserved funds");
        
        uint256 claimable = getClaimableAfterTGE(account, category);
        if (claimable > 0) {
            claimedTokensAfterTGE[account][category] = claimable;
            balanceOfFundsForCategory[account][category] = balanceOfFundsForCategory[account][category].sub(claimable);
            totalBalanceOfFunds[account] = totalBalanceOfFunds[account].sub(claimable);
            _token.transfer(account, claimable);
            emit SendFundsAfterTGE(account, category, claimable);
        }
        else {
            revert("BadDaysCrowdsale: Nothing to send");
        }
    }
    
    function withdrawTokens(address account) whenCanWithdraw external whenNotPaused {
        require(totalBalanceOfFunds[account] > 0, "BadDaysCrowdsale: No due any tokens");
        
        uint256 claimable = getClaimable(account);
        if(claimable > 0) {
            _updateClaimable(account);
            _token.transfer(account, claimable);
            emit WithdrawTokens(_msgSender(), account, claimable);
        }
    }
    
    function switchWithdrawal(bool condition) external only(CREATOR_ROLE) {
        require(dayOfTGE > 0,"BadDaysCrowdsale: Missing TGE date");
        
        canWithdraw = condition;
        emit CanWithdraw(_msgSender(), canWithdraw);
    }
    
    function getDistributionMonth() external view returns(uint256) {
        require(dayOfTGE > 0,"BadDaysCrowdsale: Missing TGE date");
        return ((block.timestamp.sub(dayOfTGE)).div(oneMonth)).add(1);
    }

    function getDistributionDay() public view returns(uint256) {
        require(dayOfTGE > 0,"BadDaysCrowdsale: Missing TGE date");
        return ((block.timestamp.sub(dayOfTGE)).div(oneDay)).add(1);
    }
    
    function updateWhitelist(address[] memory accounts, bool mode) external only(CREATOR_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelisted[accounts[i]] = mode;
        }
        emit UpdateWhitelist(_msgSender(), accounts, mode);
    }
    
    function isWhitelisted(address account) external view returns (bool) {
        return whitelisted[account];
    }
    
    function emergencyWithdraw(address account) external only(DEFAULT_ADMIN_ROLE) {
        uint256 balance = totalBalanceOfFunds[account];
        if (balance > 0) {
            totalBalanceOfFunds[account] = 0;
            for (uint256 i = 7; i < 12; i++) {
                balanceOfFundsForCategory[account][i] = 0;
            }
            _token.transfer(getTokenWallet(), balance);
        }
    }

}