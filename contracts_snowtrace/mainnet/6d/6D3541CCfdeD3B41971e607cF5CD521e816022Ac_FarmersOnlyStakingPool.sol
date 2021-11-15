/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

/**
 * XXX
 * 𝗖𝗼𝗻𝘁𝗿𝗮𝗰𝘁 𝗼𝗿𝗶𝗴𝗶𝗻𝗮𝗹𝗹𝘆 𝗰𝗿𝗲𝗮𝘁𝗲𝗱 𝗯𝘆 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆 𝗗𝗲𝘃
 * 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆: 𝗮𝗻 𝗶𝗻𝗻𝗼𝘃𝗮𝘁𝗶𝘃𝗲 𝗗𝗲𝗙𝗶 𝗽𝗿𝗼𝘁𝗼𝗰𝗼𝗹 𝗳𝗼𝗿 𝗬𝗶𝗲𝗹𝗱 𝗙𝗮𝗿𝗺𝗶𝗻𝗴 𝗼𝗻 𝗔𝘃𝗮𝗹𝗮𝗻𝗰𝗵𝗲
 * 
 * 𝗟𝗶𝗻𝗸𝘀:
 * 𝗵𝘁𝘁𝗽𝘀://𝗳𝗮𝗿𝗺𝗲𝗿𝘀𝗼𝗻𝗹𝘆.𝗳𝗮𝗿𝗺
 * 𝗵𝘁𝘁𝗽𝘀://𝘁.𝗺𝗲/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝟮
 * 𝗵𝘁𝘁𝗽𝘀://𝘁𝘄𝗶𝘁𝘁𝗲𝗿.𝗰𝗼𝗺/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝗗𝗲𝗙𝗶
 * XXX
 */

pragma solidity ^0.8.10;

// File [email protected]
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

// File [email protected]
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
    
    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        if (a == 1) return 1;
        if (b == 0) return 1;
        if (b == 1) return a;
        uint256 c = a ** b;
        return c;
    }
}

// File [email protected]
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

// File [email protected]
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

// File [email protected]
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File [email protected]
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

        
    𝑮𝑼𝒀 𝑾𝑯𝑶 𝑩𝑳𝑰𝑵𝑫𝑳𝒀 𝑭𝑶𝑹𝑲𝑬𝑫 𝑻𝑯𝑬 𝑪𝑶𝑵𝑻𝑹𝑨𝑪𝑻
                    |
                   |
                  |
                 V
                    
        
 /     \             \            /    \       
|       |             \          |      |      
|       `.             |         |       :     
`        F             |        \|       |     
 \       | /       /  \\\   --__ \\       :    
  \      \/   _--~~          ~--__| A     |      
   \      \_-~                    ~-_\    |    
    \_     R        _.--------.______\|   |    
      \     \______// _ ___ _ (_(__>  \   |    
       \   .  C ___)  ______ (_(____>  M  /    
       /\ |   C ____)/      \ (_____>  |_/     
      / /\|   C_____)       |  (___>   /  \    
     |   E   _C_____)\______/  // _/ /     \   
     |    \  |__   \\_________// (__/       |  
    | \    \____)   `----   --'             R  
    |  \_          ___\       /_          _/ | 
   S              /    |     |  \            | 
   |             |    /       \  \           | 
   |          / /    O         |  \           |
   |         / /      \__/\___/    N          |
  |           /        |    |       |         |
  L          |         |    |       |         Y
                      
                      
                       ^
                      /
                    / 
                  /
            𝑭𝑨𝑹𝑴𝑬𝑹𝑺𝑶𝑵𝑳𝒀 𝑫𝑬𝑽'𝒔 𝑩𝑰𝑮 𝑩𝑶𝒀


 */
abstract contract Ownable is Context {
    address private _owner;

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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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

// File [email protected]
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
     * by making the `nonReentrant` function external, and making it call a
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

// File [email protected]
/**
 * XXX
 * 𝗖𝗼𝗻𝘁𝗿𝗮𝗰𝘁 𝗼𝗿𝗶𝗴𝗶𝗻𝗮𝗹𝗹𝘆 𝗰𝗿𝗲𝗮𝘁𝗲𝗱 𝗯𝘆 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆 𝗗𝗲𝘃
 * 𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆: 𝗮𝗻 𝗶𝗻𝗻𝗼𝘃𝗮𝘁𝗶𝘃𝗲 𝗗𝗲𝗙𝗶 𝗽𝗿𝗼𝘁𝗼𝗰𝗼𝗹 𝗳𝗼𝗿 𝗬𝗶𝗲𝗹𝗱 𝗙𝗮𝗿𝗺𝗶𝗻𝗴 𝗼𝗻 𝗔𝘃𝗮𝗹𝗮𝗻𝗰𝗵𝗲
 * 
 * 𝗟𝗶𝗻𝗸𝘀:
 * 𝗵𝘁𝘁𝗽𝘀://𝗳𝗮𝗿𝗺𝗲𝗿𝘀𝗼𝗻𝗹𝘆.𝗳𝗮𝗿𝗺
 * 𝗵𝘁𝘁𝗽𝘀://𝘁.𝗺𝗲/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝟮
 * 𝗵𝘁𝘁𝗽𝘀://𝘁𝘄𝗶𝘁𝘁𝗲𝗿.𝗰𝗼𝗺/𝗙𝗮𝗿𝗺𝗲𝗿𝘀𝗢𝗻𝗹𝘆𝗗𝗲𝗙𝗶
 * XXX
 */
contract FarmersOnlyStakingPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;                 // Address of LP token contract.
        uint256 lastRewardTime;         // Last second that Rewards distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated Rewards per share, times 1e30. See below.
    }

    // The stake token
    IERC20 public immutable stakeToken;
    // The reward token
    IERC20 public immutable rewardToken;

    // Reward tokens created per second.
    uint256 public rewardPerTime;

    // Keep track of number of tokens staked in case the contract earns reflect fees
    uint256 public totalStaked = 0;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // The second when Reward mining starts.
    uint256 public startTime;
	// The second when mining ends.
    uint256 public bonusEndTime;

    // Maximum emission rate for the StakingPool.
    uint256 public constant MAX_REWARD_PER_TIME = 2 ether;

    event Deposit(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event SkimStakeTokenFees(address indexed user, uint256 amount);
    event SetRewardPerTime(uint256 oldRewardPerTime, uint256 newRewardPerTime);
    event SetBonusEndTime(uint256 oldBonusEndTime, uint256 newBonusEndTime);
    event SetStartTime(uint256 oldStartTime, uint256 newStartTime);

    constructor(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerTime,
        uint256 _startTime,
        uint256 _bonusEndTime
    ){
        require(_stakeToken != _rewardToken, "constructor: does not support same currency pools");
        /* require(_rewardPerTime.mul(uint256(10).pow(uint256(18).sub(_rewardToken.decimals()))) <= MAX_REWARD_PER_TIME, "constructor: rewardPerTime is larger than MAX_REWARD_PER_TIME");
*/
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        rewardPerTime = _rewardPerTime;
        startTime = _startTime;
        bonusEndTime = _bonusEndTime;

        // staking pool
        poolInfo = PoolInfo({
            lpToken: _stakeToken,
            lastRewardTime: _startTime,
            accRewardTokenPerShare: 0
        });

    }

    // Return reward multiplier over the given _from to _to second.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndTime) {
            return _to.sub(_from);
        } else if (_from >= bonusEndTime) {
            return 0;
        } else {
            return bonusEndTime.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        if (block.timestamp > pool.lastRewardTime && totalStaked != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 tokenReward = multiplier.mul(rewardPerTime);
            accRewardTokenPerShare = accRewardTokenPerShare.add(tokenReward.mul(1e30).div(totalStaked));
        }
        return user.amount.mul(accRewardTokenPerShare).div(1e30).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        if (totalStaked == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 tokenReward = multiplier.mul(rewardPerTime);
        pool.accRewardTokenPerShare = pool.accRewardTokenPerShare.add(tokenReward.mul(1e30).div(totalStaked));
        pool.lastRewardTime = block.timestamp;
    }

    /// Deposit staking token into the contract to earn rewards.
    /// @dev Since this contract needs to be supplied with rewards we are
    ///  sending the balance of the contract if the pending rewards are higher
    /// @param _amount The amount of staking tokens to deposit
    function deposit(uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        uint256 finalDepositAmount = 0;
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardTokenPerShare).div(1e30).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 currentRewardBalance = rewardBalance();
                if(currentRewardBalance > 0) {
                    if(pending > currentRewardBalance) {
                        safeTransferReward(msg.sender, currentRewardBalance);
                    } else {
                        safeTransferReward(msg.sender, pending);
                    }
                }
            }
        }
        if (_amount > 0) {
            uint256 preStakeBalance = totalStakeTokenBalance();
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            finalDepositAmount = totalStakeTokenBalance().sub(preStakeBalance);
            user.amount = user.amount.add(finalDepositAmount);
            totalStaked = totalStaked.add(finalDepositAmount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(1e30);

        emit Deposit(msg.sender, finalDepositAmount);
    }

    /// Withdraw rewards and/or staked tokens. Pass a 0 amount to withdraw only rewards
    /// @param _amount The amount of staking tokens to withdraw
    function withdraw(uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(pool.accRewardTokenPerShare).div(1e30).sub(user.rewardDebt);
        if(pending > 0) {
            uint256 currentRewardBalance = rewardBalance();
            if(currentRewardBalance > 0) {
                if(pending > currentRewardBalance) {
                    safeTransferReward(msg.sender, currentRewardBalance);
                } else {
                    safeTransferReward(msg.sender, pending);
                }
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(msg.sender, _amount);
            totalStaked = totalStaked.sub(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(1e30);

        emit Withdraw(msg.sender, _amount);
    }

    /// Obtain the reward balance of this contract
    /// @return wei balace of conract
    function rewardBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    // Deposit Rewards into contract
    function depositRewards(uint256 _amount) external {
        require(_amount > 0, 'Deposit value must be greater than 0.');
        
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit DepositRewards(_amount);
    }

    /// @param _to address to send reward token to
    /// @param _amount value of reward token to transfer
    function safeTransferReward(address _to, uint256 _amount) internal {
        rewardToken.safeTransfer(_to, _amount);
    }

    /* Admin Functions */

    /// @param _rewardPerTime The amount of reward tokens to be given per second
    function setRewardPerTime(uint256 _rewardPerTime) external onlyOwner {
        require(_rewardPerTime <= MAX_REWARD_PER_TIME, "setRewardPerTime: rewardPerTime is larger than MAX_REWARD_PER_TIME");
        updatePool();

        uint256 _oldRewardPerTime = rewardPerTime;

        rewardPerTime = _rewardPerTime;

        emit SetRewardPerTime(_oldRewardPerTime, _rewardPerTime);
    }

    /// @param  _bonusEndTime The second when rewards will end
    function setBonusEndTime(uint256 _bonusEndTime) external onlyOwner {
        require(_bonusEndTime > startTime, 'setBonusEndTime: bonus end time must be greater than start time');

        uint256 _oldBonusEndTime = bonusEndTime;

        bonusEndTime = _bonusEndTime;

        emit SetBonusEndTime(_oldBonusEndTime, _bonusEndTime);
    }
    
    /// @param  _startTime The second when rewards will start
    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "setStartTime: cannot set start time in the past");
        require(_startTime < bonusEndTime, "setStartTime: start time must be smaller than bonus end time");
        require(startTime > block.timestamp, "setStartTime: pool is already started");

        uint256 _oldStartTime = startTime;

        startTime = _startTime;
        poolInfo.lastRewardTime = _startTime;

        emit SetStartTime(_oldStartTime, _startTime);
    }

    /// @dev Obtain the stake token fees (if any) earned by reflect token
    function getStakeTokenFeeBalance() public view returns (uint256) {
        return totalStakeTokenBalance().sub(totalStaked);
    }

    /// @dev Obtain the stake balance of this contract
    /// @return wei balace of contract
    function totalStakeTokenBalance() public view returns (uint256) {
        // Return BEO20 balance
        return stakeToken.balanceOf(address(this));
    }

    /// @dev Remove excess stake tokens earned by reflect fees
    function skimStakeTokenFees() external onlyOwner {
        uint256 stakeTokenFeeBalance = getStakeTokenFeeBalance();
        stakeToken.safeTransfer(msg.sender, stakeTokenFeeBalance);
        emit SkimStakeTokenFees(msg.sender, stakeTokenFeeBalance);
    }

    /* Emergency Functions */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(msg.sender, user.amount);
        totalStaked = totalStaked.sub(user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardBalance(), 'not enough rewards');
        // Withdraw rewards
        safeTransferReward(msg.sender, _amount);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

}