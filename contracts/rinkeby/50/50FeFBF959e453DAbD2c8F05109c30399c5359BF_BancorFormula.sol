pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IBancorFormula.sol";
import "./Power.sol";
import "../IExtension.sol";

/**
 * @title Bancor formula by Bancor
 * @dev Modified from the original by Slava Balasanov
 * https://github.com/bancorprotocol/contracts
 * Split Power.sol out from BancorFormula.sol and replace SafeMath formulas with zeppelin's SafeMath
 * Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements;
 * and to You under the Apache License, Version 2.0. "
 */
contract BancorFormula is 
    IBancorFormula,
    Power,
    IExtension 
{
  using SafeMath for uint256;

  uint32 private constant MAX_WEIGHT = 1000000;

  function initialize(DaoRegistry dao, address creator) external override {}
  /**
   * @dev given a token supply, connector balance, weight and a deposit amount (in the connector token),
   * calculates the return for a given conversion (in the main token)
   *
   * Formula:
   * Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
   *
   * @param _supply              token total supply
   * @param _connectorBalance    total connector balance
   * @param _connectorWeight     connector weight, represented in ppm, 1-1000000
   * @param _depositAmount       deposit amount, in connector token
   *
   *  @return purchase return amount
  */
  function calculatePurchaseReturn(
    uint256 _supply,
    uint256 _connectorBalance,
    uint32 _connectorWeight,
    uint256 _depositAmount) public view override returns (uint256)
  {
    // validate input
    require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

    // special case for 0 deposit amount
    if (_depositAmount == 0) {
      return 0;
    }

    // special case if the weight = 100%
    if (_connectorWeight == MAX_WEIGHT) {
      return _supply.mul(_depositAmount).div(_connectorBalance);
    }

    uint256 result;
    uint8 precision;
    uint256 baseN = _depositAmount.add(_connectorBalance);
    (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
    uint256 temp = _supply.mul(result) >> precision;
    
    return temp - _supply;
  }

  /**
   * @dev given a token supply, connector balance, weight and a sell amount (in the main token),
   * calculates the return for a given conversion (in the connector token)
   *
   * Formula:
   * Return = _connectorBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_connectorWeight / 1000000)))
   *
   * @param _supply              token total supply
   * @param _connectorBalance    total connector
   * @param _connectorWeight     constant connector Weight, represented in ppm, 1-1000000
   * @param _sellAmount          sell amount, in the token itself
   *
   * @return sale return amount
  */
  function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view override returns (uint256) {
    // validate input
    require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply);

    // special case for 0 sell amount
    if (_sellAmount == 0) {
      return 0;
    }

    // special case for selling the entire supply
    if (_sellAmount == _supply) {
      return _connectorBalance;
    }

    // special case if the weight = 100%
    if (_connectorWeight == MAX_WEIGHT) {
    
      return _connectorBalance.mul(_sellAmount).div(_supply);
    }

    uint256 result;
    uint8 precision;
    uint256 baseD = _supply - _sellAmount;
    (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
    uint256 oldBalance = _connectorBalance.mul(result);
    uint256 newBalance = _connectorBalance << precision;
    
    return oldBalance.sub(newBalance).div(result);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


/*
    Bancor Formula interface
*/
interface IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) external view returns (uint256);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


/**
 * bancor formula by bancor
 * https://github.com/bancorprotocol/contracts
 * Modified from the original by Slava Balasanov
 * Split Power.sol out from BancorFormula.sol
 * Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements;
 * and to You under the Apache License, Version 2.0. "
 */
contract Power {
  string public version = "0.3";

  uint256 private constant ONE = 1;
  uint32 private constant MAX_WEIGHT = 1000000;
  uint8 private constant MIN_PRECISION = 32;
  uint8 private constant MAX_PRECISION = 127;

  /*
    The values below depend on MAX_PRECISION. If you choose to change it:
    Apply the same change in file 'PrintIntScalingFactors.py', run it and paste the results below.
  */
  uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
  uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
  uint256 private constant MAX_NUM = 0x1ffffffffffffffffffffffffffffffff;

  /*
    The values below depend on MAX_PRECISION. If you choose to change it:
    Apply the same change in file 'PrintLn2ScalingFactors.py', run it and paste the results below.
  */
  uint256 private constant LN2_MANTISSA = 0x2c5c85fdf473de6af278ece600fcbda;
  uint8   private constant LN2_EXPONENT = 122;

  /*
    The values below depend on MIN_PRECISION and MAX_PRECISION. If you choose to change either one of them:
    Apply the same change in file 'PrintFunctionBancorFormula.py', run it and paste the results below.
  */
  uint256[128] private maxExpArray;

  constructor() {
//  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
//  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
//  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
//  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
//  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
//  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
//  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
//  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
//  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
//  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
//  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
//  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
//  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
//  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
//  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
//  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
//  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
//  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
//  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
//  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
//  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
//  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
//  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
//  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
//  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
//  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
//  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
//  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
//  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
//  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
//  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
//  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
    maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
    maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
    maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
    maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
    maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
    maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
    maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
    maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
    maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
    maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
    maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
    maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
    maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
    maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
    maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
    maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
    maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
    maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
    maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
    maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
    maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
    maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
    maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
    maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
    maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
    maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
    maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
    maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
    maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
    maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
    maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
    maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
    maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
    maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
    maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
    maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
    maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
    maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
    maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
    maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
    maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
    maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
    maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
    maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
    maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
    maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
    maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
    maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
    maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
    maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
    maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
    maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
    maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
    maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
    maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
    maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
    maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
    maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
    maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
    maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
    maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
    maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
    maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
    maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
    maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
    maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
    maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
    maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
    maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
    maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
    maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
    maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
    maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
    maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
    maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
    maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
    maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
    maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
    maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
    maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
    maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
    maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
    maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
    maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
    maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
    maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
    maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
    maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
    maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
    maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
    maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
    maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
    maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
    maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
    maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
    maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
  }


  /**
    General Description:
        Determine a value of precision.
        Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
        Return the result along with the precision used.

    Detailed Description:
        Instead of calculating "base ^ exp", we calculate "e ^ (ln(base) * exp)".
        The value of "ln(base)" is represented with an integer slightly smaller than "ln(base) * 2 ^ precision".
        The larger "precision" is, the more accurately this value represents the real value.
        However, the larger "precision" is, the more bits are required in order to store this value.
        And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
        This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
        Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
        This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
*/
  function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
    uint256 lnBaseTimesExp = ln(_baseN, _baseD) * _expN / _expD;
    uint8 precision = findPositionInMaxExpArray(lnBaseTimesExp);
    return (fixedExp(lnBaseTimesExp >> (MAX_PRECISION - precision), precision), precision);
  }

  /**
    Return floor(ln(numerator / denominator) * 2 ^ MAX_PRECISION), where:
    - The numerator   is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
    - The denominator is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
    - The output      is a value between 0 and floor(ln(2 ^ (256 - MAX_PRECISION) - 1) * 2 ^ MAX_PRECISION)
    This functions assumes that the numerator is larger than or equal to the denominator, because the output would be negative otherwise.
  */
  function ln(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
    assert(_numerator <= MAX_NUM);

    uint256 res = 0;
    uint256 x = _numerator * FIXED_1 / _denominator;

    // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
    if (x >= FIXED_2) {
      uint8 count = floorLog2(x / FIXED_1);
      x >>= count; // now x < 2
      res = count * FIXED_1;
    }

    // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
    if (x > FIXED_1) {
      for (uint8 i = MAX_PRECISION; i > 0; --i) {
        x = (x * x) / FIXED_1; // now 1 < x < 4
        if (x >= FIXED_2) {
          x >>= 1; // now 1 < x < 2
          res += ONE << (i - 1);
        }
      }
    }

    return (res * LN2_MANTISSA) >> LN2_EXPONENT;
  }

  /**
    Compute the largest integer smaller than or equal to the binary logarithm of the input.
  */
  function floorLog2(uint256 _n) internal pure returns (uint8) {
    uint8 res = 0;
    uint256 n = _n;

    if (n < 256) {
      // At most 8 iterations
      while (n > 1) {
        n >>= 1;
        res += 1;
      }
    } else {
      // Exactly 8 iterations
      for (uint8 s = 128; s > 0; s >>= 1) {
        if (n >= (ONE << s)) {
          n >>= s;
          res |= s;
        }
      }
    }

    return res;
  }

  /**
      The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
      - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
      - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
  */
  function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
    uint8 lo = MIN_PRECISION;
    uint8 hi = MAX_PRECISION;

    while (lo + 1 < hi) {
      uint8 mid = (lo + hi) / 2;
      if (maxExpArray[mid] >= _x)
        lo = mid;
      else
        hi = mid;
    }

    if (maxExpArray[hi] >= _x)
        return hi;
    if (maxExpArray[lo] >= _x)
        return lo;

    assert(false);
    return 0;
  }

  /**
      This function can be auto-generated by the script 'PrintFunctionFixedExp.py'.
      It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
      It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
      The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
      The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
  */
  function fixedExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
    uint256 xi = _x;
    uint256 res = 0;

    xi = (xi * _x) >> _precision;
    res += xi * 0x03442c4e6074a82f1797f72ac0000000; // add x^2 * (33! / 2!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0116b96f757c380fb287fd0e40000000; // add x^3 * (33! / 3!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0045ae5bdd5f0e03eca1ff4390000000; // add x^4 * (33! / 4!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000defabf91302cd95b9ffda50000000; // add x^5 * (33! / 5!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0002529ca9832b22439efff9b8000000; // add x^6 * (33! / 6!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000054f1cf12bd04e516b6da88000000; // add x^7 * (33! / 7!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000a9e39e257a09ca2d6db51000000; // add x^8 * (33! / 8!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000012e066e7b839fa050c309000000; // add x^9 * (33! / 9!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000052b6b54569976310000; // add x^17 * (33! / 17!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000004985f67696bf748000; // add x^18 * (33! / 18!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000001317c70077000; // add x^23 * (33! / 23!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000082573a0a00; // add x^25 * (33! / 25!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000005035ad900; // add x^26 * (33! / 26!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000000000002f881b00; // add x^27 * (33! / 27!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000001b29340; // add x^28 * (33! / 28!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000000000efc40; // add x^29 * (33! / 29!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000007fe0; // add x^30 * (33! / 30!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000420; // add x^31 * (33! / 31!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000021; // add x^32 * (33! / 32!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000001; // add x^33 * (33! / 33!)

    return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
  }
}

pragma solidity ^0.8.0;
import "../core/DaoRegistry.sol";

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

interface IExtension {
    function initialize(DaoRegistry dao, address creator) external;
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

import './DaoConstants.sol';
import '../guards/AdapterGuard.sol';
import '../guards/MemberGuard.sol';
import '../extensions/IExtension.sol';
import './interfaces/IDaoFactory.sol';
import './interfaces/IDaoRegistry.sol';
/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract DaoRegistry is MemberGuard, IDaoRegistry,  AdapterGuard {
    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern

    enum DaoState {
        CREATION,
        READY
    }
    /*
     * EVENTS
     */
    /// @dev - Events for Proposals
    event SubmittedProposal(bytes32 proposalId, uint256 flags);
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    event ProcessedProposal(bytes32 proposalId, uint256 flags);
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    event AdapterRemoved(bytes32 adapterId);

    event ExtensionAdded(bytes32 extensionId, address extensionAddress);
    event ExtensionRemoved(bytes32 extensionId);

    /// @dev - Events for Members
    event UpdateDelegateKey(address memberAddress, address newDelegateKey);
    event ConfigurationUpdated(bytes32 key, uint256 value);
    event AddressConfigurationUpdated(bytes32 key, address value);

    enum MemberFlag {
        EXISTS,
        VETOER,
        SERVICE_PROVIDER
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED,
        VETO
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        ADD_VETOER,
        REMOVE_VETOER,
        ADD_SERVICE_PROVIDER,
        REMOVE_SERVICE_PROVIDER,
        ADD_MOVEMENT
    }

    /*
     * STRUCTURES
     */
    struct Proposal {
        // the structure to track all the proposals in the DAO
        address adapterAddress; // the adapter address that called the functions to change the DAO state
        uint256 flags; // flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
    }

    struct Member {
        // the structure to track all the members in the DAO
        uint256 flags; // flags to track the state of the member: exists, etc
    }

    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    struct DelegateCheckpoint {
        // A checkpoint for marking the delegate key for a member from a given block
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
    }

    struct CreatedMovement {
        string name;
        address movement;
        string cid;
    }

    /*
     * PUBLIC VARIABLES
     */
    mapping(address => Member) public members; // the map to track all members of the DAO

    address[] private _members;

    // delegate key => member address mapping
    mapping(address => address) public memberAddressesByDelegatedKey;

    // memberAddress => checkpointNum => DelegateCheckpoint
    mapping(address => mapping(uint32 => DelegateCheckpoint)) checkpoints;
    // memberAddress => numDelegateCheckpoints
    mapping(address => uint32) numCheckpoints;

    DaoState public state;

    /// @notice The map that keeps track of all proposasls submitted to the DAO
    mapping(bytes32 => Proposal) public proposals;
    bytes32[] private _proposals;
    /// @notice The map that tracks the voting adapter address per proposalId
    mapping(bytes32 => address) public votingAdapter;
    /// @notice The map that keeps track of all adapters registered in the DAO
    mapping(bytes32 => address) public adapters;
    /// @notice The inverse map to get the adapter id based on its address
    mapping(address => AdapterEntry) public inverseAdapters;
    /// @notice The map that keeps track of all extensions registered in the DAO
    mapping(bytes32 => address) public extensions;

    mapping(bytes32 => address) public factories;

    /// @notice The inverse map to get the extension id based on its address
    mapping(address => ExtensionEntry) public inverseExtensions;
    /// @notice The map that keeps track of configuration parameters for the DAO and adapters
    mapping(bytes32 => uint256) public mainConfiguration;
    mapping(bytes32 => address) public addressConfiguration;

    /// @notice The map created movements
    mapping(bytes32 => CreatedMovement) public movements;

    uint256 public lockedAt;

    /// @notice Clonable contract must have an empty constructor
    // constructor() {
    // }

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    function initialize(address creator, address payer) external {
        require(!initialized, 'dao already initialized');
        potentialNewMember(msg.sender);
        potentialNewMember(payer);
        potentialNewMember(creator);

        initialized = true;
    }

    /**
     * @notice default fallback function to prevent from sending ether to the contract
     */
    receive() external payable {
        revert('you cannot send money back directly');
    }

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() external {
        state = DaoState.READY;
    }

    function lockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = block.number;
        }
    }

    function unlockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = 0;
        }
    }

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(bytes32 key, uint256 value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        mainConfiguration[key] = value;

        emit ConfigurationUpdated(key, value);
    }

    function potentialNewMember(address memberAddress)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        if (!getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
            require(
                memberAddressesByDelegatedKey[memberAddress] == address(0x0),
                'member address already taken as delegated key'
            );
            member.flags = setFlag(
                member.flags,
                uint8(MemberFlag.EXISTS),
                true
            );
            memberAddressesByDelegatedKey[memberAddress] = memberAddress;
            _members.push(memberAddress);
        }

        address bankAddress = extensions[BANK];
        if (bankAddress != address(0x0)) {
            BankExtension bank = BankExtension(bankAddress);
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) {
                bank.addToBalance(memberAddress, MEMBER_COUNT, 1);
            }
        }
    }

    // Vetoer
    function isVetoer(address addr) public view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.VETOER);
    }

    function addVetoer(address memberAddress)
        public
        hasAccess(this, AclFlag.ADD_VETOER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (!getFlag(member.flags, uint8(MemberFlag.VETOER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.VETOER),
                    true
                );
            }
        }
    }

    function removeVetoer(address memberAddress)
        public
        hasAccess(this, AclFlag.REMOVE_VETOER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (getFlag(member.flags, uint8(MemberFlag.VETOER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.VETOER),
                    false
                );
            }
        }
    }

    // ServiceProvider
    function isServiceProvider(address addr) public override view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.SERVICE_PROVIDER);
    }

    function addServiceProvider(address memberAddress)
        public
        hasAccess(this, AclFlag.ADD_SERVICE_PROVIDER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (!getFlag(member.flags, uint8(MemberFlag.SERVICE_PROVIDER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.SERVICE_PROVIDER),
                    true
                );
            }
        }
    }

    function removeServiceProvider(address memberAddress)
        public
        hasAccess(this, AclFlag.REMOVE_SERVICE_PROVIDER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];

        if (getFlag(member.flags, uint8(MemberFlag.SERVICE_PROVIDER))) {
            if (getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                member.flags = setFlag(
                    member.flags,
                    uint8(MemberFlag.SERVICE_PROVIDER),
                    false
                );
            }
        }
    }

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(bytes32 key, address value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        addressConfiguration[key] = value;

        emit AddressConfigurationUpdated(key, value);
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getConfiguration(bytes32 key) external view returns (uint256) {
        return mainConfiguration[key];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getAddressConfiguration(bytes32 key)
        external
        view
        returns (address)
    {
        return addressConfiguration[key];
    }

    function addFactory(bytes32 factoryId, address factrory) external {
        require(factoryId != bytes32(0), 'factory id must not be empty');
        require(
            factories[factoryId] == address(0x0),
            'factory Id already in use'
        );
        factories[factoryId] = factrory;
    }

    function getFactoryAddress(bytes32 factoryId)
        external
        view
        returns (address)
    {
        require(factories[factoryId] != address(0), 'factory not found');
        return factories[factoryId];
    }

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     * @param creator The DAO's creator, who will be an initial member
     */
    function addExtension(
        bytes32 extensionId,
        IExtension extension,
        address creator
    ) external override hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(extensionId != bytes32(0), 'extension id must not be empty');
        require(
            extensions[extensionId] == address(0x0),
            'extension Id already in use'
        );
        extensions[extensionId] = address(extension);
        inverseExtensions[address(extension)].id = extensionId;
        extension.initialize(this, creator);
        emit ExtensionAdded(extensionId, address(extension));
    }

    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    ) external hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(isAdapter(adapterAddress), 'not an adapter');
        require(isExtension(extensionAddress), 'not an extension');
        inverseExtensions[extensionAddress].acl[adapterAddress] = acl;
    }

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) external hasAccess(this, AclFlag.REPLACE_ADAPTER) {
        require(adapterId != bytes32(0), 'adapterId must not be empty');

        address currentAdapterAddr = adapters[adapterId];
        if (currentAdapterAddr != address(0x0)) {
            delete inverseAdapters[currentAdapterAddr];
            delete adapters[adapterId];
            emit AdapterRemoved(adapterId);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            uint256 value = values[i];
            mainConfiguration[key] = value;
            emit ConfigurationUpdated(key, value);
        }

        if (adapterAddress != address(0x0)) {
            require(
                inverseAdapters[adapterAddress].id == bytes32(0),
                'adapterAddress already in use'
            );
            adapters[adapterId] = adapterAddress;
            inverseAdapters[adapterAddress].id = adapterId;
            inverseAdapters[adapterAddress].acl = acl;
            emit AdapterAdded(adapterId, adapterAddress, acl);
        }
    }

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(bytes32 extensionId)
        external
        hasAccess(this, AclFlag.REMOVE_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extensionId must not be empty');
        require(
            extensions[extensionId] != address(0x0),
            'extensionId not registered'
        );
        delete inverseExtensions[extensions[extensionId]];
        delete extensions[extensionId];
        emit ExtensionRemoved(extensionId);
    }

    /**
     * @notice Looks up if there is an extension of a given address
     * @return Whether or not the address is an extension
     * @param extensionAddr The address to look up
     */
    function isExtension(address extensionAddr) public view returns (bool) {
        return inverseExtensions[extensionAddr].id != bytes32(0);
    }

    /**
     * @notice Looks up if there is an adapter of a given address
     * @return Whether or not the address is an adapter
     * @param adapterAddress The address to look up
     */
    function isAdapter(address adapterAddress) public view returns (bool) {
        return inverseAdapters[adapterAddress].id != bytes32(0);
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccess(address adapterAddress, AclFlag flag)
        public
        view
        returns (bool)
    {
        return getFlag(inverseAdapters[adapterAddress].acl, uint8(flag));
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) public view returns (bool) {
        return
            isAdapter(adapterAddress) &&
            getFlag(
                inverseExtensions[extensionAddress].acl[adapterAddress],
                uint8(flag)
            );
    }

    /**
     * @return The address of a given adapter ID
     * @param adapterId The ID to look up
     */
    function getAdapterAddress(bytes32 adapterId)
        external
        view
        returns (address)
    {
        require(adapters[adapterId] != address(0), 'adapter not found');
        return adapters[adapterId];
    }

    /**
     * @return The address of a given extension Id
     * @param extensionId The ID to look up
     */
    function getExtensionAddress(bytes32 extensionId)
        external
        view
        override
        returns (address)
    {
        require(extensions[extensionId] != address(0), 'extension not found');
        return extensions[extensionId];
    }

    /**
     * PROPOSALS
     */
    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(bytes32 proposalId)
        public
        hasAccess(this, AclFlag.SUBMIT_PROPOSAL)
    {
        require(proposalId != bytes32(0), 'invalid proposalId');
        require(
            !getProposalFlag(proposalId, ProposalFlag.EXISTS),
            'proposalId must be unique'
        );
        proposals[proposalId] = Proposal(msg.sender, 1); // 1 means that only the first flag is being set i.e. EXISTS
        emit SubmittedProposal(proposalId, 1);
    }

    function vetoProposal(bytes32 proposalId, address vetoer)
        external
        onlyVetoer(this, vetoer)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;

        require(
            msg.sender == vetoer,
            'only the vetoer that submitted the proposal can set its flag'
        );

        require(
            !getProposalFlag(proposalId, ProposalFlag.VETO),
            'proposal vetoed'
        );

        flags = setFlag(flags, uint8(ProposalFlag.VETO), true);

        proposals[proposalId].flags = flags;
    }

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) external onlyMember2(this, sponsoringMember) {
        // also checks if the flag was already set
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.SPONSORED
        );

        uint256 flags = proposal.flags;

        require(
            !getProposalFlag(proposalId, ProposalFlag.VETO),
            'proposal vetoed'
        );

        require(
            proposal.adapterAddress == msg.sender,
            'only the adapter that submitted the proposal can process it'
        );

        require(
            !getFlag(flags, uint8(ProposalFlag.PROCESSED)),
            'proposal already processed'
        );
        votingAdapter[proposalId] = votingAdapterAddr;
        emit SponsoredProposal(proposalId, flags, votingAdapterAddr);
    }

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(bytes32 proposalId) external {
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.PROCESSED
        );

        require(
            !getProposalFlag(proposalId, ProposalFlag.VETO),
            'proposal vetoed'
        );

        require(proposal.adapterAddress == msg.sender, 'err::adapter mismatch');
        uint256 flags = proposal.flags;

        emit ProcessedProposal(proposalId, flags);
    }

    /**
     * @notice Sets a flag of a proposal
     * @dev Reverts if the proposal is already processed
     * @param proposalId The ID of the proposal to be changed
     * @param flag The flag that will be set on the proposal
     */
    function _setProposalFlag(bytes32 proposalId, ProposalFlag flag)
        internal
        returns (Proposal storage)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;
        require(
            getFlag(flags, uint8(ProposalFlag.EXISTS)),
            'proposal does not exist for this dao'
        );

        require(
            proposal.adapterAddress == msg.sender,
            'only the adapter that submitted the proposal can set its flag'
        );

        require(!getFlag(flags, uint8(flag)), 'flag already set');

        flags = setFlag(flags, uint8(flag), true);
        proposals[proposalId].flags = flags;

        return proposals[proposalId];
    }

    /*
     * MEMBERS
     */

    /**
     * @return Whether or not a given address is a member of the DAO.
     * @dev it will resolve by delegate key, not member address.
     * @param addr The address to look up
     */
    function isMember(address addr) public view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.EXISTS);
    }

    /**
     * @return Whether or not a flag is set for a given proposal
     * @param proposalId The proposal to check against flag
     * @param flag The flag to check in the proposal
     */
    function getProposalFlag(bytes32 proposalId, ProposalFlag flag)
        public
        view
        returns (bool)
    {
        return getFlag(proposals[proposalId].flags, uint8(flag));
    }

    /**
     * @return Whether or not a flag is set for a given member
     * @param memberAddress The member to check against flag
     * @param flag The flag to check in the member
     */
    function getMemberFlag(address memberAddress, MemberFlag flag)
        public
        view
        returns (bool)
    {
        return getFlag(members[memberAddress].flags, uint8(flag));
    }

    function getNbMembers() public view returns (uint256) {
        return _members.length;
    }

    function getMemberAddress(uint256 index) public view returns (address) {
        return _members[index];
    }

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(address memberAddr, address newDelegateKey)
        external
        hasAccess(this, AclFlag.UPDATE_DELEGATE_KEY)
    {
        require(newDelegateKey != address(0x0), 'newDelegateKey cannot be 0');

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != memberAddr) {
            require(
                // newDelegate must not be delegated to
                memberAddressesByDelegatedKey[newDelegateKey] == address(0x0),
                'cannot overwrite existing delegated keys'
            );
        } else {
            require(
                memberAddressesByDelegatedKey[memberAddr] == address(0x0),
                'address already taken as delegated key'
            );
        }

        Member storage member = members[memberAddr];
        require(
            getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        // Reset the delegation of the previous delegate
        memberAddressesByDelegatedKey[
            getCurrentDelegateKey(memberAddr)
        ] = address(0x0);

        memberAddressesByDelegatedKey[newDelegateKey] = memberAddr;

        _createNewDelegateCheckpoint(memberAddr, newDelegateKey);
        emit UpdateDelegateKey(memberAddr, newDelegateKey);
    }

    /**
     * Public read-only functions
     */

    /**
     * @param checkAddr The address to check for a delegate
     * @return the delegated address or the checked address if it is not a delegate
     */
    function getAddressIfDelegated(address checkAddr)
        public
        view
        returns (address)
    {
        address delegatedKey = memberAddressesByDelegatedKey[checkAddr];
        return delegatedKey == address(0x0) ? checkAddr : delegatedKey;
    }

    /**
     * @param memberAddr The member whose delegate will be returned
     * @return the delegate key at the current time for a member
     */
    function getCurrentDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = numCheckpoints[memberAddr];
        return
            nCheckpoints > 0
                ? checkpoints[memberAddr][nCheckpoints - 1].delegateKey
                : memberAddr;
    }

    /**
     * @param memberAddr The member address to look up
     * @return The delegate key address for memberAddr at the second last checkpoint number
     */
    function getPreviousDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = numCheckpoints[memberAddr];
        return
            nCheckpoints > 1
                ? checkpoints[memberAddr][nCheckpoints - 2].delegateKey
                : memberAddr;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param memberAddr The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorDelegateKey(address memberAddr, uint256 blockNumber)
        external
        view
        returns (address)
    {
        require(
            blockNumber < block.number,
            'Uni::getPriorDelegateKey: not yet determined'
        );

        uint32 nCheckpoints = numCheckpoints[memberAddr];
        if (nCheckpoints == 0) {
            return memberAddr;
        }

        // First check most recent balance
        if (
            checkpoints[memberAddr][nCheckpoints - 1].fromBlock <= blockNumber
        ) {
            return checkpoints[memberAddr][nCheckpoints - 1].delegateKey;
        }

        // Next check implicit zero balance
        if (checkpoints[memberAddr][0].fromBlock > blockNumber) {
            return memberAddr;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DelegateCheckpoint memory cp = checkpoints[memberAddr][center];
            if (cp.fromBlock == blockNumber) {
                return cp.delegateKey;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[memberAddr][lower].delegateKey;
    }

    /**
     * @notice Creates a new delegate checkpoint of a certain member
     * @param member The member whose delegate checkpoints will be added to
     * @param newDelegateKey The delegate key that will be written into the new checkpoint
     */
    function _createNewDelegateCheckpoint(
        address member,
        address newDelegateKey
    ) internal {
        uint32 nCheckpoints = numCheckpoints[member];
        if (
            nCheckpoints > 0 &&
            checkpoints[member][nCheckpoints - 1].fromBlock == block.number
        ) {
            checkpoints[member][nCheckpoints - 1].delegateKey = newDelegateKey;
        } else {
            checkpoints[member][nCheckpoints] = DelegateCheckpoint(
                uint96(block.number),
                newDelegateKey
            );
            numCheckpoints[member] = nCheckpoints + 1;
        }
    }

    /**
     * Movements
     */

    function createMovement(
        bytes32 proposalId,
        Movememt calldata movement,
        string calldata name,
        address creator
    ) external hasAccess(this, AclFlag.ADD_MOVEMENT){
        IDaoFactory daoFactory = IDaoFactory(
            this.getFactoryAddress(DAO_FACTORY)
        );
        address daoAddr = daoFactory.createDao(name, creator);

        daoFactory.initializeClone(daoAddr, movement, creator);

        movements[proposalId] = CreatedMovement(
            name,
            daoAddr,
            movement.file
        );
        
        _proposals.push(proposalId);
    }

    function getMovement(bytes32 proposalId)
        public
        view
        returns (CreatedMovement memory)
    {
        return movements[proposalId];
    }

    function getMovements() public view returns (CreatedMovement[] memory m) {
        uint256 len = _proposals.length;
        m = new CreatedMovement[](len);

        for (uint256 i = 0; i < len; i++) {
            m[i] = movements[_proposals[i]];
        }
    }
}

/// Thegraph return active movement

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

abstract contract DaoConstants {
    // Adapters
    bytes32 internal constant VOTING = keccak256('voting');
    bytes32 internal constant ONBOARDING = keccak256('onboarding');
    bytes32 internal constant NONVOTING_ONBOARDING =
        keccak256('nonvoting-onboarding');
    bytes32 internal constant TRIBUTE = keccak256('tribute');
    bytes32 internal constant FINANCING = keccak256('financing');
    bytes32 internal constant MANAGING = keccak256('managing');
    bytes32 internal constant RAGEQUIT = keccak256('ragequit');
    bytes32 internal constant GUILDKICK = keccak256('guildkick');
    bytes32 internal constant CONFIGURATION = keccak256('configuration');
    bytes32 internal constant DISTRIBUTE = keccak256('distribute');
    bytes32 internal constant TRIBUTE_NFT = keccak256('tribute-nft');
    bytes32 internal constant ERC1155_ADAPT = keccak256('erc1155-adpt');
    bytes32 internal constant INTIATIVE_ADAPT = keccak256('intiative-adpt');

    // Extensions
    bytes32 internal constant BANK = keccak256('bank');
    bytes32 internal constant ENDOWMENT_BANK = keccak256('endowment-bank');
    bytes32 internal constant BANKOR_FORMULA = keccak256('bancor-formula');
    bytes32 internal constant BONDING_CURVE = keccak256('bonding-curve');
    bytes32 internal constant ERC1271 = keccak256('erc1271');
    bytes32 internal constant NFT = keccak256('nft');
    bytes32 internal constant ERC20_EXT = keccak256('erc20-ext');
    bytes32 internal constant EXECUTOR_EXT = keccak256('executor-ext');
    bytes32 internal constant ERC1155_EXT = keccak256('erc1155-ext');

    // Reserved Addresses
    address internal constant GUILD = address(0xdead);
    address internal constant ESCROW = address(0x4bec);
    address internal constant TOTAL = address(0xbabe);
    address internal constant UNITS = address(0xFF1CE);
    address internal constant LOCKED_UNITS = address(0xFFF1CE);
    address internal constant LOOT = address(0xB105F00D);
    address internal constant LOCKED_LOOT = address(0xBB105F00D);
    address internal constant ETH_TOKEN = address(0x0);
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    uint8 internal constant MAX_TOKENS_GUILD_BANK = 200;

    // Factory
    bytes32 internal constant DAO_FACTORY = keccak256('dao-factory');
    bytes32 internal constant BANK_FACTORY = keccak256('bank-factory');
    bytes32 internal constant ERC20_FACTORY = keccak256('erc20-factory');
    bytes32 internal constant BONDING_CURVE_FACTORY = keccak256('bonding-curve-factory');


    // Movement Structure
    struct Movememt {
        string tokenSymbol;
        string tokenName;
        bytes dataBondingCurve;
        uint256 votingPeriod;
        string file;
    }

    //helper
    function getFlag(uint256 flags, uint256 flag) public pure returns (bool) {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) public pure returns (uint256) {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(address addr) public pure returns (bool) {
        return addr != GUILD && addr != TOTAL && addr != ESCROW;
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(address addr) public pure returns (bool) {
        return addr != address(0x0);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../core/DaoRegistry.sol";
import "../extensions/IExtension.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract AdapterGuard {
    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(DaoRegistry dao) {
        require(
            (dao.state() == DaoRegistry.DaoState.CREATION &&
                creationModeCheck(dao)) || dao.isAdapter(msg.sender),
            "onlyAdapter"
        );
        _;
    }

    modifier reentrancyGuard(DaoRegistry dao) {
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        _;
        dao.unlockSession();
    }

    modifier executorFunc(DaoRegistry dao) {
        address executorAddr =
            dao.getExtensionAddress(keccak256("executor-ext"));
        require(address(this) == executorAddr, "only callable by the executor");
        _;
    }

    modifier hasAccess(DaoRegistry dao, DaoRegistry.AclFlag flag) {
        require(
            (dao.state() == DaoRegistry.DaoState.CREATION &&
                creationModeCheck(dao)) ||
                dao.hasAdapterAccess(msg.sender, flag),
            "accessDenied"
        );
        _;
    }

    function creationModeCheck(DaoRegistry dao) internal view returns (bool) {
        return
            dao.getNbMembers() == 0 ||
            dao.isMember(msg.sender) ||
            dao.isAdapter(msg.sender);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import '../core/DaoRegistry.sol';
import '../extensions/bank/Bank.sol';
import "../core/interfaces/IDaoRegistry.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
abstract contract MemberGuard is DaoConstants {
    /**
     * @dev Only members of the DAO are allowed to execute the function call.
     */
    modifier onlyMember(DaoRegistry dao) {
        _onlyMember(dao, msg.sender);
        _;
    }

    modifier onlyOwnerOrServiceProvider(
        address owner,
        DaoRegistry dao
    ) {
        require(owner == msg.sender || IDaoRegistry(dao.getMemberAddress(1)).isServiceProvider(msg.sender), "accessDenided");
        _;
    }

    modifier onlyVetoer(DaoRegistry dao, address _addr) {
        _onlyVetoer(dao, _addr);
        _;
    }

    modifier onlyServiceProvider(DaoRegistry dao, address _addr) {
        _onlyServiceProvider(dao, _addr);
        _;
    }

    modifier onlyMember2(DaoRegistry dao, address _addr) {
        _onlyMember(dao, _addr);
        _;
    }

    function _onlyMember(DaoRegistry dao, address _addr) internal view {
        require(isActiveMember(dao, _addr), 'onlyMember');
    }

    function _onlyVetoer(DaoRegistry dao, address _addr) internal view {
        require(dao.isVetoer(_addr), 'onlyVetoer');
    }

    function _onlyServiceProvider(DaoRegistry dao, address _addr)
        internal
        view
    {
        require(dao.isServiceProvider(_addr), 'onlyServiceProvider');
    }

    function isActiveMember(DaoRegistry dao, address _addr)
        public
        view
        returns (bool)
    {
        address bankAddress = dao.extensions(BANK);
        if (bankAddress != address(0x0)) {
            address memberAddr = dao.getAddressIfDelegated(_addr);
            return BankExtension(bankAddress).balanceOf(memberAddr, UNITS) > 0;
        }

        return dao.isMember(_addr);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
import '../DaoConstants.sol';

interface IDaoFactory {
    function createDao(string calldata daoName, address creator)
        external
        returns (address daoAddr);

    function initializeClone(
        address dao,
        DaoConstants.Movememt calldata movement,
        address creator
    ) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../extensions/IExtension.sol";

interface IDaoRegistry {
    function addExtension(
        bytes32 extensionId,
        IExtension extension,
        address creator
    ) external;

    function isServiceProvider(address addr) external returns (bool);
    
    function getExtensionAddress(bytes32 extensionId) external view returns (address);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../../core/DaoConstants.sol";
import "../../core/DaoRegistry.sol";
import "../IExtension.sol";
import "../interfaces/IBank.sol";
import "../../guards/AdapterGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
MIT License

Copyright (c) 2020 Openlaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

contract BankExtension is DaoConstants, AdapterGuard, IExtension, IBank {
    using Address for address payable;
    using SafeERC20 for IERC20;

    uint8 public maxExternalTokens; // the maximum number of external tokens that can be stored in the bank

    bool public initialized = false; // internally tracks deployment under eip-1167 proxy pattern
    DaoRegistry public dao;

    enum AclFlag {
        ADD_TO_BALANCE,
        SUB_FROM_BALANCE,
        INTERNAL_TRANSFER,
        WITHDRAW,
        REGISTER_NEW_TOKEN,
        REGISTER_NEW_INTERNAL_TOKEN,
        UPDATE_TOKEN
    }

    modifier noProposal {
        require(dao.lockedAt() < block.number, "proposal lock");
        _;
    }

    /// @dev - Events for Bank
    event NewBalance(address member, address tokenAddr, uint160 amount);

    event Withdraw(address account, address tokenAddr, uint160 amount);

    /*
     * STRUCTURES
     */

    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    address[] public tokens;
    address[] public internalTokens;
    // tokenAddress => availability
    mapping(address => bool) public availableTokens;
    mapping(address => bool) public availableInternalTokens;
    // tokenAddress => memberAddress => checkpointNum => Checkpoint
    mapping(address => mapping(address => mapping(uint32 => Checkpoint)))
        public checkpoints;
    // tokenAddress => memberAddress => numCheckpoints
    mapping(address => mapping(address => uint32)) public numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    modifier hasExtensionAccess(AclFlag flag) {
        require(
            address(this) == msg.sender ||
                address(dao) == msg.sender ||
                dao.state() == DaoRegistry.DaoState.CREATION ||
                dao.hasAdapterAccessToExtension(
                    msg.sender,
                    address(this),
                    uint8(flag)
                ),
            "bank::accessDenied"
        );
        _;
    }

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     */
    function initialize(DaoRegistry _dao, address creator) external override {
        require(!initialized, "bank already initialized");
        require(_dao.isMember(creator), "bank::not member");
        dao = _dao;
        initialized = true;

        availableInternalTokens[UNITS] = true;
        internalTokens.push(UNITS);

        availableInternalTokens[MEMBER_COUNT] = true;
        internalTokens.push(MEMBER_COUNT);
        uint256 nbMembers = _dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            addToBalance(_dao.getMemberAddress(i), MEMBER_COUNT, 1);
        }

        _createNewAmountCheckpoint(creator, UNITS, 1);
        _createNewAmountCheckpoint(TOTAL, UNITS, 1);
    }

    
    function withdrawTo(
        address payable member,
        address payable to,       
        address tokenAddr,
        uint256 amount
    ) public hasExtensionAccess(AclFlag.WITHDRAW) {
        require(
            balanceOf(member, tokenAddr) >= amount,
            "bank::withdraw::not enough funds"
        );
        subtractFromBalance(member, tokenAddr, amount);
        if (tokenAddr == ETH_TOKEN) {
            member.sendValue(amount);
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            erc20.safeTransfer(to, amount);
        }

        emit Withdraw(member, tokenAddr, uint160(amount));
    }

    function withdraw(
            address payable member,
            address tokenAddr,
            uint256 amount
        ) external {
            withdrawTo(member, member, tokenAddr, amount);
    }

    /**
     * @return Whether or not the given token is an available internal token in the bank
     * @param token The address of the token to look up
     */
    function isInternalToken(address token) external view returns (bool) {
        return availableInternalTokens[token];
    }

    /**
     * @return Whether or not the given token is an available token in the bank
     * @param token The address of the token to look up
     */
    function isTokenAllowed(address token) public view returns (bool) {
        return availableTokens[token];
    }

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(uint8 maxTokens) external {
        require(!initialized, "bank already initialized");
        require(
            maxTokens > 0 && maxTokens <= MAX_TOKENS_GUILD_BANK,
            "max number of external tokens should be (0,200)"
        );
        maxExternalTokens = maxTokens;
    }

    /*
     * BANK
     */

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(address token)
        external
        hasExtensionAccess(AclFlag.REGISTER_NEW_TOKEN)
    {
        require(isNotReservedAddress(token), "reservedToken");
        require(!availableInternalTokens[token], "internalToken");
        require(
            tokens.length <= maxExternalTokens,
            "exceeds the maximum tokens allowed"
        );

        if (!availableTokens[token]) {
            availableTokens[token] = true;
            tokens.push(token);
        }
    }

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(address token)
        external
        hasExtensionAccess(AclFlag.REGISTER_NEW_INTERNAL_TOKEN)
    {
        require(isNotReservedAddress(token), "reservedToken");
        require(!availableTokens[token], "availableToken");

        if (!availableInternalTokens[token]) {
            availableInternalTokens[token] = true;
            internalTokens.push(token);
        }
    }

    function updateToken(address tokenAddr)
        external
        hasExtensionAccess(AclFlag.UPDATE_TOKEN)
    {
        require(isTokenAllowed(tokenAddr), "token not allowed");
        uint256 totalBalance = balanceOf(TOTAL, tokenAddr);

        uint256 realBalance;

        if (tokenAddr == ETH_TOKEN) {
            realBalance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            realBalance = erc20.balanceOf(address(this));
        }

        if (totalBalance < realBalance) {
            addToBalance(GUILD, tokenAddr, realBalance - totalBalance);
        } else if (totalBalance > realBalance) {
            uint256 tokensToRemove = totalBalance - realBalance;
            uint256 guildBalance = balanceOf(GUILD, tokenAddr);
            if (guildBalance > tokensToRemove) {
                subtractFromBalance(GUILD, tokenAddr, tokensToRemove);
            } else {
                subtractFromBalance(GUILD, tokenAddr, guildBalance);
            }
        }
    }

    /**
     * Public read-only functions
     */

    /**
     * Internal bookkeeping
     */

    /**
     * @return The token from the bank of a given index
     * @param index The index to look up in the bank's tokens
     */
    function getToken(uint256 index) external view returns (address) {
        return tokens[index];
    }

    /**
     * @return The amount of token addresses in the bank
     */
    function nbTokens() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @return All the tokens registered in the bank.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @return The internal token at a given index
     * @param index The index to look up in the bank's array of internal tokens
     */
    function getInternalToken(uint256 index) external view returns (address) {
        return internalTokens[index];
    }

    /**
     * @return The amount of internal token addresses in the bank
     */
    function nbInternalTokens() external view returns (uint256) {
        return internalTokens.length;
    }

    /**
     * @notice Adds to a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function addToBalance(
        address member,
        address token,
        uint256 amount
    ) public override payable hasExtensionAccess(AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            "unknown token address"
        );
        uint256 newAmount = balanceOf(member, token) + amount;
        uint256 newTotalAmount = balanceOf(TOTAL, token) + amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(TOTAL, token, newTotalAmount);
    }

    /**
     * @notice Remove from a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function subtractFromBalance(
        address member,
        address token,
        uint256 amount
    ) public hasExtensionAccess(AclFlag.SUB_FROM_BALANCE) {
        uint256 newAmount = balanceOf(member, token) - amount;
        uint256 newTotalAmount = balanceOf(TOTAL, token) - amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(TOTAL, token, newTotalAmount);
    }

    /**
     * @notice Make an internal token transfer
     * @param from The member who is sending tokens
     * @param to The member who is receiving tokens
     * @param amount The new amount to transfer
     */
    function internalTransfer(
        address from,
        address to,
        address token,
        uint256 amount
    ) public hasExtensionAccess(AclFlag.INTERNAL_TRANSFER) {
        uint256 newAmount = balanceOf(from, token) - amount;
        uint256 newAmount2 = balanceOf(to, token) + amount;

        _createNewAmountCheckpoint(from, token, newAmount);
        _createNewAmountCheckpoint(to, token, newAmount2);
    }

    /**
     * @notice Returns an member's balance of a given token
     * @param member The address to look up
     * @param tokenAddr The token where the member's balance of which will be returned
     * @return The amount in account's tokenAddr balance
     */
    function balanceOf(address member, address tokenAddr)
        public
        view
        returns (uint160)
    {
        uint32 nCheckpoints = numCheckpoints[tokenAddr][member];
        return
            nCheckpoints > 0
                ? checkpoints[tokenAddr][member][nCheckpoints - 1].amount
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) external view returns (uint256) {
        require(
            blockNumber < block.number,
            "Uni::getPriorAmount: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[tokenAddr][account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (
            checkpoints[tokenAddr][account][nCheckpoints - 1].fromBlock <=
            blockNumber
        ) {
            return checkpoints[tokenAddr][account][nCheckpoints - 1].amount;
        }

        // Next check implicit zero balance
        if (checkpoints[tokenAddr][account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenAddr][account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.amount;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[tokenAddr][account][lower].amount;
    }

    /**
     * @notice Creates a new amount checkpoint for a token of a certain member
     * @dev Reverts if the amount is greater than 2**64-1
     * @param member The member whose checkpoints will be added to
     * @param token The token of which the balance will be changed
     * @param amount The amount to be written into the new checkpoint
     */
    function _createNewAmountCheckpoint(
        address member,
        address token,
        uint256 amount
    ) internal {
        bool isValidToken = false;
        if (availableInternalTokens[token]) {
            require(
                amount < type(uint88).max,
                "token amount exceeds the maximum limit for internal tokens"
            );
            isValidToken = true;
        } else if (availableTokens[token]) {
            require(
                amount < type(uint160).max,
                "token amount exceeds the maximum limit for external tokens"
            );
            isValidToken = true;
        }
        uint160 newAmount = uint160(amount);

        require(isValidToken, "token not registered");

        uint32 nCheckpoints = numCheckpoints[token][member];
        if (
            nCheckpoints > 0 &&
            checkpoints[token][member][nCheckpoints - 1].fromBlock ==
            block.number
        ) {
            checkpoints[token][member][nCheckpoints - 1].amount = newAmount;
        } else {
            checkpoints[token][member][nCheckpoints] = Checkpoint(
                uint96(block.number),
                newAmount
            );
            numCheckpoints[token][member] = nCheckpoints + 1;
        }
        emit NewBalance(member, token, newAmount);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


interface IBank {
    function addToBalance(address member, address token, uint256 amount) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}