/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.4.24;

contract myScDemoOne {
    
    
    string value;
    
    constructor() public {
        value = "My Value";
    }
    
    function get() public view returns(string){
        return value;
    }
    
    function set(string _value) public {
        value = _value;
    }
}