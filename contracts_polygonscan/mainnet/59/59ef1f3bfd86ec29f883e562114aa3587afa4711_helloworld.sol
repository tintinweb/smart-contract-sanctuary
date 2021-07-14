/**
 *Submitted for verification at polygonscan.com on 2021-07-14
*/

pragma solidity ^0.5.17;
contract helloworld {
    string public name;
    
    constructor() public {
        name = "Hello World!";
    }
    
    function setName(string memory _name) public {
        name = _name;
    }
}