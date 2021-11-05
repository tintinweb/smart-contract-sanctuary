/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract Test {
    
    string private name = "Ire";

    function getName() public view returns (string memory)
    {
        return name;
    }

    function setName(string memory _name) public
    {
        name = _name;
    }
    
}