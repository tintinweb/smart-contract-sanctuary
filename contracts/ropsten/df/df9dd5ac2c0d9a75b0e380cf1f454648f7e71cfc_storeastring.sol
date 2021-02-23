/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity ^0.5.0;


contract storeastring {
    
    string public a;
    bytes32 public b;
    
    function storeSomething(string memory _a) public {
        a = _a;
    }
    
    function storeSomething(bytes32 _b) public {
        b = _b;
    }
}