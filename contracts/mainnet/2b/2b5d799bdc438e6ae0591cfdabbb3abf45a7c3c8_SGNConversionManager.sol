pragma solidity 0.4.25;

// File: contracts/saga-genesis/interfaces/ISGNConversionManager.sol

/**
 * @title SGN Conversion Manager Interface.
 */
interface ISGNConversionManager {
    /**
     * @dev Compute the SGR worth of a given SGN amount at a given minting-point.
     * @param _amount The amount of SGN.
     * @param _index The minting-point index.
     * @return The equivalent amount of SGR.
     */
    function sgn2sgr(uint256 _amount, uint256 _index) external view returns (uint256);
}

// File: contracts/saga-genesis/SGNConversionManager.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title SGN Conversion Manager.
 * @dev Calculate the conversion of SGN to SGR.
 * @notice Some of the code has been auto-generated via 'PrintSGNConversionManager.py',
 * in compliance with 'Sogur Monetary Model.pdf' / APPENDIX D: SOGUR MODEL POINTS.
 */
contract SGNConversionManager is ISGNConversionManager {
    string public constant VERSION = "1.1.0";

    uint256 public constant MAX_AMOUNT = 107000000e18;

    uint256 public constant DENOMINATOR = 1000000;

    uint256[95] public numerators;

    constructor() public {
        numerators[0] = 0;
        numerators[1] = 0;
        numerators[2] = 0;
        numerators[3] = 13514;
        numerators[4] = 13514;
        numerators[5] = 29794;
        numerators[6] = 60279;
        numerators[7] = 98386;
        numerators[8] = 155680;
        numerators[9] = 220880;
        numerators[10] = 297550;
        numerators[11] = 381820;
        numerators[12] = 475340;
        numerators[13] = 585540;
        numerators[14] = 594430;
        numerators[15] = 626090;
        numerators[16] = 626090;
        numerators[17] = 658600;
        numerators[18] = 658600;
        numerators[19] = 685580;
        numerators[20] = 716700;
        numerators[21] = 750640;
        numerators[22] = 752880;
        numerators[23] = 783970;
        numerators[24] = 819060;
        numerators[25] = 855700;
        numerators[26] = 855700;
        numerators[27] = 890860;
        numerators[28] = 894550;
        numerators[29] = 926680;
        numerators[30] = 963090;
        numerators[31] = 1000800;
        numerators[32] = 1039700;
        numerators[33] = 1079500;
        numerators[34] = 1120300;
        numerators[35] = 1162000;
        numerators[36] = 1162000;
        numerators[37] = 1204100;
        numerators[38] = 1244600;
        numerators[39] = 1285400;
        numerators[40] = 1327000;
        numerators[41] = 1411600;
        numerators[42] = 1493600;
        numerators[43] = 1622100;
        numerators[44] = 1763400;
        numerators[45] = 1911900;
        numerators[46] = 1983200;
        numerators[47] = 2041700;
        numerators[48] = 2099400;
        numerators[49] = 2158700;
        numerators[50] = 2219800;
        numerators[51] = 2283000;
        numerators[52] = 2348100;
        numerators[53] = 2415100;
        numerators[54] = 2484300;
        numerators[55] = 2555400;
        numerators[56] = 2628600;
        numerators[57] = 2703700;
        numerators[58] = 2780800;
        numerators[59] = 2859900;
        numerators[60] = 2859900;
        numerators[61] = 2940200;
        numerators[62] = 3023000;
        numerators[63] = 3107900;
        numerators[64] = 3194700;
        numerators[65] = 3283500;
        numerators[66] = 3374200;
        numerators[67] = 3466900;
        numerators[68] = 3561500;
        numerators[69] = 3658000;
        numerators[70] = 3756400;
        numerators[71] = 3856800;
        numerators[72] = 3959000;
        numerators[73] = 4063200;
        numerators[74] = 4253500;
        numerators[75] = 4468200;
        numerators[76] = 4693600;
        numerators[77] = 4837900;
        numerators[78] = 4967000;
        numerators[79] = 5096300;
        numerators[80] = 5228800;
        numerators[81] = 5365500;
        numerators[82] = 5506600;
        numerators[83] = 5653400;
        numerators[84] = 5653400;
        numerators[85] = 5803000;
        numerators[86] = 5958100;
        numerators[87] = 6118100;
        numerators[88] = 6282400;
        numerators[89] = 6451200;
        numerators[90] = 6623900;
        numerators[91] = 6800700;
        numerators[92] = 6981300;
        numerators[93] = 7057400;
        numerators[94] = 7057400;
    }

    /**
     * @dev Compute the amount of SGR received upon conversion of a given SGN amount at a given minting-point.
     * @param _amount The amount of SGN.
     * @param _index The minting-point index.
     * @return The amount of SGR received upon conversion.
     */
    function sgn2sgr(uint256 _amount, uint256 _index) external view returns (uint256) {
        assert(_amount <= MAX_AMOUNT);
        assert(_index < numerators.length);
        return _amount * numerators[_index] / DENOMINATOR;
    }
}