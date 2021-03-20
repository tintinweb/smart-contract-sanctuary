/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: IERC20

interface IERC20 {
    function decimals() external view returns (uint);
}

// Part: IKeep3rV1Oracle

// Modified from https://github.com/keep3r-network/keep3r.network/blob/master/contracts/Keep3rV1Volatility.sol
// Subject to the MIT license

interface IKeep3rV1Oracle {
  function sample(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint[] memory);
}

// File: Keep3rV1OracleMetrics.sol

contract Keep3rV1OracleMetrics {

  uint private constant FIXED_1 = 0x080000000000000000000000000000000;
  uint private constant FIXED_2 = 0x100000000000000000000000000000000;
  uint private constant SQRT_1 = 13043817825332782212;
  uint private constant LNX = 3988425491;
  uint private constant LOG_10_2 = 3010299957;
  uint private constant LOG_E_2 = 6931471806;
  uint private constant BASE = 1e10;

  uint public constant periodSize = 1800;

  IKeep3rV1Oracle public constant KV1O = IKeep3rV1Oracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa); // SushiswapV1Oracle

  function floorLog2(uint256 _n) public pure returns (uint8) {
      uint8 res = 0;

      if (_n < 256) {
          // At most 8 iterations
          while (_n > 1) {
              _n >>= 1;
              res += 1;
          }
      } else {
          // Exactly 8 iterations
          for (uint8 s = 128; s > 0; s >>= 1) {
              if (_n >= (uint(1) << s)) {
                  _n >>= s;
                  res |= s;
              }
          }
      }

      return res;
  }

  function ln(uint256 x) public pure returns (uint) {
      uint res = 0;

      // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
      if (x >= FIXED_2) {
          uint8 count = floorLog2(x / FIXED_1);
          x >>= count; // now x < 2
          res = count * FIXED_1;
      }

      // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
      if (x > FIXED_1) {
          for (uint8 i = 127; i > 0; --i) {
              x = (x * x) / FIXED_1; // now 1 < x < 4
              if (x >= FIXED_2) {
                  x >>= 1; // now 1 < x < 2
                  res += uint(1) << (i - 1);
              }
          }
      }

      return res * LOG_E_2 / BASE;
  }

  /**
   * @dev computes e ^ (x / FIXED_1) * FIXED_1
   * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
   * auto-generated via 'PrintFunctionOptimalExp.py'
   * Detailed description:
   * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
   * - The exponentiation of each binary exponent is given (pre-calculated)
   * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
   * - The exponentiation of the input is calculated by multiplying the intermediate results above
   * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
   */
  function optimalExp(uint256 x) public pure returns (uint256) {
      uint256 res = 0;

      uint256 y;
      uint256 z;

      z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
      z = (z * y) / FIXED_1;
      res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
      z = (z * y) / FIXED_1;
      res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
      z = (z * y) / FIXED_1;
      res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
      z = (z * y) / FIXED_1;
      res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
      z = (z * y) / FIXED_1;
      res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
      z = (z * y) / FIXED_1;
      res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
      z = (z * y) / FIXED_1;
      res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
      z = (z * y) / FIXED_1;
      res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
      z = (z * y) / FIXED_1;
      res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
      z = (z * y) / FIXED_1;
      res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
      z = (z * y) / FIXED_1;
      res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
      z = (z * y) / FIXED_1;
      res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
      res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

      if ((x & 0x010000000000000000000000000000000) != 0)
          res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
      if ((x & 0x020000000000000000000000000000000) != 0)
          res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
      if ((x & 0x040000000000000000000000000000000) != 0)
          res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
      if ((x & 0x080000000000000000000000000000000) != 0)
          res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
      if ((x & 0x100000000000000000000000000000000) != 0)
          res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
      if ((x & 0x200000000000000000000000000000000) != 0)
          res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
      if ((x & 0x400000000000000000000000000000000) != 0)
          res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

      return res;
  }

  function sqrt(uint x) public pure returns (uint y) {
      uint z = (x + 1) / 2;
      y = x;
      while (z < y) {
          y = z;
          z = (x / z + z) / 2;
      }
  }

  /**
   * @notice computes mle for mu in assumed GBM price path
   * @dev Non-standard form of P_t = P_0 * e^{mu * t + sigma * W_t}
   */
  function mu(address tokenIn, address tokenOut, uint points, uint window) public view returns (uint m) {
    // TODO: Fix for signed int output
    uint[] memory p = KV1O.sample(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut, points, window);
    for (uint8 i = 1; i <= (p.length - 1); i++) {
      m += (ln(p[i] * FIXED_1) - ln(p[i-1] * FIXED_1));
    }
    return m / (periodSize * (p.length - 1));
  }

  /**
   * @notice computes mle for sigma**2 in assumed GBM price path
   * @dev Non-standard form of P_t = P_0 * e^{mu * t + sigma * W_t}
   */
  function sigSqrd(address tokenIn, address tokenOut, uint points, uint window) public view returns (uint ss) {
    // TODO: Fix for signed int output
    uint[] memory p = KV1O.sample(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut, points, window);

    uint m = mu(tokenIn, tokenOut, points, window);
    m = m * periodSize;
    for (uint8 i = 1; i <= (p.length - 1); i++) {
      ss += ((ln(p[i] * FIXED_1) - ln(p[i-1] * FIXED_1)) - m)**2; // FIXED_1 needed?
    }
    return ss / (periodSize * (p.length - 1));
  }

  /**
   * @notice computes mle for sigma in assumed GBM price path
   * @dev Non-standard form of P_t = P_0 * e^{mu * t + sigma * W_t}
   */
  function sig(address tokenIn, address tokenOut, uint points, uint window) external view returns (uint) {
    return sqrt(sigSqrd(tokenIn, tokenOut, points, window));
  }

  /**
   * @notice rolling mu for last r windows
   */
  function rMu(address tokenIn, address tokenOut, uint points, uint window, uint8 r) public view returns (uint[] memory) {
    uint[] memory _mus = new uint[](r);

    // need to hit sample() for points = r * points with window = window to get extra number of points
    // then for i = 1, ..., r; assemble the _mus
    uint allPoints = points * uint(r);
    uint[] memory p = KV1O.sample(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut, allPoints, window);

    uint m = 0;
    uint index = 0;
    for (uint8 i = 1; i <= (p.length - 1); i++) {
      m += (ln(p[i] * FIXED_1) - ln(p[i-1] * FIXED_1));
      if (i % (points * window) == 0) {
        _mus[index] = (m / (periodSize * (p.length - 1)));
        m = 0;
        index += 1;
      }
    }
    return _mus;
  }

  /**
   * @notice rolling sig for last r windows
   */
  function rSigSqrd(address tokenIn, address tokenOut, uint points, uint window, uint8 r) external view returns (uint[] memory) {
    uint[] memory _mus = rMu(tokenIn, tokenOut, points, window, r);
    uint[] memory _sigs = new uint[](r);

    // need to hit sample() for points = r * points with window = window to get extra number of points
    // then for i = 1, ..., r; assemble the _sigs
    uint allPoints = points * uint(r);
    uint[] memory p = KV1O.sample(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut, allPoints, window);

    uint ss = 0;
    uint index = 0;
    for (uint8 i = 1; i <= (p.length - 1); i++) {
      ss += ((ln(p[i] * FIXED_1) - ln(p[i-1] * FIXED_1)) - _mus[index]*periodSize)**2;
      if (i % (points * window) == 0) {
        _sigs[index] = (ss / (periodSize * (p.length - 1)));
        ss = 0;
        index += 1;
      }
    }

    return _sigs;
  }
}