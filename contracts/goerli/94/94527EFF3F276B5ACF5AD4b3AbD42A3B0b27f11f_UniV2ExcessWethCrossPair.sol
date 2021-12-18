// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "./UniV2AdapterCore.sol";

contract UniV2ExcessWethCrossPair is UniV2AdapterCore {
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

import '../../Libraries/TransferHelper.sol';
import "../Withdrawable.sol";
import "../ISwapAdapter.sol";
import "../IWETH.sol";
import "./UniswapV2Library.sol";

abstract contract UniV2AdapterCore is ISwapAdapter, Withdrawable {
  IWETH public weth;
  address public factory;
  bool public initialized;

  function initialize (IWETH _weth, address _factory) external onlyOwner {
    require(!initialized, 'INITIALIZED');
    initialized = true;
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

import "../OpenZeppelin/Ownable.sol";
import "../OpenZeppelin/IERC20.sol";
import '../Libraries/TransferHelper.sol';

contract Withdrawable is Ownable {
  constructor () {
    transferOwnership(0x71795b2d53Ffbe5b1805FE725538E4f8fBD29e26);
  }

  function withdrawToken(IERC20 token, uint amount, address to) external onlyOwner {
    TransferHelper.safeTransfer(address(token), to, amount);
  }

  function withdrawEth(uint amount, address payable to) external onlyOwner {
    (bool success, ) = to.call{value: amount}("");
    require(success, "Withdrawable: withdrawEth call failed");
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "../OpenZeppelin/IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "../../OpenZeppelin/SafeMath.sol";
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

import "./Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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