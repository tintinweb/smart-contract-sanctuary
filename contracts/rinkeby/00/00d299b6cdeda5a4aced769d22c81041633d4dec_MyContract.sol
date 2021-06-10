/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity *0.4.24;

contract MyContract {
    string value;
    uint age;
    
    constructor() public {
        value = "myValue";
    }
    
    function get() public view returns (string) {
        return value; 
    }
        
    function set(string _value, uint _age) public {
        value = _value;
        age = _age;
    }
}