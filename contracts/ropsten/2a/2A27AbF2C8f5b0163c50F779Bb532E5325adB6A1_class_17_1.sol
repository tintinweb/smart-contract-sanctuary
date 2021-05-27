/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity 0.8.0;

contract class_17_1 {
    
    function ambiguity() public pure returns (bool) {
        
        return (keccak256(abi.encodePacked("aa", "b")) == keccak256(abi.encodePacked("a", "ab")));
        
    }
    
}