// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

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
pragma solidity >=0.6.0;


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
pragma solidity 0.7.6;
pragma abicoder v2;

import "./NarwhalRouter.sol";
import "./BMath.sol";
import "./interfaces/IIndexPool.sol";
import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";


contract IndexedNarwhalRouter is NarwhalRouter, BMath {
  using TokenInfo for bytes32;
  using TokenInfo for address;
  using TransferHelper for address;
  using SafeMath for uint256;

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) NarwhalRouter(_uniswapFactory, _sushiswapFactory, _weth) {}

/** ========== Mint Single: Exact In ========== */

  /**
   * @dev Swaps ether for each token in `path` using their Uniswap pairs,
   * then mints at least `minPoolAmountOut` pool tokens from `indexPool`.
   *
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param minPoolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapExactETHForTokensAndMint(
    bytes32[] calldata path,
    address indexPool,
    uint minPoolAmountOut
  ) external payable returns (uint poolAmountOut) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    uint256[] memory amounts = getAmountsOut(path, msg.value);

    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));

    uint amountOut =  amounts[amounts.length - 1];
    return _mintExactIn(
      path[path.length - 1].readToken(),
      amountOut,
      indexPool,
      minPoolAmountOut
    );
  }

  /**
   * @dev Swaps a token for each other token in `path` using their Uniswap pairs,
   * then mints at least `minPoolAmountOut` pool tokens from `indexPool`.
   *
   * @param amountIn Amount of the first token in `path` to swap.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param minPoolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapExactTokensForTokensAndMint(
    uint amountIn,
    bytes32[] calldata path,
    address indexPool,
    uint minPoolAmountOut
  ) external returns (uint poolAmountOut) {
    uint256[] memory amounts = getAmountsOut(path, amountIn);
    path[0].readToken().safeTransferFrom(
      msg.sender, pairFor(path[0], path[1]), amounts[0]
    );
    _swap(amounts, path, address(this));
    uint amountOut = amounts[amounts.length - 1];

    return _mintExactIn(
      path[path.length - 1].readToken(),
      amountOut,
      indexPool,
      minPoolAmountOut
    );
  }

  function _mintExactIn(
    address tokenIn,
    uint amountIn,
    address indexPool,
    uint minPoolAmountOut
  ) internal returns (uint poolAmountOut) {
    TransferHelper.safeApprove(tokenIn, indexPool, amountIn);
    poolAmountOut = IIndexPool(indexPool).joinswapExternAmountIn(
      tokenIn,
      amountIn,
      minPoolAmountOut
    );
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

/** ========== Burn Single: Exact In ========== */


  /**
   * @dev Redeems `poolAmountIn` pool tokens for the first token in `path`
   * and swaps it to at least `minAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountIn Amount of pool tokens to burn.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param minAmountOut Amount of last token in `path` that must be received to not revert.
   * @return amountOut Amount of output tokens received.
   */
  function burnExactAndSwapForTokens(
    address indexPool,
    uint poolAmountIn,
    bytes32[] calldata path,
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
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param minAmountOut Amount of ether that must be received to not revert.
   * @return amountOut Amount of ether received.
   */
  function burnExactAndSwapForETH(
    address indexPool,
    uint poolAmountIn,
    bytes32[] calldata path,
    uint minAmountOut
  ) external returns (uint amountOut) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
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
    bytes32[] memory path,
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
      path[0].readToken(),
      poolAmountIn,
      0
    );
    // Calculate the swap amounts for the redeemed amount of the first token in `path`.
    uint[] memory amounts = getAmountsOut(path, redeemedAmountOut);
    amountOut = amounts[amounts.length - 1];
    require(amountOut >= minAmountOut, "NRouter: MIN_OUT");
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0].readToken(),
      pairFor(path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
  }

/** ========== Mint Single: Exact Out ========== */

  /**
   * @dev Swaps ether for each token in `path` through Uniswap,
   * then mints `poolAmountOut` pool tokens from `indexPool`.
   *
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param poolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapETHForTokensAndMintExact(
    bytes32[] calldata path,
    address indexPool,
    uint poolAmountOut
  ) external payable {
    address swapTokenOut = path[path.length - 1].readToken();
    uint amountOut = _tokenInGivenPoolOut(indexPool, swapTokenOut, poolAmountOut);
    require(path[0].readToken() == address(weth), "INVALID_PATH");

    uint[] memory amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= msg.value, "NRouter: MAX_IN");

    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));

    // refund dust eth, if any
    if (msg.value > amounts[0]) {
      TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    return _mintExactOut(
      swapTokenOut,
      amountOut,
      indexPool,
      poolAmountOut
    );
  }

  /**
   * @dev Swaps a token for each other token in `path` through Uniswap,
   * then mints at least `poolAmountOut` pool tokens from `indexPool`.
   *
   * @param amountInMax Maximum amount of the first token in `path` to give.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param poolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapTokensForTokensAndMintExact(
    uint amountInMax,
    bytes32[] calldata path,
    address indexPool,
    uint poolAmountOut
  ) external {
    address swapTokenOut = path[path.length - 1].readToken();
    uint amountOut = _tokenInGivenPoolOut(indexPool, swapTokenOut, poolAmountOut);
    uint[] memory amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender, pairFor(path[0], path[1]), amounts[0]
    );
    _swap(amounts, path, address(this));
    _mintExactOut(
      swapTokenOut,
      amountOut,
      indexPool,
      poolAmountOut
    );
  }

  function _mintExactOut(
    address tokenIn,
    uint amountIn,
    address indexPool,
    uint poolAmountOut
  ) internal {
    TransferHelper.safeApprove(tokenIn, indexPool, amountIn);
    IIndexPool(indexPool).joinswapPoolAmountOut(
      tokenIn,
      poolAmountOut,
      amountIn
    );
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

  function _tokenInGivenPoolOut(
    address indexPool,
    address tokenIn,
    uint256 poolAmountOut
  ) internal view returns (uint256 amountIn) {
    IIndexPool.Record memory record = IIndexPool(indexPool).getTokenRecord(tokenIn);
    if (!record.ready) {
      uint256 minimumBalance = IIndexPool(indexPool).getMinimumBalance(tokenIn);
      uint256 realToMinRatio = bdiv(
        bsub(minimumBalance, record.balance),
        minimumBalance
      );
      uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
      record.balance = minimumBalance;
      record.denorm = uint96(badd(MIN_WEIGHT, weightPremium));
    }

    uint256 totalSupply = IERC20(indexPool).totalSupply();
    uint256 totalWeight = IIndexPool(indexPool).getTotalDenormalizedWeight();
    uint256 swapFee = IIndexPool(indexPool).getSwapFee();

    return calcSingleInGivenPoolOut(
      record.balance,
      record.denorm,
      totalSupply,
      totalWeight,
      poolAmountOut,
      swapFee
    );
  }

/** ========== Burn Single: Exact Out ========== */

  /**
   * @dev Redeems up to `poolAmountInMax` pool tokens for the first token in `path`
   * and swaps it to exactly `tokenAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountInMax Maximum amount of pool tokens to burn.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param tokenAmountOut Amount of last token in `path` to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactTokens(
    address indexPool,
    uint poolAmountInMax,
    bytes32[] calldata path,
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
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param ethAmountOut Amount of eth to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactETH(
    address indexPool,
    uint poolAmountInMax,
    bytes32[] calldata path,
    uint ethAmountOut
  ) external returns (uint poolAmountIn) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
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
    bytes32[] memory path,
    uint tokenAmountOut,
    address recipient
  ) internal returns (uint poolAmountIn) {
    // Transfer the maximum pool tokens to the router.
    indexPool.safeTransferFrom(
      msg.sender,
      address(this),
      poolAmountInMax
    );
    // Calculate the swap amounts for `tokenAmountOut` of the last token in `path`.
    uint[] memory amounts = getAmountsIn(path, tokenAmountOut);
    // Burn the pool tokens for the exact amount of the first token in `path`.
    poolAmountIn = IIndexPool(indexPool).exitswapExternAmountOut(
      path[0].readToken(),
      amounts[0],
      poolAmountInMax
    );
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0].readToken(),
      pairFor(path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
    // Return any unburned pool tokens to the caller.
    indexPool.safeTransfer(
      msg.sender,
      poolAmountInMax.sub(poolAmountIn)
    );
  }

/** ========== Mint All: Exact Out ========== */

  /**
   * @dev Swaps an input token for every underlying token in an index pool,
   * then mints `poolAmountOut` pool tokens from the pool.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   *
   * `intermediaries` is an encoded Narwhal path with a one-byte prefix indicating
   * whether the first swap should use sushiswap.
   *
   * @param indexPool Address of the index pool to mint tokens with.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountOut Amount of index pool tokens to mint.
   * @param tokenIn Token to buy the underlying tokens with.
   * @param amountInMax Maximumm amount of `tokenIn` to spend.
   * @return Amount of `tokenIn` spent.
   */
  function swapTokensForAllTokensAndMintExact(
    address indexPool,
    bytes32[] calldata intermediaries,
    uint256 poolAmountOut,
    address tokenIn,
    uint256 amountInMax
  ) external returns (uint256) {
    uint256 remainder = amountInMax;
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      tokens.length == intermediaries.length,
      "NRouter: ARR_LEN"
    );
    tokenIn.safeTransferFrom(msg.sender, address(this), amountInMax);
    uint256[] memory amountsToPool = new uint256[](tokens.length);

    uint256 ratio = bdiv(poolAmountOut, IERC20(indexPool).totalSupply());

    // Reserve 3 slots in memory for the addresses
    bytes32[] memory path = new bytes32[](3);
    path[0] = tokenIn.pack(false);
    for (uint256 i = 0; i < tokens.length; i++) {
      (amountsToPool[i], remainder) = _handleMintInput(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio,
        remainder
      );
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
    if (remainder > 0) {
      tokenIn.safeTransfer(msg.sender, remainder);
    }
    return amountInMax.sub(remainder);
  }

  /**
   * @dev Swaps ether for every underlying token in an index pool,
   * then mints `poolAmountOut` pool tokens from the pool.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   *
   * `intermediaries` is an encoded Narwhal path with a one-byte prefix indicating
   * whether the first swap should use sushiswap.
   *
   * @param indexPool Address of the index pool to mint tokens with.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountOut Amount of index pool tokens to mint.
   * @return Amount of ether spent.
   */
  function swapETHForAllTokensAndMintExact(
    address indexPool,
    bytes32[] calldata intermediaries,
    uint256 poolAmountOut
  ) external payable returns (uint) {
    uint256 remainder = msg.value;
    IWETH(weth).deposit{value: msg.value}();
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(tokens.length == intermediaries.length, "NRouter: ARR_LEN");
    uint256[] memory amountsToPool = new uint256[](tokens.length);

    uint256 ratio = bdiv(poolAmountOut, IERC20(indexPool).totalSupply());

    // Reserve 3 slots in memory for the addresses
    bytes32[] memory path = new bytes32[](3);
    path[0] = address(weth).pack(false);

    for (uint256 i = 0; i < tokens.length; i++) {
      (amountsToPool[i], remainder) = _handleMintInput(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio,
        remainder
      );
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);

    if (remainder > 0) {
      IWETH(weth).withdraw(remainder);
      TransferHelper.safeTransferETH(msg.sender, remainder);
    }
    return msg.value.sub(remainder);
  }

  function _handleMintInput(
    address indexPool,
    bytes32 intermediate,
    address poolToken,
    bytes32[] memory path,
    uint256 poolRatio,
    uint256 amountInMax
  ) internal returns (uint256 amountToPool, uint256 remainder) {
    address tokenIn = path[0].readToken();
    uint256 usedBalance = IIndexPool(indexPool).getUsedBalance(poolToken);
    amountToPool = bmul(poolRatio, usedBalance);
    if (tokenIn == poolToken) {
      remainder = amountInMax.sub(amountToPool, "NRouter: MAX_IN");
    } else {
      bool sushiFirst;
      assembly {
        sushiFirst := shr(168,  intermediate)
        intermediate := and(
          0x0000000000000000000000ffffffffffffffffffffffffffffffffffffffffff,
          intermediate
        )
      }
      path[0] = tokenIn.pack(sushiFirst);
      if (intermediate == bytes32(0)) {
        // If no intermediate token is given, set path length to 2 so the other
        // functions will not use the 3rd address.
        assembly { mstore(path, 2) }
        // It doesn't matter whether a token is set to use sushi or not
        // if it is the last token in the list.
        path[1] = poolToken.pack(false);
      } else {
        // If an intermediary is given, set path length to 3 so the other
        // functions will use all addresses.
        assembly { mstore(path, 3) }
        path[1] = intermediate;
        path[2] = poolToken.pack(false);
      }
      uint[] memory amounts = getAmountsIn(path, amountToPool);
      remainder = amountInMax.sub(amounts[0], "NRouter: MAX_IN");
      tokenIn.safeTransfer(pairFor(path[0], path[1]), amounts[0]);
      _swap(amounts, path, address(this));
    }
    poolToken.safeApprove(indexPool, amountToPool);
  }

/** ========== Burn All: Exact In ========== */

  /**
   * @dev Burns `poolAmountOut` for all the underlying tokens in a pool, then
   * swaps each of them on Uniswap for at least `minAmountOut` of `tokenOut`.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param minAmountsOut Minimum amount of each underlying token that must be
   * received from the pool to not revert.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountIn Amount of index pool tokens to burn.
   * @param tokenOut Address of the token to buy.
   * @param minAmountOut Minimum amount of `tokenOut` that must be received to
   * not revert.
   * @return amountOutTotal Amount of `tokenOut` received.
   */
  function burnForAllTokensAndSwapForTokens(
    address indexPool,
    uint256[] calldata minAmountsOut,
    bytes32[] calldata intermediaries,
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
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param minAmountsOut Minimum amount of each underlying token that must be
   * received from the pool to not revert.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountIn Amount of index pool tokens to burn.
   * @param minAmountOut Minimum amount of ether that must be received to
   * not revert.
   * @return amountOutTotal Amount of ether received.
   */
  function burnForAllTokensAndSwapForETH(
    address indexPool,
    uint256[] calldata minAmountsOut,
    bytes32[] calldata intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      address(weth),
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
    bytes32[] calldata intermediaries,
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
    bytes32[] memory path = new bytes32[](3);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint amountOut = _handleBurnOutput(
        tokens[i],
        intermediaries[i],
        tokenOut,
        path,
        recipient
      );
      amountOutTotal = amountOutTotal.add(amountOut);
    }
    require(amountOutTotal >= minAmountOut, "NRouter: MIN_OUT");
  }

  function _handleBurnOutput(
    address tokenIn,
    bytes32 intermediate,
    address tokenOut,
    bytes32[] memory path,
    address recipient
  ) internal returns (uint amountOut) {
    uint256 _balance = IERC20(tokenIn).balanceOf(address(this));
    if (tokenIn == tokenOut) {
      amountOut = _balance;
      if (recipient != address(this)) {
        tokenIn.safeTransfer(recipient, _balance);
      }
    } else {
      bool sushiFirst;
      assembly {
        sushiFirst := shr(168,  intermediate)
        intermediate := and(
          0x0000000000000000000000ffffffffffffffffffffffffffffffffffffffffff,
          intermediate
        )
      }
      path[0] = tokenIn.pack(sushiFirst);
      if (intermediate == bytes32(0)) {
        // If no intermediate token is given, set path length to 2 so the other
        // functions will not use the 3rd address.
        assembly { mstore(path, 2) }
        // It doesn't matter whether a token is set to use sushi or not
        // if it is the last token in the list.
        path[1] = tokenOut.pack(false);
      } else {
        // If an intermediary is given, set path length to 3 so the other
        // functions will use all addresses.
        assembly { mstore(path, 3) }
        path[1] = intermediate;
        path[2] = tokenOut.pack(false);
      }
      uint[] memory amounts = getAmountsOut(path, _balance);
      tokenIn.safeTransfer(pairFor(path[0], path[1]), amounts[0]);
      _swap(amounts, path, recipient);
      amountOut = amounts[amounts.length - 1];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWETH.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TokenInfo.sol";


contract Narwhal {
  using SafeMath for uint256;
  using TokenInfo for bytes32;

  address public immutable uniswapFactory;
  address public immutable sushiswapFactory;
  IWETH public immutable weth;

/** ========== Constructor ========== */

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) {
    uniswapFactory = _uniswapFactory;
    sushiswapFactory = _sushiswapFactory;
    weth = IWETH(_weth);
  }

/** ========== Fallback ========== */

  receive() external payable {
    assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
  }

/** ========== Swaps ========== */

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, bytes32[] memory path, address recipient) internal {
    for (uint i; i < path.length - 1; i++) {
      (bytes32 input, bytes32 output) = (path[i], path[i + 1]);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = (input < output) ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? pairFor(output, path[i + 2]) : recipient;
      IUniswapV2Pair(pairFor(input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

/** ========== Pair Calculation & Sorting ========== */

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

  function zeroForOne(bytes32 tokenA, bytes32 tokenB) internal pure returns (bool) {
    return tokenA < tokenB;
  }

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(bytes32 tokenA, bytes32 tokenB)
    internal
    pure
    returns (bytes32 token0, bytes32 token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != bytes32(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculateUniPair(address token0, address token1 ) internal view returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            uniswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  function calculateSushiPair(address token0, address token1) internal view returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            sushiswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
          )
        )
      )
    );
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address tokenA,
    address tokenB,
    bool sushi
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = sushi ? calculateSushiPair(token0, token1) : calculateUniPair(token0, token1);
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(bytes32 tokenInfoA, bytes32 tokenInfoB) internal view returns (address pair) {
    (address tokenA, bool sushi) = tokenInfoA.unpack();
    address tokenB = tokenInfoB.readToken();
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = sushi ? calculateSushiPair(token0, token1) : calculateUniPair(token0, token1);
  }

/** ========== Pair Reserves ========== */

  // fetches and sorts the reserves for a pair
  function getReserves(
    bytes32 tokenInfoA,
    bytes32 tokenInfoB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(tokenInfoA, tokenInfoB)).getReserves();
    (reserveA, reserveB) = tokenInfoA < tokenInfoB
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

/** ========== Swap Amounts ========== */

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
    bytes32[] memory path,
    uint256 amountIn
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    bytes32[] memory path,
    uint256 amountOut
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Narwhal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";


contract NarwhalRouter is Narwhal {
  using TokenInfo for bytes32;
  using TokenInfo for address;
  using TransferHelper for address;
  using SafeMath for uint256;

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "NRouter: EXPIRED");
    _;
  }

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) Narwhal(_uniswapFactory, _sushiswapFactory, _weth) {}

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = getAmountsOut(path, amountIn);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsOut(path, msg.value);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    weth.withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsOut(path, amountIn);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    weth.withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    uint256 amountOut,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= msg.value, "NRouter: MAX_IN");
    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
    // // refund dust eth, if any
    if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";


interface IIndexPool is IERC20 {
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
    address unbindHandler,
    address exitFeeRecipient
  ) external;

  function setMaxPoolTokens(uint256 maxPoolTokens) external;

  function setSwapFee(uint256 swapFee) external;

  function delegateCompLikeToken(address token, address delegatee) external;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function migrator() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

pragma solidity >=0.5.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }


  function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x + y) >= x, errorMessage);
  }

  function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x - y) <= x, errorMessage);
  }

  function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, errorMessage);
  }
}

pragma solidity >=0.5.0;


library TokenInfo {
  function unpack(bytes32 tokenInfo) internal pure returns (address token, bool useSushiNext) {
    assembly {
      token := shr(8, tokenInfo)
      useSushiNext := byte(31, tokenInfo)
    }
  }

  function pack(address token, bool sushi) internal pure returns (bytes32 tokenInfo) {
    assembly {
      tokenInfo := or(
        shl(8, token),
        sushi
      )
    }
  }

  function readToken(bytes32 tokenInfo) internal pure returns (address token) {
    assembly {
      token := shr(8, tokenInfo)
    }
  }

  function readSushi(bytes32 tokenInfo) internal pure returns (bool useSushiNext) {
    assembly {
      useSushiNext := byte(31, tokenInfo)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash cfedb1f55864dcf8cc0831fdd8ec18eb045b7fd1.

Subject to the MIT license
*************************************************************************************************/


library TransferHelper {
  function safeApproveMax(address token, address to) internal {
    safeApprove(token, to, type(uint256).max);
  }

  function safeUnapprove(address token, address to) internal {
    safeApprove(token, to, 0);
  }

  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:SA");
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:ST");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:STF");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}("");
    require(success, "TH:STE");
  }
}

