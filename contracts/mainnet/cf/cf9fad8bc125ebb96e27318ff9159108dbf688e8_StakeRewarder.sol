/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/utils/math/SafeMath.sol


pragma solidity ^0.8.0;

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

// File: openzeppelin-solidity/contracts/utils/Context.sol


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

// File: openzeppelin-solidity/contracts/access/Ownable.sol


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

// File: openzeppelin-solidity/contracts/utils/Address.sol


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

// File: openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol


pragma solidity ^0.8.0;



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

// File: openzeppelin-solidity/contracts/utils/introspection/IERC165.sol


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

// File: openzeppelin-solidity/contracts/utils/introspection/ERC165.sol


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

// File: openzeppelin-solidity/contracts/utils/Strings.sol


pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// File: openzeppelin-solidity/contracts/access/AccessControl.sol


pragma solidity ^0.8.0;

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
        mapping (address => bool) members;
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
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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

// File: contracts/VestingMultiVault.sol

pragma solidity ^0.8.0;





/**
 * @title VestingMultiVault
 * @dev A token vesting contract that will release tokens gradually like a
 * standard equity vesting schedule, with a cliff and vesting period but no
 * arbitrary restrictions on the frequency of claims. Optionally has an initial
 * tranche claimable immediately after the cliff expires (in addition to any
 * amounts that would have vested up to that point but didn't due to a cliff).
 */
contract VestingMultiVault is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Issued(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 duration
    );

    event Released(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 amount,
        uint256 remaining
    );
    
    event Revoked(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 allocationAmount,
        uint256 revokedAmount
    );

    struct Allocation {
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 total;
        uint256 claimed;
        uint256 initial;
    }

    // The token being vested.
    IERC20 public immutable token;

    // The amount unclaimed for an address, whether or not vested.
    mapping(address => uint256) public pendingAmount;

    // The allocations assigned to an address.
    mapping(address => Allocation[]) public userAllocations;

    // The precomputed hash of the "ISSUER" role.
    bytes32 public constant ISSUER = keccak256("ISSUER");

    /**
     * @dev Creates a vesting contract that releases allocations of a token
     * over an arbitrary time period with support for tranches and cliffs.
     * @param _token The ERC-20 token to be vested
     */
    constructor(IERC20 _token) {
        token = _token;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER, msg.sender);
    }

    /**
     * @dev Creates a new allocation for a beneficiary. Tokens are released
     * linearly over time until a given number of seconds have passed since the
     * start of the vesting schedule. Callable only by issuers.
     * @param _beneficiary The address to which tokens will be released
     * @param _amount The amount of the allocation (in wei)
     * @param _startAt The unix timestamp at which the vesting may begin
     * @param _cliff The number of seconds after _startAt before which no vesting occurs
     * @param _duration The number of seconds after which the entire allocation is vested
     * @param _initialPct The percentage of the allocation initially available (integer, 0-100)
     */
    function issue(
        address _beneficiary,
        uint256 _amount,
        uint256 _startAt,
        uint256 _cliff,
        uint256 _duration,
        uint256 _initialPct
    ) public onlyRole(ISSUER) {
        require(token.allowance(msg.sender, address(this)) >= _amount, "Token allowance not sufficient");
        require(_beneficiary != address(0), "Cannot grant tokens to the zero address");
        require(_cliff <= _duration, "Cliff must not exceed duration");
        require(_initialPct <= 100, "Initial release percentage must be an integer 0 to 100 (inclusive)");

        // Pull the number of tokens required for the allocation.
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Increase the total pending for the address.
        pendingAmount[_beneficiary] = pendingAmount[_beneficiary].add(_amount);

        // Push the new allocation into the stack.
        userAllocations[_beneficiary].push(Allocation({
            claimed:    0,
            cliff:      _cliff,
            duration:   _duration,
            initial:    _amount.mul(_initialPct).div(100),
            start:      _startAt,
            total:      _amount
        }));
        
        emit Issued(
            _beneficiary,
            userAllocations[_beneficiary].length - 1,
            _amount,
            _startAt,
            _cliff,
            _duration
        );
    }
    
    /**
     * @dev Revokes an existing allocation. Any unclaimed tokens are recalled
     * and sent to the caller. Callable only be issuers.
     * @param _beneficiary The address whose allocation is to be revoked
     * @param _id The allocation ID to revoke
     */
    function revoke(
        address _beneficiary,
        uint256 _id
    ) public onlyRole(ISSUER) {
        Allocation storage allocation = userAllocations[_beneficiary][_id];
        
        // Calculate the remaining amount.
        uint256 total = allocation.total;
        uint256 remainder = total.sub(allocation.claimed);

        // Update the total pending for the address.
        pendingAmount[_beneficiary] = pendingAmount[_beneficiary].sub(remainder);

        // Update the allocation to be claimed in full.
        allocation.claimed = total;
        
        // Transfer the tokens vested 
        token.safeTransfer(msg.sender, remainder);
        emit Revoked(
            _beneficiary,
            _id,
            total,
            remainder
        );
    }

    /**
     * @dev Transfers vested tokens from an allocation to its beneficiary. Callable by anyone.
     * @param _beneficiary The address that has vested tokens
     * @param _id The vested allocation index
     */
    function release(
        address _beneficiary,
        uint256 _id
    ) public {
        Allocation storage allocation = userAllocations[_beneficiary][_id];

        // Calculate the releasable amount.
        uint256 amount = _releasableAmount(allocation);
        require(amount > 0, "Nothing to release");
        
        // Add the amount to the allocation's total claimed.
        allocation.claimed = allocation.claimed.add(amount);

        // Subtract the amount from the beneficiary's total pending.
        pendingAmount[_beneficiary] = pendingAmount[_beneficiary].sub(amount);

        // Transfer the tokens to the beneficiary.
        token.safeTransfer(_beneficiary, amount);

        emit Released(
            _beneficiary,
            _id,
            amount,
            allocation.total.sub(allocation.claimed)
        );
    }
    
    /**
     * @dev Transfers vested tokens from any number of allocations to their beneficiary. Callable by anyone. May be gas-intensive.
     * @param _beneficiary The address that has vested tokens
     * @param _ids The vested allocation indexes
     */
    function releaseMultiple(
        address _beneficiary,
        uint256[] calldata _ids
    ) external {
        for (uint256 i = 0; i < _ids.length; i++) {
            release(_beneficiary, _ids[i]);
        }
    }
    
    /**
     * @dev Gets the number of allocations issued for a given address.
     * @param _beneficiary The address to check for allocations
     */
    function allocationCount(
        address _beneficiary
    ) public view returns (uint256 count) {
        return userAllocations[_beneficiary].length;
    }
    
    /**
     * @dev Calculates the amount that has already vested but has not yet been released for a given address.
     * @param _beneficiary Address to check
     * @param _id The allocation index
     */
    function releasableAmount(
        address _beneficiary,
        uint256 _id
    ) public view returns (uint256 amount) {
        Allocation storage allocation = userAllocations[_beneficiary][_id];
        return _releasableAmount(allocation);
    }
    
    /**
     * @dev Gets the total releasable for a given address. Likely gas-intensive, not intended for contract use.
     * @param _beneficiary Address to check
     */
    function totalReleasableAount(
        address _beneficiary
    ) public view returns (uint256 amount) {
        for (uint256 i = 0; i < allocationCount(_beneficiary); i++) {
            amount = amount.add(releasableAmount(_beneficiary, i));
        }
        return amount;
    }
    
    /**
     * @dev Calculates the amount that has vested to date.
     * @param _beneficiary Address to check
     * @param _id The allocation index
     */
    function vestedAmount(
        address _beneficiary,
        uint256 _id
    ) public view returns (uint256) {
        Allocation storage allocation = userAllocations[_beneficiary][_id];
        return _vestedAmount(allocation);
    }
    
    /**
     * @dev Gets the total ever vested for a given address. Likely gas-intensive, not intended for contract use.
     * @param _beneficiary Address to check
     */
    function totalVestedAount(
        address _beneficiary
    ) public view returns (uint256 amount) {
        for (uint256 i = 0; i < allocationCount(_beneficiary); i++) {
            amount = amount.add(vestedAmount(_beneficiary, i));
        }
        return amount;
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param allocation Allocation to calculate against
     */
    function _releasableAmount(
        Allocation storage allocation
    ) internal view returns (uint256) {
        return _vestedAmount(allocation).sub(allocation.claimed);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param allocation Allocation to calculate against
     */
    function _vestedAmount(
        Allocation storage allocation
    ) internal view returns (uint256 amount) {
        if (block.timestamp < allocation.start.add(allocation.cliff)) {
            // Nothing is vested until after the start time + cliff length.
            amount = 0;
        } else if (block.timestamp >= allocation.start.add(allocation.duration)) {
            // The entire amount has vested if the entire duration has elapsed.
            amount = allocation.total;
        } else {
            // The initial tranche is available once the cliff expires, plus any portion of
            // tokens which have otherwise become vested as of the current block's timestamp.
            amount = allocation.initial.add(
                allocation.total
                    .sub(allocation.initial)
                    .sub(amount)
                    .mul(block.timestamp.sub(allocation.start))
                    .div(allocation.duration)
            );
        }
        
        return amount;
    }
}

// File: contracts/StakeRewarder.sol

pragma solidity ^0.8.5;

/**
 * @title StakeRewarder
 * @dev This contract distributes rewards to depositors of supported tokens.
 * It's based on Sushi's MasterChef v1, but notably only serves what's already
 * available: no new tokens can be created. It's just a restaurant, not a farm.
 */
contract StakeRewarder is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint256 amount;     // Quantity of tokens the user has staked.
        uint256 rewardDebt; // Reward debt. See explanation below.
        // We do some fancy math here. Basically, any point in time, the
        // amount of rewards entitled to a user but is pending to be distributed is:
        //
        //   pendingReward = (stakedAmount * pool.accPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens in a pool:
        //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User's pending rewards are issued (greatly simplifies accounting).
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    
    struct PoolInfo {
        IERC20 token;            // Address of the token contract.
        uint256 weight;          // Weight points assigned to this pool.
        uint256 power;           // The multiplier for determining "staking power".
        uint256 total;           // Total number of tokens staked.
        uint256 accPerShare;     // Accumulated rewards per share (times 1e12).
        uint256 lastRewardBlock; // Last block where rewards were calculated.
    }
    
    // Distribution vault.
    VestingMultiVault public immutable vault;
    
    // Reward configuration.
    IERC20 public immutable rewardToken;
    uint256 public rewardPerBlock;
    uint256 public vestingCliff;
    uint256 public vestingDuration;
    
    // Housekeeping for each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Underpaid rewards owed to a user.
    mapping(address => uint256) public underpayment;
    
    // The sum of weights across all staking tokens.
    uint256 public totalWeight = 0;
    
    // The block number when staking starts.
    uint256 public startBlock;
    
    event TokenAdded(address indexed token, uint256 weight, uint256 totalWeight);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyReclaim(address indexed user, address token, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev Create a staking contract that rewards depositors using its own token balance
     * and optionally vests rewards over time.
     * @param _rewardToken The token to be distributed as rewards.
     * @param _rewardPerBlock The quantity of reward tokens accrued per block.
     * @param _startBlock The first block at which staking is allowed.
     * @param _vestingCliff The number of seconds until issued rewards begin vesting.
     * @param _vestingDuration The number of seconds after issuance until vesting is completed.
     * @param _vault The VestingMultiVault that is ultimately responsible for reward distribution.
     */
    constructor(
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _vestingCliff,
        uint256 _vestingDuration,
        VestingMultiVault _vault
    ) {
        // Set the initial reward config
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        vestingCliff = _vestingCliff;
        vestingDuration = _vestingDuration;
        
        // Set the vault and reward token (immutable after creation)
        vault = _vault;
        rewardToken = _rewardToken;
        
        // Approve the vault to pull reward tokens
        _rewardToken.approve(address(_vault), 2**256 - 1);
    }

    /**
     * @dev Adds a new staking pool to the stack. Can only be called by the owner.
     * @param _token The token to be staked.
     * @param _weight The weight of this pool (used to determine proportion of rewards relative to the total weight).
     * @param _power The power factor of this pool (used as a multiple of tokens staked, e.g. for determining voting power).
     * @param _shouldUpdate Whether to update all pools first.
     */
    function createPool(
        IERC20 _token,
        uint256 _weight,
        uint256 _power,
        bool _shouldUpdate
    ) public onlyOwner {
        if (_shouldUpdate) {
            pokePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalWeight = totalWeight.add(_weight);
        poolInfo.push(
            PoolInfo({
                token: _token,
                weight: _weight,
                power: _power,
                total: 0,
                accPerShare: 0,
                lastRewardBlock: lastRewardBlock
            })
        );
    }

    /**
     * @dev Update the given staking pool's weight and power. Can only be called by the owner.
     * @param _pid The pool identifier.
     * @param _weight The weight of this pool (used to determine proportion of rewards relative to the total weight).
     * @param _power The power of this pool's token (used as a multiplier of tokens staked, e.g. for voting).
     * @param _shouldUpdate Whether to update all pools first.
     */ 
    function updatePool(
        uint256 _pid,
        uint256 _weight,
        uint256 _power,
        bool _shouldUpdate
    ) public onlyOwner {
        if (_shouldUpdate) {
            pokePools();
        }
        
        totalWeight = totalWeight.sub(poolInfo[_pid].weight).add(
            _weight
        );

        poolInfo[_pid].weight = _weight;
        poolInfo[_pid].power = _power;
    }
    
    /**
     * @dev Update the reward per block. Can only be called by the owner.
     * @param _rewardPerBlock The total quantity to distribute per block.
     */
    function setRewardPerBlock(
        uint256 _rewardPerBlock
    ) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }
    
    /**
     * @dev Update the vesting rules for rewards. Can only be called by the owner.
     * @param _duration the number of seconds over which vesting occurs (see VestingMultiVault)
     * @param _cliff the number of seconds before any release occurs (see VestingMultiVault)
     */
    function setVestingRules(
        uint256 _duration,
        uint256 _cliff
    ) public onlyOwner {
        vestingDuration = _duration;
        vestingCliff = _cliff;
    }

    /**
     * @dev Calculate elapsed blocks between `_from` and `_to`.
     * @param _from The starting block.
     * @param _to The ending block.
     */
    function duration(
        uint256 _from,
        uint256 _to
    ) public pure returns (uint256) {
        return _to.sub(_from);
    }
    
    function totalPendingRewards(
        address _beneficiary
    ) public view returns (uint256 total) {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            total = total.add(pendingRewards(pid, _beneficiary));
        }

        return total;
    }

    /**
     * @dev View function to see pending rewards for an address. Likely gas intensive.
     * @param _pid The pool identifier.
     * @param _beneficiary The address to check.
     */
    function pendingRewards(
        uint256 _pid,
        address _beneficiary
    ) public view returns (uint256 amount) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_beneficiary];
        uint256 accPerShare = pool.accPerShare;
        uint256 tokenSupply = pool.total;
        
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 reward = duration(pool.lastRewardBlock, block.number)
                .mul(rewardPerBlock)
                .mul(pool.weight)
                .div(totalWeight);

            accPerShare = accPerShare.add(
                reward.mul(1e12).div(tokenSupply)
            );
        }

        return user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev Gets the sum of power for every pool. Likely gas intensive.
     * @param _beneficiary The address to check.
     */
    function totalPower(
        address _beneficiary
    ) public view returns (uint256 total) {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            total = total.add(power(pid, _beneficiary));
        }

        return total;
    }

    /**
     * @dev Gets power for a single pool.
     * @param _pid The pool identifier.
     * @param _beneficiary The address to check.
     */
    function power(
        uint256 _pid,
        address _beneficiary
    ) public view returns (uint256 amount) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_beneficiary];
        return pool.power.mul(user.amount);
    }

    /**
     * @dev Update all pools. Callable by anyone. Could be gas intensive.
     */
    function pokePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            pokePool(pid);
        }
    }

    /**
     * @dev Update rewards of the given pool to be up-to-date. Callable by anyone.
     * @param _pid The pool identifier.
     */
    function pokePool(
        uint256 _pid
    ) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 tokenSupply = pool.total;
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 reward = duration(pool.lastRewardBlock, block.number)
            .mul(rewardPerBlock)
            .mul(pool.weight)
            .div(totalWeight);

        pool.accPerShare = pool.accPerShare.add(
            reward.mul(1e12).div(tokenSupply)
        );

        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Claim rewards not yet distributed for an address. Callable by anyone.
     * @param _pid The pool identifier.
     * @param _beneficiary The address to claim for.
     */
    function claim(
        uint256 _pid,
        address _beneficiary
    ) public {
        // make sure the pool is up-to-date
        pokePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_beneficiary];

        _claim(pool, user, _beneficiary);
    }
    
    /**
     * @dev Claim rewards from multiple pools. Callable by anyone.
     * @param _pids An array of pool identifiers.
     * @param _beneficiary The address to claim for.
     */
    function claimMultiple(
        uint256[] calldata _pids,
        address _beneficiary
    ) external {
        for (uint256 i = 0; i < _pids.length; i++) {
            claim(_pids[i], _beneficiary);
        }
    }

    /**
     * @dev Stake tokens to earn a share of rewards.
     * @param _pid The pool identifier.
     * @param _amount The number of tokens to deposit.
     */
    function deposit(
        uint256 _pid,
        uint256 _amount
    ) public {
        require(_amount > 0, "deposit: only non-zero amounts allowed");
        
        // make sure the pool is up-to-date
        pokePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        // deliver any pending rewards
        _claim(pool, user, msg.sender);
        
        // pull in user's staked assets
        pool.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        // update the pool's total deposit
        pool.total = pool.total.add(_amount);
        
        // update user's deposit and reward info
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw staked tokens and any pending rewards.
     */
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) public {
        require(_amount > 0, "withdraw: only non-zero amounts allowed");

        // make sure the pool is up-to-date
        pokePool(_pid);
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "withdraw: amount too large");
        
        // deliver any pending rewards
        _claim(pool, user, msg.sender);

        // update the pool's total deposit
        pool.total = pool.total.sub(_amount);
        
        // update the user's deposit and reward info
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        
        // send back the staked assets
        pool.token.safeTransfer(address(msg.sender), _amount);
        
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw staked tokens and forego any unclaimed rewards. This is a fail-safe.
     */
    function emergencyWithdraw(
        uint256 _pid
    ) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        
        // reset everything to zero
        user.amount = 0;
        user.rewardDebt = 0;
        underpayment[msg.sender] = 0;

        // update the pool's total deposit
        pool.total = pool.total.sub(amount);
        
        // send back the staked assets
        pool.token.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
    /**
     * @dev Reclaim stuck tokens (e.g. unexpected external rewards). This is a fail-safe.
     */
    function emergencyReclaim(
        IERC20 _token,
        uint256 _amount
    ) public onlyOwner {
        if (_amount == 0) {
            _amount = _token.balanceOf(address(this));
        }
        
        _token.transfer(msg.sender, _amount);
        emit EmergencyReclaim(msg.sender, address(_token), _amount);
    }
    
    /**
     * @dev Gets the length of the pools array.
     */
    function poolLength() external view returns (uint256 length) {
        return poolInfo.length;
    }
    
    /**
     * @dev Claim rewards not yet distributed for an address.
     * @param pool The staking pool issuing rewards.
     * @param user The staker who earned them.
     * @param to The address to pay. 
     */
    function _claim(
        PoolInfo storage pool,
        UserInfo storage user,
        address to
    ) internal {
        if (user.amount > 0) {
            // calculate the pending reward
            uint256 pending = user.amount
                .mul(pool.accPerShare)
                .div(1e12)
                .sub(user.rewardDebt)
                .add(underpayment[to]);
            
            // send the rewards out
            uint256 payout = _safelyDistribute(to, pending);
            if (payout < pending) {
                underpayment[to] = pending.sub(payout);
            } else {
                underpayment[to] = 0;
            }
            
            emit Claim(to, payout);
        }
    }
    
    /**
     * @dev Safely distribute at most the amount of tokens in holding.
     */
    function _safelyDistribute(
        address _to,
        uint256 _amount
    ) internal returns (uint256 amount) {
        uint256 available = rewardToken.balanceOf(address(this));
        amount = _amount > available ? available : _amount;
        
        vault.issue(
            _to,                // address _beneficiary,
            _amount,            // uint256 _amount,
            block.timestamp,    // uint256 _startAt,
            vestingCliff,       // uint256 _cliff,
            vestingDuration,    // uint256 _duration,
            0                   // uint256 _initialPct
        );
        
        return amount;
    }
}