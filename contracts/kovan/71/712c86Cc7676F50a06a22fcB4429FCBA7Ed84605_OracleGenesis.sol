pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity 0.6.12;

/*
    Bancor Formula interface
*/
interface IBancorFormula {

}

pragma solidity >=0.5.11;

interface IBasicToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.6.12;

interface IBuyback {
    function swapExactInputSingle(uint amountIn) external returns (uint);
}

pragma solidity ^0.6.12;

interface IOracle {
    function getCollateralPrice(address collateralAddr) external view returns (uint);
    function getETHprice() external view returns (uint);
    function getSPAprice() external view returns (uint);
    function getUSDsPrice() external view returns (uint);
    function getUSDsPrice_average() external view returns (uint);
    function getCollateralPrice_prec(address collateralAddr) external view returns (uint);
    function getETHprice_prec() external view returns (uint);
    function getSPAprice_prec() external view returns (uint);
    function getUSDsPrice_prec() external view returns (uint);
    function updateInOutRatio() external;
    function USDsInOutRatio() external view returns (uint);
    function USDsInOutRatio_prec() external view returns (uint32);
}

pragma solidity >=0.5.0;

interface ISperaxToken {
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

    function burnFrom(address account, uint256 amount) external;
    function mintForUSDs(address account, uint256 amount) external;
}

pragma solidity ^0.6.12;

/**
 * @title Platform interface to integrate with lending platform like Compound, AAVE etc.
 */
interface IStrategy {
    /**
     * @dev Deposit the given collateral to platform
     * @param _collateral collateral address
     * @param _amount Amount to deposit
     */
    function deposit(address _collateral, uint256 _amount) external;

    /**
     * @dev Deposit the entire balance of all supported collaterals in the Strategy
     *      to the platform
     */
    function depositAll() external;

    /**
     * @dev Withdraw given collateral from Lending platform
     */
    function withdraw(
        address _recipient,
        address _collateral,
        uint256 _amount
    ) external;

    /**
     * @dev Liquidate all collaterals in strategy and return them to Vault.
     */
    function withdrawAll() external;

    /**
     * @dev Returns the current balance of the given collateral.
     */
    function checkBalance(address _collateral)
        external
        view
        returns (uint256 balance);

    function checkInterestEarned(address _collateral)
        external
        view
        returns (uint256 interestEarned);

    /**
     * @dev Returns bool indicating whether strategy supports collateral.
     */
    function supportsCollateral(address _collateral) external view returns (bool);

    /**
     * @dev Collect reward tokens from the Strategy.
     */
    function collectRewardToken() external;

    /**
     * @dev The address of the reward token for the Strategy.
     */
    function rewardTokenAddress() external pure returns (address);

    /**
     * @dev The threshold (denominated in the reward token) over which the
     * vault will auto harvest on allocate calls.
     */
    function rewardLiquidationThreshold() external pure returns (uint256);
}

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
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

    function sync() external;
}

pragma solidity ^0.6.12;
import "../libraries/BancorFormula.sol";

interface IVaultCore {
    function mintRedeemAllowed() external view returns (bool);
    function allocationAllowed() external view returns (bool);
    function rebaseAllowed() external view returns (bool);
    function swapfeeInAllowed() external view returns (bool);
    function swapfeeOutAllowed() external view returns (bool);
    function oracleAddr() external view returns (address);
    function startBlockHeight() external view returns (uint);
    function BancorInstance() external view returns (BancorFormula);
    function chi_alpha() external view returns (uint32);
    function chi_alpha_prec() external view returns (uint64);
    function chi_prec() external view returns (uint64);
    function chiInit() external view returns (uint64);
    function chi_beta() external view returns (uint32);
    function chi_beta_prec() external view returns (uint16);
    function chi_gamma() external view returns (uint32);
    function chi_gamma_prec() external view returns (uint16);
    function swapFee_prec() external view returns (uint64);
    function swapFee_p() external view returns (uint32);
    function swapFee_p_prec() external view returns (uint16);
    function swapFee_theta() external view returns (uint32);
    function swapFee_theta_prec() external view returns (uint16);
    function swapFee_a() external view returns (uint32);
    function swapFee_a_prec() external view returns (uint16);
    function swapFee_A() external view returns (uint32);
    function swapFee_A_prec() external view returns (uint16);
    function allocatePrecentage() external view returns (uint32);
    function allocatePrecentage_prec() external view returns (uint16);
    function collateralRatio() external view returns (uint);
}

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../interfaces/IBancorFormula.sol";

contract BancorFormula is IBancorFormula {
    using SafeMathUpgradeable for uint256;

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    // Auto-generated via 'PrintIntScalingFactors.py'
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    // Auto-generated via 'PrintLn2ScalingFactors.py'
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    // Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    // Auto-generated via 'PrintLambertFactors.py'
    uint256 private constant LAMBERT_CONV_RADIUS = 0x002f16ac6c59de6f8d5d6f63c1482a7c86;
    uint256 private constant LAMBERT_POS2_SAMPLE = 0x0003060c183060c183060c183060c18306;
    uint256 private constant LAMBERT_POS2_MAXVAL = 0x01af16ac6c59de6f8d5d6f63c1482a7c80;
    uint256 private constant LAMBERT_POS3_MAXVAL = 0x6b22d43e72c326539cceeef8bb48f255ff;

    // Auto-generated via 'PrintWeightFactors.py'
    uint256 private constant MAX_UNF_WEIGHT = 0x10c6f7a0b5ed8d36b4c7f34938583621fafc8b0079a2834d26fa3fcc9ea9;

    // Auto-generated via 'PrintMaxExpArray.py'
    uint256[128] private maxExpArray;

    function initMaxExpArray() private {
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
     * @dev should be executed after construction (too large for the constructor)
     */
    function init() public {
        initMaxExpArray();
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
    ) public view returns (uint256, uint8) {
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
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
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
     * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
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
        res += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

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

}

pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

pragma solidity >=0.4.0;

import './FullMath.sol';
import './Babylonian.sol';
import './BitMath.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

pragma solidity >=0.5.11;

import { IBasicToken } from "../interfaces/IBasicToken.sol";

library Helpers {
    /**
     * @notice Fetch the `symbol()` from an ERC20 token
     * @dev Grabs the `symbol()` from a contract
     * @param _token Address of the ERC20 token
     * @return string Symbol of the ERC20 token
     */
    function getSymbol(address _token) internal view returns (string memory) {
        string memory symbol = IBasicToken(_token).symbol();
        return symbol;
    }

    /**
     * @notice Fetch the `decimals()` from an ERC20 token
     * @dev Grabs the `decimals()` from a contract and fails if
     *      the decimal value does not live within a certain range
     * @param _token Address of the ERC20 token
     * @return uint256 Decimals of the ERC20 token
     */
    function getDecimals(address _token) internal view returns (uint256) {
        uint256 decimals = IBasicToken(_token).decimals();
        require(
            decimals >= 4 && decimals <= 18,
            "Token must have sufficient decimal places"
        );

        return decimals;
    }
}

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 * Converted from openzeppelin/contracts/token/ERC20/ERC20Detailed.sol
 */
abstract contract InitializableERC20Detailed is ERC20Upgradeable {
    // Storage gap to skip storage from prior to OUSD reset
    uint256[100] private _____gap;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(
        string memory nameArg,
        string memory symbolArg,
        uint8 decimalsArg
    ) internal {
        _name = nameArg;
        _symbol = symbolArg;
        _decimals = decimalsArg;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }


}

pragma solidity >=0.5.0 <0.8.0;

//TO-DO: check library difference
//import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '../libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
//import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '../libraries/PoolAddress.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Fetches time-weighted average tick using Uniswap V3 oracle
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @param period Number of seconds in the past to start calculating time-weighted average
    /// @return timeWeightedAverageTick The time-weighted average tick from (block.timestamp - period) to block.timestamp
    function consult(address pool, uint32 period) internal view returns (int24 timeWeightedAverageTick) {
        require(period != 0, 'BP');

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = period;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondAgos);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(tickCumulativesDelta / period);

        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % period != 0)) timeWeightedAverageTick--;
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
}

pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// Based on StableMath from Stability Labs Pty. Ltd.
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /***************************************
                    Helpers
    ****************************************/

    /**
     * @dev Adjust the scale of an integer
     * @param adjustment Amount to adjust by e.g. scaleBy(1e18, -1) == 1e17
     */
    function scaleBy(uint256 x, int8 adjustment)
        internal
        pure
        returns (uint256)
    {
        if (adjustment > 0) {
            x = x.mul(10**uint256(adjustment));
        } else if (adjustment < 0) {
            x = x.div(10**uint256(adjustment * -1));
        }
        return x;
    }

    /***************************************
               Precise Arithmetic
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @param scale Scale unit
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e38 / 1e18 = 9e18
        return z.div(scale);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *          scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }
}

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';
import './FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "../libraries/BancorFormula.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IVaultCore.sol";
import "../libraries/StableMath.sol";

library VaultCoreLibrary {
	using SafeERC20Upgradeable for ERC20Upgradeable;
	using SafeMathUpgradeable for uint;
	using StableMath for uint;

	/**
	 * @dev calculate chiTarget by the formula in section 2.2 of the whitepaper
	 * @param blockPassed the number of blocks that have passed since USDs is launched, i.e. "Block Height"
	 * @param priceUSDs the price of USDs, i.e. "USDs Price"
	 * @param precisionUSDs the precision used in the variable "priceUSDs"
	 * @return chiTarget_ the value of chiTarget
	 */
	function chiTarget(
			uint blockPassed, uint priceUSDs, uint precisionUSDs, address _VaultCoreContract
		) public view returns (uint chiTarget_) {
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		uint chiAdjustmentA = blockPassed.mul(uint(_vaultContract.chi_prec())).mul(_vaultContract.chi_alpha()).div(_vaultContract.chi_alpha_prec());
		uint chiAdjustmentB;
		uint afterB;
		if (priceUSDs >= precisionUSDs) {
			chiAdjustmentB = uint(_vaultContract.chi_beta()).mul(uint(_vaultContract.chi_prec())).mul(priceUSDs - precisionUSDs).mul(priceUSDs - precisionUSDs).div(_vaultContract.chi_beta_prec());
			afterB = uint(_vaultContract.chiInit()).add(chiAdjustmentB);
		} else {
			chiAdjustmentB = uint(_vaultContract.chi_beta()).mul(uint(_vaultContract.chi_prec())).mul(precisionUSDs - priceUSDs).mul(precisionUSDs - priceUSDs).div(_vaultContract.chi_beta_prec());
			(, afterB) = uint(_vaultContract.chiInit()).trySub(chiAdjustmentB);
		}
		(, chiTarget_) = afterB.trySub(chiAdjustmentA);
	}

	function multiplier(uint original, uint price, uint precision) public pure returns (uint) {
		return original.mul(price).div(precision);
	}

	/**
	 * @dev calculate chiMint
	 * @return chiMint, i.e. chiTarget, since they share the same value
	 */
	function chiMint(address _VaultCoreContract) public view returns (uint)	{
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		uint priceUSDs = uint(IOracle(_vaultContract.oracleAddr()).getUSDsPrice());
		uint precisionUSDs = IOracle(_vaultContract.oracleAddr()).getUSDsPrice_prec();
		uint blockPassed = uint(block.number).sub(_vaultContract.startBlockHeight());
		return chiTarget(blockPassed, priceUSDs, precisionUSDs, _VaultCoreContract);
	}


	/**
	 * @dev calculate chiRedeem based on the formula at the end of section 2.2
	 * @return chiRedeem_
	 */
	function chiRedeem(address _VaultCoreContract) public view returns (uint chiRedeem_) {
		// calculate chiTarget
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		uint priceUSDs = uint(IOracle(_vaultContract.oracleAddr()).getUSDsPrice());
		uint precisionUSDs = IOracle(_vaultContract.oracleAddr()).getUSDsPrice_prec();
		uint blockPassed = uint(block.number).sub(_vaultContract.startBlockHeight());
		uint chiTarget_ = chiTarget(blockPassed, priceUSDs, precisionUSDs, _VaultCoreContract);
		// calculate chiRedeem
		uint collateralRatio_ = _vaultContract.collateralRatio();
		if (chiTarget_ > collateralRatio_) {
			chiRedeem_ = chiTarget_.add(uint(_vaultContract.chi_gamma()).mul(chiTarget_ - collateralRatio_).div(uint(_vaultContract.chi_gamma_prec())));
		} else {
			chiRedeem_ = chiTarget_;
		}
	}


	/**
	 * @dev calculate the OutSwap fee, i.e. fees for redeeming USDs
	 * @return the OutSwap fee
	 */
	function calculateSwapFeeOut(address _VaultCoreContract) public view returns (uint) {
		// if the OutSwap fee is diabled, return 0
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		if (!_vaultContract.swapfeeOutAllowed()) {
			return 0;
		}
		// implement the formula in Section 4.3.2 of whitepaper
		uint USDsInOutRatio = IOracle(_vaultContract.oracleAddr()).USDsInOutRatio();
		uint32 USDsInOutRatio_prec = IOracle(_vaultContract.oracleAddr()).USDsInOutRatio_prec();
		if (USDsInOutRatio <= uint(_vaultContract.swapFee_a()).mul(uint(USDsInOutRatio_prec)).div(uint(_vaultContract.swapFee_a_prec()))) {
			return uint(_vaultContract.swapFee_prec()) / 1000; //0.1%
		} else {
			uint exponentWithPrec = USDsInOutRatio - uint(_vaultContract.swapFee_a()).mul(uint(USDsInOutRatio_prec)).div(uint(_vaultContract.swapFee_a_prec()));
			if (exponentWithPrec >= 2^32) {
				return uint(_vaultContract.swapFee_prec());
			}
			(uint powResWithPrec, uint8 powResPrec) = BancorFormula(_vaultContract.BancorInstance()).power(
				uint(_vaultContract.swapFee_A()), uint(_vaultContract.swapFee_A_prec()), uint32(exponentWithPrec), USDsInOutRatio_prec
			);
			uint toReturn = uint(powResWithPrec >> powResPrec).mul(uint(_vaultContract.swapFee_prec())) / 100;
			if (toReturn >= uint(_vaultContract.swapFee_prec())) {
				return uint(_vaultContract.swapFee_prec());
			} else {
				return toReturn;
			}
		}
	}

	function redeemView(
		address _collaAddr,
		uint USDsAmt,
		address _VaultCoreContract,
		address _oracleAddr
	) public view returns (uint SPAMintAmt, uint collaUnlockAmt, uint USDsBurntAmt, uint swapFeeAmount) {
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		uint swapFee = calculateSwapFeeOut(_VaultCoreContract);
		collaUnlockAmt = 0;
		USDsBurntAmt = 0;
		swapFeeAmount = 0;
		SPAMintAmt = multiplier(USDsAmt, (uint(_vaultContract.chi_prec()) - chiRedeem(_VaultCoreContract)), uint(_vaultContract.chi_prec()));
		SPAMintAmt = multiplier(SPAMintAmt, IOracle(_oracleAddr).getSPAprice_prec(), IOracle(_oracleAddr).getSPAprice());
		if (swapFee > 0) {
			SPAMintAmt = SPAMintAmt.sub(multiplier(SPAMintAmt, swapFee, uint(_vaultContract.swapFee_prec())));
		}

		// Unlock collaeral
		collaUnlockAmt = multiplier(USDsAmt, chiMint(_VaultCoreContract), uint(_vaultContract.chi_prec()));
		if (_collaAddr == address(0)) {
			collaUnlockAmt = multiplier(collaUnlockAmt, IOracle(_oracleAddr).getCollateralPrice_prec(_collaAddr), IOracle(_oracleAddr).getCollateralPrice(_collaAddr));
			collaUnlockAmt = collaUnlockAmt.div(10**(uint(18).sub(uint(ERC20Upgradeable(_collaAddr).decimals()))));
		} else {
			collaUnlockAmt = multiplier(collaUnlockAmt, IOracle(_oracleAddr).getETHprice_prec(), IOracle(_oracleAddr).getETHprice());
		}

		if (swapFee > 0) {
			collaUnlockAmt = collaUnlockAmt.sub(multiplier(collaUnlockAmt, swapFee, uint(_vaultContract.swapFee_prec())));
		}

		// //Burn USDs
		swapFeeAmount = multiplier(USDsAmt, swapFee, uint(_vaultContract.swapFee_prec()));
		USDsBurntAmt = USDsAmt.sub(swapFeeAmount);
	}

	/**
	 * @dev calculate the InSwap fee, i.e. fees for minting USDs
	 * @return the InSwap fee
	 */
	function calculateSwapFeeIn(address _VaultCoreContract) public view returns (uint) {
		// if InSwap fee is disabled, return 0
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		if (!_vaultContract.swapfeeInAllowed()) {
			return 0;
		}

		// implement the formula in Section 4.3.1 of whitepaper
		uint priceUSDs_Average = IOracle(_vaultContract.oracleAddr()).getUSDsPrice_average();
		uint precisionUSDs = IOracle(_vaultContract.oracleAddr()).getUSDsPrice_prec();
		uint smallPwithPrecision = uint(_vaultContract.swapFee_p()).mul(precisionUSDs).div(_vaultContract.swapFee_p_prec());
		uint swapFee_prec = uint(_vaultContract.swapFee_prec());
		if (smallPwithPrecision < priceUSDs_Average) {
			return swapFee_prec / 1000; // 0.1%
		} else {
			uint temp = (smallPwithPrecision - priceUSDs_Average).mul(_vaultContract.swapFee_theta()).div(_vaultContract.swapFee_theta_prec()); //precision: precisionUSDs
			uint temp2 = temp.mul(temp); //precision: precisionUSDs^2
			uint temp3 = temp2.mul(swapFee_prec).div(precisionUSDs).div(precisionUSDs);
			uint temp4 = temp3.div(100);
			uint temp5 = swapFee_prec / 1000 + temp4;
			if (temp5 >= swapFee_prec) {
				return swapFee_prec;
			} else {
				return temp5;
			}
		}
	}

	/**
	 * @dev the general mintView function that display all related quantities based on mint types
	 *		valueType = 0: mintWithUSDs
	 *		valueType = 1: mintWithSPA
	 *		valueType = 2: mintWithColla
	 *		valueType = 3: mintWithETH
	 * @param collaAddr the address of user's chosen collateral
	 * @param valueAmt the amount of user input whose specific meaning depends on valueType
	 * @param valueType the type of user input whose interpretation is listed above in @dev
	 * @return SPABurnAmt the amount of SPA to burn
	 *			collaDeptAmt the amount of collateral to stake
	 *			USDsAmt the amount of USDs to mint
	 *			swapFeeAmount the amount of Inswapfee to pay
	 */
	function mintView(
		address collaAddr,
		uint valueAmt,
		uint8 valueType,
		address _VaultCoreContract
	) public view returns (uint SPABurnAmt, uint collaDeptAmt, uint USDsAmt, uint swapFeeAmount) {
		// obtain the price and pecision of the collateral
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);

		// obtain other necessary data
		uint swapFee = calculateSwapFeeIn(_VaultCoreContract);

		if (valueType == 0) { // when mintWithUSDs
			// calculate USDsAmt
			USDsAmt = valueAmt;
			// calculate SPABurnAmt
			SPABurnAmt = SPAAmountCalculator(valueType, USDsAmt, _VaultCoreContract, swapFee);
			// calculate collaDeptAmt
			collaDeptAmt = collaDeptAmountCalculator(valueType, USDsAmt, _VaultCoreContract, collaAddr, swapFee);

			// calculate swapFeeAmount
			swapFeeAmount = USDsAmt.mul(swapFee).div(uint(_vaultContract.swapFee_prec()));

		} else if (valueType == 1) { // when mintWithSPA
			// calculate SPABurnAmt
			SPABurnAmt = valueAmt;
			// calculate USDsAmt
			USDsAmt = USDsAmountCalculator(valueType, valueAmt, _VaultCoreContract, collaAddr, swapFee);
			// calculate collaDeptAmt

			collaDeptAmt = collaDeptAmountCalculator(valueType, USDsAmt, _VaultCoreContract, collaAddr, swapFee);
			// calculate swapFeeAmount
			swapFeeAmount = USDsAmt.mul(swapFee).div(uint(_vaultContract.swapFee_prec()));

		} else if (valueType == 2 || valueType == 3) { // when mintWithColla or mintWithETH
			// calculate collaDeptAmt
			collaDeptAmt = valueAmt;
			// calculate USDsAmt
			USDsAmt = USDsAmountCalculator(valueType, valueAmt, _VaultCoreContract, collaAddr, swapFee);

			// calculate SPABurnAmt
			SPABurnAmt = SPAAmountCalculator(valueType, USDsAmt, _VaultCoreContract, swapFee);
			// calculate swapFeeAmount
			swapFeeAmount = USDsAmt.mul(swapFee).div(uint(_vaultContract.swapFee_prec()));
		}
	}

	function collaDeptAmountCalculator(
		uint valueType, uint USDsAmt, address _VaultCoreContract, address collaAddr, uint swapFee
	) internal view returns (uint256 collaDeptAmt) {
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		uint collaAddrDecimal = uint(ERC20Upgradeable(collaAddr).decimals());
		if (valueType == 1) {
			collaDeptAmt = USDsAmt.mul(chiMint(_VaultCoreContract)).mul(IOracle(_vaultContract.oracleAddr()).getCollateralPrice_prec(collaAddr)).div(uint(_vaultContract.chi_prec()).mul(IOracle(_vaultContract.oracleAddr()).getCollateralPrice(collaAddr))).div(10**(uint(18).sub(collaAddrDecimal)));
			if (swapFee > 0) {
				collaDeptAmt = collaDeptAmt.add(collaDeptAmt.mul(swapFee).div(uint(_vaultContract.swapFee_prec())));
			}
		} else if (valueType == 0) {
			collaDeptAmt = USDsAmt.mul(chiMint(_VaultCoreContract)).mul(IOracle(_vaultContract.oracleAddr()).getCollateralPrice_prec(collaAddr)).div(uint(_vaultContract.chi_prec()).mul(IOracle(_vaultContract.oracleAddr()).getCollateralPrice(collaAddr))).div(10**(uint(18).sub(collaAddrDecimal)));
			if (swapFee > 0) {
				collaDeptAmt = collaDeptAmt.add(collaDeptAmt.mul(swapFee).div(uint(_vaultContract.swapFee_prec())));
			}
		}
	}

	function SPAAmountCalculator(
		uint valueType, uint USDsAmt, address _VaultCoreContract, uint swapFee
	) internal view returns (uint256 SPABurnAmt) {
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		uint priceSPA = IOracle(_vaultContract.oracleAddr()).getSPAprice();
		uint precisionSPA = IOracle(_vaultContract.oracleAddr()).getSPAprice_prec();
		if (valueType == 2 || valueType == 3) {
			SPABurnAmt = USDsAmt.mul(uint(_vaultContract.chi_prec()) - chiMint(_VaultCoreContract)).mul(precisionSPA).div(priceSPA.mul(uint(_vaultContract.chi_prec())));
			if (swapFee > 0) {
				SPABurnAmt = SPABurnAmt.add(SPABurnAmt.mul(swapFee).div(uint(_vaultContract.swapFee_prec())));
			}
		} else if (valueType == 0) {
			SPABurnAmt = USDsAmt.mul(uint(_vaultContract.chi_prec()) - chiMint(_VaultCoreContract)).mul(precisionSPA).div(priceSPA.mul(uint(_vaultContract.chi_prec())));
			if (swapFee > 0) {
				SPABurnAmt = SPABurnAmt.add(SPABurnAmt.mul(swapFee).div(uint(_vaultContract.swapFee_prec())));
			}
		}
	}

	function USDsAmountCalculator(
		uint valueType, uint valueAmt, address _VaultCoreContract, address collaAddr, uint swapFee
	) internal view returns (uint256 USDsAmt) {
		IVaultCore _vaultContract = IVaultCore(_VaultCoreContract);
		uint priceSPA = IOracle(_vaultContract.oracleAddr()).getSPAprice();
		uint precisionSPA = IOracle(_vaultContract.oracleAddr()).getSPAprice_prec();
		if (valueType == 2 || valueType == 3) {
			USDsAmt = valueAmt;
			if (swapFee > 0) {
				USDsAmt = USDsAmt.mul(uint(_vaultContract.swapFee_prec())).div(uint(_vaultContract.swapFee_prec()).add(swapFee));
			}
			if (valueType == 3) {
				USDsAmt = USDsAmt.mul(10**(uint(18).sub(uint(ERC20Upgradeable(collaAddr).decimals())))).mul(uint(_vaultContract.chi_prec()).mul(IOracle(_vaultContract.oracleAddr()).getETHprice())).div(IOracle(_vaultContract.oracleAddr()).getETHprice_prec()).div(chiMint(_VaultCoreContract));
			} else {
				USDsAmt = USDsAmt.mul(10**(uint(18).sub(uint(ERC20Upgradeable(collaAddr).decimals())))).mul(uint(_vaultContract.chi_prec()).mul(IOracle(_vaultContract.oracleAddr()).getCollateralPrice(collaAddr))).div(IOracle(_vaultContract.oracleAddr()).getCollateralPrice_prec(collaAddr)).div(chiMint(_VaultCoreContract));
			}
		} else if (valueType == 1) {
			USDsAmt = valueAmt;
			if (swapFee > 0) {
				USDsAmt = USDsAmt.mul(uint(_vaultContract.swapFee_prec())).div(uint(_vaultContract.swapFee_prec()).add(swapFee));
			}
			USDsAmt = USDsAmt.mul(uint(_vaultContract.chi_prec())).mul(priceSPA).div(precisionSPA.mul(uint(_vaultContract.chi_prec()) - chiMint(_VaultCoreContract)));
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// To-do: remove for testing purpose functions;
// To-do: check USDsInOutRatio_prec;
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2; //What's this for?


import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/access/OwnableUpgradeable.sol";
import "../libraries/openzeppelin/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../vault/VaultCore.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../libraries/UniswapV2OracleLibrary.sol";
import "../libraries/OracleLibrary.sol";

/**
 * @title Oracle - the oracle contract for Spark
 * @author Sperax Dev Team
 * @notice this contract gets data from UniswapV2 pair and feed these data into the main contact of Spark, i.e. Spark.sol
 * @dev this contract draws insights from "ExampleOracleSimple.sol" by UniswapV2 team
 */

contract OracleGenesis is Initializable, IOracle, OwnableUpgradeable {
    using SafeMathUpgradeable for *;
    using OracleLibrary for *;

    uint public override USDsInOutRatio; // USDsInOutRatio is accurate after 24 hours (one iteration)
    uint32 public constant override USDsInOutRatio_prec = 10**6;
    uint8 public constant FREQUENCY = 24;
    uint32 public updateNextIndex;
    uint32 public lastUpdateTime; // the timstamp of the lastest update
    uint32 public updatePeriod; // the default updatePeriod of one update is 1 hours
    uint public constant ETHprice_prec = 10**8;
    uint public constant SPAprice_prec = 10**18;
    uint public constant USDsPrice_prec = 10**18;
    AggregatorV3Interface priceFeedETH;
    address public constant SPAaddr = address(0xbb5E27Ae27A6a7D092b181FbDdAc1A1004e9adff);
    address public constant WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public VaultAddr;
    address public USDsOraclePool;
    address public SPAoraclePool;
    address public SPAoracleBaseTokenAddr;
    address public USDsOracleBaseTokenAddr;

    event USDsInOutRatioUpdated(
        uint USDsInOutRatio,
        uint USDsOnflow_average,
        uint USDsInflow_average,
        uint32 timeStamp,
        uint index
    );
    event updatePeriodChanged(
        uint32 newPeriod
    );
    event collateralInfoChanged(
        address _collateralAddr,
        bool _supported,
        AggregatorV3Interface _priceFeed,
        uint _price_prec
    );

    uint[FREQUENCY+1] public USDsInflow;
    uint[FREQUENCY+1] public USDsOnflow;
    mapping (address => collateralStruct) collateralsInfo;
    struct collateralStruct {
        address collateralAddr;
        bool supported;
        AggregatorV3Interface priceFeed;
        uint price_prec;
    }

    //
    // Initializer
    //
    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        updatePeriod = 1 hours;
        lastUpdateTime = uint32(now % 2**32);
        priceFeedETH = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    function updateOraclePoolsAddress(address _SPAoracleBaseTokenAddr, address _USDsOracleBaseTokenAddr, address _USDsOraclePool, address _SPAoraclePool) external onlyOwner {
        SPAoracleBaseTokenAddr = _SPAoracleBaseTokenAddr;
        USDsOracleBaseTokenAddr = _USDsOracleBaseTokenAddr;
        USDsOraclePool = _USDsOraclePool;
        SPAoraclePool = _SPAoraclePool;
    }

    function updateVaultAddress(address _VaultAddr) external onlyOwner {
        VaultAddr = _VaultAddr;
    }

    /**
     * @notice change updatePeriod
     * @dev the frequency of update always remains the same
     * @param newPeriod new minimal updatePeriod in between two updates
     */
    function changePeriod(uint32 newPeriod) external onlyOwner {
        updatePeriod = newPeriod;
        emit updatePeriodChanged(updatePeriod);
    }

    function updateCollateralInfo(address _collateralAddr, bool _supported, AggregatorV3Interface _priceFeed, uint _price_prec) external onlyOwner {
        collateralStruct storage updatedCollateral = collateralsInfo[_collateralAddr];
        updatedCollateral.collateralAddr = _collateralAddr;
        updatedCollateral.supported = _supported;
        updatedCollateral.priceFeed = _priceFeed;
        updatedCollateral.price_prec = _price_prec;
        emit collateralInfoChanged(_collateralAddr, _supported, _priceFeed, _price_prec);
    }

    /**
     * @notice update the price of token0 to the latest
     * @dev the price would be updated only once per updatePeriod time
     * @dev USDsInOutRatio is accurate after 24 hours (one iteration)
     */
    function updateInOutRatio() external override {
        uint32 currTime = uint32(now % 2 ** 32);
        uint32 timeElapsed = currTime - lastUpdateTime;
        require(currTime >= lastUpdateTime, "updateInOutRatio; error last update happened in the future");
        require(timeElapsed >= updatePeriod, "updateInOutRatio: the time elapsed is too short.");
        uint32 indexNew = updateNextIndex;
        uint32 indexOld = (indexNew + 1) % (FREQUENCY + 1);
        USDsInflow[indexNew] = USDs(VaultAddr)._totalMinted();
        USDsOnflow[indexNew] = USDs(VaultAddr)._totalBurnt();
        uint USDsInflow_average = USDsInflow[indexNew].sub(USDsInflow[indexOld]);
        uint USDsOnflow_average = USDsOnflow[indexNew].sub(USDsOnflow[indexOld]);
        if (USDsInOutRatio == 0) {
            USDsInOutRatio = USDsInOutRatio_prec;
        } else {
            USDsInOutRatio = USDsOnflow_average.mul(USDsInOutRatio_prec).div(USDsInflow_average);
        }
        lastUpdateTime = currTime;
        updateNextIndex = indexOld;
        emit USDsInOutRatioUpdated(USDsInOutRatio, USDsOnflow_average, USDsInflow_average, lastUpdateTime, indexNew);
    }

    function getCollateralPrice(address collateralAddr) external view override returns (uint) {
        collateralStruct memory  collateralInfo = collateralsInfo[collateralAddr];
        require(collateralInfo.supported, "getCollateralPrice: Collateral not supported.");
        return _getCollateralPrice(collateralAddr);
    }

    function getETHprice() external view override returns (uint) {
        return _getETHprice();
	}

    function getSPAprice() external view override returns (uint) {
        int24 timeWeightedAverageTick = SPAoraclePool.consult(3600);
        uint quoteAmount = timeWeightedAverageTick.getQuoteAtTick(uint128(SPAprice_prec), SPAaddr, SPAoracleBaseTokenAddr);
        uint SPAprice = _getETHprice().mul(quoteAmount).div(ETHprice_prec);
        return SPAprice;
    }

    function getUSDsPrice() external view override returns (uint) {
        // int24 timeWeightedAverageTick = USDsOraclePool.consult(3600);
        // uint quoteAmount = timeWeightedAverageTick.getQuoteAtTick(uint128(USDsPrice_prec), VaultAddr, USDsOracleBaseTokenAddr);
        // uint USDsPrice = _getCollateralPrice(USDsOracleBaseTokenAddr).mul(quoteAmount).div(_getCollateralPrice_prec(USDsOracleBaseTokenAddr));
        return 1 * USDsPrice_prec;
    }

    function getUSDsPrice_average() external view override returns (uint) {
        // int24 timeWeightedAverageTick = USDsOraclePool.consult(86400);
        // uint quoteAmount = timeWeightedAverageTick.getQuoteAtTick(uint128(USDsPrice_prec), VaultAddr, USDsOracleBaseTokenAddr);
        // uint USDsPrice_average = _getCollateralPrice(USDsOracleBaseTokenAddr).mul(quoteAmount).div(_getCollateralPrice_prec(USDsOracleBaseTokenAddr));
        return 1 * USDsPrice_prec;
    }

    function getCollateralPrice_prec(address collateralAddr) external view override returns (uint) {
        collateralStruct memory  collateralInfo = collateralsInfo[collateralAddr];
        require(collateralInfo.supported, "getCollateralPrice_prec: Collateral not supported.");
        return _getCollateralPrice_prec(collateralAddr);
    }

    function getETHprice_prec() external view override returns (uint) {
        return ETHprice_prec;
    }

    function getSPAprice_prec() external view override returns (uint) {
        return SPAprice_prec;
    }

    function getUSDsPrice_prec() external view override returns (uint) {
        return USDsPrice_prec;
    }

    function _getCollateralPrice(address collateralAddr) internal view returns (uint) {
        collateralStruct memory  collateralInfo = collateralsInfo[collateralAddr];
        require(collateralInfo.supported, "_getCollateralPrice: Collateral not supported.");
        (
            ,
            int price,
            ,
            ,
        ) = collateralInfo.priceFeed.latestRoundData();
        return uint(price);
    }


	function _getETHprice() internal view returns (uint) {
		(
            ,
            int price,
            ,
            ,
		) = priceFeedETH.latestRoundData();
		return uint(price);
	}

    function _getCollateralPrice_prec(address collateralAddr) internal view returns (uint) {
        collateralStruct memory  collateralInfo = collateralsInfo[collateralAddr];
        require(collateralInfo.supported, "_getCollateralPrice_prec: Collateral not supported.");
        return collateralInfo.price_prec;
	}


}

/**
    Questions:
    1. in changeSupply, why we need to first check if _totalSupply > 0?
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title USDs Token Contract
 * @dev ERC20 compatible contract for USDs
 * @dev Implements an elastic supply
 * @author Origin Protocol Inc
 */

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/access/OwnableUpgradeable.sol";
import "../libraries/openzeppelin/OwnableUpgradeable.sol";
import { InitializableERC20Detailed } from "../libraries/InitializableERC20Detailed.sol";
import { StableMath } from "../libraries/StableMath.sol";

/**
 * NOTE that this is an ERC20 token but the invariant that the sum of
 * balanceOf(x) for all x is not >= totalSupply(). This is a consequence of the
 * rebasing design. Any integrations with USDs should be aware.
 */

contract USDs is Initializable, InitializableERC20Detailed, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using StableMath for uint256;

    event TotalSupplyUpdated(
        uint256 totalSupply,
        uint256 rebasingCredits,
        uint256 rebasingCreditsPerToken
    );

    enum RebaseOptions { NotSet, OptOut, OptIn }

    uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1
    uint256 public _totalSupply;    // the total supply of USDs
    uint256 public _totalMinted;    // the total num of USDs minted so far
    uint256 public _totalBurnt;     // the total num of USDs burnt so far
    mapping(address => mapping(address => uint256)) private _allowances;
    address public vaultAddress;    // the address where (i) all collaterals of USDs protocol reside, e.g. USDT, USDC, ETH, etc and (ii) major actions like USDs minting are initiated
    // an user's balance of USDs is based on her balance of "credits."
    // in a rebase process, her USDs balance will change according to her credit balance and the rebase ratio
    mapping(address => uint256) private _creditBalances;
    // the total number of credits of the USDs protocol
    uint256 public rebasingCredits;
    // the rebase ratio = num of credits / num of USDs
    uint256 public rebasingCreditsPerToken;
    // Frozen address/credits are non rebasing (value is held in contracts which
    // do not receive yield unless they explicitly opt in)
    uint256 public nonRebasingSupply;   // num of USDs that are not affected by rebase
    mapping(address => uint256) public nonRebasingCreditsPerToken; // the rebase ratio of non-rebasing accounts just before they opt out
    mapping(address => RebaseOptions) public rebaseState;          // the rebase state of each account, i.e. opt in or opt out

    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _vaultAddress
    ) external initializer {
        InitializableERC20Detailed._initialize(_nameArg, _symbolArg, 18);
        OwnableUpgradeable.__Ownable_init();
        rebasingCreditsPerToken = 1e18;
        vaultAddress = _vaultAddress;
    }

    /**
     * @dev change the vault address
     * @param newVault the new vault address
     */
    function changeVault(address newVault) external onlyOwner {
        vaultAddress = newVault;
    }

    /**
     * @dev Verifies that the caller is the Savings Manager contract
     */
    modifier onlyVault() {
        require(vaultAddress == msg.sender, "Caller is not the Vault");
        _;
    }

    /**
     * @dev check the current total supply of USDs
     * @return The total supply of USDs.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the USDs balance of the specified address.
     * @param _account Address to query the balance of.
     * @return A uint256 representing the _amount of base units owned by the
     *         specified address.
     */
    function balanceOf(address _account) public view override returns (uint256) {
        if (_creditBalances[_account] == 0) return 0;
        return
            _creditBalances[_account].divPrecisely(_creditsPerToken(_account));
    }

    /**
     * @dev Gets the credits balance of the specified address.
     * @param _account The address to query the balance of.
     * @return (uint256, uint256) Credit balance and credits per token of the
     *         address
     */
    function creditsBalanceOf(address _account)
        public
        view
        returns (uint256, uint256)
    {
        return (_creditBalances[_account], _creditsPerToken(_account));
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param _to the address to transfer to.
     * @param _value the _amount to be transferred.
     * @return true on success.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(
            _value <= balanceOf(msg.sender),
            "Transfer greater than balance"
        );

        _executeTransfer(msg.sender, _to, _value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from The address you want to send tokens from.
     * @param _to The address you want to transfer to.
     * @param _value The _amount of tokens to be transferred.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(_value <= balanceOf(_from), "Transfer greater than balance");

        // notice: allowance balnce check depends on "sub" non-negative check
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(
            _value
        );

        _executeTransfer(_from, _to, _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Update the count of non rebasing credits in response to a transfer
     * @param _from The address you want to send tokens from.
     * @param _to The address you want to transfer to.
     * @param _value Amount of USDs to transfer
     */
    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        bool isNonRebasingTo = _isNonRebasingAccount(_to);
        bool isNonRebasingFrom = _isNonRebasingAccount(_from);

        // Credits deducted and credited might be different due to the
        // differing creditsPerToken used by each account
        uint256 creditsCredited = _value.mulTruncate(_creditsPerToken(_to));
        uint256 creditsDeducted = _value.mulTruncate(_creditsPerToken(_from));

        _creditBalances[_from] = _creditBalances[_from].sub(
            creditsDeducted,
            "Transfer amount exceeds balance"
        );
        _creditBalances[_to] = _creditBalances[_to].add(creditsCredited);

        // update global stats
        if (isNonRebasingTo && !isNonRebasingFrom) {
            // Transfer to non-rebasing account from rebasing account, credits
            // are removed from the non rebasing tally
            nonRebasingSupply = nonRebasingSupply.add(_value);
            // Update rebasingCredits by subtracting the deducted amount
            rebasingCredits = rebasingCredits.sub(creditsDeducted);
        } else if (!isNonRebasingTo && isNonRebasingFrom) {
            // Transfer to rebasing account from non-rebasing account
            // Decreasing non-rebasing credits by the amount that was sent
            nonRebasingSupply = nonRebasingSupply.sub(_value);
            // Update rebasingCredits by adding the credited amount
            rebasingCredits = rebasingCredits.add(creditsCredited);
        }
    }

    /**
     * @dev Function to check the _amount of tokens that an owner has allowed to a _spender.
     * @param _owner The address which owns the funds.
     * @param _spender The address which will spend the funds.
     * @return The number of tokens still available for the _spender.
     */
    function allowance(address _owner, address _spender)
        public
        view
        override returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified _amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param _spender The address which will spend the funds.
     * @param _value The _amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the _amount of tokens that an owner has allowed to a _spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The _amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender]
            .add(_addedValue);
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the _amount of tokens that an owner has allowed to a _spender.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The _amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            _allowances[msg.sender][_spender] = 0;
        } else {
            _allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Mints new USDs tokens, increasing totalSupply.
     * @param _account the account address the newly minted USDs will be attributed to
     * @param _amount the amount of USDs that will be minted
     */
    function mint(address _account, uint256 _amount) external onlyVault {
        _mint(_account, _amount);
    }

    /**
     * @dev Creates `_amount` tokens and assigns them to `_account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     * @param _account the account address the newly minted USDs will be attributed to
     * @param _amount the amount of USDs that will be minted
     */
    function _mint(address _account, uint256 _amount) internal override {
        require(_account != address(0), "Mint to the zero address");

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);

        uint256 creditAmount = _amount.mulTruncate(_creditsPerToken(_account));
        _creditBalances[_account] = _creditBalances[_account].add(creditAmount);

        // notice: If the account is non rebasing and doesn't have a set creditsPerToken
        //          then set it i.e. this is a mint from a fresh contract

        // update global stats
        if (isNonRebasingAccount) {
            nonRebasingSupply = nonRebasingSupply.add(_amount);
        } else {
            rebasingCredits = rebasingCredits.add(creditAmount);
        }

        _totalSupply = _totalSupply.add(_amount);
        _totalMinted = _totalMinted.add(_amount);

        require(_totalSupply < MAX_SUPPLY, "Max supply");

        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Burns tokens, decreasing totalSupply.
     */
    function burn(address account, uint256 amount) external onlyVault {
        _burn(account, amount);
    }

    /**
     * @dev Destroys `_amount` tokens from `_account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `_account` cannot be the zero address.
     * - `_account` must have at least `_amount` tokens.
     */
    function _burn(address _account, uint256 _amount) internal override {
        require(_account != address(0), "Burn from the zero address");
        if (_amount == 0) {
            return;
        }

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);
        uint256 creditAmount = _amount.mulTruncate(_creditsPerToken(_account));
        uint256 currentCredits = _creditBalances[_account];

        // Remove the credits, burning rounding errors
        if (
            currentCredits == creditAmount || currentCredits - 1 == creditAmount
        ) {
            // Handle dust from rounding
            _creditBalances[_account] = 0;
        } else if (currentCredits > creditAmount) {
            _creditBalances[_account] = _creditBalances[_account].sub(
                creditAmount
            );
        } else {
            revert("Remove exceeds balance");
        }

        // Remove from the credit tallies and non-rebasing supply
        if (isNonRebasingAccount) {
            nonRebasingSupply = nonRebasingSupply.sub(_amount);
        } else {
            rebasingCredits = rebasingCredits.sub(creditAmount);
        }

        _totalSupply = _totalSupply.sub(_amount);
        _totalBurnt = _totalBurnt.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Get the credits per token for an account. Returns a fixed amount
     *      if the account is non-rebasing.
     * @param _account Address of the account.
     */
    function _creditsPerToken(address _account)
        internal
        view
        returns (uint256)
    {
        if (nonRebasingCreditsPerToken[_account] != 0) {
            return nonRebasingCreditsPerToken[_account];
        } else {
            return rebasingCreditsPerToken;
        }
    }

    /**
     * @dev Is an account using rebasing accounting or non-rebasing accounting?
     *      Also, ensure contracts are non-rebasing if they have not opted in.
     * @param _account Address of the account.
     */
    function _isNonRebasingAccount(address _account) internal returns (bool) {
        bool isContract = AddressUpgradeable.isContract(_account);
        if (isContract && rebaseState[_account] == RebaseOptions.NotSet) {
            _ensureRebasingMigration(_account);
        }
        return nonRebasingCreditsPerToken[_account] > 0;
    }

    /**
     * @dev Ensures internal account for rebasing and non-rebasing credits and
     *      supply is updated following deployment of frozen yield change.
     */
    function _ensureRebasingMigration(address _account) internal {
        if (nonRebasingCreditsPerToken[_account] == 0) {
            // Set fixed credits per token for this account
            nonRebasingCreditsPerToken[_account] = rebasingCreditsPerToken;
            // Update non rebasing supply
            nonRebasingSupply = nonRebasingSupply.add(balanceOf(_account));
            // Update credit tallies
            rebasingCredits = rebasingCredits.sub(_creditBalances[_account]);
        }
    }

    /**
     * @dev Add a contract address to the non rebasing exception list. I.e. the
     * address's balance will be part of rebases so the account will be exposed
     * to upside and downside.
     */
    function rebaseOptIn() public onlyOwner {
        require(_isNonRebasingAccount(msg.sender), "Account has not opted out");

        // Convert balance into the same amount at the current exchange rate
        uint256 newCreditBalance = _creditBalances[msg.sender]
            .mul(rebasingCreditsPerToken)
            .div(_creditsPerToken(msg.sender));

        // Decreasing non rebasing supply
        nonRebasingSupply = nonRebasingSupply.sub(balanceOf(msg.sender));

        _creditBalances[msg.sender] = newCreditBalance;

        // Increase rebasing credits, totalSupply remains unchanged so no
        // adjustment necessary
        rebasingCredits = rebasingCredits.add(_creditBalances[msg.sender]);

        rebaseState[msg.sender] = RebaseOptions.OptIn;

        // Delete any fixed credits per token
        delete nonRebasingCreditsPerToken[msg.sender];
    }

    /**
     * @dev Remove a contract address to the non rebasing exception list.
     */
    function rebaseOptOut() public onlyOwner {
        require(!_isNonRebasingAccount(msg.sender), "Account has not opted in");

        // Increase non rebasing supply
        nonRebasingSupply = nonRebasingSupply.add(balanceOf(msg.sender));
        // Set fixed credits per token
        nonRebasingCreditsPerToken[msg.sender] = rebasingCreditsPerToken;

        // Decrease rebasing credits, total supply remains unchanged so no
        // adjustment necessary
        rebasingCredits = rebasingCredits.sub(_creditBalances[msg.sender]);

        // Mark explicitly opted out of rebasing
        rebaseState[msg.sender] = RebaseOptions.OptOut;
    }

    /**
     * @dev The rebase function. Modify the supply without minting new tokens. This uses a change in
     *      the exchange rate between "credits" and USDs tokens to change balances.
     * @param _newTotalSupply New total supply of USDs.
     */
    function changeSupply(uint256 _newTotalSupply)
        external
        onlyVault
    {
        require(_totalSupply > 0, "Cannot increase 0 supply");

        // special case: if the total supply remains the same
        if (_totalSupply == _newTotalSupply) {
            emit TotalSupplyUpdated(
                _totalSupply,
                rebasingCredits,
                rebasingCreditsPerToken
            );
            return;
        }

        // check if the new total supply surpasses the MAX
        _totalSupply = _newTotalSupply > MAX_SUPPLY
            ? MAX_SUPPLY
            : _newTotalSupply;
        // calculate the new rebase ratio, i.e. credits per token
        rebasingCreditsPerToken = rebasingCredits.divPrecisely(
            _totalSupply.sub(nonRebasingSupply)
        );

        require(rebasingCreditsPerToken > 0, "Invalid change in supply");

        // re-calculate the total supply to accomodate precision error
        _totalSupply = rebasingCredits
            .divPrecisely(rebasingCreditsPerToken)
            .add(nonRebasingSupply);

        emit TotalSupplyUpdated(
            _totalSupply,
            rebasingCredits,
            rebasingCreditsPerToken
        );
    }
}

//TO-DO: check source file of SafeMathUpgradeable regarding trySub() (and the usage of "unchecked")
//TO-DO: check ERC20Upgradeable vs ERC20Upgradeable
// Note: assuming when exponentWith_prec >= 2^32, toReturn >= swapFee_prec () (TO-DO: work out the number)
//TO-DO: deal with collateralStrategies
//TO-DO: what happen when we redeem aTokens
//TO-DO: whether _redeem needs "SafeTransferFrom" and how
//TO-DO: check all user inputs, especially mintView
//TO-DO: remove for testing purposes files
pragma solidity ^0.6.12;

//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/access/OwnableUpgradeable.sol";
import "../libraries/openzeppelin/OwnableUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../libraries/Helpers.sol";
//import "../interfaces/IOracle.sol";
import "../interfaces/ISperaxToken.sol";
import "../interfaces/IStrategy.sol";
import "../libraries/VaultCoreLibrary.sol";
import "../token/USDs.sol";
//import "../libraries/BancorFormula.sol";
import "../interfaces/IBuyback.sol";
import "../interfaces/IVaultCore.sol";

contract VaultCore is Initializable, OwnableUpgradeable, IVaultCore {
	using SafeERC20Upgradeable for ERC20Upgradeable;
	using SafeMathUpgradeable for uint;
	using StableMath for uint;

	bool public override mintRedeemAllowed;
	bool public override allocationAllowed;
	bool public override rebaseAllowed;
	bool public override swapfeeInAllowed;
	bool public override swapfeeOutAllowed;
	address public SPAaddr;
	address public override oracleAddr;
	address public SPAvault;
	USDs USDsInstance;
	BancorFormula public override BancorInstance;
	uint public override startBlockHeight;
	uint public SPAminted;
	uint public SPAburnt;
	uint32 public override chi_alpha;
	uint64 public override constant chi_alpha_prec = 10**12;
	uint64 public override constant chi_prec = 10**12;
	uint64 public override chiInit;
	uint32 public override chi_beta;
	uint16 public override constant chi_beta_prec = 10**4;
	uint32 public override chi_gamma;
	uint16 public override constant chi_gamma_prec = 10**4;
	uint64 public override constant swapFee_prec = 10**12;
	uint32 public override swapFee_p;
	uint16 public override constant swapFee_p_prec = 10**4;
	uint32 public override swapFee_theta;
	uint16 public override constant swapFee_theta_prec = 10**4;
	uint32 public override swapFee_a;
	uint16 public override constant swapFee_a_prec = 10**4;
	uint32 public override swapFee_A;
	uint16 public override constant swapFee_A_prec = 10**4;
	uint32 public override allocatePrecentage;
	uint16 public override constant allocatePrecentage_prec = 10**4;

	event parametersUpdated(uint64 _chiInit, uint32 _chi_beta, uint32 _chi_gamma, uint32 _swapFee_p, uint32 _swapFee_theta, uint32 _swapFee_a, uint32 _swapFee_A, uint32 _allocatePrecentage);
	event USDsMinted(address indexed wallet, uint indexed USDsAmt, uint collateralAmt, uint SPAsAmt, uint feeAmt);
	event USDsRedeemed(address indexed wallet, uint indexed USDsAmt, uint collateralAmt, uint SPAsAmt, uint feeAmt);
	event Rebase(uint indexed oldSupply, uint indexed newSupply);
	event CollateralInfoChanged(address indexed collateralAddr, bool supported, address defaultStrategyAddr, bool allocationAllowed, address buyBackAddr, bool rebaseAllowed);
	event StrategyInfoChanged(address strategyAddr, bool enabled);
	event MintRedeemPermssionChanged(bool indexed permission);
	event AllocationPermssionChanged(bool indexed permission);
	event SwapFeeInOutPermissionChanged(bool indexed swapfeeInAllowed, bool indexed swapfeeOutAllowed);

	/**
	 * @dev check if USDs mint & redeem are both allowed
	 */
	modifier whenMintRedeemAllowed {
		require(mintRedeemAllowed, "Mint & redeem paused");
		_;
	}
	/**
	 * @dev check if re-investment of collaterals is allowed
	 */
	modifier whenAllocationAllowed {
		require(allocationAllowed, "Allocate paused");
		_;
	}
	/**
	 * @dev check if rebase is allowed
	 */
	modifier whenRebaseAllowed {
		require(rebaseAllowed, "Rebase paused");
		_;
	}

	struct collateralStruct {
		address collateralAddr;
		bool supported;
		address defaultStrategyAddr;
		bool allocationAllowed;
		address buyBackAddr;
		bool rebaseAllowed;
	}
	struct strategyStruct {
		address strategyAddr;
		bool enabled;
	}
	mapping(address => uint) public supportedCollateral;		// if it is 1, the collateral is supported; else it is 0, it is not supported
	mapping(address => collateralStruct) collateralsInfo;
	mapping(address => strategyStruct) strategiesInfo;
	collateralStruct[] allCollaterals;	// the list of all supported collaterals
	strategyStruct[] allStrategies;	// the list of all strategy addresses

	function initialize() public initializer {
		OwnableUpgradeable.__Ownable_init();
		mintRedeemAllowed = true;
		swapfeeInAllowed = false;
		swapfeeOutAllowed = false;
		allocationAllowed = false;
		SPAaddr = 0xbb5E27Ae27A6a7D092b181FbDdAc1A1004e9adff;	// SPA on Kovan
		SPAvault = address(this);
		startBlockHeight = block.number;
		BancorInstance = BancorFormula(0x0f27662A7e4033eB4549a4E6Bd42a35a96979BdC);
		chi_alpha = uint32(chi_alpha_prec * 513 / 10**10);
		chiInit = chi_prec * 95 / 100;
		chi_beta = chi_beta_prec * 9;
		chi_gamma = chi_gamma_prec;
		swapFee_p = swapFee_p_prec * 99 / 100;
		swapFee_theta = swapFee_theta_prec * 50;
		swapFee_a = swapFee_a_prec * 12 / 10;
		swapFee_A = swapFee_A_prec * 20;
		allocatePrecentage = allocatePrecentage_prec * 8 / 10;
	}

	//For testing purposes:
	function updateUSDsAddress(address _USDsAddr) external onlyOwner {
		USDsInstance = USDs(_USDsAddr);
	}

	function updateOracleAddress(address _oracleAddr) external onlyOwner {
		oracleAddr =  _oracleAddr;
	}

	function updateParameters(uint64 _chiInit, uint32 _chi_beta, uint32 _chi_gamma, uint32 _swapFee_p, uint32 _swapFee_theta, uint32 _swapFee_a, uint32 _swapFee_A, uint32 _allocatePrecentage) external onlyOwner {
		chiInit = _chiInit;
		chi_beta = _chi_beta;
		chi_gamma = _chi_gamma;
		swapFee_p = _swapFee_p;
		swapFee_theta = _swapFee_theta;
		swapFee_a = _swapFee_a;
		swapFee_A = _swapFee_A;
		allocatePrecentage = _allocatePrecentage;
		emit parametersUpdated(chiInit, chi_beta, chi_gamma, swapFee_p, swapFee_theta, swapFee_a, swapFee_A, allocatePrecentage);
	}

	/**
	 * @dev disable USDs mint & redeem
	 */
	function updateMintBurnPermission(bool _mintRedeemAllowed) external onlyOwner {
		mintRedeemAllowed = _mintRedeemAllowed;
		emit MintRedeemPermssionChanged(mintRedeemAllowed);
	}
	/**
	 * @dev disable collateral re-investment
	 */
	function updateAllocationPermission(bool _allocationAllowed) external onlyOwner {
		allocationAllowed = _allocationAllowed;
		emit AllocationPermssionChanged(allocationAllowed);
	}
	/**
	 * @dev disable swapInFee, i.e. mint becomes free
	 */
	function updateSwapInOutFeePermission(bool _swapfeeInAllowed, bool _swapfeeOutAllowed) external onlyOwner {
		swapfeeInAllowed = _swapfeeInAllowed;
		swapfeeOutAllowed = _swapfeeOutAllowed;
		emit SwapFeeInOutPermissionChanged(swapfeeInAllowed, swapfeeOutAllowed);
	}

	function updateCollateralInfo(address _collateralAddr, bool _supported, address _defaultStrategyAddr, bool _allocationAllowed, address _buyBackAddr, bool _rebaseAllowed) external onlyOwner {
		_updateCollateralInfo(_collateralAddr, _supported, _defaultStrategyAddr, _allocationAllowed, _buyBackAddr, _rebaseAllowed);
	}

	function _updateCollateralInfo(address _collateralAddr, bool _supported, address _defaultStrategyAddr, bool _allocationAllowed, address _buyBackAddr, bool _rebaseAllowed) internal {
		collateralStruct storage updatedCollateral = collateralsInfo[_collateralAddr];
		updatedCollateral.collateralAddr = _collateralAddr;
		updatedCollateral.supported = _supported;
		updatedCollateral.defaultStrategyAddr = _defaultStrategyAddr;
		updatedCollateral.allocationAllowed = _allocationAllowed;
		updatedCollateral.buyBackAddr = _buyBackAddr;
		emit CollateralInfoChanged(_collateralAddr, _supported, _defaultStrategyAddr, _allocationAllowed, _buyBackAddr, _rebaseAllowed);
	}

	function updateStrategyInfo(address _strategyAddr, bool _enabled) external onlyOwner {
		_updateStrategyInfo(_strategyAddr, _enabled);
	}

	function _updateStrategyInfo(address _strategyAddr, bool _enabled) internal {
		strategyStruct storage updatedStrategy = strategiesInfo[_strategyAddr];
		updatedStrategy.strategyAddr = _strategyAddr;
		updatedStrategy.enabled = _enabled;
		emit StrategyInfoChanged(_strategyAddr, _enabled);
	}

	/**
	 * @dev mint USDs by entering USDs amount
	 * @param collateralAddr the address of user's chosen collateral
	 * @param USDsMintAmt the amount of USDs to be minted
	 */
	function mintWithUSDs(address collateralAddr, uint USDsMintAmt, uint slippageCollateral, uint slippageSPA, uint deadline)
		public
		whenMintRedeemAllowed
	{
		require(collateralsInfo[collateralAddr].supported, "Collateral not supported");
		require(USDsMintAmt > 0, "Amount needs to be greater than 0");
		_mint(collateralAddr, USDsMintAmt, 0, USDsMintAmt, slippageCollateral, slippageSPA, deadline);
	}

	/**
	 * @dev mint USDs by entering SPA amount
	 * @param collateralAddr the address of user's chosen collateral
	 * @param SPAamt the amount of SPA to burn
	 */

	function mintWithSPA(address collateralAddr, uint SPAamt, uint slippageUSDs, uint slippageCollateral, uint deadline)
		public
		whenMintRedeemAllowed
	{
		require(collateralsInfo[collateralAddr].supported, "Collateral not supported");
		require(SPAamt > 0, "Amount needs to be greater than 0");
		_mint(collateralAddr, SPAamt, 1, slippageUSDs, slippageCollateral, SPAamt, deadline);
	}

	/**
	 * @dev mint USDs by entering collateral amount (excluding ETH)
	 * @param collateralAddr the address of user's chosen collateral
	 * @param collateralAmt the amount of collateral to stake
	 */
	function mintWithColla(address collateralAddr, uint collateralAmt, uint slippageUSDs, uint slippageSPA, uint deadline)
		public
		whenMintRedeemAllowed
	{
		require(collateralsInfo[collateralAddr].supported, "Collateral not supported");
		require(collateralAmt > 0, "Amount needs to be greater than 0");
		_mint(collateralAddr, collateralAmt, 2, slippageUSDs, collateralAmt, slippageSPA, deadline);
	}

	/**
	 * @dev mint USDs by ETH
	 * note: this function needs changes when USDs is deployed on other blockchain platform
	 */
	function mintWithEth(uint slippageUSDs, uint slippageSPA, uint deadline) public payable whenMintRedeemAllowed {
		require(msg.value > 0, "Need to pay Ether");
		_mint(address(0), msg.value, 3, slippageUSDs, msg.value, slippageSPA, deadline);
	}


	/**
	 * @dev the generic, internal mint function
	 * @param collateralAddr the address of the collateral
	 * @param valueAmt the amount of tokens (the specific meaning depends on valueType)
	 * @param valueType the type of tokens (specific meanings are listed lower)
	 *		valueType = 0: mintWithUSDs
	 *		valueType = 1: mintWithSPA
	 *		valueType = 2: mintWithColla
	 *		valueType = 3: mintWithETH
	 */
	function _mint(
		address collateralAddr,
		uint valueAmt,
		uint8 valueType,
		uint slippageUSDs,
		uint slippageCollat,
		uint slippageSPA,
		uint deadline
	) internal whenMintRedeemAllowed {
		// calculate all necessary related quantities based on user inputs
		(uint SPABurnAmt, uint collateralDepAmt, uint USDsAmt, uint swapFeeAmount) = VaultCoreLibrary.mintView(collateralAddr, valueAmt, valueType, address(this));

		// slippageUSDs is the minimum value of the minted USDs
		// slippageCollat is the maximum value of the required collateral
		// slippageSPA is the maximum value of the required spa
		require(USDsAmt >= slippageUSDs, "USDs amount is lower than the maximum slippage");
		require(collateralDepAmt <= slippageCollat, "Collateral amount is more than the maximum slippage");
		require(SPABurnAmt >= slippageSPA, "SPA amount is more than the maximum slippage");
		require(block.timestamp <= deadline, "Deadline expired");

		// burn SPA tokens
		ISperaxToken(SPAaddr).burnFrom(msg.sender, SPABurnAmt);
		SPAburnt = SPAburnt.add(SPABurnAmt);
		// if it it not mintWithETH, stake collaterals
		if (valueType != 3) {
			ERC20Upgradeable(collateralAddr).safeTransferFrom(msg.sender, address(this), collateralDepAmt);
		}
		// mint USDs and collect swapIn fees
		USDsInstance.mint(msg.sender, USDsAmt);
		USDsInstance.mint(address(this), swapFeeAmount);
		emit USDsMinted(msg.sender, USDsAmt, collateralDepAmt, SPABurnAmt, swapFeeAmount);
	}

	/**
	 *
	 */
	function redeem(address collateralAddr, uint USDsAmt, uint slippageCollat, uint slippageSPA, uint deadline)
		public
		whenMintRedeemAllowed
	{
		require(collateralsInfo[collateralAddr].supported, "Collateral not supported");
		require(USDsAmt > 0, "Amount needs to be greater than 0");
		_redeem(collateralAddr, USDsAmt, slippageCollat, slippageSPA, deadline);
	}

	/**
	 *
	 */
	function redeemWithEth(uint USDsAmt, uint slippageEth, uint slippageSPA, uint deadline)
		public
		whenMintRedeemAllowed
	{
		require(USDsAmt > 0, "Amount needs to be greater than 0");
		_redeem(address(0), USDsAmt, slippageEth, slippageSPA, deadline);
	}

	function _redeem(
		address collateralAddr,
		uint USDsAmt,
		uint slippageCollat,
		uint slippageSPA,
		uint deadline
	) internal whenMintRedeemAllowed {
		(uint SPAMintAmt, uint collateralUnlockedAmt, uint USDsBurntAmt, uint swapFeeAmount) = VaultCoreLibrary.redeemView(collateralAddr, USDsAmt, address(this), oracleAddr);

		// slippageCollat is the minimum value of the unlocked collateral
		// slippageSPA is the minimum value of the minted spa
		require(collateralUnlockedAmt >= slippageCollat, "Collateral amount is lower than the maximum slippage");
		require(SPAMintAmt >= slippageSPA, "SPA amount is lower than the maximum slippage");
		require(block.timestamp <= deadline, "Deadline expired");

		ISperaxToken(SPAaddr).mintForUSDs(msg.sender, SPAMintAmt);
		SPAminted = SPAminted.add(SPAMintAmt);

		if (collateralAddr == address(0)) {
			(bool sent, ) = msg.sender.call{value: collateralUnlockedAmt}("");
			require(sent, "Failed to send Ether");
		} else {
			ERC20Upgradeable(collateralAddr).safeTransfer(msg.sender, collateralUnlockedAmt);
		}
		USDsInstance.burn(msg.sender, USDsBurntAmt);
		USDsInstance.transferFrom(msg.sender, address(this), swapFeeAmount);

		emit USDsRedeemed(msg.sender, USDsBurntAmt, collateralUnlockedAmt,SPAMintAmt, swapFeeAmount);
	}

	/**
	 * @dev Calculate the total value of collaterals held by the Vault and all
	 *      strategies and update the supply of USDs.
	 */
	function rebase() external onlyOwner {
		_rebase();
	}

	/**
	 * @dev Calculate the total value of collaterals held by the Vault and all
	 *      strategies and update the supply of USDs, optionaly sending a
	 *      portion of the yield to the trustee.
	 */
	function _rebase() internal {
		IStrategy strategy;
		collateralStruct memory collateral;
		uint newTokensAmt;
		uint USDsSupply = USDsInstance._totalSupply();
		uint USDsSupplyIncrementTotal;
		uint USDsReceived;
		for (uint y = 0; y < allCollaterals.length; y++) {
			collateral = allCollaterals[y];
			strategy = IStrategy(collateral.defaultStrategyAddr);
			newTokensAmt = strategy.checkInterestEarned(collateral.collateralAddr);
			if (newTokensAmt > 0 && collateral.rebaseAllowed) {
				strategy.withdraw(address(this), collateral.collateralAddr, newTokensAmt);
				USDsReceived = IBuyback(collateral.buyBackAddr).swapExactInputSingle(newTokensAmt);
				USDsInstance.burn(address(this), USDsReceived);
				USDsSupplyIncrementTotal = USDsSupplyIncrementTotal.add(USDsReceived);
			}
		}
		uint USDsNewSupply = USDsSupply.add(USDsSupplyIncrementTotal);
		USDsInstance.changeSupply(USDsNewSupply);
		emit Rebase(USDsSupply, USDsNewSupply);
	}
	//
	// /**
	//  * @dev  _precision: same as chi (chi_prec)
	//  */
	//
	function collateralRatio() public view override returns (uint ratio) {
		uint totalValueLocked = _totalValueLocked();
		uint USDsSupply = USDsInstance.totalSupply();
		uint priceUSDs = uint(IOracle(oracleAddr).getUSDsPrice());
		uint precisionUSDs = IOracle(oracleAddr).getUSDsPrice_prec();
		uint USDsValue = USDsSupply.mul(priceUSDs).div(precisionUSDs);
		ratio = totalValueLocked.mul(chi_prec).div(USDsValue);
	}

	function totalValueLocked() external view returns (uint value) {
		value = _totalValueLocked();
	}

	function _totalValueLocked() internal view returns (uint value) {
		value = _totalValueInVault().add(_totalValueInStrategies());
	}

	function totalValueInVault() external view returns (uint value) {
		value = _totalValueInVault();
	}

	function _totalValueInVault() internal view returns (uint value) {
		for (uint y = 0; y < allCollaterals.length; y++) {
			collateralStruct memory collateral = allCollaterals[y];
			uint priceColla = IOracle(oracleAddr).getCollateralPrice(collateral.collateralAddr);
			uint precisionColla = IOracle(oracleAddr).getCollateralPrice_prec(collateral.collateralAddr);
			uint collateralAddrDecimal = uint(ERC20Upgradeable(collateral.collateralAddr).decimals());
			uint collaTotalValueInVault = ERC20Upgradeable(collateral.collateralAddr).balanceOf(address(this)).mul(priceColla).div(precisionColla);
			uint collaTotalValueInVault_18 = collaTotalValueInVault.mul(10**(uint(18).sub(collateralAddrDecimal)));
			value = value.add(collaTotalValueInVault_18);
		}
	}

	function totalValueInStrategies() external view returns (uint value) {
		value = _totalValueInStrategies();
	}

	function _totalValueInStrategies() internal view returns (uint value) {
		for (uint i = 0; i < allStrategies.length; i++) {
			if (allStrategies[i].enabled) {
				value = value.add(_totalValueInStrategy(allStrategies[i].strategyAddr));
			}
		}
	}

	function _totalValueInStrategy(address _strategyAddr) internal view returns (uint value) {
		IStrategy strategy = IStrategy(_strategyAddr);
		for (uint y = 0; y < allCollaterals.length; y++) {
			collateralStruct memory collateral = allCollaterals[y];
			if (strategy.supportsCollateral(collateral.collateralAddr)) {
				uint priceColla = IOracle(oracleAddr).getCollateralPrice(collateral.collateralAddr);
				uint precisionColla = IOracle(oracleAddr).getCollateralPrice_prec(collateral.collateralAddr);
				uint collateralAddrDecimal = uint(ERC20Upgradeable(collateral.collateralAddr).decimals());
				uint collaTotalValueInStrategy = strategy.checkBalance(collateral.collateralAddr).mul(priceColla).div(precisionColla);
				uint collaTotalValueInStrategy_18 = collaTotalValueInStrategy.mul(10**(uint(18).sub(collateralAddrDecimal)));
				value = value.add(collaTotalValueInStrategy_18);
			}
		}
	}

	/**
		* @notice Allocate unallocated funds on Vault to strategies.
		* @dev Allocate unallocated funds on Vault to strategies.
		**/
	function allocateAll() external whenAllocationAllowed onlyOwner {
		for (uint i = 0; i < allCollaterals.length; i++) {
			collateralStruct memory collateral = allCollaterals[i];
			if (collateral.supported && collateral.allocationAllowed) {
				IStrategy strategyInstance = IStrategy(collateral.defaultStrategyAddr);
				uint amtInVault = ERC20Upgradeable(collateral.collateralAddr).balanceOf(address(this));
				uint amtInStrategy = strategyInstance.checkBalance(collateral.collateralAddr);
				uint amtTotal = amtInVault.add(amtInStrategy);
				(, uint amtToAllocate) = amtTotal.mul(allocatePrecentage).div(allocatePrecentage_prec).trySub(amtInStrategy);
				if (amtToAllocate > 0) {
					_allocate(collateral.collateralAddr, amtToAllocate);
				}
			}
		}
	}

	function allocate(address _collateralAddr, uint amtToAllocate) external whenAllocationAllowed onlyOwner {
		_allocate(_collateralAddr, amtToAllocate);
	}

	/**
	* @notice Allocate unallocated funds on Vault to strategies.
	* @dev Allocate unallocated funds on Vault to strategies.
	**/
	function _allocate(address _collateralAddr, uint amtToAllocate) internal {
		collateralStruct memory collateral = collateralsInfo[_collateralAddr];
		require(collateral.supported, "_allocate: Collateral not supported. ");
		require(collateral.defaultStrategyAddr != address(0), "_allocate: Strategy not set. ");
		require(collateral.allocationAllowed, "_allocate: Allocation not allowed. ");
		IStrategy strategyInstance = IStrategy(collateralsInfo[_collateralAddr].defaultStrategyAddr);
		strategyStruct memory strategy = strategiesInfo[collateralsInfo[_collateralAddr].defaultStrategyAddr];
		require(strategy.strategyAddr != address(0), "_allocate: Strategy not set. ");
		require(strategy.enabled, "_allocate: Strategy not enabled. ");
		require(amtToAllocate > 0, "_allocate: amtToAllocate should be positive. ");
		ERC20Upgradeable(_collateralAddr).safeTransfer(collateral.defaultStrategyAddr, amtToAllocate);
		strategyInstance.deposit(_collateralAddr, amtToAllocate);
	}

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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}