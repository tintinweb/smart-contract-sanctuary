/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//Younwoo Noh

pragma solidity 0.8.0;

contract Likelion_6_1 {
     string[] ID;
     string[] PW;

    function pushInformationDB(string memory _ID, string memory _PW) public {
        ID.push(_ID);
        PW.push(_PW);
    }
    function getID(uint i) public view returns(string memory) {
        return ID[i];
    }
    function pushInformation(string memory _ID, string memory _PW) public view returns (string memory) {
        for(uint i=0; i<PW.length; i++) {
            if(keccak256(bytes(PW[i]))!=keccak256(bytes(PW[i]))) {
                return "Error";
            }
        }
    }
}