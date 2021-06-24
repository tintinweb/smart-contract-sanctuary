/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: IWBNB.sol

pragma solidity >=0.5.0;

interface IWBNB {

function deposit() external payable ;

function withdraw(uint wad) external ;

function approve(address guy, uint wad) external returns (bool) ;

function transfer(address dst, uint wad) external returns (bool) ;

}

// File: IPancakeFactory.sol

pragma solidity >=0.5.0;

interface IPancakeFactory {
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
// File: IPancakeRouter01.sol

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

// File: IPancakeRouter02.sol

pragma solidity >=0.6.2;


interface IPancakeRouter02 is IPancakeRouter01 {
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

// File: IPancakePair.sol

pragma solidity >=0.6.2;

interface IPancakePair {
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

    function initialize(address, address) external;
}
// File: Address.sol

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

// File: IBEP20.sol

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

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

// File: SafeBEP20.sol

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

// File: SafeMath.sol

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

// File: MultiSwap.sol

pragma solidity ^0.6.12;


//import "./Ownable.sol";






contract MultiSwap is Initializable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    
    struct Route {
        address factory;
        address ROUTER;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
        
    address private WBNB;
    address private BNB;
    
    uint maxReserve;
    uint maxSlippage;
    uint totalRoute;
    
    address _owner;
    
    Route[] tradingRoutes;
    
    function initialize() public initializer {
        _owner = msg.sender;
        //ROUTER = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F); // BSC
        //ROUTER = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // BSC v2
        //ROUTER = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // BSC Test
        //ROUTER = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH Test
        maxReserve = 5 * 1000000 * 10e9;
        maxSlippage = 10;
        //tradingRoutes.push(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //./WBNB = 0xc778417E063141139Fce010982780140Aa0cD5Ab;totalRoute = 1;
    }
    
    receive() external payable {}

    constructor() public { initialize(); }

    /* ========== View Functions ========== */
    
    function swapRateInSat(address ROUTER02, uint ETHamountInSat, address[] memory _froms, address _to) external view returns (uint) {
        IPancakeRouter02 ROUTER;
        address[] memory path;
        uint amount;
        uint tokenAmount;
        require(totalRoute > 0,"route = 0");
        ROUTER = IPancakeRouter02(ROUTER02);
        for (uint i=0;i<_froms.length;i++) {
            if (_froms[i] == WBNB || _froms[i] == BNB || _to == WBNB || _to == BNB) {
                path = new address[](2);
                path[0] = WBNB;
                path[1] = _to;
                if (path[1] == BNB) path[1] = WBNB;
                _froms[i] == BNB ? tokenAmount = ETHamountInSat : tokenAmount = IBEP20(path[0]).balanceOf(msg.sender);
            } else {
                path = new address[](3);
                path[0] = _froms[i];
                path[1] = WBNB;
                path[2] = _to;
                tokenAmount = IBEP20(path[0]).balanceOf(msg.sender);
            }
        amount = path[0] == path[1] ? amount.add(tokenAmount) : amount.add(ROUTER.getAmountsOut(tokenAmount, path)[path.length - 1]);
        }
        
        return amount / 10e9;
    }
    
    function reserveInSat() external view returns (uint) {
        return maxReserve / 10e9;
    }
    
    function slippageDivByTen() external view returns (uint) {
        return maxSlippage;
    }
    
    /* ========== External Functions ========== */
    
    function swap(address _from, uint amount, address _to) external payable {
        address payable sender = msg.sender;
        uint newAmount;
        require(totalRoute > 0,"route = 0");
        if (_from == BNB) {
            if (amount == 0) amount = msg.value;
            require(msg.value > 0,"eth = 0");
            if (amount > maxReserve && sender.balance < maxReserve) amount = amount.sub(maxReserve);
            _swap(_from, amount, _to, msg.sender);
            if (msg.value == amount+maxReserve) sender.transfer(maxReserve);
        } else {
            IBEP20 token = IBEP20(_from);
            if (amount == 0) amount = token.balanceOf(msg.sender);
            require(amount > 0 && amount <= token.balanceOf(msg.sender),"token amount less than available");
            require(token.allowance(msg.sender,address(this)) >= amount,"transfer amount exceeds allowance");
            require(token.transferFrom(msg.sender,address(this),amount), "transfer failed");
            if (_from != WBNB) amount = _swap(_from,amount,WBNB,address(this));
            if (sender.balance < maxReserve && _to != BNB) {
                newAmount = amount > maxReserve - sender.balance ? amount - (maxReserve - sender.balance) : amount;
            } else {
                newAmount = amount;
            }
            if (_to == WBNB) {
                _send(WBNB,msg.sender,newAmount);
            }
            else if (_to == BNB) {
                IWBNB(WBNB).withdraw(newAmount);
                sender.transfer(newAmount);
            }
            else {
                _swap(WBNB, newAmount, _to, msg.sender);
            }
            if (newAmount != amount) {
                IWBNB(WBNB).withdraw(amount - newAmount);
                sender.transfer(amount - newAmount);
            }
        }
    }
    
    function multiSwap(address[] memory _froms, address _to) external payable {
        uint amount;
        uint amountBNB;
        uint newAmountBNB;
        address payable sender = msg.sender;
        //require(msg.sender == _owner || (msg.sender != _owner && msg.value >= maxReserve), "send fee");
        require(totalRoute > 0,"route = 0");
        for (uint i=0;i<_froms.length;i++) {
            if (_froms[i] == BNB) {
                require(msg.value > 0,"eth = 0");
                IWBNB(WBNB).deposit{value:msg.value}();
                amountBNB = amountBNB.add(msg.value);
            } else {
                amount = IBEP20(_froms[i]).balanceOf(msg.sender);
                require(amount > 0 && amount <= IBEP20(_froms[i]).balanceOf(msg.sender),"token amount less than available");
                require(IBEP20(_froms[i]).allowance(msg.sender,address(this)) >= amount,"transfer amount exceeds allowance");
                require(IBEP20(_froms[i]).transferFrom(msg.sender,address(this),amount), "transfer failed");
                amountBNB = _froms[i] == WBNB ? amountBNB.add(amount) : amountBNB.add(_swap(_froms[i], amount, WBNB, address(this)));
            }
        }
        if (sender.balance < maxReserve && _to != BNB) {
            newAmountBNB = amountBNB > maxReserve - sender.balance ? amountBNB - (maxReserve - sender.balance) : amountBNB;
        } else {
            newAmountBNB = amountBNB;
        }
        if (_to == WBNB) {
            _send(WBNB,msg.sender,newAmountBNB);
        }
        else if (_to == BNB) {
            IWBNB(WBNB).withdraw(newAmountBNB);
            sender.transfer(newAmountBNB);
        }
        else {
            _swap(WBNB, newAmountBNB, _to, msg.sender);
        }
        if (newAmountBNB != amountBNB) {
            IWBNB(WBNB).withdraw(amountBNB - newAmountBNB);
            sender.transfer(amountBNB - newAmountBNB);
        }
    }
    
    function multiSwapLP(address ROUTER02, address[] memory _froms, address token0, address token1) external payable {
        uint token0Amount;
        uint token1Amount;
        uint amount;
        uint amountBNB;
        //require(msg.sender == _owner || (msg.sender != _owner && msg.value >= maxReserve), "send fee");
        for (uint i=0;i<_froms.length;i++) {
                if (_froms[i] == BNB) {
                    require(msg.value > 0,"eth = 0");
                    IWBNB(WBNB).deposit{value:msg.value}();
                    amountBNB = amountBNB.add(msg.value);
                } else {
                    amount = IBEP20(_froms[i]).balanceOf(msg.sender);
                    require(amount > 0 && amount <= IBEP20(_froms[i]).balanceOf(msg.sender),"token amount less than available");
                    require(IBEP20(_froms[i]).allowance(msg.sender,address(this)) >= amount,"transfer amount exceeds allowance");
                    require(IBEP20(_froms[i]).transferFrom(msg.sender,address(this),amount), "transfer failed");
                    amountBNB = _froms[i] == WBNB ? amountBNB.add(amount) : amountBNB.add(_swap(_froms[i], amount, WBNB, address(this)));
                }
        }
        token0Amount = token0 == WBNB ? amountBNB.div(2) : _swap(WBNB, amountBNB.div(2), token0, address(this));
        token1Amount = token1 == WBNB ? amountBNB.div(2) : _swap(WBNB, amountBNB.div(2), token1, address(this));
        if (IBEP20(token0).allowance(address(this),address(ROUTER02)) < token0Amount) IBEP20(token0).approve(address(ROUTER02), uint(~0));
        if (IBEP20(token1).allowance(address(this),address(ROUTER02)) < token1Amount) IBEP20(token1).approve(address(ROUTER02), uint(~0));
        IPancakeRouter02(ROUTER02).addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, msg.sender, block.timestamp+86400);
    }

    /* ========== Private Functions ========== */
    
    function _send(address token, address _to, uint amount) internal returns (bool) {
        if (amount == 0) amount = IBEP20(token).balanceOf(address(this));
        if (IBEP20(token).allowance(address(this),_to) < amount) IBEP20(token).approve(_to, uint(~0));
        return IBEP20(token).transferFrom(address(this),_to,amount);
    }
    
    function _swap(address _from, uint amount, address _to, address receiver) internal returns (uint) {
        IPancakeRouter02 ROUTER;
        address[] memory path;
        uint[] memory amounts;
        uint minAmount;
        uint bestAmount;
        if (_from == WBNB && _to == BNB) {
            IWBNB(WBNB).withdraw(amount);
            payable(receiver).transfer(amount);
            return amount;
        }
        else if (_from == BNB && _to == WBNB) {
            IWBNB(WBNB).deposit{value:amount}();
            _send(WBNB, receiver, amount);
            return amount;
        }
        if (_from == BNB || _from == WBNB) {
            path = new address[](2);
            if (_from == BNB) IWBNB(WBNB).deposit{value:amount}();
            path[0] = WBNB;
            path[1] = _to;
        }
        else if (_to == BNB || _to == WBNB) {
            path = new address[](2);
            path[0] = _from;
            path[1] = WBNB;
        }
        else if (_from != _to) {
            path = new address[](3);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = _to;
        }
        
        for (uint i=0;i<totalRoute;i++) {
            if (tradingRoutes[i].ROUTER != address(0) && IPancakeFactory(tradingRoutes[i].factory).getPair(_from, _to) != address(0)) {
                minAmount = IPancakeRouter02(tradingRoutes[i].ROUTER).getAmountsOut(amount, path)[path.length - 1];
                if (minAmount > bestAmount) {
                     bestAmount = minAmount;
                     ROUTER = IPancakeRouter02(tradingRoutes[i].ROUTER);
                }
             }
        }
        
        require(address(ROUTER) != address(0),"route = 0");
        
        if (IBEP20(path[0]).allowance(address(this),address(ROUTER)) < amount) IBEP20(path[0]).approve(address(ROUTER), uint(~0));
        
        minAmount = bestAmount - (bestAmount * maxSlippage / 1000);
        
        if (_to == BNB) {
            amounts = ROUTER.swapExactTokensForTokens(amount, minAmount, path, address(this), block.timestamp+86400);
            IWBNB(WBNB).withdraw(amounts[amounts.length - 1]);
            payable(receiver).transfer(amounts[amounts.length - 1]);
            return amounts[amounts.length - 1];
        } else {
            amounts = ROUTER.swapExactTokensForTokens(amount, minAmount, path, receiver, block.timestamp+86400);
            return amounts[amounts.length - 1];
        }
    }
    
    /* ========== RESTRICTED FUNCTIONS ========== */

    function newReserve(uint newReserveInSat) external onlyOwner returns (uint) {
        maxReserve = newReserveInSat.mul(10e10);
        return newReserveInSat;
    }
    
    function addRouter(address ROUTER02) external onlyOwner {
        bool exist;
        if (totalRoute == 0) {
                tradingRoutes.push(Route({
                factory: IPancakeRouter02(ROUTER02).factory(),
                ROUTER: ROUTER02
            }));
            totalRoute++;
            if (WBNB == address(0)) WBNB = IPancakeRouter02(ROUTER02).WETH();
        } else {
            for (uint i;i<totalRoute;i++){
                if (ROUTER02 == tradingRoutes[i].ROUTER) {
                    exist = true;
                    break;
                }
            }
        }
        require(!exist,"address already exist");
        tradingRoutes.push(Route({
            factory: IPancakeRouter02(ROUTER02).factory(),
            ROUTER: ROUTER02
        }));
        if (WBNB == address(0)) WBNB = IPancakeRouter02(ROUTER02).WETH();
    }
    
    function removeRouter(address ROUTER02) external onlyOwner {
        for (uint i;i<totalRoute;i++){
            if (ROUTER02 == tradingRoutes[i].ROUTER) {
                delete tradingRoutes[i];
                totalRoute--;
                break;
            }
        }
    }
    
    function newSlippage(uint maxSlippageMultiplyByTen) external onlyOwner returns (uint) {
        maxSlippage = maxSlippageMultiplyByTen;
        return maxSlippage;
    }
    
    function withdraw(address token) external onlyOwner {
        if (token == BNB) {
            payable(_owner).transfer(address(this).balance);
            return;
        }

        IBEP20(token).transfer(_owner, IBEP20(token).balanceOf(address(this)));
    }
}