/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/libs/TransferHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/libs/StringHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 字符串工具
library StringHelper {

    /// @dev 连接两个字符串
    /// @param a 字符串a
    /// @param b 字符串b
    /// @return 连接后的字符串
    function stringConcat(string memory a, string memory b) internal pure returns (string memory)
    {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory ret = new string(ba.length + bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < ba.length; ++i) {
            bret[k++] = ba[i];
        } 
        for (uint i = 0; i < bb.length; ++i) {
            bret[k++] = bb[i];
        } 
        return string(ret);
    } 
    
    /// @dev 将整形转化为字符串，如果长度小于指定长度，则在前面补0
    /// @param iv 要转化的整形值
    /// @param minLength 最小长度
    /// @return 转化结果字符串
    function toString(uint iv, uint minLength) internal pure returns (string memory) 
    {
        bytes memory buf = new bytes(64);
        uint index = 0;
        do {
            buf[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        } while (iv > 0 || index < minLength);
        bytes memory str = new bytes(index);
        for(uint i = 0; i < index; ++i) {
            str[i] = buf[index - i - 1];
        }
        return string(str);
    }

    /// @dev 将字符串转为大写形式
    /// @param str 目标字符串
    /// @return 目标字符串的大写
    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 97 && b <= 122) {
                bs[i] = bytes1(uint8(b - 32));
            }
        }
        return str;
    }

    /// @dev 将字符串转为小写形式
    /// @param str 目标字符串
    /// @return 目标字符串的小写
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 65 && b <= 90) {
                bs[i] = bytes1(uint8(b + 32));
            }
        }
        return str;
    }

    /// @dev 截取字符串
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @return 截取结果
    function substring(string memory str, uint start, uint count) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        if (start >= length) {
            return "";
        }
        if (start + count > length) {
            count = length - start;
        }
        bytes memory re = new bytes(count);
        while (count > 0) {
            --count;
            re[count] = bs[start + count];
        }
        return string(re);
    }

    /// @dev 截取字符串
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @return 截取结果
    function substring(string memory str, uint start) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        if (start >= length) {
            return "";
        }
        uint count = length - start;
        bytes memory re = new bytes(count);
        while (count > 0) {
            --count;
            re[count] = bs[start + count];
        }
        return string(re);
    }
}


// File contracts/libs/ABDKMath64x64.sol

// BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

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
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
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
    unchecked {
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
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
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
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
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
    unchecked {
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
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
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
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
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
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
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
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
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

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
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
    unchecked {
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
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
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
}


// File contracts/interfaces/IFortEuropeanOption.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 定义欧式期权接口
interface IFortEuropeanOption {
    
    struct Config {
        // 波动率
        uint96 sigmaSQ;

        // 64位二进制精度
        // 0.3/365/86400 = 9.512937595129377E-09
        // 175482725206
        int128 miu;

        // TODO: 通过数值计算过程，确定期权行权时间最大间隔
        // 期权行权时间和当前时间的最小间隔
        uint32 minPeriod;
    }

    /// @dev Modify configuration
    /// @param tokenAddress 目标代币地址
    /// @param config Configuration object
    function setConfig(address tokenAddress, Config calldata config) external;

    /// @dev Get configuration
    /// @param tokenAddress 目标代币地址
    /// @return Configuration object
    function getConfig(address tokenAddress) external view returns (Config memory);

    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (address[] memory optionArray);
    
    /// @dev 获取已经开通的欧式期权代币数量
    /// @return 已经开通的欧式期权代币数量
    function getTokenCount() external view returns (uint);

    /// @dev 获取欧式期权代币地址
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @return 欧式期权代币地址
    function getEuropeanToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) external view returns (address);

    /// @dev 预估开仓可以买到的期权币数量
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    /// @param oraclePrice 当前预言机价格价
    /// @return amount 预估可以获得的期权币数量
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external view returns (uint amount);

    /// @dev 开仓
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    function open(
        address tokenAddress,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external payable;

    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable;
}


// File contracts/interfaces/IFortMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for Fort builtin contract address mapping
interface IFortMapping {

    /// @dev Set the built-in contract address of the system
    /// @param fortToken Address of fort token contract
    /// @param fortDAO IFortDAO implementation contract address
    /// @param fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @param fortLever IFortLever implementation contract address
    /// @param fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return fortToken Address of fort token contract
    /// @return fortDAO IFortDAO implementation contract address
    /// @return fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @return fortLever IFortLever implementation contract address
    /// @return fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view returns (
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    );

    /// @dev Get address of fort token contract
    /// @return Address of fort token contract
    function getFortTokenAddress() external view returns (address);

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getFortDAOAddress() external view returns (address);

    /// @dev Get IFortEuropeanOption implementation contract address for Fort
    /// @return IFortEuropeanOption implementation contract address for Fort
    function getFortEuropeanOptionAddress() external view returns (address);

    /// @dev Get IFortLever implementation contract address
    /// @return IFortLever implementation contract address
    function getFortLeverAddress() external view returns (address);

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getFortVaultForStakingAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by Fort system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}


// File contracts/interfaces/IFortGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface IFortGovernance is IFortMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/interfaces/IFortDAO.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface IFortDAO {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable;

    /// @dev The function returns eth rewards of specified pool
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view returns (uint);

    /// @dev Settlement
    /// @param pool Destination pool. Indicates which pool to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable;
}


// File contracts/FortBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of Fort
contract FortBase {

    /// @dev IFortGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Fort:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IFortGovernance(governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to FortDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = IFortGovernance(_governance).getFortDAOAddress();
        if (tokenAddress == address(0)) {
            IFortDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IFortGovernance(_governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "Fort:!contract");
        _;
    }
}


// File contracts/FortFrequentlyUsed.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of Fort
contract FortFrequentlyUsed is FortBase {

    // Address of FortToken contract
    //address constant FORT_TOKEN_ADDRESS = ;
    address FORT_TOKEN_ADDRESS;

    // Address of NestPriceFacade contract
    address NEST_PRICE_FACADE_ADDRESS;
    
    // USDT代币地址
    //address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDT_TOKEN_ADDRESS;

    // USDT代币的基数
    uint constant USDT_BASE = 1000000;

    // Genesis block number of fort
    // FortToken contract is created at block height TODO: 11040156. However, because the mining algorithm of Fort v1.0
    // is different from that at present, a new mining algorithm is adopted from Fort v2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the fort begins to decay. According to the circulation when Fort v1.0 is online, the new mining
    // algorithm is used to deduce and convert the fort, and the new algorithm is used to mine the Fort2.1
    // on-line flow, the actual block is TODO: 11040688
    uint constant FORT_GENESIS_BLOCK = 0;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public override {

        super.update(newGovernance);
        (
            FORT_TOKEN_ADDRESS,//address fortToken,
            ,//address fortDAO,
            ,//address fortEuropeanOption,
            ,//address fortLever,
            ,//address fortVaultForStaking,
            NEST_PRICE_FACADE_ADDRESS //address nestPriceFacade
        ) = IFortGovernance(newGovernance).getBuiltinAddress();
    }

    // TODO: 测试方法
    function setUsdtTokenAddress(address usdtTokenAddress) external {
        USDT_TOKEN_ADDRESS = usdtTokenAddress;
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

// MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// MIT

pragma solidity ^0.8.0;



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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/interfaces/INestPriceFacade.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the methods for price call entry
interface INestPriceFacade {
    
    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        address tokenAddress, 
        uint height, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price);

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        address tokenAddress, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price);

    // /// @dev Price call entry configuration structure
    // struct Config {

    //     // Single query fee（0.0001 ether, DIMI_ETHER). 100
    //     uint16 singleFee;

    //     // Double query fee（0.0001 ether, DIMI_ETHER). 100
    //     uint16 doubleFee;

    //     // The normal state flag of the call address. 0
    //     uint8 normalFlag;
    // }

    // /// @dev Modify configuration
    // /// @param config Configuration object
    // function setConfig(Config calldata config) external;

    // /// @dev Get configuration
    // /// @return Configuration object
    // function getConfig() external view returns (Config memory);

    // /// @dev Set the address flag. Only the address flag equals to config.normalFlag can the price be called
    // /// @param addr Destination address
    // /// @param flag Address flag
    // function setAddressFlag(address addr, uint flag) external;

    // /// @dev Get the flag. Only the address flag equals to config.normalFlag can the price be called
    // /// @param addr Destination address
    // /// @return Address flag
    // function getAddressFlag(address addr) external view returns(uint);

    // /// @dev Set INestQuery implementation contract address for token
    // /// @param tokenAddress Destination token address
    // /// @param nestQueryAddress INestQuery implementation contract address, 0 means delete
    // function setNestQuery(address tokenAddress, address nestQueryAddress) external;

    // /// @dev Get INestQuery implementation contract address for token
    // /// @param tokenAddress Destination token address
    // /// @return INestQuery implementation contract address, 0 means use default
    // function getNestQuery(address tokenAddress) external view returns (address);

    // /// @dev Get cached fee in fee channel
    // /// @param tokenAddress Destination token address
    // /// @return Cached fee in fee channel
    // function getTokenFee(address tokenAddress) external view returns (uint);

    // /// @dev Settle fee for charge fee channel
    // /// @param tokenAddress tokenAddress of charge fee channel
    // function settle(address tokenAddress) external;
    
    // /// @dev Get the latest trigger price
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function triggeredPrice(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(
        address tokenAddress, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ);

    // /// @dev Find the price at block number
    // /// @param tokenAddress Destination token address
    // /// @param height Destination block number
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function findPrice(
    //     address tokenAddress, 
    //     uint height, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    // /// @dev Get the latest effective price
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function latestPrice(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    // /// @dev Get the last (num) effective price
    // /// @param tokenAddress Destination token address
    // /// @param count The number of prices that want to return
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    // function lastPriceList(
    //     address tokenAddress, 
    //     uint count, 
    //     address paybackAddress
    // ) external payable returns (uint[] memory);

    // /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return latestPriceBlockNumber The block number of latest price
    // /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    // /// @return triggeredPriceBlockNumber The block number of triggered price
    // /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    // /// @return triggeredAvgPrice Average price
    // /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function latestPriceAndTriggeredPriceInfo(address tokenAddress, address paybackAddress) 
    // external 
    // payable 
    // returns (
    //     uint latestPriceBlockNumber, 
    //     uint latestPriceValue,
    //     uint triggeredPriceBlockNumber,
    //     uint triggeredPriceValue,
    //     uint triggeredAvgPrice,
    //     uint triggeredSigmaSQ
    // );

    // /// @dev Returns lastPriceList and triggered price info
    // /// @param tokenAddress Destination token address
    // /// @param count The number of prices that want to return
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    // /// @return triggeredPriceBlockNumber The block number of triggered price
    // /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    // /// @return triggeredAvgPrice Average price
    // /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function lastPriceListAndTriggeredPriceInfo(
    //     address tokenAddress, 
    //     uint count, 
    //     address paybackAddress
    // ) external payable 
    // returns (
    //     uint[] memory prices,
    //     uint triggeredPriceBlockNumber,
    //     uint triggeredPriceValue,
    //     uint triggeredAvgPrice,
    //     uint triggeredSigmaSQ
    // );

    // /// @dev Get the latest trigger price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // function triggeredPrice2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice
    // );

    // /// @dev Get the full information of latest trigger price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return avgPrice Average price
    // /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    // /// the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447, 
    // /// it means that the volatility has exceeded the range that can be expressed
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // /// @return ntokenAvgPrice Average price of ntoken
    // /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function triggeredPriceInfo2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint avgPrice, 
    //     uint sigmaSQ, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice, 
    //     uint ntokenAvgPrice, 
    //     uint ntokenSigmaSQ
    // );

    // /// @dev Get the latest effective price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // function latestPrice2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice
    // );
}


// File contracts/FortToken.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// TODO: 命名问题
/// @dev Fort代币
contract FortToken is FortBase, ERC20("Decentralized Derivatives Unit", "DCU") {

    // 保存挖矿权限地址
    mapping(address=>uint) _minters;

    constructor() {
    }

    modifier onlyMinter {
        require(_minters[msg.sender] == 1, "FortToken:not minter");
        _;
    }

    /// @dev 设置挖矿权限
    /// @param account 目标账号
    /// @param flag 挖矿权限标记，只有1表示可以挖矿
    function setMinter(address account, uint flag) external onlyGovernance {
        _minters[account] = flag;
    }

    function checkMinter(address account) external view returns (uint) {
        return _minters[account];
    }

    /// @dev 铸币
    /// @param to 接受地址
    /// @param value 铸币数量
    function mint(address to, uint value) external onlyMinter {
        _mint(to, value);
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param value 销毁数量
    function burn(address from, uint value) external onlyMinter {
        _burn(from, value);
    }
}


// File contracts/FortOptionToken.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev 期权凭证
contract FortOptionToken is ERC20 {

    address immutable OWNER;
    address immutable TOKEN_ADDRESS;
    uint immutable PRICE;
    bool immutable ORIENTATION;
    uint immutable ENDBLOCK;

    constructor(
        string memory name, 
        string memory symbol, 
        address tokenAddress, 
        uint price,
        bool orientation,
        uint endblock
    ) ERC20(name, symbol) {
        
        OWNER = msg.sender;
        TOKEN_ADDRESS = tokenAddress;
        PRICE = price;
        ORIENTATION = orientation;
        ENDBLOCK = endblock;
    }

    modifier onlyOwner {
        require(msg.sender == OWNER, "FortOptionToken:not owner");
        _;
    }
    
    /// @dev 获取期权信息
    /// @return tokenAddress 目标代币地址
    /// @return price 行权价格
    /// @return orientation 期权方向
    /// @return endblock 行权区块号
    function getOptionInfo() external view returns (
        address tokenAddress, 
        uint price,
        bool orientation,
        uint endblock
    ) {
        return (TOKEN_ADDRESS, PRICE, ORIENTATION, ENDBLOCK);
    }

    /// @dev 铸币
    /// @param to 接收地址
    /// @param value 铸币数量
    function mint(address to, uint value) external onlyOwner {
        _mint(to, value);
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param value 销毁数量
    function burn(address from, uint value) external onlyOwner {
        _burn(from, value);
    }
}


// File hardhat/[email protected]

// MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File contracts/FortEuropeanOption.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev 欧式期权
contract FortEuropeanOption is FortFrequentlyUsed, IFortEuropeanOption {

    // 64位二进制精度的1
    int128 constant ONE = 0x10000000000000000;

    // 64位二进制精度的2
    int128 constant TWO = 0x20000000000000000;

    // 64位二进制精度的50000
    uint constant V50000 = 0x0C3500000000000000000;

    // 期权代币映射
    mapping(bytes32=>address) _optionMapping;

    // 配置参数
    mapping(address=>Config) _configs;

    // 期权代币数组
    address[] _options;

    constructor() {
    }

    // /// @dev 设置配置
    // function setConfig(uint96 sigmaSQ, int128 miu, uint32 minPeriod) external onlyGovernance {
    //     _sigmaSQ = sigmaSQ;
    //     _miu = miu;
    //     _minPeriod = minPeriod;
    // }

    // /// @dev 获取配置
    // function getConfig() external view returns (uint96 sigmaSQ, int128 miu, uint32 minPeriod) {
    //     return (_sigmaSQ, _miu, _minPeriod);
    // }
    
    /// @dev Modify configuration
    /// @param tokenAddress 目标代币地址
    /// @param config Configuration object
    function setConfig(address tokenAddress, Config calldata config) external override {
        _configs[tokenAddress] = config;
    }

    /// @dev Get configuration
    /// @param tokenAddress 目标代币地址
    /// @return Configuration object
    function getConfig(address tokenAddress) external view override returns (Config memory) {
        return _configs[tokenAddress];
    }

    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view override returns (address[] memory optionArray) {

        // 加载代币数组
        address[] storage options = _options;
        // 创建结果数组
        optionArray = new address[](count);

        uint i = 0;
        // 倒序
        if (order == 0) {
            uint end = options.length - offset - 1;
            while (i < count) {
                optionArray[i] = options[end - i];
                ++i;
            }
        } 
        // 正序
        else {
            while (i < count) {
                optionArray[i] = options[i + offset];
                ++i;
            }
        }
    }

    /// @dev 获取已经开通的欧式期权代币数量
    /// @return 已经开通的欧式期权代币数量
    function getTokenCount() external view override returns (uint) {
        return _options.length;
    }

    // 对齐价格，保留7位有效数字
    function _align(uint price) private pure returns (uint) {
        uint decimals = 0;
        while (price >= 10000000) {
            price /= 10;
            ++decimals;
        }
        return price * 10 ** decimals;
    }

    // 根据期权信息获取索引key
    function _getKey(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
    }

    /// @dev 获取欧式期权代币地址
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @return 欧式期权代币地址
    function getEuropeanToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) external view override returns (address) {
        return _optionMapping[_getKey(tokenAddress, _align(price), orientation, endblock)];
    }

    // // 检查开仓代币地址是否合法
    // function _check(address tokenAddress) private pure returns (bool) {
    //     // TODO: 确定哪些交易对可以开仓
    //     //return tokenAddress == 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    //     require(tokenAddress == address(0), "FEO:not allowed");
    //     return true;
    // }

    // 获取代币的小数位数
    function _getDecimals(address tokenAddress) private view returns (uint) {
        if (tokenAddress == address(0)) {
            return 18;
        }
        return uint(ERC20(tokenAddress).decimals());
    }

    // C2.006-7ETH1000877
    // 那就7位有效数字 然后+-10的幂次
    // 最多或者6位也行 代币名称
    function _getName(
        string memory name, 
        uint price, 
        bool orientation, 
        uint endblock
    ) public pure returns (string memory) {

        bytes memory re = new bytes(31);
        uint index = 0;

        // 1. 将价格保留7位有效数字，并计算指数部分
        uint decimals = 6;
        while (price < 1000000) {
            price = price * 10;
            --decimals;
        }
        while (price >= 10000000) {
            price = price / 10;
            ++decimals;
        }

        // 2. 期权方向，看涨C，看跌P
        if (orientation) {
            re[index++] = bytes1(uint8(67));
        } else {
            re[index++] = bytes1(uint8(80));
        }

        // 3. 期权行权价格
        // 3.1 行权价格整数部分
        uint c = price / 1000000;
        re[index++] = bytes1(uint8(48 + c));
        re[index++] = bytes1(uint8(46));
        // 3.2 行权价格小数部分
        for (uint b = 1000000; b > 1; b /= 10) {
            c = (price % b) / (b / 10);
            re[index++] = bytes1(uint8(48 + c));
        }
        // 3.3 行权价格指数部分
        if (decimals < 6) {
            re[index++] = bytes1(uint8(45));
            decimals = 6 - decimals;
        } else {
            re[index++] = bytes1(uint8(43));
            decimals = decimals - 6;
        }
        require(decimals < 10, "FEO:price to large");
        re[index++] = bytes1(uint8(decimals + 48));
        
        // 4. 目标代币名称
        bytes memory str = bytes(name);
        for (uint i = 0; i < str.length; ++i) {
            re[index++] = str[i];
        }

        // 5. 行权区块号
        str = bytes(StringHelper.toString(endblock, 1));
        for (uint i = 0; i < str.length; ++i) {
            re[index++] = str[i];
        }

        return string(re);
    }

    /// @dev 开仓
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    function open(
        address tokenAddress,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external payable override {

        Config memory config = _configs[tokenAddress];
        require(uint(config.minPeriod) > 0, "FEO:not allowed");
        // 1. 最小期权费用（计算公式）为每份（注意用户买入可以是0.1份，这是指计算）
        //    期权费用不低于S0,K的1%（分别对应看涨和看跌）
        //    Vc>=S0*1%; Vp>=K*1%
        // 2. 行权周期不低于10000区块
        // 3. 杠杆币 100FORT起（最小单位未来和FORT价格挂钩：注意激励相容） 期权0.1份起
        // 4. 按照区块触发
        // 5. 1.0目前就支持eth/usd开仓
        // 6. 杠杆币：E/U+F1和E/U-F1
        // 7. 期权 C3302E/U10003837 P3321E/U10008766
        //    价格精度和转化问题

        require(fortAmount < 0x100000000000000000000000000000000, "FEO:fortAmount too large");
        require(endblock > block.number + uint(config.minPeriod), "FEO:endblock to small");

        // 1. 获取或创建期权代币
        price = _align(price);
        bytes32 key = _getKey(tokenAddress, price, orientation, endblock);
        address option = _optionMapping[key];
        if (option == address(0)) {
            
            // TODO: 重新对齐
            // TODO: 代币命名问题
            //string memory idx = StringHelper.toString(_options.length, 1);
            string memory name = _getName(
                tokenAddress == address(0) ? "ETH" : StringHelper.substring(
                    StringHelper.toUpper(ERC20(tokenAddress).symbol()),
                    0,
                    4
                ),
                price, 
                orientation, 
                endblock
            );
            option = address(new FortOptionToken(
                name,
                name,
                tokenAddress, 
                price, 
                orientation, 
                endblock
            ));
            _optionMapping[key] = option;
            _options.push(option);
        }

        // 2. 调用预言机获取价格
        // 2.1 获取token相对于eth的价格
        uint oraclePrice;
        {
            uint tokenAmount = 1 ether;
            uint fee = msg.value;
            if (tokenAddress != address(0)) {
                fee = msg.value >> 1;
                (
                    ,//uint blockNumber, 
                    tokenAmount,
                    ,
                    //uint sigmaSQ
                ) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPriceInfo {
                    value: fee
                } (
                    tokenAddress, 
                    msg.sender
                );
            }

            // 2.2 获取usdt相对于eth的价格
            (
                ,//uint blockNumber, 
                uint usdtAmount,
                ,
                //uint sigmaSQ
            ) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPriceInfo {
                value: fee
            } (
                USDT_TOKEN_ADDRESS, 
                msg.sender
            );

            // 将token价格转化为以usdt为单位计算的价格
            oraclePrice = usdtAmount * 10 ** (_getDecimals(tokenAddress)) / tokenAmount;
        }

        // 3. TODO: 计算权利金（需要的fort数量）
        // 按照平均每14秒出一个块计算
        // TODO: 确定时间间隔，是从block.number算起，还是从预言机价格所在区块算起
        uint T = (endblock - block.number) * 14;
        // TODO: 测试代码
        // TODO: 验证计算值，和C#代码比较
        // TODO: 重新分析数据取值范围
        //T = 1000 * 14;
        console.log("open-oraclePrice", oraclePrice);
        console.log("open-price", price);
        console.log("open-T", T);
        console.log("open-sigmaSQ", uint(config.sigmaSQ));
        {
            uint vc = _calcVc(config, oraclePrice, T, price);
            uint vp = _calcVp(config, oraclePrice, T, price);
            console.log("open-vc", vc);
            console.log("open-vp", vp);
        }

        uint v;
        // 看涨
        if (orientation) {
            // TODO: 注意价格是倒过来的
            v = _calcVc(config, oraclePrice, T, price);
            // Vc>=S0*1%; Vp>=K*1%
            require(v * 100 >= oraclePrice << 64, "FEO:vc must greater than S0*1%");
            //amount = (fortAmount << 64) * 1 ether / vc;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vc;
            //amount = (fortAmount << 64) * USDT_BASE / vc;
        }
        // 看跌
        else {
            // TODO: 注意价格是倒过来的
            v = _calcVp(config, oraclePrice, T, price);
            // Vc>=S0*1%; Vp>=K*1%
            require(v * 100 >= price << 64, "FEO:vp must greater than K*1%");
            //amount = (fortAmount << 64) * 1 ether / vp;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vp;
            //amount = (fortAmount << 64) * USDT_BASE / vp;
        }
        v = (fortAmount << 64) * USDT_BASE / v;
        require(v > 0.1 ether, "FEO:at least 0.1");

        // 4. 销毁权利金
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 5. 分发期权凭证
        FortOptionToken(option).mint(msg.sender, v);
    }

    /// @dev 预估开仓可以买到的期权币数量
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    /// @param oraclePrice 当前预言机价格价
    /// @return amount 预估可以获得的期权币数量
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external view override returns (uint amount) {

        Config memory config = _configs[tokenAddress];
        require(uint(config.minPeriod) > 0, "FEO:not allowed");
        
        require(fortAmount < 0x100000000000000000000000000000000, "FEO:fortAmount too large");
        require(endblock > block.number + uint(config.minPeriod), "FEO:endblock to small");

        // 1. 获取或创建期权代币
        price = _align(price);

        // 2. 调用预言机获取价格
        
        // 3. TODO: 计算权利金（需要的fort数量）
        // 按照平均每14秒出一个块计算
        // TODO: 确定时间间隔，是从block.number算起，还是从预言机价格所在区块算起
        uint T = (endblock - block.number) * 14;

        // 看涨
        if (orientation) {
            // TODO: 注意价格是倒过来的
            uint vc = _calcVc(config, oraclePrice, T, price);
            // Vc>=S0*1%; Vp>=K*1%
            require(vc * 100 >= oraclePrice << 64, "FEO:vc must greater than S0*1%");
            //amount = (fortAmount << 64) * 1 ether / vc;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vc;
            amount = (fortAmount << 64) * USDT_BASE / vc;
        }
        // 看跌
        else {
            // TODO: 注意价格是倒过来的
            uint vp = _calcVp(config, oraclePrice, T, price);
            // Vc>=S0*1%; Vp>=K*1%
            require(vp * 100 >= price << 64, "FEO:vp must greater than K*1%");
            //amount = (fortAmount << 64) * 1 ether / vp;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vp;
            amount = (fortAmount << 64) * USDT_BASE / vp;
        }
    }
    
    // 将18位十进制定点数转化为64位二级制定点数
    function _d18TOb64(uint v) private pure returns (int128) {
        //require(v < 0x1000000000000000000000000000000000000000000000000, "FEO:value can't ROL 64bits");
        require(v < 0x0DE0B6B3A764000000000000000000000000000000000000, "FEO:can't convert to 64bits");
        return int128(int((v << 64) / 1 ether));
    }

    // 将uint转化为int128
    function _toInt128(uint v) private pure returns (int128) {
        require(v < 0x100000000000000000000000000000000, "FEO:can't convert to int128");
        return int128(int(v));
    }

    // 将int128转化为uint
    function _toUInt(int128 v) private pure returns (uint) {
        require(v >= 0, "FEO:can't convert to uint");
        return uint(int(v));
    }

    // 计算看涨期权价格
    function _calcVc(Config memory config, uint S0, uint T, uint K) private pure returns (uint) {

        int128 sigmaSQ_T = _d18TOb64(uint(config.sigmaSQ) * T);
        int128 miu_T = _toInt128(uint(int(config.miu)) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = _toUInt(ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu_T), 
            ABDKMath64x64.sub(
                ONE,
                _snd(ABDKMath64x64.sub(d, sigma_t))
            )
        )) * S0;
        uint right = _toUInt(ABDKMath64x64.sub(ONE, _snd(d))) * K;

        return left - right;
    }

    // 计算看跌期权价格
    function _calcVp(Config memory config, uint S0, uint T, uint K) private pure returns (uint) {

        int128 sigmaSQ_T = _d18TOb64(uint(config.sigmaSQ) * T);
        int128 miu_T = _toInt128(uint(int(config.miu)) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = _toUInt(_snd(d)) * K;
        uint right = _toUInt(ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu_T), 
            _snd(ABDKMath64x64.sub(d, sigma_t))
        )) * S0;

        return left - right;
    }

    // 计算公式种的d1，因为没有除以σ，所以命名为D1
    function _D1(uint S0, uint K, int128 sigmaSQ_T, int128 miu_T) private pure returns (int128) {

        require(K < 0x1000000000000000000000000000000000000000000000000, "FEO:K can't ROL 64bits");
        return
            ABDKMath64x64.sub(
                ABDKMath64x64.add(
                    ABDKMath64x64.ln(_toInt128((K << 64) / S0)),
                    sigmaSQ_T >> 1
                ),
                miu_T
            );
    }

    // 通过查表的方法计算标准正态分布函数
    function _snd(int128 x) private pure returns (int128) {
        uint[28] memory table = [
            /* */ ///////////////////// STANDARD NORMAL TABLE //////////////////////////
            /* */ 0x174A15BF143412A8111C0F8F0E020C740AE6095807CA063B04AD031E018F0000, //
            ///// 0x2F8C2E0F2C912B1229922811268F250B23872202207D1EF61D6F1BE61A5D18D8, //
            /* */ 0x2F8C2E0F2C912B1229922811268F250B23872202207D1EF61D6F1BE61A5D18D4, //
            /* */ 0x46A2453C43D4426B41003F943E263CB63B4539D3385F36EA357333FB32823108, //
            /* */ 0x5C0D5AC5597B582F56E05590543E52EA5194503C4EE24D874C294ACA49694807, //
            /* */ 0x6F6C6E466D1F6BF56AC9699B686A6738660364CC6392625761195FD95E975D53, //
            /* */ 0x807E7F7F7E7D7D797C737B6A7A5F79517841772F761A750373E972CD71AF708E, //
            /* */ 0x8F2A8E518D768C998BB98AD789F2890B88218736864785568463836E8276817B, //
            /* */ 0x9B749AC19A0B9953989997DD971E965D959A94D4940C9342927591A690D49000, //
            /* */ 0xA57CA4ECA459A3C4A32EA295A1FAA15CA0BDA01C9F789ED29E2A9D809CD39C25, //
            ///// 0xA57CA4ECA459A3C4A32EA295A1FAA15DA0BDA01C9F789ED29E2A9D809CD39C25, //
            /* */ 0xAD78AD07AC93AC1EABA7AB2EAAB3AA36A9B8A937A8B5A830A7AAA721A697A60B, //
            /* */ 0xB3AAB353B2FAB2A0B245B1E7B189B128B0C6B062AFFDAF96AF2DAEC2AE56ADE8, //
            /* */ 0xB859B818B7D6B793B74EB708B6C0B678B62EB5E2B595B547B4F7B4A6B454B400, //
            /* */ 0xBBCDBB9EBB6EBB3CBB0ABAD7BAA2BA6DBA36B9FFB9C6B98CB951B915B8D8B899, //
            /* */ 0xBE49BE27BE05BDE2BDBEBD99BD74BD4DBD26BCFEBCD5BCACBC81BC56BC29BBFC, //
            /* */ 0xC006BFEEBFD7BFBEBFA5BF8CBF72BF57BF3CBF20BF03BEE6BEC8BEA9BE8ABE69, //
            /* */ 0xC135C126C116C105C0F4C0E3C0D1C0BFC0ACC099C086C072C05DC048C032C01C, //
            /* */ 0xC200C1F5C1EBC1E0C1D5C1C9C1BEC1B1C1A5C198C18BC17EC170C162C154C145, //
            /* */ 0xC283C27CC275C26EC267C260C258C250C248C240C238C22FC226C21DC213C20A, //
            /* */ 0xC2D6C2D2C2CDC2C9C2C5C2C0C2BBC2B6C2B1C2ACC2A7C2A1C29BC295C28FC289, //
            /* */ 0xC309C306C304C301C2FEC2FCC2F9C2F6C2F2C2EFC2ECC2E8C2E5C2E1C2DEC2DA, //
            /* */ 0xC328C326C325C323C321C320C31EC31CC31AC318C316C314C312C310C30EC30B, //
            /* */ 0xC33AC339C338C337C336C335C334C333C332C331C330C32EC32DC32CC32AC329, //
            /* */ 0xC344C343C343C342C342C341C341C340C33FC33FC33EC33DC33DC33CC33BC33A, //
            /* */ 0xC34AC349C349C349C348C348C348C348C347C347C346C346C346C345C345C344, //
            /* */ 0xC34DC34DC34CC34CC34CC34CC34CC34CC34BC34BC34BC34BC34BC34AC34AC34A, //
            /* */ 0xC34EC34EC34EC34EC34EC34EC34EC34EC34EC34EC34DC34DC34DC34DC34DC34D, //
            /* */ 0xC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34EC34E, //
            /* */ 0xC350C350C350C350C350C350C34FC34FC34FC34FC34FC34FC34FC34FC34FC34F  //
            /* */ //////////////////// MADE IN CHINA 2021-08-24 ////////////////////////
        ];

        //  uint[448] memory tableOld = [
        //  uint(0), 399, 798, 1197, 1595, 1994, 2392, 2790, 3188, 3586,
		//  3983, 4380, 4776, 5172, 5567, 5962, 6356, 6749, 7142, 7535,
		//  7926, 8317, 8706, 9095, 9483, 9871, 10257, 10642, 11026, 11409,
		//  11791, 12172, 12552, 12930, 13307, 13683, 14058, 14431, 14803, 15173,
		//  15542, 15910, 16276, 16640, 17003, 17364, 17724, 18082, 18439, 18793,
		//  19146, 19497, 19847, 20194, 20540, 20884, 21226, 21566, 21904, 22240,
		//  22575, 22907, 23237, 23565, 23891, 24215, 24537, 24857, 25175, 25490,
		//  25804, 26115, 26424, 26730, 27035, 27337, 27637, 27935, 28230, 28524,
		//  28814, 29103, 29389, 29673, 29955, 30234, 30511, 30785, 31057, 31327,
		//  31594, 31859, 32121, 32381, 32639, 32894, 33147, 33398, 33646, 33891,
		//  34134, 34375, 34614, 34849, 35083, 35314, 35543, 35769, 35993, 36214,
		//  36433, 36650, 36864, 37076, 37286, 37493, 37698, 37900, 38100, 38298,
		//  38493, 38686, 38877, 39065, 39251, 39435, 39617, 39796, 39973, 40147,
		//  40320, 40490, 40658, 40824, 40988, 41149, 41309, 41466, 41621, 41774,
		//  41924, 42073, 42220, 42364, 42507, 42647, 42785, 42922, 43056, 43189,
		//  43319, 43448, 43574, 43699, 43822, 43943, 44062, 44179, 44295, 44408,
		//  44520, 44630, 44738, 44845, 44950, 45053, 45154, 45254, 45352, 45449,
		//  45543, 45637, 45728, 45818, 45907, 45994, 46080, 46164, 46246, 46327,
		//  46407, 46485, 46562, 46638, 46712, 46784, 46856, 46926, 46995, 47062,
		//  47128, 47193, 47257, 47320, 47381, 47441, 47500, 47558, 47615, 47670,
		//  47725, 47778, 47831, 47882, 47932, 47982, 48030, 48077, 48124, 48169,
		//  48214, 48257, 48300, 48341, 48382, 48422, 48461, 48500, 48537, 48574,
		//  48610, 48645, 48679, 48713, 48745, 48778, 48809, 48840, 48870, 48899,
		//  48928, 48956, 48983, 49010, 49036, 49061, 49086, 49111, 49134, 49158,
		//  49180, 49202, 49224, 49245, 49266, 49286, 49305, 49324, 49343, 49361,
		//  49379, 49396, 49413, 49430, 49446, 49461, 49477, 49492, 49506, 49520,
		//  49534, 49547, 49560, 49573, 49585, 49598, 49609, 49621, 49632, 49643,
		//  49653, 49664, 49674, 49683, 49693, 49702, 49711, 49720, 49728, 49736,
		//  49744, 49752, 49760, 49767, 49774, 49781, 49788, 49795, 49801, 49807,
		//  49813, 49819, 49825, 49831, 49836, 49841, 49846, 49851, 49856, 49861,
		//  49865, 49869, 49874, 49878, 49882, 49886, 49889, 49893, 49896, 49900,
		//  49903, 49906, 49910, 49913, 49916, 49918, 49921, 49924, 49926, 49929,
		//  49931, 49934, 49936, 49938, 49940, 49942, 49944, 49946, 49948, 49950,
		//  49952, 49953, 49955, 49957, 49958, 49960, 49961, 49962, 49964, 49965,
		//  49966, 49968, 49969, 49970, 49971, 49972, 49973, 49974, 49975, 49976,
		//  49977, 49978, 49978, 49979, 49980, 49981, 49981, 49982, 49983, 49983,
		//  49984, 49985, 49985, 49986, 49986, 49987, 49987, 49988, 49988, 49989,
		//  49989, 49990, 49990, 49990, 49991, 49991, 49992, 49992, 49992, 49992,
		//  49993, 49993, 49993, 49994, 49994, 49994, 49994, 49995, 49995, 49995,
		//  49995, 49995, 49996, 49996, 49996, 49996, 49996, 49996, 49997, 49997,
		//  49997, 49997, 49997, 49997, 49997, 49997, 49998, 49998, 49998, 49998,
		//  49998, 49998, 49998, 49998, 49998, 49998, 49998, 49998, 49999, 49999,
		//  49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999,
		//  49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999,
		//  49999, 49999, 50000, 50000, 50000, 50000, 50000, 50000
        //  ];

        // for (uint i = 0; i < 448; ++i) {
        //     require(uint(tableOld[i]) == uint((table[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF), "FEO:not equal");
        // }

        uint ux = uint(int(x < 0 ? -x : x)) * 100;
        uint i = ux >> 64;
        uint v = V50000;

        if (i < 447) {
            v = uint((table[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF) << 64;
            v = (
                    (
                        (
                            (uint((table[(i + 1) >> 4] >> (((i + 1) & 0xF) << 4)) & 0xFFFF) << 64)
                            - v
                        ) * (ux - (i << 64))
                    ) >> 64
                ) + v;
        }

        if (x > 0) {
            v = V50000 + v;
        } else {
            v = V50000 - v;
        }

        return int128(int(v / 100000));
    }

    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable override {

        // 1. 获取期权信息
        (
            address tokenAddress, 
            uint price, 
            bool orientation, 
            uint endblock
        ) = FortOptionToken(optionAddress).getOptionInfo();

        // TODO: 测试期间不检查
        //require(block.number >= endblock, "FEO:at maturity");

        // 2. 销毁期权代币
        FortOptionToken(optionAddress).burn(msg.sender, amount);

        // 3. 调用预言机获取价格，读取预言机在指定区块的价格
        // 3.1 获取token相对于eth的价格
        uint tokenAmount = 1 ether;
        uint fee = msg.value;
        if (tokenAddress != address(0)) {
            fee = msg.value >> 1;
            (
                ,//uint blockNumber, 
                tokenAmount
            ) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).findPrice {
                value: fee
            } (
                tokenAddress, 
                endblock,
                msg.sender
            );
        }

        // 3.2 获取usdt相对于eth的价格
        (
            ,//uint blockNumber, 
            uint usdtAmount
        ) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).findPrice {
            value: fee
        } (
            USDT_TOKEN_ADDRESS, 
            endblock,
            msg.sender
        );

        // 将token价格转化为以usdt为单位计算的价格
        uint oraclePrice = usdtAmount * 10 ** (_getDecimals(tokenAddress)) / tokenAmount;
        // 4. 分情况计算用户可以获得的fort数量
        uint gain = 0;
        // 计算结算结果
        // 看涨期权
        if (orientation) {
            // 赌赢了
            if (oraclePrice > price) {
                gain = amount * (oraclePrice - price) / USDT_BASE;
            }
            // 赌输了
            // else {
            // }
        } 
        // 看跌期权
        else {
            // 赌赢了
            if (oraclePrice < price) {
                gain = amount * (price - oraclePrice) / USDT_BASE;
            }
            // 赌输了
            // else {
            // }
        }

        // 5. 用户赌赢了，给其增发赢得的fort
        if (gain > 0) {
            FortToken(FORT_TOKEN_ADDRESS).mint(msg.sender, gain);
        }
    }

    // TODO: 测试方法，需要删掉
    function log(string memory m, int v) private view {
        if (v < 0) {
            console.log(m, "-", uint(-v));
        } else {
            console.log(m, uint(v));
        }
    }
}