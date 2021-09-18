/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Register{
    string private Username;
    bytes32[] public FaceTraits;
    string private password; 
    
    /*
    constructor() public {
        
        StoreInfo("test",[""] , "test3");
    }*/
    
    function StoreInfo(string memory uname, string[1] memory fts, string memory pwd) public{
        Username = uname;
         for(uint i = 0; i < fts.length; i++) {
            FaceTraits[i]= stringToBytes32(fts[i]);

        }
        password = pwd;
    }
    
    function GetInfo(uint i) public view returns (bytes32){
        return FaceTraits[i];
    }
    
    function stringToBytes32(string memory source) pure public  returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}