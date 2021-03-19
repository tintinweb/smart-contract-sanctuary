// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "./BNum.sol";


contract BMath is BNum {
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

    //uint newBalTi = poolRatio^(1/weightTi) * balTi;
    uint256 boo = bdiv(BONE, normalizedWeight);
    uint256 tokenInRatio = bpow(poolRatio, boo);
    uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
    uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
    // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
    //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
    //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
    uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
    return tokenAmountIn;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


contract BNum {
  uint256 internal constant BONE = 1e18;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;
  uint256 internal constant MIN_WEIGHT = BONE / 4;

  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
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
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }

  // DSMath.wpow
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

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
    require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

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
    // term 0:
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
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
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import "@indexed-finance/indexed-core/contracts/interfaces/IIndexPool.sol";

import "./libraries/UniswapV2Library.sol";
import "./BMath.sol";


contract IndexedUniswapRouterBurner is BMath {
  address public immutable factory;
  address public immutable weth;

  constructor(address factory_, address weth_) public {
    factory = factory_;
    weth = weth_;
  }

  receive() external payable {
    require(msg.sender == weth, "IndexedUniswapRouterBurner: RECEIVED_ETHER");
  }

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address[] memory path, address recipient) internal {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, address token1) = UniswapV2Library.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : recipient;
      IUniswapV2Pair(UniswapV2Library.calculatePair(factory, token0, token1)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  /**
   * @dev Redeems `poolAmountIn` pool tokens for the first token in `path`
   * and swaps it to at least `minAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountIn Amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param minAmountOut Amount of last token in `path` that must be received to not revert.
   * @return amountOut Amount of output tokens received.
   */
  function burnExactAndSwapForTokens(
    address indexPool,
    uint poolAmountIn,
    address[] calldata path,
    uint minAmountOut
  ) external returns (uint amountOut) {
    amountOut = _burnExactAndSwap(
      indexPool,
      poolAmountIn,
      path,
      minAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Redeems `poolAmountIn` pool tokens for the first token in `path`
   * and swaps it to at least `minAmountOut` ether.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountIn Amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param minAmountOut Amount of ether that must be received to not revert.
   * @return amountOut Amount of ether received.
   */
  function burnExactAndSwapForETH(
    address indexPool,
    uint poolAmountIn,
    address[] calldata path,
    uint minAmountOut
  ) external returns (uint amountOut) {
    require(path[path.length - 1] == weth, 'IndexedUniswapRouterBurner: INVALID_PATH');
    amountOut = _burnExactAndSwap(
      indexPool,
      poolAmountIn,
      path,
      minAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(amountOut);
    TransferHelper.safeTransferETH(msg.sender, amountOut);
  }

  function _burnExactAndSwap(
    address indexPool,
    uint poolAmountIn,
    address[] memory path,
    uint minAmountOut,
    address recipient
  ) internal returns (uint amountOut) {
    // Transfer the pool tokens to the router.
    TransferHelper.safeTransferFrom(
      indexPool,
      msg.sender,
      address(this),
      poolAmountIn
    );
    // Burn the pool tokens for the first token in `path`.
    uint redeemedAmountOut = IIndexPool(indexPool).exitswapPoolAmountIn(
      path[0],
      poolAmountIn,
      0
    );
    // Calculate the swap amounts for the redeemed amount of the first token in `path`.
    uint[] memory amounts = UniswapV2Library.getAmountsOut(factory, redeemedAmountOut, path);
    amountOut = amounts[amounts.length - 1];
    require(
      amountOut >= minAmountOut,
      "IndexedUniswapRouterBurner: INSUFFICIENT_OUTPUT_AMOUNT"
    );
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0],
      UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
  }

  /**
   * @dev Redeems up to `poolAmountInMax` pool tokens for the first token in `path`
   * and swaps it to exactly `tokenAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountInMax Maximum amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param tokenAmountOut Amount of last token in `path` to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactTokens(
    address indexPool,
    uint poolAmountInMax,
    address[] calldata path,
    uint tokenAmountOut
  ) external returns (uint poolAmountIn) {
    poolAmountIn = _burnAndSwapForExact(
      indexPool,
      poolAmountInMax,
      path,
      tokenAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Redeems up to `poolAmountInMax` pool tokens for the first token in `path`
   * and swaps it to exactly `ethAmountOut` ether.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountInMax Maximum amount of pool tokens to burn.
   * @param path Array of tokens to swap using the Uniswap router.
   * @param ethAmountOut Amount of eth to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactETH(
    address indexPool,
    uint poolAmountInMax,
    address[] calldata path,
    uint ethAmountOut
  ) external returns (uint poolAmountIn) {
    require(path[path.length - 1] == weth, 'IndexedUniswapRouterBurner: INVALID_PATH');
    poolAmountIn = _burnAndSwapForExact(
      indexPool,
      poolAmountInMax,
      path,
      ethAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(ethAmountOut);
    TransferHelper.safeTransferETH(msg.sender, ethAmountOut);
  }

  function _burnAndSwapForExact(
    address indexPool,
    uint poolAmountInMax,
    address[] memory path,
    uint tokenAmountOut,
    address recipient
  ) internal returns (uint poolAmountIn) {
    // Transfer the maximum pool tokens to the router.
    TransferHelper.safeTransferFrom(
      indexPool,
      msg.sender,
      address(this),
      poolAmountInMax
    );
    // Calculate the swap amounts for `tokenAmountOut` of the last token in `path`.
    uint[] memory amounts = UniswapV2Library.getAmountsIn(factory, tokenAmountOut, path);
    // Burn the pool tokens for the exact amount of the first token in `path`.
    poolAmountIn = IIndexPool(indexPool).exitswapExternAmountOut(
      path[0],
      amounts[0],
      poolAmountInMax
    );
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0],
      UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
    // Return any unburned pool tokens to the caller.
    TransferHelper.safeTransfer(
      indexPool,
      msg.sender,
      SafeMath.sub(poolAmountInMax, poolAmountIn)
    );
  }

  /**
   * @dev Burns `poolAmountOut` for all the underlying tokens in a pool, then
   * swaps each of them on Uniswap for at least `minAmountOut` of `tokenOut`.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   */
  function burnForAllTokensAndSwapForTokens(
    address indexPool,
    uint256[] calldata minAmountsOut,
    address[] calldata intermediaries,
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

  /**
   * @dev Burns `poolAmountOut` for all the underlying tokens in a pool, then
   * swaps each of them on Uniswap for at least `minAmountOut` ether.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   */
  function burnForAllTokensAndSwapForETH(
    address indexPool,
    uint256[] calldata minAmountsOut,
    address[] calldata intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint amountOutTotal) {
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

  function _burnForAllTokensAndSwap(
    address indexPool,
    address tokenOut,
    uint256[] calldata minAmountsOut,
    address[] calldata intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut,
    address recipient
  ) internal returns (uint amountOutTotal) {
    // Transfer the pool tokens from the caller.
    TransferHelper.safeTransferFrom(indexPool, msg.sender, address(this), poolAmountIn);
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      intermediaries.length == tokens.length && minAmountsOut.length == tokens.length,
      "IndexedUniswapRouterBurner: BAD_ARRAY_LENGTH"
    );
    IIndexPool(indexPool).exitPool(poolAmountIn, minAmountsOut);
    // Reserve 3 slots in memory for the addresses
    address[] memory path = new address[](3);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint[] memory amounts = _getSwapAmountsForExit(
        tokens[i],
        intermediaries[i],
        tokenOut,
        path
      );
      TransferHelper.safeTransfer(
        tokens[i],
        UniswapV2Library.pairFor(factory, tokens[i], path[1]),
        amounts[0]
      );
      _swap(amounts, path, recipient);

      uint amountOut = amounts[amounts.length - 1];
      amountOutTotal = SafeMath.add(amountOutTotal, amountOut);
    }
    require(amountOutTotal >= minAmountOut, "IndexedUniswapRouterBurner: INSUFFICIENT_OUTPUT_AMOUNT");
  }

  function _getSwapAmountsForExit(
    address tokenIn,
    address intermediate,
    address tokenOut,
    address[] memory path
  ) internal view returns (uint[] memory amounts) {
    if (intermediate == address(0)) {
      // If no intermediate token is given, set path length to 2 so the other
      // functions will not use the 3rd address.
      assembly { mstore(path, 2) }
      path[1] = tokenOut;
    } else {
      // If an intermediary is given, set path length to 3 so the other
      // functions will use all addresses.
      assembly { mstore(path, 3) }
      path[1] = intermediate;
      path[2] = tokenOut;
    }
    uint balance = IERC20(tokenIn).balanceOf(address(this));
    amounts = UniswapV2Library.getAmountsOut(factory, balance, path);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
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

  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256 tokenAmountIn
  );

  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

  event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);

  event LOG_TOKEN_REMOVED(address token);

  event LOG_TOKEN_ADDED(
    address indexed token,
    uint256 desiredDenorm,
    uint256 minimumBalance
  );

  event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);

  event LOG_TOKEN_READY(address indexed token);

  event LOG_PUBLIC_SWAP_ENABLED();

  event LOG_MAX_TOKENS_UPDATED(uint256 maxPoolTokens);

  event LOG_SWAP_FEE_UPDATED(uint256 swapFee);

  function configure(
    address controller,
    string calldata name,
    string calldata symbol
  ) external;

  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider,
    address unbindHandler
  ) external;

  function setMaxPoolTokens(uint256 maxPoolTokens) external;

  function setSwapFee(uint256 swapFee) external;

  function reweighTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms
  ) external;

  function reindexTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms,
    uint256[] calldata minimumBalances
  ) external;

  function setMinimumBalance(address token, uint256 minimumBalance) external;

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external returns (uint256/* poolAmountOut */);

  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external returns (uint256/* tokenAmountIn */);

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  )
    external returns (uint256/* tokenAmountOut */);

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external returns (uint256/* poolAmountIn */);

  function gulp(address token) external;

  function flashBorrow(
    address recipient,
    address token,
    uint256 amount,
    bytes calldata data
  ) external;

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256/* tokenAmountOut */, uint256/* spotPriceAfter */);

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external returns (uint256 /* tokenAmountIn */, uint256 /* spotPriceAfter */);

  function isPublicSwap() external view returns (bool);

  function getSwapFee() external view returns (uint256/* swapFee */);

  function getController() external view returns (address);

  function getMaxPoolTokens() external view returns (uint256);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens() external view returns (address[] memory tokens);

  function getDenormalizedWeight(address token) external view returns (uint256/* denorm */);

  function getTokenRecord(address token) external view returns (Record memory record);

  function extrapolatePoolValueFromToken() external view returns (address/* token */, uint256/* extrapolatedValue */);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function getMinimumBalance(address token) external view returns (uint256);

  function getUsedBalance(address token) external view returns (uint256);

  function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256);
}

pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }

  // fetches and sorts the reserves for a pair
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

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
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

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
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

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
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

  // performs chained getAmountOut calculations on any number of pairs
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

  // performs chained getAmountIn calculations on any number of pairs
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