/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

pragma solidity >=0.7.0 <0.9.0;

contract Helloworld {
    string _name;
    
    function setName(string memory name) public {
        _name = name;
    }
    
    function getName() public view returns (string memory) {
        return _name;
    }
}