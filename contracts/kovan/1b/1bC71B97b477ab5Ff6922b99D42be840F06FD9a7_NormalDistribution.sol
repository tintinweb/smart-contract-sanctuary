// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/INormalDistribution.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title NormalDistribution
 * @author Pods Finance
 * @notice Calculates the Cumulative Distribution Function of
 * the standard normal distribution
 */
contract NormalDistribution is INormalDistribution {
    using SafeMath for uint256;
    mapping(uint256 => uint256) private _probabilities;

    constructor() public {
        _probabilities[100] = 5040;
        _probabilities[200] = 5080;
        _probabilities[300] = 5120;
        _probabilities[400] = 5160;
        _probabilities[500] = 5199;
        _probabilities[600] = 5239;
        _probabilities[700] = 5279;
        _probabilities[800] = 5319;
        _probabilities[900] = 5359;
        _probabilities[1000] = 5398;
        _probabilities[1100] = 5438;
        _probabilities[1200] = 5478;
        _probabilities[1300] = 5517;
        _probabilities[1400] = 5557;
        _probabilities[1500] = 5596;
        _probabilities[1600] = 5636;
        _probabilities[1700] = 5675;
        _probabilities[1800] = 5714;
        _probabilities[1900] = 5753;
        _probabilities[2000] = 5793;
        _probabilities[2100] = 5832;
        _probabilities[2200] = 5871;
        _probabilities[2300] = 5910;
        _probabilities[2400] = 5948;
        _probabilities[2500] = 5987;
        _probabilities[2600] = 6026;
        _probabilities[2700] = 6064;
        _probabilities[2800] = 6103;
        _probabilities[2900] = 6141;
        _probabilities[3000] = 6179;
        _probabilities[3100] = 6217;
        _probabilities[3200] = 6255;
        _probabilities[3300] = 6293;
        _probabilities[3400] = 6331;
        _probabilities[3500] = 6368;
        _probabilities[3600] = 6406;
        _probabilities[3700] = 6443;
        _probabilities[3800] = 6480;
        _probabilities[3900] = 6517;
        _probabilities[4000] = 6554;
        _probabilities[4100] = 6591;
        _probabilities[4200] = 6628;
        _probabilities[4300] = 6664;
        _probabilities[4400] = 6700;
        _probabilities[4500] = 6736;
        _probabilities[4600] = 6772;
        _probabilities[4700] = 6808;
        _probabilities[4800] = 6844;
        _probabilities[4900] = 6879;
        _probabilities[5000] = 6915;
        _probabilities[5100] = 6950;
        _probabilities[5200] = 6985;
        _probabilities[5300] = 7019;
        _probabilities[5400] = 7054;
        _probabilities[5500] = 7088;
        _probabilities[5600] = 7123;
        _probabilities[5700] = 7157;
        _probabilities[5800] = 7190;
        _probabilities[5900] = 7224;
        _probabilities[6000] = 7257;
        _probabilities[6100] = 7291;
        _probabilities[6200] = 7324;
        _probabilities[6300] = 7357;
        _probabilities[6400] = 7389;
        _probabilities[6500] = 7422;
        _probabilities[6600] = 7454;
        _probabilities[6700] = 7486;
        _probabilities[6800] = 7517;
        _probabilities[6900] = 7549;
        _probabilities[7000] = 7580;
        _probabilities[7100] = 7611;
        _probabilities[7200] = 7642;
        _probabilities[7300] = 7673;
        _probabilities[7400] = 7704;
        _probabilities[7500] = 7734;
        _probabilities[7600] = 7764;
        _probabilities[7700] = 7794;
        _probabilities[7800] = 7823;
        _probabilities[7900] = 7852;
        _probabilities[8000] = 7881;
        _probabilities[8100] = 7910;
        _probabilities[8200] = 7939;
        _probabilities[8300] = 7967;
        _probabilities[8400] = 7995;
        _probabilities[8500] = 8023;
        _probabilities[8600] = 8051;
        _probabilities[8700] = 8078;
        _probabilities[8800] = 8106;
        _probabilities[8900] = 8133;
        _probabilities[9000] = 8159;
        _probabilities[9100] = 8186;
        _probabilities[9200] = 8212;
        _probabilities[9300] = 8238;
        _probabilities[9400] = 8264;
        _probabilities[9500] = 8289;
        _probabilities[9600] = 8315;
        _probabilities[9700] = 8340;
        _probabilities[9800] = 8365;
        _probabilities[9900] = 8389;
        _probabilities[10000] = 8413;
        _probabilities[10100] = 8438;
        _probabilities[10200] = 8461;
        _probabilities[10300] = 8485;
        _probabilities[10400] = 8508;
        _probabilities[10500] = 8531;
        _probabilities[10600] = 8554;
        _probabilities[10700] = 8577;
        _probabilities[10800] = 8599;
        _probabilities[10900] = 8621;
        _probabilities[11000] = 8643;
        _probabilities[11100] = 8665;
        _probabilities[11200] = 8686;
        _probabilities[11300] = 8708;
        _probabilities[11400] = 8729;
        _probabilities[11500] = 8749;
        _probabilities[11600] = 8770;
        _probabilities[11700] = 8790;
        _probabilities[11800] = 8810;
        _probabilities[11900] = 8830;
        _probabilities[12000] = 8849;
        _probabilities[12100] = 8869;
        _probabilities[12200] = 8888;
        _probabilities[12300] = 8907;
        _probabilities[12400] = 8925;
        _probabilities[12500] = 8944;
        _probabilities[12600] = 8962;
        _probabilities[12700] = 8980;
        _probabilities[12800] = 8997;
        _probabilities[12900] = 9015;
        _probabilities[13000] = 9032;
        _probabilities[13100] = 9049;
        _probabilities[13200] = 9066;
        _probabilities[13300] = 9082;
        _probabilities[13400] = 9099;
        _probabilities[13500] = 9115;
        _probabilities[13600] = 9131;
        _probabilities[13700] = 9147;
        _probabilities[13800] = 9162;
        _probabilities[13900] = 9177;
        _probabilities[14000] = 9192;
        _probabilities[14100] = 9207;
        _probabilities[14200] = 9222;
        _probabilities[14300] = 9236;
        _probabilities[14400] = 9251;
        _probabilities[14500] = 9265;
        _probabilities[14600] = 9279;
        _probabilities[14700] = 9292;
        _probabilities[14800] = 9306;
        _probabilities[14900] = 9319;
        _probabilities[15000] = 9332;
        _probabilities[15100] = 9345;
        _probabilities[15200] = 9357;
        _probabilities[15300] = 9370;
        _probabilities[15400] = 9382;
        _probabilities[15500] = 9394;
        _probabilities[15600] = 9406;
        _probabilities[15700] = 9418;
        _probabilities[15800] = 9429;
        _probabilities[15900] = 9441;
        _probabilities[16000] = 9452;
        _probabilities[16100] = 9463;
        _probabilities[16200] = 9474;
        _probabilities[16300] = 9484;
        _probabilities[16400] = 9495;
        _probabilities[16500] = 9505;
        _probabilities[16600] = 9515;
        _probabilities[16700] = 9525;
        _probabilities[16800] = 9535;
        _probabilities[16900] = 9545;
        _probabilities[17000] = 9554;
        _probabilities[17100] = 9564;
        _probabilities[17200] = 9573;
        _probabilities[17300] = 9582;
        _probabilities[17400] = 9591;
        _probabilities[17500] = 9599;
        _probabilities[17600] = 9608;
        _probabilities[17700] = 9616;
        _probabilities[17800] = 9625;
        _probabilities[17900] = 9633;
        _probabilities[18000] = 9641;
        _probabilities[18100] = 9649;
        _probabilities[18200] = 9656;
        _probabilities[18300] = 9664;
        _probabilities[18400] = 9671;
        _probabilities[18500] = 9678;
        _probabilities[18600] = 9686;
        _probabilities[18700] = 9693;
        _probabilities[18800] = 9699;
        _probabilities[18900] = 9706;
        _probabilities[19000] = 9713;
        _probabilities[19100] = 9719;
        _probabilities[19200] = 9726;
        _probabilities[19300] = 9732;
        _probabilities[19400] = 9738;
        _probabilities[19500] = 9744;
        _probabilities[19600] = 9750;
        _probabilities[19700] = 9756;
        _probabilities[19800] = 9761;
        _probabilities[19900] = 9767;
        _probabilities[20000] = 9772;
        _probabilities[20100] = 9778;
        _probabilities[20200] = 9783;
        _probabilities[20300] = 9788;
        _probabilities[20400] = 9793;
        _probabilities[20500] = 9798;
        _probabilities[20600] = 9803;
        _probabilities[20700] = 9808;
        _probabilities[20800] = 9812;
        _probabilities[20900] = 9817;
        _probabilities[21000] = 9821;
        _probabilities[21100] = 9826;
        _probabilities[21200] = 9830;
        _probabilities[21300] = 9834;
        _probabilities[21400] = 9838;
        _probabilities[21500] = 9842;
        _probabilities[21600] = 9846;
        _probabilities[21700] = 9850;
        _probabilities[21800] = 9854;
        _probabilities[21900] = 9857;
        _probabilities[22000] = 9861;
        _probabilities[22100] = 9864;
        _probabilities[22200] = 9868;
        _probabilities[22300] = 9871;
        _probabilities[22400] = 9874;
        _probabilities[22500] = 9879;
        _probabilities[22600] = 9880;
        _probabilities[22700] = 9884;
        _probabilities[22800] = 9887;
        _probabilities[22900] = 9890;
        _probabilities[23000] = 9893;
        _probabilities[23100] = 9896;
        _probabilities[23200] = 9898;
        _probabilities[23300] = 9901;
        _probabilities[23400] = 9904;
        _probabilities[23500] = 9906;
        _probabilities[23600] = 9909;
        _probabilities[23700] = 9911;
        _probabilities[23800] = 9913;
        _probabilities[23900] = 9916;
        _probabilities[24000] = 9918;
        _probabilities[24100] = 9920;
        _probabilities[24200] = 9922;
        _probabilities[24300] = 9924;
        _probabilities[24400] = 9927;
        _probabilities[24500] = 9929;
        _probabilities[24600] = 9930;
        _probabilities[24700] = 9932;
        _probabilities[24800] = 9934;
        _probabilities[24900] = 9936;
        _probabilities[25000] = 9938;
        _probabilities[25100] = 9940;
        _probabilities[25200] = 9941;
        _probabilities[25300] = 9943;
        _probabilities[25400] = 9945;
        _probabilities[25500] = 9946;
        _probabilities[25600] = 9948;
        _probabilities[25700] = 9949;
        _probabilities[25800] = 9951;
        _probabilities[25900] = 9952;
        _probabilities[26000] = 9953;
        _probabilities[26100] = 9955;
        _probabilities[26200] = 9956;
        _probabilities[26300] = 9957;
        _probabilities[26400] = 9958;
        _probabilities[26500] = 9960;
        _probabilities[26600] = 9961;
        _probabilities[26700] = 9962;
        _probabilities[26800] = 9963;
        _probabilities[26900] = 9964;
        _probabilities[27000] = 9965;
        _probabilities[27100] = 9966;
        _probabilities[27200] = 9967;
        _probabilities[27300] = 9968;
        _probabilities[27400] = 9969;
        _probabilities[27500] = 9970;
        _probabilities[27600] = 9971;
        _probabilities[27700] = 9972;
        _probabilities[27800] = 9973;
        _probabilities[27900] = 9974;
        _probabilities[28000] = 9974;
        _probabilities[28100] = 9975;
        _probabilities[28200] = 9976;
        _probabilities[28300] = 9977;
        _probabilities[28400] = 9977;
        _probabilities[28500] = 9978;
        _probabilities[28600] = 9979;
        _probabilities[28700] = 9979;
        _probabilities[28800] = 9980;
        _probabilities[28900] = 9981;
        _probabilities[29000] = 9981;
        _probabilities[29100] = 9982;
        _probabilities[29200] = 9982;
        _probabilities[29300] = 9983;
        _probabilities[29400] = 9984;
        _probabilities[29500] = 9984;
        _probabilities[29600] = 9985;
        _probabilities[29700] = 9985;
        _probabilities[29800] = 9986;
        _probabilities[29900] = 9986;
        _probabilities[30000] = 9986;
        _probabilities[30100] = 9987;
        _probabilities[30200] = 9987;
        _probabilities[30300] = 9988;
        _probabilities[30400] = 9988;
        _probabilities[30500] = 9989;
        _probabilities[30600] = 9989;
        _probabilities[30700] = 9989;
    }

    /**
     * @notice Returns the probability of Z in a normal distribution curve
     * @dev For performance numbers are truncated to 2 decimals. Ex: 1134500000000000000(1.13) gets truncated to 113
     * @dev For Z > ±0.307 the curve response gets more concentrated
     * @param z A point in the normal distribution
     * @param decimals Amount of decimals of z
     * @return The probability of a z variable in a normal distribution
     */
    function getProbability(int256 z, uint256 decimals) external override view returns (uint256) {
        require(decimals >= 4 && decimals < 77, "NormalDistribution: invalid decimals");
        uint256 absZ = _abs(z);
        uint256 truncatedZ = absZ.div(10**(decimals.sub(2))).mul(100);
        uint256 responseDecimals = 10**(decimals.sub(4));

        // Handle negative z
        if (z < 0) {
            return uint256(10000).sub(_nearest(truncatedZ)).mul(responseDecimals);
        }

        return _nearest(truncatedZ).mul(responseDecimals);
    }

    /**
     * @dev Returns the module of a number.
     */
    function _abs(int256 a) internal pure returns (uint256) {
        return a < 0 ? uint256(-a) : uint256(a);
    }

    /**
     * @dev Returns the nearest z value on the table
     */
    function _nearest(uint256 z) internal view returns (uint256) {
        if (z >= 36300) {
            return 9999;
        } else if (z >= 34900) {
            return 9998;
        } else if (z >= 34000) {
            return 9997;
        } else if (z >= 33300) {
            return 9996;
        } else if (z >= 32700) {
            return 9995;
        } else if (z >= 32200) {
            return 9994;
        } else if (z >= 31800) {
            return 9993;
        } else if (z >= 31400) {
            return 9992;
        } else if (z >= 31100) {
            return 9991;
        } else if (z >= 30800) {
            return 9990;
        } else {
            return _probabilities[z];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface INormalDistribution {
    function getProbability(int256 z, uint256 decimals) external view returns (uint256);
}

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}