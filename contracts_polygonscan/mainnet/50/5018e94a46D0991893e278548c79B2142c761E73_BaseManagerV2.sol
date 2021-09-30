/**
 *Submitted for verification at polygonscan.com on 2021-09-30
*/

// Dependency file: @openzeppelin/contracts/utils/Address.sol



// pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
     * // importANT: because control is transferred to `recipient`, care must be
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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity >=0.6.0 <0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: contracts/lib/AddressArrayUtils.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


*/

// pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/27/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}


// Dependency file: contracts/interfaces/ISetToken.sol

// pragma solidity 0.6.10;


// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */

    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);

    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);

    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

// Dependency file: contracts/interfaces/IBaseManager.sol

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


*/

// pragma solidity 0.6.10;


// import { ISetToken } from "contracts/interfaces/ISetToken.sol";

interface IBaseManager {
    function setToken() external returns(ISetToken);

    function methodologist() external returns(address);

    function operator() external returns(address);

    function interactManager(address _module, bytes calldata _encoded) external;

    function transferTokens(address _token, address _destination, uint256 _amount) external;
}

// Dependency file: contracts/interfaces/IExtension.sol

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


*/

// pragma solidity 0.6.10;


// import { IBaseManager } from "contracts/interfaces/IBaseManager.sol";

interface IExtension {
    function manager() external view returns (IBaseManager);
}

// Dependency file: contracts/lib/MutualUpgrade.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


*/

// pragma solidity 0.6.10;

/**
 * @title MutualUpgrade
 * @author Set Protocol
 *
 * The MutualUpgrade contract contains a modifier for handling mutual upgrades between two parties
 */
contract MutualUpgrade {
    /* ============ State Variables ============ */

    // Mapping of upgradable units and if upgrade has been initialized by other party
    mapping(bytes32 => bool) public mutualUpgrades;

    /* ============ Events ============ */

    event MutualUpgradeRegistered(
        bytes32 _upgradeHash
    );

    /* ============ Modifiers ============ */

    modifier mutualUpgrade(address _signerOne, address _signerTwo) {
        require(
            msg.sender == _signerOne || msg.sender == _signerTwo,
            "Must be authorized address"
        );

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The upgrade hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (!mutualUpgrades[expectedHash]) {
            bytes32 newHash = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualUpgrades[newHash] = true;

            emit MutualUpgradeRegistered(newHash);

            return;
        }

        delete mutualUpgrades[expectedHash];

        // Run the rest of the upgrades
        _;
    }

    /* ============ Internal Functions ============ */

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns(address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}


// Root file: contracts/manager/BaseManagerV2.sol

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

// import { Address } from "@openzeppelin/contracts/utils/Address.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// import { AddressArrayUtils } from "contracts/lib/AddressArrayUtils.sol";
// import { IExtension } from "contracts/interfaces/IExtension.sol";
// import { ISetToken } from "contracts/interfaces/ISetToken.sol";
// import { MutualUpgrade } from "contracts/lib/MutualUpgrade.sol";


/**
 * @title BaseManagerV2
 * @author Set Protocol
 *
 * Smart contract manager that contains permissions and admin functionality. Implements IIP-64, supporting
 * a registry of protected modules that can only be upgraded with methodologist consent.
 */
contract BaseManagerV2 is MutualUpgrade {
    using Address for address;
    using AddressArrayUtils for address[];
    using SafeERC20 for IERC20;

    /* ============ Struct ========== */

    struct ProtectedModule {
        bool isProtected;                               // Flag set to true if module is protected
        address[] authorizedExtensionsList;             // List of Extensions authorized to call module
        mapping(address => bool) authorizedExtensions;  // Map of extensions authorized to call module
    }

    /* ============ Events ============ */

    event ExtensionAdded(
        address _extension
    );

    event ExtensionRemoved(
        address _extension
    );

    event MethodologistChanged(
        address _oldMethodologist,
        address _newMethodologist
    );

    event OperatorChanged(
        address _oldOperator,
        address _newOperator
    );

    event ExtensionAuthorized(
        address _module,
        address _extension
    );

    event ExtensionAuthorizationRevoked(
        address _module,
        address _extension
    );

    event ModuleProtected(
        address _module,
        address[] _extensions
    );

    event ModuleUnprotected(
        address _module
    );

    event ReplacedProtectedModule(
        address _oldModule,
        address _newModule,
        address[] _newExtensions
    );

    event EmergencyReplacedProtectedModule(
        address _module,
        address[] _extensions
    );

    event EmergencyRemovedProtectedModule(
        address _module
    );

    event EmergencyResolved();

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not a listed extension
     */
    modifier onlyExtension() {
        require(isExtension[msg.sender], "Must be extension");
        _;
    }

    /**
     * Throws if contract is in an emergency state following a unilateral operator removal of a
     * protected module.
     */
    modifier upgradesPermitted() {
        require(emergencies == 0, "Upgrades paused by emergency");
        _;
    }

    /**
     * Throws if contract is *not* in an emergency state. Emergency replacement and resolution
     * can only happen in an emergency
     */
    modifier onlyEmergency() {
        require(emergencies > 0, "Not in emergency");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of SetToken
    ISetToken public setToken;

    // Array of listed extensions
    address[] internal extensions;

    // Mapping to check if extension is added
    mapping(address => bool) public isExtension;

    // Address of operator which typically executes manager only functions on Set Protocol modules
    address public operator;

    // Address of methodologist which serves as providing methodology for the index
    address public methodologist;

    // Counter incremented when the operator "emergency removes" a protected module. Decremented
    // when methodologist executes an "emergency replacement". Operator can only add modules and
    // extensions when `emergencies` is zero. Emergencies can only be declared "over" by mutual agreement
    // between operator and methodologist or by the methodologist alone via `resolveEmergency`
    uint256 public emergencies;

    // Mapping of protected modules. These cannot be called or removed except by mutual upgrade.
    mapping(address => ProtectedModule) public protectedModules;

    // List of protected modules, for iteration. Used when checking that an extension removal
    // can happen without methodologist approval
    address[] public protectedModulesList;

    // Boolean set when methodologist authorizes initialization after contract deployment.
    // Must be true to call via `interactManager`.
    bool public initialized;

    /* ============ Constructor ============ */

    constructor(
        ISetToken _setToken,
        address _operator,
        address _methodologist
    )
        public
    {
        setToken = _setToken;
        operator = _operator;
        methodologist = _methodologist;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY METHODOLOGIST : Called by the methodologist to enable contract. All `interactManager`
     * calls revert until this is invoked. Lets methodologist review and authorize initial protected
     * module settings.
     */
    function authorizeInitialization() external onlyMethodologist {
        require(!initialized, "Initialization authorized");
        initialized = true;
    }

    /**
     * MUTUAL UPGRADE: Update the SetToken manager address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newManager           New manager address
     */
    function setManager(address _newManager) external mutualUpgrade(operator, methodologist) {
        require(_newManager != address(0), "Zero address not valid");
        setToken.setManager(_newManager);
    }

    /**
     * OPERATOR ONLY: Add a new extension that the BaseManager can call.
     *
     * @param _extension           New extension to add
     */
    function addExtension(address _extension) external upgradesPermitted onlyOperator {
        require(!isExtension[_extension], "Extension already exists");
        require(address(IExtension(_extension).manager()) == address(this), "Extension manager invalid");

        _addExtension(_extension);
    }

    /**
     * OPERATOR ONLY: Remove an existing extension tracked by the BaseManager.
     *
     * @param _extension           Old extension to remove
     */
    function removeExtension(address _extension) external onlyOperator {
        require(isExtension[_extension], "Extension does not exist");
        require(!_isAuthorizedExtension(_extension), "Extension used by protected module");

        extensions.removeStorage(_extension);

        isExtension[_extension] = false;

        emit ExtensionRemoved(_extension);
    }

    /**
     * MUTUAL UPGRADE: Authorizes an extension for a protected module. Operator and Methodologist must
     * each call this function to execute the update. Adds extension to manager if not already present.
     *
     * @param _module           Module to authorize extension for
     * @param _extension          Extension to authorize for module
     */
    function authorizeExtension(address _module, address _extension)
        external
        mutualUpgrade(operator, methodologist)
    {
        require(protectedModules[_module].isProtected, "Module not protected");
        require(!protectedModules[_module].authorizedExtensions[_extension], "Extension already authorized");

        _authorizeExtension(_module, _extension);

        emit ExtensionAuthorized(_module, _extension);
    }

    /**
     * MUTUAL UPGRADE: Revokes extension authorization for a protected module. Operator and Methodologist
     * must each call this function to execute the update. In order to remove the extension completely
     * from the contract removeExtension must be called by the operator.
     *
     * @param _module           Module to revoke extension authorization for
     * @param _extension          Extension to revoke authorization of
     */
    function revokeExtensionAuthorization(address _module, address _extension)
        external
        mutualUpgrade(operator, methodologist)
    {
        require(protectedModules[_module].isProtected, "Module not protected");
        require(isExtension[_extension], "Extension does not exist");
        require(protectedModules[_module].authorizedExtensions[_extension], "Extension not authorized");

        protectedModules[_module].authorizedExtensions[_extension] = false;
        protectedModules[_module].authorizedExtensionsList.removeStorage(_extension);

        emit ExtensionAuthorizationRevoked(_module, _extension);
    }

    /**
     * ADAPTER ONLY: Interact with a module registered on the SetToken. Manager initialization must
     * have been authorized by methodologist. Extension making this call must be authorized
     * to call module if module is protected.
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactManager(address _module, bytes memory _data) external onlyExtension {
        require(initialized, "Manager not initialized");
        require(_module != address(setToken), "Extensions cannot call SetToken");
        require(_senderAuthorizedForModule(_module, msg.sender), "Extension not authorized for module");

        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * OPERATOR ONLY: Transfers _tokens held by the manager to _destination. Can be used to
     * recover anything sent here accidentally. In BaseManagerV2, extensions should
     * be the only contracts designated as `feeRecipient` in fee modules.
     *
     * @param _token           ERC20 token to send
     * @param _destination     Address receiving the tokens
     * @param _amount          Quantity of tokens to send
     */
    function transferTokens(address _token, address _destination, uint256 _amount) external onlyExtension {
        IERC20(_token).safeTransfer(_destination, _amount);
    }

    /**
     * OPERATOR ONLY: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external upgradesPermitted onlyOperator {
        setToken.addModule(_module);
    }

    /**
     * OPERATOR ONLY: Remove a new module from the SetToken. Any extensions associated with this
     * module need to be removed in separate transactions via removeExtension.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOperator {
        require(!protectedModules[_module].isProtected, "Module protected");
        setToken.removeModule(_module);
    }

    /**
     * OPERATOR ONLY: Marks a currently protected module as unprotected and deletes its authorized
     * extension registries. Removes module from the SetToken. Increments the `emergencies` counter,
     * prohibiting any operator-only module or extension additions until `emergencyReplaceProtectedModule`
     * is executed or `resolveEmergency` is called by the methodologist.
     *
     * Called by operator when a module must be removed immediately for security reasons and it's unsafe
     * to wait for a `mutualUpgrade` process to play out.
     *
     * NOTE: If removing a fee module, you can ensure all fees are distributed by calling distribute
     * on the module's de-authorized fee extension after this call.
     *
     * @param _module           Module to remove
     */
    function emergencyRemoveProtectedModule(address _module) external onlyOperator {
        _unProtectModule(_module);
        setToken.removeModule(_module);
        emergencies += 1;

        emit EmergencyRemovedProtectedModule(_module);
    }

    /**
     * OPERATOR ONLY: Marks an existing module as protected and authorizes extensions for
     * it, adding them if necessary. Adds module to the protected modules list
     *
     * The operator uses this when they're adding new features and want to assure the methodologist
     * they won't be unilaterally changed in the future. Cannot be called during an emergency because
     * methodologist needs to explicitly approve protection arrangements under those conditions.
     *
     * NOTE: If adding a fee extension while protecting a fee module, it's // important to set the
     * module `feeRecipient` to the new extension's address (ideally before this call).
     *
     * @param  _module          Module to protect
     * @param  _extensions        Array of extensions to authorize for protected module
     */
    function protectModule(address _module, address[] memory _extensions)
        external
        upgradesPermitted
        onlyOperator
    {
        require(setToken.getModules().contains(_module), "Module not added yet");
        _protectModule(_module, _extensions);

        emit ModuleProtected(_module, _extensions);
    }

    /**
     * METHODOLOGIST ONLY: Marks a currently protected module as unprotected and deletes its authorized
     * extension registries. Removes old module from the protected modules list.
     *
     * Called by the methodologist when they want to cede control over a protected module without triggering
     * an emergency (for example, to remove it because its dead).
     *
     * @param  _module          Module to revoke protections for
     */
    function unProtectModule(address _module) external onlyMethodologist {
        _unProtectModule(_module);

        emit ModuleUnprotected(_module);
    }

    /**
     * MUTUAL UPGRADE: Replaces a protected module. Operator and Methodologist must each call this
     * function to execute the update.
     *
     * > Marks a currently protected module as unprotected
     * > Deletes its authorized extension registries.
     * > Removes old module from SetToken.
     * > Adds new module to SetToken.
     * > Marks `_newModule` as protected and authorizes new extensions for it.
     *
     * Used when methodologists wants to guarantee that an existing protection arrangement is replaced
     * with a suitable substitute (ex: upgrading a StreamingFeeSplitExtension).
     *
     * NOTE: If replacing a fee module, it's necessary to set the module `feeRecipient` to be
     * the new fee extension address after this call. Any fees remaining in the old module's
     * de-authorized extensions can be distributed by calling `distribute()` on the old extension.
     *
     * @param _oldModule        Module to remove
     * @param _newModule        Module to add in place of removed module
     * @param _newExtensions      Extensions to authorize for new module
     */
    function replaceProtectedModule(address _oldModule, address _newModule, address[] memory _newExtensions)
        external
        mutualUpgrade(operator, methodologist)
    {
        _unProtectModule(_oldModule);

        setToken.removeModule(_oldModule);
        setToken.addModule(_newModule);

        _protectModule(_newModule, _newExtensions);

        emit ReplacedProtectedModule(_oldModule, _newModule, _newExtensions);
    }

    /**
     * MUTUAL UPGRADE & EMERGENCY ONLY: Replaces a module the operator has removed with
     * `emergencyRemoveProtectedModule`. Operator and Methodologist must each call this function to
     *  execute the update.
     *
     * > Adds new module to SetToken.
     * > Marks `_newModule` as protected and authorizes new extensions for it.
     * > Adds `_newModule` to protectedModules list.
     * > Decrements the emergencies counter,
     *
     * Used when methodologist wants to guarantee that a protection arrangement which was
     * removed in an emergency is replaced with a suitable substitute. Operator's ability to add modules
     * or extensions is restored after invoking this method (if this is the only emergency.)
     *
     * NOTE: If replacing a fee module, it's necessary to set the module `feeRecipient` to be
     * the new fee extension address after this call. Any fees remaining in the old module's
     * de-authorized extensions can be distributed by calling `accrueFeesAndDistribute` on the old extension.
     *
     * @param _module          Module to add in place of removed module
     * @param _extensions      Array of extensions to authorize for replacement module
     */
    function emergencyReplaceProtectedModule(
        address _module,
        address[] memory _extensions
    )
        external
        mutualUpgrade(operator, methodologist)
        onlyEmergency
    {
        setToken.addModule(_module);
        _protectModule(_module, _extensions);

        emergencies -= 1;

        emit EmergencyReplacedProtectedModule(_module, _extensions);
    }

    /**
     * METHODOLOGIST ONLY & EMERGENCY ONLY: Decrements the emergencies counter.
     *
     * Allows a methodologist to exit a state of emergency without replacing a protected module that
     * was removed. This could happen if the module has no viable substitute or operator and methodologist
     * agree that restoring normal operations is the best way forward.
     */
    function resolveEmergency() external onlyMethodologist onlyEmergency {
        emergencies -= 1;

        emit EmergencyResolved();
    }

    /**
     * METHODOLOGIST ONLY: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function setMethodologist(address _newMethodologist) external onlyMethodologist {
        emit MethodologistChanged(methodologist, _newMethodologist);

        methodologist = _newMethodologist;
    }

    /**
     * OPERATOR ONLY: Update the operator address
     *
     * @param _newOperator           New operator address
     */
    function setOperator(address _newOperator) external onlyOperator {
        emit OperatorChanged(operator, _newOperator);

        operator = _newOperator;
    }

    /* ============ External Getters ============ */

    function getExtensions() external view returns(address[] memory) {
        return extensions;
    }

    function getAuthorizedExtensions(address _module) external view returns (address[] memory) {
        return protectedModules[_module].authorizedExtensionsList;
    }

    function isAuthorizedExtension(address _module, address _extension) external view returns (bool) {
        return protectedModules[_module].authorizedExtensions[_extension];
    }

    function getProtectedModules() external view returns (address[] memory) {
        return protectedModulesList;
    }

    /* ============ Internal ============ */


    /**
     * Add a new extension that the BaseManager can call.
     */
    function _addExtension(address _extension) internal {
        extensions.push(_extension);

        isExtension[_extension] = true;

        emit ExtensionAdded(_extension);
    }

    /**
     * Marks a currently protected module as unprotected and deletes it from authorized extension
     * registries. Removes module from the SetToken.
     */
    function _unProtectModule(address _module) internal {
        require(protectedModules[_module].isProtected, "Module not protected");

        // Clear mapping and array entries in struct before deleting mapping entry
        for (uint256 i = 0; i < protectedModules[_module].authorizedExtensionsList.length; i++) {
            address extension = protectedModules[_module].authorizedExtensionsList[i];
            protectedModules[_module].authorizedExtensions[extension] = false;
        }

        delete protectedModules[_module];

        protectedModulesList.removeStorage(_module);
    }

    /**
     * Adds new module to SetToken. Marks `_newModule` as protected and authorizes
     * new extensions for it. Adds `_newModule` module to protectedModules list.
     */
    function _protectModule(address _module, address[] memory _extensions) internal {
        require(!protectedModules[_module].isProtected, "Module already protected");

        protectedModules[_module].isProtected = true;
        protectedModulesList.push(_module);

        for (uint i = 0; i < _extensions.length; i++) {
            _authorizeExtension(_module, _extensions[i]);
        }
    }

    /**
     * Adds extension if not already added and marks extension as authorized for module
     */
    function _authorizeExtension(address _module, address _extension) internal {
        if (!isExtension[_extension]) {
            _addExtension(_extension);
        }

        protectedModules[_module].authorizedExtensions[_extension] = true;
        protectedModules[_module].authorizedExtensionsList.push(_extension);
    }

    /**
     * Searches the extension mappings of each protected modules to determine if an extension
     * is authorized by any of them. Authorized extensions cannot be unilaterally removed by
     * the operator.
     */
    function _isAuthorizedExtension(address _extension) internal view returns (bool) {
        for (uint256 i = 0; i < protectedModulesList.length; i++) {
            if (protectedModules[protectedModulesList[i]].authorizedExtensions[_extension]) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks if `_sender` (an extension) is allowed to call a module (which may be protected)
     */
    function _senderAuthorizedForModule(address _module, address _sender) internal view returns (bool) {
        if (protectedModules[_module].isProtected) {
            return protectedModules[_module].authorizedExtensions[_sender];
        }

        return true;
    }
}