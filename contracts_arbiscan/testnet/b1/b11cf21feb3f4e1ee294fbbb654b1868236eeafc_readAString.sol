/**
 *Submitted for verification at arbiscan.io on 2021-10-06
*/

pragma solidity ^0.7.0;


contract readAString {
    
    string public a = "show me a string";
    bytes32 public b = 0x4a06276b8fe44173f03422331069528608b909bdcc8339f2d31e5f90d95afe92;
    
    function storeSomething(string memory _a) public view returns (string memory) {
        if (keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(a))) {
            return a;   
        } else {
            return "Nothing to show"; 
        }
    }
    
    function storeSomething(uint256 _b) public view returns (bytes32) {
        if (_b == 1) {
            return b;   
        } else {
            return 0x0;
        }
    }
}