/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
// I love special numbers
pragma solidity ^0.8.7; 


contract theFourKeysGame{
    
    string[100] res;
    
    
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
      return address(iaddr);
    }

    
    constructor(){
        res[0] = "44ab999E3f";
		res[1] = "2F78fE411D";
		res[2] = "5f53F8F6Bf";
		res[3] = "1cD95F428B";
		res[4] = "Db6D476f58";
		res[5] = "dF12fcCCFc";
		res[6] = "b9f4f89718";
		res[7] = "fBfA9f3fC8";
		res[8] = "24D1a10DBB";
		res[9] = "af5D1Bb4Ec";
		res[10] = "A1D2A73860";
		res[11] = "c3bc78fB6D";
		res[12] = "a60d7a5BAb";
		res[13] = "e843E5DE4D";
		res[14] = "FD8630eb09";
		res[15] = "AFeEA070D0";
		res[16] = "c971821D1c";
		res[17] = "ecf382cB51";
		res[18] = "81a0a0495e";
		res[19] = "1d3e8f6E82";
		res[20] = "bbFdC5cF93";
		res[21] = "f36f11a11C";
		res[22] = "15D6A31DcE";
		res[23] = "9cD7731188";
		res[24] = "B6a50a8d7e";
		res[25] = "cC5Aab0Af8";
		res[26] = "E1eE02dEfC";
		res[27] = "F2c9b2FDf3";
		res[28] = "0A72fb0A41";
		res[29] = "2Be7AD099f";
		res[30] = "d84eA20548";
		res[31] = "EA83b6b1C5";
		res[32] = "b9bbdfA91B";
		res[33] = "a4574A00b9";
		res[34] = "0C48673Bbe";
		res[35] = "c3390CF0A9";
		res[36] = "FF041F3DCE";
		res[37] = "55FFC5B4c9";
		res[38] = "C8be489c5c";
		res[39] = "Ec8E500De3";
		res[40] = "5ED7D34dEb";
		res[41] = "8925254bAc";
		res[42] = "785fff347C";
		res[43] = "280BB9cD4c";
		res[44] = "4DFFaC078A";
		res[45] = "9dF6BA73bF";
		res[46] = "A37CdC40b6";
		res[47] = "0c7b4C1A84";
		res[48] = "CbB8De9B2F";
		res[49] = "fF8EE0C7e9";
		res[50] = "De366ccBC9";
		res[51] = "Ec1fed5648";
		res[52] = "02fE034Db0";
		res[53] = "827f6996D8";
		res[54] = "FaAC9C5B3c";
		res[55] = "fbeE2c355a";
		res[56] = "AfA2a0e2C1";
		res[57] = "408fBEb799";
		res[58] = "A40caa4F1f";
		res[59] = "eE20D5F8Ba";
		res[60] = "44F64A06DB";
		res[61] = "beCf6dBEEA";
		res[62] = "6FAFA038d8";
		res[63] = "d6BBBEcD6E";
		res[64] = "8d6E97e6b1";
		res[65] = "513C639F6C";
		res[66] = "DF3bF5D4d9";
		res[67] = "bc8CE7bBA7";
		res[68] = "cFBf598fD0";
		res[69] = "26FFd95d50";
		res[70] = "51e1E0473b";
		res[71] = "771FECeBed";
		res[72] = "CAafa0E77a";
		res[73] = "4Ad417426f";
		res[74] = "4Cd291f89b";
		res[75] = "d05AE4085C";
		res[76] = "f12Ec7ad82";
		res[77] = "b3e24bd2BE";
		res[78] = "18CA635EeF";
		res[79] = "C9B0bFAe39";
		res[80] = "F0E9b5a9A5";
		res[81] = "381A1d1678";
		res[82] = "2a1390dF65";
		res[83] = "E2Cc5F1A21";
		res[84] = "eb7Ec9EfDe";
		res[85] = "8A7568b75F";
		res[86] = "664F9bc701";
		res[87] = "41e058AC3b";
		res[88] = "2df4B3e4cE";
		res[89] = "Bd760550d6";
		res[90] = "CDcC6adf1b";
		res[91] = "669F546b04";
		res[92] = "aC12AdC9e5";
		res[93] = "81EDF9FCFF";
		res[94] = "95E740a0cD";
		res[95] = "98feae1ea7";
		res[96] = "66fb5C0431";
		res[97] = "FCa88cbcde";
		res[98] = "56694edd44";
		res[99] = "FFAec521DB";

    }
    
    modifier onlyValidNumbers(uint key1, uint key2, uint key3, uint key4){
        require(key1 < 100 && key1 < 100 && key3 < 100 && key4 < 100, "Invalid key provided");
        require(key1 >= 0 && key2 >= 0 && key3 >= 0 && key4 >= 0, "Invalid key provided");
        _;
    }
    
    function getFirstKey() public pure returns (string memory){
        return "I'm a perfect number";
    }
    
    function getSecondKey() public pure returns (string memory){
        return "I'm friendly.. and I love 140!";
    }
    
    function getThirdKey() public pure returns (string memory){
        return "I'm Sphenic and 7 is part of that list";
    }
    
    function getfourthKey() public pure returns (string memory){
        return "I'm a Marsenne prime that has more than two digits";
    }
    
    
    function getNextSmartContractAddress(uint key1, uint key2, uint key3, uint key4) onlyValidNumbers(key1,key2,key3,key4) public view returns(address){
        string memory a = string(abi.encodePacked("0x",res[key1], res[key2], res[key3], res[key4]));
        return parseAddr(a);
    }
}