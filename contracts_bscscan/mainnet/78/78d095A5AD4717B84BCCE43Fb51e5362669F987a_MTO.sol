/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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


pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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


pragma solidity ^0.6.0;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * Mint to the MTO contract
     */
    function mint(uint256 _amount) external returns (bool);
    
    
    function includeInFee(address _address) external;
    function excludeFromFee(address _address) external;
    function setTaxFeeFactor(uint256 _taxFeeFactor) external;
    function withdrawToken() external;
    

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


pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.5.0;

interface IPool {

    function rewardPerBlock() external pure returns (uint256);
    function updateRewardPerBlock(uint256) external;
    function updateBonusEndBlock(uint256) external;
    function updateStartBlock(uint256) external;
    function setLockupDuration(uint256) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

  event Mint(address indexed sender, uint amount0, uint amount1);
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

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}


interface IXRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}


interface IXRouter02 is IXRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


pragma solidity >=0.6.2;

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




pragma solidity >=0.6.2;

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


pragma solidity 0.6.12;

contract MTO is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Admin address
    address public adminAddress;
    // The raising token
    address public stakeToken;
    // The offering token
    address public offeringToken;
    // LP of offering token
    address public lpAddress; // auto generete when deploying
    // Uni Router address
    address public uniRouterAddress;
    // Set on global level, could be passed to functions via arguments
    uint256 public routerDeadlineDuration = 300;
    // Token price
    uint256 public tokenPrice; // x10; Eg: if price is 45.6 you should set 456.
    // RewardsPerBlockPerToken 
    uint256 public rewardsPerBlockPerTokenMinted; // (per 1 entire token, not 18 digits)
    // Pools
    address[] public pools;
    // Pools alloc
    uint256[] public poolsAlloc;
    // Purchase limit
    uint256 public stakeTokenPurchaseLimit = 1000000000000000000000000; // 1 mill
    // Liquidity fee base points / 10.000
    uint256 public liquidityFee = 2000; // 20% init
    // deltaAlloc to control market buy amount
    /* MODIFICATION 2021-09-13 */
    uint256 public deltaAlloc = 120;
    address[] public stakeToOfferPath;
    /* END MODIFICATION */

    // Burn Address
    /* MODIFICATION 2021-09-13 */
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    /* END MODIFICATION */

    // Deposit event
    event Deposit(address indexed user, uint256 amount);

    // Constructor
    constructor(address _offeringToken, address _stakeToken, address _uniRouterAddress, address _lpAddress, uint256 _tokenPrice) public {
        // Set admin address
        adminAddress = msg.sender;
        // Set offering token, can't be changed.
        offeringToken = _offeringToken;
        // Set stake token
        stakeToken = _stakeToken;
        // Set token price
        tokenPrice = _tokenPrice;
        // Set uniRouterAddress
        uniRouterAddress = _uniRouterAddress;
        // Set lpAddress
        lpAddress = _lpAddress;
        // Set path
        stakeToOfferPath = [stakeToken, offeringToken];
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }
    
    // @dev set staked Token (BUSD)
    function setStakeToken(address _stakeToken) public onlyAdmin {
        stakeToken = _stakeToken;
    }
    
    // @dev set MAIN lp address
    function setLPAddress(address _lpAddress) public onlyAdmin {
        lpAddress = _lpAddress;
    }
    
    // @dev set router address
    function setUniRouterAddress(address _uniRouterAddress) public onlyAdmin {
        uniRouterAddress = _uniRouterAddress;
    }
    
    // @dev set offeringToken price
    function setTokenPrice(uint256 _tokenPrice) public onlyAdmin {
        require(_tokenPrice > 0, "token price must be higher than zero");
        tokenPrice = _tokenPrice;
    }
    
    // @dev Update rewards per block per token minted
    function setRewardsPerBlockPerToken(uint256 _rewardsPerBlockPerTokenMinted) public onlyAdmin {
        // set pool rewardsPerBlock
        if (rewardsPerBlockPerTokenMinted > 0) {
            // iterate pools
            for (uint256 i = 0; i < pools.length; i++) {
                // Get actual pool rewards
                uint256 actualRewardsPerBlock = IPool(pools[i]).rewardPerBlock();
                // Add pool extra rewards
                IPool(pools[i]).updateRewardPerBlock(actualRewardsPerBlock.mul(_rewardsPerBlockPerTokenMinted).div(rewardsPerBlockPerTokenMinted));       
            }
        }
        // Set new rewards
        rewardsPerBlockPerTokenMinted = _rewardsPerBlockPerTokenMinted;
    }
    
    // @dev add new pool
    function addPool(address _pool, uint256 _alloc) public onlyAdmin {
        pools.push(_pool);
        poolsAlloc.push(_alloc);
        // Exclude pool from fee
        tokenExcludeFromFee(_pool);
    }
    
    // @dev update pool
    function setPool(uint256 _pid, uint256 _alloc) public onlyAdmin {
        poolsAlloc[_pid] = _alloc;
    }
    
    // @dev manually set rewards per block
    function setPoolRewardPerBlock(uint256 _pid, uint256 _rewardPerBlock) public onlyAdmin {
        IPool(pools[_pid]).updateRewardPerBlock(_rewardPerBlock);       
    }
    
    // @dev update bonusEndBlock. Can only be called by the owner.
    function setPoolBonusEndBlock(uint256 _pid, uint256 _bonusEndBlock) public onlyAdmin {
        IPool(pools[_pid]).updateBonusEndBlock(_bonusEndBlock);
    }   
    
    // @dev update startBlock. Can only be called by the owner.
    function setPoolStartBlock(uint256 _pid, uint256 _startBlock) public onlyAdmin {
        IPool(pools[_pid]).updateStartBlock(_startBlock);
    }   
    
    // @dev set pool lockup duration in seconds
    function setPoolLockupDuration(uint256 _pid, uint256 _lockupDuration) public onlyAdmin {
        IPool(pools[_pid]).setLockupDuration(_lockupDuration);
    }
    
    // @dev include in token tx fee
    function tokenIncludeInFee(address _address) public onlyAdmin {
        IBEP20(offeringToken).includeInFee(_address);
    }
    
    // @dev exclude from token tx fee
    function tokenExcludeFromFee(address _address) public onlyAdmin {
        IBEP20(offeringToken).excludeFromFee(_address);
    }
    
    // @dev withdraw bTMT tokens from de token contract
    function tokenWithdrawToken() public onlyAdmin {
        IBEP20(offeringToken).withdrawToken();
        /* MODIFICATION 2021-09-13 */
        uint256 qty = IBEP20(offeringToken).balanceOf(address(this));
        IBEP20(offeringToken).safeTransfer(adminAddress, qty);
        /* END MODIFICATION */ 
    }
    
    // @dev set token tx fee
    function setTokenTaxFeeFactor(uint256 _taxFeeFactor) public onlyAdmin {
        IBEP20(offeringToken).setTaxFeeFactor(_taxFeeFactor);
    }
    
    // @dev set BUSD limit to deposit, se to zero (0) to disable deposit
    function setStakeTokenPurchaseLimit(uint256 _stakeTokenPurchaseLimit) public onlyAdmin {
        stakeTokenPurchaseLimit = _stakeTokenPurchaseLimit;
    }
    
    // @dev set liquidity fee base points 10000 = 100%, 1000 = 10%, 100 = 1%
    function setLiquidityFee(uint256 _liquidityFee) public onlyAdmin {
        require(_liquidityFee <= 10000, "limit must be between 0 and 10000");
        liquidityFee = _liquidityFee;
    }
    
    // @dev withdraw tokens in the contract (committed BUSD or extra mined BTC)
    function withdrawTokens() external onlyAdmin {
        uint256 qty = IBEP20(stakeToken).balanceOf(address(this));
        IBEP20(stakeToken).safeTransfer(adminAddress, qty);
    }
    
    // @dev set delta alloc that modifies the market buy amount
    /* MODIFICATION 2021-09-14 */
    function setDeltaAlloc(uint256 _deltaAlloc) public onlyAdmin {
        require(_deltaAlloc <= 10000, "limit must be between 0 and 10000");
        deltaAlloc = _deltaAlloc;
    }
    /* END MODIFICATION */
    
    // /// @dev Deposit BEP20 tokens with support for reflect tokens
    // function deposit(uint256 _amount) external {
    //     // need to be higher than 0
    //     require(_amount > 0, "amount must be higher than 0");
    //     // Need to be lower than limit
    //     require(_amount <= stakeTokenPurchaseLimit, "amount must be lower than the limit");
        
    //     // Get actual stake token balance
    //     uint256 pre = getTotalStakeTokenBalance();
    //     // Transfer tokens from user to contract
    //     IBEP20(stakeToken).safeTransferFrom(
    //         address(msg.sender),
    //         address(this),
    //         _amount
    //     );
    //     // Get final token amount
    //     uint256 finalDepositAmount = getTotalStakeTokenBalance().sub(pre);
        
    //     // Calculate mint amount
    //     /* Modification 2021-09-13 */
    //     uint256 mintAmount = finalDepositAmount.div(tokenPrice).mul(10); 
    //     /* END MODIFICATION 2021-09-13 */
    //     // Mint to this contract
    //     IBEP20(offeringToken).mint(mintAmount);
    //     // Transfer to user
    //     IBEP20(offeringToken).safeTransfer(address(msg.sender), mintAmount);
        
    //     // Increase pools
    //     increasePoolsRewards(mintAmount);
        
    //     // Add liquidity
    //     addLiquidity(finalDepositAmount);
        
    //     // Emit Event
    //     emit Deposit(msg.sender, _amount);
    // }
    
    /// @dev Deposit BEP20 tokens with support for reflect tokens
    function deposit(uint256 _amount) external {
        // need to be higher than 0
        require(_amount > 0, "amount must be higher than 0");
        // Need to be lower than limit
        require(_amount <= stakeTokenPurchaseLimit, "amount must be lower than the limit");
        
        // Get actual stake token balance
        uint256 pre = getTotalStakeTokenBalance();
        // Transfer tokens from user to contract
        IBEP20(stakeToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        // Get final token amount
        uint256 finalDepositAmount = getTotalStakeTokenBalance().sub(pre);
        
        /* MODIFICATION 2021-09-13 */
        // Get market price x10 so its in the same format than the tokenPrice
        uint256 marketPrice = 10000000 / getAmountToMint(lpAddress, 1000000);
        // Calculate final amount that user needs to receive
        uint256 finalReceiveAmount = finalDepositAmount.div(marketPrice).mul(10); 
        // Amount to buy in the market
        uint256 marketBuyFactor = 10000; // 100%
        if (marketPrice >= tokenPrice) {
            marketBuyFactor = (((marketPrice*100/tokenPrice)-100)/10)*deltaAlloc;
            if (marketBuyFactor > 5000) {
                marketBuyFactor = 5000;
            }
            marketBuyFactor = 5000 - marketBuyFactor;
        }
        // Buy in the market
        uint256 preMarketBuyAmount = IBEP20(offeringToken).balanceOf(address(this));
        buyNativeToken(finalDepositAmount.mul(marketBuyFactor).div(10000));
        uint256 marketBuyAmount = IBEP20(offeringToken).balanceOf(address(this)).sub(preMarketBuyAmount);
        // Mint amount
        uint256 mintAmount = finalReceiveAmount.sub(marketBuyAmount);
        // Mint to this contract
        IBEP20(offeringToken).mint(mintAmount);
        // Transfer to user
        IBEP20(offeringToken).safeTransfer(address(msg.sender), finalReceiveAmount);
        /* END MODIFICATION */
        
        // Increase pools
        increasePoolsRewards(mintAmount);
        
        // Add liquidity
        if (marketPrice >= tokenPrice) {
            addLiquidity(finalDepositAmount);
        }
        
        // Emit Event
        emit Deposit(msg.sender, _amount);
    }
    
    // Add rewards
    function increasePoolsRewards(uint256 _mintAmount) internal {
        
        // Calculate TOTAL extra rewards given the minted amount
        uint256 totalExtraRewardsPerBlock = rewardsPerBlockPerTokenMinted.mul(_mintAmount.div(10**18));
        
        // Get total allocs
        uint256 totalAllocs = getTotalAllocs();
        
        // Iterate pools
        for (uint256 i = 0; i < pools.length; i++) {
            // Continue if allocs 
            if (poolsAlloc[i] > 0) {
                // Caculate pool extra rewards
                uint256 extraPoolRewards = totalExtraRewardsPerBlock.mul(poolsAlloc[i]).div(totalAllocs);
                // Get actual pool rewards
                uint256 actualRewardsPerBlock = IPool(pools[i]).rewardPerBlock();
                // Add pool extra rewards
                IPool(pools[i]).updateRewardPerBlock(actualRewardsPerBlock.add(extraPoolRewards));                
            }
        }
    }
    
    function getTotalAllocs() public view returns(uint256) {
        uint256 totalAllocs = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            totalAllocs = totalAllocs.add(poolsAlloc[i]);
        }
        return totalAllocs;
    }
    
    /* MODIFICATION 2021-09-14 */
    function buyNativeToken(uint256 _amount) internal {
        if (_amount > 0) {
            IBEP20(stakeToken).safeIncreaseAllowance(uniRouterAddress, _amount);
            IXRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                stakeToOfferPath,
                address(this),
                now + routerDeadlineDuration
            );
        }
    }
    /* END MODIFICATION */
    
    function addLiquidity(uint256 _depositAmount) internal {
        
        // Calculate how much staked token goes to liquidity
        uint256 stakeTokenLiquidityAmount = _depositAmount.mul(liquidityFee).div(10000);
        
        // Mint same value of offering token
        uint256 offeringTokenLiquidityAmount = getAmountToMint(lpAddress, stakeTokenLiquidityAmount);
        // Mint to this contract
        IBEP20(offeringToken).mint(offeringTokenLiquidityAmount);
        
        // Increase allowance stakeToken
        IBEP20(stakeToken).safeIncreaseAllowance(uniRouterAddress,stakeTokenLiquidityAmount);
        // Increase allowance offeringToken
        IBEP20(offeringToken).safeIncreaseAllowance(uniRouterAddress,offeringTokenLiquidityAmount);

        // Add liquidity
        IXRouter02(uniRouterAddress).addLiquidity(
            offeringToken,
            stakeToken,
            offeringTokenLiquidityAmount,
            stakeTokenLiquidityAmount,
            0,
            0,
            burnAddress,
            now + routerDeadlineDuration
        );
    }
    
    // calculate price based on pair reserves
    function getAmountToMint(address pairAddress, uint256 amount) public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        /* MODIFICATION 2021-09-13 */
        uint256 amountOfTokensNeeded = 0;
        if (pair.token0() == offeringToken) {
            amountOfTokensNeeded = ( (amount*Res0) / Res1); // return amount of token0 needed to buy token1
        }
        if (pair.token1() == offeringToken) {
            amountOfTokensNeeded = ( (amount*Res1) / Res0); // return amount of token1 needed to buy token0
        }
        /* END MODIFICATION */
        return amountOfTokensNeeded; // return amount of token0 needed to buy token1
    }

    function getTotalStakeTokenBalance() public view returns (uint256) {
        return IBEP20(stakeToken).balanceOf(address(this));
    }
}