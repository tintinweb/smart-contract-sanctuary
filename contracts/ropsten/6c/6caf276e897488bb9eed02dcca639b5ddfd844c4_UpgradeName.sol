/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract UpgradeName {
    string myname = "Ermoshin Vladislav";
    
    function setName(string memory _newName) external {
       myname = _newName;
    }
    
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function getName() public view returns (string memory) {
        return append("Hi, ", myname);
    }
}