/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity >=0.4.0 <0.6.0;

contract SimpleStorage {
    
    constructor() public {
        storedData = 987;
    }
    
    function getResult() public view returns(uint) {
        uint a = 3;
        uint b = 2;
        uint result = a + b;
        return result;
    }
    
    
    uint storedData;
    
    function set(uint x) public {
        storedData = x;
    }
    
    function get() public view returns (uint) {
        return storedData;
    }
}