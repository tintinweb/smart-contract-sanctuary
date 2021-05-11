/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.8.0;

contract AdditionContract333 {
    
    bytes32[] public _a;
    
    function Addition(uint a, uint b) public view returns (uint) {
        return (a + b);
    }
    
    function showMeSomeBytes() public view returns (bytes32[] memory) {
        return _a;
    }
    
    function addBytes(bytes32 pampit) public {
        _a.push(pampit);
    }
}