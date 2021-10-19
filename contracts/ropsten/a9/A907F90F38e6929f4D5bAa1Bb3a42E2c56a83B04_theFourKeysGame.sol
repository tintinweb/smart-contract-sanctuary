/**
 *Submitted for verification at Etherscan.io on 2021-10-19
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
 		res[0] = "97355FcDB1";
		res[1] = "33cCd7035A";
		res[2] = "bA6156c18D";
		res[3] = "EF939CE6Cd";
		res[4] = "FeDdaCdbCa";
		res[5] = "EDe59a2F4F";
		res[6] = "fE05BA1eD5";
		res[7] = "7308ca8fe4";
		res[8] = "1b08dEC1DE";
		res[9] = "DCecad55AF";
		res[10] = "EaB7BAf519";
		res[11] = "3DD3CEc5EA";
		res[12] = "FB98caAc01";
		res[13] = "6AD17afC4A";
		res[14] = "E4Cab11BF0";
		res[15] = "b313e302aD";
		res[16] = "E4aAF3fBEE";
		res[17] = "fAeae942fa";
		res[18] = "B16D02AfBE";
		res[19] = "8E8258910b";
		res[20] = "eC250a525B";
		res[21] = "1b7ebbE11f";
		res[22] = "1AA7b5dBcd";
		res[23] = "aac5aC368F";
		res[24] = "b5ede1F6C3";
		res[25] = "eD7Ff9Fa62";
		res[26] = "35a273EAde";
		res[27] = "Ed18FFbb73";
		res[28] = "e8F2355a32";
		res[29] = "9Bc82dD9DC";
		res[30] = "e6f4E0918e";
		res[31] = "8A37d8c71A";
		res[32] = "30E85aAe25";
		res[33] = "D4375aA5Ac";
		res[34] = "8ee7Fc7A3A";
		res[35] = "D5b7dd1Fe0";
		res[36] = "f2f08D6A39";
		res[37] = "adcCF50cEF";
		res[38] = "8AC57CBcBe";
		res[39] = "a32eBD02FA";
		res[40] = "9eDa4229cb";
		res[41] = "fCF29c078f";
		res[42] = "07E37eE3Dc";
		res[43] = "911eCEcCf2";
		res[44] = "79e9c681B0";
		res[45] = "4C59daB13b";
		res[46] = "5BaA1E7cfd";
		res[47] = "99fAA2eA39";
		res[48] = "5FD005bcef";
		res[49] = "A9be4Ad43D";
		res[50] = "74f67A5449";
		res[51] = "F15D3CfbF3";
		res[52] = "fA2BdfBCDb";
		res[53] = "FDA418aDBd";
		res[54] = "aCaE7D444C";
		res[55] = "Ce06cCb0F0";
		res[56] = "bC839dBD4e";
		res[57] = "E55F9aC59f";
		res[58] = "Ec7b8Dc318";
		res[59] = "DCb15C1d15";
		res[60] = "A12bB2c31E";
		res[61] = "8b891bcBFd";
		res[62] = "756FddddAD";
		res[63] = "6B7cFE5907";
		res[64] = "B4DB9fAE74";
		res[65] = "eF805cD9df";
		res[66] = "27f7D1d0cE";
		res[67] = "D0BFBD4f73";
		res[68] = "fbdc261D1C";
		res[69] = "5dc2AB4d2f";
		res[70] = "9863C976a4";
		res[71] = "4cd08BF9C6";
		res[72] = "784f4477d7";
		res[73] = "fa288ccDCA";
		res[74] = "9Cb16806ac";
		res[75] = "fa5aEdEbFD";
		res[76] = "F44Efb44b7";
		res[77] = "E0DF465fee";
		res[78] = "ed09D7da14";
		res[79] = "d61F7d5b9f";
		res[80] = "Dd24AA595b";
		res[81] = "Ac8ecF0fd5";
		res[82] = "bfeCeDe4A1";
		res[83] = "cFb1745372";
		res[84] = "1CB87cC456";
		res[85] = "Aac85dfBdc";
		res[86] = "d8e01F5957";
		res[87] = "D659D3dB9E";
		res[88] = "FCDA0ab778";
		res[89] = "17DaB53E83";
		res[90] = "cd1adBc6C2";
		res[91] = "D22CA4C5bd";
		res[92] = "B5A7bD20cF";
		res[93] = "AB4E71d69D";
		res[94] = "cc1021B65c";
		res[95] = "AabB8B6d8a";
		res[96] = "d848fBF94A";
		res[97] = "b00E50DEF5";
		res[98] = "Af0dDB9350";
		res[99] = "352dc8c5c9";



    }
    
    fallback() external payable{
        // empty
    }
    receive() external payable{
        //empty
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
        return "I'm a Marsenne prime that has more than a single digit";
    }
    
    
    function getNextSmartContractAddress(uint key1, uint key2, uint key3, uint key4) onlyValidNumbers(key1,key2,key3,key4) public view returns(address){
        string memory a = string(abi.encodePacked("0x",res[key1], res[key2], res[key3], res[key4]));
        return parseAddr(a);
    }
}