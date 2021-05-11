/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//yeong hae
pragma solidity 0.8.0;

contract Likelion_9 {
    bytes32 hash;
    
    function makePassword() public{
        uint a = 0;
        uint b = 4;
        uint c = 2;
        uint d = 9;
        hash = keccak256(abi.encodePacked(a, b, c, d));
    }
    
    function lookOfPassword() public view returns(uint, uint) {
        uint a = 0;
        uint b = 4;
        
        for(uint c = 0; c < 10; c++) {
            for(uint d = 0; d < 10; d++) {
                bytes32 password = keccak256(abi.encodePacked(a, b, c, d));
                if(password == hash) {
                    return(c, d);
                }
            }
        }
        return(404, 404);
    }
}