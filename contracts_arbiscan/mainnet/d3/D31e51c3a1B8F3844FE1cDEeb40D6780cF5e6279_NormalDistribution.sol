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
    mapping(uint256 => uint256) private _cachedDataPoints;

    event DataPointSet(uint256 key, uint256 value);

    constructor() public {
        _cachedDataPoints[0] = 50000;
        _cachedDataPoints[100] = 50399;
        _cachedDataPoints[200] = 50798;
        _cachedDataPoints[300] = 51197;
        _cachedDataPoints[400] = 51595;
        _cachedDataPoints[500] = 51994;
        _cachedDataPoints[600] = 52392;
        _cachedDataPoints[700] = 52790;
        _cachedDataPoints[800] = 53188;
        _cachedDataPoints[900] = 53586;
        _cachedDataPoints[1000] = 53983;
        _cachedDataPoints[1100] = 54380;
        _cachedDataPoints[1200] = 54776;
        _cachedDataPoints[1300] = 55172;
        _cachedDataPoints[1400] = 55567;
        _cachedDataPoints[1500] = 55962;
        _cachedDataPoints[1600] = 56356;
        _cachedDataPoints[1700] = 56749;
        _cachedDataPoints[1800] = 57142;
        _cachedDataPoints[1900] = 57535;
        _cachedDataPoints[2000] = 57926;
        _cachedDataPoints[2100] = 58317;
        _cachedDataPoints[2200] = 58706;
        _cachedDataPoints[2300] = 59095;
        _cachedDataPoints[2400] = 59483;
        _cachedDataPoints[2500] = 59871;
        _cachedDataPoints[2600] = 60257;
        _cachedDataPoints[2700] = 60642;
        _cachedDataPoints[2800] = 61026;
        _cachedDataPoints[2900] = 61409;
        _cachedDataPoints[3000] = 61791;
        _cachedDataPoints[3100] = 62172;
        _cachedDataPoints[3200] = 62552;
        _cachedDataPoints[3300] = 62930;
        _cachedDataPoints[3400] = 63307;
        _cachedDataPoints[3500] = 63683;
        _cachedDataPoints[3600] = 64058;
        _cachedDataPoints[3700] = 64431;
        _cachedDataPoints[3800] = 64803;
        _cachedDataPoints[3900] = 65173;
        _cachedDataPoints[4000] = 65542;
        _cachedDataPoints[4100] = 65910;
        _cachedDataPoints[4200] = 66276;
        _cachedDataPoints[4300] = 66640;
        _cachedDataPoints[4400] = 67003;
        _cachedDataPoints[4500] = 67364;
        _cachedDataPoints[4600] = 67724;
        _cachedDataPoints[4700] = 68082;
        _cachedDataPoints[4800] = 68439;
        _cachedDataPoints[4900] = 68793;
        _cachedDataPoints[5000] = 69146;
        _cachedDataPoints[5100] = 69497;
        _cachedDataPoints[5200] = 69847;
        _cachedDataPoints[5300] = 70194;
        _cachedDataPoints[5400] = 70540;
        _cachedDataPoints[5500] = 70884;
        _cachedDataPoints[5600] = 71226;
        _cachedDataPoints[5700] = 71566;
        _cachedDataPoints[5800] = 71904;
        _cachedDataPoints[5900] = 72240;
        _cachedDataPoints[6000] = 72575;
        _cachedDataPoints[6100] = 72907;
        _cachedDataPoints[6200] = 73237;
        _cachedDataPoints[6300] = 73565;
        _cachedDataPoints[6400] = 73891;
        _cachedDataPoints[6500] = 74215;
        _cachedDataPoints[6600] = 74537;
        _cachedDataPoints[6700] = 74857;
        _cachedDataPoints[6800] = 75175;
        _cachedDataPoints[6900] = 75490;
        _cachedDataPoints[7000] = 75804;
        _cachedDataPoints[7100] = 76115;
        _cachedDataPoints[7200] = 76424;
        _cachedDataPoints[7300] = 76730;
        _cachedDataPoints[7400] = 77035;
        _cachedDataPoints[7500] = 77337;
        _cachedDataPoints[7600] = 77637;
        _cachedDataPoints[7700] = 77935;
        _cachedDataPoints[7800] = 78230;
        _cachedDataPoints[7900] = 78524;
        _cachedDataPoints[8000] = 78814;
        _cachedDataPoints[8100] = 79103;
        _cachedDataPoints[8200] = 79389;
        _cachedDataPoints[8300] = 79673;
        _cachedDataPoints[8400] = 79955;
        _cachedDataPoints[8500] = 80234;
        _cachedDataPoints[8600] = 80511;
        _cachedDataPoints[8700] = 80785;
        _cachedDataPoints[8800] = 81057;
        _cachedDataPoints[8900] = 81327;
        _cachedDataPoints[9000] = 81594;
        _cachedDataPoints[9100] = 81859;
        _cachedDataPoints[9200] = 82121;
        _cachedDataPoints[9300] = 82381;
        _cachedDataPoints[9400] = 82639;
        _cachedDataPoints[9500] = 82894;
        _cachedDataPoints[9600] = 83147;
        _cachedDataPoints[9700] = 83398;
        _cachedDataPoints[9800] = 83646;
        _cachedDataPoints[9900] = 83891;
        _cachedDataPoints[10000] = 84134;
        _cachedDataPoints[10100] = 84375;
        _cachedDataPoints[10200] = 84614;
        _cachedDataPoints[10300] = 84849;
        _cachedDataPoints[10400] = 85083;
        _cachedDataPoints[10500] = 85314;
        _cachedDataPoints[10600] = 85543;
        _cachedDataPoints[10700] = 85769;
        _cachedDataPoints[10800] = 85993;
        _cachedDataPoints[10900] = 86214;
        _cachedDataPoints[11000] = 86433;
        _cachedDataPoints[11100] = 86650;
        _cachedDataPoints[11200] = 86864;
        _cachedDataPoints[11300] = 87076;
        _cachedDataPoints[11400] = 87286;
        _cachedDataPoints[11500] = 87493;
        _cachedDataPoints[11600] = 87698;
        _cachedDataPoints[11700] = 87900;
        _cachedDataPoints[11800] = 88100;
        _cachedDataPoints[11900] = 88298;
        _cachedDataPoints[12000] = 88493;
        _cachedDataPoints[12100] = 88686;
        _cachedDataPoints[12200] = 88877;
        _cachedDataPoints[12300] = 89065;
        _cachedDataPoints[12400] = 89251;
        _cachedDataPoints[12500] = 89435;
        _cachedDataPoints[12600] = 89617;
        _cachedDataPoints[12700] = 89796;
        _cachedDataPoints[12800] = 89973;
        _cachedDataPoints[12900] = 90147;
        _cachedDataPoints[13000] = 90320;
        _cachedDataPoints[13100] = 90490;
        _cachedDataPoints[13200] = 90658;
        _cachedDataPoints[13300] = 90824;
        _cachedDataPoints[13400] = 90988;
        _cachedDataPoints[13500] = 91149;
        _cachedDataPoints[13600] = 91309;
        _cachedDataPoints[13700] = 91466;
        _cachedDataPoints[13800] = 91621;
        _cachedDataPoints[13900] = 91774;
        _cachedDataPoints[14000] = 91924;
        _cachedDataPoints[14100] = 92073;
        _cachedDataPoints[14200] = 92220;
        _cachedDataPoints[14300] = 92364;
        _cachedDataPoints[14400] = 92507;
        _cachedDataPoints[14500] = 92647;
        _cachedDataPoints[14600] = 92785;
        _cachedDataPoints[14700] = 92922;
        _cachedDataPoints[14800] = 93056;
        _cachedDataPoints[14900] = 93189;
        _cachedDataPoints[15000] = 93319;
        _cachedDataPoints[15100] = 93448;
        _cachedDataPoints[15200] = 93574;
        _cachedDataPoints[15300] = 93699;
        _cachedDataPoints[15400] = 93822;
        _cachedDataPoints[15500] = 93943;
        _cachedDataPoints[15600] = 94062;
        _cachedDataPoints[15700] = 94179;
        _cachedDataPoints[15800] = 94295;
        _cachedDataPoints[15900] = 94408;
        _cachedDataPoints[16000] = 94520;
        _cachedDataPoints[16100] = 94630;
        _cachedDataPoints[16200] = 94738;
        _cachedDataPoints[16300] = 94845;
        _cachedDataPoints[16400] = 94950;
        _cachedDataPoints[16500] = 95053;
        _cachedDataPoints[16600] = 95154;
        _cachedDataPoints[16700] = 95254;
        _cachedDataPoints[16800] = 95352;
        _cachedDataPoints[16900] = 95449;
        _cachedDataPoints[17000] = 95543;
        _cachedDataPoints[17100] = 95637;
        _cachedDataPoints[17200] = 95728;
        _cachedDataPoints[17300] = 95818;
        _cachedDataPoints[17400] = 95907;
        _cachedDataPoints[17500] = 95994;
        _cachedDataPoints[17600] = 96080;
        _cachedDataPoints[17700] = 96164;
        _cachedDataPoints[17800] = 96246;
        _cachedDataPoints[17900] = 96327;
        _cachedDataPoints[18000] = 96407;
        _cachedDataPoints[18100] = 96485;
        _cachedDataPoints[18200] = 96562;
        _cachedDataPoints[18300] = 96638;
        _cachedDataPoints[18400] = 96712;
        _cachedDataPoints[18500] = 96784;
        _cachedDataPoints[18600] = 96856;
        _cachedDataPoints[18700] = 96926;
        _cachedDataPoints[18800] = 96995;
        _cachedDataPoints[18900] = 97062;
        _cachedDataPoints[19000] = 97128;
        _cachedDataPoints[19100] = 97193;
        _cachedDataPoints[19200] = 97257;
        _cachedDataPoints[19300] = 97320;
        _cachedDataPoints[19400] = 97381;
        _cachedDataPoints[19500] = 97441;
        _cachedDataPoints[19600] = 97500;
        _cachedDataPoints[19700] = 97558;
        _cachedDataPoints[19800] = 97615;
        _cachedDataPoints[19900] = 97670;
        _cachedDataPoints[20000] = 97725;
        _cachedDataPoints[20100] = 97778;
        _cachedDataPoints[20200] = 97831;
        _cachedDataPoints[20300] = 97882;
        _cachedDataPoints[20400] = 97932;
        _cachedDataPoints[20500] = 97982;
        _cachedDataPoints[20600] = 98030;
        _cachedDataPoints[20700] = 98077;
        _cachedDataPoints[20800] = 98124;
        _cachedDataPoints[20900] = 98169;
        _cachedDataPoints[21000] = 98214;
        _cachedDataPoints[21100] = 98257;
        _cachedDataPoints[21200] = 98300;
        _cachedDataPoints[21300] = 98341;
        _cachedDataPoints[21400] = 98382;
        _cachedDataPoints[21500] = 98422;
        _cachedDataPoints[21600] = 98461;
        _cachedDataPoints[21700] = 98500;
        _cachedDataPoints[21800] = 98537;
        _cachedDataPoints[21900] = 98574;
        _cachedDataPoints[22000] = 98610;
        _cachedDataPoints[22100] = 98645;
        _cachedDataPoints[22200] = 98679;
        _cachedDataPoints[22300] = 98713;
        _cachedDataPoints[22400] = 98745;
        _cachedDataPoints[22500] = 98778;
        _cachedDataPoints[22600] = 98809;
        _cachedDataPoints[22700] = 98840;
        _cachedDataPoints[22800] = 98870;
        _cachedDataPoints[22900] = 98899;
        _cachedDataPoints[23000] = 98928;
        _cachedDataPoints[23100] = 98956;
        _cachedDataPoints[23200] = 98983;
        _cachedDataPoints[23300] = 99010;
        _cachedDataPoints[23400] = 99036;
        _cachedDataPoints[23500] = 99061;
        _cachedDataPoints[23600] = 99086;
        _cachedDataPoints[23700] = 99111;
        _cachedDataPoints[23800] = 99134;
        _cachedDataPoints[23900] = 99158;
        _cachedDataPoints[24000] = 99180;
        _cachedDataPoints[24100] = 99202;
        _cachedDataPoints[24200] = 99224;
        _cachedDataPoints[24300] = 99245;
        _cachedDataPoints[24400] = 99266;
        _cachedDataPoints[24500] = 99286;
        _cachedDataPoints[24600] = 99305;
        _cachedDataPoints[24700] = 99324;
        _cachedDataPoints[24800] = 99343;
        _cachedDataPoints[24900] = 99361;
        _cachedDataPoints[25000] = 99379;
        _cachedDataPoints[25100] = 99396;
        _cachedDataPoints[25200] = 99413;
        _cachedDataPoints[25300] = 99430;
        _cachedDataPoints[25400] = 99446;
        _cachedDataPoints[25500] = 99461;
        _cachedDataPoints[25600] = 99477;
        _cachedDataPoints[25700] = 99492;
        _cachedDataPoints[25800] = 99506;
        _cachedDataPoints[25900] = 99520;
        _cachedDataPoints[26000] = 99534;
        _cachedDataPoints[26100] = 99547;
        _cachedDataPoints[26200] = 99560;
        _cachedDataPoints[26300] = 99573;
        _cachedDataPoints[26400] = 99585;
        _cachedDataPoints[26500] = 99598;
        _cachedDataPoints[26600] = 99609;
        _cachedDataPoints[26700] = 99621;
        _cachedDataPoints[26800] = 99632;
        _cachedDataPoints[26900] = 99643;
        _cachedDataPoints[27000] = 99653;
        _cachedDataPoints[27100] = 99664;
        _cachedDataPoints[27200] = 99674;
        _cachedDataPoints[27300] = 99683;
        _cachedDataPoints[27400] = 99693;
        _cachedDataPoints[27500] = 99702;
        _cachedDataPoints[27600] = 99711;
        _cachedDataPoints[27700] = 99720;
        _cachedDataPoints[27800] = 99728;
        _cachedDataPoints[27900] = 99736;
        _cachedDataPoints[28000] = 99744;
        _cachedDataPoints[28100] = 99752;
        _cachedDataPoints[28200] = 99760;
        _cachedDataPoints[28300] = 99767;
        _cachedDataPoints[28400] = 99774;
        _cachedDataPoints[28500] = 99781;
        _cachedDataPoints[28600] = 99788;
        _cachedDataPoints[28700] = 99795;
        _cachedDataPoints[28800] = 99801;
        _cachedDataPoints[28900] = 99807;
        _cachedDataPoints[29000] = 99813;
        _cachedDataPoints[29100] = 99819;
        _cachedDataPoints[29200] = 99825;
        _cachedDataPoints[29300] = 99831;
        _cachedDataPoints[29400] = 99836;
        _cachedDataPoints[29500] = 99841;
        _cachedDataPoints[29600] = 99846;
        _cachedDataPoints[29700] = 99851;
        _cachedDataPoints[29800] = 99856;
        _cachedDataPoints[29900] = 99861;
        _cachedDataPoints[30000] = 99865;
        _cachedDataPoints[30100] = 99869;
        _cachedDataPoints[30200] = 99874;
        _cachedDataPoints[30300] = 99878;
        _cachedDataPoints[30400] = 99882;
        _cachedDataPoints[30500] = 99886;
        _cachedDataPoints[30600] = 99889;
        _cachedDataPoints[30700] = 99893;
        _cachedDataPoints[30800] = 99896;
        _cachedDataPoints[30900] = 99900;
        _cachedDataPoints[31000] = 99903;
        _cachedDataPoints[31100] = 99906;
        _cachedDataPoints[31200] = 99910;
        _cachedDataPoints[31300] = 99913;
        _cachedDataPoints[31400] = 99916;
        _cachedDataPoints[31500] = 99918;
        _cachedDataPoints[31600] = 99921;
        _cachedDataPoints[31700] = 99924;
        _cachedDataPoints[31800] = 99926;
        _cachedDataPoints[31900] = 99929;
        _cachedDataPoints[32000] = 99931;
        _cachedDataPoints[32100] = 99934;
        _cachedDataPoints[32200] = 99936;
        _cachedDataPoints[32300] = 99938;
        _cachedDataPoints[32400] = 99940;
        _cachedDataPoints[32500] = 99942;
        _cachedDataPoints[32600] = 99944;
        _cachedDataPoints[32700] = 99946;
        _cachedDataPoints[32800] = 99948;
        _cachedDataPoints[32900] = 99950;
        _cachedDataPoints[33000] = 99952;
        _cachedDataPoints[33100] = 99953;
        _cachedDataPoints[33200] = 99955;
        _cachedDataPoints[33300] = 99957;
        _cachedDataPoints[33400] = 99958;
        _cachedDataPoints[33500] = 99960;
        _cachedDataPoints[33600] = 99961;
        _cachedDataPoints[33700] = 99962;
        _cachedDataPoints[33800] = 99964;
        _cachedDataPoints[33900] = 99965;
        _cachedDataPoints[34000] = 99966;
        _cachedDataPoints[34100] = 99968;
        _cachedDataPoints[34200] = 99969;
        _cachedDataPoints[34300] = 99970;
        _cachedDataPoints[34400] = 99971;
        _cachedDataPoints[34500] = 99972;
        _cachedDataPoints[34600] = 99973;
        _cachedDataPoints[34700] = 99974;
        _cachedDataPoints[34800] = 99975;
        _cachedDataPoints[34900] = 99976;
        _cachedDataPoints[35000] = 99977;
        _cachedDataPoints[35100] = 99978;
        _cachedDataPoints[35200] = 99978;
        _cachedDataPoints[35300] = 99979;
        _cachedDataPoints[35400] = 99980;
        _cachedDataPoints[35500] = 99981;
        _cachedDataPoints[35600] = 99981;
        _cachedDataPoints[35700] = 99982;
        _cachedDataPoints[35800] = 99983;
        _cachedDataPoints[35900] = 99983;
        _cachedDataPoints[36000] = 99984;
        _cachedDataPoints[36100] = 99985;
        _cachedDataPoints[36200] = 99985;
        _cachedDataPoints[36300] = 99986;
        _cachedDataPoints[36400] = 99986;
        _cachedDataPoints[36500] = 99987;
        _cachedDataPoints[36600] = 99987;
        _cachedDataPoints[36700] = 99988;
        _cachedDataPoints[36800] = 99988;
        _cachedDataPoints[36900] = 99989;
        _cachedDataPoints[37000] = 99989;
        _cachedDataPoints[37100] = 99990;
        _cachedDataPoints[37200] = 99990;
        _cachedDataPoints[37300] = 99990;
        _cachedDataPoints[37400] = 99991;
        _cachedDataPoints[37500] = 99991;
        _cachedDataPoints[37600] = 99992;
        _cachedDataPoints[37700] = 99992;
        _cachedDataPoints[37800] = 99992;
        _cachedDataPoints[37900] = 99992;
        _cachedDataPoints[38000] = 99993;
        _cachedDataPoints[38100] = 99993;
        _cachedDataPoints[38200] = 99993;
        _cachedDataPoints[38300] = 99994;
        _cachedDataPoints[38400] = 99994;
        _cachedDataPoints[38500] = 99994;
        _cachedDataPoints[38600] = 99994;
        _cachedDataPoints[38700] = 99995;
        _cachedDataPoints[38800] = 99995;
        _cachedDataPoints[38900] = 99995;
        _cachedDataPoints[39000] = 99995;
        _cachedDataPoints[39100] = 99995;
        _cachedDataPoints[39200] = 99996;
        _cachedDataPoints[39300] = 99996;
        _cachedDataPoints[39400] = 99996;
        _cachedDataPoints[39500] = 99996;
        _cachedDataPoints[39600] = 99996;
        _cachedDataPoints[39700] = 99996;
    }

    /**
     * @notice Returns probability approximations of Z in a normal distribution curve
     * @dev For performance, numbers are truncated to 2 decimals. Ex: 1134500000000000000(1.13) gets truncated to 113
     * @dev For Z > ±0.307 the curve response gets more concentrated, hence some predefined answers can be
     * given for a few sets of z. Otherwise it will calculate a median answer between the saved data points
     * @param z A point in the normal distribution
     * @param decimals Amount of decimals of z
     * @return The probability of a z variable in a normal distribution
     */
    function getProbability(int256 z, uint256 decimals) external override view returns (uint256) {
        require(decimals >= 5 && decimals < 77, "NormalDistribution: invalid decimals");
        uint256 absZ = _abs(z);
        uint256 truncatedZ = absZ.div(10**(decimals.sub(2))).mul(100);
        uint256 fourthDigit = absZ.div(10**(decimals.sub(3))) - absZ.div(10**(decimals.sub(2))).mul(10);
        uint256 responseDecimals = 10**(decimals.sub(5));
        uint256 responseValue;

        if (truncatedZ >= 41900) {
            // Over 4.18 the answer is rounded to 0.99999
            responseValue = 99999;
        } else if (truncatedZ >= 40600) {
            // Between 4.06 and 4.17 the answer is rounded to 0.99998
            responseValue = 99998;
        } else if (truncatedZ >= 39800) {
            // Between 3.98 and 4.05 the answer is rounded to 0.99997
            responseValue = 99997;
        } else if (fourthDigit >= 7) {
            // If the fourthDigit is 7, 8 or 9, rounds up to the next data point
            responseValue = _cachedDataPoints[truncatedZ + 100];
        } else if (fourthDigit >= 4) {
            // If the fourthDigit is 4, 5 or 6, get the average between the current and the next
            responseValue = _cachedDataPoints[truncatedZ].add(_cachedDataPoints[truncatedZ + 100]).div(2);
        } else {
            // If the fourthDigit is 0, 1, 2 or 3, rounds down to the current data point
            responseValue = _cachedDataPoints[truncatedZ];
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
        _cachedDataPoints[key] = value;
        emit DataPointSet(key, value);
    }

    /**
     * @dev Returns the absolute value of a number.
     */
    function _abs(int256 a) internal pure returns (uint256) {
        return a < 0 ? uint256(-a) : uint256(a);
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface INormalDistribution {
    function getProbability(int256 z, uint256 decimals) external view returns (uint256);

    function setDataPoint(uint256 key, uint256 value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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