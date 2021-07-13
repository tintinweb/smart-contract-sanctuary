// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "realLibrary.sol";
 
contract Greeter {
    using realLibrary for string;

    string public name;

    constructor() public {
        name = 'Hel';
    }
          
    function setName(string memory _name) public {    
        name = _name.setName(); 
             
    }  


    function getName() view public returns (string memory) {
        return name;
    
    }

}