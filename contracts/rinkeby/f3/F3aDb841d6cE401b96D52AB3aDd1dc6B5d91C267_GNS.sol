// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract BancorFormula {
    using SafeMath for uint256;

    uint16 public constant version = 6;

    uint256 private constant ONE = 1;
    uint32 private constant MAX_RATIO = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
     * @dev Auto-generated via 'PrintIntScalingFactors.py'
     */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
     * @dev Auto-generated via 'PrintLn2ScalingFactors.py'
     */
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
     * @dev Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
     */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
     * @dev Auto-generated via 'PrintFunctionConstructor.py'
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
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
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
     * @dev given a token supply, reserve balance, ratio and a deposit amount (in the reserve token),
     * calculates the return for a given conversion (in the main token)
     *
     * Formula:
     * Return = _supply * ((1 + _depositAmount / _reserveBalance) ^ (_reserveRatio / 1000000) - 1)
     *
     * @param _supply              token total supply
     * @param _reserveBalance      total reserve balance
     * @param _reserveRatio        reserve ratio, represented in ppm, 1-1000000
     * @param _depositAmount       deposit amount, in reserve token
     *
     * @return purchase return amount
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _depositAmount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RATIO,
            "invalid parameters"
        );

        // special case for 0 deposit amount
        if (_depositAmount == 0) return 0;

        // special case if the ratio = 100%
        if (_reserveRatio == MAX_RATIO) return _supply.mul(_depositAmount) / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount.add(_reserveBalance);
        (result, precision) = power(baseN, _reserveBalance, _reserveRatio, MAX_RATIO);
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a token supply, reserve balance, ratio and a sell amount (in the main token),
     * calculates the return for a given conversion (in the reserve token)
     *
     * Formula:
     * Return = _reserveBalance * (1 - (1 - _sellAmount / _supply) ^ (1000000 / _reserveRatio))
     *
     * @param _supply              token total supply
     * @param _reserveBalance      total reserve
     * @param _reserveRatio        constant reserve Ratio, represented in ppm, 1-1000000
     * @param _sellAmount          sell amount, in the token itself
     *
     * @return sale return amount
     */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _sellAmount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _reserveRatio > 0 &&
                _reserveRatio <= MAX_RATIO &&
                _sellAmount <= _supply,
            "invalid parameters"
        );

        // special case for 0 sell amount
        if (_sellAmount == 0) return 0;

        // special case for selling the entire supply
        if (_sellAmount == _supply) return _reserveBalance;

        // special case if the ratio = 100%
        if (_reserveRatio == MAX_RATIO) return _reserveBalance.mul(_sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_RATIO, _reserveRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given two reserve balances/ratios and a sell amount (in the first reserve token),
     * calculates the return for a conversion from the first reserve token to the second reserve token (in the second reserve token)
     * note that prior to version 4, you should use 'calculateCrossConnectorReturn' instead
     *
     * Formula:
     * Return = _toReserveBalance * (1 - (_fromReserveBalance / (_fromReserveBalance + _amount)) ^ (_fromReserveRatio / _toReserveRatio))
     *
     * @param _fromReserveBalance      input reserve balance
     * @param _fromReserveRatio        input reserve ratio, represented in ppm, 1-1000000
     * @param _toReserveBalance        output reserve balance
     * @param _toReserveRatio          output reserve ratio, represented in ppm, 1-1000000
     * @param _amount                  input reserve amount
     *
     * @return second reserve amount
     */
    function calculateCrossReserveReturn(
        uint256 _fromReserveBalance,
        uint32 _fromReserveRatio,
        uint256 _toReserveBalance,
        uint32 _toReserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _fromReserveBalance > 0 &&
                _fromReserveRatio > 0 &&
                _fromReserveRatio <= MAX_RATIO &&
                _toReserveBalance > 0 &&
                _toReserveRatio > 0 &&
                _toReserveRatio <= MAX_RATIO
        );

        // special case for equal ratios
        if (_fromReserveRatio == _toReserveRatio)
            return _toReserveBalance.mul(_amount) / _fromReserveBalance.add(_amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = _fromReserveBalance.add(_amount);
        (result, precision) = power(baseN, _fromReserveBalance, _fromReserveRatio, _toReserveRatio);
        uint256 temp1 = _toReserveBalance.mul(result);
        uint256 temp2 = _toReserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given a smart token supply, reserve balance, total ratio and an amount of requested smart tokens,
     * calculates the amount of reserve tokens required for purchasing the given amount of smart tokens
     *
     * Formula:
     * Return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_RATIO / _totalRatio) - 1)
     *
     * @param _supply              smart token supply
     * @param _reserveBalance      reserve token balance
     * @param _totalRatio          total ratio, represented in ppm, 2-2000000
     * @param _amount              requested amount of smart tokens
     *
     * @return amount of reserve tokens
     */
    function calculateFundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _totalRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 && _reserveBalance > 0 && _totalRatio > 1 && _totalRatio <= MAX_RATIO * 2
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the total ratio = 100%
        if (_totalRatio == MAX_RATIO) return (_amount.mul(_reserveBalance) - 1) / _supply + 1;

        uint256 result;
        uint8 precision;
        uint256 baseN = _supply.add(_amount);
        (result, precision) = power(baseN, _supply, MAX_RATIO, _totalRatio);
        uint256 temp = ((_reserveBalance.mul(result) - 1) >> precision) + 1;
        return temp - _reserveBalance;
    }

    /**
     * @dev given a smart token supply, reserve balance, total ratio and an amount of smart tokens to liquidate,
     * calculates the amount of reserve tokens received for selling the given amount of smart tokens
     *
     * Formula:
     * Return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_RATIO / _totalRatio))
     *
     * @param _supply              smart token supply
     * @param _reserveBalance      reserve token balance
     * @param _totalRatio          total ratio, represented in ppm, 2-2000000
     * @param _amount              amount of smart tokens to liquidate
     *
     * @return amount of reserve tokens
     */
    function calculateLiquidateReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _totalRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _totalRatio > 1 &&
                _totalRatio <= MAX_RATIO * 2 &&
                _amount <= _supply
        );

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case for liquidating the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the total ratio = 100%
        if (_totalRatio == MAX_RATIO) return _amount.mul(_reserveBalance) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_RATIO, _totalRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev General Description:
     *     Determine a value of precision.
     *     Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
     *     Return the result along with the precision used.
     *
     * Detailed Description:
     *     Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
     *     The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
     *     The larger "precision" is, the more accurately this value represents the real value.
     *     However, the larger "precision" is, the more bits are required in order to store this value.
     *     And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
     *     This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     *     Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     *     This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     *     This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
     *     Since we rely on unsigned-integer arithmetic and "base < 1" ==> "log(base) < 0", this function does not support "_baseN < _baseD".
     */
    function power(
        uint256 _baseN,
        uint256 _baseD,
        uint32 _expN,
        uint32 _expD
    ) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = (_baseN * FIXED_1) / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = (baseLog * _expN) / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (
                generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision),
                precision
            );
        }
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1.
     * This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

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

        return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
    }

    /**
     * @dev computes the largest integer smaller than or equal to the binary logarithm of the input.
     */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
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
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
     * @dev the global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x) lo = mid;
            else hi = mid;
        }

        if (maxExpArray[hi] >= _x) return hi;
        if (maxExpArray[lo] >= _x) return lo;

        require(false);
        return 0;
    }

    /**
     * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1
     * Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalLog.py'
     * Detailed description:
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        res +=
            (z * (0x100000000000000000000000000000000 - y)) /
            0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        res +=
            (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) /
            0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        res +=
            (z * (0x099999999999999999999999999999999 - y)) /
            0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        res +=
            (z * (0x092492492492492492492492492492492 - y)) /
            0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        res +=
            (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) /
            0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        res +=
            (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) /
            0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        res +=
            (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) /
            0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        res +=
            (z * (0x088888888888888888888888888888888 - y)) /
            0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
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
    function optimalExp(uint256 x) internal pure returns (uint256) {
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

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateCrossConnectorReturn(
        uint256 _fromConnectorBalance,
        uint32 _fromConnectorWeight,
        uint256 _toConnectorBalance,
        uint32 _toConnectorWeight,
        uint256 _amount
    ) public view returns (uint256) {
        return
            calculateCrossReserveReturn(
                _fromConnectorBalance,
                _fromConnectorWeight,
                _toConnectorBalance,
                _toConnectorWeight,
                _amount
            );
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../bancor/BancorFormula.sol";
import "../upgrades/GraphUpgradeable.sol";

import "./IGNS.sol";
import "./GNSStorage.sol";

/**
 * @title GNS
 * @dev The Graph Name System contract provides a decentralized naming system for subgraphs
 * used in the scope of the Graph Network. It translates subgraph names into subgraph versions.
 * Each version is associated with a Subgraph Deployment. The contract has no knowledge of
 * human-readable names. All human readable names emitted in events.
 */
contract GNS is GNSV1Storage, GraphUpgradeable, IGNS {
    using SafeMath for uint256;

    uint256 private constant MAX_UINT256 = 2**256 - 1;

    // 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    // Equates to Connector weight on bancor formula to be CW = 1
    uint32 private constant defaultReserveRatio = 1000000;

    // -- Events --

    /**
     * @dev Emitted when graph account sets its default name
     */
    event SetDefaultName(
        address indexed graphAccount,
        uint256 nameSystem, // only ENS for now
        bytes32 nameIdentifier,
        string name
    );

    /**
     * @dev Emitted when graph account sets a subgraphs metadata on IPFS
     */
    event SubgraphMetadataUpdated(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        bytes32 subgraphMetadata
    );

    /**
     * @dev Emitted when a `graph account` publishes a `subgraph` with a `version`.
     * Every time this event is emitted, indicates a new version has been created.
     * The event also emits a `metadataHash` with subgraph details and version details.
     */
    event SubgraphPublished(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        bytes32 indexed subgraphDeploymentID,
        bytes32 versionMetadata
    );

    /**
     * @dev Emitted when a graph account deprecated one of its subgraphs
     */
    event SubgraphDeprecated(address indexed graphAccount, uint256 indexed subgraphNumber);

    /**
     * @dev Emitted when a graphAccount creates an nSignal bonding curve that
     * points to a subgraph deployment
     */
    event NameSignalEnabled(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        bytes32 indexed subgraphDeploymentID,
        uint32 reserveRatio
    );

    /**
     * @dev Emitted when a name curator deposits its vSignal into an nSignal curve to mint nSignal
     */
    event NSignalMinted(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        address indexed nameCurator,
        uint256 nSignalCreated,
        uint256 vSignalCreated,
        uint256 tokensDeposited
    );

    /**
     * @dev Emitted when a name curator burns its nSignal, which in turn burns
     * the vSignal, and receives GRT
     */
    event NSignalBurned(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        address indexed nameCurator,
        uint256 nSignalBurnt,
        uint256 vSignalBurnt,
        uint256 tokensReceived
    );

    /**
     * @dev Emitted when a graph account upgrades its nSignal curve to point to a new
     * subgraph deployment, burning all the old vSignal and depositing the GRT into the
     * new vSignal curve, creating new nSignal
     */
    event NameSignalUpgrade(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        uint256 newVSignalCreated,
        uint256 tokensSignalled,
        bytes32 indexed subgraphDeploymentID
    );

    /**
     * @dev Emitted when an nSignal curve has been permanently disabled
     */
    event NameSignalDisabled(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        uint256 withdrawableGRT
    );

    /**
     * @dev Emitted when a nameCurator withdraws its GRT from a deprecated name signal pool
     */
    event GRTWithdrawn(
        address indexed graphAccount,
        uint256 indexed subgraphNumber,
        address indexed nameCurator,
        uint256 nSignalBurnt,
        uint256 withdrawnGRT
    );

    /**
    @dev Modifier that allows a function to be called by owner of a graph account
    @param _graphAccount Address of the graph account
    */
    modifier onlyGraphAccountOwner(address _graphAccount) {
        address graphAccountOwner = erc1056Registry.identityOwner(_graphAccount);
        require(graphAccountOwner == msg.sender, "GNS: Only graph account owner can call");
        _;
    }

    /**
     * @dev Initialize this contract.
     */
    function initialize(
        address _controller,
        address _bondingCurve,
        address _didRegistry
    ) external onlyImpl {
        Managed._initialize(_controller);

        bondingCurve = _bondingCurve;
        erc1056Registry = IEthereumDIDRegistry(_didRegistry);

        // Settings
        _setOwnerTaxPercentage(500000);
    }

    /**
     * @dev Approve curation contract to pull funds.
     */
    function approveAll() external override {
        graphToken().approve(address(curation()), MAX_UINT256);
    }

    /**
     * @dev Set the owner fee percentage. This is used to prevent a subgraph owner to drain all
     * the name curators tokens while upgrading or deprecating and is configurable in parts per hundred.
     * @param _ownerTaxPercentage Owner tax percentage
     */
    function setOwnerTaxPercentage(uint32 _ownerTaxPercentage) external override onlyGovernor {
        _setOwnerTaxPercentage(_ownerTaxPercentage);
    }

    /**
     * @dev Internal: Set the owner tax percentage. This is used to prevent a subgraph owner to drain all
     * the name curators tokens while upgrading or deprecating and is configurable in parts per hundred.
     * @param _ownerTaxPercentage Owner tax percentage
     */
    function _setOwnerTaxPercentage(uint32 _ownerTaxPercentage) private {
        require(_ownerTaxPercentage <= MAX_PPM, "Owner tax must be MAX_PPM or less");
        ownerTaxPercentage = _ownerTaxPercentage;
        emit ParameterUpdated("ownerTaxPercentage");
    }

    /**
     * @dev Allows a graph account to set a default name
     * @param _graphAccount Account that is setting its name
     * @param _nameSystem Name system account already has ownership of a name in
     * @param _nameIdentifier The unique identifier that is used to identify the name in the system
     * @param _name The name being set as default
     */
    function setDefaultName(
        address _graphAccount,
        uint8 _nameSystem,
        bytes32 _nameIdentifier,
        string calldata _name
    ) external override onlyGraphAccountOwner(_graphAccount) {
        emit SetDefaultName(_graphAccount, _nameSystem, _nameIdentifier, _name);
    }

    /**
     * @dev Allows a graph account update the metadata of a subgraph they have published
     * @param _graphAccount Account that owns the subgraph
     * @param _subgraphNumber Subgraph number
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function updateSubgraphMetadata(
        address _graphAccount,
        uint256 _subgraphNumber,
        bytes32 _subgraphMetadata
    ) public override onlyGraphAccountOwner(_graphAccount) {
        emit SubgraphMetadataUpdated(_graphAccount, _subgraphNumber, _subgraphMetadata);
    }

    /**
     * @dev Allows a graph account to publish a new subgraph, which means a new subgraph number
     * will be used.
     * @param _graphAccount Account that is publishing the subgraph
     * @param _subgraphDeploymentID Subgraph deployment ID of the version, linked to the name
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function publishNewSubgraph(
        address _graphAccount,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata,
        bytes32 _subgraphMetadata
    ) external override notPaused onlyGraphAccountOwner(_graphAccount) {
        uint256 subgraphNumber = graphAccountSubgraphNumbers[_graphAccount];
        _publishVersion(_graphAccount, subgraphNumber, _subgraphDeploymentID, _versionMetadata);
        graphAccountSubgraphNumbers[_graphAccount] = graphAccountSubgraphNumbers[_graphAccount].add(
            1
        );
        updateSubgraphMetadata(_graphAccount, subgraphNumber, _subgraphMetadata);
        _enableNameSignal(_graphAccount, subgraphNumber);
    }

    /**
     * @dev Allows a graph account to publish a new version of its subgraph.
     * Version is derived from the occurrence of SubgraphPublished being emitted.
     * The first time SubgraphPublished is called would be Version 0
     * @param _graphAccount Account that is publishing the subgraph
     * @param _subgraphNumber Subgraph number for the account
     * @param _subgraphDeploymentID Subgraph deployment ID of the version, linked to the name
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     */
    function publishNewVersion(
        address _graphAccount,
        uint256 _subgraphNumber,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) external override notPaused onlyGraphAccountOwner(_graphAccount) {
        require(
            isPublished(_graphAccount, _subgraphNumber),
            "GNS: Cannot update version if not published, or has been deprecated"
        );
        bytes32 oldSubgraphDeploymentID = subgraphs[_graphAccount][_subgraphNumber];
        require(
            _subgraphDeploymentID != oldSubgraphDeploymentID,
            "GNS: Cannot publish a new version with the same subgraph deployment ID"
        );

        _publishVersion(_graphAccount, _subgraphNumber, _subgraphDeploymentID, _versionMetadata);
        _upgradeNameSignal(_graphAccount, _subgraphNumber, _subgraphDeploymentID);
    }

    /**
     * @dev Private function used by both external publishing functions
     * @param _graphAccount Account that is publishing the subgraph
     * @param _subgraphNumber Subgraph number for the account
     * @param _subgraphDeploymentID Subgraph deployment ID of the version, linked to the name
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     */
    function _publishVersion(
        address _graphAccount,
        uint256 _subgraphNumber,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) private {
        require(_subgraphDeploymentID != 0, "GNS: Cannot set deploymentID to 0 in publish");

        // Stores a subgraph deployment ID, which indicates a version has been created
        subgraphs[_graphAccount][_subgraphNumber] = _subgraphDeploymentID;

        // Emit version and name data
        emit SubgraphPublished(
            _graphAccount,
            _subgraphNumber,
            _subgraphDeploymentID,
            _versionMetadata
        );
    }

    /**
     * @dev Deprecate a subgraph. Can only be done by the graph account owner.
     * @param _graphAccount Account that is deprecating the subgraph
     * @param _subgraphNumber Subgraph number for the account
     */
    function deprecateSubgraph(address _graphAccount, uint256 _subgraphNumber)
        external
        override
        notPaused
        onlyGraphAccountOwner(_graphAccount)
    {
        require(
            isPublished(_graphAccount, _subgraphNumber),
            "GNS: Cannot deprecate a subgraph which does not exist"
        );

        delete subgraphs[_graphAccount][_subgraphNumber];
        emit SubgraphDeprecated(_graphAccount, _subgraphNumber);

        _disableNameSignal(_graphAccount, _subgraphNumber);
    }

    /**
     * @dev Enable name signal on a graph accounts numbered subgraph, which points to a subgraph
     * deployment
     * @param _graphAccount Graph account enabling name signal
     * @param _subgraphNumber Subgraph number being used
     */
    function _enableNameSignal(address _graphAccount, uint256 _subgraphNumber) private {
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        namePool.subgraphDeploymentID = subgraphs[_graphAccount][_subgraphNumber];
        namePool.reserveRatio = defaultReserveRatio;

        emit NameSignalEnabled(
            _graphAccount,
            _subgraphNumber,
            namePool.subgraphDeploymentID,
            namePool.reserveRatio
        );
    }

    /**
     * @dev Update a name signal on a graph accounts numbered subgraph
     * @param _graphAccount Graph account updating name signal
     * @param _subgraphNumber Subgraph number being used
     * @param _newSubgraphDeploymentID Deployment ID being upgraded to
     */
    function _upgradeNameSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        bytes32 _newSubgraphDeploymentID
    ) private {
        // This is to prevent the owner from front running its name curators signal by posting
        // its own signal ahead, bringing the name curators in, and dumping on them
        ICuration curation = curation();
        require(
            !curation.isCurated(_newSubgraphDeploymentID),
            "GNS: Owner cannot point to a subgraphID that has been pre-curated"
        );

        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        require(
            namePool.nSignal > 0,
            "GNS: There must be nSignal on this subgraph for curve math to work"
        );
        require(namePool.disabled == false, "GNS: Cannot be disabled");

        // Burn all version signal in the name pool for tokens
        uint256 tokens = curation.burn(namePool.subgraphDeploymentID, namePool.vSignal, 0);

        // Take the owner cut of the curation tax, add it to the total
        uint32 curationTaxPercentage = curation.curationTaxPercentage();
        uint256 tokensWithTax = _chargeOwnerTax(tokens, _graphAccount, curationTaxPercentage);

        // Update pool: constant nSignal, vSignal can change
        namePool.subgraphDeploymentID = _newSubgraphDeploymentID;
        (namePool.vSignal, ) = curation.mint(namePool.subgraphDeploymentID, tokensWithTax, 0);

        emit NameSignalUpgrade(
            _graphAccount,
            _subgraphNumber,
            namePool.vSignal,
            tokensWithTax,
            _newSubgraphDeploymentID
        );
    }

    /**
     * @dev Allow a name curator to mint some nSignal by depositing GRT
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number
     * @param _tokensIn The amount of tokens the nameCurator wants to deposit
     * @param _nSignalOutMin Expected minimum amount of name signal to receive
     */
    function mintNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _tokensIn,
        uint256 _nSignalOutMin
    ) external override notPartialPaused {
        // Pool checks
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        require(namePool.disabled == false, "GNS: Cannot be disabled");
        require(
            namePool.subgraphDeploymentID != 0,
            "GNS: Must deposit on a name signal that exists"
        );

        // Pull tokens from sender
        require(
            graphToken().transferFrom(msg.sender, address(this), _tokensIn),
            "GNS: Cannot transfer tokens to mint n signal"
        );

        // Get name signal to mint for tokens deposited
        (uint256 vSignal, ) = curation().mint(namePool.subgraphDeploymentID, _tokensIn, 0);
        uint256 nSignal = vSignalToNSignal(_graphAccount, _subgraphNumber, vSignal);

        // Slippage protection
        require(nSignal >= _nSignalOutMin, "GNS: Slippage protection");

        // Update pools
        namePool.vSignal = namePool.vSignal.add(vSignal);
        namePool.nSignal = namePool.nSignal.add(nSignal);
        namePool.curatorNSignal[msg.sender] = namePool.curatorNSignal[msg.sender].add(nSignal);

        emit NSignalMinted(_graphAccount, _subgraphNumber, msg.sender, nSignal, vSignal, _tokensIn);
    }

    /**
     * @dev Allow a nameCurator to burn some of its nSignal and get GRT in return
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number which was curated on by nameCurators
     * @param _nSignal The amount of nSignal the nameCurator wants to burn
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     */
    function burnNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _nSignal,
        uint256 _tokensOutMin
    ) external override notPartialPaused {
        // Pool checks
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        require(namePool.disabled == false, "GNS: Cannot be disabled");

        // Curator balance checks
        uint256 curatorNSignal = namePool.curatorNSignal[msg.sender];
        require(
            _nSignal <= curatorNSignal,
            "GNS: Curator cannot withdraw more nSignal than they have"
        );

        // Get tokens for name signal amount to burn
        uint256 vSignal = nSignalToVSignal(_graphAccount, _subgraphNumber, _nSignal);
        uint256 tokens = curation().burn(namePool.subgraphDeploymentID, vSignal, _tokensOutMin);

        // Update pools
        namePool.vSignal = namePool.vSignal.sub(vSignal);
        namePool.nSignal = namePool.nSignal.sub(_nSignal);
        namePool.curatorNSignal[msg.sender] = namePool.curatorNSignal[msg.sender].sub(_nSignal);

        // Return the tokens to the nameCurator
        require(
            graphToken().transfer(msg.sender, tokens),
            "GNS: Error sending nameCurators tokens"
        );

        emit NSignalBurned(_graphAccount, _subgraphNumber, msg.sender, _nSignal, vSignal, tokens);
    }

    /**
     * @dev Owner disables the subgraph. This means the subgraph-number combination can no longer
     * be used for name signal. The nSignal curve is destroyed, the vSignal is burned, and the GNS
     * contract holds the GRT from burning the vSignal, which all curators can withdraw manually.
     * @param _graphAccount Account that is deprecating its name curation
     * @param _subgraphNumber Subgraph number
     */
    function _disableNameSignal(address _graphAccount, uint256 _subgraphNumber) private {
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];

        // If no nSignal, then no need to burn vSignal
        if (namePool.nSignal != 0) {
            namePool.withdrawableGRT = curation().burn(
                namePool.subgraphDeploymentID,
                namePool.vSignal,
                0
            );
            namePool.vSignal = 0;
        }

        // Set the NameCurationPool fields to make it disabled
        namePool.disabled = true;

        emit NameSignalDisabled(_graphAccount, _subgraphNumber, namePool.withdrawableGRT);
    }

    /**
     * @dev When the subgraph curve is disabled, all nameCurators can call this function and
     * withdraw the GRT they are entitled for its original deposit of vSignal
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number which was curated on by nameCurators
     */
    function withdraw(address _graphAccount, uint256 _subgraphNumber)
        external
        override
        notPartialPaused
    {
        // Pool checks
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        require(namePool.disabled == true, "GNS: Name bonding curve must be disabled first");
        require(namePool.withdrawableGRT > 0, "GNS: No more GRT to withdraw");

        // Curator balance checks
        uint256 curatorNSignal = namePool.curatorNSignal[msg.sender];
        require(curatorNSignal > 0, "GNS: Curator must have some nSignal to withdraw GRT");

        // Get curator share of tokens to be withdrawn
        uint256 tokensOut = curatorNSignal.mul(namePool.withdrawableGRT).div(namePool.nSignal);
        namePool.curatorNSignal[msg.sender] = 0;
        namePool.nSignal = namePool.nSignal.sub(curatorNSignal);
        namePool.withdrawableGRT = namePool.withdrawableGRT.sub(tokensOut);

        require(
            graphToken().transfer(msg.sender, tokensOut),
            "GNS: Error withdrawing tokens for nameCurator"
        );

        emit GRTWithdrawn(_graphAccount, _subgraphNumber, msg.sender, curatorNSignal, tokensOut);
    }

    /**
     * @dev Calculate tax that owner will have to cover for upgrading or deprecating.
     * @param _tokens Tokens that were received from deprecating the old subgraph
     * @param _owner Subgraph owner
     * @param _curationTaxPercentage Tax percentage on curation deposits from Curation contract
     * @return Total tokens that will be sent to curation, _tokens + ownerTax
     */
    function _chargeOwnerTax(
        uint256 _tokens,
        address _owner,
        uint32 _curationTaxPercentage
    ) private returns (uint256) {
        if (_curationTaxPercentage == 0 || ownerTaxPercentage == 0) {
            return 0;
        }

        // Tax on the total bonding curve funds
        uint256 taxOnOriginal = _tokens.mul(_curationTaxPercentage).div(MAX_PPM);
        // Total after the tax
        uint256 totalWithoutOwnerTax = _tokens.sub(taxOnOriginal);
        // The portion of tax that the owner will pay
        uint256 ownerTax = taxOnOriginal.mul(ownerTaxPercentage).div(MAX_PPM);

        uint256 totalWithOwnerTax = totalWithoutOwnerTax.add(ownerTax);

        // The total after tax, plus owner partial repay, divided by
        // the tax, to adjust it slightly upwards. ex:
        // 100 GRT, 5 GRT Tax, owner pays 100% --> 5 GRT
        // To get 100 in the protocol after tax, Owner deposits
        // ~5.26, as ~105.26 * .95 = 100
        uint256 totalAdjustedUp = totalWithOwnerTax.mul(MAX_PPM).div(
            uint256(MAX_PPM).sub(uint256(_curationTaxPercentage))
        );

        uint256 ownerTaxAdjustedUp = totalAdjustedUp.sub(_tokens);

        // Get the owner of the subgraph to reimburse the curation tax
        require(
            graphToken().transferFrom(_owner, address(this), ownerTaxAdjustedUp),
            "GNS: Error reimbursing curation tax"
        );
        return totalAdjustedUp;
    }

    /**
     * @dev Calculate name signal to be returned for an amount of tokens.
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number which was curated on by nameCurators
     * @param _tokensIn Tokens being exchanged for name signal
     * @return Amount of name signal and curation tax
     */
    function tokensToNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _tokensIn
    )
        public
        override
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        (uint256 vSignal, uint256 curationTax) = curation().tokensToSignal(
            namePool.subgraphDeploymentID,
            _tokensIn
        );
        uint256 nSignal = vSignalToNSignal(_graphAccount, _subgraphNumber, vSignal);
        return (vSignal, nSignal, curationTax);
    }

    /**
     * @dev Calculate tokens returned for an amount of name signal.
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number which was curated on by nameCurators
     * @param _nSignalIn Name signal being exchanged for tokens
     * @return Amount of tokens returned for an amount of nSignal
     */
    function nSignalToTokens(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _nSignalIn
    ) public override view returns (uint256, uint256) {
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        uint256 vSignal = nSignalToVSignal(_graphAccount, _subgraphNumber, _nSignalIn);
        uint256 tokensOut = curation().signalToTokens(namePool.subgraphDeploymentID, vSignal);
        return (vSignal, tokensOut);
    }

    /**
     * @dev Calculate nSignal to be returned for an amount of vSignal.
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number which was curated on by nameCurators
     * @param _vSignalIn Amount of vSignal to exchange for name signal
     * @return Amount of nSignal that can be bought
     */
    function vSignalToNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _vSignalIn
    ) public override view returns (uint256) {
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];

        // Handle initialization by using 1:1 version to name signal
        if (namePool.vSignal == 0) {
            return _vSignalIn;
        }

        return
            BancorFormula(bondingCurve).calculatePurchaseReturn(
                namePool.nSignal,
                namePool.vSignal,
                namePool.reserveRatio,
                _vSignalIn
            );
    }

    /**
     * @dev Calculate vSignal to be returned for an amount of name signal.
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number which was curated on by nameCurators
     * @param _nSignalIn Name signal being exchanged for vSignal
     * @return Amount of vSignal that can be returned
     */
    function nSignalToVSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _nSignalIn
    ) public override view returns (uint256) {
        NameCurationPool storage namePool = nameSignals[_graphAccount][_subgraphNumber];
        return
            BancorFormula(bondingCurve).calculateSaleReturn(
                namePool.nSignal,
                namePool.vSignal,
                namePool.reserveRatio,
                _nSignalIn
            );
    }

    /**
     * @dev Get the amount of name signal a curator has on a name pool.
     * @param _graphAccount Subgraph owner
     * @param _subgraphNumber Subgraph owners subgraph number which was curated on by nameCurators
     * @param _curator Curator to look up to see n signal balance
     * @return Amount of name signal owned by a curator for the name pool
     */
    function getCuratorNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        address _curator
    ) public override view returns (uint256) {
        return nameSignals[_graphAccount][_subgraphNumber].curatorNSignal[_curator];
    }

    /**
     * @dev Return whether a subgraph name is published.
     * @param _graphAccount Account being checked
     * @param _subgraphNumber Subgraph number being checked for publishing
     * @return Return true if subgraph is currently published
     */
    function isPublished(address _graphAccount, uint256 _subgraphNumber)
        public
        override
        view
        returns (bool)
    {
        return subgraphs[_graphAccount][_subgraphNumber] != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32
        internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl {
        require(msg.sender == _implementation(), "Caller must be the implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Accept to be an implementation of proxy.
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @dev Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IGNS {
    // -- Pool --

    struct NameCurationPool {
        uint256 vSignal; // The token of the subgraph deployment bonding curve
        uint256 nSignal; // The token of the name curation bonding curve
        mapping(address => uint256) curatorNSignal;
        bytes32 subgraphDeploymentID;
        uint32 reserveRatio;
        bool disabled;
        uint256 withdrawableGRT;
    }

    // -- Configuration --

    function approveAll() external;

    function setOwnerTaxPercentage(uint32 _ownerTaxPercentage) external;

    // -- Publishing --

    function setDefaultName(
        address _graphAccount,
        uint8 _nameSystem,
        bytes32 _nameIdentifier,
        string calldata _name
    ) external;

    function updateSubgraphMetadata(
        address _graphAccount,
        uint256 _subgraphNumber,
        bytes32 _subgraphMetadata
    ) external;

    function publishNewSubgraph(
        address _graphAccount,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata,
        bytes32 _subgraphMetadata
    ) external;

    function publishNewVersion(
        address _graphAccount,
        uint256 _subgraphNumber,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) external;

    function deprecateSubgraph(address _graphAccount, uint256 _subgraphNumber) external;

    // -- Curation --

    function mintNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _tokensIn,
        uint256 _nSignalOutMin
    ) external;

    function burnNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _nSignal,
        uint256 _tokensOutMin
    ) external;

    function withdraw(address _graphAccount, uint256 _subgraphNumber) external;

    // -- Getters --

    function tokensToNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _tokensIn
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function nSignalToTokens(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _nSignalIn
    ) external view returns (uint256, uint256);

    function vSignalToNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _vSignalIn
    ) external view returns (uint256);

    function nSignalToVSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        uint256 _nSignalIn
    ) external view returns (uint256);

    function getCuratorNSignal(
        address _graphAccount,
        uint256 _subgraphNumber,
        address _curator
    ) external view returns (uint256);

    function isPublished(address _graphAccount, uint256 _subgraphNumber)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "../governance/Managed.sol";

import "./erc1056/IEthereumDIDRegistry.sol";

import "./IGNS.sol";

contract GNSV1Storage is Managed {
    // -- State --

    // In parts per hundred
    uint32 public ownerTaxPercentage;

    // Bonding curve formula
    address public bondingCurve;

    // graphAccountID => subgraphNumber => subgraphDeploymentID
    // subgraphNumber = A number associated to a graph accounts deployed subgraph. This
    //                  is used to point to a subgraphID (graphAccountID + subgraphNumber)
    mapping(address => mapping(uint256 => bytes32)) public subgraphs;

    // graphAccountID => subgraph deployment counter
    mapping(address => uint256) public graphAccountSubgraphNumbers;

    // graphAccountID => subgraphNumber => NameCurationPool
    mapping(address => mapping(uint256 => IGNS.NameCurationPool)) public nameSignals;

    // ERC-1056 contract reference
    IEthereumDIDRegistry public erc1056Registry;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IManaged.sol";
import "./IController.sol";
import "../curation/ICuration.sol";
import "../epochs/IEpochManager.sol";
import "../rewards/IRewardsManager.sol";
import "../staking/IStaking.sol";
import "../token/IGraphToken.sol";

/**
 * @title Graph Managed contract
 * @dev The Managed contract provides an interface for contracts to interact with the Controller
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
contract Managed {
    // Controller that contract is registered with
    IController public controller;
    mapping(bytes32 => address) public addressCache;
    uint256[10] private __gap;

    event ParameterUpdated(string param);
    event SetController(address controller);

    function _notPartialPaused() internal view {
        require(!controller.paused(), "Paused");
        require(!controller.partialPaused(), "Partial-paused");
    }

    function _notPaused() internal view {
        require(!controller.paused(), "Paused");
    }

    function _onlyGovernor() internal view {
        require(msg.sender == controller.getGovernor(), "Caller must be Controller governor");
    }

    modifier notPartialPaused {
        _notPartialPaused();
        _;
    }

    modifier notPaused {
        _notPaused();
        _;
    }

    // Check if sender is controller
    modifier onlyController() {
        require(msg.sender == address(controller), "Caller must be Controller");
        _;
    }

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /**
     * @dev Initialize the controller
     */
    function _initialize(address _controller) internal {
        _setController(_controller);
    }

    /**
     * @notice Set Controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        _setController(_controller);
    }

    /**
     * @dev Set controller.
     * @param _controller Controller contract address
     */
    function _setController(address _controller) internal {
        require(_controller != address(0), "Controller must be set");
        controller = IController(_controller);
        emit SetController(_controller);
    }

    /**
     * @dev Return Curation interface
     * @return Curation contract registered with Controller
     */
    function curation() internal view returns (ICuration) {
        return ICuration(controller.getContractProxy(keccak256("Curation")));
    }

    /**
     * @dev Return EpochManager interface
     * @return Epoch manager contract registered with Controller
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(controller.getContractProxy(keccak256("EpochManager")));
    }

    /**
     * @dev Return RewardsManager interface
     * @return Rewards manager contract registered with Controller
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(controller.getContractProxy(keccak256("RewardsManager")));
    }

    /**
     * @dev Return Staking interface
     * @return Staking contract registered with Controller
     */
    function staking() internal view returns (IStaking) {
        return IStaking(controller.getContractProxy(keccak256("Staking")));
    }

    /**
     * @dev Return GraphToken interface
     * @return Graph token contract registered with Controller
     */
    function graphToken() internal view returns (IGraphToken) {
        return IGraphToken(controller.getContractProxy(keccak256("GraphToken")));
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.3;

interface IEthereumDIDRegistry {
    function identityOwner(address identity) external view returns (address);

    function setAttribute(
        address identity,
        bytes32 name,
        bytes calldata value,
        uint256 validity
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IManaged {
    function setController(address _controller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IGraphCurationToken.sol";

interface ICuration {
    // -- Pool --

    struct CurationPool {
        uint256 tokens; // GRT Tokens stored as reserves for the subgraph deployment
        uint32 reserveRatio; // Ratio for the bonding curve
        IGraphCurationToken gcs; // Curation token contract for this curation pool
    }

    // -- Configuration --

    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit) external;

    function setCurationTaxPercentage(uint32 _percentage) external;

    // -- Curation --

    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external returns (uint256, uint256);

    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external returns (uint256);

    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external;

    // -- Getters --

    function isCurated(bytes32 _subgraphDeploymentID) external view returns (bool);

    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getCurationPoolSignal(bytes32 _subgraphDeploymentID) external view returns (uint256);

    function getCurationPoolTokens(bytes32 _subgraphDeploymentID) external view returns (uint256);

    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        view
        returns (uint256, uint256);

    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        external
        view
        returns (uint256);

    function curationTaxPercentage() external view returns (uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IEpochManager {
    // -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IRewardsManager {
    /**
     * @dev Stores accumulated rewards and snapshots related to a particular SubgraphDeployment.
     */
    struct Subgraph {
        uint256 accRewardsForSubgraph;
        uint256 accRewardsForSubgraphSnapshot;
        uint256 accRewardsPerSignalSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    // -- Params --

    function setIssuanceRate(uint256 _issuanceRate) external;

    // -- Denylist --

    function setSubgraphAvailabilityOracle(address _subgraphAvailabilityOracle) external;

    function setDenied(bytes32 _subgraphDeploymentID, bool _deny) external;

    function setDeniedMany(bytes32[] calldata _subgraphDeploymentID, bool[] calldata _deny)
        external;

    function isDenied(bytes32 _subgraphDeploymentID) external view returns (bool);

    // -- Getters --

    function getNewRewardsPerSignal() external view returns (uint256);

    function getAccRewardsPerSignal() external view returns (uint256);

    function getAccRewardsForSubgraph(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getAccRewardsPerAllocatedToken(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256, uint256);

    function getRewards(address _allocationID) external view returns (uint256);

    // -- Updates --

    function updateAccRewardsPerSignal() external returns (uint256);

    function takeRewards(address _allocationID) external returns (uint256);

    // -- Hooks --

    function onSubgraphSignalUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);

    function onSubgraphAllocationUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

interface IStaking {
    // -- Allocation Data --

    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState { Null, Active, Closed, Finalized, Claimed }

    /**
     * @dev Allocate GRT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address indexer;
        bytes32 subgraphDeploymentID;
        uint256 tokens; // Tokens allocated to a SubgraphDeployment
        uint256 createdAtEpoch; // Epoch when it was created
        uint256 closedAtEpoch; // Epoch when it was closed
        uint256 collectedFees; // Collected fees for the allocation
        uint256 effectiveAllocation; // Effective allocation when closed
        uint256 accRewardsPerAllocatedToken; // Snapshot used for reward calc
    }

    /**
     * @dev Represents a request to close an allocation with a specific proof of indexing.
     * This is passed when calling closeAllocationMany to define the closing parameters for
     * each allocation.
     */
    struct CloseAllocationRequest {
        address allocationID;
        bytes32 poi;
    }

    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }

    // -- Configuration --

    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external;

    function setThawingPeriod(uint32 _thawingPeriod) external;

    function setCurationPercentage(uint32 _percentage) external;

    function setProtocolPercentage(uint32 _percentage) external;

    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    function setDelegationRatio(uint32 _delegationRatio) external;

    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) external;

    function setDelegationParametersCooldown(uint32 _blocks) external;

    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) external;

    function setDelegationTaxPercentage(uint32 _percentage) external;

    function setSlasher(address _slasher, bool _allowed) external;

    function setAssetHolder(address _assetHolder, bool _allowed) external;

    // -- Operation --

    function setOperator(address _operator, bool _allowed) external;

    function isOperator(address _operator, address _indexer) external view returns (bool);

    // -- Staking --

    function stake(uint256 _tokens) external;

    function stakeTo(address _indexer, uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    function withdraw() external;

    // -- Delegation --

    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    // -- Channel management and allocations --

    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function closeAllocation(address _allocationID, bytes32 _poi) external;

    function closeAllocationMany(CloseAllocationRequest[] calldata _requests) external;

    function closeAndAllocate(
        address _oldAllocationID,
        bytes32 _poi,
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function collect(uint256 _tokens, address _allocationID) external;

    function claim(address _allocationID, bool _restake) external;

    function claimMany(address[] calldata _allocationID, bool _restake) external;

    // -- Getters and calculations --

    function hasStake(address _indexer) external view returns (bool);

    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    function getIndexerCapacity(address _indexer) external view returns (uint256);

    function getAllocation(address _allocationID) external view returns (Allocation memory);

    function getAllocationState(address _allocationID) external view returns (AllocationState);

    function isAllocation(address _allocationID) external view returns (bool);

    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getDelegation(address _indexer, address _delegator)
        external
        view
        returns (Delegation memory);

    function isDelegator(address _indexer, address _delegator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGraphToken is IERC20 {
    // -- Mint and Burn --

    function burn(uint256 amount) external;

    function mint(address _to, uint256 _amount) external;

    // -- Mint Admin --

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function renounceMinter() external;

    function isMinter(address _account) external view returns (bool);

    // -- Permit --

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGraphCurationToken is IERC20 {
    function burnFrom(address _account, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;
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

pragma solidity ^0.7.3;

import "../governance/Managed.sol";
import "../staking/IStaking.sol";
import "./IStaking.sol";
import "./libs/Rebates.sol";
import "./libs/Stakes.sol";

contract StakingV1Storage is Managed {
    // -- Staking --

    // Minimum amount of tokens an indexer needs to stake
    uint256 public minimumIndexerStake;

    // Time in blocks to unstake
    uint32 public thawingPeriod; // in blocks

    // Percentage of fees going to curators
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public curationPercentage;

    // Percentage of fees burned as protocol fee
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public protocolPercentage;

    // Period for allocation to be finalized
    uint32 public channelDisputeEpochs;

    // Maximum allocation time
    uint32 public maxAllocationEpochs;

    // Rebate ratio
    uint32 public alphaNumerator;
    uint32 public alphaDenominator;

    // Indexer stakes : indexer => Stake
    mapping(address => Stakes.Indexer) public stakes;

    // Allocations : allocationID => Allocation
    mapping(address => IStaking.Allocation) public allocations;

    // Subgraph Allocations: subgraphDeploymentID => tokens
    mapping(bytes32 => uint256) public subgraphAllocations;

    // Rebate pools : epoch => Pool
    mapping(uint256 => Rebates.Pool) public rebates;

    // -- Slashing --

    // List of addresses allowed to slash stakes
    mapping(address => bool) public slashers;

    // -- Delegation --

    // Set the delegation capacity multiplier defined by the delegation ratio
    // If delegation ratio is 100, and an Indexer has staked 5 GRT,
    // then they can use up to 500 GRT from the delegated stake
    uint32 public delegationRatio;

    // Time in blocks an indexer needs to wait to change delegation parameters
    uint32 public delegationParametersCooldown;

    // Time in epochs a delegator needs to wait to withdraw delegated stake
    uint32 public delegationUnbondingPeriod; // in epochs

    // Percentage of tokens to tax a delegation deposit
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public delegationTaxPercentage;

    // Delegation pools : indexer => DelegationPool
    mapping(address => IStaking.DelegationPool) public delegationPools;

    // -- Operators --

    // Operator auth : indexer => operator
    mapping(address => mapping(address => bool)) public operatorAuth;

    // -- Asset Holders --

    // Allowed AssetHolders: assetHolder => is allowed
    mapping(address => bool) public assetHolders;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./Cobbs.sol";

/**
 * @title A collection of data structures and functions to manage Rebates
 *        Used for low-level state changes, require() conditions should be evaluated
 *        at the caller function scope.
 */
library Rebates {
    using SafeMath for uint256;

    // Tracks stats for allocations closed on a particular epoch for claiming
    // The pool also keeps tracks of total query fees collected and stake used
    // Only one rebate pool exists per epoch
    struct Pool {
        uint256 fees; // total query fees in the rebate pool
        uint256 effectiveAllocatedStake; // total effective allocation of stake
        uint256 claimedRewards; // total claimed rewards from the rebate pool
        uint32 unclaimedAllocationsCount; // amount of unclaimed allocations
        uint32 alphaNumerator; // numerator of `alpha` in the cobb-douglas function
        uint32 alphaDenominator; // denominator of `alpha` in the cobb-douglas function
    }

    /**
     * @dev Init the rebate pool with the rebate ratio.
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function init(
        Rebates.Pool storage pool,
        uint32 _alphaNumerator,
        uint32 _alphaDenominator
    ) internal {
        pool.alphaNumerator = _alphaNumerator;
        pool.alphaDenominator = _alphaDenominator;
    }

    /**
     * @dev Return true if the rebate pool was already initialized.
     */
    function exists(Rebates.Pool storage pool) internal view returns (bool) {
        return pool.effectiveAllocatedStake > 0;
    }

    /**
     * @dev Return the amount of unclaimed fees.
     */
    function unclaimedFees(Rebates.Pool storage pool) internal view returns (uint256) {
        return pool.fees.sub(pool.claimedRewards);
    }

    /**
     * @dev Deposit tokens into the rebate pool.
     * @param _indexerFees Amount of fees collected in tokens
     * @param _indexerEffectiveAllocatedStake Effective stake allocated by indexer for a period of epochs
     */
    function addToPool(
        Rebates.Pool storage pool,
        uint256 _indexerFees,
        uint256 _indexerEffectiveAllocatedStake
    ) internal {
        pool.fees = pool.fees.add(_indexerFees);
        pool.effectiveAllocatedStake = pool.effectiveAllocatedStake.add(
            _indexerEffectiveAllocatedStake
        );
        pool.unclaimedAllocationsCount += 1;
    }

    /**
     * @dev Redeem tokens from the rebate pool.
     * @param _indexerFees Amount of fees collected in tokens
     * @param _indexerEffectiveAllocatedStake Effective stake allocated by indexer for a period of epochs
     * @return Amount of reward tokens according to Cobb-Douglas rebate formula
     */
    function redeem(
        Rebates.Pool storage pool,
        uint256 _indexerFees,
        uint256 _indexerEffectiveAllocatedStake
    ) internal returns (uint256) {
        uint256 rebateReward = 0;

        // Calculate the rebate rewards for the indexer
        if (pool.fees > 0) {
            rebateReward = LibCobbDouglas.cobbDouglas(
                pool.fees, // totalRewards
                _indexerFees,
                pool.fees,
                _indexerEffectiveAllocatedStake,
                pool.effectiveAllocatedStake,
                pool.alphaNumerator,
                pool.alphaDenominator
            );

            // Under NO circumstance we will reward more than total fees in the pool
            uint256 _unclaimedFees = pool.fees.sub(pool.claimedRewards);
            if (rebateReward > _unclaimedFees) {
                rebateReward = _unclaimedFees;
            }
        }

        // Update pool state
        pool.unclaimedAllocationsCount -= 1;
        pool.claimedRewards = pool.claimedRewards.add(rebateReward);

        return rebateReward;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title A collection of data structures and functions to manage the Indexer Stake state.
 *        Used for low-level state changes, require() conditions should be evaluated
 *        at the caller function scope.
 */
library Stakes {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;

    struct Indexer {
        uint256 tokensStaked; // Tokens on the indexer stake (staked by the indexer)
        uint256 tokensAllocated; // Tokens used in allocations
        uint256 tokensLocked; // Tokens locked for withdrawal subject to thawing period
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }

    /**
     * @dev Deposit tokens to the indexer stake.
     * @param stake Stake data
     * @param _tokens Amount of tokens to deposit
     */
    function deposit(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.add(_tokens);
    }

    /**
     * @dev Release tokens from the indexer stake.
     * @param stake Stake data
     * @param _tokens Amount of tokens to release
     */
    function release(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.sub(_tokens);
    }

    /**
     * @dev Allocate tokens from the main stack to a SubgraphDeployment.
     * @param stake Stake data
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.add(_tokens);
    }

    /**
     * @dev Unallocate tokens from a SubgraphDeployment back to the main stack.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unallocate
     */
    function unallocate(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.sub(_tokens);
    }

    /**
     * @dev Lock tokens until a thawing period pass.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unstake
     * @param _period Period in blocks that need to pass before withdrawal
     */
    function lockTokens(
        Stakes.Indexer storage stake,
        uint256 _tokens,
        uint256 _period
    ) internal {
        // Take into account period averaging for multiple unstake requests
        uint256 lockingPeriod = _period;
        if (stake.tokensLocked > 0) {
            lockingPeriod = stake.getLockingPeriod(_tokens, _period);
        }

        // Update balances
        stake.tokensLocked = stake.tokensLocked.add(_tokens);
        stake.tokensLockedUntil = block.number.add(lockingPeriod);
    }

    /**
     * @dev Unlock tokens.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unkock
     */
    function unlockTokens(Stakes.Indexer storage stake, uint256 _tokens) internal {
        stake.tokensLocked = stake.tokensLocked.sub(_tokens);
        if (stake.tokensLocked == 0) {
            stake.tokensLockedUntil = 0;
        }
    }

    /**
     * @dev Take all tokens out from the locked stake for withdrawal.
     * @param stake Stake data
     * @return Amount of tokens being withdrawn
     */
    function withdrawTokens(Stakes.Indexer storage stake) internal returns (uint256) {
        // Calculate tokens that can be released
        uint256 tokensToWithdraw = stake.tokensWithdrawable();

        if (tokensToWithdraw > 0) {
            // Reset locked tokens
            stake.unlockTokens(tokensToWithdraw);

            // Decrease indexer stake
            stake.release(tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Get the locking period of the tokens to unstake.
     * If already unstaked before calculate the weighted average.
     * @param stake Stake data
     * @param _tokens Amount of tokens to unstake
     * @param _thawingPeriod Period in blocks that need to pass before withdrawal
     * @return The weighted average locking period
     */
    function getLockingPeriod(
        Stakes.Indexer memory stake,
        uint256 _tokens,
        uint256 _thawingPeriod
    ) internal view returns (uint256) {
        uint256 blockNum = block.number;
        uint256 periodA = (stake.tokensLockedUntil > blockNum)
            ? stake.tokensLockedUntil.sub(blockNum)
            : 0;
        uint256 periodB = _thawingPeriod;
        uint256 stakeA = stake.tokensLocked;
        uint256 stakeB = _tokens;
        return periodA.mul(stakeA).add(periodB.mul(stakeB)).div(stakeA.add(stakeB));
    }

    /**
     * @dev Return true if there are tokens staked by the Indexer.
     * @param stake Stake data
     * @return True if staked
     */
    function hasTokens(Stakes.Indexer memory stake) internal pure returns (bool) {
        return stake.tokensStaked > 0;
    }

    /**
     * @dev Return the amount of tokens used in allocations and locked for withdrawal.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensUsed(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensAllocated.add(stake.tokensLocked);
    }

    /**
     * @dev Return the amount of tokens staked not considering the ones that are already going
     * through the thawing period or are ready for withdrawal. We call it secure stake because
     * it is not subject to change by a withdraw call from the indexer.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensSecureStake(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensLocked);
    }

    /**
     * @dev Tokens free balance on the indexer stake that can be used for any purpose.
     * Any token that is allocated cannot be used as well as tokens that are going through the
     * thawing period or are withdrawable
     * Calc: tokensStaked - tokensAllocated - tokensLocked
     * @param stake Stake data
     * @return Token amount
     */
    function tokensAvailable(Stakes.Indexer memory stake) internal pure returns (uint256) {
        return stake.tokensAvailableWithDelegation(0);
    }

    /**
     * @dev Tokens free balance on the indexer stake that can be used for allocations.
     * This function accepts a parameter for extra delegated capacity that takes into
     * account delegated tokens
     * @param stake Stake data
     * @param _delegatedCapacity Amount of tokens used from delegators to calculate availability
     * @return Token amount
     */
    function tokensAvailableWithDelegation(Stakes.Indexer memory stake, uint256 _delegatedCapacity)
        internal
        pure
        returns (uint256)
    {
        uint256 tokensCapacity = stake.tokensStaked.add(_delegatedCapacity);
        uint256 _tokensUsed = stake.tokensUsed();
        // If more tokens are used than the current capacity, the indexer is overallocated.
        // This means the indexer doesn't have available capacity to create new allocations.
        // We can reach this state when the indexer has funds allocated and then any
        // of these conditions happen:
        // - The delegationCapacity ratio is reduced.
        // - The indexer stake is slashed.
        // - A delegator removes enough stake.
        if (_tokensUsed > tokensCapacity) {
            // Indexer stake is over allocated: return 0 to avoid stake to be used until
            // the overallocation is restored by staking more tokens, unallocating tokens
            // or using more delegated funds
            return 0;
        }
        return tokensCapacity.sub(_tokensUsed);
    }

    /**
     * @dev Tokens available for withdrawal after thawing period.
     * @param stake Stake data
     * @return Token amount
     */
    function tokensWithdrawable(Stakes.Indexer memory stake) internal view returns (uint256) {
        // No tokens to withdraw before locking period
        if (stake.tokensLockedUntil == 0 || block.number < stake.tokensLockedUntil) {
            return 0;
        }
        return stake.tokensLocked;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./LibFixedMath.sol";

library LibCobbDouglas {
    /// @dev The cobb-douglas function used to compute fee-based rewards for
    ///      staking pools in a given epoch. This function does not perform
    ///      bounds checking on the inputs, but the following conditions
    ///      need to be true:
    ///         0 <= fees / totalFees <= 1
    ///         0 <= stake / totalStake <= 1
    ///         0 <= alphaNumerator / alphaDenominator <= 1
    /// @param totalRewards collected over an epoch.
    /// @param fees Fees attributed to the the staking pool.
    /// @param totalFees Total fees collected across all pools that earned rewards.
    /// @param stake Stake attributed to the staking pool.
    /// @param totalStake Total stake across all pools that earned rewards.
    /// @param alphaNumerator Numerator of `alpha` in the cobb-douglas function.
    /// @param alphaDenominator Denominator of `alpha` in the cobb-douglas
    ///        function.
    /// @return rewards Rewards owed to the staking pool.
    function cobbDouglas(
        uint256 totalRewards,
        uint256 fees,
        uint256 totalFees,
        uint256 stake,
        uint256 totalStake,
        uint32 alphaNumerator,
        uint32 alphaDenominator
    ) public pure returns (uint256 rewards) {
        int256 feeRatio = LibFixedMath.toFixed(fees, totalFees);
        int256 stakeRatio = LibFixedMath.toFixed(stake, totalStake);
        if (feeRatio == 0 || stakeRatio == 0) {
            return rewards = 0;
        }
        // The cobb-doublas function has the form:
        // `totalRewards * feeRatio ^ alpha * stakeRatio ^ (1-alpha)`
        // This is equivalent to:
        // `totalRewards * stakeRatio * e^(alpha * (ln(feeRatio / stakeRatio)))`
        // However, because `ln(x)` has the domain of `0 < x < 1`
        // and `exp(x)` has the domain of `x < 0`,
        // and fixed-point math easily overflows with multiplication,
        // we will choose the following if `stakeRatio > feeRatio`:
        // `totalRewards * stakeRatio / e^(alpha * (ln(stakeRatio / feeRatio)))`

        // Compute
        // `e^(alpha * ln(feeRatio/stakeRatio))` if feeRatio <= stakeRatio
        // or
        // `e^(alpa * ln(stakeRatio/feeRatio))` if feeRatio > stakeRatio
        int256 n = feeRatio <= stakeRatio
            ? LibFixedMath.div(feeRatio, stakeRatio)
            : LibFixedMath.div(stakeRatio, feeRatio);
        n = LibFixedMath.exp(
            LibFixedMath.mulDiv(
                LibFixedMath.ln(n),
                int256(alphaNumerator),
                int256(alphaDenominator)
            )
        );
        // Compute
        // `totalRewards * n` if feeRatio <= stakeRatio
        // or
        // `totalRewards / n` if stakeRatio > feeRatio
        // depending on the choice we made earlier.
        n = feeRatio <= stakeRatio
            ? LibFixedMath.mul(stakeRatio, n)
            : LibFixedMath.div(stakeRatio, n);
        // Multiply the above with totalRewards.
        rewards = LibFixedMath.uintMul(n, totalRewards);
    }
}

/*

  Copyright 2017 Bprotocol Foundation, 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.3;

// solhint-disable indent
/// @dev Signed, fixed-point, 127-bit precision math library.
library LibFixedMath {
    // 1
    int256 private constant FIXED_1 = int256(
        0x0000000000000000000000000000000080000000000000000000000000000000
    );
    // 2**255
    int256 private constant MIN_FIXED_VAL = int256(
        0x8000000000000000000000000000000000000000000000000000000000000000
    );
    // 1^2 (in fixed-point)
    int256 private constant FIXED_1_SQUARED = int256(
        0x4000000000000000000000000000000000000000000000000000000000000000
    );
    // 1
    int256 private constant LN_MAX_VAL = FIXED_1;
    // e ^ -63.875
    int256 private constant LN_MIN_VAL = int256(
        0x0000000000000000000000000000000000000000000000000000000733048c5a
    );
    // 0
    int256 private constant EXP_MAX_VAL = 0;
    // -63.875
    int256 private constant EXP_MIN_VAL = -int256(
        0x0000000000000000000000000000001ff0000000000000000000000000000000
    );

    /// @dev Get one as a fixed-point number.
    function one() internal pure returns (int256 f) {
        f = FIXED_1;
    }

    /// @dev Returns the addition of two fixed point numbers, reverting on overflow.
    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = _add(a, b);
    }

    /// @dev Returns the addition of two fixed point numbers, reverting on overflow.
    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b == MIN_FIXED_VAL) {
            revert("out-of-bounds");
        }
        c = _add(a, -b);
    }

    /// @dev Returns the multiplication of two fixed point numbers, reverting on overflow.
    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = _mul(a, b) / FIXED_1;
    }

    /// @dev Returns the division of two fixed point numbers.
    function div(int256 a, int256 b) internal pure returns (int256 c) {
        c = _div(_mul(a, FIXED_1), b);
    }

    /// @dev Performs (a * n) / d, without scaling for precision.
    function mulDiv(
        int256 a,
        int256 n,
        int256 d
    ) internal pure returns (int256 c) {
        c = _div(_mul(a, n), d);
    }

    /// @dev Returns the unsigned integer result of multiplying a fixed-point
    ///      number with an integer, reverting if the multiplication overflows.
    ///      Negative results are clamped to zero.
    function uintMul(int256 f, uint256 u) internal pure returns (uint256) {
        if (int256(u) < int256(0)) {
            revert("out-of-bounds");
        }
        int256 c = _mul(f, int256(u));
        if (c <= 0) {
            return 0;
        }
        return uint256(uint256(c) >> 127);
    }

    /// @dev Returns the absolute value of a fixed point number.
    function abs(int256 f) internal pure returns (int256 c) {
        if (f == MIN_FIXED_VAL) {
            revert("out-of-bounds");
        }
        if (f >= 0) {
            c = f;
        } else {
            c = -f;
        }
    }

    /// @dev Returns 1 / `x`, where `x` is a fixed-point number.
    function invert(int256 f) internal pure returns (int256 c) {
        c = _div(FIXED_1_SQUARED, f);
    }

    /// @dev Convert signed `n` / 1 to a fixed-point number.
    function toFixed(int256 n) internal pure returns (int256 f) {
        f = _mul(n, FIXED_1);
    }

    /// @dev Convert signed `n` / `d` to a fixed-point number.
    function toFixed(int256 n, int256 d) internal pure returns (int256 f) {
        f = _div(_mul(n, FIXED_1), d);
    }

    /// @dev Convert unsigned `n` / 1 to a fixed-point number.
    ///      Reverts if `n` is too large to fit in a fixed-point number.
    function toFixed(uint256 n) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            revert("out-of-bounds");
        }
        f = _mul(int256(n), FIXED_1);
    }

    /// @dev Convert unsigned `n` / `d` to a fixed-point number.
    ///      Reverts if `n` / `d` is too large to fit in a fixed-point number.
    function toFixed(uint256 n, uint256 d) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            revert("out-of-bounds");
        }
        if (int256(d) < int256(0)) {
            revert("out-of-bounds");
        }
        f = _div(_mul(int256(n), FIXED_1), int256(d));
    }

    /// @dev Convert a fixed-point number to an integer.
    function toInteger(int256 f) internal pure returns (int256 n) {
        return f / FIXED_1;
    }

    /// @dev Get the natural logarithm of a fixed-point number 0 < `x` <= LN_MAX_VAL
    function ln(int256 x) internal pure returns (int256 r) {
        if (x > LN_MAX_VAL) {
            revert("out-of-bounds");
        }
        if (x <= 0) {
            revert("too-small");
        }
        if (x == FIXED_1) {
            return 0;
        }
        if (x <= LN_MIN_VAL) {
            return EXP_MIN_VAL;
        }

        int256 y;
        int256 z;
        int256 w;

        // Rewrite the input as a quotient of negative natural exponents and a single residual q, such that 1 < q < 2
        // For example: log(0.3) = log(e^-1 * e^-0.25 * 1.0471028872385522)
        //              = 1 - 0.25 - log(1 + 0.0471028872385522)
        // e ^ -32
        if (x <= int256(0x00000000000000000000000000000000000000000001c8464f76164760000000)) {
            r -= int256(0x0000000000000000000000000000001000000000000000000000000000000000); // - 32
            x =
                (x * FIXED_1) /
                int256(0x00000000000000000000000000000000000000000001c8464f76164760000000); // / e ^ -32
        }
        // e ^ -16
        if (x <= int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000)) {
            r -= int256(0x0000000000000000000000000000000800000000000000000000000000000000); // - 16
            x =
                (x * FIXED_1) /
                int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000); // / e ^ -16
        }
        // e ^ -8
        if (x <= int256(0x00000000000000000000000000000000000afe10820813d78000000000000000)) {
            r -= int256(0x0000000000000000000000000000000400000000000000000000000000000000); // - 8
            x =
                (x * FIXED_1) /
                int256(0x00000000000000000000000000000000000afe10820813d78000000000000000); // / e ^ -8
        }
        // e ^ -4
        if (x <= int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000)) {
            r -= int256(0x0000000000000000000000000000000200000000000000000000000000000000); // - 4
            x =
                (x * FIXED_1) /
                int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000); // / e ^ -4
        }
        // e ^ -2
        if (x <= int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000100000000000000000000000000000000); // - 2
            x =
                (x * FIXED_1) /
                int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000); // / e ^ -2
        }
        // e ^ -1
        if (x <= int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000080000000000000000000000000000000); // - 1
            x =
                (x * FIXED_1) /
                int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000); // / e ^ -1
        }
        // e ^ -0.5
        if (x <= int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000040000000000000000000000000000000); // - 0.5
            x =
                (x * FIXED_1) /
                int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000); // / e ^ -0.5
        }
        // e ^ -0.25
        if (x <= int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000020000000000000000000000000000000); // - 0.25
            x =
                (x * FIXED_1) /
                int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000); // / e ^ -0.25
        }
        // e ^ -0.125
        if (x <= int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) {
            r -= int256(0x0000000000000000000000000000000010000000000000000000000000000000); // - 0.125
            x =
                (x * FIXED_1) /
                int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d); // / e ^ -0.125
        }
        // `x` is now our residual in the range of 1 <= x <= 2 (or close enough).

        // Add the taylor series for log(1 + z), where z = x - 1
        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        r += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        r += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        r += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        r += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        r += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        r += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        r += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        r += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16
    }

    /// @dev Compute the natural exponent for a fixed-point number EXP_MIN_VAL <= `x` <= 1
    function exp(int256 x) internal pure returns (int256 r) {
        if (x < EXP_MIN_VAL) {
            // Saturate to zero below EXP_MIN_VAL.
            return 0;
        }
        if (x == 0) {
            return FIXED_1;
        }
        if (x > EXP_MAX_VAL) {
            revert("out-of-bounds");
        }

        // Rewrite the input as a product of natural exponents and a
        // single residual q, where q is a number of small magnitude.
        // For example: e^-34.419 = e^(-32 - 2 - 0.25 - 0.125 - 0.044)
        //              = e^-32 * e^-2 * e^-0.25 * e^-0.125 * e^-0.044
        //              -> q = -0.044

        // Multiply with the taylor series for e^q
        int256 y;
        int256 z;
        // q = x % 0.125 (the residual)
        z = y = x % 0x0000000000000000000000000000000010000000000000000000000000000000;
        z = (z * y) / FIXED_1;
        r += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        r += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        r += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        r += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        r += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        r += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        r += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        r += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        r += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        r = r / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        // Multiply with the non-residual terms.
        x = -x;
        // e ^ -32
        if ((x & int256(0x0000000000000000000000000000001000000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000000000f1aaddd7742e56d32fb9f99744)) /
                int256(0x0000000000000000000000000043cbaf42a000812488fc5c220ad7b97bf6e99e); // * e ^ -32
        }
        // e ^ -16
        if ((x & int256(0x0000000000000000000000000000000800000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000000afe10820813d65dfe6a33c07f738f)) /
                int256(0x000000000000000000000000000005d27a9f51c31b7c2f8038212a0574779991); // * e ^ -16
        }
        // e ^ -8
        if ((x & int256(0x0000000000000000000000000000000400000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000002582ab704279e8efd15e0265855c47a)) /
                int256(0x0000000000000000000000000000001b4c902e273a58678d6d3bfdb93db96d02); // * e ^ -8
        }
        // e ^ -4
        if ((x & int256(0x0000000000000000000000000000000200000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000001152aaa3bf81cb9fdb76eae12d029571)) /
                int256(0x00000000000000000000000000000003b1cc971a9bb5b9867477440d6d157750); // * e ^ -4
        }
        // e ^ -2
        if ((x & int256(0x0000000000000000000000000000000100000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000002f16ac6c59de6f8d5d6f63c1482a7c86)) /
                int256(0x000000000000000000000000000000015bf0a8b1457695355fb8ac404e7a79e3); // * e ^ -2
        }
        // e ^ -1
        if ((x & int256(0x0000000000000000000000000000000080000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000004da2cbf1be5827f9eb3ad1aa9866ebb3)) /
                int256(0x00000000000000000000000000000000d3094c70f034de4b96ff7d5b6f99fcd8); // * e ^ -1
        }
        // e ^ -0.5
        if ((x & int256(0x0000000000000000000000000000000040000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000063afbe7ab2082ba1a0ae5e4eb1b479dc)) /
                int256(0x00000000000000000000000000000000a45af1e1f40c333b3de1db4dd55f29a7); // * e ^ -0.5
        }
        // e ^ -0.25
        if ((x & int256(0x0000000000000000000000000000000020000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) /
                int256(0x00000000000000000000000000000000910b022db7ae67ce76b441c27035c6a1); // * e ^ -0.25
        }
        // e ^ -0.125
        if ((x & int256(0x0000000000000000000000000000000010000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000783eafef1c0a8f3978c7f81824d62ebf)) /
                int256(0x0000000000000000000000000000000088415abbe9a76bead8d00cf112e4d4a8); // * e ^ -0.125
        }
    }

    /// @dev Returns the multiplication two numbers, reverting on overflow.
    function _mul(int256 a, int256 b) private pure returns (int256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        if (c / a != b || c / b != a) {
            revert("overflow");
        }
    }

    /// @dev Returns the division of two numbers, reverting on division by zero.
    function _div(int256 a, int256 b) private pure returns (int256 c) {
        if (b == 0) {
            revert("overflow");
        }
        if (a == MIN_FIXED_VAL && b == -1) {
            revert("overflow");
        }
        c = a / b;
    }

    /// @dev Adds two numbers, reverting on overflow.
    function _add(int256 a, int256 b) private pure returns (int256 c) {
        c = a + b;
        if ((a < 0 && b < 0 && c > a) || (a > 0 && b > 0 && c < a)) {
            revert("overflow");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "../upgrades/GraphUpgradeable.sol";

import "./IStaking.sol";
import "./StakingStorage.sol";
import "./libs/Rebates.sol";
import "./libs/Stakes.sol";

/**
 * @title Staking contract
 */
contract Staking is StakingV1Storage, GraphUpgradeable, IStaking {
    using SafeMath for uint256;
    using Stakes for Stakes.Indexer;
    using Rebates for Rebates.Pool;

    // 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    // -- Events --

    /**
     * @dev Emitted when `indexer` update the delegation parameters for its delegation pool.
     */
    event DelegationParametersUpdated(
        address indexed indexer,
        uint32 indexingRewardCut,
        uint32 queryFeeCut,
        uint32 cooldownBlocks
    );

    /**
     * @dev Emitted when `indexer` stake `tokens` amount.
     */
    event StakeDeposited(address indexed indexer, uint256 tokens);

    /**
     * @dev Emitted when `indexer` unstaked and locked `tokens` amount `until` block.
     */
    event StakeLocked(address indexed indexer, uint256 tokens, uint256 until);

    /**
     * @dev Emitted when `indexer` withdrew `tokens` staked.
     */
    event StakeWithdrawn(address indexed indexer, uint256 tokens);

    /**
     * @dev Emitted when `indexer` was slashed for a total of `tokens` amount.
     * Tracks `reward` amount of tokens given to `beneficiary`.
     */
    event StakeSlashed(
        address indexed indexer,
        uint256 tokens,
        uint256 reward,
        address beneficiary
    );

    /**
     * @dev Emitted when `delegator` delegated `tokens` to the `indexer`, the delegator
     * gets `shares` for the delegation pool proportionally to the tokens staked.
     */
    event StakeDelegated(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens,
        uint256 shares
    );

    /**
     * @dev Emitted when `delegator` undelegated `tokens` from `indexer`.
     * Tokens get locked for withdrawal after a period of time.
     */
    event StakeDelegatedLocked(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens,
        uint256 shares,
        uint256 until
    );

    /**
     * @dev Emitted when `delegator` withdrew delegated `tokens` from `indexer`.
     */
    event StakeDelegatedWithdrawn(
        address indexed indexer,
        address indexed delegator,
        uint256 tokens
    );

    /**
     * @dev Emitted when `indexer` allocated `tokens` amount to `subgraphDeploymentID`
     * during `epoch`.
     * `allocationID` indexer derived address used to identify the allocation.
     * `metadata` additional information related to the allocation.
     */
    event AllocationCreated(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        bytes32 metadata
    );

    /**
     * @dev Emitted when `indexer` collected `tokens` amount in `epoch` for `allocationID`.
     * These funds are related to `subgraphDeploymentID`.
     * The `from` value is the sender of the collected funds.
     */
    event AllocationCollected(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        address from,
        uint256 curationFees,
        uint256 rebateFees
    );

    /**
     * @dev Emitted when `indexer` close an allocation in `epoch` for `allocationID`.
     * An amount of `tokens` get unallocated from `subgraphDeploymentID`.
     * The `effectiveAllocation` are the tokens allocated from creation to closing.
     * This event also emits the POI (proof of indexing) submitted by the indexer.
     * `isDelegator` is true if the sender was one of the indexer's delegators.
     */
    event AllocationClosed(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        uint256 effectiveAllocation,
        address sender,
        bytes32 poi,
        bool isDelegator
    );

    /**
     * @dev Emitted when `indexer` claimed a rebate on `subgraphDeploymentID` during `epoch`
     * related to the `forEpoch` rebate pool.
     * The rebate is for `tokens` amount and `unclaimedAllocationsCount` are left for claim
     * in the rebate pool. `delegationFees` collected and sent to delegation pool.
     */
    event RebateClaimed(
        address indexed indexer,
        bytes32 indexed subgraphDeploymentID,
        address indexed allocationID,
        uint256 epoch,
        uint256 forEpoch,
        uint256 tokens,
        uint256 unclaimedAllocationsCount,
        uint256 delegationFees
    );

    /**
     * @dev Emitted when `caller` set `slasher` address as `allowed` to slash stakes.
     */
    event SlasherUpdate(address indexed caller, address indexed slasher, bool allowed);

    /**
     * @dev Emitted when `caller` set `assetHolder` address as `allowed` to send funds
     * to staking contract.
     */
    event AssetHolderUpdate(address indexed caller, address indexed assetHolder, bool allowed);

    /**
     * @dev Emitted when `indexer` set `operator` access.
     */
    event SetOperator(address indexed indexer, address indexed operator, bool allowed);

    /**
     * @dev Check if the caller is the slasher.
     */
    modifier onlySlasher {
        require(slashers[msg.sender] == true, "!slasher");
        _;
    }

    /**
     * @dev Check if the caller is authorized (indexer or operator)
     */
    function _isAuth(address _indexer) private view returns (bool) {
        return msg.sender == _indexer || isOperator(msg.sender, _indexer) == true;
    }

    /**
     * @dev Initialize this contract.
     */
    function initialize(
        address _controller,
        uint256 _minimumIndexerStake,
        uint32 _thawingPeriod,
        uint32 _protocolPercentage,
        uint32 _curationPercentage,
        uint32 _channelDisputeEpochs,
        uint32 _maxAllocationEpochs,
        uint32 _delegationUnbondingPeriod,
        uint32 _delegationRatio,
        uint32 _rebateAlphaNumerator,
        uint32 _rebateAlphaDenominator
    ) external onlyImpl {
        Managed._initialize(_controller);

        // Settings
        _setMinimumIndexerStake(_minimumIndexerStake);
        _setThawingPeriod(_thawingPeriod);

        _setProtocolPercentage(_protocolPercentage);
        _setCurationPercentage(_curationPercentage);

        _setChannelDisputeEpochs(_channelDisputeEpochs);
        _setMaxAllocationEpochs(_maxAllocationEpochs);

        _setDelegationUnbondingPeriod(_delegationUnbondingPeriod);
        _setDelegationRatio(_delegationRatio);
        _setDelegationParametersCooldown(0);
        _setDelegationTaxPercentage(0);

        _setRebateRatio(_rebateAlphaNumerator, _rebateAlphaDenominator);
    }

    /**
     * @dev Set the minimum indexer stake required to.
     * @param _minimumIndexerStake Minimum indexer stake
     */
    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external override onlyGovernor {
        _setMinimumIndexerStake(_minimumIndexerStake);
    }

    /**
     * @dev Internal: Set the minimum indexer stake required.
     * @param _minimumIndexerStake Minimum indexer stake
     */
    function _setMinimumIndexerStake(uint256 _minimumIndexerStake) private {
        require(_minimumIndexerStake > 0, "!minimumIndexerStake");
        minimumIndexerStake = _minimumIndexerStake;
        emit ParameterUpdated("minimumIndexerStake");
    }

    /**
     * @dev Set the thawing period for unstaking.
     * @param _thawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function setThawingPeriod(uint32 _thawingPeriod) external override onlyGovernor {
        _setThawingPeriod(_thawingPeriod);
    }

    /**
     * @dev Internal: Set the thawing period for unstaking.
     * @param _thawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function _setThawingPeriod(uint32 _thawingPeriod) private {
        require(_thawingPeriod > 0, "!thawingPeriod");
        thawingPeriod = _thawingPeriod;
        emit ParameterUpdated("thawingPeriod");
    }

    /**
     * @dev Set the curation percentage of query fees sent to curators.
     * @param _percentage Percentage of query fees sent to curators
     */
    function setCurationPercentage(uint32 _percentage) external override onlyGovernor {
        _setCurationPercentage(_percentage);
    }

    /**
     * @dev Internal: Set the curation percentage of query fees sent to curators.
     * @param _percentage Percentage of query fees sent to curators
     */
    function _setCurationPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, ">percentage");
        curationPercentage = _percentage;
        emit ParameterUpdated("curationPercentage");
    }

    /**
     * @dev Set a protocol percentage to burn when collecting query fees.
     * @param _percentage Percentage of query fees to burn as protocol fee
     */
    function setProtocolPercentage(uint32 _percentage) external override onlyGovernor {
        _setProtocolPercentage(_percentage);
    }

    /**
     * @dev Internal: Set a protocol percentage to burn when collecting query fees.
     * @param _percentage Percentage of query fees to burn as protocol fee
     */
    function _setProtocolPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, ">percentage");
        protocolPercentage = _percentage;
        emit ParameterUpdated("protocolPercentage");
    }

    /**
     * @dev Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * @param _channelDisputeEpochs Period in epochs
     */
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external override onlyGovernor {
        _setChannelDisputeEpochs(_channelDisputeEpochs);
    }

    /**
     * @dev Internal: Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * @param _channelDisputeEpochs Period in epochs
     */
    function _setChannelDisputeEpochs(uint32 _channelDisputeEpochs) private {
        require(_channelDisputeEpochs > 0, "!channelDisputeEpochs");
        channelDisputeEpochs = _channelDisputeEpochs;
        emit ParameterUpdated("channelDisputeEpochs");
    }

    /**
     * @dev Set the max time allowed for indexers stake on allocations.
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external override onlyGovernor {
        _setMaxAllocationEpochs(_maxAllocationEpochs);
    }

    /**
     * @dev Internal: Set the max time allowed for indexers stake on allocations.
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function _setMaxAllocationEpochs(uint32 _maxAllocationEpochs) private {
        maxAllocationEpochs = _maxAllocationEpochs;
        emit ParameterUpdated("maxAllocationEpochs");
    }

    /**
     * @dev Set the rebate ratio (fees to allocated stake).
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator)
        external
        override
        onlyGovernor
    {
        _setRebateRatio(_alphaNumerator, _alphaDenominator);
    }

    /**
     * @dev Set the rebate ratio (fees to allocated stake).
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function _setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) private {
        require(_alphaNumerator > 0 && _alphaDenominator > 0, "!alpha");
        alphaNumerator = _alphaNumerator;
        alphaDenominator = _alphaDenominator;
        emit ParameterUpdated("rebateRatio");
    }

    /**
     * @dev Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @param _delegationRatio Delegation capacity multiplier
     */
    function setDelegationRatio(uint32 _delegationRatio) external override onlyGovernor {
        _setDelegationRatio(_delegationRatio);
    }

    /**
     * @dev Internal: Set the delegation ratio.
     * If set to 10 it means the indexer can use up to 10x the indexer staked amount
     * from their delegated tokens
     * @param _delegationRatio Delegation capacity multiplier
     */
    function _setDelegationRatio(uint32 _delegationRatio) private {
        delegationRatio = _delegationRatio;
        emit ParameterUpdated("delegationRatio");
    }

    /**
     * @dev Set the delegation parameters.
     * @param _indexingRewardCut Percentage of indexing rewards left for delegators
     * @param _queryFeeCut Percentage of query fees left for delegators
     * @param _cooldownBlocks Period that need to pass to update delegation parameters
     */
    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) public override {
        address indexer = msg.sender;

        // Incentives must be within bounds
        require(_queryFeeCut <= MAX_PPM, ">queryFeeCut");
        require(_indexingRewardCut <= MAX_PPM, ">indexingRewardCut");

        // Cooldown period set by indexer cannot be below protocol global setting
        require(_cooldownBlocks >= delegationParametersCooldown, "<cooldown");

        // Verify the cooldown period passed
        DelegationPool storage pool = delegationPools[indexer];
        require(
            pool.updatedAtBlock == 0 ||
                pool.updatedAtBlock.add(uint256(pool.cooldownBlocks)) <= block.number,
            "!cooldown"
        );

        // Update delegation params
        pool.indexingRewardCut = _indexingRewardCut;
        pool.queryFeeCut = _queryFeeCut;
        pool.cooldownBlocks = _cooldownBlocks;
        pool.updatedAtBlock = block.number;

        emit DelegationParametersUpdated(
            indexer,
            _indexingRewardCut,
            _queryFeeCut,
            _cooldownBlocks
        );
    }

    /**
     * @dev Set the time in blocks an indexer needs to wait to change delegation parameters.
     * @param _blocks Number of blocks to set the delegation parameters cooldown period
     */
    function setDelegationParametersCooldown(uint32 _blocks) external override onlyGovernor {
        _setDelegationParametersCooldown(_blocks);
    }

    /**
     * @dev Internal: Set the time in blocks an indexer needs to wait to change delegation parameters.
     * @param _blocks Number of blocks to set the delegation parameters cooldown period
     */
    function _setDelegationParametersCooldown(uint32 _blocks) private {
        delegationParametersCooldown = _blocks;
        emit ParameterUpdated("delegationParametersCooldown");
    }

    /**
     * @dev Set the period for undelegation of stake from indexer.
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod)
        external
        override
        onlyGovernor
    {
        _setDelegationUnbondingPeriod(_delegationUnbondingPeriod);
    }

    /**
     * @dev Internal: Set the period for undelegation of stake from indexer.
     * @param _delegationUnbondingPeriod Period in epochs to wait for token withdrawals after undelegating
     */
    function _setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) private {
        require(_delegationUnbondingPeriod > 0, "!delegationUnbondingPeriod");
        delegationUnbondingPeriod = _delegationUnbondingPeriod;
        emit ParameterUpdated("delegationUnbondingPeriod");
    }

    /**
     * @dev Set a delegation tax percentage to burn when delegated funds are deposited.
     * @param _percentage Percentage of delegated tokens to burn as delegation tax
     */
    function setDelegationTaxPercentage(uint32 _percentage) external override onlyGovernor {
        _setDelegationTaxPercentage(_percentage);
    }

    /**
     * @dev Internal: Set a delegation tax percentage to burn when delegated funds are deposited.
     * @param _percentage Percentage of delegated tokens to burn as delegation tax
     */
    function _setDelegationTaxPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, ">percentage");
        delegationTaxPercentage = _percentage;
        emit ParameterUpdated("delegationTaxPercentage");
    }

    /**
     * @dev Set or unset an address as allowed slasher.
     * @param _slasher Address of the party allowed to slash indexers
     * @param _allowed True if slasher is allowed
     */
    function setSlasher(address _slasher, bool _allowed) external override onlyGovernor {
        require(_slasher != address(0), "!slasher");
        slashers[_slasher] = _allowed;
        emit SlasherUpdate(msg.sender, _slasher, _allowed);
    }

    /**
     * @dev Set an address as allowed asset holder.
     * @param _assetHolder Address of allowed source for state channel funds
     * @param _allowed True if asset holder is allowed
     */
    function setAssetHolder(address _assetHolder, bool _allowed) external override onlyGovernor {
        require(_assetHolder != address(0), "!assetHolder");
        assetHolders[_assetHolder] = _allowed;
        emit AssetHolderUpdate(msg.sender, _assetHolder, _allowed);
    }

    /**
     * @dev Return if allocationID is used.
     * @param _allocationID Address used as signer by the indexer for an allocation
     * @return True if allocationID already used
     */
    function isAllocation(address _allocationID) external override view returns (bool) {
        return _getAllocationState(_allocationID) != AllocationState.Null;
    }

    /**
     * @dev Getter that returns if an indexer has any stake.
     * @param _indexer Address of the indexer
     * @return True if indexer has staked tokens
     */
    function hasStake(address _indexer) external override view returns (bool) {
        return stakes[_indexer].hasTokens();
    }

    /**
     * @dev Return the allocation by ID.
     * @param _allocationID Address used as allocation identifier
     * @return Allocation data
     */
    function getAllocation(address _allocationID)
        external
        override
        view
        returns (Allocation memory)
    {
        return allocations[_allocationID];
    }

    /**
     * @dev Return the current state of an allocation.
     * @param _allocationID Address used as the allocation identifier
     * @return AllocationState
     */
    function getAllocationState(address _allocationID)
        external
        override
        view
        returns (AllocationState)
    {
        return _getAllocationState(_allocationID);
    }

    /**
     * @dev Return the total amount of tokens allocated to subgraph.
     * @param _subgraphDeploymentID Address used as the allocation identifier
     * @return Total tokens allocated to subgraph
     */
    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        override
        view
        returns (uint256)
    {
        return subgraphAllocations[_subgraphDeploymentID];
    }

    /**
     * @dev Return the delegation from a delegator to an indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return Delegation data
     */
    function getDelegation(address _indexer, address _delegator)
        external
        override
        view
        returns (Delegation memory)
    {
        return delegationPools[_indexer].delegators[_delegator];
    }

    /**
     * @dev Return whether the delegator has delegated to the indexer.
     * @param _indexer Address of the indexer where funds have been delegated
     * @param _delegator Address of the delegator
     * @return True if delegator of indexer
     */
    function isDelegator(address _indexer, address _delegator) public override view returns (bool) {
        return delegationPools[_indexer].delegators[_delegator].shares > 0;
    }

    /**
     * @dev Get the total amount of tokens staked by the indexer.
     * @param _indexer Address of the indexer
     * @return Amount of tokens staked by the indexer
     */
    function getIndexerStakedTokens(address _indexer) external override view returns (uint256) {
        return stakes[_indexer].tokensStaked;
    }

    /**
     * @dev Get the total amount of tokens available to use in allocations.
     * This considers the indexer stake and delegated tokens according to delegation ratio
     * @param _indexer Address of the indexer
     * @return Amount of tokens staked by the indexer
     */
    function getIndexerCapacity(address _indexer) public override view returns (uint256) {
        Stakes.Indexer memory indexerStake = stakes[_indexer];
        uint256 tokensDelegated = delegationPools[_indexer].tokens;

        uint256 tokensDelegatedCap = indexerStake.tokensSecureStake().mul(uint256(delegationRatio));
        uint256 tokensDelegatedCapacity = (tokensDelegated < tokensDelegatedCap)
            ? tokensDelegated
            : tokensDelegatedCap;

        return indexerStake.tokensAvailableWithDelegation(tokensDelegatedCapacity);
    }

    /**
     * @dev Returns amount of delegated tokens ready to be withdrawn after unbonding period.
     * @param _delegation Delegation of tokens from delegator to indexer
     * @return Amount of tokens to withdraw
     */
    function getWithdraweableDelegatedTokens(Delegation memory _delegation)
        public
        view
        returns (uint256)
    {
        // There must be locked tokens and period passed
        uint256 currentEpoch = epochManager().currentEpoch();
        if (_delegation.tokensLockedUntil > 0 && currentEpoch >= _delegation.tokensLockedUntil) {
            return _delegation.tokensLocked;
        }
        return 0;
    }

    /**
     * @dev Authorize or unauthorize an address to be an operator.
     * @param _operator Address to authorize
     * @param _allowed Whether authorized or not
     */
    function setOperator(address _operator, bool _allowed) external override {
        require(_operator != msg.sender, "operator == sender");
        operatorAuth[msg.sender][_operator] = _allowed;
        emit SetOperator(msg.sender, _operator, _allowed);
    }

    /**
     * @dev Return true if operator is allowed for indexer.
     * @param _operator Address of the operator
     * @param _indexer Address of the indexer
     */
    function isOperator(address _operator, address _indexer) public override view returns (bool) {
        return operatorAuth[_indexer][_operator];
    }

    /**
     * @dev Deposit tokens on the indexer stake.
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _tokens) external override {
        stakeTo(msg.sender, _tokens);
    }

    /**
     * @dev Deposit tokens on the indexer stake.
     * @param _indexer Address of the indexer
     * @param _tokens Amount of tokens to stake
     */
    function stakeTo(address _indexer, uint256 _tokens) public override notPartialPaused {
        require(_tokens > 0, "!tokens");

        // Ensure minimum stake
        require(
            stakes[_indexer].tokensSecureStake().add(_tokens) >= minimumIndexerStake,
            "!minimumIndexerStake"
        );

        // Transfer tokens to stake from caller to this contract
        require(graphToken().transferFrom(msg.sender, address(this), _tokens), "!transfer");

        // Stake the transferred tokens
        _stake(_indexer, _tokens);
    }

    /**
     * @dev Unstake tokens from the indexer stake, lock them until thawing period expires.
     * @param _tokens Amount of tokens to unstake
     */
    function unstake(uint256 _tokens) external override notPartialPaused {
        address indexer = msg.sender;
        Stakes.Indexer storage indexerStake = stakes[indexer];

        require(_tokens > 0, "!tokens");
        require(indexerStake.hasTokens(), "!stake");
        require(indexerStake.tokensAvailable() >= _tokens, "!stake-avail");

        // Ensure minimum stake
        uint256 newStake = indexerStake.tokensSecureStake().sub(_tokens);
        require(newStake == 0 || newStake >= minimumIndexerStake, "!minimumIndexerStake");

        // Before locking more tokens, withdraw any unlocked ones
        uint256 tokensToWithdraw = indexerStake.tokensWithdrawable();
        if (tokensToWithdraw > 0) {
            _withdraw(indexer);
        }

        indexerStake.lockTokens(_tokens, thawingPeriod);

        emit StakeLocked(indexer, indexerStake.tokensLocked, indexerStake.tokensLockedUntil);
    }

    /**
     * @dev Withdraw indexer tokens once the thawing period has passed.
     */
    function withdraw() external override notPaused {
        _withdraw(msg.sender);
    }

    /**
     * @dev Slash the indexer stake. Delegated tokens are not subject to slashing.
     * Can only be called by the slasher role.
     * @param _indexer Address of indexer to slash
     * @param _tokens Amount of tokens to slash from the indexer stake
     * @param _reward Amount of reward tokens to send to a beneficiary
     * @param _beneficiary Address of a beneficiary to receive a reward for the slashing
     */
    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external override onlySlasher notPartialPaused {
        Stakes.Indexer storage indexerStake = stakes[_indexer];

        // Only able to slash a non-zero number of tokens
        require(_tokens > 0, "!tokens");

        // Rewards comes from tokens slashed balance
        require(_tokens >= _reward, "rewards>slash");

        // Cannot slash stake of an indexer without any or enough stake
        require(indexerStake.hasTokens(), "!stake");
        require(_tokens <= indexerStake.tokensStaked, "slash>stake");

        // Validate beneficiary of slashed tokens
        require(_beneficiary != address(0), "!beneficiary");

        // Slashing more tokens than freely available (over allocation condition)
        // Unlock locked tokens to avoid the indexer to withdraw them
        if (_tokens > indexerStake.tokensAvailable() && indexerStake.tokensLocked > 0) {
            uint256 tokensOverAllocated = _tokens.sub(indexerStake.tokensAvailable());
            uint256 tokensToUnlock = (tokensOverAllocated > indexerStake.tokensLocked)
                ? indexerStake.tokensLocked
                : tokensOverAllocated;
            indexerStake.unlockTokens(tokensToUnlock);
        }

        // Remove tokens to slash from the stake
        indexerStake.release(_tokens);

        // -- Interactions --

        IGraphToken graphToken = graphToken();

        // Set apart the reward for the beneficiary and burn remaining slashed stake
        _burnTokens(graphToken, _tokens.sub(_reward));

        // Give the beneficiary a reward for slashing
        if (_reward > 0) {
            require(graphToken.transfer(_beneficiary, _reward), "!transfer");
        }

        emit StakeSlashed(_indexer, _tokens, _reward, _beneficiary);
    }

    /**
     * @dev Delegate tokens to an indexer.
     * @param _indexer Address of the indexer to delegate tokens to
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued of the delegation pool
     */
    function delegate(address _indexer, uint256 _tokens)
        external
        override
        notPartialPaused
        returns (uint256)
    {
        address delegator = msg.sender;

        // Transfer tokens to delegate to this contract
        require(graphToken().transferFrom(delegator, address(this), _tokens), "!transfer");

        // Update state
        return _delegate(delegator, _indexer, _tokens);
    }

    /**
     * @dev Undelegate tokens from an indexer.
     * @param _indexer Address of the indexer where tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function undelegate(address _indexer, uint256 _shares)
        external
        override
        notPartialPaused
        returns (uint256)
    {
        return _undelegate(msg.sender, _indexer, _shares);
    }

    /**
     * @dev Withdraw delegated tokens once the unbonding period has passed.
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _delegateToIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     */
    function withdrawDelegated(address _indexer, address _delegateToIndexer)
        external
        override
        notPaused
        returns (uint256)
    {
        return _withdrawDelegated(msg.sender, _indexer, _delegateToIndexer);
    }

    /**
     * @dev Allocate available tokens to a subgraph deployment.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external override notPaused {
        _allocate(msg.sender, _subgraphDeploymentID, _tokens, _allocationID, _metadata, _proof);
    }

    /**
     * @dev Allocate available tokens to a subgraph deployment.
     * @param _indexer Indexer address to allocate funds from.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external override notPaused {
        _allocate(_indexer, _subgraphDeploymentID, _tokens, _allocationID, _metadata, _proof);
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * To be eligible for rewards a proof of indexing must be presented.
     * Presenting a bad proof is subject to slashable condition.
     * To opt out for rewards set _poi to 0x0
     * @param _allocationID The allocation identifier
     * @param _poi Proof of indexing submitted for the allocated period
     */
    function closeAllocation(address _allocationID, bytes32 _poi) external override notPaused {
        _closeAllocation(_allocationID, _poi);
    }

    /**
     * @dev Close multiple allocations and free the staked tokens.
     * To be eligible for rewards a proof of indexing must be presented.
     * Presenting a bad proof is subject to slashable condition.
     * To opt out for rewards set _poi to 0x0
     * @param _requests An array of CloseAllocationRequest
     */
    function closeAllocationMany(CloseAllocationRequest[] calldata _requests)
        external
        override
        notPaused
    {
        for (uint256 i = 0; i < _requests.length; i++) {
            _closeAllocation(_requests[i].allocationID, _requests[i].poi);
        }
    }

    /**
     * @dev Close and allocate. This will perform a close and then create a new Allocation
     * atomically on the same transaction.
     * @param _closingAllocationID The identifier of the allocation to be closed
     * @param _poi Proof of indexing submitted for the allocated period
     * @param _indexer Indexer address to allocate funds from.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocation identifier
     * @param _metadata IPFS hash for additional information about the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function closeAndAllocate(
        address _closingAllocationID,
        bytes32 _poi,
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external override notPaused {
        _closeAllocation(_closingAllocationID, _poi);
        _allocate(_indexer, _subgraphDeploymentID, _tokens, _allocationID, _metadata, _proof);
    }

    /**
     * @dev Collect query fees for an allocation from state channels.
     * Funds received are only accepted from a valid sender.
     * @param _tokens Amount of tokens to collect
     * @param _allocationID Allocation where the tokens will be assigned
     */
    function collect(uint256 _tokens, address _allocationID) external override {
        // Allocation identifier validation
        require(_allocationID != address(0), "!alloc");

        // The contract caller must be an authorized asset holder
        require(assetHolders[msg.sender] == true, "!assetHolder");

        // Allocation must exist
        AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState != AllocationState.Null, "!collect");

        // Get allocation
        Allocation storage alloc = allocations[_allocationID];
        uint256 queryFees = _tokens;
        uint256 curationFees = 0;
        bytes32 subgraphDeploymentID = alloc.subgraphDeploymentID;

        // Process query fees only if non-zero amount
        if (queryFees > 0) {
            // Pull tokens to collect from the authorized sender
            IGraphToken graphToken = graphToken();
            require(graphToken.transferFrom(msg.sender, address(this), _tokens), "!transfer");

            // -- Collect protocol tax --
            // If the Allocation is not active or closed we are going to charge a 100% protocol tax
            uint256 usedProtocolPercentage = (allocState == AllocationState.Active ||
                allocState == AllocationState.Closed)
                ? protocolPercentage
                : MAX_PPM;
            uint256 protocolTax = _collectTax(graphToken, queryFees, usedProtocolPercentage);
            queryFees = queryFees.sub(protocolTax);

            // -- Collect curation fees --
            // Only if the subgraph deployment is curated
            curationFees = _collectCurationFees(
                graphToken,
                subgraphDeploymentID,
                queryFees,
                curationPercentage
            );
            queryFees = queryFees.sub(curationFees);

            // Add funds to the allocation
            alloc.collectedFees = alloc.collectedFees.add(queryFees);

            // When allocation is closed redirect funds to the rebate pool
            // This way we can keep collecting tokens even after the allocation is closed and
            // before it gets to the finalized state.
            if (allocState == AllocationState.Closed) {
                Rebates.Pool storage rebatePool = rebates[alloc.closedAtEpoch];
                rebatePool.fees = rebatePool.fees.add(queryFees);
            }
        }

        emit AllocationCollected(
            alloc.indexer,
            subgraphDeploymentID,
            epochManager().currentEpoch(),
            _tokens,
            _allocationID,
            msg.sender,
            curationFees,
            queryFees
        );
    }

    /**
     * @dev Claim tokens from the rebate pool.
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function claim(address _allocationID, bool _restake) external override notPaused {
        _claim(_allocationID, _restake);
    }

    /**
     * @dev Claim tokens from the rebate pool for many allocations.
     * @param _allocationID Array of allocations from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function claimMany(address[] calldata _allocationID, bool _restake)
        external
        override
        notPaused
    {
        for (uint256 i = 0; i < _allocationID.length; i++) {
            _claim(_allocationID[i], _restake);
        }
    }

    /**
     * @dev Stake tokens on the indexer.
     * This function does not check minimum indexer stake requirement to allow
     * to be called by functions that increase the stake when collecting rewards
     * without reverting
     * @param _indexer Address of staking party
     * @param _tokens Amount of tokens to stake
     */
    function _stake(address _indexer, uint256 _tokens) private {
        // Deposit tokens into the indexer stake
        stakes[_indexer].deposit(_tokens);

        // Initialize the delegation pool the first time
        if (delegationPools[_indexer].updatedAtBlock == 0) {
            setDelegationParameters(MAX_PPM, MAX_PPM, delegationParametersCooldown);
        }

        emit StakeDeposited(_indexer, _tokens);
    }

    /**
     * @dev Withdraw indexer tokens once the thawing period has passed.
     * @param _indexer Address of indexer to withdraw funds from
     */
    function _withdraw(address _indexer) private {
        // Get tokens available for withdraw and update balance
        uint256 tokensToWithdraw = stakes[_indexer].withdrawTokens();
        require(tokensToWithdraw > 0, "!tokens");

        // Return tokens to the indexer
        require(graphToken().transfer(_indexer, tokensToWithdraw), "!transfer");

        emit StakeWithdrawn(_indexer, tokensToWithdraw);
    }

    /**
     * @dev Allocate available tokens to a subgraph deployment.
     * @param _indexer Indexer address to allocate funds from.
     * @param _subgraphDeploymentID ID of the SubgraphDeployment where tokens will be allocated
     * @param _tokens Amount of tokens to allocate
     * @param _allocationID The allocationID will work to identify collected funds related to this allocation
     * @param _metadata Metadata related to the allocation
     * @param _proof A 65-bytes Ethereum signed message of `keccak256(indexerAddress,allocationID)`
     */
    function _allocate(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) private {
        require(_isAuth(_indexer), "!auth");

        // Only allocations with a non-zero token amount are allowed
        require(_tokens > 0, "!tokens");

        // Check allocation
        require(_allocationID != address(0), "!alloc");
        require(_getAllocationState(_allocationID) == AllocationState.Null, "!null");

        // Caller must prove that they own the private key for the allocationID adddress
        // The proof is an Ethereum signed message of KECCAK256(indexerAddress,allocationID)
        bytes32 messageHash = keccak256(abi.encodePacked(_indexer, _allocationID));
        bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
        require(ECDSA.recover(digest, _proof) == _allocationID, "!proof");

        // Needs to have free capacity not used for other purposes to allocate
        require(getIndexerCapacity(_indexer) >= _tokens, "!capacity");

        // Creates an allocation
        // Allocation identifiers are not reused
        // The assetHolder address can send collected funds to the allocation
        Allocation memory alloc = Allocation(
            _indexer,
            _subgraphDeploymentID,
            _tokens, // Tokens allocated
            epochManager().currentEpoch(), // createdAtEpoch
            0, // closedAtEpoch
            0, // Initialize collected fees
            0, // Initialize effective allocation
            _updateRewards(_subgraphDeploymentID) // Initialize accumulated rewards per stake allocated
        );
        allocations[_allocationID] = alloc;

        // Mark allocated tokens as used
        stakes[_indexer].allocate(alloc.tokens);

        // Track total allocations per subgraph
        // Used for rewards calculations
        subgraphAllocations[alloc.subgraphDeploymentID] = subgraphAllocations[alloc
            .subgraphDeploymentID]
            .add(alloc.tokens);

        emit AllocationCreated(
            _indexer,
            _subgraphDeploymentID,
            alloc.createdAtEpoch,
            alloc.tokens,
            _allocationID,
            _metadata
        );
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * @param _allocationID The allocation identifier
     * @param _poi Proof of indexing submitted for the allocated period
     */
    function _closeAllocation(address _allocationID, bytes32 _poi) private {
        // Allocation must exist and be active
        AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == AllocationState.Active, "!active");

        // Get allocation
        Allocation memory alloc = allocations[_allocationID];

        // Validate that an allocation cannot be closed before one epoch
        alloc.closedAtEpoch = epochManager().currentEpoch();
        uint256 epochs = alloc.createdAtEpoch < alloc.closedAtEpoch
            ? alloc.closedAtEpoch.sub(alloc.createdAtEpoch)
            : 0;
        require(epochs > 0, "<epochs");

        // Indexer or operator can close an allocation
        // Delegators are also allowed but only after maxAllocationEpochs passed
        bool isIndexer = _isAuth(alloc.indexer);
        if (epochs > maxAllocationEpochs) {
            require(isIndexer || isDelegator(alloc.indexer, msg.sender), "!auth-or-del");
        } else {
            require(isIndexer, "!auth");
        }

        // Calculate effective allocation for the amount of epochs it remained allocated
        alloc.effectiveAllocation = _getEffectiveAllocation(
            maxAllocationEpochs,
            alloc.tokens,
            epochs
        );

        // Close the allocation and start counting a period to settle remaining payments from
        // state channels.
        allocations[_allocationID].closedAtEpoch = alloc.closedAtEpoch;
        allocations[_allocationID].effectiveAllocation = alloc.effectiveAllocation;

        // Account collected fees and effective allocation in rebate pool for the epoch
        Rebates.Pool storage rebatePool = rebates[alloc.closedAtEpoch];
        if (!rebatePool.exists()) {
            rebatePool.init(alphaNumerator, alphaDenominator);
        }
        rebatePool.addToPool(alloc.collectedFees, alloc.effectiveAllocation);

        // Distribute rewards if proof of indexing was presented by the indexer or operator
        if (isIndexer && _poi != 0) {
            _distributeRewards(_allocationID, alloc.indexer);
        }

        // Free allocated tokens from use
        stakes[alloc.indexer].unallocate(alloc.tokens);

        // Track total allocations per subgraph
        // Used for rewards calculations
        subgraphAllocations[alloc.subgraphDeploymentID] = subgraphAllocations[alloc
            .subgraphDeploymentID]
            .sub(alloc.tokens);

        emit AllocationClosed(
            alloc.indexer,
            alloc.subgraphDeploymentID,
            alloc.closedAtEpoch,
            alloc.tokens,
            _allocationID,
            alloc.effectiveAllocation,
            msg.sender,
            _poi,
            !isIndexer
        );
    }

    /**
     * @dev Claim tokens from the rebate pool.
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function _claim(address _allocationID, bool _restake) private {
        // Funds can only be claimed after a period of time passed since allocation was closed
        AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == AllocationState.Finalized, "!finalized");

        // Get allocation
        Allocation memory alloc = allocations[_allocationID];

        // Only the indexer or operator can decide if to restake
        bool restake = _isAuth(alloc.indexer) ? _restake : false;

        // Process rebate reward
        Rebates.Pool storage rebatePool = rebates[alloc.closedAtEpoch];
        uint256 tokensToClaim = rebatePool.redeem(alloc.collectedFees, alloc.effectiveAllocation);

        // Add delegation rewards to the delegation pool
        uint256 delegationRewards = _collectDelegationQueryRewards(alloc.indexer, tokensToClaim);
        tokensToClaim = tokensToClaim.sub(delegationRewards);

        // Purge allocation data except for:
        // - indexer: used in disputes and to avoid reusing an allocationID
        // - subgraphDeploymentID: used in disputes
        allocations[_allocationID].tokens = 0; // This avoid collect(), close() and claim() to be called
        allocations[_allocationID].createdAtEpoch = 0;
        allocations[_allocationID].closedAtEpoch = 0;
        allocations[_allocationID].collectedFees = 0;
        allocations[_allocationID].effectiveAllocation = 0;
        allocations[_allocationID].accRewardsPerAllocatedToken = 0;

        // -- Interactions --

        IGraphToken graphToken = graphToken();

        // When all allocations processed then burn unclaimed fees and prune rebate pool
        if (rebatePool.unclaimedAllocationsCount == 0) {
            _burnTokens(graphToken, rebatePool.unclaimedFees());
            delete rebates[alloc.closedAtEpoch];
        }

        // When there are tokens to claim from the rebate pool, transfer or restake
        if (tokensToClaim > 0) {
            // Assign claimed tokens
            if (restake) {
                // Restake to place fees into the indexer stake
                _stake(alloc.indexer, tokensToClaim);
            } else {
                // Transfer funds back to the indexer
                require(graphToken.transfer(alloc.indexer, tokensToClaim), "!transfer");
            }
        }

        emit RebateClaimed(
            alloc.indexer,
            alloc.subgraphDeploymentID,
            _allocationID,
            epochManager().currentEpoch(),
            alloc.closedAtEpoch,
            tokensToClaim,
            rebatePool.unclaimedAllocationsCount,
            delegationRewards
        );
    }

    /**
     * @dev Delegate tokens to an indexer.
     * @param _delegator Address of the delegator
     * @param _indexer Address of the indexer to delegate tokens to
     * @param _tokens Amount of tokens to delegate
     * @return Amount of shares issued of the delegation pool
     */
    function _delegate(
        address _delegator,
        address _indexer,
        uint256 _tokens
    ) private returns (uint256) {
        // Only delegate a non-zero amount of tokens
        require(_tokens > 0, "!tokens");
        // Only delegate to non-empty address
        require(_indexer != address(0), "!indexer");
        // Only delegate to staked indexer
        require(stakes[_indexer].hasTokens(), "!stake");

        // Get the delegation pool of the indexer
        DelegationPool storage pool = delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Collect delegation tax
        uint256 delegationTax = _collectTax(graphToken(), _tokens, delegationTaxPercentage);
        uint256 delegatedTokens = _tokens.sub(delegationTax);

        // Calculate shares to issue
        uint256 shares = (pool.tokens == 0)
            ? delegatedTokens
            : delegatedTokens.mul(pool.shares).div(pool.tokens);

        // Update the delegation pool
        pool.tokens = pool.tokens.add(delegatedTokens);
        pool.shares = pool.shares.add(shares);

        // Update the delegation
        delegation.shares = delegation.shares.add(shares);

        emit StakeDelegated(_indexer, _delegator, delegatedTokens, shares);

        return shares;
    }

    /**
     * @dev Undelegate tokens from an indexer.
     * @param _delegator Address of the delegator
     * @param _indexer Address of the indexer where tokens had been delegated
     * @param _shares Amount of shares to return and undelegate tokens
     * @return Amount of tokens returned for the shares of the delegation pool
     */
    function _undelegate(
        address _delegator,
        address _indexer,
        uint256 _shares
    ) private returns (uint256) {
        // Can only undelegate a non-zero amount of shares
        require(_shares > 0, "!shares");

        // Get the delegation pool of the indexer
        DelegationPool storage pool = delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Delegator need to have enough shares in the pool to undelegate
        require(delegation.shares >= _shares, "!shares-avail");

        // Withdraw tokens if available
        if (getWithdraweableDelegatedTokens(delegation) > 0) {
            _withdrawDelegated(_delegator, _indexer, address(0));
        }

        // Calculate tokens to get in exchange for the shares
        uint256 tokens = _shares.mul(pool.tokens).div(pool.shares);

        // Update the delegation pool
        pool.tokens = pool.tokens.sub(tokens);
        pool.shares = pool.shares.sub(_shares);

        // Update the delegation
        delegation.shares = delegation.shares.sub(_shares);
        delegation.tokensLocked = delegation.tokensLocked.add(tokens);
        delegation.tokensLockedUntil = epochManager().currentEpoch().add(delegationUnbondingPeriod);

        emit StakeDelegatedLocked(
            _indexer,
            _delegator,
            tokens,
            _shares,
            delegation.tokensLockedUntil
        );

        return tokens;
    }

    /**
     * @dev Withdraw delegated tokens once the unbonding period has passed.
     * @param _delegator Delegator that is withdrawing tokens
     * @param _indexer Withdraw available tokens delegated to indexer
     * @param _delegateToIndexer Re-delegate to indexer address if non-zero, withdraw if zero address
     */
    function _withdrawDelegated(
        address _delegator,
        address _indexer,
        address _delegateToIndexer
    ) private returns (uint256) {
        // Get the delegation pool of the indexer
        DelegationPool storage pool = delegationPools[_indexer];
        Delegation storage delegation = pool.delegators[_delegator];

        // Validation
        uint256 tokensToWithdraw = getWithdraweableDelegatedTokens(delegation);
        require(tokensToWithdraw > 0, "!tokens");

        // Reset lock
        delegation.tokensLocked = 0;
        delegation.tokensLockedUntil = 0;

        emit StakeDelegatedWithdrawn(_indexer, _delegator, tokensToWithdraw);

        // -- Interactions --

        if (_delegateToIndexer != address(0)) {
            // Re-delegate tokens to a new indexer
            _delegate(_delegator, _delegateToIndexer, tokensToWithdraw);
        } else {
            // Return tokens to the delegator
            require(graphToken().transfer(_delegator, tokensToWithdraw), "!transfer");
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Collect the delegation rewards for query fees.
     * This function will assign the collected fees to the delegation pool.
     * @param _indexer Indexer to which the tokens to distribute are related
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @return Amount of delegation rewards
     */
    function _collectDelegationQueryRewards(address _indexer, uint256 _tokens)
        private
        returns (uint256)
    {
        uint256 delegationRewards = 0;
        DelegationPool storage pool = delegationPools[_indexer];
        if (pool.tokens > 0 && pool.queryFeeCut < MAX_PPM) {
            uint256 indexerCut = uint256(pool.queryFeeCut).mul(_tokens).div(MAX_PPM);
            delegationRewards = _tokens.sub(indexerCut);
            pool.tokens = pool.tokens.add(delegationRewards);
        }
        return delegationRewards;
    }

    /**
     * @dev Collect the delegation rewards for indexing.
     * This function will assign the collected fees to the delegation pool.
     * @param _indexer Indexer to which the tokens to distribute are related
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @return Amount of delegation rewards
     */
    function _collectDelegationIndexingRewards(address _indexer, uint256 _tokens)
        private
        returns (uint256)
    {
        uint256 delegationRewards = 0;
        DelegationPool storage pool = delegationPools[_indexer];
        if (pool.tokens > 0 && pool.indexingRewardCut < MAX_PPM) {
            uint256 indexerCut = uint256(pool.indexingRewardCut).mul(_tokens).div(MAX_PPM);
            delegationRewards = _tokens.sub(indexerCut);
            pool.tokens = pool.tokens.add(delegationRewards);
        }
        return delegationRewards;
    }

    /**
     * @dev Collect the curation fees for a subgraph deployment from an amount of tokens.
     * This function transfer curation fees to the Curation contract by calling Curation.collect
     * @param _graphToken Token to collect
     * @param _subgraphDeploymentID Subgraph deployment to which the curation fees are related
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @param _curationPercentage Percentage of tokens to collect as fees
     * @return Amount of curation fees
     */
    function _collectCurationFees(
        IGraphToken _graphToken,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        uint256 _curationPercentage
    ) private returns (uint256) {
        if (_tokens == 0) {
            return 0;
        }

        ICuration curation = curation();
        bool isCurationEnabled = _curationPercentage > 0 && address(curation) != address(0);

        if (isCurationEnabled && curation.isCurated(_subgraphDeploymentID)) {
            uint256 curationFees = uint256(_curationPercentage).mul(_tokens).div(MAX_PPM);
            if (curationFees > 0) {
                // Transfer and call collect()
                // This function transfer tokens to a trusted protocol contracts
                // Then we call collect() to do the transfer bookeeping
                require(_graphToken.transfer(address(curation), curationFees), "!transfer");
                curation.collect(_subgraphDeploymentID, curationFees);
            }
            return curationFees;
        }
        return 0;
    }

    /**
     * @dev Collect tax to burn for an amount of tokens.
     * @param _graphToken Token to burn
     * @param _tokens Total tokens received used to calculate the amount of tax to collect
     * @param _percentage Percentage of tokens to burn as tax
     * @return Amount of tax charged
     */
    function _collectTax(
        IGraphToken _graphToken,
        uint256 _tokens,
        uint256 _percentage
    ) private returns (uint256) {
        uint256 tax = uint256(_percentage).mul(_tokens).div(MAX_PPM);
        _burnTokens(_graphToken, tax); // Burn tax if any
        return tax;
    }

    /**
     * @dev Return the current state of an allocation
     * @param _allocationID Allocation identifier
     * @return AllocationState
     */
    function _getAllocationState(address _allocationID) private view returns (AllocationState) {
        Allocation storage alloc = allocations[_allocationID];

        if (alloc.indexer == address(0)) {
            return AllocationState.Null;
        }
        if (alloc.tokens == 0) {
            return AllocationState.Claimed;
        }

        uint256 closedAtEpoch = alloc.closedAtEpoch;
        if (closedAtEpoch == 0) {
            return AllocationState.Active;
        }

        uint256 epochs = epochManager().epochsSince(closedAtEpoch);
        if (epochs >= channelDisputeEpochs) {
            return AllocationState.Finalized;
        }
        return AllocationState.Closed;
    }

    /**
     * @dev Get the effective stake allocation considering epochs from allocation to closing.
     * @param _maxAllocationEpochs Max amount of epochs to cap the allocated stake
     * @param _tokens Amount of tokens allocated
     * @param _numEpochs Number of epochs that passed from allocation to closing
     * @return Effective allocated tokens across epochs
     */
    function _getEffectiveAllocation(
        uint256 _maxAllocationEpochs,
        uint256 _tokens,
        uint256 _numEpochs
    ) private pure returns (uint256) {
        bool shouldCap = _maxAllocationEpochs > 0 && _numEpochs > _maxAllocationEpochs;
        return _tokens.mul((shouldCap) ? _maxAllocationEpochs : _numEpochs);
    }

    /**
     * @dev Triggers an update of rewards due to a change in allocations.
     * @param _subgraphDeploymentID Subgraph deployment updated
     */
    function _updateRewards(bytes32 _subgraphDeploymentID) private returns (uint256) {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) == address(0)) {
            return 0;
        }
        return rewardsManager.onSubgraphAllocationUpdate(_subgraphDeploymentID);
    }

    /**
     * @dev Assign rewards for the closed allocation to indexer and delegators.
     * @param _allocationID Allocation
     */
    function _distributeRewards(address _allocationID, address _indexer) private {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) == address(0)) {
            return;
        }
        // Automatically triggers update of rewards snapshot as allocation will change
        // after this call. Take rewards mint tokens for the Staking contract to distribute
        // between indexer and delegators
        uint256 totalRewards = rewardsManager.takeRewards(_allocationID);
        if (totalRewards == 0) {
            return;
        }

        // Calculate delegation rewards and add them to the delegation pool
        uint256 delegationRewards = _collectDelegationIndexingRewards(_indexer, totalRewards);
        uint256 indexerRewards = totalRewards.sub(delegationRewards);

        // Add the rest of the rewards to the indexer stake
        if (indexerRewards > 0) {
            _stake(_indexer, indexerRewards);
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _graphToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function _burnTokens(IGraphToken _graphToken, uint256 _amount) private {
        if (_amount > 0) {
            _graphToken.burn(_amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "../staking/libs/Rebates.sol";
import "../staking/libs/Cobbs.sol";

// Mock contract used for testing rebates
contract RebatePoolMock {
    using Rebates for Rebates.Pool;

    // -- State --

    uint32 public alphaNumerator;
    uint32 public alphaDenominator;

    Rebates.Pool public rebatePool;

    // -- Events --

    event Redeemed(uint256 value);

    // Set the alpha for rebates
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external {
        rebatePool.init(_alphaNumerator, _alphaDenominator);
    }

    // Add fees and stake to the rebate pool
    function add(uint256 _indexerFees, uint256 _indexerAllocatedStake) external {
        rebatePool.addToPool(_indexerFees, _indexerAllocatedStake);
    }

    // Remove rewards from rebate pool
    function pop(uint256 _indexerFees, uint256 _indexerAllocatedStake) external returns (uint256) {
        uint256 value = rebatePool.redeem(_indexerFees, _indexerAllocatedStake);
        emit Redeemed(value);
        return value;
    }

    // Stub to test the cobb-douglas formula directly
    function cobbDouglas(
        uint256 _totalRewards,
        uint256 _fees,
        uint256 _totalFees,
        uint256 _stake,
        uint256 _totalStake,
        uint32 _alphaNumerator,
        uint32 _alphaDenominator
    ) external pure returns (uint256) {
        if (_totalFees == 0) {
            return 0;
        }

        return
            LibCobbDouglas.cobbDouglas(
                _totalRewards,
                _fees,
                _totalFees,
                _stake,
                _totalStake,
                _alphaNumerator,
                _alphaDenominator
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../governance/Governed.sol";

/**
 * @title GraphToken contract
 * @dev This is the implementation of the ERC20 Graph Token.
 * The implementation exposes a Permit() function to allow for a spender to send a signed message
 * and approve funds to a spender following EIP2612 to make integration with other contracts easier.
 *
 * The token is initially owned by the deployer address that can mint tokens to create the initial
 * distribution. For convenience, an initial supply can be passed in the constructor that will be
 * assigned to the deployer.
 *
 * The governor can add the RewardsManager contract to mint indexing rewards.
 *
 */
contract GraphToken is Governed, ERC20, ERC20Burnable {
    using SafeMath for uint256;

    // -- EIP712 --
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator

    bytes32 private constant DOMAIN_TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    );
    bytes32 private constant DOMAIN_NAME_HASH = keccak256("Graph Token");
    bytes32 private constant DOMAIN_VERSION_HASH = keccak256("0");
    bytes32
        private constant DOMAIN_SALT = 0x51f3d585afe6dfeb2af01bba0889a36c1db03beec88c6a4d0c53817069026afa; // Randomly generated salt
    bytes32 private constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    // -- State --

    bytes32 private DOMAIN_SEPARATOR;
    mapping(address => bool) private _minters;
    mapping(address => uint256) public nonces;

    // -- Events --

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Only minter can call");
        _;
    }

    /**
     * @dev Graph Token Contract Constructor.
     * @param _initialSupply Initial supply of GRT
     */
    constructor(uint256 _initialSupply) ERC20("Graph Token", "GRT") {
        Governed._initialize(msg.sender);

        // The Governor has the initial supply of tokens
        _mint(msg.sender, _initialSupply);

        // The Governor is the default minter
        _addMinter(msg.sender);

        // EIP-712 domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME_HASH,
                DOMAIN_VERSION_HASH,
                _getChainID(),
                address(this),
                DOMAIN_SALT
            )
        );
    }

    /**
     * @dev Approve token allowance by validating a message signed by the holder.
     * @param _owner Address of the token holder
     * @param _spender Address of the approved spender
     * @param _value Amount of tokens to approve the spender
     * @param _deadline Expiration time of the signed permit
     * @param _v Signature version
     * @param _r Signature r value
     * @param _s Signature s value
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        _owner,
                        _spender,
                        _value,
                        nonces[_owner],
                        _deadline
                    )
                )
            )
        );
        nonces[_owner] = nonces[_owner].add(1);

        address recoveredAddress = ECDSA.recover(digest, abi.encodePacked(_r, _s, _v));
        require(_owner == recoveredAddress, "GRT: invalid permit");
        require(_deadline == 0 || block.timestamp <= _deadline, "GRT: expired permit");

        _approve(_owner, _spender, _value);
    }

    /**
     * @dev Add a new minter.
     * @param _account Address of the minter
     */
    function addMinter(address _account) external onlyGovernor {
        _addMinter(_account);
    }

    /**
     * @dev Remove a minter.
     * @param _account Address of the minter
     */
    function removeMinter(address _account) external onlyGovernor {
        _removeMinter(_account);
    }

    /**
     * @dev Renounce to be a minter.
     */
    function renounceMinter() external {
        _removeMinter(msg.sender);
    }

    /**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    /**
     * @dev Return if the `_account` is a minter or not.
     * @param _account Address to check
     * @return True if the `_account` is minter
     */
    function isMinter(address _account) public view returns (bool) {
        return _minters[_account];
    }

    /**
     * @dev Add a new minter.
     * @param _account Address of the minter
     */
    function _addMinter(address _account) private {
        _minters[_account] = true;
        emit MinterAdded(_account);
    }

    /**
     * @dev Remove a minter.
     * @param _account Address of the minter
     */
    function _removeMinter(address _account) private {
        _minters[_account] = false;
        emit MinterRemoved(_account);
    }

    /**
     * @dev Get the running network chain ID.
     * @return The chain ID
     */
    function _getChainID() private pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor (string memory name_, string memory symbol_) {
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

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @title Graph Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governed {
    // -- State --

    address public governor;
    address public pendingGovernor;

    // -- Events --

    event NewPendingOwnership(address indexed from, address indexed to);
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor to the contract caller.
     */
    function _initialize(address _initGovernor) internal {
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(
            pendingGovernor != address(0) && msg.sender == pendingGovernor,
            "Caller must be pending governor"
        );

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
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

pragma solidity ^0.7.3;

import "../governance/Governed.sol";

import "./IGraphProxy.sol";
import "./GraphUpgradeable.sol";

/** 
 * @title GraphProxyAdmin
 * @dev This is the owner of upgradeable proxy contracts.
 * Proxy contracts use a TransparentProxy pattern, any admin related call
 * like upgrading a contract or changing the admin needs to be send through
 * this contract.
 */
contract GraphProxyAdmin is Governed {

    /** 
     * @dev Contract constructor.
     */
    constructor() {
        Governed._initialize(msg.sender);
    }

    /**
     * @dev Returns the current implementation of a proxy.
     * This is needed because only the proxy admin can query it.
     * @return The address of the current implementation of the proxy.
     */
    function getProxyImplementation(IGraphProxy _proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(_proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the pending implementation of a proxy.
     * This is needed because only the proxy admin can query it.
     * @return The address of the pending implementation of the proxy.
     */
    function getProxyPendingImplementation(IGraphProxy _proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("pendingImplementation()")) == 0x396f7b23
        (bool success, bytes memory returndata) = address(_proxy).staticcall(hex"396f7b23");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the admin of a proxy. Only the admin can query it.
     * @return The address of the current admin of the proxy.
     */
    function getProxyAdmin(IGraphProxy _proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(_proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of a proxy.
     * @param _proxy Proxy to change admin.
     * @param _newAdmin Address to transfer proxy administration to.
     */
    function changeProxyAdmin(IGraphProxy _proxy, address _newAdmin) public onlyGovernor {
        _proxy.setAdmin(_newAdmin);
    }

    /**
     * @dev Upgrades a proxy to the newest implementation of a contract.
     * @param _proxy Proxy to be upgraded.
     * @param _implementation the address of the Implementation.
     */
    function upgrade(IGraphProxy _proxy, address _implementation) public onlyGovernor {
        _proxy.upgradeTo(_implementation);
    }

    /**
     * @dev Accepts a proxy.
     * @param _implementation Address of the implementation accepting the proxy.
     * @param _proxy Address of the proxy being accepted.
     */
    function acceptProxy(GraphUpgradeable _implementation, IGraphProxy _proxy) public onlyGovernor {
        _implementation.acceptProxy(_proxy);
    }

    /**
     * @dev Accepts a proxy and call a function on the implementation.
     * @param _implementation Address of the implementation accepting the proxy.
     * @param _proxy Address of the proxy being accepted.
     * @param _data Encoded function to call on the implementation after accepting the proxy.
     */
    function acceptProxyAndCall(
        GraphUpgradeable _implementation,
        IGraphProxy _proxy,
        bytes calldata _data
    ) external onlyGovernor {
        _implementation.acceptProxyAndCall(_proxy, _data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../upgrades/GraphUpgradeable.sol";

import "./RewardsManagerStorage.sol";
import "./IRewardsManager.sol";

contract RewardsManager is RewardsManagerV1Storage, GraphUpgradeable, IRewardsManager {
    using SafeMath for uint256;

    uint256 private constant TOKEN_DECIMALS = 1e18;
    uint256 private constant MIN_ISSUANCE_RATE = 1e18;

    // -- Events --

    /**
     * @dev Emitted when rewards are assigned to an indexer.
     */
    event RewardsAssigned(
        address indexed indexer,
        address indexed allocationID,
        uint256 epoch,
        uint256 amount
    );

    /**
     * @dev Emitted when rewards are denied to an indexer.
     */
    event RewardsDenied(address indexed indexer, address indexed allocationID, uint256 epoch);

    /**
     * @dev Emitted when a subgraph is denied for claiming rewards.
     */
    event RewardsDenylistUpdated(bytes32 indexed subgraphDeploymentID, uint256 sinceBlock);

    // -- Modifiers --

    modifier onlySubgraphAvailabilityOracle() {
        require(
            msg.sender == address(subgraphAvailabilityOracle),
            "Caller must be the subgraph availability oracle"
        );
        _;
    }

    /**
     * @dev Initialize this contract.
     */
    function initialize(address _controller, uint256 _issuanceRate) external onlyImpl {
        Managed._initialize(_controller);

        // Settings
        _setIssuanceRate(_issuanceRate);
    }

    /**
     * @dev Sets the issuance rate.
     * The issuance rate is defined as a percentage increase of the total supply per block.
     * This means that it needs to be greater than 1.0, any number under 1.0 is not
     * allowed and an issuance rate of 1.0 means no issuance.
     * To accommodate a high precision the issuance rate is expressed in wei.
     * @param _issuanceRate Issuance rate expressed in wei
     */
    function setIssuanceRate(uint256 _issuanceRate) external override onlyGovernor {
        _setIssuanceRate(_issuanceRate);
    }

    /**
     * @dev Sets the issuance rate.
     * @param _issuanceRate Issuance rate
     */
    function _setIssuanceRate(uint256 _issuanceRate) private {
        require(_issuanceRate >= MIN_ISSUANCE_RATE, "Issuance rate under minimum allowed");

        // Called since `issuance rate` will change
        updateAccRewardsPerSignal();

        issuanceRate = _issuanceRate;
        emit ParameterUpdated("issuanceRate");
    }

    /**
     * @dev Sets the subgraph oracle allowed to denegate distribution of rewards to subgraphs.
     * @param _subgraphAvailabilityOracle Address of the subgraph availability oracle
     */
    function setSubgraphAvailabilityOracle(address _subgraphAvailabilityOracle)
        external
        override
        onlyGovernor
    {
        subgraphAvailabilityOracle = _subgraphAvailabilityOracle;
        emit ParameterUpdated("subgraphAvailabilityOracle");
    }

    /**
     * @dev Denies to claim rewards for a subgraph.
     * NOTE: Can only be called by the subgraph availability oracle
     * @param _subgraphDeploymentID Subgraph deployment ID
     * @param _deny Whether to set the subgraph as denied for claiming rewards or not
     */
    function setDenied(bytes32 _subgraphDeploymentID, bool _deny)
        external
        override
        onlySubgraphAvailabilityOracle
    {
        _setDenied(_subgraphDeploymentID, _deny);
    }

    /**
     * @dev Denies to claim rewards for multiple subgraph.
     * NOTE: Can only be called by the subgraph availability oracle
     * @param _subgraphDeploymentID Array of subgraph deployment ID
     * @param _deny Array of denied status for claiming rewards for each subgraph
     */
    function setDeniedMany(bytes32[] calldata _subgraphDeploymentID, bool[] calldata _deny)
        external
        override
        onlySubgraphAvailabilityOracle
    {
        require(_subgraphDeploymentID.length == _deny.length, "!length");
        for (uint256 i = 0; i < _subgraphDeploymentID.length; i++) {
            _setDenied(_subgraphDeploymentID[i], _deny[i]);
        }
    }

    /**
     * @dev Internal: Denies to claim rewards for a subgraph.
     * @param _subgraphDeploymentID Subgraph deployment ID
     * @param _deny Whether to set the subgraph as denied for claiming rewards or not
     */
    function _setDenied(bytes32 _subgraphDeploymentID, bool _deny) private {
        uint256 sinceBlock = _deny ? block.number : 0;
        denylist[_subgraphDeploymentID] = sinceBlock;
        emit RewardsDenylistUpdated(_subgraphDeploymentID, sinceBlock);
    }

    /**
     * @dev Tells if subgraph is in deny list
     * @param _subgraphDeploymentID Subgraph deployment ID to check
     */
    function isDenied(bytes32 _subgraphDeploymentID) public override view returns (bool) {
        return denylist[_subgraphDeploymentID] > 0;
    }

    /**
     * @dev Gets the issuance of rewards per signal since last updated.
     *
     * Compound interest formula: `a = p(1 + r/n)^nt`
     * The formula is simplified with `n = 1` as we apply the interest once every time step.
     * The `r` is passed with +1 included. So for 10% instead of 0.1 it is 1.1
     * The simplified formula is `a = p * r^t`
     *
     * Notation:
     * t: time steps are in blocks since last updated
     * p: total supply of GRT tokens
     * a: inflated amount of total supply for the period `t` when interest `r` is applied
     * x: newly accrued rewards token for the period `t`
     *
     * @return newly accrued rewards per signal since last update
     */
    function getNewRewardsPerSignal() public override view returns (uint256) {
        // Calculate time steps
        uint256 t = block.number.sub(accRewardsPerSignalLastBlockUpdated);
        // Optimization to skip calculations if zero time steps elapsed
        if (t == 0) {
            return 0;
        }

        // Zero issuance under a rate of 1.0
        if (issuanceRate <= MIN_ISSUANCE_RATE) {
            return 0;
        }

        // Zero issuance if no signalled tokens
        IGraphToken graphToken = graphToken();
        uint256 signalledTokens = graphToken.balanceOf(address(curation()));
        if (signalledTokens == 0) {
            return 0;
        }

        uint256 r = issuanceRate;
        uint256 p = graphToken.totalSupply();
        uint256 a = p.mul(_pow(r, t, TOKEN_DECIMALS)).div(TOKEN_DECIMALS);

        // New issuance per signalled token during time steps
        uint256 x = a.sub(p);

        // We multiply the decimals to keep the precision as fixed-point number
        return x.mul(TOKEN_DECIMALS).div(signalledTokens);
    }

    /**
     * @dev Gets the currently accumulated rewards per signal.
     */
    function getAccRewardsPerSignal() public override view returns (uint256) {
        return accRewardsPerSignal.add(getNewRewardsPerSignal());
    }

    /**
     * @dev Gets the accumulated rewards for the subgraph.
     * @param _subgraphDeploymentID Subgraph deployment
     * @return Accumulated rewards for subgraph
     */
    function getAccRewardsForSubgraph(bytes32 _subgraphDeploymentID)
        public
        override
        view
        returns (uint256)
    {
        Subgraph storage subgraph = subgraphs[_subgraphDeploymentID];

        uint256 newAccrued = getAccRewardsPerSignal().sub(subgraph.accRewardsPerSignalSnapshot);
        uint256 subgraphSignalledTokens = curation().getCurationPoolTokens(_subgraphDeploymentID);
        if (subgraphSignalledTokens == 0) {
            return 0;
        }

        uint256 newValue = newAccrued.mul(subgraphSignalledTokens).div(TOKEN_DECIMALS);
        return subgraph.accRewardsForSubgraph.add(newValue);
    }

    /**
     * @dev Gets the accumulated rewards per allocated token for the subgraph.
     * @param _subgraphDeploymentID Subgraph deployment
     * @return Accumulated rewards per allocated token for the subgraph
     * @return Accumulated rewards for subgraph
     */
    function getAccRewardsPerAllocatedToken(bytes32 _subgraphDeploymentID)
        public
        override
        view
        returns (uint256, uint256)
    {
        Subgraph storage subgraph = subgraphs[_subgraphDeploymentID];

        uint256 accRewardsForSubgraph = getAccRewardsForSubgraph(_subgraphDeploymentID);
        uint256 newAccrued = accRewardsForSubgraph.sub(subgraph.accRewardsForSubgraphSnapshot);

        uint256 subgraphAllocatedTokens = staking().getSubgraphAllocatedTokens(
            _subgraphDeploymentID
        );
        if (subgraphAllocatedTokens == 0) {
            return (0, accRewardsForSubgraph);
        }

        uint256 newValue = newAccrued.mul(TOKEN_DECIMALS).div(subgraphAllocatedTokens);
        return (subgraph.accRewardsPerAllocatedToken.add(newValue), accRewardsForSubgraph);
    }

    /**
     * @dev Updates the accumulated rewards per signal and save checkpoint block number.
     * Must be called before `issuanceRate` or `total signalled GRT` changes
     * Called from the Curation contract on mint() and burn()
     * @return Accumulated rewards per signal
     */
    function updateAccRewardsPerSignal() public override returns (uint256) {
        accRewardsPerSignal = getAccRewardsPerSignal();
        accRewardsPerSignalLastBlockUpdated = block.number;
        return accRewardsPerSignal;
    }

    /**
     * @dev Triggers an update of rewards for a subgraph.
     * Must be called before `signalled GRT` on a subgraph changes.
     * Note: Hook called from the Curation contract on mint() and burn()
     * @param _subgraphDeploymentID Subgraph deployment
     * @return Accumulated rewards for subgraph
     */
    function onSubgraphSignalUpdate(bytes32 _subgraphDeploymentID)
        external
        override
        returns (uint256)
    {
        // Called since `total signalled GRT` will change
        updateAccRewardsPerSignal();

        // Updates the accumulated rewards for a subgraph
        Subgraph storage subgraph = subgraphs[_subgraphDeploymentID];
        subgraph.accRewardsForSubgraph = getAccRewardsForSubgraph(_subgraphDeploymentID);
        subgraph.accRewardsPerSignalSnapshot = accRewardsPerSignal;
        return subgraph.accRewardsForSubgraph;
    }

    /**
     * @dev Triggers an update of rewards for a subgraph.
     * Must be called before allocation on a subgraph changes.
     * NOTE: Hook called from the Staking contract on allocate() and close()
     *
     * @param _subgraphDeploymentID Subgraph deployment
     * @return Accumulated rewards per allocated token for a subgraph
     */
    function onSubgraphAllocationUpdate(bytes32 _subgraphDeploymentID)
        public
        override
        returns (uint256)
    {
        Subgraph storage subgraph = subgraphs[_subgraphDeploymentID];
        (
            uint256 accRewardsPerAllocatedToken,
            uint256 accRewardsForSubgraph
        ) = getAccRewardsPerAllocatedToken(_subgraphDeploymentID);
        subgraph.accRewardsPerAllocatedToken = accRewardsPerAllocatedToken;
        subgraph.accRewardsForSubgraphSnapshot = accRewardsForSubgraph;
        return subgraph.accRewardsPerAllocatedToken;
    }

    /**
     * @dev Calculate current rewards for a given allocation on demand.
     * @param _allocationID Allocation
     * @return Rewards amount for an allocation
     */
    function getRewards(address _allocationID) external override view returns (uint256) {
        IStaking.Allocation memory alloc = staking().getAllocation(_allocationID);

        (uint256 accRewardsPerAllocatedToken, ) = getAccRewardsPerAllocatedToken(
            alloc.subgraphDeploymentID
        );
        return
            _calcRewards(
                alloc.tokens,
                alloc.accRewardsPerAllocatedToken,
                accRewardsPerAllocatedToken
            );
    }

    /**
     * @dev Calculate current rewards for a given allocation.
     * @param _tokens Tokens allocated
     * @param _startAccRewardsPerAllocatedToken Allocation start accumulated rewards
     * @param _endAccRewardsPerAllocatedToken Allocation end accumulated rewards
     * @return Rewards amount
     */
    function _calcRewards(
        uint256 _tokens,
        uint256 _startAccRewardsPerAllocatedToken,
        uint256 _endAccRewardsPerAllocatedToken
    ) private pure returns (uint256) {
        uint256 newAccrued = _endAccRewardsPerAllocatedToken.sub(_startAccRewardsPerAllocatedToken);
        return newAccrued.mul(_tokens).div(TOKEN_DECIMALS);
    }

    /**
     * @dev Pull rewards from the contract for a particular allocation.
     * This function can only be called by the Staking contract.
     * This function will mint the necessary tokens to reward based on the inflation calculation.
     * @param _allocationID Allocation
     * @return Assigned rewards amount
     */
    function takeRewards(address _allocationID) external override returns (uint256) {
        // Only Staking contract is authorized as caller
        IStaking staking = staking();
        require(msg.sender == address(staking), "Caller must be the staking contract");

        IGraphToken graphToken = graphToken();
        IStaking.Allocation memory alloc = staking.getAllocation(_allocationID);

        uint256 accRewardsPerAllocatedToken = onSubgraphAllocationUpdate(
            alloc.subgraphDeploymentID
        );

        // Do not do rewards on denied subgraph deployments ID
        if (isDenied(alloc.subgraphDeploymentID)) {
            emit RewardsDenied(alloc.indexer, _allocationID, alloc.closedAtEpoch);
            return 0;
        }

        // Calculate rewards accrued by this allocation
        uint256 rewards = _calcRewards(
            alloc.tokens,
            alloc.accRewardsPerAllocatedToken,
            accRewardsPerAllocatedToken
        );

        // Mint directly to staking contract for the reward amount
        // The staking contract will do bookkeeping of the reward and
        // assign in proportion to each stakeholder incentive
        graphToken.mint(address(staking), rewards);

        emit RewardsAssigned(alloc.indexer, _allocationID, alloc.closedAtEpoch, rewards);

        return rewards;
    }

    /**
     * @dev Raises x to the power of n with scaling factor of base.
     * Based on: https://github.com/makerdao/dss/blob/master/src/pot.sol#L81
     * @param x Base of the exponentiation
     * @param n Exponent
     * @param base Scaling factor
     * @return z Exponential of n with base x
     */
    function _pow(
        uint256 x,
        uint256 n,
        uint256 base
    ) private pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := base
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := base
                        }
                        default {
                            z := x
                        }
                    let half := div(base, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, base)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, base)
                        }
                    }
                }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IRewardsManager.sol";
import "../governance/Managed.sol";

contract RewardsManagerV1Storage is Managed {
    // -- State --

    uint256 public issuanceRate;
    uint256 public accRewardsPerSignal;
    uint256 public accRewardsPerSignalLastBlockUpdated;

    // Address of role allowed to deny rewards on subgraphs
    address public subgraphAvailabilityOracle;

    // Subgraph related rewards: subgraph deployment ID => subgraph rewards
    mapping(bytes32 => IRewardsManager.Subgraph) public subgraphs;

    // Subgraph denylist : subgraph deployment ID => block when added or zero (if not denied)
    mapping(bytes32 => uint256) public denylist;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../upgrades/GraphUpgradeable.sol";

import "./EpochManagerStorage.sol";
import "./IEpochManager.sol";

/**
 * @title EpochManager contract
 * @dev Produce epochs based on a number of blocks to coordinate contracts in the protocol.
 */
contract EpochManager is EpochManagerV1Storage, GraphUpgradeable, IEpochManager {
    using SafeMath for uint256;

    // -- Events --

    event EpochRun(uint256 indexed epoch, address caller);
    event EpochLengthUpdate(uint256 indexed epoch, uint256 epochLength);

    /**
     * @dev Initialize this contract.
     */
    function initialize(address _controller, uint256 _epochLength) external onlyImpl {
        require(_epochLength > 0, "Epoch length cannot be 0");

        Managed._initialize(_controller);

        lastLengthUpdateEpoch = 0;
        lastLengthUpdateBlock = blockNum();
        epochLength = _epochLength;

        emit EpochLengthUpdate(lastLengthUpdateEpoch, epochLength);
    }

    /**
     * @dev Set the epoch length.
     * @notice Set epoch length to `_epochLength` blocks
     * @param _epochLength Epoch length in blocks
     */
    function setEpochLength(uint256 _epochLength) external override onlyGovernor {
        require(_epochLength > 0, "Epoch length cannot be 0");
        require(_epochLength != epochLength, "Epoch length must be different to current");

        lastLengthUpdateEpoch = currentEpoch();
        lastLengthUpdateBlock = currentEpochBlock();
        epochLength = _epochLength;

        emit EpochLengthUpdate(lastLengthUpdateEpoch, epochLength);
    }

    /**
     * @dev Run a new epoch, should be called once at the start of any epoch.
     * @notice Perform state changes for the current epoch
     */
    function runEpoch() external override {
        // Check if already called for the current epoch
        require(!isCurrentEpochRun(), "Current epoch already run");

        lastRunEpoch = currentEpoch();

        // Hook for protocol general state updates

        emit EpochRun(lastRunEpoch, msg.sender);
    }

    /**
     * @dev Return true if the current epoch has already run.
     * @return Return true if current epoch is the last epoch that has run
     */
    function isCurrentEpochRun() public override view returns (bool) {
        return lastRunEpoch == currentEpoch();
    }

    /**
     * @dev Return current block number.
     * @return Block number
     */
    function blockNum() public override view returns (uint256) {
        return block.number;
    }

    /**
     * @dev Return blockhash for a block.
     * @return BlockHash for `_block` number
     */
    function blockHash(uint256 _block) external override view returns (bytes32) {
        uint256 currentBlock = blockNum();

        require(_block < currentBlock, "Can only retrieve past block hashes");
        require(
            currentBlock < 256 || _block >= currentBlock - 256,
            "Can only retrieve hashes for last 256 blocks"
        );

        return blockhash(_block);
    }

    /**
     * @dev Return the current epoch, it may have not been run yet.
     * @return The current epoch based on epoch length
     */
    function currentEpoch() public override view returns (uint256) {
        return lastLengthUpdateEpoch.add(epochsSinceUpdate());
    }

    /**
     * @dev Return block where the current epoch started.
     * @return The block number when the current epoch started
     */
    function currentEpochBlock() public override view returns (uint256) {
        return lastLengthUpdateBlock.add(epochsSinceUpdate().mul(epochLength));
    }

    /**
     * @dev Return the number of blocks that passed since current epoch started.
     * @return Blocks that passed since start of epoch
     */
    function currentEpochBlockSinceStart() external override view returns (uint256) {
        return blockNum() - currentEpochBlock();
    }

    /**
     * @dev Return the number of epoch that passed since another epoch.
     * @param _epoch Epoch to use as since epoch value
     * @return Number of epochs and current epoch
     */
    function epochsSince(uint256 _epoch) external override view returns (uint256) {
        uint256 epoch = currentEpoch();
        return _epoch < epoch ? epoch.sub(_epoch) : 0;
    }

    /**
     * @dev Return number of epochs passed since last epoch length update.
     * @return The number of epoch that passed since last epoch length update
     */
    function epochsSinceUpdate() public override view returns (uint256) {
        return blockNum().sub(lastLengthUpdateBlock).div(epochLength);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../governance/Managed.sol";

contract EpochManagerV1Storage is Managed {
    // -- State --

    // Epoch length in blocks
    uint256 public epochLength;

    // Epoch that was last run
    uint256 public lastRunEpoch;

    // Block and epoch when epoch length was last updated
    uint256 public lastLengthUpdateEpoch;
    uint256 public lastLengthUpdateBlock;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "../governance/Managed.sol";
import "../upgrades/GraphUpgradeable.sol";

import "./DisputeManagerStorage.sol";
import "./IDisputeManager.sol";

/*
 * @title DisputeManager
 * @dev Provides a way to align the incentives of participants by having slashing as deterrent
 * for incorrect behaviour.
 *
 * There are two types of disputes that can be created: Query disputes and Indexing disputes.
 *
 * Query Disputes:
 * Graph nodes receive queries and return responses with signed receipts called attestations.
 * An attestation can be disputed if the consumer thinks the query response was invalid.
 * Indexers use the derived private key for an allocation to sign attestations.
 *
 * Indexing Disputes:
 * Indexers present a Proof of Indexing (POI) when they close allocations to prove
 * they were indexing a subgraph. The Staking contract emits that proof with the format
 * keccak256(indexer.address, POI).
 * Any challenger can dispute the validity of a POI by submitting a dispute to this contract
 * along with a deposit.
 *
 * Arbitration:
 * Disputes can only be accepted, rejected or drawn by the arbitrator role that can be delegated
 * to a EOA or DAO.
 */
contract DisputeManager is DisputeManagerV1Storage, GraphUpgradeable, IDisputeManager {
    using SafeMath for uint256;

    // -- EIP-712  --

    bytes32 private constant DOMAIN_TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    );
    bytes32 private constant DOMAIN_NAME_HASH = keccak256("Graph Protocol");
    bytes32 private constant DOMAIN_VERSION_HASH = keccak256("0");
    bytes32
        private constant DOMAIN_SALT = 0xa070ffb1cd7409649bf77822cce74495468e06dbfaef09556838bf188679b9c2;
    bytes32 private constant RECEIPT_TYPE_HASH = keccak256(
        "Receipt(bytes32 requestCID,bytes32 responseCID,bytes32 subgraphDeploymentID)"
    );

    // -- Constants --

    uint256 private constant ATTESTATION_SIZE_BYTES = 161;
    uint256 private constant RECEIPT_SIZE_BYTES = 96;

    uint256 private constant SIG_R_LENGTH = 32;
    uint256 private constant SIG_S_LENGTH = 32;
    uint256 private constant SIG_R_OFFSET = RECEIPT_SIZE_BYTES;
    uint256 private constant SIG_S_OFFSET = RECEIPT_SIZE_BYTES + SIG_R_LENGTH;
    uint256 private constant SIG_V_OFFSET = RECEIPT_SIZE_BYTES + SIG_R_LENGTH + SIG_S_LENGTH;

    uint256 private constant UINT8_BYTE_LENGTH = 1;
    uint256 private constant BYTES32_BYTE_LENGTH = 32;

    uint256 private constant MAX_PPM = 1000000; // 100% in parts per million

    // -- Events --

    /**
     * @dev Emitted when a query dispute is created for `subgraphDeploymentID` and `indexer`
     * by `fisherman`.
     * The event emits the amount of `tokens` deposited by the fisherman and `attestation` submitted.
     */
    event QueryDisputeCreated(
        bytes32 indexed disputeID,
        address indexed indexer,
        address indexed fisherman,
        uint256 tokens,
        bytes32 subgraphDeploymentID,
        bytes attestation
    );

    /**
     * @dev Emitted when an indexing dispute is created for `allocationID` and `indexer`
     * by `fisherman`.
     * The event emits the amount of `tokens` deposited by the fisherman.
     */
    event IndexingDisputeCreated(
        bytes32 indexed disputeID,
        address indexed indexer,
        address indexed fisherman,
        uint256 tokens,
        address allocationID
    );

    /**
     * @dev Emitted when arbitrator accepts a `disputeID` to `indexer` created by `fisherman`.
     * The event emits the amount `tokens` transferred to the fisherman, the deposit plus reward.
     */
    event DisputeAccepted(
        bytes32 indexed disputeID,
        address indexed indexer,
        address indexed fisherman,
        uint256 tokens
    );

    /**
     * @dev Emitted when arbitrator rejects a `disputeID` for `indexer` created by `fisherman`.
     * The event emits the amount `tokens` burned from the fisherman deposit.
     */
    event DisputeRejected(
        bytes32 indexed disputeID,
        address indexed indexer,
        address indexed fisherman,
        uint256 tokens
    );

    /**
     * @dev Emitted when arbitrator draw a `disputeID` for `indexer` created by `fisherman`.
     * The event emits the amount `tokens` used as deposit and returned to the fisherman.
     */
    event DisputeDrawn(
        bytes32 indexed disputeID,
        address indexed indexer,
        address indexed fisherman,
        uint256 tokens
    );

    /**
     * @dev Emitted when two disputes are in conflict to link them.
     * This event will be emitted after each DisputeCreated event is emitted
     * for each of the individual disputes.
     */
    event DisputeLinked(bytes32 indexed disputeID1, bytes32 indexed disputeID2);

    /**
     * @dev Check if the caller is the arbitrator.
     */
    modifier onlyArbitrator {
        require(msg.sender == arbitrator, "Caller is not the Arbitrator");
        _;
    }

    /**
     * @dev Initialize this contract.
     * @param _arbitrator Arbitrator role
     * @param _minimumDeposit Minimum deposit required to create a Dispute
     * @param _fishermanRewardPercentage Percent of slashed funds for fisherman (ppm)
     * @param _slashingPercentage Percentage of indexer stake slashed (ppm)
     */
    function initialize(
        address _controller,
        address _arbitrator,
        uint256 _minimumDeposit,
        uint32 _fishermanRewardPercentage,
        uint32 _slashingPercentage
    ) external onlyImpl {
        Managed._initialize(_controller);

        // Settings
        _setArbitrator(_arbitrator);
        _setMinimumDeposit(_minimumDeposit);
        _setFishermanRewardPercentage(_fishermanRewardPercentage);
        _setSlashingPercentage(_slashingPercentage);

        // EIP-712 domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME_HASH,
                DOMAIN_VERSION_HASH,
                _getChainID(),
                address(this),
                DOMAIN_SALT
            )
        );
    }

    /**
     * @dev Set the arbitrator address.
     * @notice Update the arbitrator to `_arbitrator`
     * @param _arbitrator The address of the arbitration contract or party
     */
    function setArbitrator(address _arbitrator) external override onlyGovernor {
        _setArbitrator(_arbitrator);
    }

    /**
     * @dev Internal: Set the arbitrator address.
     * @notice Update the arbitrator to `_arbitrator`
     * @param _arbitrator The address of the arbitration contract or party
     */
    function _setArbitrator(address _arbitrator) private {
        require(_arbitrator != address(0), "Arbitrator must be set");
        arbitrator = _arbitrator;
        emit ParameterUpdated("arbitrator");
    }

    /**
     * @dev Set the minimum deposit required to create a dispute.
     * @notice Update the minimum deposit to `_minimumDeposit` Graph Tokens
     * @param _minimumDeposit The minimum deposit in Graph Tokens
     */
    function setMinimumDeposit(uint256 _minimumDeposit) external override onlyGovernor {
        _setMinimumDeposit(_minimumDeposit);
    }

    /**
     * @dev Internal: Set the minimum deposit required to create a dispute.
     * @notice Update the minimum deposit to `_minimumDeposit` Graph Tokens
     * @param _minimumDeposit The minimum deposit in Graph Tokens
     */
    function _setMinimumDeposit(uint256 _minimumDeposit) private {
        require(_minimumDeposit > 0, "Minimum deposit must be set");
        minimumDeposit = _minimumDeposit;
        emit ParameterUpdated("minimumDeposit");
    }

    /**
     * @dev Set the percent reward that the fisherman gets when slashing occurs.
     * @notice Update the reward percentage to `_percentage`
     * @param _percentage Reward as a percentage of indexer stake
     */
    function setFishermanRewardPercentage(uint32 _percentage) external override onlyGovernor {
        _setFishermanRewardPercentage(_percentage);
    }

    /**
     * @dev Internal: Set the percent reward that the fisherman gets when slashing occurs.
     * @notice Update the reward percentage to `_percentage`
     * @param _percentage Reward as a percentage of indexer stake
     */
    function _setFishermanRewardPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, "Reward percentage must be below or equal to MAX_PPM");
        fishermanRewardPercentage = _percentage;
        emit ParameterUpdated("fishermanRewardPercentage");
    }

    /**
     * @dev Set the percentage used for slashing indexers.
     * @param _percentage Percentage used for slashing
     */
    function setSlashingPercentage(uint32 _percentage) external override onlyGovernor {
        _setSlashingPercentage(_percentage);
    }

    /**
     * @dev Internal: Set the percentage used for slashing indexers.
     * @param _percentage Percentage used for slashing
     */
    function _setSlashingPercentage(uint32 _percentage) private {
        // Must be within 0% to 100% (inclusive)
        require(_percentage <= MAX_PPM, "Slashing percentage must be below or equal to MAX_PPM");
        slashingPercentage = _percentage;
        emit ParameterUpdated("slashingPercentage");
    }

    /**
     * @dev Return whether a dispute exists or not.
     * @notice Return if dispute with ID `_disputeID` exists
     * @param _disputeID True if dispute already exists
     */
    function isDisputeCreated(bytes32 _disputeID) public override view returns (bool) {
        return disputes[_disputeID].fisherman != address(0);
    }

    /**
     * @dev Get the message hash that an indexer used to sign the receipt.
     * Encodes a receipt using a domain separator, as described on
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification.
     * @notice Return the message hash used to sign the receipt
     * @param _receipt Receipt returned by indexer and submitted by fisherman
     * @return Message hash used to sign the receipt
     */
    function encodeHashReceipt(Receipt memory _receipt) public override view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01", // EIP-191 encoding pad, EIP-712 version 1
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            RECEIPT_TYPE_HASH,
                            _receipt.requestCID,
                            _receipt.responseCID,
                            _receipt.subgraphDeploymentID
                        ) // EIP 712-encoded message hash
                    )
                )
            );
    }

    /**
     * @dev Returns if two attestations are conflicting.
     * Everything must match except for the responseID.
     * @param _attestation1 Attestation
     * @param _attestation2 Attestation
     * @return True if the two attestations are conflicting
     */
    function areConflictingAttestations(
        Attestation memory _attestation1,
        Attestation memory _attestation2
    ) public override pure returns (bool) {
        return (_attestation1.requestCID == _attestation2.requestCID &&
            _attestation1.subgraphDeploymentID == _attestation2.subgraphDeploymentID &&
            _attestation1.responseCID != _attestation2.responseCID);
    }

    /**
     * @dev Returns the indexer that signed an attestation.
     * @param _attestation Attestation
     * @return Indexer address
     */
    function getAttestationIndexer(Attestation memory _attestation)
        public
        override
        view
        returns (address)
    {
        // Get attestation signer, allocationID
        address allocationID = _recoverAttestationSigner(_attestation);

        IStaking.Allocation memory alloc = staking().getAllocation(allocationID);
        require(alloc.indexer != address(0), "Indexer cannot be found for the attestation");
        require(
            alloc.subgraphDeploymentID == _attestation.subgraphDeploymentID,
            "Allocation and attestation subgraphDeploymentID must match"
        );
        return alloc.indexer;
    }

    /**
     * @dev Get the fisherman reward for a given indexer stake.
     * @notice Return the fisherman reward based on the `_indexer` stake
     * @param _indexer Indexer to be slashed
     * @return Reward calculated as percentage of the indexer slashed funds
     */
    function getTokensToReward(address _indexer) public override view returns (uint256) {
        uint256 tokens = getTokensToSlash(_indexer);
        if (tokens == 0) {
            return 0;
        }
        return uint256(fishermanRewardPercentage).mul(tokens).div(MAX_PPM);
    }

    /**
     * @dev Get the amount of tokens to slash for an indexer based on the current stake.
     * @param _indexer Address of the indexer
     * @return Amount of tokens to slash
     */
    function getTokensToSlash(address _indexer) public override view returns (uint256) {
        uint256 tokens = staking().getIndexerStakedTokens(_indexer); // slashable tokens
        if (tokens == 0) {
            return 0;
        }
        return uint256(slashingPercentage).mul(tokens).div(MAX_PPM);
    }

    /**
     * @dev Create a query dispute for the arbitrator to resolve.
     * This function is called by a fisherman that will need to `_deposit` at
     * least `minimumDeposit` GRT tokens.
     * @param _attestationData Attestation bytes submitted by the fisherman
     * @param _deposit Amount of tokens staked as deposit
     */
    function createQueryDispute(bytes calldata _attestationData, uint256 _deposit)
        external
        override
        returns (bytes32)
    {
        // Get funds from submitter
        _pullSubmitterDeposit(_deposit);

        // Create a dispute
        return
            _createQueryDisputeWithAttestation(
                msg.sender,
                _deposit,
                _parseAttestation(_attestationData),
                _attestationData
            );
    }

    /**
     * @dev Create query disputes for two conflicting attestations.
     * A conflicting attestation is a proof presented by two different indexers
     * where for the same request on a subgraph the response is different.
     * For this type of dispute the submitter is not required to present a deposit
     * as one of the attestation is considered to be right.
     * Two linked disputes will be created and if the arbitrator resolve one, the other
     * one will be automatically resolved.
     * @param _attestationData1 First attestation data submitted
     * @param _attestationData2 Second attestation data submitted
     * @return DisputeID1, DisputeID2
     */
    function createQueryDisputeConflict(
        bytes calldata _attestationData1,
        bytes calldata _attestationData2
    ) external override returns (bytes32, bytes32) {
        address fisherman = msg.sender;

        // Parse each attestation
        Attestation memory attestation1 = _parseAttestation(_attestationData1);
        Attestation memory attestation2 = _parseAttestation(_attestationData2);

        // Test that attestations are conflicting
        require(
            areConflictingAttestations(attestation1, attestation2),
            "Attestations must be in conflict"
        );

        // Create the disputes
        // The deposit is zero for conflicting attestations
        bytes32 dID1 = _createQueryDisputeWithAttestation(
            fisherman,
            0,
            attestation1,
            _attestationData1
        );
        bytes32 dID2 = _createQueryDisputeWithAttestation(
            fisherman,
            0,
            attestation2,
            _attestationData2
        );

        // Store the linked disputes to be resolved
        disputes[dID1].relatedDisputeID = dID2;
        disputes[dID2].relatedDisputeID = dID1;

        // Emit event that links the two created disputes
        emit DisputeLinked(dID1, dID2);

        return (dID1, dID2);
    }

    /**
     * @dev Create a query dispute passing the parsed attestation.
     * To be used in createQueryDispute() and createQueryDisputeConflict()
     * to avoid calling parseAttestation() multiple times
     * `_attestationData` is only passed to be emitted
     * @param _fisherman Creator of dispute
     * @param _deposit Amount of tokens staked as deposit
     * @param _attestation Attestation struct parsed from bytes
     * @param _attestationData Attestation bytes submitted by the fisherman
     * @return DisputeID
     */
    function _createQueryDisputeWithAttestation(
        address _fisherman,
        uint256 _deposit,
        Attestation memory _attestation,
        bytes memory _attestationData
    ) private returns (bytes32) {
        // Get the indexer that signed the attestation
        address indexer = getAttestationIndexer(_attestation);

        // The indexer is disputable
        require(staking().hasStake(indexer), "Dispute indexer has no stake");

        // Create a disputeID
        bytes32 disputeID = keccak256(
            abi.encodePacked(
                _attestation.requestCID,
                _attestation.responseCID,
                _attestation.subgraphDeploymentID,
                indexer,
                _fisherman
            )
        );

        // Only one dispute for a (indexer, subgraphDeploymentID) at a time
        require(!isDisputeCreated(disputeID), "Dispute already created");

        // Store dispute
        disputes[disputeID] = Dispute(
            indexer,
            _fisherman,
            _deposit,
            0 // no related dispute
        );

        emit QueryDisputeCreated(
            disputeID,
            indexer,
            _fisherman,
            _deposit,
            _attestation.subgraphDeploymentID,
            _attestationData
        );

        return disputeID;
    }

    /**
     * @dev Create an indexing dispute for the arbitrator to resolve.
     * The disputes are created in reference to an allocationID
     * This function is called by a challenger that will need to `_deposit` at
     * least `minimumDeposit` GRT tokens.
     * @param _allocationID The allocation to dispute
     * @param _deposit Amount of tokens staked as deposit
     */
    function createIndexingDispute(address _allocationID, uint256 _deposit)
        external
        override
        returns (bytes32)
    {
        // Get funds from submitter
        _pullSubmitterDeposit(_deposit);

        // Create a dispute
        return _createIndexingDisputeWithAllocation(msg.sender, _deposit, _allocationID);
    }

    /**
     * @dev Create indexing dispute internal function.
     * @param _fisherman The challenger creating the dispute
     * @param _deposit Amount of tokens staked as deposit
     * @param _allocationID Allocation disputed
     */

    function _createIndexingDisputeWithAllocation(
        address _fisherman,
        uint256 _deposit,
        address _allocationID
    ) private returns (bytes32) {
        // Create a disputeID
        bytes32 disputeID = keccak256(abi.encodePacked(_allocationID));

        // Only one dispute for an allocationID at a time
        require(!isDisputeCreated(disputeID), "Dispute already created");

        // Allocation must exist
        IStaking.Allocation memory alloc = staking().getAllocation(_allocationID);
        require(alloc.indexer != address(0), "Dispute allocation must exist");

        // The indexer must be disputable
        require(staking().hasStake(alloc.indexer), "Dispute indexer has no stake");

        // Store dispute
        disputes[disputeID] = Dispute(alloc.indexer, _fisherman, _deposit, 0);

        emit IndexingDisputeCreated(disputeID, alloc.indexer, _fisherman, _deposit, _allocationID);

        return disputeID;
    }

    /**
     * @dev The arbitrator accepts a dispute as being valid.
     * @notice Accept a dispute with ID `_disputeID`
     * @param _disputeID ID of the dispute to be accepted
     */
    function acceptDispute(bytes32 _disputeID) external override onlyArbitrator {
        Dispute memory dispute = _resolveDispute(_disputeID);

        // Slash
        uint256 tokensToReward = _slashIndexer(dispute.indexer, dispute.fisherman);

        // Give the fisherman their deposit back
        if (dispute.deposit > 0) {
            require(
                graphToken().transfer(dispute.fisherman, dispute.deposit),
                "Error sending dispute deposit"
            );
        }

        // Resolve the conflicting dispute if any
        _resolveDisputeInConflict(dispute);

        emit DisputeAccepted(
            _disputeID,
            dispute.indexer,
            dispute.fisherman,
            dispute.deposit.add(tokensToReward)
        );
    }

    /**
     * @dev The arbitrator rejects a dispute as being invalid.
     * @notice Reject a dispute with ID `_disputeID`
     * @param _disputeID ID of the dispute to be rejected
     */
    function rejectDispute(bytes32 _disputeID) external override onlyArbitrator {
        Dispute memory dispute = _resolveDispute(_disputeID);

        // Handle conflicting dispute if any
        require(
            !_isDisputeInConflict(dispute),
            "Dispute for conflicting attestation, must accept the related ID to reject"
        );

        // Burn the fisherman's deposit
        if (dispute.deposit > 0) {
            graphToken().burn(dispute.deposit);
        }

        emit DisputeRejected(_disputeID, dispute.indexer, dispute.fisherman, dispute.deposit);
    }

    /**
     * @dev The arbitrator draws dispute.
     * @notice Ignore a dispute with ID `_disputeID`
     * @param _disputeID ID of the dispute to be disregarded
     */
    function drawDispute(bytes32 _disputeID) external override onlyArbitrator {
        Dispute memory dispute = _resolveDispute(_disputeID);

        // Return deposit to the fisherman
        if (dispute.deposit > 0) {
            require(
                graphToken().transfer(dispute.fisherman, dispute.deposit),
                "Error sending dispute deposit"
            );
        }

        // Resolve the conflicting dispute if any
        _resolveDisputeInConflict(dispute);

        emit DisputeDrawn(_disputeID, dispute.indexer, dispute.fisherman, dispute.deposit);
    }

    /**
     * @dev Resolve a dispute by removing it from storage and returning a memory copy.
     * @param _disputeID ID of the dispute to resolve
     * @return Dispute
     */
    function _resolveDispute(bytes32 _disputeID) private returns (Dispute memory) {
        require(isDisputeCreated(_disputeID), "Dispute does not exist");

        Dispute memory dispute = disputes[_disputeID];

        // Resolve dispute
        delete disputes[_disputeID]; // Re-entrancy

        return dispute;
    }

    /**
     * @dev Returns whether the dispute is for a conflicting attestation or not.
     * @param _dispute Dispute
     * @return True conflicting attestation dispute
     */
    function _isDisputeInConflict(Dispute memory _dispute) private pure returns (bool) {
        return _dispute.relatedDisputeID != 0;
    }

    /**
     * @dev Resolve the conflicting dispute if there is any for the one passed to this function.
     * @param _dispute Dispute
     * @return True if resolved
     */
    function _resolveDisputeInConflict(Dispute memory _dispute) private returns (bool) {
        if (_isDisputeInConflict(_dispute)) {
            bytes32 relatedDisputeID = _dispute.relatedDisputeID;
            delete disputes[relatedDisputeID];
            return true;
        }
        return false;
    }

    /**
     * @dev Pull deposit from submitter account.
     * @param _deposit Amount of tokens to deposit
     */
    function _pullSubmitterDeposit(uint256 _deposit) private {
        // Ensure that fisherman has staked at least the minimum amount
        require(_deposit >= minimumDeposit, "Dispute deposit is under minimum required");

        // Transfer tokens to deposit from fisherman to this contract
        require(
            graphToken().transferFrom(msg.sender, address(this), _deposit),
            "Cannot transfer tokens to deposit"
        );
    }

    /**
     * @dev Make the staking contract slash the indexer and reward the challenger.
     * Give the challenger a reward equal to the fishermanRewardPercentage of slashed amount
     * @param _indexer Address of the indexer
     * @param _challenger Address of the challenger
     * @return Dispute reward tokens
     */
    function _slashIndexer(address _indexer, address _challenger) private returns (uint256) {
        // Have staking contract slash the indexer and reward the fisherman
        // Give the fisherman a reward equal to the fishermanRewardPercentage of slashed amount
        uint256 tokensToSlash = getTokensToSlash(_indexer);
        uint256 tokensToReward = getTokensToReward(_indexer);

        require(tokensToSlash > 0, "Dispute has zero tokens to slash");
        staking().slash(_indexer, tokensToSlash, tokensToReward, _challenger);

        return tokensToReward;
    }

    /**
     * @dev Recover the signer address of the `_attestation`.
     * @param _attestation The attestation struct
     * @return Signer address
     */
    function _recoverAttestationSigner(Attestation memory _attestation)
        private
        view
        returns (address)
    {
        // Obtain the hash of the fully-encoded message, per EIP-712 encoding
        Receipt memory receipt = Receipt(
            _attestation.requestCID,
            _attestation.responseCID,
            _attestation.subgraphDeploymentID
        );
        bytes32 messageHash = encodeHashReceipt(receipt);

        // Obtain the signer of the fully-encoded EIP-712 message hash
        // NOTE: The signer of the attestation is the indexer that served the request
        return
            ECDSA.recover(
                messageHash,
                abi.encodePacked(_attestation.r, _attestation.s, _attestation.v)
            );
    }

    /**
     * @dev Get the running network chain ID
     * @return The chain ID
     */
    function _getChainID() private pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Parse the bytes attestation into a struct from `_data`.
     * @return Attestation struct
     */
    function _parseAttestation(bytes memory _data) private pure returns (Attestation memory) {
        // Check attestation data length
        require(_data.length == ATTESTATION_SIZE_BYTES, "Attestation must be 161 bytes long");

        // Decode receipt
        (bytes32 requestCID, bytes32 responseCID, bytes32 subgraphDeploymentID) = abi.decode(
            _data,
            (bytes32, bytes32, bytes32)
        );

        // Decode signature
        // Signature is expected to be in the order defined in the Attestation struct
        bytes32 r = _toBytes32(_data, SIG_R_OFFSET);
        bytes32 s = _toBytes32(_data, SIG_S_OFFSET);
        uint8 v = _toUint8(_data, SIG_V_OFFSET);

        return Attestation(requestCID, responseCID, subgraphDeploymentID, r, s, v);
    }

    /**
     * @dev Parse a uint8 from `_bytes` starting at offset `_start`.
     * @return uint8 value
     */
    function _toUint8(bytes memory _bytes, uint256 _start) private pure returns (uint8) {
        require(_bytes.length >= (_start + UINT8_BYTE_LENGTH), "Bytes: out of bounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    /**
     * @dev Parse a bytes32 from `_bytes` starting at offset `_start`.
     * @return bytes32 value
     */
    function _toBytes32(bytes memory _bytes, uint256 _start) private pure returns (bytes32) {
        require(_bytes.length >= (_start + BYTES32_BYTE_LENGTH), "Bytes: out of bounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../governance/Managed.sol";

import "./IDisputeManager.sol";

contract DisputeManagerV1Storage is Managed {
    // -- State --

    bytes32 internal DOMAIN_SEPARATOR;

    // The arbitrator is solely in control of arbitrating disputes
    address public arbitrator;

    // Minimum deposit required to create a Dispute
    uint256 public minimumDeposit;

    // Percentage of indexer slashed funds to assign as a reward to fisherman in successful dispute
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public fishermanRewardPercentage;

    // Percentage of indexer stake to slash on disputes
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public slashingPercentage;

    // Disputes created : disputeID => Dispute
    // disputeID - check creation functions to see how disputeID is built
    mapping(bytes32 => IDisputeManager.Dispute) public disputes;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

interface IDisputeManager {
    // -- Dispute --

    // Disputes contain info necessary for the Arbitrator to verify and resolve
    struct Dispute {
        address indexer;
        address fisherman;
        uint256 deposit;
        bytes32 relatedDisputeID;
    }

    // -- Attestation --

    // Receipt content sent from indexer in response to request
    struct Receipt {
        bytes32 requestCID;
        bytes32 responseCID;
        bytes32 subgraphDeploymentID;
    }

    // Attestation sent from indexer in response to a request
    struct Attestation {
        bytes32 requestCID;
        bytes32 responseCID;
        bytes32 subgraphDeploymentID;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    // -- Configuration --

    function setArbitrator(address _arbitrator) external;

    function setMinimumDeposit(uint256 _minimumDeposit) external;

    function setFishermanRewardPercentage(uint32 _percentage) external;

    function setSlashingPercentage(uint32 _percentage) external;

    // -- Getters --

    function isDisputeCreated(bytes32 _disputeID) external view returns (bool);

    function encodeHashReceipt(Receipt memory _receipt) external view returns (bytes32);

    function areConflictingAttestations(
        Attestation memory _attestation1,
        Attestation memory _attestation2
    ) external pure returns (bool);

    function getAttestationIndexer(Attestation memory _attestation) external view returns (address);

    function getTokensToReward(address _indexer) external view returns (uint256);

    function getTokensToSlash(address _indexer) external view returns (uint256);

    // -- Dispute --

    function createQueryDispute(bytes calldata _attestationData, uint256 _deposit)
        external
        returns (bytes32);

    function createQueryDisputeConflict(
        bytes calldata _attestationData1,
        bytes calldata _attestationData2
    ) external returns (bytes32, bytes32);

    function createIndexingDispute(address _allocationID, uint256 _deposit)
        external
        returns (bytes32);

    function acceptDispute(bytes32 _disputeID) external;

    function rejectDispute(bytes32 _disputeID) external;

    function drawDispute(bytes32 _disputeID) external;
}

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import '@statechannels/nitro-protocol/contracts/interfaces/ForceMoveApp.sol';
import '@statechannels/nitro-protocol/contracts/Outcome.sol';
import '@openzeppelin/contracts/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract AttestationApp is ForceMoveApp {
    using SafeMath for uint256;

    struct ConstantAppData {
        uint256 chainId;
        address allocationId;
        address verifyingContract;
        bytes32 subgraphDeploymentID;
    }

    struct VariableAppData {
        uint256 paymentAmount;
        bytes32 requestCID;
        bytes32 responseCID;
        bytes signature;
    }

    struct AttestationAppData {
        ConstantAppData constants;
        VariableAppData variable;
    }

    uint256 constant PARTICIPANT_GATEWAY = 0;
    uint256 constant PARTICIPANT_INDEXER = 1;

    function validTransition(
        VariablePart calldata a,
        VariablePart calldata b,
        uint48 turnNumB,
        uint256 nParticipants
    ) external override pure returns (bool) {
        // BEGIN COPY: Copied from SingleAssetPayments.sol
        // https://github.com/statechannels/statechannels/blob/ee1a0aa/packages/nitro-protocol/contracts/examples/SingleAssetPayments.sol
        Outcome.OutcomeItem[] memory outcomeA = abi.decode(a.outcome, (Outcome.OutcomeItem[]));
        Outcome.OutcomeItem[] memory outcomeB = abi.decode(b.outcome, (Outcome.OutcomeItem[]));

        // Throws if more than one asset
        require(outcomeA.length == 1, 'outcomeA: Only one asset allowed');
        require(outcomeB.length == 1, 'outcomeB: Only one asset allowed');

        // Throws unless the assetoutcome is an allocation
        Outcome.AssetOutcome memory assetOutcomeA = abi.decode(
            outcomeA[0].assetOutcomeBytes,
            (Outcome.AssetOutcome)
        );
        Outcome.AssetOutcome memory assetOutcomeB = abi.decode(
            outcomeB[0].assetOutcomeBytes,
            (Outcome.AssetOutcome)
        );

        require(
            assetOutcomeA.assetOutcomeType == uint8(Outcome.AssetOutcomeType.Allocation),
            'outcomeA: AssetOutcomeType must be Allocation'
        );
        require(
            assetOutcomeB.assetOutcomeType == uint8(Outcome.AssetOutcomeType.Allocation),
            'outcomeB: AssetOutcomeType must be Allocation'
        );

        // Throws unless that allocation has exactly n outcomes
        Outcome.AllocationItem[] memory allocationA = abi.decode(
            assetOutcomeA.allocationOrGuaranteeBytes,
            (Outcome.AllocationItem[])
        );
        Outcome.AllocationItem[] memory allocationB = abi.decode(
            assetOutcomeB.allocationOrGuaranteeBytes,
            (Outcome.AllocationItem[])
        );
        require(
            allocationA.length == nParticipants,
            'outcomeA: Allocation length must equal number of participants'
        );
        require(
            allocationB.length == nParticipants,
            'outcomeB: Allocation length must equal number of participants'
        );
        // END COPY

        require(nParticipants == 2, 'Must be a 2-party channels');

        AttestationAppData memory providedStateA = abi.decode(a.appData, (AttestationAppData));
        AttestationAppData memory providedStateB = abi.decode(b.appData, (AttestationAppData));

        // Validate the constants
        require(
            _bytesEqual(abi.encode(providedStateA.constants),abi.encode(providedStateB.constants)),
            'Constants must not change'
        );

        // Next validate the variable parts
        if (turnNumB % 2 == PARTICIPANT_GATEWAY) {
            require(
                providedStateB.variable.requestCID != 0,
                'Gateway Query: RequestCID must be non-zero'
            );
            require(
                providedStateB.variable.responseCID == 0,
                'Gateway Query: ResponseCID must be zero'
            );

            require(
                isZero(providedStateB.variable.signature),
                'Gateway Query: Signature must be zero'
            );
            require(
                providedStateB.variable.paymentAmount > 0,
                'Gateway Query: Payment amount must be non-zero'
            );
        } else {
            // Indexer moved

            // If there is a non-zero responseCID the attestation has been provided
            if (providedStateB.variable.responseCID > 0) {
                require(
                    recoverAttestationSigner(providedStateB) ==
                        providedStateB.constants.allocationId,
                    'Indexer Attestation: must be signed with the allocationId'
                );

                require(
                    allocationB[PARTICIPANT_GATEWAY].amount ==
                        allocationA[PARTICIPANT_GATEWAY].amount.sub(
                            providedStateA.variable.paymentAmount
                        ),
                    'Indexer Attestation: Gateway funds must be decremented by payment amount'
                );

                require(
                    allocationB[PARTICIPANT_INDEXER].amount ==
                        allocationA[PARTICIPANT_INDEXER].amount.add(
                            providedStateA.variable.paymentAmount
                        ),
                    'Indexer Attestation: Indexer funds must be incremented by payment amount'
                );

                // If there is a zero responseCID the query has been rejected
            } else {
                require(
                    providedStateB.variable.requestCID == 0,
                    'Indexer Reject: RequestCID must be zero'
                );

                require(
                    isZero(providedStateB.variable.signature),
                    'Indexer Rject: Signature must be zero'
                );

                require(
                    allocationB[PARTICIPANT_INDEXER].amount ==
                        allocationA[PARTICIPANT_INDEXER].amount,
                    'Indexer Reject: Indexer funds must not change'
                );
                require(
                    allocationB[PARTICIPANT_GATEWAY].amount ==
                        allocationA[PARTICIPANT_GATEWAY].amount,
                    'Indexer Reject: Gateway funds must not change'
                );
            }
        }
        return true;
    }

    function isZero(bytes memory data) private pure returns (bool) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[0] != 0) {
                return false;
            }
        }
        return true;
    }

     /**
     * @notice Check for equality of two byte strings
     * @dev Check for equality of two byte strings
     * @param _preBytes One bytes string
     * @param _postBytes The other bytes string
     * @return true if the bytes are identical, false otherwise.
     */
    function _bytesEqual(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        // copied from https://www.npmjs.com/package/solidity-bytes-utils/v/0.1.1
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
                case 1 {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                    let cb := 1

                    let mc := add(_preBytes, 0x20)
                    let end := add(mc, length)

                    for {
                        let cc := add(_postBytes, 0x20)
                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                    } eq(add(lt(mc, end), cb), 2) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        // if any of these checks fails then arrays are not equal
                        if iszero(eq(mload(mc), mload(cc))) {
                            // unsuccess:
                            success := 0
                            cb := 0
                        }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }

        return success;
    }

    // EIP-712 TYPE HASH CONSTANTS
    bytes32 private constant DOMAIN_TYPE_HASH = keccak256(
        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)'
    );

    bytes32 private constant RECEIPT_TYPE_HASH = keccak256(
        'Receipt(bytes32 requestCID,bytes32 responseCID,bytes32 subgraphDeploymentID)'
    );

    // EIP-712 DOMAIN SEPARATOR CONSTANTS
    bytes32 private constant DOMAIN_NAME_HASH = keccak256('Graph Protocol');
    bytes32 private constant DOMAIN_VERSION_HASH = keccak256('0');
    bytes32
        private constant DOMAIN_SALT = 0xa070ffb1cd7409649bf77822cce74495468e06dbfaef09556838bf188679b9c2;

    function recoverAttestationSigner(AttestationAppData memory appData)
        public
        pure
        returns (address)
    {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        '\x19\x01',
                        keccak256(
                            abi.encode(
                                DOMAIN_TYPE_HASH,
                                DOMAIN_NAME_HASH,
                                DOMAIN_VERSION_HASH,
                                appData.constants.chainId,
                                appData.constants.verifyingContract,
                                DOMAIN_SALT
                            )
                        ),
                        keccak256(
                            abi.encode(
                                RECEIPT_TYPE_HASH,
                                appData.variable.requestCID,
                                appData.variable.responseCID,
                                appData.constants.subgraphDeploymentID
                            )
                        )
                    )
                ),
                appData.variable.signature
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/**
 * @dev The ForceMoveApp interface calls for its children to implement an application-specific validTransition function, defining the state machine of a ForceMove state channel DApp.
 */
interface ForceMoveApp {
    struct VariablePart {
        bytes outcome;
        bytes appData;
    }

    /**
     * @notice Encodes application-specific rules for a particular ForceMove-compliant state channel.
     * @dev Encodes application-specific rules for a particular ForceMove-compliant state channel.
     * @param a State being transitioned from.
     * @param b State being transitioned to.
     * @param turnNumB Turn number being transitioned to.
     * @param nParticipants Number of participants in this state channel.
     * @return true if the transition conforms to this application's rules, false otherwise
     */
    function validTransition(
        VariablePart calldata a,
        VariablePart calldata b,
        uint48 turnNumB,
        uint256 nParticipants
    ) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

library Outcome {
    //An outcome is an array of OutcomeItems
    // Outcome = OutcomeItem[]
    // OutcomeItem = (AssetHolderAddress, AssetOutcome)
    // AssetOutcome = (AssetOutcomeType, Allocation | Guarantee)
    // Allocation = AllocationItem[]
    // AllocationItem = (Destination, Amount)
    // Guarantee = (ChannelAddress, Destination[])
    // Destination = ChannelAddress | ExternalDestination

    struct OutcomeItem {
        address assetHolderAddress;
        bytes assetOutcomeBytes; // abi.encode(AssetOutcome)
    }

    enum AssetOutcomeType {Allocation, Guarantee}

    struct AssetOutcome {
        uint8 assetOutcomeType; // AssetOutcomeType.Allocation or AssetOutcomeType.Guarantee
        bytes allocationOrGuaranteeBytes; // abi.encode(AllocationItem[]) or abi.encode(Guarantee), depending on OutcomeType
    }

    // reserve Allocation to refer to AllocationItem[]
    struct AllocationItem {
        bytes32 destination;
        uint256 amount;
    }

    struct Guarantee {
        bytes32 targetChannelId;
        bytes32[] destinations;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import './Outcome.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAssetHolder.sol';

/**
 * @dev An implementation of the IAssetHolder interface. The AssetHolder contract escrows ETH or tokens against state channels. It allows assets to be internally accounted for, and ultimately prepared for transfer from one channel to other channel and/or external destinations, as well as for guarantees to be claimed. Note there is no deposit function and the _transferAsset function is unimplemented; inheriting contracts should implement these functions in a manner appropriate to the asset type (e.g. ETH or ERC20 tokens).
 */
contract AssetHolder is IAssetHolder {
    using SafeMath for uint256;

    address public AdjudicatorAddress;

    mapping(bytes32 => uint256) public holdings;

    mapping(bytes32 => bytes32) public assetOutcomeHashes;


    // **************
    // Public methods
    // **************

    /**
     * @notice Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries.
     * @dev Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries.
     * @param fromChannelId Unique identifier for state channel to transfer funds *from*.
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation
     * @param destination External destination or channel to transfer funds *to*.
     */
    function transfer(bytes32 fromChannelId, bytes memory allocationBytes, bytes32 destination) public {
        // checks
        _requireCorrectAllocationHash(fromChannelId, allocationBytes);
        // effects and interactions
        _transfer(fromChannelId, allocationBytes, destination);
    }

    /**
     * @notice Transfers the funds escrowed against `channelId` to the beneficiaries of that channel. Checks against the storage in this contract.
     * @dev Transfers the funds escrowed against `channelId` and transfers them to the beneficiaries of that channel. Checks against the storage in this contract.
     * @param channelId Unique identifier for a state channel.
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation
     */
    function transferAll(bytes32 channelId, bytes memory allocationBytes) public override {
        // checks
        _requireCorrectAllocationHash(channelId, allocationBytes);
        // effects and interactions
        _transferAll(channelId, allocationBytes);
    }

    /**
     * @notice Transfers the funds escrowed against `guarantorChannelId` to the beneficiaries of the __target__ of that channel. Checks against the storage in this contract.
     * @dev Transfers the funds escrowed against `guarantorChannelId` to the beneficiaries of the __target__ of that channel. Checks against the storage in this contract.
     * @param guarantorChannelId Unique identifier for a guarantor state channel.
     * @param guaranteeBytes The abi.encode of Outcome.Guarantee
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation for the __target__
     */
    function claimAll(
        bytes32 guarantorChannelId,
        bytes memory guaranteeBytes,
        bytes memory allocationBytes
    ) public override {
        // checks
        _requireCorrectGuaranteeHash(guarantorChannelId, guaranteeBytes);
        Outcome.Guarantee memory guarantee = abi.decode(guaranteeBytes, (Outcome.Guarantee));
        _requireCorrectAllocationHash(guarantee.targetChannelId, allocationBytes);
        // effects and interactions
        _claimAll(guarantorChannelId,guarantee, allocationBytes);
    }


    
    // **************
    // Permissioned methods
    // **************

    modifier AdjudicatorOnly {
        require(msg.sender == AdjudicatorAddress, 'Only the NitroAdjudicator is authorized');
        _;
    }

        /**
     * @notice Transfers the funds escrowed against `channelId` to the beneficiaries of that channel. No checks performed against storage in this contract. Permissioned.
     * @dev Transfers the funds escrowed against `channelId` and transfers them to the beneficiaries of that channel. No checks performed against storage in this contract. Permissioned.
     * @param channelId Unique identifier for a state channel.
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation
     */
    function transferAllAdjudicatorOnly(bytes32 channelId, bytes calldata allocationBytes)
        external
        virtual
        AdjudicatorOnly
    {
        // no checks
        //
        // effects and interactions
        _transferAll(channelId, allocationBytes);
    }


    /**
     * @notice Sets the given assetOutcomeHash for the given channelId in the assetOutcomeHashes storage mapping.
     * @dev Sets the given assetOutcomeHash for the given channelId in the assetOutcomeHashes storage mapping.
     * @param channelId Unique identifier for a state channel.
     * @param assetOutcomeHash The keccak256 of the abi.encode of the Outcome.
     */
    function setAssetOutcomeHash(bytes32 channelId, bytes32 assetOutcomeHash)
        external
        AdjudicatorOnly
        returns (bool success)
    {
        _setAssetOutcomeHash(channelId, assetOutcomeHash);
        return true;
    }

    // **************
    // Internal methods
    // **************
    
    /**
     * @notice Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries. Does not check allocationBytes against on chain storage.
     * @dev Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries. Does not check allocationBytes against on chain storage.
     * @param fromChannelId Unique identifier for state channel to transfer funds *from*.
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation
     * @param destination External destination or channel to transfer funds *to*.
     */
    function _transfer(bytes32 fromChannelId, bytes memory allocationBytes, bytes32 destination) internal {
        Outcome.AllocationItem[] memory allocation = abi.decode(
            allocationBytes,
            (Outcome.AllocationItem[])
        );
        uint256 balance = holdings[fromChannelId];
        uint256 affordsForDestination;
        uint256 residualAllocationAmount;
        uint256 _amount;
        uint256 i;
        bool deleteHash = false;

        // loop over allocations and decrease balance until we hit the specified destination
        for (i = 0; i < allocation.length; i++) {
            if (balance == 0) {
                revert('_transfer | fromChannel affords 0 for destination');
            }
            _amount = allocation[i].amount;
            if (allocation[i].destination == destination) {
                 if (balance < _amount) {
                    affordsForDestination = balance;
                    residualAllocationAmount = _amount - balance;
                    balance = 0;
                } else {
                    affordsForDestination = _amount;
                    residualAllocationAmount = 0;
                    balance = balance.sub(_amount);
                }
            break; // means that i holds the index of the destination that may need to be altered or removed
            }
            if (balance < _amount) {
                balance = 0;
            } else {
                balance = balance.sub(_amount);
            }
        }

        require(affordsForDestination > 0, '_transfer fromChannel allocates 0 to destination');
        
        // effects
        holdings[fromChannelId] -= affordsForDestination;

        // construct new outcome

        bytes memory encodedAllocation; 

        if (residualAllocationAmount > 0) {
            // new allocation identical save for a single entry 
            Outcome.AllocationItem[] memory newAllocation = new Outcome.AllocationItem[](
                allocation.length
            );
            for (uint256 k = 0; k < allocation.length; k++) {
                newAllocation[k] = allocation[k];
                if (allocation[k].destination == destination) {
                    newAllocation[k].amount = residualAllocationAmount;
                }
            }
            encodedAllocation = abi.encode(newAllocation);
        }

        if (residualAllocationAmount == 0) {
            Outcome.AllocationItem[] memory splicedAllocation = new Outcome.AllocationItem[](
                allocation.length - 1
            );
            // full payout so we want to splice a shorter outcome
            for (uint256 k = 0; k < i; k++) {
                splicedAllocation[k] = allocation[k];
            }
            for (uint256 k = i + 1; k < allocation.length; k++) {
                splicedAllocation[k - 1] = allocation[k];
            }
            if (splicedAllocation.length == 0) {
                deleteHash = true;
            }
            encodedAllocation = abi.encode(splicedAllocation);
        }

        // replace or delete hash
        if (deleteHash) {
            delete assetOutcomeHashes[fromChannelId];
        } else {
            assetOutcomeHashes[fromChannelId] = keccak256(
                abi.encode(
                    Outcome.AssetOutcome(
                        uint8(Outcome.AssetOutcomeType.Allocation),
                        encodedAllocation
                    )
                )
            );
        } 


        // storage updated BEFORE external contracts called (prevent reentrancy attacks)
        if (_isExternalDestination(destination)) {
            _transferAsset(_bytes32ToAddress(destination), affordsForDestination);    
        } else {
            holdings[destination] += affordsForDestination;
        }
        // Event emitted regardless of success of external calls
        emit AssetTransferred(fromChannelId, destination, affordsForDestination);

        
    }

    /**
     * @notice Transfers the funds escrowed against `channelId` to the beneficiaries of that channel. Does not check allocationBytes against on chain storage.
     * @dev Transfers the funds escrowed against `channelId` and transfers them to the beneficiaries of that channel. Does not check allocationBytes against on chain storage.
     * @param channelId Unique identifier for a state channel.
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation
     */
    function _transferAll(bytes32 channelId, bytes memory allocationBytes) internal {
        Outcome.AllocationItem[] memory allocation = abi.decode(
            allocationBytes,
            (Outcome.AllocationItem[])
        );
        uint256 balance = holdings[channelId];
        uint256 numPayouts = 0;
        uint256 numNewAllocationItems = allocation.length;
        uint256 _amount;
        bool overlap;
        uint256 finalPayoutAmount;
        uint256 firstNewAllocationItemAmount;

        for (uint256 i = 0; i < allocation.length; i++) {
            if (balance == 0) {
                // if funds are completely depleted, keep the allocationItem and do not pay out
                break;
            } else {
                _amount = allocation[i].amount;
                if (balance < _amount) {
                    // if funds still exist but are insufficient for this allocationItem, payout what's available and keep the allocationItem (but reduce the amount allocated)
                    // this block is never executed more than once
                    numPayouts++;
                    overlap = true;
                    finalPayoutAmount = balance;
                    firstNewAllocationItemAmount = _amount.sub(balance);
                    balance = 0;
                } else {
                    // if ample funds still exist, pay them out and discard the allocationItem
                    numPayouts++;
                    numNewAllocationItems = numNewAllocationItems.sub(1);
                    balance = balance.sub(_amount);
                }
            }
        }

        // effects
        holdings[channelId] = balance;

        if (numNewAllocationItems > 0) {
            // construct newAllocation
            Outcome.AllocationItem[] memory newAllocation = new Outcome.AllocationItem[](
                numNewAllocationItems
            );
            for (uint256 k = 0; k < numNewAllocationItems; k++) {
                newAllocation[k] = allocation[allocation.length.sub(numNewAllocationItems).add(k)];
                if (overlap && k == 0) {
                    newAllocation[k].amount = firstNewAllocationItemAmount;
                }
            }

            // store hash
            assetOutcomeHashes[channelId] = keccak256(
                abi.encode(
                    Outcome.AssetOutcome(
                        uint8(Outcome.AssetOutcomeType.Allocation),
                        abi.encode(newAllocation)
                    )
                )
            );
        } else {
            delete assetOutcomeHashes[channelId];
        }


        // holdings updated BEFORE asset transferred (prevent reentrancy attacks)
        uint256 payoutAmount;
        for (uint256 m = 0; m < numPayouts; m++) {
            if (overlap && m == numPayouts.sub(1)) {
                payoutAmount = finalPayoutAmount;
            } else {
                payoutAmount = allocation[m].amount;
            }
            if (_isExternalDestination(allocation[m].destination)) {
                _transferAsset(_bytes32ToAddress(allocation[m].destination), payoutAmount);
            } else {
                holdings[allocation[m].destination] += payoutAmount;
            }
            // Event emitted regardless of success of external calls
            emit AssetTransferred(channelId, allocation[m].destination, payoutAmount);
        }
    }


    /**
     * @notice Transfers the funds escrowed against `guarantorChannelId` to the beneficiaries of the __target__ of that channel. Does not check allocationBytes against on chain storage.
     * @dev Transfers the funds escrowed against `guarantorChannelId` to the beneficiaries of the __target__ of that channel. Does not check allocationBytes against on chain storage.
     * @param guarantorChannelId Unique identifier for a guarantor state channel.
     * @param guarantee The guarantee
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation for the __target__
     */
    function _claimAll(
        bytes32 guarantorChannelId,
        Outcome.Guarantee memory guarantee,
        bytes memory allocationBytes
    ) internal {
        uint256 balance = holdings[guarantorChannelId];

        Outcome.AllocationItem[] memory allocation = abi.decode(
            allocationBytes,
            (Outcome.AllocationItem[])
        ); // this remains constant length

        uint256[] memory payouts = new uint256[](allocation.length);
        uint256 newAllocationLength = allocation.length;

        // first increase payouts according to guarantee
        for (uint256 i = 0; i < guarantee.destinations.length; i++) {
            if (balance == 0) {
                break;
            }
            // for each destination in the guarantee
            bytes32 _destination = guarantee.destinations[i];
            for (uint256 j = 0; j < allocation.length; j++) {
                if (balance == 0) {
                    break;
                }
                if (_destination == allocation[j].destination) {
                    // find amount allocated to that destination (if it exists in channel alllocation)
                    uint256 _amount = allocation[j].amount;
                    if (_amount > 0) {
                        if (balance >= _amount) {
                            balance = balance.sub(_amount);
                            allocation[j].amount = 0; // subtract _amount;
                            newAllocationLength = newAllocationLength.sub(1);
                            payouts[j] += _amount;
                            break;
                        } else {
                            allocation[j].amount = _amount.sub(balance);
                            payouts[j] += balance;
                            balance = 0;
                            break;
                        }
                    }
                }
            }
        }

        // next, increase payouts according to original allocation order
        // this block only has an effect if balance > 0
        for (uint256 j = 0; j < allocation.length; j++) {
            // for each entry in the target channel's outcome
            if (balance == 0) {
                break;
            }
            uint256 _amount = allocation[j].amount;
            if (_amount > 0) {
                if (balance >= _amount) {
                    balance = balance.sub(_amount);
                    allocation[j].amount = 0; // subtract _amount;
                    newAllocationLength = newAllocationLength.sub(1);
                    payouts[j]+= _amount;
                } else {
                    allocation[j].amount = _amount.sub(balance);
                    payouts[j]+= balance;
                    balance = 0;
                }
            }
        }

        // EFFECTS
        holdings[guarantorChannelId] = balance;
       

        // at this point have payouts array of uint256s, each corresponding to original destinations
        // and allocations has some zero amounts which we want to prune
        Outcome.AllocationItem[] memory newAllocation;
        if (newAllocationLength > 0) {
            newAllocation = new Outcome.AllocationItem[](newAllocationLength);
        }

        uint256 k = 0;
        for (uint256 j = 0; j < allocation.length; j++) {
            // for each destination in the target channel's allocation
            if (allocation[j].amount > 0) {
                newAllocation[k] = allocation[j];
                k++;
            }
        }
        assert(k == newAllocationLength);

        if (newAllocationLength > 0) {
            // store hash
            assetOutcomeHashes[guarantee.targetChannelId] = keccak256(
                abi.encode(
                    Outcome.AssetOutcome(
                        uint8(Outcome.AssetOutcomeType.Allocation),
                        abi.encode(newAllocation)
                    )
                )
            );
        } else {
            delete assetOutcomeHashes[guarantorChannelId];
            delete assetOutcomeHashes[guarantee.targetChannelId];
        }

        // INTERACTIONS
        for (uint256 j = 0; j < allocation.length; j++) {
            // for each destination in the target channel's allocation
            if (payouts[j] > 0) {
                if (_isExternalDestination(allocation[j].destination)) {
                    _transferAsset(_bytes32ToAddress(allocation[j].destination), payouts[j]);
                } else {
                    holdings[allocation[j].destination] += payouts[j];
                }
            emit AssetTransferred(
                        guarantorChannelId,
                        allocation[j].destination,
                        payouts[j]
                    );
            }
        }
    }
   

    /**
     * @notice Sets the given assetOutcomeHash for the given channelId in the assetOutcomeHashes storage mapping
     * @dev Sets the given assetOutcomeHash for the given channelId in the assetOutcomeHashes storage mapping
     * @param channelId Unique identifier for a state channel.
     * @param assetOutcomeHash The keccak256 of the abi.encode of the Outcome.
     */
    function _setAssetOutcomeHash(bytes32 channelId, bytes32 assetOutcomeHash) internal {
        require(assetOutcomeHashes[channelId] == bytes32(0), 'Outcome hash already exists');
        assetOutcomeHashes[channelId] = assetOutcomeHash;
    }

    /**
     * @notice Transfers the given amount of this AssetHolders's asset type to a supplied ethereum address.
     * @dev Transfers the given amount of this AssetHolders's asset type to a supplied ethereum address.
     * @param destination ethereum address to be credited.
     * @param amount Quantity of assets to be transferred.
     */
    function _transferAsset(address payable destination, uint256 amount) internal virtual {}

    /**
     * @notice Checks if a given destination is external (and can therefore have assets transferred to it) or not.
     * @dev Checks if a given destination is external (and can therefore have assets transferred to it) or not.
     * @param destination Destination to be checked.
     * @return True if the destination is external, false otherwise.
     */
    function _isExternalDestination(bytes32 destination) internal pure returns (bool) {
        return uint96(bytes12(destination)) == 0;
    }

    /**
     * @notice Converts an ethereum address to a nitro external destination.
     * @dev Converts an ethereum address to a nitro external destination.
     * @param participant The address to be converted.
     * @return The input address left-padded with zeros.
     */
    function _addressToBytes32(address participant) internal pure returns (bytes32) {
        return bytes32(uint256(participant));
    }

    /**
     * @notice Converts a nitro destination to an ethereum address.
     * @dev Converts a nitro destination to an ethereum address.
     * @param destination The destination to be converted.
     * @return The rightmost 160 bits of the input string.
     */
    function _bytes32ToAddress(bytes32 destination) internal pure returns (address payable) {
        return address(uint160(uint256(destination)));
    }

    // **************
    // Requirers
    // **************

    function _requireCorrectAllocationHash(bytes32 channelId, bytes memory allocationBytes) internal view {
        require(
            assetOutcomeHashes[channelId] ==
                keccak256(
                    abi.encode(
                        Outcome.AssetOutcome(
                            uint8(Outcome.AssetOutcomeType.Allocation),
                            allocationBytes
                        )
                    )
                ),
            'AssetHolder | submitted allocationBytes data does not match stored assetOutcomeHash'
        );
    }

    function _requireCorrectGuaranteeHash(bytes32 guarantorChannelId, bytes memory guaranteeBytes) internal view {
        require(
            assetOutcomeHashes[guarantorChannelId] ==
                keccak256(
                    abi.encode(
                        Outcome.AssetOutcome(
                            uint8(Outcome.AssetOutcomeType.Guarantee),
                            guaranteeBytes
                        )
                    )
                ),
            'AssetHolder | submitted guaranteeBytes data does not match stored assetOutcomeHash'
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/**
 * @dev The IAssetHolder interface calls for functions that allow assets to be transferred from one channel to other channel and/or external destinations, as well as for guarantees to be claimed.
 */
interface IAssetHolder {
    /**
     * @notice Transfers the funds escrowed against `channelId` to the beneficiaries of that channel.
     * @dev Transfers the funds escrowed against `channelId` and transfers them to the beneficiaries of that channel.
     * @param channelId Unique identifier for a state channel.
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation
     */
    function transferAll(bytes32 channelId, bytes calldata allocationBytes) external;

    /**
     * @notice Transfers the funds escrowed against `guarantorChannelId` to the beneficiaries of the __target__ of that channel.
     * @dev Transfers the funds escrowed against `guarantorChannelId` to the beneficiaries of the __target__ of that channel.
     * @param guarantorChannelId Unique identifier for a guarantor state channel.
     * @param guaranteeBytes The abi.encode of Outcome.Guarantee
     * @param allocationBytes The abi.encode of AssetOutcome.Allocation for the __target__
     */
    function claimAll(
        bytes32 guarantorChannelId,
        bytes calldata guaranteeBytes,
        bytes calldata allocationBytes
    ) external;

    /**
     * @dev Indicates that `amountDeposited` has been deposited into `destination`.
     * @param destination The channel being deposited into.
     * @param amountDeposited The amount being deposited.
     * @param destinationHoldings The new holdings for `destination`.
     */
    event Deposited(
        bytes32 indexed destination,
        uint256 amountDeposited,
        uint256 destinationHoldings
    );

    /**
     * @dev Indicates that `amount` assets have been transferred (internally or externally) to the destination denoted by `destination`.
     * @param channelId The channelId of the funds being withdrawn.
     * @param destination An internal destination (channelId) of external destination (padded ethereum address)
     * @param amount Number of assets transferred (wei or tokens).
     */
    event AssetTransferred(bytes32 indexed channelId, bytes32 indexed destination, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import './AssetHolder.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Ther ERC20AssetHolder contract extends the AssetHolder contract, and adds the following functionality: it allows ERC20 tokens to be escrowed against a state channelId and to be transferred to external destinations.
 */
contract ERC20AssetHolder is AssetHolder {
    using SafeMath for uint256;

    IERC20 public Token;

    /**
     * @notice Constructor function storing the AdjudicatorAddress and instantiating an interface to an ERC20 Token contract.
     * @dev Constructor function storing the AdjudicatorAddress and instantiating an interface to an ERC20 Token contract.
     * @param _AdjudicatorAddress Address of an Adjudicator  contract, supplied at deploy-time.
     * @param _TokenAddress Address of an ERC20 Token  contract, supplied at deploy-time.
     */
    constructor(address _AdjudicatorAddress, address _TokenAddress) {
        AdjudicatorAddress = _AdjudicatorAddress;
        Token = IERC20(_TokenAddress);
    }

    /**
     * @notice Deposit ERC20 tokens against a given destination.
     * @dev Deposit ERC20 tokens against a given destination.
     * @param destination ChannelId to be credited.
     * @param expectedHeld The amount of tokens that the depositor believes are _already_ escrowed against the channelId.
     * @param amount The intended number of tokens to be deposited.
     */
    function deposit(
        bytes32 destination,
        uint256 expectedHeld,
        uint256 amount
    ) public {
        require(!_isExternalDestination(destination), 'Cannot deposit to external destination');
        uint256 amountDeposited;
        // this allows participants to reduce the wait between deposits, while protecting them from losing funds by depositing too early. Specifically it protects against the scenario:
        // 1. Participant A deposits
        // 2. Participant B sees A's deposit, which means it is now safe for them to deposit
        // 3. Participant B submits their deposit
        // 4. The chain re-orgs, leaving B's deposit in the chain but not A's
        require(
            holdings[destination] >= expectedHeld,
            'Deposit | holdings[destination] is less than expected'
        );
        require(
            holdings[destination] < expectedHeld.add(amount),
            'Deposit | holdings[destination] already meets or exceeds expectedHeld + amount'
        );

        // The depositor wishes to increase the holdings against channelId to amount + expectedHeld
        // The depositor need only deposit (at most) amount + (expectedHeld - holdings) (the term in parentheses is non-positive)

        amountDeposited = expectedHeld.add(amount).sub(holdings[destination]); // strictly positive
        // require successful deposit before updating holdings (protect against reentrancy)
        require(
            Token.transferFrom(msg.sender, address(this), amountDeposited),
            'Could not deposit ERC20s'
        );
        holdings[destination] = holdings[destination].add(amountDeposited);
        emit Deposited(destination, amountDeposited, holdings[destination]);
    }

    /**
     * @notice Transfers the given amount of ERC20 tokens to a supplied ethereum address.
     * @dev Transfers the given amount of ERC20 tokens to a supplied ethereum address.
     * @param destination Ethereum address to be credited.
     * @param amount Quantity of tokens to be transferred.
     */
    function _transferAsset(address payable destination, uint256 amount) internal virtual override {
        require(Token.transfer(destination, amount), 'Could not transfer ERC20 tokens');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "../../governance/Governed.sol";

/**
 * @title Graph Testnet stablecoin contract
 * @dev This is the implementation of an ERC20 stablecoin used for experiments on testnet.
 */
contract GDAI is Governed, ERC20, ERC20Burnable {
    address public GSR;

    /**
     * @dev GDAI constructor.
     */
    constructor() ERC20("Graph DAI", "GDAI") {
        Governed._initialize(msg.sender);

        // The Governor is sent all tokens
        _mint(msg.sender, 100000000 ether); // 100,000,000 GDAI
    }

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernorOrGSR {
        require(msg.sender == governor || msg.sender == GSR, "Only Governor or GSR can call");
        _;
    }

    function setGSR(address _GSR) external onlyGovernor {
        GSR = _GSR;
    }

    /**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external onlyGovernorOrGSR {
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../../governance/Governed.sol";
import "./GDAI.sol";

/**
 * @title Graph Saving Rate contract
 * Heavily influenced by Maker DAI savings rate
 * https://github.com/makerdao/dss/blob/master/src/pot.sol
 * @dev This contracts receives GDAI deposits and provides an interests rate for use in testnet.
 */

contract GSRManager is Governed {
    using SafeMath for uint256;

    uint256 private constant ISSUANCE_RATE_DECIMALS = 1e18;
    uint256 public savingsRate; // savings rate being earned (dsr in DSR)
    uint256 public reserves; // total interest bearing GDAI (Pie in DSR)
    uint256 public cumulativeInterestRate; // cumulative interest rate of the contract (chi in DSR)
    uint256 public lastDripTime; // Last time drip was called (rho in DSR)
    mapping(address => uint256) public balances; // balance of interest bearing GDAI (pie in DSR)
    GDAI public token; // GDAI

    event SetRate(uint256 newRate);
    event Drip(uint256 cumulativeInterestRate, uint256 lastDripTime);
    event Join(address indexed account, uint256 gdai, uint256 gsrBalance);
    event Exit(address indexed account, uint256 gsrBalance, uint256 gdai);

    /**
     * @dev Graph Saving Rate constructor.
     */
    constructor(uint256 _savingsRate, address _gdai) {
        require(_savingsRate != 0, "Savings rate can't be zero");
        Governed._initialize(msg.sender);
        cumulativeInterestRate = ISSUANCE_RATE_DECIMALS;
        lastDripTime = block.timestamp;
        savingsRate = _savingsRate;
        token = GDAI(_gdai);
    }

    // Governance sets savings rate
    function setRate(uint256 _newRate) external onlyGovernor {
        require(_newRate != 0, "Savings rate can't be zero");
        drip();
        savingsRate = _newRate;
        emit SetRate(savingsRate);
    }

    // Update the rate and mint tokens
    // We enforce drip to always be called by all state changing functions. Lessens require statements
    function drip() public returns (uint256 updatedRate) {
        updatedRate = calcUpdatedRate();
        uint256 rateDifference = updatedRate.sub(cumulativeInterestRate);
        cumulativeInterestRate = updatedRate;
        lastDripTime = block.timestamp;
        token.mint(address(this), reserves.mul(rateDifference).div(ISSUANCE_RATE_DECIMALS));
        emit Drip(cumulativeInterestRate, lastDripTime);
    }

    // Someone enters
    function join(uint256 _amount) external {
        drip();
        uint256 savingsBalance = _amount.mul(ISSUANCE_RATE_DECIMALS).div(cumulativeInterestRate);
        balances[msg.sender] = balances[msg.sender].add(savingsBalance);
        reserves = reserves.add(savingsBalance);
        token.transferFrom(msg.sender, address(this), _amount);
        emit Join(msg.sender, _amount, savingsBalance);
    }

    // Someone exits
    function exit(uint256 _amount) external {
        drip();
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        uint256 withdrawnAmount = _amount.mul(cumulativeInterestRate).div(ISSUANCE_RATE_DECIMALS);
        reserves = reserves.sub(_amount);
        token.transfer(msg.sender, withdrawnAmount);
        emit Exit(msg.sender, _amount, withdrawnAmount);
    }

    // Calculate the new cumulative interest rate
    function calcUpdatedRate() public view returns (uint256 updatedRate) {
        updatedRate = cumulativeInterestRate
            .mul(_pow(savingsRate, block.timestamp - lastDripTime, ISSUANCE_RATE_DECIMALS))
            .div(ISSUANCE_RATE_DECIMALS);
    }

    // Calculate the total balance a user would have if they withdrew
    function calcReturn(address _account) external view returns (uint256 totalBalance) {
        uint256 updatedRate = calcUpdatedRate();
        totalBalance = balances[_account].mul(updatedRate).div(ISSUANCE_RATE_DECIMALS);
    }

    /** TODO - have a math library and use it here and in RewardsMAnager
     * @dev Raises x to the power of n with scaling factor of base.
     * Based on: https://github.com/makerdao/dss/blob/master/src/pot.sol#L81
     * @param x Base of the exponentiation
     * @param n Exponent
     * @param base Scaling factor
     * @return z Exponential of n with base x
     */
    function _pow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := base
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := base
                        }
                        default {
                            z := x
                        }
                    let half := div(base, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, base)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, base)
                        }
                    }
                }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../governance/Governed.sol";

/**
 * @title GraphCurationToken contract
 * @dev This is the implementation of the Curation ERC20 token (GCS).
 * GCS are created for each subgraph deployment curated in the Curation contract.
 * The Curation contract is the owner of GCS tokens and the only one allowed to mint or
 * burn them. GCS tokens are transferrable and their holders can do any action allowed
 * in a standard ERC20 token implementation except for burning them.
 */
contract GraphCurationToken is ERC20, Governed {
    /**
     * @dev Graph Curation Token Contract Constructor.
     * @param _owner Address of the contract issuing this token
     */
    constructor(address _owner) ERC20("Graph Curation Share", "GCS") {
        Governed._initialize(_owner);
    }

    /**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) public onlyGovernor {
        _mint(_to, _amount);
    }

    /**
     * @dev Burn tokens from an address.
     * @param _account Address from where tokens will be burned
     * @param _amount Amount of tokens to burn
     */
    function burnFrom(address _account, uint256 _amount) public onlyGovernor {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../bancor/BancorFormula.sol";
import "../upgrades/GraphUpgradeable.sol";

import "./CurationStorage.sol";
import "./ICuration.sol";
import "./GraphCurationToken.sol";

/**
 * @title Curation contract
 * @dev Allows curators to signal on subgraph deployments that might be relevant to indexers by
 * staking Graph Tokens (GRT). Additionally, curators earn fees from the Query Market related to the
 * subgraph deployment they curate.
 * A curators deposit goes to a curation pool along with the deposits of other curators,
 * only one such pool exists for each subgraph deployment.
 * The contract mints Graph Curation Shares (GCS) according to a bonding curve for each individual
 * curation pool where GRT is deposited.
 * Holders can burn GCS using this contract to get GRT tokens back according to the
 * bonding curve.
 */
contract Curation is CurationV1Storage, GraphUpgradeable, ICuration {
    using SafeMath for uint256;

    // 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    // Amount of signal you get with your minimum token deposit
    uint256 private constant SIGNAL_PER_MINIMUM_DEPOSIT = 1e18; // 1 signal as 18 decimal number

    // -- Events --

    /**
     * @dev Emitted when `curator` deposited `tokens` on `subgraphDeploymentID` as curation signal.
     * The `curator` receives `signal` amount according to the curation pool bonding curve.
     * An amount of `curationTax` will be collected and burned.
     */
    event Signalled(
        address indexed curator,
        bytes32 indexed subgraphDeploymentID,
        uint256 tokens,
        uint256 signal,
        uint256 curationTax
    );

    /**
     * @dev Emitted when `curator` burned `signal` for a `subgraphDeploymentID`.
     * The curator will receive `tokens` according to the value of the bonding curve.
     */
    event Burned(
        address indexed curator,
        bytes32 indexed subgraphDeploymentID,
        uint256 tokens,
        uint256 signal
    );

    /**
     * @dev Emitted when `tokens` amount were collected for `subgraphDeploymentID` as part of fees
     * distributed by an indexer from query fees received from state channels.
     */
    event Collected(bytes32 indexed subgraphDeploymentID, uint256 tokens);

    /**
     * @dev Initialize this contract.
     */
    function initialize(
        address _controller,
        address _bondingCurve,
        uint32 _defaultReserveRatio,
        uint32 _curationTaxPercentage,
        uint256 _minimumCurationDeposit
    ) external onlyImpl {
        Managed._initialize(_controller);

        require(_bondingCurve != address(0), "Bonding curve must be set");
        bondingCurve = _bondingCurve;

        // Settings
        _setDefaultReserveRatio(_defaultReserveRatio);
        _setCurationTaxPercentage(_curationTaxPercentage);
        _setMinimumCurationDeposit(_minimumCurationDeposit);
    }

    /**
     * @dev Set the default reserve ratio percentage for a curation pool.
     * @notice Update the default reserver ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external override onlyGovernor {
        _setDefaultReserveRatio(_defaultReserveRatio);
    }

    /**
     * @dev Internal: Set the default reserve ratio percentage for a curation pool.
     * @notice Update the default reserver ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function _setDefaultReserveRatio(uint32 _defaultReserveRatio) private {
        // Reserve Ratio must be within 0% to 100% (inclusive, in PPM)
        require(_defaultReserveRatio > 0, "Default reserve ratio must be > 0");
        require(
            _defaultReserveRatio <= MAX_PPM,
            "Default reserve ratio cannot be higher than MAX_PPM"
        );

        defaultReserveRatio = _defaultReserveRatio;
        emit ParameterUpdated("defaultReserveRatio");
    }

    /**
     * @dev Set the minimum deposit amount for curators.
     * @notice Update the minimum deposit amount to `_minimumCurationDeposit`
     * @param _minimumCurationDeposit Minimum amount of tokens required deposit
     */
    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit)
        external
        override
        onlyGovernor
    {
        _setMinimumCurationDeposit(_minimumCurationDeposit);
    }

    /**
     * @dev Internal: Set the minimum deposit amount for curators.
     * @notice Update the minimum deposit amount to `_minimumCurationDeposit`
     * @param _minimumCurationDeposit Minimum amount of tokens required deposit
     */
    function _setMinimumCurationDeposit(uint256 _minimumCurationDeposit) private {
        require(_minimumCurationDeposit > 0, "Minimum curation deposit cannot be 0");

        minimumCurationDeposit = _minimumCurationDeposit;
        emit ParameterUpdated("minimumCurationDeposit");
    }

    /**
     * @dev Set the curation tax percentage to charge when a curator deposits GRT tokens.
     * @param _percentage Curation tax percentage charged when depositing GRT tokens
     */
    function setCurationTaxPercentage(uint32 _percentage) external override onlyGovernor {
        _setCurationTaxPercentage(_percentage);
    }

    /**
     * @dev Internal: Set the curation tax percentage to charge when a curator deposits GRT tokens.
     * @param _percentage Curation tax percentage charged when depositing GRT tokens
     */
    function _setCurationTaxPercentage(uint32 _percentage) private {
        require(
            _percentage <= MAX_PPM,
            "Curation tax percentage must be below or equal to MAX_PPM"
        );

        _curationTaxPercentage = _percentage;
        emit ParameterUpdated("curationTaxPercentage");
    }

    /**
     * @dev Assign Graph Tokens collected as curation fees to the curation pool reserve.
     * This function can only be called by the Staking contract and will do the bookeeping of
     * transferred tokens into this contract.
     * @param _subgraphDeploymentID SubgraphDeployment where funds should be allocated as reserves
     * @param _tokens Amount of Graph Tokens to add to reserves
     */
    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external override {
        // Only Staking contract is authorized as caller
        require(msg.sender == address(staking()), "Caller must be the staking contract");

        // Must be curated to accept tokens
        require(
            isCurated(_subgraphDeploymentID),
            "Subgraph deployment must be curated to collect fees"
        );

        // Collect new funds into reserve
        CurationPool storage curationPool = pools[_subgraphDeploymentID];
        curationPool.tokens = curationPool.tokens.add(_tokens);

        emit Collected(_subgraphDeploymentID, _tokens);
    }

    /**
     * @dev Deposit Graph Tokens in exchange for signal of a SubgraphDeployment curation pool.
     * @param _subgraphDeploymentID Subgraph deployment pool from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @param _signalOutMin Expected minimum amount of signal to receive
     * @return Signal minted and deposit tax
     */
    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external override notPartialPaused returns (uint256, uint256) {
        // Need to deposit some funds
        require(_tokensIn > 0, "Cannot deposit zero tokens");

        // Exchange GRT tokens for GCS of the subgraph pool
        (uint256 signalOut, uint256 curationTax) = tokensToSignal(_subgraphDeploymentID, _tokensIn);

        // Slippage protection
        require(signalOut >= _signalOutMin, "Slippage protection");

        address curator = msg.sender;
        CurationPool storage curationPool = pools[_subgraphDeploymentID];

        // If it hasn't been curated before then initialize the curve
        if (!isCurated(_subgraphDeploymentID)) {
            // Initialize
            curationPool.reserveRatio = defaultReserveRatio;

            // If no signal token for the pool - create one
            if (address(curationPool.gcs) == address(0)) {
                // TODO: Use a minimal proxy to reduce gas cost
                // https://github.com/graphprotocol/contracts/issues/405
                // --abarmat-- 20201113
                curationPool.gcs = IGraphCurationToken(
                    address(new GraphCurationToken(address(this)))
                );
            }
        }

        // Trigger update rewards calculation snapshot
        _updateRewards(_subgraphDeploymentID);

        // Transfer tokens from the curator to this contract
        // This needs to happen after _updateRewards snapshot as that function
        // is using balanceOf(curation)
        IGraphToken graphToken = graphToken();
        require(
            graphToken.transferFrom(curator, address(this), _tokensIn),
            "Cannot transfer tokens to deposit"
        );

        // Burn withdrawal fees
        if (curationTax > 0) {
            graphToken.burn(curationTax);
        }

        // Update curation pool
        curationPool.tokens = curationPool.tokens.add(_tokensIn.sub(curationTax));
        curationPool.gcs.mint(curator, signalOut);

        emit Signalled(curator, _subgraphDeploymentID, _tokensIn, signalOut, curationTax);

        return (signalOut, curationTax);
    }

    /**
     * @dev Return an amount of signal to get tokens back.
     * @notice Burn _signal from the SubgraphDeployment curation pool
     * @param _subgraphDeploymentID SubgraphDeployment the curator is returning signal
     * @param _signalIn Amount of signal to return
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     * @return Tokens returned
     */
    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external override notPartialPaused returns (uint256) {
        address curator = msg.sender;

        // Validations
        require(_signalIn > 0, "Cannot burn zero signal");
        require(
            getCuratorSignal(curator, _subgraphDeploymentID) >= _signalIn,
            "Cannot burn more signal than you own"
        );

        // Get the amount of tokens to refund based on returned signal
        uint256 tokensOut = signalToTokens(_subgraphDeploymentID, _signalIn);

        // Slippage protection
        require(tokensOut >= _tokensOutMin, "Slippage protection");

        // Trigger update rewards calculation
        _updateRewards(_subgraphDeploymentID);

        // Update curation pool
        CurationPool storage curationPool = pools[_subgraphDeploymentID];
        curationPool.tokens = curationPool.tokens.sub(tokensOut);
        curationPool.gcs.burnFrom(curator, _signalIn);

        // If all signal burnt delete the curation pool
        if (getCurationPoolSignal(_subgraphDeploymentID) == 0) {
            delete pools[_subgraphDeploymentID];
        }

        // Return the tokens to the curator
        require(graphToken().transfer(curator, tokensOut), "Error sending curator tokens");

        emit Burned(curator, _subgraphDeploymentID, tokensOut, _signalIn);

        return tokensOut;
    }

    /**
     * @dev Check if any GRT tokens are deposited for a SubgraphDeployment.
     * @param _subgraphDeploymentID SubgraphDeployment to check if curated
     * @return True if curated
     */
    function isCurated(bytes32 _subgraphDeploymentID) public override view returns (bool) {
        return pools[_subgraphDeploymentID].tokens > 0;
    }

    /**
     * @dev Get the amount of signal a curator has in a curation pool.
     * @param _curator Curator owning the signal tokens
     * @param _subgraphDeploymentID Subgraph deployment curation pool
     * @return Amount of signal owned by a curator for the subgraph deployment
     */
    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        public
        override
        view
        returns (uint256)
    {
        if (address(pools[_subgraphDeploymentID].gcs) == address(0)) {
            return 0;
        }
        return pools[_subgraphDeploymentID].gcs.balanceOf(_curator);
    }

    /**
     * @dev Get the amount of signal in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of signal minted for the subgraph deployment
     */
    function getCurationPoolSignal(bytes32 _subgraphDeploymentID)
        public
        override
        view
        returns (uint256)
    {
        if (address(pools[_subgraphDeploymentID].gcs) == address(0)) {
            return 0;
        }
        return pools[_subgraphDeploymentID].gcs.totalSupply();
    }

    /**
     * @dev Get the amount of token reserves in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of token reserves in the curation pool
     */
    function getCurationPoolTokens(bytes32 _subgraphDeploymentID)
        external
        override
        view
        returns (uint256)
    {
        return pools[_subgraphDeploymentID].tokens;
    }

    /**
     * @dev Get curation tax percentage
     * @return Amount the curation tax percentage in PPM
     */
    function curationTaxPercentage() external override view returns (uint32) {
        return _curationTaxPercentage;
    }

    /**
     * @dev Calculate amount of signal that can be bought with tokens in a curation pool.
     * This function considers and excludes the deposit tax.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought and tokens subtracted for the tax
     */
    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        public
        override
        view
        returns (uint256, uint256)
    {
        uint256 curationTax = _tokensIn.mul(uint256(_curationTaxPercentage)).div(MAX_PPM);
        uint256 signalOut = _tokensToSignal(_subgraphDeploymentID, _tokensIn.sub(curationTax));
        return (signalOut, curationTax);
    }

    /**
     * @dev Calculate amount of signal that can be bought with tokens in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought with tokens
     */
    function _tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        private
        view
        returns (uint256)
    {
        // Get curation pool tokens and signal
        CurationPool memory curationPool = pools[_subgraphDeploymentID];

        // Init curation pool
        if (curationPool.tokens == 0) {
            require(
                _tokensIn >= minimumCurationDeposit,
                "Curation deposit is below minimum required"
            );
            return
                BancorFormula(bondingCurve)
                    .calculatePurchaseReturn(
                    SIGNAL_PER_MINIMUM_DEPOSIT,
                    minimumCurationDeposit,
                    defaultReserveRatio,
                    _tokensIn.sub(minimumCurationDeposit)
                )
                    .add(SIGNAL_PER_MINIMUM_DEPOSIT);
        }

        return
            BancorFormula(bondingCurve).calculatePurchaseReturn(
                getCurationPoolSignal(_subgraphDeploymentID),
                curationPool.tokens,
                curationPool.reserveRatio,
                _tokensIn
            );
    }

    /**
     * @dev Calculate number of tokens to get when burning signal from a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment to burn signal
     * @param _signalIn Amount of signal to burn
     * @return Amount of tokens to get for an amount of signal
     */
    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        public
        override
        view
        returns (uint256)
    {
        CurationPool memory curationPool = pools[_subgraphDeploymentID];
        uint256 curationPoolSignal = getCurationPoolSignal(_subgraphDeploymentID);
        require(
            curationPool.tokens > 0,
            "Subgraph deployment must be curated to perform calculations"
        );
        require(
            curationPoolSignal >= _signalIn,
            "Signal must be above or equal to signal issued in the curation pool"
        );

        return
            BancorFormula(bondingCurve).calculateSaleReturn(
                curationPoolSignal,
                curationPool.tokens,
                curationPool.reserveRatio,
                _signalIn
            );
    }

    /**
     * @dev Triggers an update of rewards due to a change in signal.
     * @param _subgraphDeploymentID Subgraph deployment updated
     */
    function _updateRewards(bytes32 _subgraphDeploymentID) private {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) != address(0)) {
            rewardsManager.onSubgraphSignalUpdate(_subgraphDeploymentID);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ICuration.sol";
import "../governance/Managed.sol";

contract CurationV1Storage is Managed {
    // -- State --

    // Tax charged when curator deposit funds
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 internal _curationTaxPercentage;

    // Default reserve ratio to configure curator shares bonding curve
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public defaultReserveRatio;

    // Minimum amount allowed to be deposited by curators to initialize a pool
    // This is the `startPoolBalance` for the bonding curve
    uint256 public minimumCurationDeposit;

    // Bonding curve formula
    address public bondingCurve;

    // Mapping of subgraphDeploymentID => CurationPool
    // There is only one CurationPool per SubgraphDeploymentID
    mapping(bytes32 => ICuration.CurationPool) public pools;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@statechannels/nitro-protocol/contracts/ERC20AssetHolder.sol";

import "../governance/IController.sol";
import "../staking/IStaking.sol";

/// @title GRTAssetHolder - Container for funds used to pay an indexer off-chain
contract GRTAssetHolder is ERC20AssetHolder {
    uint256 private constant MAX_UINT256 = 2**256 - 1;

    IController public Controller;

    constructor(
        address _AdjudicatorAddress,
        address _TokenAddress,
        IController _Controller
    ) ERC20AssetHolder(_AdjudicatorAddress, _TokenAddress) {
        AdjudicatorAddress = _AdjudicatorAddress;
        Controller = _Controller;
    }

    function staking() public view returns (IStaking) {
        return IStaking(Controller.getContractProxy(keccak256("Staking")));
    }

    function approveAll() external {
        require(
            Token.approve(address(staking()), MAX_UINT256),
            "GRTAssetHolder: Token approval failed"
        );
    }

    function _transferAsset(address payable destination, uint256 amount) internal override {
        IStaking _staking = staking();

        if (_staking.isAllocation(destination)) {
            _staking.collect(amount, destination);
            return;
        }

        require(Token.transfer(destination, amount), "GRTAssetHolder: transferring tokens failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IController.sol";
import "./IManaged.sol";
import "./Governed.sol";
import "./Pausable.sol";

/**
 * @title Graph Controller contract
 * @dev Controller is a registry of contracts for convenience. Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
contract Controller is Governed, Pausable, IController {
    // Track contract ids to contract proxy address
    mapping(bytes32 => address) private registry;

    event SetContractProxy(bytes32 indexed id, address contractAddress);

    /** 
     * @dev Contract constructor.
     */
    constructor() {
        Governed._initialize(msg.sender);

        _setPaused(true);
    }

    /**
     * @dev Check if the caller is the governor or pause guardian.
     */
    modifier onlyGovernorOrGuardian {
        require(
            msg.sender == governor || msg.sender == pauseGuardian,
            "Only Governor or Guardian can call"
        );
        _;
    }

    /**
     * @notice Getter to access governor
     */
    function getGovernor() external override view returns (address) {
        return governor;
    }

    // -- Registry --

    /**
     * @notice Register contract id and mapped address
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _contractAddress Contract address
     */
    function setContractProxy(bytes32 _id, address _contractAddress)
        external
        override
        onlyGovernor
    {
        require(_contractAddress != address(0), "Contract address must be set");
        registry[_id] = _contractAddress;
        emit SetContractProxy(_id, _contractAddress);
    }

    /**
     * @notice Unregister a contract address
     * @param _id Contract id (keccak256 hash of contract name)
     */
    function unsetContractProxy(bytes32 _id)
        external
        override
        onlyGovernor
    {
        registry[_id] = address(0);
        emit SetContractProxy(_id, address(0));
    }

    /**
     * @notice Get contract proxy address by its id
     * @param _id Contract id
     */
    function getContractProxy(bytes32 _id) public override view returns (address) {
        return registry[_id];
    }

    /**
     * @notice Update contract's controller
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _controller Controller address
     */
    function updateController(bytes32 _id, address _controller) external override onlyGovernor {
        require(_controller != address(0), "Controller must be set");
        return IManaged(registry[_id]).setController(_controller);
    }

    // -- Pausing --

    /**
     * @notice Change the partial paused state of the contract
     * Partial pause is intended as a partial pause of the protocol
     */
    function setPartialPaused(bool _partialPaused) external override onlyGovernorOrGuardian {
        _setPartialPaused(_partialPaused);
    }

    /**
     * @notice Change the paused state of the contract
     * Full pause most of protocol functions
     */
    function setPaused(bool _paused) external override onlyGovernorOrGuardian {
        _setPaused(_paused);
    }

    /**
     * @notice Change the Pause Guardian
     * @param _newPauseGuardian The address of the new Pause Guardian
     */
    function setPauseGuardian(address _newPauseGuardian) external override onlyGovernor {
        require(_newPauseGuardian != address(0), "PauseGuardian must be set");
        _setPauseGuardian(_newPauseGuardian);
    }

    /**
     * @notice Getter to access paused
     */
    function paused() external override view returns (bool) {
        return _paused;
    }

    /**
     * @notice Getter to access partial pause status
     */
    function partialPaused() external override view returns (bool) {
        return _partialPaused;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract Pausable {
    // Partial paused paused exit and enter functions for GRT, but not internal
    // functions, such as allocating
    bool internal _partialPaused;
    // Paused will pause all major protocol functions
    bool internal _paused;

    // Time last paused for both pauses
    uint256 public lastPausePartialTime;
    uint256 public lastPauseTime;

    // Pause guardian is a separate entity from the governor that can pause
    address public pauseGuardian;

    event PartialPauseChanged(bool isPaused);
    event PauseChanged(bool isPaused);
    event NewPauseGuardian(address indexed oldPauseGuardian, address indexed pauseGuardian);

    /**
     * @notice Change the partial paused state of the contract
     */
    function _setPartialPaused(bool _toPause) internal {
        if (_toPause == _partialPaused) {
            return;
        }
        _partialPaused = _toPause;
        if (_partialPaused) {
            lastPausePartialTime = block.timestamp;
        }
        emit PartialPauseChanged(_partialPaused);
    }

    /**
     * @notice Change the paused state of the contract
     */
    function _setPaused(bool _toPause) internal {
        if (_toPause == _paused) {
            return;
        }
        _paused = _toPause;
        if (_paused) {
            lastPauseTime = block.timestamp;
        }
        emit PauseChanged(_paused);
    }

    /**
     * @notice Change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     */
    function _setPauseGuardian(address newPauseGuardian) internal {
        address oldPauseGuardian = pauseGuardian;
        pauseGuardian = newPauseGuardian;
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "../governance/Managed.sol";
import "../upgrades/GraphUpgradeable.sol";

import "./ServiceRegistryStorage.sol";
import "./IServiceRegistry.sol";

/**
 * @title ServiceRegistry contract
 * @dev This contract supports the service discovery process by allowing indexers to
 * register their service url and any other relevant information.
 */
contract ServiceRegistry is ServiceRegistryV1Storage, GraphUpgradeable, IServiceRegistry {
    // -- Events --

    event ServiceRegistered(address indexed indexer, string url, string geohash);
    event ServiceUnregistered(address indexed indexer);

    /**
     * @dev Check if the caller is authorized (indexer or operator)
     */
    function _isAuth(address _indexer) internal view returns (bool) {
        return msg.sender == _indexer || staking().isOperator(msg.sender, _indexer) == true;
    }

    /**
     * @dev Initialize this contract.
     */
    function initialize(address _controller) external onlyImpl {
        Managed._initialize(_controller);
    }

    /**
     * @dev Register an indexer service
     * @param _url URL of the indexer service
     * @param _geohash Geohash of the indexer service location
     */
    function register(string calldata _url, string calldata _geohash) external override {
        _register(msg.sender, _url, _geohash);
    }

    /**
     * @dev Register an indexer service
     * @param _indexer Address of the indexer
     * @param _url URL of the indexer service
     * @param _geohash Geohash of the indexer service location
     */
    function registerFor(
        address _indexer,
        string calldata _url,
        string calldata _geohash
    ) external override {
        _register(_indexer, _url, _geohash);
    }

    /**
     * @dev Internal: Register an indexer service
     * @param _indexer Address of the indexer
     * @param _url URL of the indexer service
     * @param _geohash Geohash of the indexer service location
     */
    function _register(
        address _indexer,
        string calldata _url,
        string calldata _geohash
    ) private {
        require(_isAuth(_indexer), "!auth");
        require(bytes(_url).length > 0, "Service must specify a URL");

        services[_indexer] = IndexerService(_url, _geohash);

        emit ServiceRegistered(_indexer, _url, _geohash);
    }

    /**
     * @dev Unregister an indexer service
     */
    function unregister() external override {
        _unregister(msg.sender);
    }

    /**
     * @dev Unregister an indexer service
     * @param _indexer Address of the indexer
     */
    function unregisterFor(address _indexer) external override {
        _unregister(_indexer);
    }

    /**
     * @dev Unregister an indexer service
     * @param _indexer Address of the indexer
     */
    function _unregister(address _indexer) private {
        require(_isAuth(_indexer), "!auth");
        require(isRegistered(_indexer), "Service already unregistered");

        delete services[_indexer];
        emit ServiceUnregistered(_indexer);
    }

    /**
     * @dev Return the registration status of an indexer service
     * @return True if the indexer service is registered
     */
    function isRegistered(address _indexer) public override view returns (bool) {
        return bytes(services[_indexer].url).length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../governance/Managed.sol";

import "./IServiceRegistry.sol";

contract ServiceRegistryV1Storage is Managed {
    // -- State --

    mapping(address => IServiceRegistry.IndexerService) public services;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IServiceRegistry {
    struct IndexerService {
        string url;
        string geohash;
    }

    function register(string calldata _url, string calldata _geohash) external;

    function registerFor(
        address _indexer,
        string calldata _url,
        string calldata _geohash
    ) external;

    function unregister() external;

    function unregisterFor(address _indexer) external;

    function isRegistered(address _indexer) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../governance/Governed.sol";

/**
 * @title GovernedMock contract
 */
contract GovernedMock is Governed {
    constructor() {
        Governed._initialize(msg.sender);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}