/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface BPool {
  function getCurrentTokens() external view returns (address[] memory tokens);

  function getNormalizedWeight(address token) external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

interface ISmartBPool {
  function bPool() external view returns (BPool);

  function totalSupply() external view returns (uint256);
}

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracle {
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address _asset) external view returns (uint256);
}

contract BConst {
  uint256 public constant BONE = 10**18;

  uint256 public constant MIN_BOUND_TOKENS = 2;
  uint256 public constant MAX_BOUND_TOKENS = 8;

  uint256 public constant MIN_FEE = BONE / 10**6;
  uint256 public constant MAX_FEE = BONE / 10;
  uint256 public constant EXIT_FEE = 0;

  uint256 public constant MIN_WEIGHT = BONE;
  uint256 public constant MAX_WEIGHT = BONE * 50;
  uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
  uint256 public constant MIN_BALANCE = BONE / 10**12;

  uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

  uint256 public constant MIN_BPOW_BASE = 1 wei;
  uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 public constant BPOW_PRECISION = BONE / 10**10;

  uint256 public constant MAX_IN_RATIO = BONE / 2;
  uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

contract BNum is BConst {
  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'ERR_ADD_OVERFLOW');
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, 'ERR_SUB_UNDERFLOW');
    return c;
  }

  function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, 'ERR_MUL_OVERFLOW');
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, 'ERR_MUL_OVERFLOW');
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'ERR_DIV_ZERO');
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, 'ERR_DIV_INTERNAL'); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, 'ERR_DIV_INTERNAL'); //  badd require
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
    require(base >= MIN_BPOW_BASE, 'ERR_BPOW_BASE_TOO_LOW');
    require(base <= MAX_BPOW_BASE, 'ERR_BPOW_BASE_TOO_HIGH');

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

/** @title NaiveBalancerSmartPoolPriceProvider
 * @notice Price provider for a balancer pool token
 * - NAIVE CALCULATION, USE ONLY FOR PRICE FETCHING
 * This implementation assumes the underlying pool on the smart pool is a standard Balancer Shared Pool
 * - DON'T USE THIS ORACLE IF FUNDAMENTAL CHANGES ON THE UNDERLYING POOL ARE APPLIED
 */

contract NaiveBalancerSmartPoolPriceProvider is BNum {
  ISmartBPool public pool;
  address[] public tokens;
  uint256[] public weights;
  bool[] public isPeggedToEth;
  uint8[] public decimals;
  IPriceOracle public priceOracle;

  /**
   * BalancerSmartPoolPriceProvider constructor.
   * @param _pool Balancer pool address.
   * @param _isPeggedToEth For each token, true if it is pegged to ETH (token order determined by pool.getPool().getFinalTokens()).
   * @param _decimals Number of decimals for each token (token order determined by pool.getPool().getFinalTokens()).
   * @param _priceOracle Aave price oracle.
   */
  constructor(
    ISmartBPool _pool,
    bool[] memory _isPeggedToEth,
    uint8[] memory _decimals,
    IPriceOracle _priceOracle
  ) public {
    pool = _pool;

    BPool underlyingBPool = _pool.bPool();
    //Get token list
    tokens = underlyingBPool.getCurrentTokens();
    uint256 length = tokens.length;
    //Validate contructor params
    require(length >= 2 && length <= 3, 'ERR_INVALID_POOL_TOKENS_NUMBER');
    require(_isPeggedToEth.length == length, 'ERR_INVALID_PEGGED_LENGTH');
    require(_decimals.length == length, 'ERR_INVALID_DECIMALS_LENGTH');
    for (uint8 i = 0; i < length; i++) {
      require(_decimals[i] <= 18, 'ERR_INVALID_DECIMALS');
    }
    require(address(_priceOracle) != address(0), 'ERR_INVALID_PRICE_PROVIDER');
    //Get token normalized weights
    for (uint8 i = 0; i < length; i++) {
      weights.push(underlyingBPool.getNormalizedWeight(tokens[i]));
    }
    isPeggedToEth = _isPeggedToEth;
    decimals = _decimals;
    priceOracle = _priceOracle;
  }

  /**
   * Returns the token balance in ethers by multiplying its balance with its price in ethers.
   * @param index Token index.
   */
  function getEthBalanceByToken(uint256 index) internal view returns (uint256) {
    uint256 pi = isPeggedToEth[index] ? BONE : uint256(priceOracle.getAssetPrice(tokens[index]));
    require(pi > 0, 'ERR_NO_ORACLE_PRICE');
    uint256 missingDecimals = 18 - decimals[index];
    uint256 bi = bmul(pool.bPool().getBalance(tokens[index]), BONE * 10**(missingDecimals));
    return bmul(bi, pi);
  }

  /**
   * Calculates the price of the pool token using the formula of weighted arithmetic mean.
   * @param ethTotals Balance of each token in ethers.
   */
  function getArithmeticMean(uint256[] memory ethTotals) internal view returns (uint256) {
    uint256 totalEth = 0;
    uint256 length = tokens.length;
    for (uint8 i = 0; i < length; i++) {
      totalEth = badd(totalEth, ethTotals[i]);
    }
    return bdiv(totalEth, pool.totalSupply());
  }

  /**
   * Returns the pool's token price.
   * It calculates the price using Chainlink as an external price source and the pool's tokens balances using the weighted arithmetic mean formula.
   */
  function latestAnswer() external view returns (uint256) {
    //Get token balances in ethers
    uint256[] memory ethTotals = new uint256[](tokens.length);
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; i++) {
      ethTotals[i] = getEthBalanceByToken(i);
    }

    return getArithmeticMean(ethTotals);
  }

  /**
   * Returns Balancer pool address.
   */
  function getPool() external view returns (ISmartBPool) {
    return pool;
  }

  /**
   * Returns all tokens.
   */
  function getTokens() external view returns (address[] memory) {
    return tokens;
  }

  /**
   * Returns all tokens's weights.
   */
  function getWeights() external view returns (uint256[] memory) {
    return weights;
  }
}