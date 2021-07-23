/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.8.0;

contract Newly {
    uint256 value;
    
    constructor() public {
        
    }
    
    function get() public view returns(uint256){
        return value;
    }
    
    function set(uint256 _value) public {
        value += _value;
    }
    
}