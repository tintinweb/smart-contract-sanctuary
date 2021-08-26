/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity  ^0.6.0;

contract storageSomething {
    string public name; 
    function change(string memory _name) public {
        name = _name;
    }
    
}