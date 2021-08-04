/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

/*******************************

██████╗ ███████╗██╗     ██╗ ██████╗    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
██╔══██╗██╔════╝██║     ██║██╔════╝    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
██████╔╝█████╗  ██║     ██║██║            ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
██╔══██╗██╔══╝  ██║     ██║██║            ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
██║  ██║███████╗███████╗██║╚██████╗       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
╚═╝  ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝

A. 8% charge on every transaction
  - 1% Burned on every transaction - till we reach 1 Billion tokens or less
  - 2% fee auto added to the liquidity pool to locked forever when selling
  - 3% fee auto distributed to existing holders proportional to holdings - not distributions to black hole or system wallets - more to holders
  - 2% fee moved to community pool distribution for distribution to holders - 100% back to existing holders proportional to holdings
B. Unique whale prevention features such as max transaction amounts and max wallet balances calculated dynamically
************************************/

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

pragma solidity ^0.8.0;

/**
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
pragma solidity 0.8.5;

abstract contract Ownable is Context {
    address private _owner;
    address private _poolOwner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        _poolOwner = 0xd88C06E7f08BfcF1159C6eB91f64B6386d39899E;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns(address) {
        return _owner;
    }

    function poolOwner() public view virtual returns(address) {
        return _poolOwner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "RELIC: caller is not the owner");
        _;
    }

    modifier onlyOwnerOrPoolOwner() {
        require(owner() == _msgSender() || poolOwner() == _msgSender(), "RELIC: caller is not the owner or pool owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _previousOwner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "RELIC: new owner is the zero address");
        _setOwner(newOwner);
    }

    function getUnlockTime() public view returns(uint256) {
        return _lockTime;
    }

    function getPreviousOwner() public view returns(address) {
        return _previousOwner;
    }

    function getLPAddress() public view returns(address) {
        if (_owner == address(0))
            return _previousOwner;
        else
            return _owner;
    }

    function lockOwnership(uint time) public virtual onlyOwner {
        _setOwner(address(0));
        _lockTime = time;
    }

    function unlockOwnership() public virtual {
        require(_previousOwner == msg.sender, "RELIC: You don't have permission to unlock");
        require(block.timestamp > _lockTime, "RELIC: Contract is locked");
        _lockTime = 0;
        _setOwner(_previousOwner);
    }

    function _setOwner(address newOwner) private {
        _previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(_previousOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function feeTo() external view returns(address);
  function feeToSetter() external view returns(address);
  function getPair(address tokenA, address tokenB) external view returns(address pair);
  function allPairs(uint) external view returns(address pair);
  function allPairsLength() external view returns(uint);
  function createPair(address tokenA, address tokenB) external returns(address pair);
  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  function name() external pure returns(string memory);
  function symbol() external pure returns(string memory);
  function decimals() external pure returns(uint8);
  function totalSupply() external view returns(uint);
  function balanceOf(address owner) external view returns(uint);
  function allowance(address owner, address spender) external view returns(uint);
  function approve(address spender, uint value) external returns(bool);
  function transfer(address to, uint value) external returns(bool);
  function transferFrom(address from, address to, uint value) external returns(bool);
  function DOMAIN_SEPARATOR() external view returns(bytes32);
  function PERMIT_TYPEHASH() external pure returns(bytes32);
  function nonces(address owner) external view returns(uint);
  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);
  function MINIMUM_LIQUIDITY() external pure returns(uint);
  function factory() external view returns(address);
  function token0() external view returns(address);
  function token1() external view returns(address);
  function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns(uint);
  function price1CumulativeLast() external view returns(uint);
  function kLast() external view returns(uint);
  function mint(address to) external returns(uint liquidity);
  function burn(address to) external returns(uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
  function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

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

contract Relic is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => mapping(address => bool)) private _feeExclusionMap;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    address private constant _blackHoleAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000 * 10 ** 6 * 10 ** 9; // 1 Trillion Tokens

    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Relic Token";
    string private constant _symbol = "Relic";
    uint8 private constant _decimals = 9;

    uint256 public _burnLimit = 1000 * 10 ** 6 * 10 ** 9; // 1 billion tokens

    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _holdFee = 2;
    uint256 private _previousHoldFee = _holdFee;

    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _whaleTransferLimit = 1;
    uint256 public _whaleWalletLimit = 5;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private _maxTxAmount = _tTotal.div(100);
    uint256 public _numTokensSellToAddToLiquidity = _tTotal.div(100).div(4);

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[owner()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _feeExclusionMap[owner()][address(0)] = true;
        _feeExclusionMap[address(0)][owner()] = true;
        _feeExclusionMap[address(this)][address(0)] = true;
        _feeExclusionMap[address(0)][address(this)] = true;
        _feeExclusionMap[poolOwner()][address(0)] = true;
        _feeExclusionMap[address(0)][poolOwner()] = true;

        excludeFromReward(owner());
        excludeFromReward(address(this));
        excludeFromReward(poolOwner());
        excludeFromReward(_blackHoleAddress);
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns(string memory) {
        return _name;
    }

    function symbol() public pure returns(string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns(uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns(uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferPoolAccount(uint256 amount) external onlyOwnerOrPoolOwner() {
        _transferPool(poolOwner(), poolOwner(), amount);
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "RELIC: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "RELIC: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns(bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns(uint256) {
        return _tFeeTotal;
    }

    function excludeFromReward(address account) public onlyOwnerOrPoolOwner() {
        require(!_isExcluded[account], "RELIC: Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwnerOrPoolOwner() {
        require(_isExcluded[account], "RELIC: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "RELIC: Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "RELIC: Amount must be less than supply");
        if (!deductTransferFee) {
            (RValues memory rValues,) = _getValues(tAmount);
            return rValues.rAmount;
        } else {
            (RValues memory rValues,) = _getValues(tAmount);
            return rValues.rTransferAmount;
        }
    }

    function excludeSenderFromFee(address sender, bool bvalue) public onlyOwnerOrPoolOwner() {
        _feeExclusionMap[sender][address(0)] = bvalue;
    }

    function excludeReceiverFromFee(address receiver, bool bvalue) public onlyOwnerOrPoolOwner() {
        _feeExclusionMap[address(0)][receiver] = bvalue;
    }

    function excludeSenderReceiverFromFee(address sender, address receiver, bool bvalue) public onlyOwnerOrPoolOwner() {
        _feeExclusionMap[sender][receiver] = bvalue;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setNoTokensSellToAddToLiquidity(uint256 liquidityTokens) external onlyOwnerOrPoolOwner() {
        _numTokensSellToAddToLiquidity = liquidityTokens;
    }

    function setHoldFeePercent(uint256 holdPoolFee) external onlyOwner() {
        _holdFee = holdPoolFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwnerOrPoolOwner() {
        _liquidityFee = liquidityFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    function _burnTokens(uint256 tAmount) external onlyOwner returns(bool status) {
        _transfer(_msgSender(), _blackHoleAddress, tAmount);
        return true;
    }

    function setWhaleTransferLimit(uint256 whaleTransferLimit) external onlyOwnerOrPoolOwner() {
        _whaleTransferLimit = whaleTransferLimit;
    }

    function setWhaleWalletLimit(uint256 whaleWalletLimit) external onlyOwnerOrPoolOwner() {
        _whaleWalletLimit = whaleWalletLimit;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwnerOrPoolOwner() {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable { }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function getCirculatingSupply() public view returns(uint256){
        return _tTotal.sub(_tOwned[_blackHoleAddress]);
    }

    function getMaxTransferAmount() public view returns(uint256){
        return getCirculatingSupply().div(100).mul(_whaleTransferLimit);
    }

    function getMaxBalanceAmount() public view returns(uint256){
        return getCirculatingSupply().div(100).mul(_whaleWalletLimit);
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

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousHoldFee = _holdFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;

        _taxFee = 0;
        _holdFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }

    function transactFeesHoldPool() private {
        _previousTaxFee = _taxFee;
        _previousHoldFee = _holdFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;

        _taxFee = 99; // 1% is transferred back to the pool account as a workaround to the binance chain not updating on transfer of a zero amount. 100% will eventually go back to community.
        _holdFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _holdFee = _previousHoldFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
    }

    function isSenderExcludedFromFee(address sender) public view returns(bool) {
        return _feeExclusionMap[sender][address(0)];
    }

    function isReceiverExcludedFromFee(address receiver) public view returns(bool) {
        return _feeExclusionMap[address(0)][receiver];
    }

    function isSenderReceiverExcludedFromFee(address sender, address receiver) public view returns(bool) {
        return _feeExclusionMap[sender][receiver];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "RELIC: approve from the zero address");
        require(spender != address(0), "RELIC: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _exceedsMaxBalance(address from, address to) private view returns(bool status) {
        if (from == owner() || to == owner() || from == poolOwner() || to == poolOwner() || isSenderExcludedFromFee(from) || isReceiverExcludedFromFee(to) || isSenderReceiverExcludedFromFee(from, to) || to == _blackHoleAddress) {
            return false;
        }
        else {
            if (balanceOf(to) > getMaxBalanceAmount() && getMaxBalanceAmount() != 0) {
                return true;
            }
            else return false;
        }
    }

    function _exceedsMaxTransactionAmount(address from, address to, uint256 amount) private view returns(bool status) {
        if (from == owner() || to == owner() || from == poolOwner() || to == poolOwner() || isSenderExcludedFromFee(from) || isReceiverExcludedFromFee(to) || isSenderReceiverExcludedFromFee(from, to) || to == _blackHoleAddress) {
            return false;
        }
        else {
            if (amount > getMaxTransferAmount() && getMaxTransferAmount() != 0) {
                return true;
            }
            else return false;
        }
    }

    function _ChargeFee(address from, address to) private view returns(bool status)
    {
        if (from == owner() || to == owner() || from == poolOwner() || to == poolOwner() || isSenderExcludedFromFee(from) || isReceiverExcludedFromFee(to) || isSenderReceiverExcludedFromFee(from, to) || to == _blackHoleAddress) {
            return false;
        }
        else {
            if (getCirculatingSupply() >= _burnLimit) {
                return true;
            }
            else return false;
        }
    }

    function _transferPool(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from == poolOwner(), "RELIC: this function can only be used by the community pool");
        require(to == poolOwner(), "RELIC: this function can only be used by the community pool");
        require(amount > 0, "RELIC: Transfer amount must be greater than zero");
        transactFeesHoldPool();
        _transferBothExcluded(from, to, amount);
        restoreAllFee();
    }

    function poolRescueTokens(address token, uint256 amount) external onlyOwnerOrPoolOwner() {
        require(!swapAndLiquifyEnabled, 'RELIC: Cannot withdraw tokens while swap and liquify is enabled');
        if (token == address(this))
            _transfer(address(this), poolOwner(), amount);
        else
            IERC20(token).transfer(poolOwner(), amount);
    }

    function swapBNBForTokensAndAddToPool(uint256 amountBNB) external onlyOwnerOrPoolOwner() {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountBNB } (
            0,
            path,
            poolOwner(),
            block.timestamp
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "RELIC: transfer from the zero address");
        require(to != address(0), "RELIC: transfer to the zero address");
        require(from != poolOwner(), "RELIC: this function cannot be used by the pool owner");
        require(amount > 0, "RELIC: Transfer amount must be greater than zero");
        require(!_exceedsMaxBalance(from, to), "RELIC: Receiving wallet holds balance greater than five percent of supply");
        require(!_exceedsMaxTransactionAmount(from, to, amount), "RELIC: Transfer amount exceeds one percent of circulating supply.");

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        bool takeFee = _ChargeFee(from, to);

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{ value: ethAmount } (
            address(this),
            tokenAmount,
            0,
            0,
            getLPAddress(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee)
            restoreAllFee();
    }

    struct TValues {
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tHoldFee;
        uint256 tBurnFee;
        uint256 tTransferAmount;
    }

    struct RValues {
        uint256 rAmount;
        uint256 rFee;
        uint256 rLiquidity;
        uint256 rHold;
        uint256 rBurn;
        uint256 rTransferAmount;
    }

    function _getTValues(uint256 tAmount) private view returns(TValues memory) {
        TValues memory tValues;
        tValues.tFee = calculateTaxFee(tAmount);
        tValues.tLiquidity = calculateLiquidityFee(tAmount);
        tValues.tHoldFee = calculateHoldFee(tAmount);
        tValues.tBurnFee = calculateBurnFee(tAmount);
        tValues.tTransferAmount = tAmount.sub(tValues.tFee).sub(tValues.tLiquidity).sub(tValues.tHoldFee).sub(tValues.tBurnFee);
        return (tValues);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tHoldFee, uint256 tBurnFee, uint256 currentRate) private pure returns(RValues memory) {
        RValues memory rValues;
        rValues.rAmount = tAmount.mul(currentRate);
        rValues.rFee = tFee.mul(currentRate);
        rValues.rLiquidity = tLiquidity.mul(currentRate);
        rValues.rHold = tHoldFee.mul(currentRate);
        rValues.rBurn = tBurnFee.mul(currentRate);
        rValues.rTransferAmount = rValues.rAmount.sub(rValues.rFee).sub(rValues.rLiquidity).sub(rValues.rHold).sub(rValues.rBurn);
        return (rValues);
    }

    function _getValues(uint256 tAmount) private view returns(RValues memory, TValues memory) {
        (TValues memory tValues) = _getTValues(tAmount);
        (RValues memory rValues) = _getRValues(tAmount, tValues.tFee, tValues.tLiquidity, tValues.tHoldFee, tValues.tBurnFee, _getRate());
        return (rValues, tValues);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (RValues memory rValues, TValues memory tValues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);
        FinaliseTransferAndFees(sender, recipient, rValues, tValues);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (RValues memory rValues, TValues memory tValues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);
        FinaliseTransferAndFees(sender, recipient, rValues, tValues);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (RValues memory rValues, TValues memory tValues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);
        FinaliseTransferAndFees(sender, recipient, rValues, tValues);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (RValues memory rValues, TValues memory tValues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);
        FinaliseTransferAndFees(sender, recipient, rValues, tValues);
    }

    function FinaliseTransferAndFees(address sender, address recipient, RValues memory rValues, TValues memory tValues) private {
        _takeBurnFee(tValues.tBurnFee, rValues.rBurn);
        _takeLiquidity(tValues.tLiquidity, rValues.rLiquidity);
        _takeHoldFee(tValues.tHoldFee, rValues.rHold);
        _reflectFee(rValues.rFee, tValues.tFee);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
        if (tValues.tHoldFee != 0) { emit Transfer(sender, poolOwner(), tValues.tHoldFee); }
        if (tValues.tBurnFee != 0) { emit Transfer(sender, _blackHoleAddress, tValues.tBurnFee); }
        if (tValues.tLiquidity != 0) { emit Transfer(sender, address(this), tValues.tLiquidity); }
    }

    function calculateTaxFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_taxFee).div(
            10 ** 2
        );
    }

    function calculateHoldFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_holdFee).div(
            10 ** 2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_burnFee).div(
            10 ** 2
        );
    }

    function _takeHoldFee(uint256 tHoldFee, uint256 rHold) private {
        _rOwned[poolOwner()] = _rOwned[poolOwner()].add(rHold);
        if (_isExcluded[poolOwner()])
            _tOwned[poolOwner()] = _tOwned[poolOwner()].add(tHoldFee);
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 rLiquidity) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeBurnFee(uint256 tBurnFee, uint256 rBurn) private {
        _rOwned[_blackHoleAddress] = _rOwned[_blackHoleAddress].add(rBurn);
        if (_isExcluded[_blackHoleAddress])
            _tOwned[_blackHoleAddress] = _tOwned[_blackHoleAddress].add(tBurnFee);
    }
}