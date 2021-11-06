// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapAdapter {
  function tokenToTokenExcess(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount,
    uint tokenOutAmount
  ) external view returns (address[] memory excessTokens, int[] memory excessAmounts);

  function ethToTokenExcess(
    IERC20 token,
    uint ethAmount,
    uint tokenAmount
  ) external view returns (address[] memory excessTokens, int[] memory excessAmounts);

  function tokenToEthExcess(
    IERC20 token,
    uint tokenAmount,
    uint ethAmount
  ) external view returns (address[] memory excessTokens, int[] memory excessAmounts);

  function tokenToTokenOutputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount
  ) external view returns (uint tokenOutAmount);

  function tokenToTokenInputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenOutAmount
  ) external view returns (uint tokenInAmount);

  function ethToTokenOutputAmount(
    IERC20 token,
    uint ethInAmount
  ) external view returns (uint tokenOutAmount);

  function ethToTokenInputAmount(
    IERC20 token,
    uint tokenOutAmount
  ) external view returns (uint ethInAmount);

  function tokenToEthOutputAmount(
    IERC20 token,
    uint tokenInAmount
  ) external view returns (uint ethOutAmount);

  function tokenToEthInputAmount(
    IERC20 token,
    uint ethOutAmount
  ) external view returns (uint tokenInAmount);

  function tokenToToken(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount,
    uint tokenOutAmount,
    address account
  ) external;

  function ethToToken(
    IERC20 token,
    uint tokenAmount,
    address account
  ) external payable;

  function tokenToEth(
    IERC20 token,
    uint tokenAmount,
    uint ethAmount,
    address account
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import '../../Libraries/TransferHelper.sol';
import "../ISwapAdapter.sol";
import "../IWETH.sol";
import "./UniswapV2Library.sol";

abstract contract UniV2AdapterCore is ISwapAdapter {
  IWETH public weth;
  address public factory;

  constructor (IWETH _weth, address _factory) {
    weth = _weth;
    factory = _factory;
  }

  function tokenToTokenOutputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount
  ) public view override virtual returns (uint tokenOutAmount) {
    tokenOutAmount = _amountOut(tokenIn, tokenOut, tokenInAmount);
  }

  function tokenToTokenInputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenOutAmount
  ) public view override virtual returns (uint tokenInAmount) {
    tokenInAmount = _amountIn(tokenIn, tokenOut, tokenOutAmount);
  }

  function ethToTokenOutputAmount(
    IERC20 token,
    uint ethInAmount
  ) public view override virtual returns (uint tokenOutAmount) {
    tokenOutAmount = _amountOut(IERC20(address(weth)), token, ethInAmount);
  }

  function ethToTokenInputAmount(
    IERC20 token,
    uint tokenOutAmount
  ) public view override virtual returns (uint ethInAmount) {
    ethInAmount = _amountIn(IERC20(address(weth)), token, tokenOutAmount);
  }

  function tokenToEthOutputAmount(
    IERC20 token,
    uint tokenInAmount
  ) public view override virtual returns (uint ethOutAmount) {
    ethOutAmount = _amountOut(token, IERC20(address(weth)), tokenInAmount);
  }

  function tokenToEthInputAmount(
    IERC20 token,
    uint ethOutAmount
  ) public view override virtual returns (uint tokenInAmount) {
    tokenInAmount = _amountIn(token, IERC20(address(weth)), ethOutAmount);
  }

  function _singlePairSwap(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address to)
   internal
  {
    _swap(_amounts(tokenInAmount, tokenOutAmount), _path(tokenIn, tokenOut), to);
  }

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = UniswapV2Library.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
      IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  function _transferInputToPair(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount) internal {
    TransferHelper.safeTransfer(
      address(tokenIn),
      UniswapV2Library.pairFor(factory, address(tokenIn), address(tokenOut)),
      tokenInAmount
    );
  }

  function _amountOut(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount)
    internal view
    returns (uint tokenOutAmount)
  {
    address[] memory path = _path(tokenIn, tokenOut);
    tokenOutAmount = UniswapV2Library.getAmountsOut(factory, tokenInAmount, path)[1];
  }

  function _amountIn(IERC20 tokenIn, IERC20 tokenOut, uint tokenOutAmount)
    internal view
    returns (uint tokenInAmount)
  {
    address[] memory path = _path(tokenIn, tokenOut);
    tokenInAmount = UniswapV2Library.getAmountsIn(factory, tokenOutAmount, path)[0];
  }

  function _path (IERC20 tokenIn, IERC20 tokenOut)
    internal pure
    returns (address[] memory path)
  {
    path = new address[](2);
    path[0] = address(tokenIn);
    path[1] = address(tokenOut);
  }

  function _amounts (uint amountIn, uint amountOut)
    internal pure
    returns (uint[] memory amounts)
  {
    amounts = new uint[](2);
    amounts[0] = amountIn;
    amounts[1] = amountOut;
  }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IUniswapV2Pair.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "../Adapters/Withdrawable.sol";
import "../Adapters/UniV2/UniV2AdapterCore.sol";

contract MockUniV2Adapter is UniV2AdapterCore, Withdrawable {

  constructor(IWETH _weth, address _factory, address _owner)
    UniV2AdapterCore(_weth, _factory)
    Withdrawable(_owner)
  { }

  receive() external payable {}

  function tokenToTokenExcess(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount) external view override returns (address[] memory excessTokens, int[] memory excessAmounts) { }
  function ethToTokenExcess(IERC20 token, uint ethAmount, uint tokenAmount) external view override returns (address[] memory excessTokens, int[] memory excessAmounts) { }
  function tokenToEthExcess(IERC20 token, uint tokenAmount, uint ethAmount) external view override returns (address[] memory excessTokens, int[] memory excessAmounts) { }
  function tokenToToken(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address account) external override { }
  function ethToToken(IERC20 token, uint tokenAmount, address account) external payable override { }
  function tokenToEth(IERC20 token, uint tokenAmount, uint ethAmount, address account) external override { }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '../Libraries/TransferHelper.sol';

contract Withdrawable is Ownable {
  constructor (address _owner) {
    transferOwnership(_owner);
  }

  function withdrawToken(IERC20 token, uint amount, address to) external onlyOwner {
    TransferHelper.safeTransfer(address(token), to, amount);
  }

  function withdrawEth(uint amount, address payable to) external onlyOwner {
    (bool success, ) = to.call{value: amount}("");
    require(success, "Withdrawable: withdrawEth call failed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "../Withdrawable.sol";
import "./UniV2AdapterCore.sol";

contract UniV2ExcessWethCrossPair is UniV2AdapterCore, Withdrawable {
  constructor(IWETH _weth, address _factory, address _owner)
    UniV2AdapterCore(_weth, _factory)
    Withdrawable(_owner)
  { }

  function tokenToTokenOutputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount
  ) public view override returns (uint tokenOutAmount) {
    IERC20 wethToken = IERC20(address(weth));
    uint wethOut = _amountOut(tokenIn, wethToken, tokenInAmount);
    tokenOutAmount = _amountOut(wethToken, tokenOut, wethOut);
  }

  function tokenToTokenInputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenOutAmount
  ) public view override returns (uint tokenInAmount) {
    IERC20 wethToken = IERC20(address(weth));
    uint wethIn = _amountIn(wethToken, tokenOut, tokenOutAmount);
    tokenInAmount = _amountIn(tokenIn, wethToken, wethIn);
  }

  function tokenToTokenExcess(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    uint wethOut = _amountOut(tokenIn, IERC20(address(weth)), tokenInAmount);
    uint wethIn = _amountIn(IERC20(address(weth)), tokenOut, tokenOutAmount);
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(wethOut - wethIn);
  }

  function ethToTokenExcess(IERC20 token, uint ethAmount, uint tokenAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(ethAmount - _amountIn(IERC20(address(weth)), token, tokenAmount));
  }

  function tokenToEthExcess(IERC20 token, uint tokenAmount, uint ethAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(_amountOut(token, IERC20(address(weth)), tokenAmount) - ethAmount);
  }

  function tokenToToken(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address account) external override {
    IERC20 wethToken = IERC20(address(weth));
    uint wethOut = _amountOut(tokenIn, wethToken, tokenInAmount);
    uint wethIn = _amountIn(wethToken, tokenOut, tokenOutAmount);
    require(wethOut >= wethIn, 'UniV2ExcessWethCrossPair: tokenToToken INSUFFICIENT_INPUT_AMOUNT');
    _transferInputToPair(tokenIn, wethToken, tokenInAmount);
    _singlePairSwap(tokenIn, wethToken, tokenInAmount, wethOut, address(this));
    _transferInputToPair(wethToken, tokenOut, wethIn);
    _singlePairSwap(wethToken, tokenOut, wethIn, tokenOutAmount, account);
  }

  function ethToToken(IERC20 token, uint tokenAmount, address account) external payable override {
    IERC20 tokenIn = IERC20(address(weth));
    IERC20 tokenOut = token;
    uint swapInput = _amountIn(tokenIn, tokenOut, tokenAmount);
    require(msg.value >= swapInput, 'UniV2ExcessWethCrossPair: ethToToken INSUFFICIENT_INPUT_AMOUNT');
    weth.deposit{value: swapInput}();
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, tokenAmount, account);
  }

  function tokenToEth(IERC20 token, uint tokenAmount, uint ethAmount, address account) external override {
    IERC20 tokenIn = token;
    IERC20 tokenOut = IERC20(address(weth));
    uint swapOutput = _amountOut(tokenIn, tokenOut, tokenAmount);
    require(swapOutput >= ethAmount, 'UniV2ExcessWethCrossPair: tokenToEth INSUFFICIENT_OUTPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, tokenAmount);
    _singlePairSwap(tokenIn, tokenOut, tokenAmount, swapOutput, address(this));
    weth.withdraw(swapOutput);
    TransferHelper.safeTransferETH(account, ethAmount);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "../Withdrawable.sol";
import "./UniV2AdapterCore.sol";

contract UniV2ExcessOut is UniV2AdapterCore, Withdrawable {
  constructor(IWETH _weth, address _factory, address _owner)
    UniV2AdapterCore(_weth, _factory)
    Withdrawable(_owner)
  { }

  function tokenToTokenExcess(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(tokenOut);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(_amountOut(tokenIn, tokenOut, tokenInAmount) - tokenOutAmount);
  }

  function ethToTokenExcess(IERC20 token, uint ethAmount, uint tokenAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(token);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(_amountOut(IERC20(address(weth)), token, ethAmount) - tokenAmount);
  }

  function tokenToEthExcess(IERC20 token, uint tokenAmount, uint ethAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(_amountOut(token, IERC20(address(weth)), tokenAmount) - ethAmount);
  }

  function tokenToToken(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address account) external override {
    uint swapOutput = _amountOut(tokenIn, tokenOut, tokenInAmount);
    require(swapOutput >= tokenOutAmount, 'UniV2ExcessOut: tokenToToken INSUFFICIENT_OUTPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, tokenInAmount);
    _singlePairSwap(tokenIn, tokenOut, tokenInAmount, swapOutput, address(this));
    TransferHelper.safeTransfer(address(tokenOut), account, tokenOutAmount);
  }

  function ethToToken(IERC20 token, uint tokenAmount, address account) external payable override {
    IERC20 tokenIn = IERC20(address(weth));
    IERC20 tokenOut = token;
    uint swapOutput = _amountOut(tokenIn, tokenOut, msg.value);
    require(swapOutput >= tokenAmount, 'UniV2ExcessOut: ethToToken INSUFFICIENT_OUTPUT_AMOUNT');
    weth.deposit{value: msg.value}();
    _transferInputToPair(tokenIn, tokenOut, msg.value);
    _singlePairSwap(tokenIn, tokenOut, msg.value, swapOutput, address(this));
    TransferHelper.safeTransfer(address(tokenOut), account, tokenAmount);
  }

  function tokenToEth(IERC20 token, uint tokenAmount, uint ethAmount, address account) external override {
    IERC20 tokenIn = token;
    IERC20 tokenOut = IERC20(address(weth));
    uint swapOutput = _amountOut(tokenIn, tokenOut, tokenAmount);
    require(swapOutput >= ethAmount, 'UniV2ExcessOut: tokenToEth INSUFFICIENT_OUTPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, tokenAmount);
    _singlePairSwap(tokenIn, tokenOut, tokenAmount, swapOutput, address(this));
    weth.withdraw(swapOutput);
    TransferHelper.safeTransferETH(account, ethAmount);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "../Withdrawable.sol";
import "./UniV2AdapterCore.sol";

contract UniV2ExcessIn is UniV2AdapterCore, Withdrawable {
  constructor(IWETH _weth, address _factory, address _owner)
    UniV2AdapterCore(_weth, _factory)
    Withdrawable(_owner)
  { }

  function tokenToTokenExcess(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(tokenIn);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(tokenInAmount - _amountIn(tokenIn, tokenOut, tokenOutAmount));
  }

  function ethToTokenExcess(IERC20 token, uint ethAmount, uint tokenAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(0);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(ethAmount - _amountIn(IERC20(address(weth)), token, tokenAmount));
  }

  function tokenToEthExcess(IERC20 token, uint tokenAmount, uint ethAmount)
    external view override
    returns (address[] memory excessTokens, int[] memory excessAmounts)
  {
    excessTokens = new address[](1);
    excessTokens[0] = address(token);
    excessAmounts = new int[](1);
    excessAmounts[0] = int(tokenAmount - _amountIn(token, IERC20(address(weth)), ethAmount));
  }

  function tokenToToken(IERC20 tokenIn, IERC20 tokenOut, uint tokenInAmount, uint tokenOutAmount, address account) external override {
    uint swapInput = _amountIn(tokenIn, tokenOut, tokenOutAmount);
    require(tokenInAmount >= swapInput, 'UniV2ExcessIn: tokenToToken INSUFFICIENT_INPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, tokenOutAmount, account);
  }

  function ethToToken(IERC20 token, uint tokenAmount, address account) external payable override {
    IERC20 tokenIn = IERC20(address(weth));
    IERC20 tokenOut = token;
    uint swapInput = _amountIn(tokenIn, tokenOut, tokenAmount);
    require(msg.value >= swapInput, 'UniV2ExcessIn: ethToToken INSUFFICIENT_INPUT_AMOUNT');
    weth.deposit{value: swapInput}();
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, tokenAmount, account);
  }

  function tokenToEth(IERC20 token, uint tokenAmount, uint ethAmount, address account) external override {
    IERC20 tokenIn = token;
    IERC20 tokenOut = IERC20(address(weth));
    uint swapInput = _amountIn(tokenIn, tokenOut, ethAmount);
    require(tokenAmount >= swapInput, 'UniV2ExcessIn: tokenToEth INSUFFICIENT_INPUT_AMOUNT');
    _transferInputToPair(tokenIn, tokenOut, swapInput);
    _singlePairSwap(tokenIn, tokenOut, swapInput, ethAmount, address(this));
    weth.withdraw(ethAmount);
    TransferHelper.safeTransferETH(account, ethAmount);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@brinkninja/range-orders/contracts/interfaces/IRangeOrderPositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../IWETH.sol";
import "../Withdrawable.sol";

contract UniV3RangeOrdersAdapter is Withdrawable {

  IRangeOrderPositionManager public immutable rangeOrderPositionManager;
  IWETH public immutable weth;

  receive() external payable {}

  constructor(IRangeOrderPositionManager _rangeOrderPositionManager, IWETH _weth, address _owner)
    Withdrawable(_owner)
  {
    rangeOrderPositionManager = _rangeOrderPositionManager;
    weth = _weth;
  }

  function sendRangeOrder (IRangeOrderPositionManager.IncreaseLiquidityParams calldata params)
    external
  {
    IERC20(params.tokenIn).approve(address(rangeOrderPositionManager), params.inputAmount);
    rangeOrderPositionManager.increaseLiquidity(params);
  }

  function sendRangeOrderETH (IRangeOrderPositionManager.IncreaseLiquidityParams calldata params)
    external payable
  {
    weth.deposit{value: params.inputAmount}();
    IERC20(address(weth)).approve(address(rangeOrderPositionManager), params.inputAmount);
    rangeOrderPositionManager.increaseLiquidity(params);
  }

  function sendRangeOrderBatch (IRangeOrderPositionManager.IncreaseLiquidityMultiParams calldata params)
    external
  {
    IERC20(params.tokenIn).approve(address(rangeOrderPositionManager), params.totalInputAmount);
    rangeOrderPositionManager.increaseLiquidityMulti(params);
  }

  function sendRangeOrderBatchETH (IRangeOrderPositionManager.IncreaseLiquidityMultiParams calldata params)
    external payable
  {
    weth.deposit{value: params.totalInputAmount}();
    IERC20(address(weth)).approve(address(rangeOrderPositionManager), params.totalInputAmount);
    rangeOrderPositionManager.increaseLiquidityMulti(params);
  }

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";

interface IRangeOrderPositionManager {

  /// @return Returns the address of the Uniswap V3 factory
  function factory() external view returns (address);

  struct Position {
    // amount of liquidity for this position
    uint128 liquidity;
    // true when liquidity for the position has been burned on UniswapV3Pool after position has fully crossed
    bool liquidated;
  }

  function positionIndexes (bytes32 positionHash)
    external view
    returns (uint256 positionIndex);

  function positions (bytes32 positionHash, uint256 positionIndex)
    external view
    returns (Position memory position);

  function liquidityBalances (bytes32 positionHash, uint256 positionIndex, address owner)
    external view
    returns (uint128 liquidityBalance);

  struct IncreaseLiquidityParams {
    address owner;
    uint256 inputAmount;
    address tokenIn;
    address tokenOut;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
  }

  /// @notice Increases liquidity for a position owner
  /// @param params owner The owner of the position
  /// inputAmount Amount of tokenIn provided
  /// tokenIn Input token for the position
  /// tokenOut Output token for the position
  /// fee The fee pool for the position
  /// tickLower Lower bound for the position
  /// tickUpper Upper bound for the position
  function increaseLiquidity(IncreaseLiquidityParams calldata params) external;

  struct IncreaseLiquidityMultiParams {
    address[] owners;
    uint256[] inputAmounts;
    uint256 totalInputAmount;
    address tokenIn;
    address tokenOut;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
  }

  /// @notice Increases liquidity for multiple position owners
  /// @param params owners Array of owners
  /// inputAmounts Array of tokenIn amounts for each owner
  /// totalInputAmount Total of inputAmounts, required to be equal to the sum of inputAmounts values
  /// tokenIn Input token for the position
  /// tokenOut Output token for the position
  /// fee The fee pool for the position
  /// tickLower Lower bound for the position
  /// tickUpper Upper bound for the position
  function increaseLiquidityMulti(IncreaseLiquidityMultiParams calldata params) external;

  struct DecreaseLiquidityParams {
    uint256 positionIndex;
    address tokenIn;
    address tokenOut;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
    address recipient;
  }

  /// @notice Decreases liquidity
  /// @param params positionIndex Index of the position
  /// tokenIn Input token for the position
  /// tokenOut Output token for the position
  /// fee The fee pool for the position
  /// tickLower Lower bound for the position
  /// tickUpper Upper bound for the position
  /// liquidity Amount of liquidity to decrease from the position
  /// recipient The recipient of the collected assets
  function decreaseLiquidity (DecreaseLiquidityParams calldata params) external;

  struct LiquidateParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    address recipient;
  }

  /// @notice Liquidates a range order position that has been crossed
  /// @dev Burns all pool liquidity for a range order position and collects assets to this contract
  /// @param params tokenIn Input token for the position
  /// tokenOut Output token for the position
  /// fee The fee pool for the position
  /// tickLower Lower bound for the position
  /// tickUpper Upper bound for the position
  /// liquidity Amount of liquidity to decrease from the position
  /// recipient The recipient of the collected assets
  function liquidate(LiquidateParams calldata params) external;

  struct ResolveParams {
    uint256 positionIndex;
    address tokenIn;
    address tokenOut;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    address owner;
    uint128 liquidity;
  }

  /// @notice Resolves a range order position that has been liquidated
  /// @dev Transfers liquidated assets from this contract to the position owner
  /// @param params positionIndex Index of the position
  /// tokenIn Input token for the position
  /// tokenOut Output token for the position
  /// fee The fee pool for the position
  /// tickLower Lower bound for the position
  /// tickUpper Upper bound for the position
  /// owner The position owner
  function resolve (ResolveParams calldata params) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// feeGrowthOutsideX128 values can only be used if the tick is initialized,
    /// i.e. if liquidityGross is greater than 0. In addition, these values are only relative and are used to
    /// compute snapshots.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns 8 packed tick seconds outside values. See SecondsOutside for more information
    function secondsOutside(int24 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the current tick multiplied by seconds elapsed for the life of the pool as of the
    /// observation,
    /// Returns liquidityCumulative the current liquidity multiplied by seconds elapsed for the life of the pool as of
    /// the observation,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 liquidityCumulative,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns a relative timestamp value representing how long, in seconds, the pool has spent between
    /// tickLower and tickUpper
    /// @dev This timestamp is strictly relative. To get a useful elapsed time (i.e., duration) value, the value returned
    /// by this method should be checkpointed externally after a position is minted, and again before a position is
    /// burned. Thus the external contract must control the lifecycle of the position.
    /// @param tickLower The lower tick of the range for which to get the seconds inside
    /// @param tickUpper The upper tick of the range for which to get the seconds inside
    /// @return A relative timestamp for how long the pool spent in the tick range
    function secondsInside(int24 tickLower, int24 tickUpper) external view returns (uint32);

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return liquidityCumulatives Cumulative liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract TestERC20 {
  using SafeMath for uint;

  bool public _broken;

  string public name;
  string public symbol;
  uint8 public decimals = 18;

  uint  public totalSupply;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;

  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  constructor (string memory _name, string memory _symbol, uint8 _decimals) {
    uint chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(_name)),
        keccak256(bytes('1')),
        chainId,
        address(this)
      )
    );
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  function breakMe() external {
    _broken = true;
  }

  function mint(address to, uint value) external {
    require(to != address(0), "ERC20: mint to the zero address");

    totalSupply = totalSupply.add(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(address(0), to, value);
  }

  function burn(address from, uint value) external {
    require(from != address(0), "ERC20: burn from the zero address");

    balanceOf[from] = balanceOf[from].sub(value);
    totalSupply = totalSupply.sub(value);
    emit Transfer(from, address(0), value);
  }

  function approve(address spender, uint value) external returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transfer(address to, uint value) external returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint value) external returns (bool) {
    _transfer(from, to, value);

    uint256 currentAllowance = allowance[from][msg.sender];
    require(currentAllowance >= value, "TestERC20: transfer value exceeds allowance");
    _approve(from, msg.sender, currentAllowance - value);

    return true;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, 'EXPIRED');
    bytes32 digest = keccak256(
        abi.encodePacked(
            '\x19\x01',
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
    _approve(owner, spender, value);
  }

  function _approve(address owner, address spender, uint value) private {
    require(!_broken, "TestERC20._approve: Token is broken");
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _transfer(address from, address to, uint value) private {
    require(!_broken, "TestERC20._transfer: Token is broken");
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    balanceOf[from] = balanceOf[from].sub(value, "ERC20: transfer amount exceeds balance");
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(from, to, value);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "@brinkninja/utils/contracts/TestERC20.sol";

contract Imports { }