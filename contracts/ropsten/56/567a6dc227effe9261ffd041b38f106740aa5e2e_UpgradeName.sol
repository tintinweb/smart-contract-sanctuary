/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract UpgradeName {
    string myname = "Ermoshin Vladislav";
    
    function setName(string memory _newName) public {
       myname = _newName;
    }
    

    function getName() public view returns (string memory) {
        return myname;
    }
}