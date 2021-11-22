/**
 *Submitted for verification at snowtrace.io on 2021-11-22
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

// File [email protected] (shortened for FarmersOnly usage)
/**
 * 
 */
interface IUniswapPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// File [email protected] (shortened for FarmersOnly usage)
/**
 * 
 */
library UniswapLibrary {
    address private constant factoryJoe = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
    address private constant factoryPango = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        if (factory == factoryJoe) {
            pair = address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                factory,
                                keccak256(abi.encodePacked(token0, token1)),
                                hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91"
                            )
                        )
                    )  
                )
            );
        } else if (factory == factoryPango) {
            pair = address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                factory,
                                keccak256(abi.encodePacked(token0, token1)),
                                hex"40231f6b438bce0797c9ada29b718a87ea0a5cea3fe9a771abdd76bd41a3e545"
                            )
                        )
                    )  
                )
            );
        }
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }
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
}

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
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
contract OnionCoin is ERC20('FarmersOnly\'s Onion Coin', 'ONION') {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

// File [email protected]
/**
 * MasterChef is the master of Onion. He makes Onion and he is a fair guy.
 *
 * Note that it's ownable and the owner wields tremendous power. The ownership
 * will be transferred to a governance smart contract once ONION is sufficiently
 * distributed and the community can show to govern itself.
 *
 * Have fun reading it. Hopefully it's bug-free. God bless.
 * 
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
contract FarmersOnlyMasterChefL3 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ONIONs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accOnionPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accOnionPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. ONIONs to distribute per second.
        uint256 lastRewardTime;     // Last time ONIONs distribution occurs.
        uint256 accOnionPerShare;   // Accumulated ONIONs per share, times 1e18. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points.
        uint16 withdrawFeeBP;       // Withdraw fee in basis points.
        uint256 harvestInterval;    // Harvest interval in seconds.
        bool kingRot;               // "true" if a pool is king-rotating.
        bool isKing;                // "true" if a king-rotating pool is king.
        bool hybridHarvest;         // Hybrid Harvest feature status (true: active, false: disabled).
    }

    // The ONION TOKEN!
    OnionCoin public immutable onion;
    // Trader Joe Factory address used to fetch ONION-USDT reserves.
    address private immutable factoryJoe;
    // Pangolin Factory address used to fetch ONION-USDT reserves.
    address private immutable factoryPango;
    // CORN Token.
    ERC20 private constant corn = ERC20(0xFcA54c64BC44ce2E72d621B6Ed34981e53B66CaE);
    // TMT Token.
    ERC20 private constant tmt = ERC20(0xf5760bbbC3565f6A513a9c20300a335A1250C57e);
    // USDT.e Token.
    address private constant usdt = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    // USDC.e Token.
    address private constant usdc = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    // ONION tokens created per second.
    uint256 public onionPerSecond;
    
    // Dev address.
    address public devAddress;
    // Deposit Fee address.
    address public feeAddress;
    // Initial Owner address, to do things such as:
    // - disabling king rotation,  since it's an experimental feature
    // - setting king-rotating pools lpToken addresses, since it has to be done fast after token liquidity is provided, to guarantee a correct working of the masterchef
    address public firstOwnerAddress;
    // Liquidity Locker contract address.
    address public lockAddress;
    // Corn staking pool votation address for King Rotation.
    address public cornVote;
    // Tomato staking pool votation address for King Rotation.
    address public tmtVote;
    // Onion staking pool votation address for King Rotation.
    address public onionVote;

    // Max token supply: 14444 tokens.
    uint256 private constant MAX_SUPPLY = 14444 ether;
    // Max deposit fee: 4%.
    uint256 public constant MAX_DEPOSIT_FEE = 400;
    // Max withdraw fee: 20% (only settable for king-rotating pools).
    uint256 public constant MAX_KING_WITHDRAW_FEE = 2000;
    // Max harvest interval: 2 days.
    uint256 public constant MAX_HARVEST_INTERVAL = 2 days;
    // Total locked up rewards.
    uint256 public totalLockedUpRewards;
    
    // King-rotation interval.
    uint256 private kingRotation;
    // Initial king-rotation interval.
    uint256 private nextKingInt;
    // King-rotation timer.
    uint256 private kingTimer;
    // Number of king-rotating pools.
    uint256 private kings;
    // Actual king index between all pools.
    uint256 private kingPid;
    // ONION-USDT Pair for ONION price fetching.
    address private onionusdt;
    // King pool allocPoints.
    uint256 private kingMul;
    // Boolean to avoid creating normal pools after at least one king-rotating pool has been created (disabled if King Rotation is disabled).
    bool private noMoreNormalPools;
    // Tells if there's already a king between the king-rotating pools. If yes, there can't be nomore kings.
    bool private kingSet;
    // Tells if king is safe (onionSupremacy = true) or if he's bleeding (onionSupremacy = false).
    bool private kingSafe;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when ONION mining starts.
    uint256 public startTime;
    // King Rotation feature status (true: active, false: disabled).
    bool private isKingRotationActive;
    // To prevent the function "endNonNativesBoost" to be called more than once.
    bool private nonNativeBoostEnd;
    
    // Maximum onionPerSecond: 0.007.
    uint256 public constant MAX_EMISSION_RATE = 0.007 ether;
    // Initial onionPerSecond: 0.0035.
    uint256 private constant INITIAL_EMISSION_RATE = 0.0035 ether;
    // Initial king pool allocPoints: 1000x multiplier.
    uint256 private constant INITIAL_KING_MUL = 100000;
    // Initial king-rotation interval: 6 hours.
    uint256 private constant INITIAL_KING_ROT = 6 hours;
    // Minimum initial king-rotation interval: 1 hour.
    uint256 public constant MIN_KING_ROTATION = 1 hours;
    // Non-king (but still king-rotating) pool allocPoints: 1x multiplier.
    uint256 private constant NON_KING_MUL = 100;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetLockAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetVotesAddresses(address indexed user, address[3] indexed newAddresses);
    event UpdateEmissionRate(address indexed user, uint256 newEmissionRate);
    event SetOnionUsdt(address indexed user, address indexed newOnionUsdt);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event StartTimeChanged(uint256 oldStartTime, uint256 newStartTime);
    event SetHybridHarvest(address indexed user, bool newHybridHarvest);
    event SetKingRotationInterval(address indexed user, uint256 newKingRotInterval, bool isImmediate);
    event SetPoolLp(address indexed user, uint256 indexed pid, IERC20 newPoolLp);
    event SetKingPoolMul(address indexed user, uint256 newAllocPoint);

    constructor(
        OnionCoin _onion,
        /* address _devAddress,
        address _feeAddress,
        address _lockAddress,
        address _cornVote,
        address _tmtVote,
        address _onionVote,
        uint256 _startTime, */
        uint256 _startTime,
        bool _isKingRotationActive
    ){
        onion = _onion;
        startTime = _startTime;
        devAddress = msg.sender;
        feeAddress = msg.sender;
        lockAddress = 0x99FeFC0b47481E5805A5b8CC6089D595cE453B3b;
        cornVote = 0x2796bd827B9D53b505F927eA0958be1e78553e57;
        tmtVote = 0x43B45f9AD77D2767A642CF236fc1c17DaeE5bb4A;
        onionVote = 0x6D3541CCfdeD3B41971e607cF5CD521e816022Ac;
        isKingRotationActive = _isKingRotationActive;
        
        factoryJoe = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
        factoryPango = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;
        kingSafe = true;
        nextKingInt = INITIAL_KING_ROT;
        onionPerSecond = INITIAL_EMISSION_RATE;
        kingRotation = INITIAL_KING_ROT;
        onionusdt = 0x47C113915506a6319206676356a61eF7ce8fA856;
        kingTimer = startTime + INITIAL_KING_ROT;
        kingMul = INITIAL_KING_MUL;
        noMoreNormalPools = false;
        kingSet = false;
        firstOwnerAddress = msg.sender;
        kings = 0;
        totalAllocPoint = 0;
        nonNativeBoostEnd = false;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }
    
    // View function to gather the number of pools.
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    // View function to display if king is safe (🛡) or bleeding (🩸) on the frontend
    function isKingSafe() external view returns (bool) {
        return kingSafe;
    }
    
    // View function to gather ONION max supply.
    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }
    
    // View function to fetch next king rotation remaining time on frontend.
    function nextRotation() external view returns (uint256) {
        return kingTimer;
    }
    
    // View function to see if king rotation is active or not.
    function isKingRot() external view returns (bool) {
        return isKingRotationActive;
    }
    
    // View function to see which pool is the actual king.
    function king() external view returns (uint256) {
        return kingPid;
    }
    
    // View function to see if hybrid harvest is active or not.
    function isHybrid(uint256 _pid) external view returns (bool) {
        return poolInfo[_pid].hybridHarvest;
    }
    
    // View function to fetch block timestamp on frontend.
    function blockTimestamp() external view returns (uint time) { // to assist with countdowns on site
        time = block.timestamp;
    }
    
    function addStartPools() external onlyOwner{
        require(poolInfo.length == 0, "addStartPools: there already are pools");
        addPool(40000, IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7), 400, 0, 7200, false, false, true, false); // wavax
        addPool(40000, IERC20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB), 400, 0, 7200, false, false, true, false); // weth.e
        addPool(40000, IERC20(0x50b7545627a5162F82A992c33b87aDc75187B218), 400, 0, 7200, false, false, true, false); // wbtc.e
        addPool(40000, IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd), 400, 0, 7200, false, false, true, false); // joe
        addPool(40000, IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118), 400, 0, 7200, false, false, true, false); // usdt.e
        addPool(40000, IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664), 400, 0, 7200, false, false, true, false); // usdc.e
        addPool(40000, IERC20(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70), 400, 0, 7200, false, false, true, false); // dai.e
        addPool(40000, IERC20(0xe28984e1EE8D431346D32BeC9Ec800Efb643eef4), 400, 0, 7200, false, false, true, false); // wavax-usdt.e
        addPool(40000, IERC20(0x7c05d54fc5CB6e4Ad87c6f5db3b807C94bB89c52), 400, 0, 7200, false, false, true, false); // wavax-weth.e
        addPool(40000, IERC20(0xc13E562d92F7527c4389Cd29C67DaBb0667863eA), 400, 0, 7200, false, false, true, false); // usdc.e-usdt.e
        addPool(2500, corn, 100, 0, 3600, false, false, true, false); // corn
        addPool(5000, IERC20(0xc6A9dc8569ada7626b77E04445e93227d0790478), 50, 0, 3600, false, false, true, false); // corn-usdc.e
        addPool(2500, tmt, 100, 0, 3600, false, false, true, false); // tmt
        addPool(5000, IERC20(0x2b2793d3ED4640db784e6a438a5bc25b6FE7C169), 50, 0, 3600, false, false, true, false); // tmt-usdt.e
        addPool(10000, onion, 0, 0, 3600, false, false, true, false); // onion
        addPool(100000, IERC20(0xCf1089CE0f4BBa72aEB40D8CB4C2f53530B75380), 0, 2000, 0, true, true, false, false); // onion-wavax
        addPool(100, IERC20(0x8248afc9509ac21548aD1439B3d77903D6daCdE8), 0, 2000, 0, true, false, false, false); // onion-usdc.e
        addPool(100, IERC20(0x47C113915506a6319206676356a61eF7ce8fA856), 0, 2000, 0, true, false, false, false); // onion-usdt.e
        addPool(100, IERC20(0xaf94B4A9cDc1fD35de6BB188394B82Ef71FfFA7a), 0, 2000, 0, true, false, false, false); // onion weth.e
        addPool(100, IERC20(0x1904D789EECE956ABd6E12759d4a7b82435A1e63), 0, 2000, 0, true, false, false, false); // onion-wbtc.e
        addPool(100, IERC20(0x9DB8200bb987a973039b13823CA99F59277cAa89), 0, 2000, 0, true, false, false, false); // onion-dai.e
    }
    
    // This is gonne be done in like 6 hours after farming starts, so better to leave it doable without passing thru timelock
    function endNonNativesBoost() external {
        require(msg.sender == firstOwnerAddress, "endNonNativeBoost: sender is not the owner");
        require(!nonNativeBoostEnd, "endNonNativeBoost: boost already ended");
        nonNativeBoostEnd = true;
        setAllocPoint(0,4500);
        setAllocPoint(1,4500);
        setAllocPoint(2,4500);
        setAllocPoint(3,4500);
        setAllocPoint(4,4500);
        setAllocPoint(5,4500);
        setAllocPoint(6,4500);
        setAllocPoint(7,4500);
        setAllocPoint(8,4500);
        setAllocPoint(9,4500);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, uint16 _withdrawFeeBP, uint256 _harvestInterval, bool _kingRot, bool _isKing, bool _hybridHarvest, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken){
        require(isKingRotationActive || !_kingRot, "addPool: can't add a king pool if king rotation has been disabled");
        require(_kingRot || !noMoreNormalPools, "addPool: can't add normal pools after at least one king-rotating pool has been added");
        if (_withdrawFeeBP > 0) {
            require(_kingRot, "addPool: no withdraw fees on non king-rotating pools");
        }
        if (_depositFeeBP > 0) {
            require(!_kingRot, "addPool: no deposit fees on king-rotating pools");
        }
        if (_isKing) {
            require(_kingRot, "addPool: a non king-rotating pool can't be king");
            require(!kingSet, "addPool: there can only be one king!");
        }
        require(_depositFeeBP <= MAX_DEPOSIT_FEE, "addPool: invalid deposit fee basis points");
        require(_withdrawFeeBP <= MAX_KING_WITHDRAW_FEE, "addPool: invalid withdraw fee basis points");
        require(_harvestInterval <= MAX_HARVEST_INTERVAL, "addPool: invalid harvest interval");
        
        _lpToken.balanceOf(address(this));
        
        if (_kingRot) {
            _allocPoint = NON_KING_MUL;
            noMoreNormalPools = true;
            kings++;
        }
        if (_isKing) {
            _allocPoint = kingMul;
            kingPid = poolInfo.length;
            kingSet = true;
        }
    
        poolExistence[_lpToken] = true;

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardTime: lastRewardTime,
        accOnionPerShare : 0,
        depositFeeBP : _depositFeeBP,
        withdrawFeeBP : _withdrawFeeBP,
        harvestInterval : _harvestInterval,
        kingRot : _kingRot,
        isKing : _isKing,
        hybridHarvest : _hybridHarvest
        }));
    }


     // Update startTime by the owner (added this to ensure that dev can delay startTime due to the congestion network). Only used if required. 
    function setStartTime(uint256 _newStartTime) external onlyOwner {
        require(startTime > block.timestamp, 'setStartTime: farm already started');
        require(_newStartTime > block.timestamp, 'setStartTime: new start time must be future time');

        uint256 _previousStartTime = startTime;

        startTime = _newStartTime;
        
        kingTimer = _newStartTime + kingRotation;

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTime = startTime;
        }

        emit StartTimeChanged(_previousStartTime, _newStartTime);
    }

    // Update the given pool's ONION allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint16 _withdrawFeeBP, uint256 _harvestInterval, bool _withUpdate) external onlyOwner {
        if (_withdrawFeeBP > 0) {
            require(poolInfo[_pid].kingRot, "set: no withdraw fees on non king-rotating pools");
        }
        if (_depositFeeBP > 0) {
            require(!poolInfo[_pid].kingRot, "set: no deposit fees on king-rotating pools");
        }
        require(_depositFeeBP <= MAX_DEPOSIT_FEE, "set: invalid deposit fee basis points");
        require(_withdrawFeeBP <= MAX_KING_WITHDRAW_FEE, "set: invalid withdraw fee basis points");
        require(_harvestInterval <= MAX_HARVEST_INTERVAL, "set: invalid harvest interval");

        if (_withUpdate) {
            massUpdatePools();
        }
        if (poolInfo[_pid].kingRot) {
            _allocPoint = NON_KING_MUL;
        }
        if (poolInfo[_pid].isKing) {
            _allocPoint = kingMul;
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending ONIONs on frontend.
    function pendingOnion(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accOnionPerShare = pool.accOnionPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 onionReward = multiplier.mul(onionPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            accOnionPerShare = accOnionPerShare.add(onionReward.mul(1e18).div(lpSupply));
        }

        uint256 pending = user.amount.mul(accOnionPerShare).div(1e18).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest Onions's.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }
    
    // View function to see if user harvest until time.
    function getHarvestUntil(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.nextHarvestUntil;
    }
    
    // Fetch USD price of token by accessing its pair reserves using Uniswap as Oracle.
    function price(address _factory, address _token, address _quote) private view returns (uint256) {
        (uint256 reserve0, uint256 reserve1) = UniswapLibrary.getReserves(_factory, _token, _quote);
        return UniswapLibrary.quote(1e18, reserve0, reserve1);
    }
    
    // Check if the USD value of deposits in ONION vote pool is higher than the sum of USD values of deposits in TMT and CORN vote pools.
    function onionSupremacy() private view returns (bool) {
        return onion.balanceOf(onionVote).mul(price(factoryJoe, address(onion), usdt)) >
            (corn.balanceOf(cornVote).mul(price(factoryPango, address(corn), usdc)))
            .add(tmt.balanceOf(tmtVote).mul(price(factoryJoe, address(tmt), usdt)));
    }
    
    // Handles the rotation of the crown between king-rotating pools.
    function rotateKing() private {
        if (onionSupremacy()) { // if $ in the onion vote pool is higher than $ in corn+tmt pool, timer stays where it is
            kingTimer = block.timestamp + kingRotation;
            kingSafe = true;
        } else { // if $ in onion goes lower than $ in tmt+corn, timer starts, then stops when $ in onion goes back up
            if (kingTimer > block.timestamp) {
                kingRotation = kingTimer - block.timestamp;
            } else {
                kingRotation = 0;
            }
            kingSafe = false;
        }
        if (block.timestamp >= kingTimer) { // king rotation logic (if timer finishes, next king-rotating pool becomes king and timer re-starts)
            kingRotation = nextKingInt;
            kingTimer = block.timestamp + kingRotation;
            
            PoolInfo storage kingPool = poolInfo[kingPid];
            kingPool.isKing = false;
            kingPool.allocPoint = NON_KING_MUL;
            
            if (kingPid + 1 == poolInfo.length) {
                kingPid = poolInfo.length - kings;
            } else {
                kingPid++;
            }
            
            PoolInfo storage newKingPool = poolInfo[kingPid];
            newKingPool.isKing = true;
            newKingPool.allocPoint = kingMul;
        }
    }    

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        
        if (isKingRotationActive)
        {
            rotateKing();
        }
        
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 onionReward = multiplier.mul(onionPerSecond).mul(pool.allocPoint).div(totalAllocPoint);

        if (onion.totalSupply() >= MAX_SUPPLY) {
            onionReward = 0;
        } else if (onion.totalSupply().add(onionReward.mul(11).div(10)) >= MAX_SUPPLY) {
            onionReward = (MAX_SUPPLY.sub(onion.totalSupply()).mul(10).div(11));
        }

        if (onionReward > 0) {
            onion.mint(devAddress, onionReward.div(10));
            onion.mint(address(this), onionReward);
            pool.accOnionPerShare = pool.accOnionPerShare.add(onionReward.mul(1e18).div(lpSupply)); 
        }

        pool.lastRewardTime = block.timestamp;
    }
    
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Deposit LP tokens to MasterChef for ONION allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        updatePool(_pid);
        payOrLockupPendingOnion(_pid);

        if (_amount > 0) {
            uint256 _balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            // for token that have transfer tax
            _amount = pool.lpToken.balanceOf(address(this)).sub(_balanceBefore);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        
        user.rewardDebt = user.amount.mul(pool.accOnionPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "withdraw: not good");
        
        updatePool(_pid);
        payOrLockupPendingOnion(_pid);

        if (_amount > 0) {
            uint256 withdrawFee = 0;
            if (pool.withdrawFeeBP > 0) {
                withdrawFee = _amount.mul(pool.withdrawFeeBP).div(10000);
                uint256 lockFee = withdrawFee.sub(withdrawFee.div(2)); // XXX for the auto-lock of half of withdraw fee feature
                pool.lpToken.safeTransfer(feeAddress, withdrawFee.div(2)); // XXX "div(2)" for the auto-lock of half of withdraw fee feature
                pool.lpToken.safeTransfer(lockAddress, lockFee); // XXX for the auto-lock of half of withdraw fee feature
            }
            pool.lpToken.safeTransfer(msg.sender, _amount.sub(withdrawFee));
            user.amount = user.amount.sub(_amount);
        }
        
        user.rewardDebt = user.amount.mul(pool.accOnionPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function getPoolHarvestInterval(uint256 _pid) private view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        return block.timestamp.add(pool.harvestInterval);
    }

    // Pay or lockup pending onion.
    function payOrLockupPendingOnion(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = getPoolHarvestInterval(_pid);
        }
        uint256 pending = user.amount.mul(pool.accOnionPerShare).div(1e18).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);
                uint256 rewardsToLockup;
                uint256 rewardsToDistribute;
                if (poolInfo[_pid].hybridHarvest) {
                    rewardsToLockup = totalRewards.div(2);
                    rewardsToDistribute = totalRewards.sub(rewardsToLockup);
                } else {
                    rewardsToLockup = 0;
                    rewardsToDistribute = totalRewards;
                }
                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp).add(rewardsToLockup);
                user.rewardLockedUp = rewardsToLockup;
                user.nextHarvestUntil = getPoolHarvestInterval(_pid);
                // send rewards
                safeOnionTransfer(msg.sender, rewardsToDistribute);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require (user.amount > 0, "emergencyWithdraw: no amount to withdraw");
        uint256 withdrawFee = 0;
            if (pool.withdrawFeeBP > 0) {
                withdrawFee = user.amount.mul(pool.withdrawFeeBP).div(10000);
                uint256 lockFee = withdrawFee.sub(withdrawFee.div(2)); // XXX for the auto-lock of half of withdraw fee feature
                pool.lpToken.safeTransfer(feeAddress, withdrawFee.div(2)); // XXX "div(2)" for the auto-lock of half of withdraw fee feature
                pool.lpToken.safeTransfer(lockAddress, lockFee); // XXX for the auto-lock of half of withdraw fee feature
            }
        pool.lpToken.safeTransfer(msg.sender, user.amount.sub(withdrawFee));
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
    }

    // Safe onion transfer function, just in case if rounding error causes pool to not have enough ONIONs.
    function safeOnionTransfer(address _to, uint256 _amount) private {
        uint256 onionBal = onion.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > onionBal) {
            transferSuccess = onion.transfer(_to, onionBal);
        } else {
            transferSuccess = onion.transfer(_to, _amount);
        }
        require(transferSuccess, "safeOnionTransfer: transfer failed");
    }

    // Update the address where 10% emissions are sent (dev address).
    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "setDevAddress: setting devAddress to the zero address is forbidden");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    // Update the address where deposit fees and half of king-rotating pools withdraw fees are sent (fee address).
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "setFeeAddress: setting feeAddress to the zero address is forbidden");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }
    
    // Update the liquidity locker contract address, where the other half of king-rotating pools withdraw fees are sent (lock address).
    function setLockAddress(address _lockAddress) external onlyOwner {
        require(_lockAddress != address(0), "setLockAddress: setting lockAddress to the zero address is forbidden");
        lockAddress = _lockAddress;
        emit SetLockAddress(msg.sender, _lockAddress);
    }
    
    // Update the addresses of the staking pools where users vote to govern the King Rotation (votes addresses).
    function setVotesAddresses(address _cornVote, address _tmtVote, address _onionVote) external onlyOwner {
        require(_cornVote != address(0) && _tmtVote != address(0) && _onionVote != address(0), "setVotesAddresses: setting voting addresses to the zero address is forbidden");
        cornVote = _cornVote;
        tmtVote = _tmtVote;
        onionVote = _onionVote;
        massUpdatePools();
        emit SetVotesAddresses(msg.sender, [_cornVote, _tmtVote, _onionVote]);
    }

    // Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _onionPerSecond) external onlyOwner {
        require (_onionPerSecond <= MAX_EMISSION_RATE, "updateEmissionRate: value higher than maximum");
        massUpdatePools();
        onionPerSecond = _onionPerSecond;
        emit UpdateEmissionRate(msg.sender, _onionPerSecond);
    }
    
    // Turn on/off the hybrid harvest function on every pool.
    // Since this is an experimental feature and we may want to disable it anytime (no harm to users if we do that), it will be doable without waiting for the timelock delay.
    function setHybridHarvest(bool _hybridHarvest) external {
        require(msg.sender == firstOwnerAddress, "setHybridHarvest: sender is not the owner");
        for (uint i = 0; i < poolInfo.length; i++) {
            poolInfo[i].hybridHarvest = _hybridHarvest;
        }
        massUpdatePools();
        emit SetHybridHarvest(msg.sender, _hybridHarvest);
    }
    
    // Turn on/off the hybrid harvest function on a single pool.
    // Since Hybrid Harvest is an experimental feature and we may want to disable it anytime (no harm to users if we do that), it will be doable without waiting for the timelock delay.
    function setHybridHarvestSingle(uint256 _pid, bool _hybridHarvest) external {
        require(msg.sender == firstOwnerAddress, "setHybridHarvest: sender is not the owner");
        poolInfo[_pid].hybridHarvest = _hybridHarvest;
        updatePool(_pid);
    }
    
    // Update the King Rotation start interval, and also decide if it must immediately start again with the changed interval or wait for the next natural rotation.
    function setKingRotInterval(uint256 _kingInterval, bool _immediate) external onlyOwner {
        require(isKingRotationActive, "setKingPoolMul: king rotation feature has been disabled");
        require(_kingInterval >= MIN_KING_ROTATION, "setKingInterval: interval can't be less than 1 hour");
        nextKingInt = _kingInterval;
        if (_immediate) {
            kingRotation = _kingInterval;
            kingTimer = block.timestamp + kingRotation;
            massUpdatePools();
        }
        emit SetKingRotationInterval(msg.sender, _kingInterval, _immediate);
    }
    
    // Set the multiplier of the King pool.
    // Since King Rotation is an experimental feature and we may want to modify it anytime (no harm to users if we do that), it will be doable without waiting for the timelock delay
    function setKingPoolMul(uint256 _allocPoint) external {
        require(msg.sender == firstOwnerAddress, "setKingPoolMul: sender is not the owner");
        require(isKingRotationActive, "setKingPoolMul: king rotation feature has been disabled");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[kingPid].allocPoint).add(_allocPoint);
        poolInfo[kingPid].allocPoint = _allocPoint;
        kingMul = _allocPoint;
        emit SetKingPoolMul(msg.sender, _allocPoint);
    }
    
    // Disable the king-rotation feature. WARNING: NON REACTIVABLE!
    // Since King Rotation is an experimental feature and we may want to disable it anytime (no harm to users if we do that), it will be doable without waiting for the timelock delay
    function disableKingRotation() external {
        require(msg.sender == firstOwnerAddress, "disableKingRotation: sender is not the owner");
        require(isKingRotationActive, "disableKingRotation: king rotation feature has already been disabled");
        massUpdatePools();
        uint256 newAllocPoint = totalAllocPoint.div(kings.mul(2));
        noMoreNormalPools = false;
        poolInfo[kingPid].isKing = false;
        for (uint i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].kingRot) {
                totalAllocPoint = totalAllocPoint.sub(poolInfo[i].allocPoint).add(newAllocPoint);
                poolInfo[i].allocPoint = newAllocPoint;
                poolInfo[i].kingRot = false;
                poolInfo[i].withdrawFeeBP = 0;
            }
        }
        isKingRotationActive = false;
    }
    
    // Change only the allocPoint of a pool without having to put in all the parameters needed for the "set()" function.
    // Since this is something that will be done very often (no harm to users), it will be doable without passing thru the timelock.
    function setAllocPoint(uint256 _pid, uint256 _allocPoint) public {
        require(msg.sender == firstOwnerAddress, "setAllocPoint: sender is not the owner");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }
    
}