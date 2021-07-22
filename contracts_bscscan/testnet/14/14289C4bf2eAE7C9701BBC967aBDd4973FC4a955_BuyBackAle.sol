/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: Unlicensed

/**
 */


pragma solidity ^0.8.6;



library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
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


interface IBEP20 {	
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
// CAUTION	
// This version of SafeMath should only be used with Solidity 0.8 or later,	
// because it relies on the compiler's built in overflow checks.	
/**	
 * @dev Wrappers over Solidity's arithmetic operations.	
 *	
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler	
 * now has built in overflow checking.	
 */	
library SafeMath {	
    /**	
     * @dev Returns the addition of two unsigned integers, with an overflow flag.	
     *	
     * _Available since v3.4._	
     */	
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {	
        unchecked {	
            uint256 c = a + b;	
            if (c < a) return (false, 0);	
            return (true, c);	
        }	
    }	
    /**	
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.	
     *	
     * _Available since v3.4._	
     */	
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {	
        unchecked {	
            if (b > a) return (false, 0);	
            return (true, a - b);	
        }	
    }	
    /**	
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.	
     *	
     * _Available since v3.4._	
     */	
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {	
        unchecked {	
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the	
            // benefit is lost if 'b' is also tested.	
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522	
            if (a == 0) return (true, 0);	
            uint256 c = a * b;	
            if (c / a != b) return (false, 0);	
            return (true, c);	
        }	
    }	
    /**	
     * @dev Returns the division of two unsigned integers, with a division by zero flag.	
     *	
     * _Available since v3.4._	
     */	
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {	
        unchecked {	
            if (b == 0) return (false, 0);	
            return (true, a / b);	
        }	
    }	
    /**	
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.	
     *	
     * _Available since v3.4._	
     */	
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {	
        unchecked {	
            if (b == 0) return (false, 0);	
            return (true, a % b);	
        }	
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
        return a + b;	
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
        return a * b;	
    }	
    /**	
     * @dev Returns the integer division of two unsigned integers, reverting on	
     * division by zero. The result is rounded towards zero.	
     *	
     * Counterpart to Solidity's `/` operator.	
     *	
     * Requirements:	
     *	
     * - The divisor cannot be zero.	
     */	
    function div(uint256 a, uint256 b) internal pure returns (uint256) {	
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
        unchecked {	
            require(b <= a, errorMessage);	
            return a - b;	
        }	
    }	
    /**	
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on	
     * division by zero. The result is rounded towards zero.	
     *	
     * Counterpart to Solidity's `%` operator. This function uses a `revert`	
     * opcode (which leaves remaining gas untouched) while Solidity uses an	
     * invalid opcode to revert (consuming all remaining gas).	
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
        unchecked {	
            require(b > 0, errorMessage);	
            return a / b;	
        }	
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
        unchecked {	
            require(b > 0, errorMessage);	
            return a % b;	
        }	
    }	
}	
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
        require(address(this).balance >= amount, "Insufficient balance");	
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value	
        (bool success, ) = recipient.call{ value: amount }("");	
        require(success, "Unable to send value, recipient may have reverted");	
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
      return functionCall(target, data, "Low-level call failed");	
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
        return functionCallWithValue(target, data, value, "Low-level call with value failed");	
    }	
    /**	
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but	
     * with `errorMessage` as a fallback revert reason when `target` reverts.	
     *	
     * _Available since v3.1._	
     */	
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {	
        require(address(this).balance >= value, "Insufficient balance for call");	
        require(isContract(target), "Call to non-contract");	
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
        return functionStaticCall(target, data, "Low-level static call failed");	
    }	
    /**	
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],	
     * but performing a static call.	
     *	
     * _Available since v3.3._	
     */	
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {	
        require(isContract(target), "Static call to non-contract");	
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
        return functionDelegateCall(target, data, "Low-level delegate call failed");	
    }	
    /**	
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],	
     * but performing a delegate call.	
     *	
     * _Available since v3.4._	
     */	
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {	
        require(isContract(target), "Delegate call to non-contract");	
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
    address private _previousOwner;		
    uint256 private _unlockTime;
    uint256 public _lockTime = 28 days;
    
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
     * @dev Returns the address of the previous owner.
     */
    function previousowner() public view virtual returns (address) {
        return _previousOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        _previousOwner = _owner;
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function getUnlockTime() public view returns (uint256) {
        return _unlockTime;	
    }
    //Locks the contract for owner for the amount of time provided
    function lock() public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _unlockTime = block.timestamp + _lockTime;
    emit OwnershipTransferred(_owner, address(0));
    }
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _unlockTime , "Unlock time is not expired");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Create(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function create(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BuyBackAle is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
   //skizzo
   using EnumerableSet for EnumerableSet.AddressSet;
   EnumerableSet.AddressSet private _isExcludedFromReward; //anche no
   mapping (address => uint256) private _firstDeposit;
   //end skizzo
   
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 5000000000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tBNBFeeTotal;

    string private _name = "BuyBackAleSkizz";
    string private _symbol = "ALSK";
    uint8 private _decimals = 18;
    
	//normal sell
    uint256 private _DefTaxFee = 3;
	uint256 public _taxFee = _DefTaxFee;
   	uint256 private _DefBNBFee = 3;
	uint256 public _BNBFee = _DefBNBFee;

	uint256 private _feeDurationHalf =  60 ;//30 * 24 * 3600; fast sell
	uint256 private _feeDurationMax =  120 ;//30 * 24 * 3600; Bot sell
	uint256 private feeMultiplier = 0; 
	
	// fast sell
	uint256 public _taxFeeL1 = 15; 
    uint256 public _BNBFeeL1 = 15; 
	
	//bot sell
	uint256 public _taxFeeL2 = 30; 
    uint256 public _BNBFeeL2 = 30; 	


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	address payable public fundraisingAddress = payable(0x15beB1Eb0871765703Eef1Defc5Deced39160dE3);
    
    //uint256 public fundDivisor = 1;
    
    bool inSwaptoBNB;
    bool public SwaptoBNBEnabled = true;
    bool public buyBackEnabled = true;
    
    uint256 public _maxTxAmount = 10000000 * 10 ** 18;
    uint256 private minTokensBeforeSwap = 1000000 * 10 ** 18;
    uint256 private buyBackUpperLimit = 1 * 10 ** 15;
    
    uint256 private maxBalance;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwaptoBNBEnabledUpdated(bool enabled);
    event BuyBackEnabledUpdated(bool enabled);
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    event SwaptoBNB(
        uint256 tokensSwapped,
        uint256 ethReceived,
        address fundraisingAddress
    );
    
    modifier lockTheSwap {
        inSwaptoBNB = true;
        _;
        inSwaptoBNB = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        // real router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
        
    }
    
    //New Pancakeswap router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) public onlyOwner() {
       //Thank you FreezyEx
        IUniswapV2Router02 _newuniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newuniswapV2Router.factory()).createPair(address(this), _newuniswapV2Router.WETH());
        uniswapV2Router = _newuniswapV2Router;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function minTokensBeforeSwapAmount() public view returns (uint256) {
        return minTokensBeforeSwap;
    }
    
    function buyBackUpperLimitAmount() public view returns (uint256) {
        return buyBackUpperLimit;
    }
	
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function deliver(uint256 tAmount) private {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) private view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
	
	//skizzo
		//credo serva x interrogare il contratto x sapere se l'address ha diritto allo sconto. non chiamata da nessuna parte
	   function untilNormalFees(address account) public view returns(uint256) {
        if (_firstDeposit[account] == 0) {
            return 0;
        } else if(_firstDeposit[account].add(_feeDurationMax) <= block.timestamp) {
            return 0;
        } else {
            return (_firstDeposit[account].add(_feeDurationMax)).sub(block.timestamp);
        }   
    }
	
	
	//per un frontend
  	function _feeLevel(address account) public view returns(string memory feeLevel) {

        if ( _firstDeposit[account] == 0 || _firstDeposit[account].add(_feeDurationMax) <= block.timestamp ) {
            return "Holder Fee level";
        } else if((_firstDeposit[account].add(_feeDurationMax)).sub(block.timestamp) <= _feeDurationHalf ) {
            return "Premature seller fee level";
        } else  {
            return "Bot Fee level";
        }    
    }
	
		
	//dynamic fees
	    function calculateAllFee() private {		
        if(feeMultiplier == 0) {
        _taxFee = _DefTaxFee;
        _BNBFee = _DefBNBFee;
        } else if (feeMultiplier == 1) {
            _taxFee = _taxFeeL1;
            _BNBFee = _BNBFeeL1;
        }else if (feeMultiplier == 2) {
            _taxFee = _taxFeeL2;
            _BNBFee = _BNBFeeL2;
        }
    }

	
	//skizzo end

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setBNBFeePercent(uint256 BNBFee) external onlyOwner() {
         _BNBFee = BNBFee;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**3
        );
    }
    
    function setfundraisingAddress(address payable _fundraisingAddress) public onlyOwner {
        fundraisingAddress = _fundraisingAddress;
    }
    
    
    //function setfundDivisor(uint256 divisor) external onlyOwner() {
    //fundDivisor = divisor;
    //}

    function setminTokensBeforeSwap(uint256 _minTokensBeforeSwap) external onlyOwner() {
        minTokensBeforeSwap = _minTokensBeforeSwap;
    }
	
	  function TransferTofundraisingAddress(uint256 amount) private {
        fundraisingAddress.transfer(amount);
    }
    
    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
    buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function setSwaptoBNBEnabled(bool _enabled) public onlyOwner {
        SwaptoBNBEnabled = _enabled;
        emit SwaptoBNBEnabledUpdated(_enabled);
    }
    
    function setBuyBackEnabled(bool _enabled) public onlyOwner {
    buyBackEnabled = _enabled;
    emit BuyBackEnabledUpdated(_enabled);
    }
    
    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}
    
    // This will allow to rescue BNB sent by mistake directly to the contract
    function rescueBNBStuckinContract() external onlyOwner {
        address payable _owner = payable(_msgSender());
        _owner.transfer(address(this).balance);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {	
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);	
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());	
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);	
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {	
        uint256 tFee = calculateTaxFee(tAmount);	
        uint256 tLiquidity = calculateBNBFee(tAmount);	
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);	
        return (tTransferAmount, tFee, tLiquidity);	
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {	
        uint256 rAmount = tAmount.mul(currentRate);	
        uint256 rFee = tFee.mul(currentRate);	
        uint256 rLiquidity = tLiquidity.mul(currentRate);	
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateBNBFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_BNBFee).div(
            10**2
        );
    }
    
    function removeAllFee() public {
        if(_taxFee == 0 && _BNBFee == 0) return;
        
        //_DefTaxFee = _taxFee;
        _taxFee = 0;
        
        
       // _DefBNBFee = _BNBFee;
        _BNBFee = 0;
    }
    
    function restoreAllFee() public {
        _taxFee = _DefTaxFee;
        _BNBFee = _DefBNBFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if( from != owner() && to != owner() && to != address(0) && from != fundraisingAddress && from != address(this) && to != address(this))
           require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
          if (maxBalance < balanceOf(uniswapV2Pair))
        maxBalance = balanceOf(uniswapV2Pair); 

        
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (overMinTokenBalance && !inSwaptoBNB && from != uniswapV2Pair && SwaptoBNBEnabled) {
            if (to == uniswapV2Pair) {
           contractTokenBalance = minTokensBeforeSwap;
           swaptoBNB(contractTokenBalance);
                   uint256 balance = address(this).balance;
                      if (buyBackEnabled && (balanceOf(uniswapV2Pair) < (maxBalance.mul(90)).div(100))) {
                          if (buyBackEnabled) {
                        //  if (balance > buyBackUpperLimit)
                        //  balance = buyBackUpperLimit;  
                          buyBackTokens(balance);
                     //   }
                            } 
                     }
            }
        }      
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
		//skizzo
		
	  if (to == uniswapV2Pair) {
		if( untilNormalFees(from) == 0) {
           feeMultiplier = 0;
                } else if(untilNormalFees(from) <= _feeDurationHalf ) {
                    takeFee = true;
                    feeMultiplier = 1;
                } else {
                    takeFee = true;
                    feeMultiplier = 2;
                } 
                
        	    if ( from != uniswapV2Pair) {
        		_firstDeposit[from] = block.timestamp; //memorizza transazione from
                }
        		
        		calculateAllFee();	
	  }
		//end dynamic fees
		
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swaptoBNB(uint256 contractTokenBalance) private lockTheSwap {
        // swap tokens for BNB
        //uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        //uint256 transferredBalance = address(this).balance.sub(initialBalance);
        
          //Send to development and funds address
        _tBNBFeeTotal = _tBNBFeeTotal.add(address(this).balance); //transferredBalance
        //TransferTofundraisingAddress(address(this).balance);
        TransferTofundraisingAddress(address(this).balance.div(_BNBFee));
        emit SwaptoBNB(contractTokenBalance, _tBNBFeeTotal, fundraisingAddress);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        //path[1] = uniswapV2Router.WETH();
        path[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function swapETHForTokens(uint256 amount) private {
      // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        //path[0] = uniswapV2Router.WETH();
        path[0] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        path[1] = address(this);
      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }

    
    function buyBackTokens(uint256 amount) private lockTheSwap {
          if (amount > 0)
          swapETHForTokens(amount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}