//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBalancerPool.sol";
import "./SwapperV1.sol";

/**
    @title Multi Swap Tool a.k.a. Swapper
    @author wafflemakr
*/
contract SwapperV2 is SwapperV1 {
  using SafeMath for uint256;
  using UniswapV2ExchangeLib for IUniswapV2Exchange;

  // ======== STATE V2 ======== //

  enum Dex { UNISWAP, BALANCER }

  struct Swaps {
    address token;
    address pool;
    uint256 distribution;
    Dex dex;
  }

  // =========================== //

  /**
        @dev infite approve if allowance is not enough
   */
  function _setApproval(
    address to,
    address erc20,
    uint256 srcAmt
  ) internal {
    if (srcAmt > IERC20(erc20).allowance(address(this), to)) {
      IERC20(erc20).approve(to, type(uint256).max);
    }
  }

  /**
        @notice make a swap using uniswap
   */
  function _swapUniswap(
    address pool,
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount
  ) internal {
    require(fromToken != destToken, "SAME_TOKEN");
    require(amount > 0, "ZERO-AMOUNT");

    uint256 returnAmount =
      IUniswapV2Exchange(pool).getReturn(fromToken, destToken, amount);

    fromToken.transfer(pool, amount);
    if (
      uint256(uint160(address(fromToken))) <
      uint256(uint160(address(destToken)))
    ) {
      IUniswapV2Exchange(pool).swap(0, returnAmount, msg.sender, "");
    } else {
      IUniswapV2Exchange(pool).swap(returnAmount, 0, msg.sender, "");
    }
  }

  /**
        @notice make a swap using balancer
    */
  function _swapBalancer(
    address pool,
    address fromToken,
    address destToken,
    uint256 amount
  ) internal {
    _setApproval(pool, fromToken, amount);

    (uint256 tokenAmountOut, ) =
      IBalancerPool(pool).swapExactAmountIn(
        fromToken,
        amount,
        destToken,
        1,
        type(uint256).max
      );

    IERC20(destToken).transfer(msg.sender, tokenAmountOut);
  }

  /**
    @notice swap ETH for multiple tokens according to distribution % and a dex
    @dev tokens length should be equal to distribution length
    @dev msg.value will be completely converted to tokens
    @param swaps array of swap struct containing details about the swap to perform
   */
  function swapMultiple(Swaps[] memory swaps) external payable {
    require(msg.value > 0);
    require(swaps.length < 10);

    // Calculate ETH left after subtracting fee
    uint256 afterFee = msg.value.sub(msg.value.mul(fee).div(10000));

    // Wrap all ether that is going to be used in the swap
    WETH.deposit{ value: afterFee }();

    for (uint256 i = 0; i < swaps.length; i++) {
      if (swaps[i].dex == Dex.UNISWAP)
        _swapUniswap(
          swaps[i].pool,
          WETH,
          IERC20(swaps[i].token),
          afterFee.mul(swaps[i].distribution).div(10000)
        );
      else if (swaps[i].dex == Dex.BALANCER)
        _swapBalancer(
          swaps[i].pool,
          address(WETH),
          swaps[i].token,
          afterFee.mul(swaps[i].distribution).div(10000)
        );
      else revert("DEX NOT SUPPORTED");
    }

    // Send remaining ETH to fee recipient
    payable(feeRecipient).transfer(address(this).balance);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalancerPool {
  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external returns (uint256 poolAmountOut);

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint256 tokenAmountOut);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IUniswapV2Exchange.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IBalancerRegistry.sol";
import "./interfaces/IBalancerPool.sol";

/**
    @title Multi Swap Tool a.k.a. Swapper
    @author wafflemakr
*/
contract SwapperV1 is Initializable {
  using SafeMath for uint256;
  using UniswapV2ExchangeLib for IUniswapV2Exchange;

  // ======== STATE V1 ======== //

  IUniswapV2Router internal constant router =
    IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  IUniswapV2Factory internal constant factory =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

  IWETH internal constant WETH =
    IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Receives 0.1% of the total ETH used for swaps
  address public feeRecipient;

  // fee charged, initializes in 0.1%
  uint256 public fee;

  // =========================== //

  /**
    @notice intialize contract variables
   */
  function initialize(address _feeRecipient, uint256 _fee)
    external
    initializer
  {
    require(_feeRecipient != address(0));
    require(_fee > 0);
    feeRecipient = _feeRecipient;
    fee = _fee;
  }

  /**
    @notice get erc20 representative address for ETH
   */
  function getAddressETH() public pure returns (address eth) {
    eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  }

  /**
    @notice make a swap using uniswap
   */
  function _swapUniswap(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount
  ) internal returns (uint256 returnAmount) {
    require(fromToken != destToken, "SAME_TOKEN");
    require(amount > 0, "ZERO-AMOUNT");

    IUniswapV2Exchange exchange = factory.getPair(fromToken, destToken);
    returnAmount = exchange.getReturn(fromToken, destToken, amount);

    fromToken.transfer(address(exchange), amount);
    if (
      uint256(uint160(address(fromToken))) <
      uint256(uint160(address(destToken)))
    ) {
      exchange.swap(0, returnAmount, msg.sender, "");
    } else {
      exchange.swap(returnAmount, 0, msg.sender, "");
    }
  }

  /**
    @notice swap ETH for multiple tokens according to distribution %
    @dev tokens length should be equal to distribution length
    @dev msg.value will be completely converted to tokens
    @param tokens array of tokens to swap to
    @param distribution array of % amount to convert eth from (3054 = 30.54%)
   */
  function swap(address[] memory tokens, uint256[] memory distribution)
    external
    payable
  {
    require(msg.value > 0);
    require(tokens.length == distribution.length);

    // Calculate ETH left after subtracting fee
    uint256 afterFee = msg.value.sub(msg.value.mul(fee).div(100000));

    // Wrap all ether that is going to be used in the swap
    WETH.deposit{ value: afterFee }();

    for (uint256 i = 0; i < tokens.length; i++) {
      _swapUniswap(
        WETH,
        IERC20(tokens[i]),
        afterFee.mul(distribution[i]).div(10000)
      );
    }

    // Send remaining ETH to fee recipient
    payable(feeRecipient).transfer(address(this).balance);
  }

  /**
    @notice swap ETH for multiple tokens according to distribution % using router and WETH
    @dev tokens length should be equal to distribution length
    @dev msg.value will be completely converted to tokens
    @param tokens array of tokens to swap to
    @param distribution array of % amount to convert eth from (3054 = 30.54%)
   */
  function swapWithRouter(
    address[] memory tokens,
    uint256[] memory distribution
  ) external payable {
    require(msg.value > 0);
    require(tokens.length == distribution.length);

    // Calculate ETH left after subtracting fee
    uint256 afterFee = msg.value.sub(msg.value.mul(fee).div(100000));

    // Wrap all ether that is going to be used in the swap
    WETH.deposit{ value: afterFee }();
    WETH.approve(address(router), afterFee);

    address[] memory path = new address[](2);
    path[0] = address(WETH);

    for (uint256 i = 0; i < tokens.length; i++) {
      path[1] = tokens[i];
      router.swapExactTokensForTokens(
        afterFee.mul(distribution[i]).div(10000),
        1,
        path,
        msg.sender,
        block.timestamp + 1
      );
    }

    // Send remaining ETH to fee recipient
    payable(feeRecipient).transfer(address(this).balance);
  }

  /**
    @notice swap ETH for multiple tokens according to distribution % using router and ETH
    @dev tokens length should be equal to distribution length
    @dev msg.value will be completely converted to tokens
    @param tokens array of tokens to swap to
    @param distribution array of % amount to convert eth from (3054 = 30.54%)
   */
  function swapWithRouterETH(
    address[] memory tokens,
    uint256[] memory distribution
  ) external payable {
    require(msg.value > 0);
    require(tokens.length == distribution.length);

    // Calculate ETH left after subtracting fee
    uint256 afterFee = msg.value.sub(msg.value.mul(fee).div(100000));

    address[] memory path = new address[](2);
    path[0] = address(WETH);

    for (uint256 i = 0; i < tokens.length; i++) {
      path[1] = tokens[i];

      uint256 amountETH = afterFee.mul(distribution[i]).div(10000);

      router.swapExactETHForTokens{ value: amountETH }(
        amountETH,
        path,
        msg.sender,
        block.timestamp + 1
      );
    }

    // Send remaining ETH to fee recipient
    payable(feeRecipient).transfer(address(this).balance);
  }
}

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Exchange {
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

library UniswapV2ExchangeLib {
  using SafeMath for uint256;

  function getReturn(
    IUniswapV2Exchange exchange,
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amountIn
  ) internal view returns (uint256) {
    uint256 reserveIn = fromToken.balanceOf(address(exchange));
    uint256 reserveOut = destToken.balanceOf(address(exchange));

    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    return (denominator == 0) ? 0 : numerator.div(denominator);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

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

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

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

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Exchange.sol";

interface IUniswapV2Factory {
  function getPair(IERC20 tokenA, IERC20 tokenB)
    external
    view
    returns (IUniswapV2Exchange pair);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
  function deposit() external payable virtual;

  function withdraw(uint256 amount) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBalancerRegistry {
  function getBestPoolsWithLimit(
    address fromToken,
    address destToken,
    uint256 limit
  ) external view returns (address[] memory pools);
}