// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/INormalDistribution.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title NormalDistribution
 * @author Pods Finance
 * @notice Calculates the Cumulative Distribution Function of
 * the standard normal distribution
 */
contract NormalDistribution is INormalDistribution, Ownable {
    using SafeMath for uint256;
    mapping(uint256 => uint256) private _probabilities;

    event DataPointSet(uint256 key, uint256 value);

    constructor() public {
        _probabilities[0] = 50000;
        _probabilities[100] = 50399;
        _probabilities[200] = 50798;
        _probabilities[300] = 51197;
        _probabilities[400] = 51595;
        _probabilities[500] = 51994;
        _probabilities[600] = 52392;
        _probabilities[700] = 52790;
        _probabilities[800] = 53188;
        _probabilities[900] = 53586;
        _probabilities[1000] = 53983;
        _probabilities[1100] = 54380;
        _probabilities[1200] = 54776;
        _probabilities[1300] = 55172;
        _probabilities[1400] = 55567;
        _probabilities[1500] = 55962;
        _probabilities[1600] = 56356;
        _probabilities[1700] = 56749;
        _probabilities[1800] = 57142;
        _probabilities[1900] = 57535;
        _probabilities[2000] = 57926;
        _probabilities[2100] = 58317;
        _probabilities[2200] = 58706;
        _probabilities[2300] = 59095;
        _probabilities[2400] = 59483;
        _probabilities[2500] = 59871;
        _probabilities[2600] = 60257;
        _probabilities[2700] = 60642;
        _probabilities[2800] = 61026;
        _probabilities[2900] = 61409;
        _probabilities[3000] = 61791;
        _probabilities[3100] = 62172;
        _probabilities[3200] = 62552;
        _probabilities[3300] = 62930;
        _probabilities[3400] = 63307;
        _probabilities[3500] = 63683;
        _probabilities[3600] = 64058;
        _probabilities[3700] = 64431;
        _probabilities[3800] = 64803;
        _probabilities[3900] = 65173;
        _probabilities[4000] = 65542;
        _probabilities[4100] = 65910;
        _probabilities[4200] = 66276;
        _probabilities[4300] = 66640;
        _probabilities[4400] = 67003;
        _probabilities[4500] = 67364;
        _probabilities[4600] = 67724;
        _probabilities[4700] = 68082;
        _probabilities[4800] = 68439;
        _probabilities[4900] = 68793;
        _probabilities[5000] = 69146;
        _probabilities[5100] = 69497;
        _probabilities[5200] = 69847;
        _probabilities[5300] = 70194;
        _probabilities[5400] = 70540;
        _probabilities[5500] = 70884;
        _probabilities[5600] = 71226;
        _probabilities[5700] = 71566;
        _probabilities[5800] = 71904;
        _probabilities[5900] = 72240;
        _probabilities[6000] = 72575;
        _probabilities[6100] = 72907;
        _probabilities[6200] = 73237;
        _probabilities[6300] = 73565;
        _probabilities[6400] = 73891;
        _probabilities[6500] = 74215;
        _probabilities[6600] = 74537;
        _probabilities[6700] = 74857;
        _probabilities[6800] = 75175;
        _probabilities[6900] = 75490;
        _probabilities[7000] = 75804;
        _probabilities[7100] = 76115;
        _probabilities[7200] = 76424;
        _probabilities[7300] = 76730;
        _probabilities[7400] = 77035;
        _probabilities[7500] = 77337;
        _probabilities[7600] = 77637;
        _probabilities[7700] = 77935;
        _probabilities[7800] = 78230;
        _probabilities[7900] = 78524;
        _probabilities[8000] = 78814;
        _probabilities[8100] = 79103;
        _probabilities[8200] = 79389;
        _probabilities[8300] = 79673;
        _probabilities[8400] = 79955;
        _probabilities[8500] = 80234;
        _probabilities[8600] = 80511;
        _probabilities[8700] = 80785;
        _probabilities[8800] = 81057;
        _probabilities[8900] = 81327;
        _probabilities[9000] = 81594;
        _probabilities[9100] = 81859;
        _probabilities[9200] = 82121;
        _probabilities[9300] = 82381;
        _probabilities[9400] = 82639;
        _probabilities[9500] = 82894;
        _probabilities[9600] = 83147;
        _probabilities[9700] = 83398;
        _probabilities[9800] = 83646;
        _probabilities[9900] = 83891;
        _probabilities[10000] = 84134;
        _probabilities[10100] = 84375;
        _probabilities[10200] = 84614;
        _probabilities[10300] = 84849;
        _probabilities[10400] = 85083;
        _probabilities[10500] = 85314;
        _probabilities[10600] = 85543;
        _probabilities[10700] = 85769;
        _probabilities[10800] = 85993;
        _probabilities[10900] = 86214;
        _probabilities[11000] = 86433;
        _probabilities[11100] = 86650;
        _probabilities[11200] = 86864;
        _probabilities[11300] = 87076;
        _probabilities[11400] = 87286;
        _probabilities[11500] = 87493;
        _probabilities[11600] = 87698;
        _probabilities[11700] = 87900;
        _probabilities[11800] = 88100;
        _probabilities[11900] = 88298;
        _probabilities[12000] = 88493;
        _probabilities[12100] = 88686;
        _probabilities[12200] = 88877;
        _probabilities[12300] = 89065;
        _probabilities[12400] = 89251;
        _probabilities[12500] = 89435;
        _probabilities[12600] = 89617;
        _probabilities[12700] = 89796;
        _probabilities[12800] = 89973;
        _probabilities[12900] = 90147;
        _probabilities[13000] = 90320;
        _probabilities[13100] = 90490;
        _probabilities[13200] = 90658;
        _probabilities[13300] = 90824;
        _probabilities[13400] = 90988;
        _probabilities[13500] = 91149;
        _probabilities[13600] = 91309;
        _probabilities[13700] = 91466;
        _probabilities[13800] = 91621;
        _probabilities[13900] = 91774;
        _probabilities[14000] = 91924;
        _probabilities[14100] = 92073;
        _probabilities[14200] = 92220;
        _probabilities[14300] = 92364;
        _probabilities[14400] = 92507;
        _probabilities[14500] = 92647;
        _probabilities[14600] = 92785;
        _probabilities[14700] = 92922;
        _probabilities[14800] = 93056;
        _probabilities[14900] = 93189;
        _probabilities[15000] = 93319;
        _probabilities[15100] = 93448;
        _probabilities[15200] = 93574;
        _probabilities[15300] = 93699;
        _probabilities[15400] = 93822;
        _probabilities[15500] = 93943;
        _probabilities[15600] = 94062;
        _probabilities[15700] = 94179;
        _probabilities[15800] = 94295;
        _probabilities[15900] = 94408;
        _probabilities[16000] = 94520;
        _probabilities[16100] = 94630;
        _probabilities[16200] = 94738;
        _probabilities[16300] = 94845;
        _probabilities[16400] = 94950;
        _probabilities[16500] = 95053;
        _probabilities[16600] = 95154;
        _probabilities[16700] = 95254;
        _probabilities[16800] = 95352;
        _probabilities[16900] = 95449;
        _probabilities[17000] = 95543;
        _probabilities[17100] = 95637;
        _probabilities[17200] = 95728;
        _probabilities[17300] = 95818;
        _probabilities[17400] = 95907;
        _probabilities[17500] = 95994;
        _probabilities[17600] = 96080;
        _probabilities[17700] = 96164;
        _probabilities[17800] = 96246;
        _probabilities[17900] = 96327;
        _probabilities[18000] = 96407;
        _probabilities[18100] = 96485;
        _probabilities[18200] = 96562;
        _probabilities[18300] = 96638;
        _probabilities[18400] = 96712;
        _probabilities[18500] = 96784;
        _probabilities[18600] = 96856;
        _probabilities[18700] = 96926;
        _probabilities[18800] = 96995;
        _probabilities[18900] = 97062;
        _probabilities[19000] = 97128;
        _probabilities[19100] = 97193;
        _probabilities[19200] = 97257;
        _probabilities[19300] = 97320;
        _probabilities[19400] = 97381;
        _probabilities[19500] = 97441;
        _probabilities[19600] = 97500;
        _probabilities[19700] = 97558;
        _probabilities[19800] = 97615;
        _probabilities[19900] = 97670;
        _probabilities[20000] = 97725;
        _probabilities[20100] = 97778;
        _probabilities[20200] = 97831;
        _probabilities[20300] = 97882;
        _probabilities[20400] = 97932;
        _probabilities[20500] = 97982;
        _probabilities[20600] = 98030;
        _probabilities[20700] = 98077;
        _probabilities[20800] = 98124;
        _probabilities[20900] = 98169;
        _probabilities[21000] = 98214;
        _probabilities[21100] = 98257;
        _probabilities[21200] = 98300;
        _probabilities[21300] = 98341;
        _probabilities[21400] = 98382;
        _probabilities[21500] = 98422;
        _probabilities[21600] = 98461;
        _probabilities[21700] = 98500;
        _probabilities[21800] = 98537;
        _probabilities[21900] = 98574;
        _probabilities[22000] = 98610;
        _probabilities[22100] = 98645;
        _probabilities[22200] = 98679;
        _probabilities[22300] = 98713;
        _probabilities[22400] = 98745;
        _probabilities[22500] = 98778;
        _probabilities[22600] = 98809;
        _probabilities[22700] = 98840;
        _probabilities[22800] = 98870;
        _probabilities[22900] = 98899;
        _probabilities[23000] = 98928;
        _probabilities[23100] = 98956;
        _probabilities[23200] = 98983;
        _probabilities[23300] = 99010;
        _probabilities[23400] = 99036;
        _probabilities[23500] = 99061;
        _probabilities[23600] = 99086;
        _probabilities[23700] = 99111;
        _probabilities[23800] = 99134;
        _probabilities[23900] = 99158;
        _probabilities[24000] = 99180;
        _probabilities[24100] = 99202;
        _probabilities[24200] = 99224;
        _probabilities[24300] = 99245;
        _probabilities[24400] = 99266;
        _probabilities[24500] = 99286;
        _probabilities[24600] = 99305;
        _probabilities[24700] = 99324;
        _probabilities[24800] = 99343;
        _probabilities[24900] = 99361;
        _probabilities[25000] = 99379;
        _probabilities[25100] = 99396;
        _probabilities[25200] = 99413;
        _probabilities[25300] = 99430;
        _probabilities[25400] = 99446;
        _probabilities[25500] = 99461;
        _probabilities[25600] = 99477;
        _probabilities[25700] = 99492;
        _probabilities[25800] = 99506;
        _probabilities[25900] = 99520;
        _probabilities[26000] = 99534;
        _probabilities[26100] = 99547;
        _probabilities[26200] = 99560;
        _probabilities[26300] = 99573;
        _probabilities[26400] = 99585;
        _probabilities[26500] = 99598;
        _probabilities[26600] = 99609;
        _probabilities[26700] = 99621;
        _probabilities[26800] = 99632;
        _probabilities[26900] = 99643;
        _probabilities[27000] = 99653;
        _probabilities[27100] = 99664;
        _probabilities[27200] = 99674;
        _probabilities[27300] = 99683;
        _probabilities[27400] = 99693;
        _probabilities[27500] = 99702;
        _probabilities[27600] = 99711;
        _probabilities[27700] = 99720;
        _probabilities[27800] = 99728;
        _probabilities[27900] = 99736;
        _probabilities[28000] = 99744;
        _probabilities[28100] = 99752;
        _probabilities[28200] = 99760;
        _probabilities[28300] = 99767;
        _probabilities[28400] = 99774;
        _probabilities[28500] = 99781;
        _probabilities[28600] = 99788;
        _probabilities[28700] = 99795;
        _probabilities[28800] = 99801;
        _probabilities[28900] = 99807;
        _probabilities[29000] = 99813;
        _probabilities[29100] = 99819;
        _probabilities[29200] = 99825;
        _probabilities[29300] = 99831;
        _probabilities[29400] = 99836;
        _probabilities[29500] = 99841;
        _probabilities[29600] = 99846;
        _probabilities[29700] = 99851;
        _probabilities[29800] = 99856;
        _probabilities[29900] = 99861;
        _probabilities[30000] = 99865;
        _probabilities[30100] = 99869;
        _probabilities[30200] = 99874;
        _probabilities[30300] = 99878;
        _probabilities[30400] = 99882;
        _probabilities[30500] = 99886;
        _probabilities[30600] = 99889;
        _probabilities[30700] = 99893;
        _probabilities[30800] = 99896;
        _probabilities[30900] = 99900;
        _probabilities[31000] = 99903;
        _probabilities[31100] = 99906;
        _probabilities[31200] = 99910;
        _probabilities[31300] = 99913;
        _probabilities[31400] = 99916;
        _probabilities[31500] = 99918;
        _probabilities[31600] = 99921;
        _probabilities[31700] = 99924;
        _probabilities[31800] = 99926;
        _probabilities[31900] = 99929;
        _probabilities[32000] = 99931;
        _probabilities[32100] = 99934;
        _probabilities[32200] = 99936;
        _probabilities[32300] = 99938;
        _probabilities[32400] = 99940;
        _probabilities[32500] = 99942;
        _probabilities[32600] = 99944;
        _probabilities[32700] = 99946;
        _probabilities[32800] = 99948;
        _probabilities[32900] = 99950;
        _probabilities[33000] = 99952;
        _probabilities[33100] = 99953;
        _probabilities[33200] = 99955;
        _probabilities[33300] = 99957;
        _probabilities[33400] = 99958;
        _probabilities[33500] = 99960;
        _probabilities[33600] = 99961;
        _probabilities[33700] = 99962;
        _probabilities[33800] = 99964;
        _probabilities[33900] = 99965;
        _probabilities[34000] = 99966;
        _probabilities[34100] = 99968;
        _probabilities[34200] = 99969;
        _probabilities[34300] = 99970;
        _probabilities[34400] = 99971;
        _probabilities[34500] = 99972;
        _probabilities[34600] = 99973;
        _probabilities[34700] = 99974;
        _probabilities[34800] = 99975;
        _probabilities[34900] = 99976;
        _probabilities[35000] = 99977;
        _probabilities[35100] = 99978;
        _probabilities[35200] = 99978;
        _probabilities[35300] = 99979;
        _probabilities[35400] = 99980;
        _probabilities[35500] = 99981;
        _probabilities[35600] = 99981;
        _probabilities[35700] = 99982;
        _probabilities[35800] = 99983;
        _probabilities[35900] = 99983;
        _probabilities[36000] = 99984;
        _probabilities[36100] = 99985;
        _probabilities[36200] = 99985;
        _probabilities[36300] = 99986;
        _probabilities[36400] = 99986;
        _probabilities[36500] = 99987;
        _probabilities[36600] = 99987;
        _probabilities[36700] = 99988;
        _probabilities[36800] = 99988;
        _probabilities[36900] = 99989;
        _probabilities[37000] = 99989;
        _probabilities[37100] = 99990;
        _probabilities[37200] = 99990;
        _probabilities[37300] = 99990;
        _probabilities[37400] = 99991;
        _probabilities[37500] = 99991;
        _probabilities[37600] = 99992;
        _probabilities[37700] = 99992;
        _probabilities[37800] = 99992;
        _probabilities[37900] = 99992;
        _probabilities[38000] = 99993;
        _probabilities[38100] = 99993;
        _probabilities[38200] = 99993;
        _probabilities[38300] = 99994;
        _probabilities[38400] = 99994;
        _probabilities[38500] = 99994;
        _probabilities[38600] = 99994;
        _probabilities[38700] = 99995;
        _probabilities[38800] = 99995;
        _probabilities[38900] = 99995;
        _probabilities[39000] = 99995;
        _probabilities[39100] = 99995;
        _probabilities[39200] = 99996;
        _probabilities[39300] = 99996;
        _probabilities[39400] = 99996;
        _probabilities[39500] = 99996;
        _probabilities[39600] = 99996;
        _probabilities[39700] = 99996;
        _probabilities[39800] = 99997;
        _probabilities[39900] = 99997;
        _probabilities[40000] = 99997;
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
        require(decimals >= 5 && decimals < 77, "NormalDistribution: invalid decimals");
        uint256 absZ = _abs(z);
        uint256 truncatedZ = absZ.div(10**(decimals.sub(2))).mul(100);
        uint256 fourthDigit = _abs(z).div(10**(decimals.sub(3))) - _abs(z).div(10**(decimals.sub(2))).mul(10);
        uint256 responseDecimals = 10**(decimals.sub(5));
        uint256 responseValue;

        if (truncatedZ >= 41900) {
            responseValue = 99999;
        } else if (truncatedZ >= 41100) {
            responseValue = 99998;
        } else if (truncatedZ >= 40100) {
            responseValue = 99997;
        } else if (fourthDigit >= 7) {
            // If the fourthDigit is 7, 8 or 9, rounds up to the next data point
            responseValue = _probabilities[truncatedZ + 100];
        } else if (fourthDigit >= 4) {
            // If the fourthDigit is 4, 5 or 6, get the average between the current and the next
            responseValue = _probabilities[truncatedZ].add(_probabilities[truncatedZ + 100]).div(2);
        } else {
            // If the fourthDigit is 0, 1, 2 or 3, get the current
            responseValue = _probabilities[truncatedZ];
        }

        // Handle negative z
        if (z < 0) {
            responseValue = uint256(100000).sub(responseValue);
        }

        return responseValue.mul(responseDecimals);
    }

    /**
     * @dev Defines a new probability point
     * @param key A point in the normal distribution
     * @param value The value
     */
    function setDataPoint(uint256 key, uint256 value) external override onlyOwner {
        _probabilities[key] = value;
        emit DataPointSet(key, value);
    }

    /**
     * @dev Returns the module of a number.
     */
    function _abs(int256 a) internal pure returns (uint256) {
        return a < 0 ? uint256(-a) : uint256(a);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface INormalDistribution {
    function getProbability(int256 z, uint256 decimals) external view returns (uint256);

    function setDataPoint(uint256 key, uint256 value) external;
}

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

