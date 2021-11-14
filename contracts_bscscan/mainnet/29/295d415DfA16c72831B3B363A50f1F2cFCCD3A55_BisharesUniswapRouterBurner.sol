// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../core/balancer/BMath.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IIndexPool.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../lib/TransferHelper.sol";
import "../lib/UniswapV2Library.sol";


contract BisharesUniswapRouterBurner is BMath {
  address public immutable factory;
  address public immutable weth;

  constructor(address factory_, address weth_) {
    address zero = address(0);
    require(factory_ != zero, "BiShares: Factory is zero address");
    require(weth_ != zero, "BiShares: WETH is zero address");
    factory = factory_;
    weth = weth_;
  }

  receive() external payable {
    require(msg.sender == weth, "BiShares: Received ether");
  }

  function burnForAllTokensAndSwapForTokens(
    address indexPool,
    uint256[] memory minAmountsOut,
    address[] memory intermediaries,
    uint256 poolAmountIn,
    address tokenOut,
    uint256 minAmountOut
  ) external returns (uint256 amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      tokenOut,
      minAmountsOut,
      intermediaries,
      poolAmountIn,
      minAmountOut,
      msg.sender
    );
  }

  function burnForAllTokensAndSwapForETH(
    address indexPool,
    uint256[] memory minAmountsOut,
    address[] memory intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint256 amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      weth,
      minAmountsOut,
      intermediaries,
      poolAmountIn,
      minAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(amountOutTotal);
    TransferHelper.safeTransferETH(msg.sender, amountOutTotal);
  }

  function _getSwapAmountsForExit(
    address tokenIn,
    address intermediate,
    address tokenOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts, bool swap) {
    if (intermediate == address(0)) {
      assembly { mstore(path, 2) }
      path[1] = tokenOut;
    } else {
      assembly { mstore(path, 3) }
      path[1] = intermediate;
      path[2] = tokenOut;
    }
    path[0] = tokenIn;
    uint256 balance_ = IERC20(tokenIn).balanceOf(address(this));
    if (path[0] == tokenOut) {
      amounts = new uint256[](1);
      amounts[0] = balance_;
      return (amounts, swap);
    }
    amounts = UniswapV2Library.getAmountsOut(factory, balance_, path);
    swap = true;
  }

  function _burnForAllTokensAndSwap(
    address indexPool,
    address tokenOut,
    uint256[] memory minAmountsOut,
    address[] memory intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut,
    address recipient
  ) internal returns (uint256 amountOutTotal) {
    TransferHelper.safeTransferFrom(indexPool, msg.sender, address(this), poolAmountIn);
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      intermediaries.length == tokens.length && minAmountsOut.length == tokens.length,
      "BiShares: Invalid arrays length"
    );
    IIndexPool(indexPool).exitPool(poolAmountIn, minAmountsOut);
    amountOutTotal = _swapTokens(tokens, intermediaries, tokenOut, recipient);
    require(amountOutTotal >= minAmountOut, "BiShares: Insufficient output amount");
  }

  function _swap(uint256[] memory amounts, address[] memory path, address recipient) internal {
    for (uint256 i = 0; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, address token1) = UniswapV2Library.sortTokens(input, output);
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : recipient;
      IUniswapV2Pair(UniswapV2Library.calculatePair(factory, token0, token1)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  function _swapTokens(
    address[] memory tokens,
    address[] memory intermediaries,
    address tokenOut,
    address recipient
  ) private returns (uint256 amountOutTotal) {
    address[] memory path = new address[](3);
    bool swap;
    uint256[] memory amounts;
    for (uint256 i = 0; i < tokens.length; i++) {
      (amounts, swap) = _getSwapAmountsForExit(
        tokens[i],
        intermediaries[i],
        tokenOut,
        path
      );
      if (swap) {
        TransferHelper.safeTransfer(
          tokens[i],
          UniswapV2Library.pairFor(factory, tokens[i], path[1]),
          amounts[0]
        );
        _swap(amounts, path, recipient);
      }
      uint256 amountOut = amounts[amounts.length - 1];
      amountOutTotal = SafeMath.add(amountOutTotal, amountOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";

interface IUniswapFactory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

library UniswapV2Library {
  using SafeMath for uint256;
  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal view returns (address pair) {
    IUniswapFactory _factory = IUniswapFactory(factory);
    pair = _factory.getPair(token0, token1);
  }

  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }

  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IUniswapV2Pair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
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

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IIndexPool {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index index of address in tokens array
   * @param balance token balance
   */
  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function configure(
    address controller,
    string memory name,
    string memory symbol,
    address uniswapV2oracle,
    address uniswapV2router,
    address exitFeeReciver,
    address exitFeeReciverAdditional
  ) external returns (bool);
  function initialize(
    address[] memory tokens,
    uint256[] memory balances,
    uint96[] memory denorms,
    address tokenProvider
  ) external returns (bool);
  function setMaxPoolTokens(uint256 maxPoolTokens) external returns (bool);
  function delegateCompLikeToken(address token, address delegatee) external returns (bool);
  function setExitFeeRecipient(address exitFeeRecipient_, bool additional) external returns (bool);
  function reweighTokens(address[] memory tokens, uint96[] memory desiredDenorms) external returns (bool);
  function reindexTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms,
    uint256[] memory minimumBalances
  ) external returns (bool);
  function setMinimumBalance(address token, uint256 minimumBalance) external returns (bool);
  function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external returns (bool);
  function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external returns (bool);

  function oracle() external view returns (address);
  function router() external view returns (address);
  function isPublicSwap() external view returns (bool);
  function getController() external view returns (address);
  function getMaxPoolTokens() external view returns (uint256);
  function isBound(address t) external view returns (bool);
  function getNumTokens() external view returns (uint256);
  function getCurrentTokens() external view returns (address[] memory tokens);
  function getCurrentDesiredTokens() external view returns (address[] memory tokens);
  function getDenormalizedWeight(address token) external view returns (uint256);
  function getTokenRecord(address token) external view returns (Record memory record);
  function extrapolatePoolValueFromToken() external view returns (address token, uint256 extrapolatedValue);
  function getTotalDenormalizedWeight() external view returns (uint256);
  function getBalance(address token) external view returns (uint256);
  function getMinimumBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);
  function getExitFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./BConst.sol";


contract BNum is BConst {
  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "BiShares: Add overflow");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "BiShares: Sub overflow");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "BiShares: Mul overflow");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "BiShares: Mul overflow");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "BiShares: Div zero");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "BiShares: Div overflow");
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "BiShares: Div overflow");
    uint256 c2 = c1 / b;
    return c2;
  }

  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;
    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);
      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "BiShares: Bpow base too low");
    require(base <= MAX_BPOW_BASE, "BiShares: Bpow base too high");
    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);
    uint256 wholePow = bpowi(base, btoi(whole));
    if (remain == 0) {
      return wholePow;
    }
    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;
      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }
    return sum;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./BNum.sol";


contract BMath is BConst, BNum {
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) internal pure returns (uint256 spotPrice) {
    uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
    uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
    uint256 ratio = bdiv(numer, denom);
    uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
    return (spotPrice = bmul(ratio, scale));
  }

  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
    uint256 adjustedIn = bsub(BONE, swapFee);
    adjustedIn = bmul(tokenAmountIn, adjustedIn);
    uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
    uint256 foo = bpow(y, weightRatio);
    uint256 bar = bsub(BONE, foo);
    tokenAmountOut = bmul(tokenBalanceOut, bar);
    return tokenAmountOut;
  }

  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
    uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
    uint256 y = bdiv(tokenBalanceOut, diff);
    uint256 foo = bpow(y, weightRatio);
    foo = bsub(foo, BONE);
    tokenAmountIn = bsub(BONE, swapFee);
    tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
    return tokenAmountIn;
  }

  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));
    uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
    uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);
    uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    poolAmountOut = bsub(newPoolSupply, poolSupply);
    return poolAmountOut;
  }

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);
    uint256 boo = bdiv(BONE, normalizedWeight);
    uint256 tokenInRatio = bpow(poolRatio, boo);
    uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
    uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
    uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
    return tokenAmountIn;
  }

  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
    uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);
    uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
    uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);
    uint256 tokenAmountOutBeforeSwapFee = bsub(
      tokenBalanceOut,
      newTokenBalanceOut
    );
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
    return tokenAmountOut;
  }

  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) internal pure returns (uint256 poolAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    uint256 zoo = bsub(BONE, normalizedWeight);
    uint256 zar = bmul(zoo, swapFee);
    uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));
    uint256 newTokenBalanceOut = bsub(
      tokenBalanceOut,
      tokenAmountOutBeforeSwapFee
    );
    uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);
    uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);
    poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
    return poolAmountIn;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


contract BConst {
  uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;
  uint256 internal constant WEIGHT_CHANGE_PCT = BONE / 100;
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_BOUND_TOKENS = 2;
  uint256 internal constant MAX_BOUND_TOKENS = 25;
  uint256 internal constant EXIT_FEE = 1e16;
  uint256 internal constant MIN_WEIGHT = BONE / 8;
  uint256 internal constant MAX_WEIGHT = BONE * 25;
  uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 26;
  uint256 internal constant MIN_BALANCE = BONE / 10**12;
  uint256 internal constant INIT_POOL_SUPPLY = BONE * 100;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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