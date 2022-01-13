// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./DoubleSupplyStakingRouter.sol";
import "./FixedRateNmxSupplier.sol";

contract FarmingHelper {
    using ABDKMath64x64 for int128;
    address immutable public router;
    
    constructor(address _router) {
        router = _router;
    }

    function mintScheduleNextTickSupply() public view returns (uint256) {
        StakingRouter r = StakingRouter(router);
        Nmx nmx = Nmx(r.nmx());
        MintSchedule schedule = MintSchedule(nmx.mintSchedule());
        MintScheduleState memory state;
        (state.time, state.itemIndex, state.weekIndex, state.weekStartTime, state.nextTickSupply) = nmx.poolMintStates(uint256(MintPool.PRIMARY));

        (, MintScheduleState memory state2) = schedule.makeProgress(state, uint40(block.timestamp), MintPool.PRIMARY);
        (uint256 nmxSupply,) = schedule.makeProgress(state2, uint40(block.timestamp) + 1, MintPool.PRIMARY);
        return nmxSupply;
    }

    function additionalSupplierNextTickSupply() public view returns (uint256) {
        DoubleSupplyStakingRouter r = DoubleSupplyStakingRouter(router);
        FixedRateNmxSupplier additionalSupplier = FixedRateNmxSupplier(r.additionalSupplier());
        if (additionalSupplier.fromTime() > block.timestamp) return 0;
        IERC20 nmx = IERC20(r.nmx());
        uint256 balance = nmx.balanceOf(address(additionalSupplier));
        uint256 result = additionalSupplier.nmxPerSecond();
        if (balance < result) result = balance;
        return result;
    }

    function currentSupplyRate(address reciever) public view returns (uint256) {
        DoubleSupplyStakingRouter r = DoubleSupplyStakingRouter(router);
        int128 share = r.serviceShares(reciever);
        if (share == 0) return 0;
        uint256 nextTickSupply = mintScheduleNextTickSupply() + additionalSupplierNextTickSupply();
        // uint256 nextTickSupply = mintScheduleNextTickSupply();
        return share.mulu(nextTickSupply);        
    }

}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256 (xe);
      else x <<= uint256 (-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= uint256 (re);
      else if (re < 0) result >>= uint256 (-re);

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
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

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./Nmx.sol";
import "./RecoverableByOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract StakingRouter is RecoverableByOwner, NmxSupplier {
    using ABDKMath64x64 for int128;
    address immutable public nmx;
    mapping(address => int128) public serviceShares; /// @dev different StakingServices could have different shares in PRIMARY POOL
    address[] activeServices;
    uint256 pendingSupplyOfInactiveServices;
    mapping(address => uint256) public pendingSupplies; /// @dev If there is more than one StakingService it is necessary to store supplied amount of Nmx between the invocations of particular service to return correct amount of supplied tokens

    constructor(address _nmx) {
        nmx = _nmx;
    }

    /// @dev the owner can change shares of different StakingServices in PRIMARY POOL
    function changeStakingServiceShares(
        address[] calldata addresses,
        int128[] calldata shares
    ) external onlyOwner {
        require(
            addresses.length == shares.length,
            "NmxStakingRouter: addresses must be the same length as shares"
        );
        int128 cumulativeShare = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            require(addresses[i] != address(0), "NmxStakingRouter: zero address is invalid");
            require(shares[i] > 0, "NmxStakingRouter: shares must be positive");
            cumulativeShare += shares[i];
            for (uint256 j = i + 1; j < shares.length; j++) {
                require(addresses[i] != addresses[j], "NmxStakingRouter: duplicate addresses are not possible");
            }
        }
        require(
            cumulativeShare <= ABDKMath64x64.fromInt(1),
            "NmxStakingRouter: shares must be le 1<<64 in total"
        );

        updatePendingSupplies(address(0), uint40(block.timestamp));

        uint256 activeServicesLength = activeServices.length;
        uint256 _pendingSupplyOfInactiveServices = pendingSupplyOfInactiveServices;
        for (uint256 i = 0; i < activeServicesLength; i++) {
            address service = activeServices[i];
            serviceShares[service] = 0;
            _pendingSupplyOfInactiveServices += pendingSupplies[service];
        }
        for (uint256 i = 0; i < shares.length; i++) {
            address service = addresses[i];
            serviceShares[service] = shares[i];
            _pendingSupplyOfInactiveServices -= pendingSupplies[service];
        }
        pendingSupplyOfInactiveServices = _pendingSupplyOfInactiveServices;
        activeServices = addresses;
    }

    function supplyNmx(uint40 maxTime) external override returns (uint256 supply) {
        bool serviceActive;
        (supply, serviceActive) = updatePendingSupplies(_msgSender(), maxTime);
        uint256 pendingSupply = pendingSupplies[_msgSender()];
        if (pendingSupply != 0) {
            pendingSupplies[_msgSender()] = 0;
            supply += pendingSupply;
            if (!serviceActive) pendingSupplyOfInactiveServices -= pendingSupply;
        }

        bool transferred = IERC20(nmx).transfer(_msgSender(), supply);
        require(transferred, "NmxStakingRouter: NMX_FAILED_TRANSFER");
        return supply;
    }

    function getActiveServices() external view returns (address[] memory) {
        return activeServices;
    }

    function updatePendingSupplies(address requestedService, uint40 maxTime)
        private
        returns (uint256 serviceSupply, bool serviceActive)
    {
        uint256 supply = receiveSupply(maxTime);
        uint256 activeServicesLength = activeServices.length;
        for (
            uint256 activeServiceIndex = 0;
            activeServiceIndex < activeServicesLength;
            activeServiceIndex++
        ) {
            address activeService = activeServices[activeServiceIndex];
            int128 activeServiceShare = serviceShares[activeService];
            uint256 activeServiceSupply =
                ABDKMath64x64.mulu(activeServiceShare, supply);
            if (activeService == requestedService) {
                serviceSupply = activeServiceSupply;
                serviceActive = true;
            } else {
                pendingSupplies[activeService] += activeServiceSupply;
            }
        }
        return (serviceSupply, serviceActive);
    }

    function receiveSupply(uint40 maxTime) internal virtual returns (uint256) {
        return NmxSupplier(nmx).supplyNmx(maxTime);
    }

    function getRecoverableAmount(address tokenAddress) override internal view returns (uint256) {
        if (tokenAddress != nmx) return RecoverableByOwner.getRecoverableAmount(tokenAddress);
        uint256 pendingSupply = pendingSupplyOfInactiveServices;
        address[] memory _activeServices = activeServices;
        for(uint256 i = 0; i < _activeServices.length; i++) {
            pendingSupply += pendingSupplies[_activeServices[i]];
        }
        uint256 balance = IERC20(nmx).balanceOf(address(this));
        assert(balance >= pendingSupply);
        return balance - pendingSupply;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 @dev The contract is intendent to help recovering arbitrary ERC20 tokens and ETH accidentally transferred to the contract address
 */
abstract contract RecoverableByOwner is Ownable {
    function getRecoverableAmount(address tokenAddress)
        internal
        view
        virtual
        returns (uint256)
    {
        if (tokenAddress == address(0)) return address(this).balance;
        else return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     @param tokenAddress ERC20 token's address to recover or address(0) to recover ETH
     @param amount to recover from contract's address
     @param to address to receive tokens from the contract
     */
    function recoverFunds(
        address tokenAddress,
        uint256 amount,
        address to
    ) external onlyOwner {
        uint256 recoverableAmount = getRecoverableAmount(tokenAddress);
        require(
            amount <= recoverableAmount,
            "RecoverableByOwner: RECOVERABLE_AMOUNT_NOT_ENOUGH"
        );
        if (tokenAddress == address(0)) recoverEth(amount, to);
        else recoverErc20(tokenAddress, amount, to);
    }

    function recoverEth(uint256 amount, address to) private {
        address payable toPayable = payable(to);
        toPayable.transfer(amount);
    }

    function recoverErc20(
        address tokenAddress,
        uint256 amount,
        address to
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = tokenAddress.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'RecoverableByOwner: TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to got minted Nmx.
 */
interface NmxSupplier {
    /**
      @dev if caller is owner of any mint pool it will be supplied with Nmx based on the schedule and time passed from the moment
      when the method was invoked by the same mint pool owner last time
      @param maxTime the upper limit of the time to make calculations
    */
    function supplyNmx(uint40 maxTime) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./NmxSupplier.sol";
import "./MintSchedule.sol";
import "./RecoverableByOwner.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Nmx is ERC20, NmxSupplier, RecoverableByOwner {
    bytes32 immutable public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    address public mintSchedule;
    mapping(address => MintPool) public poolByOwner;
    address[3] public poolOwners; // 3 - number of MintPool values
    /** @dev dedicated state for every pool to decrease gas consumtion in case of staking/unstaking - no updates related to other mint pools are required to be persisted */
    MintScheduleState[3] public poolMintStates; // 3 - number of MintPool values

    uint40 private constant DISTRIBUTION_START_TIME = 1614319200; // 2021-02-26T06:00:00Z

    event PoolOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        MintPool indexed pool
    );
    event ScheduleChanged(address previousSchedule, address newSchedule);

    constructor(address _mintSchedule) ERC20("Nominex", "NMX") {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        emit ScheduleChanged(mintSchedule, _mintSchedule);
        mintSchedule = _mintSchedule;
        for (
            uint256 i = uint256(MintPool.PRIMARY);
            i <= uint256(MintPool.NOMINEX);
            i++
        ) {
            MintScheduleState storage poolMintState = poolMintStates[i];
            poolMintState.nextTickSupply =
                (40000 * 10**18) /
                uint40(1 days) +
                1; // +1 - to coupe with rounding error when daily supply is 9999.9999...
            poolMintState.time = DISTRIBUTION_START_TIME;
            poolMintState.weekStartTime = DISTRIBUTION_START_TIME;
        }
        // amount of Nmx has been distributed or sold already at the moment of contract deployment
        uint256 alreadyDistributedAmount = 7505656;
        // airdrops, starts of liquidity mining pools, running other secondary liquidity mining pools
        uint256 additionalAmount = 20000000;
        _mint(_msgSender(), (alreadyDistributedAmount + additionalAmount) * 10**18);
    }

    function changeSchedule(address _mintSchedule) external onlyOwner {
        require(_mintSchedule != address(0), "NMX: new schedule can not have zero address");
        require(_mintSchedule != mintSchedule, "NMX: new schedule can not be equal to the previous one");
        emit ScheduleChanged(mintSchedule, _mintSchedule);
        mintSchedule = _mintSchedule;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "NMX: deadline expired");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "NMX: invalid signature"
        );
        _approve(owner, spender, value);
    }

    /// @dev the contract owner can change any of mint pool owners
    function transferPoolOwnership(MintPool pool, address newOwner) external {
        address currentOwner = poolOwners[uint256(pool)];
        require(
            newOwner != currentOwner,
            "NMX: new owner must differs from the old one"
        );
        require(
            _msgSender() == owner() || _msgSender() == currentOwner,
            "NMX: only owner can transfer pool ownership"
        );
        MintPool existentPoolOfNewOwner = poolByOwner[newOwner];
        require(MintPool.DEFAULT_VALUE == existentPoolOfNewOwner || newOwner == address(0), "NMX: every pool must have dedicated owner");

        emit PoolOwnershipTransferred(currentOwner, newOwner, pool);
        poolOwners[uint256(pool)] = newOwner;
        poolByOwner[currentOwner] = MintPool.DEFAULT_VALUE;
        poolByOwner[newOwner] = pool;
    }

    /**
      @dev if caller is owner of any mint pool it will be supplied with Nmx based on the schedule and time passed from the moment
      when the method was invoked by the same mint pool owner last time
      @param maxTime the upper limit of the time to make calculations
    */
    function supplyNmx(uint40 maxTime) external override returns (uint256) {
        if (maxTime > uint40(block.timestamp)) maxTime = uint40(block.timestamp);
        MintPool pool = poolByOwner[_msgSender()];
        if (pool == MintPool.DEFAULT_VALUE) return 0;
        MintScheduleState storage state = poolMintStates[uint256(pool)];
        (uint256 supply, MintScheduleState memory newState) =
            MintSchedule(mintSchedule).makeProgress(
                state,
                maxTime,
                pool
            );
        poolMintStates[uint256(pool)] = newState;
        _mint(_msgSender(), supply);
        return supply;
    }

    /// @dev view function to support displaying PRIMARY POOL daily supply on UI
    function rewardRate() external view returns (uint256) {
        (, MintScheduleState memory newState) =
            MintSchedule(mintSchedule).makeProgress(
                poolMintStates[uint256(MintPool.PRIMARY)],
                uint40(block.timestamp),
                MintPool.PRIMARY
            );
        return uint256(newState.nextTickSupply);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Lib.sol";
import "./RecoverableByOwner.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract MintSchedule is RecoverableByOwner {
    /**
     @dev structure to describe the mint schedule. After each week MintScheduleState.nextTickSupply decreases.
     When the schedule completes weekCount weeks in current item it goes to the next item in the items.
     @param weekCount duration of the item in weeks
     @param weekCompletenessMultiplier a number nextTickSupply is multiplied by after each week in the item
     @param poolShares shares of the mint pool in the item
     */
    struct ScheduleItem {
        uint16 weekCount;
        int128 weekCompletenessMultiplier;
        int128[] poolShares;
    }
    uint40 constant WEEK_DURATION = 7 days;

    using ABDKMath64x64 for int128;
    ScheduleItem[] public items; /// @dev array of shcedule describing items

    constructor() {
        // 0.0, 0.625, 0.375
        int128[3] memory shares_01_28 =
            [
                0,
                ABDKMath64x64.divu(625, 1000),
                ABDKMath64x64.divu(375, 1000)
            ];

        // 0.0, 0.5625, 0.4375
        int128[3] memory shares_29_56 =
            [
                0,
                ABDKMath64x64.divu(5625, 10000),
                ABDKMath64x64.divu(4375, 10000)
            ];

        // 0.0, 0.5, 0.5
        int128[3] memory shares_57_xx =
            [
                0,
                ABDKMath64x64.divu(5, 10),
                ABDKMath64x64.divu(5, 10)
            ];

        /* period 1-7 days | duration 7 days | summary 1 week */
        ScheduleItem storage item = items.push();
        item.weekCount = 1;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(75, 100);
        item.poolShares = shares_01_28;

        /* period 8-14 days | duration 7 days | summary 2 weeks */
        item = items.push();
        item.weekCount = 1;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(35, 100);
        item.poolShares = shares_01_28;

        /* period 15-28 days | 2 weeks | summary 4 weeks */
        item = items.push();
        item.weekCount = 2;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(104, 100);
        item.poolShares = shares_01_28;

        /* period 29-56 days | 4 weeks | summary 8 weeks */
        item = items.push();
        item.weekCount = 4;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(104, 100);
        item.poolShares = shares_29_56;

        /* period 57-105 days | 7 weeks | summary 15 weeks */
        item = items.push();
        item.weekCount = 7;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(104, 100);
        item.poolShares = shares_57_xx;

        /* period 106-196 days | duration 3 months | summary 28 weeks */
        item = items.push();
        item.weekCount = 13;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(102, 100);
        item.poolShares = shares_57_xx;

        /* period 197-287 days | duration 3 months | summary 41 weeks */
        item = items.push();
        item.weekCount = 13;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(101, 100);
        item.poolShares = shares_57_xx;

        /* period 288-378 days | duration 3 months | summary 54 weeks */
        item = items.push();
        item.weekCount = 13;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(1, 1);
        item.poolShares = shares_57_xx;

        /* period 379-560 days | duration 6 months | summary 80 weeks */
        item = items.push();
        item.weekCount = 26;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(9995, 10000);
        item.poolShares = shares_57_xx;

        /* period 561-742 days | duration 6 months | summary 106 weeks */
        item = items.push();
        item.weekCount = 26;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(999, 1000);
        item.poolShares = shares_57_xx;

        /* period 743-924 days | duration 6 months | summary 132 weeks */
        item = items.push();
        item.weekCount = 26;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(9985, 10000);
        item.poolShares = shares_57_xx;

        /* period 925-1106 days | duration 6 months | summary 158 weeks */
        item = items.push();
        item.weekCount = 26;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(998, 1000);
        item.poolShares = shares_57_xx;

        /* period 1107-1470 days | duration 1 year | summary 210 weeks */
        item = items.push();
        item.weekCount = 52;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(9975, 10000);
        item.poolShares = shares_57_xx;

        /* period 1471-1834 days | duration 1 year | summary 262 weeks */
        item = items.push();
        item.weekCount = 52;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(997, 1000);
        item.poolShares = shares_57_xx;

        /* period 1835-2198 days | duration 1 year | summary 314 weeks */
        item = items.push();
        item.weekCount = 52;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(9965, 10000);
        item.poolShares = shares_57_xx;

        /* period 2199-2562 days | duration 1 year | summary 366 weeks */
        item = items.push();
        item.weekCount = 52;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(996, 1000);
        item.poolShares = shares_57_xx;

        /* period 2563-2926 days | duration 1 year | summary 418 weeks */
        item = items.push();
        item.weekCount = 52;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(997, 1000);
        item.poolShares = shares_57_xx;

        /* period 2927-3654 days | duration 2 year | summary 522 weeks */
        item = items.push();
        item.weekCount = 104;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(998, 1000);
        item.poolShares = shares_57_xx;

        /* period 3655-5110 days | duration 4 years | summary 730 weeks */
        item = items.push();
        item.weekCount = 208;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(999, 1000);
        item.poolShares = shares_57_xx;

        /* period 5111-8022 days | duration 8 years | summary 1146 weeks */
        item = items.push();
        item.weekCount = 416;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(9995, 10000);
        item.poolShares = shares_57_xx;

        /* period 8023-22582 days | duration 40 years | summary 3226 weeks */
        item = items.push();
        item.weekCount = 2080;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(9999, 10000);
        item.poolShares = shares_57_xx;

        /* period 22583-26096 days | duration 10 years (without 18 weeks) | summary 3728 weeks */
        item = items.push();
        item.weekCount = 502;
        item.weekCompletenessMultiplier = ABDKMath64x64.divu(99995, 100000);
        item.poolShares = shares_57_xx;
    }

    /**
     @dev calculates changes in scheduleState based on the time passed from last update and returns updated state and amount of Nmx to be minted
     */
    function makeProgress(
        MintScheduleState memory scheduleState,
        uint40 time,
        MintPool pool
    ) external view returns (uint256 nmxSupply, MintScheduleState memory) {
        if (time <= scheduleState.time) return (0, scheduleState);
        while (
            time > scheduleState.time && scheduleState.itemIndex < items.length
        ) {
            ScheduleItem storage item = items[scheduleState.itemIndex];
            uint40 boundary =
                min(time, scheduleState.weekStartTime + WEEK_DURATION);
            uint256 secondsFromLastUpdate = boundary - scheduleState.time;
            nmxSupply +=
                secondsFromLastUpdate *
                item.poolShares[uint256(pool)].mulu(
                    uint256(scheduleState.nextTickSupply)
                );
            persistStateChange(scheduleState, item, boundary);
        }
        return (nmxSupply, scheduleState);
    }

    function persistStateChange(
        MintScheduleState memory state,
        ScheduleItem memory item,
        uint40 time
    ) private pure {
        state.time = time;
        if (time == state.weekStartTime + WEEK_DURATION) {
            state.nextTickSupply = uint128(
                item.weekCompletenessMultiplier.mulu(
                    uint256(state.nextTickSupply)
                )
            );
            state.weekIndex++;
            state.weekStartTime = time;
            if (state.weekIndex == item.weekCount) {
                state.weekIndex = 0;
                state.itemIndex++;
            }
        }
    }

    function min(uint40 a, uint40 b) private pure returns (uint40) {
        if (a < b) return a;
        return b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev kinds of possible pools
 *
 * @param DEFAULT_VALUE - dummy type for null value
 * @param PRIMARY - blockchain based staking. All rules are declared in the  contracts
 * @param NOMINEX - tokens for Nominex company (BONUS and TEAM pools included)
 */
enum MintPool {DEFAULT_VALUE, PRIMARY, NOMINEX}

/**
 * @dev current state of the schedule for each MintPool
 *
 * @param time last invocation time
 * @param itemIndex index of current item in MintSchedule.items
 * @param weekIndex index of current week in current item in MintSchedule.items
 * @param weekStartTime start time of the current week
 * @param nextTickSupply amount of Nmx to be distributed next second
 */
struct MintScheduleState {
    uint40 time;
    uint8 itemIndex;
    uint16 weekIndex;
    uint40 weekStartTime;
    uint128 nextTickSupply;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./NmxSupplier.sol";
import "./RecoverableByOwner.sol";

contract FixedRateNmxSupplier is NmxSupplier, RecoverableByOwner {
    address immutable nmx;
    address immutable stakingRouter;
    uint128 public nmxPerSecond;
    uint40 public fromTime;

    modifier onlyStakingRouter() {
        require(stakingRouter == msg.sender, "FixedRateNmxSupplier: caller is not the staking router");
        _;
    }

    constructor(address _nmx, address _stakingRouter) {
        nmx = _nmx;
        stakingRouter = _stakingRouter;
    }

    function updateRate(uint128 _nmxPerSecond) onlyOwner external {
        updateRate(_nmxPerSecond, uint40(block.timestamp));
    }

    function updateRate(uint128 _nmxPerSecond, uint40 _fromTime) onlyOwner public {
        nmxPerSecond = _nmxPerSecond;
        fromTime = _fromTime;
    }

    function supplyNmx(uint40 maxTime) onlyStakingRouter external override returns (uint256) {
        uint128 _nmxPerSecond = nmxPerSecond;
        if (_nmxPerSecond == 0) return 0;
        if (uint40(block.timestamp) < maxTime) maxTime = uint40(block.timestamp);
        uint40 _fromTime = fromTime;
        if (_fromTime >= maxTime) return 0;
        uint40 secondsPassed = maxTime - _fromTime;
        uint256 amount = _nmxPerSecond * secondsPassed;
        uint256 balance = IERC20(nmx).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount > 0) {
            bool transferred = IERC20(nmx).transfer(msg.sender, amount);
            require(transferred, "FixedRateNmxSupplier: NMX_FAILED_TRANSFER");
            fromTime = maxTime;
        }
        return amount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./FixedRateNmxSupplier.sol";
import "./StakingRouter.sol";

contract DoubleSupplyStakingRouter is StakingRouter {
    address immutable public additionalSupplier;

    constructor(address _nmx) StakingRouter(_nmx) {
        FixedRateNmxSupplier fixedRateNmxSupplier = new FixedRateNmxSupplier(_nmx, address(this));
        fixedRateNmxSupplier.transferOwnership(msg.sender);
        additionalSupplier = address(fixedRateNmxSupplier);
    }

    function receiveSupply(uint40 maxTime) override internal returns (uint256) {
        return StakingRouter.receiveSupply(maxTime) + NmxSupplier(additionalSupplier).supplyNmx(maxTime);
    }

}