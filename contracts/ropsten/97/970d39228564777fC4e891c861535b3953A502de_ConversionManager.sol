pragma solidity 0.4.24;

interface IConversionManager {
    function sgn2sga(uint256 amount, uint256 index) external view returns (uint256);
}

/**
 * @title Conversion Manager.
 * @dev Calculate the conversion of SGN to SGA.
 */
contract ConversionManager is IConversionManager {
    uint256[105] public numerators;
    uint256 public constant DENOMINATOR = 1000000;

    constructor() public {
        numerators[  0] =        0;
        numerators[  1] =        0;
        numerators[  2] =     2500;
        numerators[  3] =    22650;
        numerators[  4] =    22650;
        numerators[  5] =    63504;
        numerators[  6] =   125680;
        numerators[  7] =   125680;
        numerators[  8] =   209810;
        numerators[  9] =   316560;
        numerators[ 10] =   446570;
        numerators[ 11] =   600530;
        numerators[ 12] =   779120;
        numerators[ 13] =   983070;
        numerators[ 14] =   983070;
        numerators[ 15] =  1213000;
        numerators[ 16] =  1213000;
        numerators[ 17] =  1267300;
        numerators[ 18] =  1324800;
        numerators[ 19] =  1385500;
        numerators[ 20] =  1449200;
        numerators[ 21] =  1515900;
        numerators[ 22] =  1585500;
        numerators[ 23] =  1657900;
        numerators[ 24] =  1733000;
        numerators[ 25] =  1810800;
        numerators[ 26] =  1810800;
        numerators[ 27] =  1884500;
        numerators[ 28] =  1960500;
        numerators[ 29] =  2038700;
        numerators[ 30] =  2119000;
        numerators[ 31] =  2201400;
        numerators[ 32] =  2285900;
        numerators[ 33] =  2372400;
        numerators[ 34] =  2460900;
        numerators[ 35] =  2551400;
        numerators[ 36] =  2551400;
        numerators[ 37] =  2636300;
        numerators[ 38] =  2722900;
        numerators[ 39] =  2811200;
        numerators[ 40] =  2901100;
        numerators[ 41] =  2992700;
        numerators[ 42] =  3085900;
        numerators[ 43] =  3180700;
        numerators[ 44] =  3277100;
        numerators[ 45] =  3375000;
        numerators[ 46] =  3474500;
        numerators[ 47] =  3575500;
        numerators[ 48] =  3678100;
        numerators[ 49] =  3782200;
        numerators[ 50] =  3887800;
        numerators[ 51] =  3994800;
        numerators[ 52] =  4103300;
        numerators[ 53] =  4216300;
        numerators[ 54] =  4333800;
        numerators[ 55] =  4455700;
        numerators[ 56] =  4581900;
        numerators[ 57] =  4712400;
        numerators[ 58] =  4847200;
        numerators[ 59] =  4986200;
        numerators[ 60] =  5129400;
        numerators[ 61] =  5276800;
        numerators[ 62] =  5428400;
        numerators[ 63] =  5584200;
        numerators[ 64] =  5744100;
        numerators[ 65] =  5908300;
        numerators[ 66] =  6076700;
        numerators[ 67] =  6076700;
        numerators[ 68] =  6249300;
        numerators[ 69] =  6426100;
        numerators[ 70] =  6607100;
        numerators[ 71] =  6792300;
        numerators[ 72] =  6981600;
        numerators[ 73] =  7175100;
        numerators[ 74] =  7372700;
        numerators[ 75] =  7574500;
        numerators[ 76] =  7780400;
        numerators[ 77] =  7990400;
        numerators[ 78] =  8204500;
        numerators[ 79] =  8422700;
        numerators[ 80] =  8645000;
        numerators[ 81] =  8871400;
        numerators[ 82] =  9101900;
        numerators[ 83] =  9336500;
        numerators[ 84] =  9575200;
        numerators[ 85] =  9818000;
        numerators[ 86] = 10064000;
        numerators[ 87] = 10320000;
        numerators[ 88] = 10585000;
        numerators[ 89] = 10860000;
        numerators[ 90] = 11144000;
        numerators[ 91] = 11438000;
        numerators[ 92] = 11742000;
        numerators[ 93] = 12056000;
        numerators[ 94] = 12380000;
        numerators[ 95] = 12380000;
        numerators[ 96] = 12714000;
        numerators[ 97] = 13058000;
        numerators[ 98] = 13411000;
        numerators[ 99] = 13774000;
        numerators[100] = 14145000;
        numerators[101] = 14525000;
        numerators[102] = 14913000;
        numerators[103] = 15000000;
        numerators[104] = 15000000;
    }

    /**
     * @dev Convert SGN to SGA at a given minting-point.
     * @param amount The amount of SGN.
     * @param index The minting-point index.
     * @return The amount of SGA.
     */
    function sgn2sga(uint256 amount, uint256 index) external view returns (uint256) {
        return amount * numerators[index] / DENOMINATOR;
    }
}