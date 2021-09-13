/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity >=0.7.0 <0.9.0;
contract Hello {
    string public name;
    
    function get() public view returns (string memory) {
        return name;
    }

    function setName(string memory _name) public {
        name = _name;
    }
    
   
    
    constructor() public {
        name = "i'm a smart contract";
    }
    
}