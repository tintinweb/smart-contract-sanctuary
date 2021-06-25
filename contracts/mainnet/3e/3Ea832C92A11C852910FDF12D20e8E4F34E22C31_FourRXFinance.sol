/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: contracts/InterestCalculator.sol


pragma solidity ^0.6.12;


contract InterestCalculator {
    using SafeMath for uint;
    uint private constant MAX_DAYS = 365;

    function _initCumulativeInterestForDays() internal pure returns(uint[] memory) {
        uint[] memory cumulativeInterestForDays = new uint[](MAX_DAYS.add(1));

        cumulativeInterestForDays[0] = 0;
        cumulativeInterestForDays[1] = 1;
        cumulativeInterestForDays[2] = 2;
        cumulativeInterestForDays[3] = 3;
        cumulativeInterestForDays[4] = 4;
        cumulativeInterestForDays[5] = 6;
        cumulativeInterestForDays[6] = 8;
        cumulativeInterestForDays[7] = 11;
        cumulativeInterestForDays[8] = 14;
        cumulativeInterestForDays[9] = 17;
        cumulativeInterestForDays[10] = 21;
        cumulativeInterestForDays[11] = 25;
        cumulativeInterestForDays[12] = 30;
        cumulativeInterestForDays[13] = 35;
        cumulativeInterestForDays[14] = 40;
        cumulativeInterestForDays[15] = 46;
        cumulativeInterestForDays[16] = 52;
        cumulativeInterestForDays[17] = 58;
        cumulativeInterestForDays[18] = 65;
        cumulativeInterestForDays[19] = 72;
        cumulativeInterestForDays[20] = 80;
        cumulativeInterestForDays[21] = 88;
        cumulativeInterestForDays[22] = 96;
        cumulativeInterestForDays[23] = 105;
        cumulativeInterestForDays[24] = 114;
        cumulativeInterestForDays[25] = 124;
        cumulativeInterestForDays[26] = 134;
        cumulativeInterestForDays[27] = 144;
        cumulativeInterestForDays[28] = 155;
        cumulativeInterestForDays[29] = 166;
        cumulativeInterestForDays[30] = 178;
        cumulativeInterestForDays[31] = 190;
        cumulativeInterestForDays[32] = 202;
        cumulativeInterestForDays[33] = 215;
        cumulativeInterestForDays[34] = 228;
        cumulativeInterestForDays[35] = 242;
        cumulativeInterestForDays[36] = 256;
        cumulativeInterestForDays[37] = 271;
        cumulativeInterestForDays[38] = 286;
        cumulativeInterestForDays[39] = 301;
        cumulativeInterestForDays[40] = 317;
        cumulativeInterestForDays[41] = 333;
        cumulativeInterestForDays[42] = 350;
        cumulativeInterestForDays[43] = 367;
        cumulativeInterestForDays[44] = 385;
        cumulativeInterestForDays[45] = 403;
        cumulativeInterestForDays[46] = 421;
        cumulativeInterestForDays[47] = 440;
        cumulativeInterestForDays[48] = 459;
        cumulativeInterestForDays[49] = 479;
        cumulativeInterestForDays[50] = 499;
        cumulativeInterestForDays[51] = 520;
        cumulativeInterestForDays[52] = 541;
        cumulativeInterestForDays[53] = 563;
        cumulativeInterestForDays[54] = 585;
        cumulativeInterestForDays[55] = 607;
        cumulativeInterestForDays[56] = 630;
        cumulativeInterestForDays[57] = 653;
        cumulativeInterestForDays[58] = 677;
        cumulativeInterestForDays[59] = 701;
        cumulativeInterestForDays[60] = 726;
        cumulativeInterestForDays[61] = 751;
        cumulativeInterestForDays[62] = 777;
        cumulativeInterestForDays[63] = 803;
        cumulativeInterestForDays[64] = 830;
        cumulativeInterestForDays[65] = 857;
        cumulativeInterestForDays[66] = 884;
        cumulativeInterestForDays[67] = 912;
        cumulativeInterestForDays[68] = 940;
        cumulativeInterestForDays[69] = 969;
        cumulativeInterestForDays[70] = 998;
        cumulativeInterestForDays[71] = 1028;
        cumulativeInterestForDays[72] = 1058;
        cumulativeInterestForDays[73] = 1089;
        cumulativeInterestForDays[74] = 1120;
        cumulativeInterestForDays[75] = 1152;
        cumulativeInterestForDays[76] = 1184;
        cumulativeInterestForDays[77] = 1217;
        cumulativeInterestForDays[78] = 1250;
        cumulativeInterestForDays[79] = 1284;
        cumulativeInterestForDays[80] = 1318;
        cumulativeInterestForDays[81] = 1353;
        cumulativeInterestForDays[82] = 1388;
        cumulativeInterestForDays[83] = 1424;
        cumulativeInterestForDays[84] = 1460;
        cumulativeInterestForDays[85] = 1497;
        cumulativeInterestForDays[86] = 1534;
        cumulativeInterestForDays[87] = 1572;
        cumulativeInterestForDays[88] = 1610;
        cumulativeInterestForDays[89] = 1649;
        cumulativeInterestForDays[90] = 1688;
        cumulativeInterestForDays[91] = 1728;
        cumulativeInterestForDays[92] = 1768;
        cumulativeInterestForDays[93] = 1809;
        cumulativeInterestForDays[94] = 1850;
        cumulativeInterestForDays[95] = 1892;
        cumulativeInterestForDays[96] = 1934;
        cumulativeInterestForDays[97] = 1977;
        cumulativeInterestForDays[98] = 2020;
        cumulativeInterestForDays[99] = 2064;
        cumulativeInterestForDays[100] = 2108;
        cumulativeInterestForDays[101] = 2153;
        cumulativeInterestForDays[102] = 2199;
        cumulativeInterestForDays[103] = 2245;
        cumulativeInterestForDays[104] = 2292;
        cumulativeInterestForDays[105] = 2339;
        cumulativeInterestForDays[106] = 2387;
        cumulativeInterestForDays[107] = 2435;
        cumulativeInterestForDays[108] = 2484;
        cumulativeInterestForDays[109] = 2533;
        cumulativeInterestForDays[110] = 2583;
        cumulativeInterestForDays[111] = 2633;
        cumulativeInterestForDays[112] = 2684;
        cumulativeInterestForDays[113] = 2736;
        cumulativeInterestForDays[114] = 2788;
        cumulativeInterestForDays[115] = 2841;
        cumulativeInterestForDays[116] = 2894;
        cumulativeInterestForDays[117] = 2948;
        cumulativeInterestForDays[118] = 3002;
        cumulativeInterestForDays[119] = 3057;
        cumulativeInterestForDays[120] = 3113;
        cumulativeInterestForDays[121] = 3169;
        cumulativeInterestForDays[122] = 3226;
        cumulativeInterestForDays[123] = 3283;
        cumulativeInterestForDays[124] = 3341;
        cumulativeInterestForDays[125] = 3399;
        cumulativeInterestForDays[126] = 3458;
        cumulativeInterestForDays[127] = 3518;
        cumulativeInterestForDays[128] = 3578;
        cumulativeInterestForDays[129] = 3639;
        cumulativeInterestForDays[130] = 3700;
        cumulativeInterestForDays[131] = 3762;
        cumulativeInterestForDays[132] = 3825;
        cumulativeInterestForDays[133] = 3888;
        cumulativeInterestForDays[134] = 3952;
        cumulativeInterestForDays[135] = 4016;
        cumulativeInterestForDays[136] = 4081;
        cumulativeInterestForDays[137] = 4147;
        cumulativeInterestForDays[138] = 4213;
        cumulativeInterestForDays[139] = 4280;
        cumulativeInterestForDays[140] = 4347;
        cumulativeInterestForDays[141] = 4415;
        cumulativeInterestForDays[142] = 4484;
        cumulativeInterestForDays[143] = 4553;
        cumulativeInterestForDays[144] = 4623;
        cumulativeInterestForDays[145] = 4694;
        cumulativeInterestForDays[146] = 4765;
        cumulativeInterestForDays[147] = 4837;
        cumulativeInterestForDays[148] = 4909;
        cumulativeInterestForDays[149] = 4982;
        cumulativeInterestForDays[150] = 5056;
        cumulativeInterestForDays[151] = 5130;
        cumulativeInterestForDays[152] = 5205;
        cumulativeInterestForDays[153] = 5281;
        cumulativeInterestForDays[154] = 5357;
        cumulativeInterestForDays[155] = 5434;
        cumulativeInterestForDays[156] = 5512;
        cumulativeInterestForDays[157] = 5590;
        cumulativeInterestForDays[158] = 5669;
        cumulativeInterestForDays[159] = 5749;
        cumulativeInterestForDays[160] = 5829;
        cumulativeInterestForDays[161] = 5910;
        cumulativeInterestForDays[162] = 5992;
        cumulativeInterestForDays[163] = 6074;
        cumulativeInterestForDays[164] = 6157;
        cumulativeInterestForDays[165] = 6241;
        cumulativeInterestForDays[166] = 6325;
        cumulativeInterestForDays[167] = 6410;
        cumulativeInterestForDays[168] = 6496;
        cumulativeInterestForDays[169] = 6582;
        cumulativeInterestForDays[170] = 6669;
        cumulativeInterestForDays[171] = 6757;
        cumulativeInterestForDays[172] = 6845;
        cumulativeInterestForDays[173] = 6934;
        cumulativeInterestForDays[174] = 7024;
        cumulativeInterestForDays[175] = 7114;
        cumulativeInterestForDays[176] = 7205;
        cumulativeInterestForDays[177] = 7297;
        cumulativeInterestForDays[178] = 7390;
        cumulativeInterestForDays[179] = 7483;
        cumulativeInterestForDays[180] = 7577;
        cumulativeInterestForDays[181] = 7672;
        cumulativeInterestForDays[182] = 7767;
        cumulativeInterestForDays[183] = 7863;
        cumulativeInterestForDays[184] = 7960;
        cumulativeInterestForDays[185] = 8058;
        cumulativeInterestForDays[186] = 8156;
        cumulativeInterestForDays[187] = 8255;
        cumulativeInterestForDays[188] = 8355;
        cumulativeInterestForDays[189] = 8455;
        cumulativeInterestForDays[190] = 8556;
        cumulativeInterestForDays[191] = 8658;
        cumulativeInterestForDays[192] = 8761;
        cumulativeInterestForDays[193] = 8864;
        cumulativeInterestForDays[194] = 8968;
        cumulativeInterestForDays[195] = 9073;
        cumulativeInterestForDays[196] = 9179;
        cumulativeInterestForDays[197] = 9285;
        cumulativeInterestForDays[198] = 9392;
        cumulativeInterestForDays[199] = 9500;
        cumulativeInterestForDays[200] = 9609;
        cumulativeInterestForDays[201] = 9719;
        cumulativeInterestForDays[202] = 9829;
        cumulativeInterestForDays[203] = 9940;
        cumulativeInterestForDays[204] = 10052;
        cumulativeInterestForDays[205] = 10165;
        cumulativeInterestForDays[206] = 10278;
        cumulativeInterestForDays[207] = 10392;
        cumulativeInterestForDays[208] = 10507;
        cumulativeInterestForDays[209] = 10623;
        cumulativeInterestForDays[210] = 10740;
        cumulativeInterestForDays[211] = 10857;
        cumulativeInterestForDays[212] = 10975;
        cumulativeInterestForDays[213] = 11094;
        cumulativeInterestForDays[214] = 11214;
        cumulativeInterestForDays[215] = 11335;
        cumulativeInterestForDays[216] = 11456;
        cumulativeInterestForDays[217] = 11578;
        cumulativeInterestForDays[218] = 11701;
        cumulativeInterestForDays[219] = 11825;
        cumulativeInterestForDays[220] = 11950;
        cumulativeInterestForDays[221] = 12076;
        cumulativeInterestForDays[222] = 12202;
        cumulativeInterestForDays[223] = 12329;
        cumulativeInterestForDays[224] = 12457;
        cumulativeInterestForDays[225] = 12586;
        cumulativeInterestForDays[226] = 12716;
        cumulativeInterestForDays[227] = 12847;
        cumulativeInterestForDays[228] = 12978;
        cumulativeInterestForDays[229] = 13110;
        cumulativeInterestForDays[230] = 13243;
        cumulativeInterestForDays[231] = 13377;
        cumulativeInterestForDays[232] = 13512;
        cumulativeInterestForDays[233] = 13648;
        cumulativeInterestForDays[234] = 13785;
        cumulativeInterestForDays[235] = 13922;
        cumulativeInterestForDays[236] = 14060;
        cumulativeInterestForDays[237] = 14199;
        cumulativeInterestForDays[238] = 14339;
        cumulativeInterestForDays[239] = 14480;
        cumulativeInterestForDays[240] = 14622;
        cumulativeInterestForDays[241] = 14765;
        cumulativeInterestForDays[242] = 14909;
        cumulativeInterestForDays[243] = 15054;
        cumulativeInterestForDays[244] = 15199;
        cumulativeInterestForDays[245] = 15345;
        cumulativeInterestForDays[246] = 15492;
        cumulativeInterestForDays[247] = 15640;
        cumulativeInterestForDays[248] = 15789;
        cumulativeInterestForDays[249] = 15939;
        cumulativeInterestForDays[250] = 16090;
        cumulativeInterestForDays[251] = 16242;
        cumulativeInterestForDays[252] = 16395;
        cumulativeInterestForDays[253] = 16549;
        cumulativeInterestForDays[254] = 16704;
        cumulativeInterestForDays[255] = 16860;
        cumulativeInterestForDays[256] = 17017;
        cumulativeInterestForDays[257] = 17174;
        cumulativeInterestForDays[258] = 17332;
        cumulativeInterestForDays[259] = 17491;
        cumulativeInterestForDays[260] = 17651;
        cumulativeInterestForDays[261] = 17812;
        cumulativeInterestForDays[262] = 17974;
        cumulativeInterestForDays[263] = 18137;
        cumulativeInterestForDays[264] = 18301;
        cumulativeInterestForDays[265] = 18466;
        cumulativeInterestForDays[266] = 18632;
        cumulativeInterestForDays[267] = 18799;
        cumulativeInterestForDays[268] = 18967;
        cumulativeInterestForDays[269] = 19136;
        cumulativeInterestForDays[270] = 19306;
        cumulativeInterestForDays[271] = 19477;
        cumulativeInterestForDays[272] = 19649;
        cumulativeInterestForDays[273] = 19822;
        cumulativeInterestForDays[274] = 19996;
        cumulativeInterestForDays[275] = 20171;
        cumulativeInterestForDays[276] = 20347;
        cumulativeInterestForDays[277] = 20524;
        cumulativeInterestForDays[278] = 20702;
        cumulativeInterestForDays[279] = 20881;
        cumulativeInterestForDays[280] = 21061;
        cumulativeInterestForDays[281] = 21242;
        cumulativeInterestForDays[282] = 21424;
        cumulativeInterestForDays[283] = 21607;
        cumulativeInterestForDays[284] = 21791;
        cumulativeInterestForDays[285] = 21976;
        cumulativeInterestForDays[286] = 22162;
        cumulativeInterestForDays[287] = 22350;
        cumulativeInterestForDays[288] = 22539;
        cumulativeInterestForDays[289] = 22729;
        cumulativeInterestForDays[290] = 22920;
        cumulativeInterestForDays[291] = 23112;
        cumulativeInterestForDays[292] = 23305;
        cumulativeInterestForDays[293] = 23499;
        cumulativeInterestForDays[294] = 23694;
        cumulativeInterestForDays[295] = 23890;
        cumulativeInterestForDays[296] = 24087;
        cumulativeInterestForDays[297] = 24285;
        cumulativeInterestForDays[298] = 24484;
        cumulativeInterestForDays[299] = 24685;
        cumulativeInterestForDays[300] = 24887;
        cumulativeInterestForDays[301] = 25090;
        cumulativeInterestForDays[302] = 25294;
        cumulativeInterestForDays[303] = 25499;
        cumulativeInterestForDays[304] = 25705;
        cumulativeInterestForDays[305] = 25912;
        cumulativeInterestForDays[306] = 26120;
        cumulativeInterestForDays[307] = 26330;
        cumulativeInterestForDays[308] = 26541;
        cumulativeInterestForDays[309] = 26753;
        cumulativeInterestForDays[310] = 26966;
        cumulativeInterestForDays[311] = 27180;
        cumulativeInterestForDays[312] = 27395;
        cumulativeInterestForDays[313] = 27611;
        cumulativeInterestForDays[314] = 27829;
        cumulativeInterestForDays[315] = 28048;
        cumulativeInterestForDays[316] = 28268;
        cumulativeInterestForDays[317] = 28489;
        cumulativeInterestForDays[318] = 28711;
        cumulativeInterestForDays[319] = 28934;
        cumulativeInterestForDays[320] = 29159;
        cumulativeInterestForDays[321] = 29385;
        cumulativeInterestForDays[322] = 29612;
        cumulativeInterestForDays[323] = 29840;
        cumulativeInterestForDays[324] = 30069;
        cumulativeInterestForDays[325] = 30300;
        cumulativeInterestForDays[326] = 30532;
        cumulativeInterestForDays[327] = 30765;
        cumulativeInterestForDays[328] = 30999;
        cumulativeInterestForDays[329] = 31235;
        cumulativeInterestForDays[330] = 31472;
        cumulativeInterestForDays[331] = 31710;
        cumulativeInterestForDays[332] = 31949;
        cumulativeInterestForDays[333] = 32190;
        cumulativeInterestForDays[334] = 32432;
        cumulativeInterestForDays[335] = 32675;
        cumulativeInterestForDays[336] = 32919;
        cumulativeInterestForDays[337] = 33165;
        cumulativeInterestForDays[338] = 33412;
        cumulativeInterestForDays[339] = 33660;
        cumulativeInterestForDays[340] = 33909;
        cumulativeInterestForDays[341] = 34160;
        cumulativeInterestForDays[342] = 34412;
        cumulativeInterestForDays[343] = 34665;
        cumulativeInterestForDays[344] = 34920;
        cumulativeInterestForDays[345] = 35176;
        cumulativeInterestForDays[346] = 35433;
        cumulativeInterestForDays[347] = 35692;
        cumulativeInterestForDays[348] = 35952;
        cumulativeInterestForDays[349] = 36213;
        cumulativeInterestForDays[350] = 36476;
        cumulativeInterestForDays[351] = 36740;
        cumulativeInterestForDays[352] = 37005;
        cumulativeInterestForDays[353] = 37272;
        cumulativeInterestForDays[354] = 37540;
        cumulativeInterestForDays[355] = 37809;
        cumulativeInterestForDays[356] = 38080;
        cumulativeInterestForDays[357] = 38352;
        cumulativeInterestForDays[358] = 38625;
        cumulativeInterestForDays[359] = 38900;
        cumulativeInterestForDays[360] = 39176;
        cumulativeInterestForDays[361] = 39454;
        cumulativeInterestForDays[362] = 39733;
        cumulativeInterestForDays[363] = 40013;
        cumulativeInterestForDays[364] = 40295;
        cumulativeInterestForDays[365] = 40578;

        return cumulativeInterestForDays;
    }

    function _getInterestTillDays(uint _day) internal pure returns(uint) {
        require(_day <= MAX_DAYS);

        return _initCumulativeInterestForDays()[_day];
    }
}

// File: contracts/Events.sol


pragma solidity ^0.6.12;


contract Events {
    event Deposit(address user, uint amount, uint8 stakeId, address uplinkAddress, uint uplinkStakeId);
    event Withdrawn(address user, uint amount);
    event ReInvest(address user, uint amount);
    event Exited(address user, uint stakeId, uint amount);
    event PoolDrawn(uint refPoolAmount, uint sponsorPoolAmount);
}

// File: contracts/PercentageCalculator.sol


pragma solidity ^0.6.12;



contract PercentageCalculator {
    using SafeMath for uint;

    uint public constant PERCENT_MULTIPLIER = 10000;

    function _calcPercentage(uint amount, uint basisPoints) internal pure returns (uint) {
        require(basisPoints >= 0);
        return amount.mul(basisPoints).div(PERCENT_MULTIPLIER);
    }

    function _calcBasisPoints(uint base, uint interest) internal pure returns (uint) {
        return interest.mul(PERCENT_MULTIPLIER).div(base);
    }
}

// File: contracts/utils/Utils.sol


pragma solidity ^0.6.12;



contract Utils {
    using SafeMath for uint;

    uint public constant DAY = 86400; // Seconds in a day

    function _calcDays(uint start, uint end) internal pure returns (uint) {
        return end.sub(start).div(DAY);
    }
}

// File: contracts/Constants.sol


pragma solidity ^0.6.12;


contract Constants {
    uint public constant MAX_CONTRACT_REWARD_BP = 37455; // 374.55%

    uint public constant LP_FEE_BP = 500; // 5%
    uint public constant REF_COMMISSION_BP = 800; // 8%

    // Ref and sponsor pools
    uint public constant REF_POOL_FEE_BP = 50; // 0.5%, goes to ref pool from each deposit
    uint public constant SPONSOR_POOL_FEE_BP = 50; // 0.5%, goes to sponsor pool from each deposit

    uint public constant EXIT_PENALTY_BP = 5000; // 50%, deduct from user's initial deposit on exit

    // Contract bonus
    uint public constant MAX_CONTRACT_BONUS_BP = 300; // maximum bonus a user can get 3%
    uint public constant CONTRACT_BONUS_UNIT = 250;    // For each 250 token balance of contract, gives
    uint public constant CONTRACT_BONUS_PER_UNIT_BP = 1; // 0.01% extra interest

    // Hold bonus
    uint public constant MAX_HOLD_BONUS_BP = 100; // Maximum 1% hold bonus
    uint public constant HOLD_BONUS_UNIT = 43200; // 12 hours
    uint public constant HOLD_BONUS_PER_UNIT_BP = 2; // 0.02% hold bonus for each 12 hours of hold

    uint public constant REWARD_THRESHOLD_BP = 300; // User will only get hold bonus if his rewards are more then 3% of his deposit

    uint public constant MAX_WITHDRAWAL_OVER_REWARD_THRESHOLD_BP = 300; // Max daily withdrawal limit if user is above REWARD_THRESHOLD_BP

    uint public constant DEV_FEE_BP = 500; // 5%
}

// File: contracts/StatsVars.sol


pragma solidity ^0.6.12;


contract StatsVars {
    // Stats
    uint public totalDepositRewards;
    uint public totalExited;
}

// File: contracts/SharedVariables.sol


pragma solidity ^0.6.12;









contract SharedVariables is Constants, StatsVars, Events, PercentageCalculator, InterestCalculator, Utils {

    uint public constant fourRXTokenDecimals = 8;
    IERC20 public fourRXToken;
    address public devAddress;

    struct Stake {
        uint8 id;
        bool active;
        bool optInInsured; // Is insured ???

        uint32 holdFrom; // Timestamp from which hold should be counted
        uint32 interestCountFrom; // TimeStamp from which interest should be counted, from the beginning
        uint32 lastWithdrawalAt; // date time of last withdrawals so we don't allow more then 3% a day

        uint origDeposit;
        uint deposit; // Initial Deposit
        uint withdrawn; // Total withdrawn from this stake
        uint penalty; // Total penalty on this stale

        uint rewards;
    }

    struct User {
        address wallet; // Wallet Address
        Stake[] stakes;
    }

    mapping (address => User) public users;

    uint[] public refPoolBonuses;
    uint[] public sponsorPoolBonuses;

    uint public maxContractBalance;

    uint16 public poolCycle;
    uint32 public poolDrewAt;

    uint public refPoolBalance;
    uint public sponsorPoolBalance;

    uint public devBalance;
}

// File: contracts/libs/SortedLinkedList.sol


pragma solidity ^0.6.12;



library SortedLinkedList {
    using SafeMath for uint;

    struct Item {
        address user;
        uint16 next;
        uint8 id;
        uint score;
    }

    uint16 internal constant GUARD = 0;

    function addNode(Item[] storage items, address user, uint score, uint8 id) internal {
        uint16 prev = findSortedIndex(items, score);
        require(_verifyIndex(items, score, prev));
        items.push(Item(user, items[prev].next, id, score));
        items[prev].next = uint16(items.length.sub(1));
    }

    function updateNode(Item[] storage items, address user, uint score, uint8 id) internal {
        (uint16 current, uint16 oldPrev) = findCurrentAndPrevIndex(items, user, id);
        require(items[oldPrev].next == current);
        require(items[current].user == user);
        require(items[current].id == id);
        score = score.add(items[current].score);
        items[oldPrev].next = items[current].next;
        addNode(items, user, score, id);
    }

    function initNodes(Item[] storage items) internal {
        items.push(Item(address(0), 0, 0, 0));
    }

    function _verifyIndex(Item[] storage items, uint score, uint16 prev) internal view returns (bool) {
        return prev == GUARD || (score <= items[prev].score && score > items[items[prev].next].score);
    }

    function findSortedIndex(Item[] storage items, uint score) internal view returns(uint16) {
        Item memory current = items[GUARD];
        uint16 index = GUARD;
        while(current.next != GUARD && items[current.next].score >= score) {
            index = current.next;
            current = items[current.next];
        }

        return index;
    }

    function findCurrentAndPrevIndex(Item[] storage items, address user, uint8 id) internal view returns (uint16, uint16) {
        Item memory current = items[GUARD];
        uint16 currentIndex = GUARD;
        uint16 prevIndex = GUARD;
        while(current.next != GUARD && !(current.user == user && current.id == id)) {
            prevIndex = currentIndex;
            currentIndex = current.next;
            current = items[current.next];
        }

        return (currentIndex, prevIndex);
    }

    function isInList(Item[] storage items, address user, uint8 id) internal view returns (bool) {
        Item memory current = items[GUARD];
        bool exists = false;

        while(current.next != GUARD ) {
            if (current.user == user && current.id == id) {
                exists = true;
                break;
            }
            current = items[current.next];
        }

        return exists;
    }
}

// File: contracts/Pools/SponsorPool.sol


pragma solidity ^0.6.12;


contract SponsorPool {
    SortedLinkedList.Item[] public sponsorPoolUsers;

    function _addSponsorPoolRecord(address user, uint amount, uint8 stakeId) internal {
        SortedLinkedList.addNode(sponsorPoolUsers, user, amount, stakeId);
    }

    function _cleanSponsorPoolUsers() internal {
        delete sponsorPoolUsers;
        SortedLinkedList.initNodes(sponsorPoolUsers);
    }
}

// File: contracts/Pools/ReferralPool.sol


pragma solidity ^0.6.12;



contract ReferralPool {

    SortedLinkedList.Item[] public refPoolUsers;

    function _addReferralPoolRecord(address user, uint amount, uint8 stakeId) internal {
        if (!SortedLinkedList.isInList(refPoolUsers, user, stakeId)) {
            SortedLinkedList.addNode(refPoolUsers, user, amount, stakeId);
        } else {
            SortedLinkedList.updateNode(refPoolUsers, user, amount, stakeId);
        }
    }

    function _cleanReferralPoolUsers() internal {
        delete refPoolUsers;
        SortedLinkedList.initNodes(refPoolUsers);
    }
}

// File: contracts/Pools.sol


pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;






contract Pools is SponsorPool, ReferralPool, SharedVariables {

    uint8 public constant MAX_REF_POOL_USERS = 12;
    uint8 public constant MAX_SPONSOR_POOL_USERS = 10;

    function _resetPools() internal {
        _cleanSponsorPoolUsers();
        _cleanReferralPoolUsers();
        delete refPoolBalance;
        delete sponsorPoolBalance;
        poolDrewAt = uint32(block.timestamp);
        poolCycle++;
    }

    function _updateSponsorPoolUsers(User memory user, Stake memory stake) internal {
        _addSponsorPoolRecord(user.wallet, stake.deposit, stake.id);
    }

    // Reorganise top ref-pool users to draw pool for
    function _updateRefPoolUsers(User memory uplinkUser , Stake memory stake, uint8 uplinkUserStakeId) internal {
        _addReferralPoolRecord(uplinkUser.wallet, stake.deposit, uplinkUserStakeId);
    }

    function drawPool() public {
        if (block.timestamp > poolDrewAt + 1 days) {

            SortedLinkedList.Item memory current = refPoolUsers[0];
            uint16 i = 0;

            while (i < MAX_REF_POOL_USERS && current.next != SortedLinkedList.GUARD) {
                current = refPoolUsers[current.next];
                users[current.user].stakes[current.id].rewards = users[current.user].stakes[current.id].rewards.add(_calcPercentage(refPoolBalance, refPoolBonuses[i]));
                i++;
            }

            current = sponsorPoolUsers[0];
            i = 0;

            while (i < MAX_SPONSOR_POOL_USERS && current.next != SortedLinkedList.GUARD) {
                current = sponsorPoolUsers[current.next];
                users[current.user].stakes[current.id].rewards = users[current.user].stakes[current.id].rewards.add(_calcPercentage(sponsorPoolBalance, sponsorPoolBonuses[i]));
                i++;
            }

            emit PoolDrawn(refPoolBalance, sponsorPoolBalance);

            _resetPools();
        }
    }

    // pool info getters

    function getPoolInfo() external view returns (uint32, uint16, uint, uint) {
        return (poolDrewAt, poolCycle, sponsorPoolBalance, refPoolBalance);
    }

    function getPoolParticipants() external view returns (address[] memory, uint8[] memory, uint[] memory, address[] memory, uint8[] memory, uint[] memory) {
        address[] memory sponsorPoolUsersAddresses = new address[](MAX_SPONSOR_POOL_USERS);
        uint8[] memory sponsorPoolUsersStakeIds = new uint8[](MAX_SPONSOR_POOL_USERS);
        uint[] memory sponsorPoolUsersAmounts = new uint[](MAX_SPONSOR_POOL_USERS);

        address[] memory refPoolUsersAddresses = new address[](MAX_REF_POOL_USERS);
        uint8[] memory refPoolUsersStakeIds = new uint8[](MAX_REF_POOL_USERS);
        uint[] memory refPoolUsersAmounts = new uint[](MAX_REF_POOL_USERS);

        uint16 i = 0;
        SortedLinkedList.Item memory current = sponsorPoolUsers[i];

        while (i < MAX_SPONSOR_POOL_USERS && current.next != SortedLinkedList.GUARD) {
            current = sponsorPoolUsers[current.next];
            sponsorPoolUsersAddresses[i] = current.user;
            sponsorPoolUsersStakeIds[i] = current.id;
            sponsorPoolUsersAmounts[i] = current.score;
            i++;
        }

        i = 0;
        current = refPoolUsers[i];

        while (i < MAX_REF_POOL_USERS && current.next != SortedLinkedList.GUARD) {
            current = refPoolUsers[current.next];
            refPoolUsersAddresses[i] = current.user;
            refPoolUsersStakeIds[i] = current.id;
            refPoolUsersAmounts[i] = current.score;
            i++;
        }

        return (sponsorPoolUsersAddresses, sponsorPoolUsersStakeIds, sponsorPoolUsersAmounts, refPoolUsersAddresses, refPoolUsersStakeIds, refPoolUsersAmounts);
    }
}

// File: contracts/RewardsAndPenalties.sol


pragma solidity ^0.6.12;




contract RewardsAndPenalties is Pools {
    using SafeMath for uint;

    function _distributeReferralReward(uint amount, Stake memory stake, address uplinkAddress, uint8 uplinkStakeId) internal {
        User storage uplinkUser = users[uplinkAddress];

        uint commission = _calcPercentage(amount, REF_COMMISSION_BP);

        uplinkUser.stakes[uplinkStakeId].rewards = uplinkUser.stakes[uplinkStakeId].rewards.add(commission);

        _updateRefPoolUsers(uplinkUser, stake, uplinkStakeId);
    }

    function _calcDepositRewards(uint amount) internal pure returns (uint) {
        uint rewardPercent = 0;

        if (amount > 175 * (10**fourRXTokenDecimals)) {
            rewardPercent = 50; // 0.5%
        } else if (amount > 150 * (10**fourRXTokenDecimals)) {
            rewardPercent = 40; // 0.4%
        } else if (amount > 135 * (10**fourRXTokenDecimals)) {
            rewardPercent = 35; // 0.35%
        } else if (amount > 119 * (10**fourRXTokenDecimals)) {
            rewardPercent = 30; // 0.3%
        } else if (amount > 100 * (10**fourRXTokenDecimals)) {
            rewardPercent = 25; // 0.25%
        } else if (amount > 89 * (10**fourRXTokenDecimals)) {
            rewardPercent = 20; // 0.2%
        } else if (amount > 75 * (10**fourRXTokenDecimals)) {
            rewardPercent = 15; // 0.15%
        } else if (amount > 59 * (10**fourRXTokenDecimals)) {
            rewardPercent = 10; // 0.1%
        } else if (amount > 45 * (10**fourRXTokenDecimals)) {
            rewardPercent = 5; // 0.05%
        } else if (amount > 20 * (10**fourRXTokenDecimals)) {
            rewardPercent = 2; // 0.02%
        } else if (amount > 9 * (10**fourRXTokenDecimals)) {
            rewardPercent = 1; // 0.01%
        }

        return _calcPercentage(amount, rewardPercent);
    }

    function _calcContractBonus(Stake memory stake) internal view returns (uint) {
        uint contractBonusPercent = fourRXToken.balanceOf(address(this)).mul(CONTRACT_BONUS_PER_UNIT_BP).div(CONTRACT_BONUS_UNIT).div(10**fourRXTokenDecimals);

        if (contractBonusPercent > MAX_CONTRACT_BONUS_BP) {
            contractBonusPercent = MAX_CONTRACT_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, contractBonusPercent);
    }

    function _calcHoldRewards(Stake memory stake) internal view returns (uint) {
        uint holdBonusPercent = (block.timestamp).sub(stake.holdFrom).div(HOLD_BONUS_UNIT).mul(HOLD_BONUS_PER_UNIT_BP);

        if (holdBonusPercent > MAX_HOLD_BONUS_BP) {
            holdBonusPercent = MAX_HOLD_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, holdBonusPercent);
    }

    function _calcRewardsWithoutHoldBonus(Stake memory stake) internal view returns (uint) {
        uint interest = _calcPercentage(stake.deposit, _getInterestTillDays(_calcDays(stake.interestCountFrom, block.timestamp)));

        uint contractBonus = _calcContractBonus(stake);

        uint totalRewardsWithoutHoldBonus = stake.rewards.add(interest).add(contractBonus);

        return totalRewardsWithoutHoldBonus;
    }

    function _calcRewards(Stake memory stake) internal view returns (uint) {
        uint rewards = _calcRewardsWithoutHoldBonus(stake);

        if (_calcBasisPoints(stake.deposit, rewards) >= REWARD_THRESHOLD_BP) {
            rewards = rewards.add(_calcHoldRewards(stake));
        }

        uint maxRewards = _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP);

        if (rewards > maxRewards) {
            rewards = maxRewards;
        }

        return rewards;
    }

    function _calcPenalty(Stake memory stake, uint withdrawalAmount) internal pure returns (uint) {
        uint basisPoints = _calcBasisPoints(stake.deposit, withdrawalAmount);
        // If user's rewards are more then REWARD_THRESHOLD_BP -- No penalty
        if (basisPoints >= REWARD_THRESHOLD_BP) {
            return 0;
        }

        return _calcPercentage(withdrawalAmount, PERCENT_MULTIPLIER.sub(basisPoints.mul(PERCENT_MULTIPLIER).div(REWARD_THRESHOLD_BP)));
    }
}

// File: contracts/Insurance.sol


pragma solidity ^0.6.12;



contract Insurance is RewardsAndPenalties {
    uint private constant BASE_INSURANCE_FOR_BP = 3500; // trigger insurance with contract balance fall below 35%
    uint private constant OPT_IN_INSURANCE_FEE_BP = 1000; // 10%
    uint private constant OPT_IN_INSURANCE_FOR_BP = 10000; // 100%

    bool public isInInsuranceState = false; // if contract is only allowing insured money this becomes true;

    function _checkForBaseInsuranceTrigger() internal {
        if (fourRXToken.balanceOf(address(this)) <= _calcPercentage(maxContractBalance, BASE_INSURANCE_FOR_BP)) {
            isInInsuranceState = true;
        } else {
            isInInsuranceState = false;
        }
    }

    function _getInsuredAvailableAmount(Stake memory stake, uint withdrawalAmount) internal pure returns (uint)
    {
        uint availableAmount = withdrawalAmount;
        // Calc correct insured value by checking which insurance should be applied
        uint insuredFor = BASE_INSURANCE_FOR_BP;
        if (stake.optInInsured) {
            insuredFor = OPT_IN_INSURANCE_FOR_BP;
        }

        uint maxWithdrawalAllowed = _calcPercentage(stake.deposit, insuredFor);

        require(maxWithdrawalAllowed >= stake.withdrawn.add(stake.penalty)); // if contract is in insurance trigger, do not allow withdrawals for the users who already have withdrawn more then 35%

        if (stake.withdrawn.add(availableAmount).add(stake.penalty) > maxWithdrawalAllowed) {
            availableAmount = maxWithdrawalAllowed.sub(stake.withdrawn).sub(stake.penalty);
        }

        return availableAmount;
    }

    function _insureStake(address user, Stake storage stake) internal {
        require(!stake.optInInsured && stake.active);
        require(fourRXToken.transferFrom(user, address(this), _calcPercentage(stake.deposit, OPT_IN_INSURANCE_FEE_BP)));

        stake.optInInsured = true;
    }
}

// File: contracts/FourRXFinance.sol


pragma solidity ^0.6.12;



/// @title 4RX Finance Staking DAPP Contract
/// @notice Available functionality: Deposit, Withdraw, ExitProgram, Insure Stake
contract FourRXFinance is Insurance {

    constructor(address _devAddress, address fourRXTokenAddress) public {
        devAddress = _devAddress;
        fourRXToken = IERC20(fourRXTokenAddress);

        // Ref Bonus // 12 Max Participants
        refPoolBonuses.push(2000); // 20%
        refPoolBonuses.push(1700); // 17%
        refPoolBonuses.push(1400); // 14%
        refPoolBonuses.push(1100); // 11%
        refPoolBonuses.push(1000); // 10%
        refPoolBonuses.push(700); // 7%
        refPoolBonuses.push(600); // 6%
        refPoolBonuses.push(500); // 5%
        refPoolBonuses.push(400); // 4%
        refPoolBonuses.push(300); // 3%
        refPoolBonuses.push(200); // 2%
        refPoolBonuses.push(100); // 1%

        // Sponsor Pool // 10 Max Participants
        sponsorPoolBonuses.push(3000); // 30%
        sponsorPoolBonuses.push(2000); // 20%
        sponsorPoolBonuses.push(1200); // 12%
        sponsorPoolBonuses.push(1000); // 10%
        sponsorPoolBonuses.push(800); // 8%
        sponsorPoolBonuses.push(700); // 7%
        sponsorPoolBonuses.push(600); // 6%
        sponsorPoolBonuses.push(400); // 4%
        sponsorPoolBonuses.push(200); // 2%
        sponsorPoolBonuses.push(100); // 1%

        _resetPools();

        poolCycle = 0;
    }

    function deposit(uint amount, address uplinkAddress, uint8 uplinkStakeId) external {
        require(
            uplinkAddress == address(0) ||
            (users[uplinkAddress].wallet != address(0) && users[uplinkAddress].stakes[uplinkStakeId].active)
        ); // Either uplink must be registered and be a active deposit or 0 address

        User storage user = users[msg.sender];

        if (users[msg.sender].stakes.length > 0) {
            require(amount >= users[msg.sender].stakes[user.stakes.length - 1].deposit.mul(2)); // deposit amount must be greater 2x then last deposit
        }

        require(fourRXToken.transferFrom(msg.sender, address(this), amount));

        drawPool(); // Draw old pool if qualified, and we're pretty sure that this stake is going to be created

        uint depositReward = _calcDepositRewards(amount);

        Stake memory stake;

        user.wallet = msg.sender;

        stake.id = uint8(user.stakes.length);
        stake.active = true;
        stake.interestCountFrom = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.origDeposit = amount;
        stake.deposit = amount.sub(_calcPercentage(amount, LP_FEE_BP)); // Deduct LP Commission
        stake.rewards = depositReward;

        _updateSponsorPoolUsers(user, stake);

        if (uplinkAddress != address(0)) {
            _distributeReferralReward(amount, stake, uplinkAddress, uplinkStakeId);
        }

        user.stakes.push(stake);

        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, REF_POOL_FEE_BP));

        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, SPONSOR_POOL_FEE_BP));

        devBalance = devBalance.add(_calcPercentage(amount, DEV_FEE_BP));

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

        totalDepositRewards = totalDepositRewards.add(depositReward);

        emit Deposit(msg.sender, amount, stake.id,  uplinkAddress, uplinkStakeId);
    }


    function balanceOf(address _userAddress, uint stakeId) public view returns (uint) {
        require(users[_userAddress].wallet == _userAddress);
        User memory user = users[_userAddress];

        return _calcRewards(user.stakes[stakeId]).sub(user.stakes[stakeId].withdrawn);
    }

    function withdraw(uint stakeId) external {
        User storage user = users[msg.sender];
        Stake storage stake = user.stakes[stakeId];
        require(user.wallet == msg.sender && stake.active); // stake should be active

        require(stake.lastWithdrawalAt + 1 days < block.timestamp); // we only allow one withdrawal each day

        uint availableAmount = _calcRewards(stake).sub(stake.withdrawn).sub(stake.penalty);

        require(availableAmount > 0);

        uint penalty = _calcPenalty(stake, availableAmount);

        if (penalty == 0) {
            availableAmount = availableAmount.sub(_calcPercentage(stake.deposit, REWARD_THRESHOLD_BP)); // Only allow withdrawal if available is more then 10% of base

            uint maxAllowedWithdrawal = _calcPercentage(stake.deposit, MAX_WITHDRAWAL_OVER_REWARD_THRESHOLD_BP);

            if (availableAmount > maxAllowedWithdrawal) {
                availableAmount = maxAllowedWithdrawal;
            }
        }

        if (isInInsuranceState) {
            availableAmount = _getInsuredAvailableAmount(stake, availableAmount);
        }

        availableAmount = availableAmount.sub(penalty);

        stake.withdrawn = stake.withdrawn.add(availableAmount);
        stake.lastWithdrawalAt = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.penalty = stake.penalty.add(penalty);

        if (stake.withdrawn >= _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP)) {
            stake.active = false; // if stake has withdrawn equals to or more then the max amount, then mark stake in-active
        }

        _checkForBaseInsuranceTrigger();

        fourRXToken.transfer(user.wallet, availableAmount);

        emit Withdrawn(user.wallet, availableAmount);
    }

    function exitProgram(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        Stake storage stake = user.stakes[stakeId];
        require(stake.active);
        uint penaltyAmount = _calcPercentage(stake.origDeposit, EXIT_PENALTY_BP);
        uint balance = balanceOf(msg.sender, stakeId);

        uint availableAmount = stake.origDeposit + balance - penaltyAmount; // (deposit + (rewards - withdrawn) - penalty)

        if (availableAmount > 0) {
            fourRXToken.transfer(user.wallet, availableAmount);
            stake.withdrawn = stake.withdrawn.add(availableAmount);
        }

        stake.active = false;
        stake.penalty = stake.penalty.add(penaltyAmount);

        totalExited = totalExited.add(1);

        emit Exited(user.wallet, stakeId, availableAmount > 0 ? availableAmount : 0);
    }

    function insureStake(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        Stake storage stake = user.stakes[stakeId];
        _insureStake(user.wallet, stake);
    }

    // Getters

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }

    function getContractInfo() external view returns (uint, bool, uint, uint) {
        return (maxContractBalance, isInInsuranceState, totalDepositRewards, totalExited);
    }

    function withdrawDevFee(address withdrawingAddress, uint amount) external {
        require(msg.sender == devAddress);
        require(amount <= devBalance);
        devBalance = devBalance.sub(amount);
        fourRXToken.transfer(withdrawingAddress, amount);
    }

    function updateDevAddress(address newDevAddress) external {
        require(msg.sender == devAddress);
        devAddress = newDevAddress;
    }
}