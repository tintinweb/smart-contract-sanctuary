/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin\contracts\access\Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

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

    function initialize(address, address) external;
}

// File: node_modules\@uniswap\v2-periphery\contracts\libraries\SafeMath.sol

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: @uniswap\v2-periphery\contracts\libraries\UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin\contracts\math\Math.sol

// SPDX-License-Identifier: MIT

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


// File: @openzeppelin\contracts\utils\Address.sol

// SPDX-License-Identifier: MIT

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

// File: contracts\libraries\SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;




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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

// File: contracts\interfaces\IMlp.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

abstract contract IMlp {
    function makeOffer(address _token, uint _amount, uint _unlockDate, uint _endDate, uint _slippageTolerancePpm, uint _maxPriceVariationPpm,bool _fluidMatching,uint _minFluidMatch) external virtual returns (uint offerId);

    function takeOffer(uint _pendingOfferId, uint _amount, uint _deadline) external virtual returns (uint activeOfferId);

    function cancelOffer(uint _offerId) external virtual;

    function release(uint _offerId, uint _deadline) external virtual;
}

// File: contracts\interfaces\IFeesController.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

abstract contract IFeesController {
    function feesTo() public virtual returns (address);
    function setFeesTo(address) public virtual;

    function feesPpm() public virtual returns (uint);
    function setFeesPpm(uint) public virtual;
}

// File: contracts\interfaces\IRewardManager.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

abstract contract IRewardManager {
    function add(uint256 _allocPoint, address _newMlp) public virtual;
    function notifyDeposit(address _account, uint256 _amount) public virtual;
    function notifyWithdraw(address _account, uint256 _amount) public virtual;
    function getPoolSupply(address pool) public view virtual returns(uint);
    function getUserAmount(address pool, address user) public view virtual returns(uint);
}

// File: contracts\Mlp.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;









contract MLP is IMlp {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint;


    IFeesController public feesController;
    uint public endDate;
    IUniswapV2Router02 public uniswapRouter;
    address public submitter;
    mapping(address => uint) public directStakeBalances;
    uint public exceedingLiquidity;
    IRewardManager public rewardManager;
    IUniswapV2Pair public uniswapPair;

    // Bonus rewards
    uint public bonusToken0;
    uint public reward0Rate;
    uint public reward0PerTokenStored;
    mapping(address => uint256) public userReward0PerTokenPaid;
    mapping(address => uint256) public userRewards0;
    uint public bonusToken1;
    uint public reward1Rate;
    uint public reward1PerTokenStored;
    mapping(address => uint256) public userReward1PerTokenPaid;
    mapping(address => uint256) public userRewards1;
    uint public lastUpdateTime;
    uint public pendingOfferCount;
    uint public activeOfferCount;

    event OfferMade(uint id);
    event OfferTaken(uint pendingOfferId, uint activeOfferId);
    event OfferCanceled(uint id);
    event OfferReleased(uint offerId);

    enum OfferStatus { PENDING, TAKEN, CANCELED }

    struct PendingOffer {
        address owner;
        address token;
        uint amount;
        uint unlockDate;
        uint endDate;
        OfferStatus status;
        uint slippageTolerancePpm;
        uint maxPriceVariationPpm;
        bool fluidMatching;
        uint minFluidMatch;
    }

    
    mapping (uint => PendingOffer) public getPendingOffer;

    struct ActiveOffer {
        address user0;
        uint originalAmount0;
        address user1;
        uint originalAmount1;
        uint unlockDate;
        uint liquidity;
        bool released;
        uint maxPriceVariationPpm;
    }

    
    mapping  (uint  => ActiveOffer) public getActiveOffer;

    constructor(
        address _uniswapPair,
        address _submitter,
        uint _endDate,
        address _uniswapRouter,
        address _feesController,
        IRewardManager _rewardManager,
        uint _bonusToken0,
        uint _bonusToken1
    ) public {
        feesController = IFeesController(_feesController);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        endDate = _endDate;
        submitter = _submitter;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        rewardManager = _rewardManager;

        uint remainingTime = endDate.sub(block.timestamp);
        bonusToken0 = _bonusToken0;
        reward0Rate = bonusToken0 / remainingTime;
        bonusToken1 = _bonusToken1;
        reward1Rate = bonusToken1 / remainingTime;
        lastUpdateTime = block.timestamp;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, endDate);
    }

    function reward0PerToken() public view returns (uint256) {
        uint totalSupply = rewardManager.getPoolSupply(address(this));
        if (totalSupply == 0) {
            return reward0PerTokenStored;
        }
        return
            reward0PerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(reward0Rate)
                    .mul(1e18)
                    / totalSupply
            );
    }

    function reward1PerToken() public view returns (uint256) {
        uint totalSupply = rewardManager.getPoolSupply(address(this));
        if (totalSupply == 0) {
            return reward1PerTokenStored;
        }
        return
            reward1PerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(reward1Rate)
                    .mul(1e18)
                    / totalSupply
            );
    }

    function rewardEarned(address account) public view returns (uint256 reward0Earned, uint256 reward1Earned) {
        uint balance = rewardManager.getUserAmount(address(this), account);
        reward0Earned = (balance.mul(reward0PerToken().sub(userReward0PerTokenPaid[account])) / 1e18).add(userRewards0[account]);
        reward1Earned = (balance.mul(reward1PerToken().sub(userReward1PerTokenPaid[account])) / 1e18).add(userRewards1[account]);
    }

    function updateRewards(address account) private {
        reward0PerTokenStored = reward0PerToken();
        reward1PerTokenStored = reward1PerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            (uint earned0, uint earned1) = rewardEarned(account);
            userRewards0[account] = earned0;
            userRewards1[account] = earned1;
            userReward0PerTokenPaid[account] = reward0PerTokenStored;
            userReward1PerTokenPaid[account] = reward1PerTokenStored;
        }
    }

    function payRewards(address account) public {
        updateRewards(account);
        (uint256 reward0, uint256 reward1) = rewardEarned(account);
        if (reward0 > 0) {
            userRewards0[account] = 0;
            IERC20(uniswapPair.token0()).safeTransfer(account, reward0);
        }
        if (reward1 > 0) {
            userRewards1[account] = 0;
            IERC20(uniswapPair.token1()).safeTransfer(account, reward1);
        }
    }

    function _notifyDeposit(address account, uint amount) private {
        updateRewards(account);
        rewardManager.notifyDeposit(account, amount);
    }

    function _notifyWithdraw(address account, uint amount) private {
        updateRewards(account);
        rewardManager.notifyWithdraw(account, amount);
    }

    function makeOffer(address _token, uint _amount, uint _unlockDate, uint _endDate, uint _slippageTolerancePpm, uint _maxPriceVariationPpm,bool _fluidMatching,uint _minFluidMatch) external override returns (uint offerId) {
        require(_amount > 0);
        require(_unlockDate > now);
        require(_endDate > now);
        require(_endDate <= _unlockDate);

        IERC20 token;

        if (_token == address(uniswapPair.token0())) {
            token = IERC20(uniswapPair.token0());
        } else if (_token == address(uniswapPair.token1())) {
            token = IERC20(uniswapPair.token1());
        } else {
            require(false, "unknown token");
        }

        token.safeTransferFrom(msg.sender, address(this), _amount);

        offerId = pendingOfferCount;
        pendingOfferCount++;

        getPendingOffer[offerId] = PendingOffer(msg.sender, _token, _amount, _unlockDate, _endDate, OfferStatus.PENDING, _slippageTolerancePpm, _maxPriceVariationPpm,_fluidMatching,_minFluidMatch);

        emit OfferMade(offerId);
    }

    struct ProviderInfo {
        address user;
        uint amount;
        IERC20 token;
    }

    struct OfferInfo {
        uint deadline;
        uint slippageTolerancePpm;
    }

    function takeOffer(uint _pendingOfferId, uint _amount, uint _deadline) external override returns (uint activeOfferId) {
        PendingOffer storage pendingOffer = getPendingOffer[_pendingOfferId];
        require(pendingOffer.status == OfferStatus.PENDING);
        require(pendingOffer.endDate > now);
        if(pendingOffer.fluidMatching){
            require(_amount >= pendingOffer.minFluidMatch || _amount <= pendingOffer.amount,"fluid matching range not okay");
        }
        pendingOffer.status = OfferStatus.TAKEN;
        uint difference;
        // Sort the users, tokens, and amount
        ProviderInfo memory provider0;
        ProviderInfo memory provider1;

        if (pendingOffer.token == uniswapPair.token0()) {
            if(pendingOffer.fluidMatching){ //check difference
                difference = pendingOffer.amount.sub(_amount); //return excess amount to maker
                IERC20(uniswapPair.token0()).transfer(pendingOffer.owner,difference);
                pendingOffer.amount = pendingOffer.amount.sub(difference);
                assert(pendingOffer.amount == _amount); //amounts must match

                provider0 = ProviderInfo(pendingOffer.owner, pendingOffer.amount, IERC20(uniswapPair.token0()));
                provider1 = ProviderInfo(msg.sender, _amount, IERC20(uniswapPair.token1()));

                provider1.token.safeTransferFrom(provider1.user, address(this), provider1.amount);
            } else {
                provider0 = ProviderInfo(pendingOffer.owner, pendingOffer.amount, IERC20(uniswapPair.token0()));
                provider1 = ProviderInfo(msg.sender, _amount, IERC20(uniswapPair.token1()));

                provider1.token.safeTransferFrom(provider1.user, address(this), provider1.amount);
            }

        } else {
            if(pendingOffer.fluidMatching){
                difference = pendingOffer.amount.sub(_amount);//return excess amount to maker
                IERC20(uniswapPair.token1()).transfer(pendingOffer.owner,difference);
                pendingOffer.amount = pendingOffer.amount.sub(difference);
                assert(pendingOffer.amount == _amount); //amounts must match

                provider0 = ProviderInfo(msg.sender, _amount, IERC20(uniswapPair.token0()));
                provider1 = ProviderInfo(pendingOffer.owner, pendingOffer.amount, IERC20(uniswapPair.token1()));
                provider0.token.safeTransferFrom(provider0.user, address(this), provider0.amount);

            } else {
                provider0 = ProviderInfo(msg.sender, _amount, IERC20(uniswapPair.token0()));
                provider1 = ProviderInfo(pendingOffer.owner, pendingOffer.amount, IERC20(uniswapPair.token1()));
                provider0.token.safeTransferFrom(provider0.user, address(this), provider0.amount);
            }

        }

        // calculate fees
        uint feesAmount0 = provider0.amount.mul(feesController.feesPpm()) / 1000;
        uint feesAmount1 = provider1.amount.mul(feesController.feesPpm()) / 1000;

        // take fees
        provider0.amount = provider0.amount.sub(feesAmount0);
        provider1.amount = provider1.amount.sub(feesAmount1);

        // send fees
        provider0.token.safeTransfer(feesController.feesTo(), feesAmount0);
        provider1.token.safeTransfer(feesController.feesTo(), feesAmount1);

        // send tokens to uniswap
        uint liquidity = _provideLiquidity(provider0, provider1, OfferInfo(_deadline, pendingOffer.slippageTolerancePpm));

        // stake liquidity
        _notifyDeposit(provider0.user, liquidity / 2);
        _notifyDeposit(provider1.user, liquidity / 2);

        if (liquidity % 2 != 0) {
            exceedingLiquidity = exceedingLiquidity.add(1);
        }

        // Record the active offer
        activeOfferId = activeOfferCount;
        activeOfferCount++;

        getActiveOffer[activeOfferId] = ActiveOffer(provider0.user, provider0.amount, provider1.user, provider1.amount, pendingOffer.unlockDate, liquidity, false, pendingOffer.maxPriceVariationPpm);

        emit OfferTaken(_pendingOfferId, activeOfferId);

        return activeOfferId;
    }

    function _provideLiquidity(ProviderInfo memory _provider0, ProviderInfo memory _provider1, OfferInfo memory _info) private returns (uint) {
        _provider0.token.safeApprove(address(uniswapRouter), _provider0.amount);
        _provider1.token.safeApprove(address(uniswapRouter), _provider1.amount);

        uint amountMin0 = _provider0.amount.sub(_provider0.amount.mul(_info.slippageTolerancePpm) / 1000);
        uint amountMin1 = _provider1.amount.sub(_provider1.amount.mul(_info.slippageTolerancePpm) / 1000);

        // Add the liquidity to Uniswap
        (uint spentAmount0, uint spentAmount1, uint liquidity) = uniswapRouter.addLiquidity(
            address(_provider0.token),
            address(_provider1.token),
            _provider0.amount,
            _provider1.amount,
            amountMin0,
            amountMin1,
            address(this),
            _info.deadline
        );

        // Give back the exceeding tokens
        if (spentAmount0 < _provider0.amount) {
            _provider0.token.safeTransfer(_provider0.user, _provider0.amount - spentAmount0);
        }
        if (spentAmount1 < _provider1.amount) {
            _provider1.token.safeTransfer(_provider1.user, _provider1.amount - spentAmount1);
        }

        return liquidity;
    }

    function cancelOffer(uint _offerId) external override {
        PendingOffer storage pendingOffer = getPendingOffer[_offerId];
        require(pendingOffer.status == OfferStatus.PENDING);

        IERC20(pendingOffer.token).safeTransfer(pendingOffer.owner, pendingOffer.amount);

        pendingOffer.status = OfferStatus.CANCELED;
        emit OfferCanceled(_offerId);
    }

    function release(uint _offerId, uint _deadline) external override {
        ActiveOffer storage offer = getActiveOffer[_offerId];

        require(msg.sender == offer.user0 || msg.sender == offer.user1, "unauthorized");
        require(now > offer.unlockDate, "locked");
        require(offer.released == false, "already released");

        IERC20 token0 = IERC20(uniswapPair.token0());
        IERC20 token1 = IERC20(uniswapPair.token1());

        IERC20(address(uniswapPair)).safeApprove(address(uniswapRouter), offer.liquidity);
        (uint amount0, uint amount1) = uniswapRouter.removeLiquidity(
            address(token0),
            address(token1),
            offer.liquidity,
            0,
            0,
            address(this),
            _deadline
        );

        _notifyWithdraw(offer.user0, offer.liquidity / 2);
        _notifyWithdraw(offer.user1, offer.liquidity / 2);

        if (_getPriceVariation(offer.originalAmount1, amount0) > offer.maxPriceVariationPpm) {
            if (amount0 > offer.originalAmount0) {
                uint toSwap = amount0.sub(offer.originalAmount0);
                address[] memory path = new address[](2);
                path[0] = uniswapPair.token0();
                path[1] = uniswapPair.token1();
                token0.safeApprove(address(uniswapRouter), toSwap);
                uint[] memory newAmounts = uniswapRouter.swapExactTokensForTokens(
                    toSwap,
                    0,
                    path,
                    address(this),
                    _deadline
                );
                amount0 = amount0.sub(toSwap);
                amount1 = amount1.add(newAmounts[1]);
            } else {
                uint toSwap = amount1.sub(offer.originalAmount1);
                address[] memory path = new address[](2);
                path[0] = uniswapPair.token1();
                path[1] = uniswapPair.token0();
                token1.safeApprove(address(uniswapRouter), toSwap);
                uint[] memory newAmounts = uniswapRouter.swapExactTokensForTokens(
                    toSwap,
                    0,
                    path,
                    address(this),
                    _deadline
                );
                amount1 = amount1.sub(toSwap);
                amount0 = amount0.add(newAmounts[1]);
            }
        }
        token0.safeTransfer(offer.user0, amount0);
        payRewards(offer.user0);
        token1.safeTransfer(offer.user1, amount1);
        payRewards(offer.user1);

        offer.released = true;
        emit OfferReleased(_offerId);
    }

    function _getPriceVariation(uint a, uint b) private pure returns (uint) {
        uint sub;
        if (a > b) {
            sub = a.sub(b);
            return sub.mul(1000) / a;
        } else {
            sub = b.sub(a);
            return sub.mul(1000) / b;
        }
    }

    function directStake(uint _amount) external {
        require(_amount > 0, "cannot stake 0");
        _notifyDeposit(msg.sender, _amount);
        directStakeBalances[msg.sender] = directStakeBalances[msg.sender].add(_amount);
        IERC20(address(uniswapPair)).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function directWithdraw(uint _amount) external {
        require(_amount > 0, "cannot withdraw 0");
        require(_amount <= directStakeBalances[msg.sender], "cannot withdraw more than staked");
        _notifyWithdraw(msg.sender, _amount);
        directStakeBalances[msg.sender] = directStakeBalances[msg.sender].sub(_amount);
        IERC20(address(uniswapPair)).transfer(msg.sender, _amount);
    }

    function transferExceedingLiquidity() external {
        require(exceedingLiquidity != 0);
        IERC20(address(uniswapPair)).transfer(feesController.feesTo(), exceedingLiquidity);
        exceedingLiquidity = 0;
    }
}

// File: contracts\interfaces\IMintableERC20.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;


abstract contract IMintableERC20 is IERC20 {
    function mint(uint amount) public virtual;
    function mintTo(address account, uint amount) public virtual;
    function burn(uint amount) public virtual;
    function setMinter(address account, bool isMinter) public virtual;
}

// File: contracts\interfaces\IPopMarketplace.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

abstract contract IPopMarketplace {
    function submitMlp(address _token0, address _token1, uint _liquidity, uint _endDate, uint _bonusToken0, uint _bonusToken1) public virtual;
    function endMlp(uint _mlpId) public virtual returns(uint);
}

// File: contracts\PopMarketplace.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;









contract PopMarketplace is IFeesController, IPopMarketplace, Ownable {
    address public uniswapFactory;
    address public uniswapRouter;
    IMintableERC20 public popToken;
    address[] public allMlp;
    address private _feesTo = msg.sender;
    uint256 private _feesPpm;
    uint256 public pendingMlpCount;
    IRewardManager public rewardManager;
    using SafeERC20 for IERC20;

    mapping(uint256 => PendingMlp) public getMlp;

    enum MlpStatus {PENDING, APPROVED, CANCELED, ENDED}

    struct PendingMlp {
        address uniswapPair;
        address submitter;
        uint256 liquidity;
        uint256 endDate;
        MlpStatus status;
        uint256 bonusToken0;
        uint256 bonusToken1;
    }

    event MlpCreated(address indexed mlp);
    event MlpSubmitted(uint256 id);
    event MlpCanceled(uint256 id);
    event MlpEnded(uint256 id);

    constructor(
        address _popToken,
        address _uniswapFactory,
        address _uniswapRouter,
        address _rewardManager
    ) public {
        popToken = IMintableERC20(_popToken);
        uniswapFactory = _uniswapFactory;
        uniswapRouter = _uniswapRouter;
        rewardManager = IRewardManager(_rewardManager);
    }

    function submitMlp(
        address _token0,
        address _token1,
        uint256 _liquidity,
        uint256 _endDate,
        uint256 _bonusToken0,
        uint256 _bonusToken1
    ) public override {
        require(_endDate > now, "end date can not be higher than now");

        IUniswapV2Pair pair =
            IUniswapV2Pair(
                UniswapV2Library.pairFor(uniswapFactory, _token0, _token1)
            );
        require(address(pair) != address(0), "pair address can not be 0");

        if (_liquidity > 0) {
            IERC20(address(pair)).safeTransferFrom(
                msg.sender,
                address(this),
                _liquidity
            );
        }
        if (_bonusToken0 > 0) {
            IERC20(_token0).safeTransferFrom(
                msg.sender,
                address(this),
                _bonusToken0
            );
        }
        if (_bonusToken1 > 0) {
            IERC20(_token1).safeTransferFrom(
                msg.sender,
                address(this),
                _bonusToken1
            );
        }

        if (_token0 != pair.token0()) {
            uint256 tmp = _bonusToken0;
            _bonusToken0 = _bonusToken1;
            _bonusToken1 = tmp;
        }

        getMlp[pendingMlpCount++] = PendingMlp({
            uniswapPair: address(pair),
            submitter: msg.sender,
            liquidity: _liquidity,
            endDate: _endDate,
            status: MlpStatus.PENDING,
            bonusToken0: _bonusToken0,
            bonusToken1: _bonusToken1
        });
        emit MlpSubmitted(pendingMlpCount - 1);
    }

    function approveMlp(uint256 _mlpId, uint256 _allocPoint)
        external
        onlyOwner()
        returns (address mlpAddress)
    {
        PendingMlp storage pendingMlp = getMlp[_mlpId];
        require(pendingMlp.status == MlpStatus.PENDING);

        MLP newMlp =
            new MLP(
                pendingMlp.uniswapPair,
                pendingMlp.submitter,
                pendingMlp.endDate,
                uniswapRouter,
                address(this),
                rewardManager,
                pendingMlp.bonusToken0,
                pendingMlp.bonusToken1
            );
        mlpAddress = address(newMlp);
        rewardManager.add(_allocPoint, mlpAddress);
        popToken.setMinter(address(newMlp), true);
        allMlp.push(mlpAddress);
        IERC20(IUniswapV2Pair(pendingMlp.uniswapPair).token0()).transfer(
            mlpAddress,
            pendingMlp.bonusToken0
        );
        IERC20(IUniswapV2Pair(pendingMlp.uniswapPair).token1()).transfer(
            mlpAddress,
            pendingMlp.bonusToken1
        );

        pendingMlp.status = MlpStatus.APPROVED;
        emit MlpCreated(mlpAddress);

        return mlpAddress;
    }

    function cancelMlp(uint256 _mlpId) external {
        PendingMlp storage pendingMlp = getMlp[_mlpId];

        require(
            pendingMlp.submitter == msg.sender,
            "msg sender must be submitter"
        );
        require(
            pendingMlp.status == MlpStatus.PENDING,
            "mlp status must be pending"
        );

        if (pendingMlp.liquidity > 0) {
            IUniswapV2Pair pair = IUniswapV2Pair(pendingMlp.uniswapPair);
            IERC20(address(pair)).safeTransfer(
                pendingMlp.submitter,
                pendingMlp.liquidity
            );
        }

        pendingMlp.status = MlpStatus.CANCELED;
        emit MlpCanceled(_mlpId);
    }

    function setFeesTo(address _newFeesTo) public override onlyOwner {
        require(_newFeesTo != address(0), "address can not be 0");
        _feesTo = _newFeesTo;
    }

    function feesTo() public override returns (address) {
        return _feesTo;
    }

    function feesPpm() public override returns (uint256) {
        return _feesPpm;
    }

    function setFeesPpm(uint256 _newFeesPpm) public override onlyOwner {
        require(_newFeesPpm > 0, "new fees must be higher than 0");
        _feesPpm = _newFeesPpm;
    }

    function endMlp(uint256 _mlpId) public override returns (uint256) {
        PendingMlp storage pendingMlp = getMlp[_mlpId];

        require(
            pendingMlp.submitter == msg.sender,
            "msg sender must be the mlp submitter"
        );
        require(
            pendingMlp.status == MlpStatus.APPROVED,
            "mlp status must be approved"
        );
        require(block.timestamp >= pendingMlp.endDate, "not yet ended");

        if (pendingMlp.liquidity > 0) {
            IUniswapV2Pair pair = IUniswapV2Pair(pendingMlp.uniswapPair);
            IERC20(address(pair)).safeTransfer(
                pendingMlp.submitter,
                pendingMlp.liquidity
            );
        }

        pendingMlp.status = MlpStatus.ENDED;
        emit MlpEnded(_mlpId);
        return pendingMlp.liquidity;
    }
}