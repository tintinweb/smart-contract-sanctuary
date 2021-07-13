/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract Register {
        string private info;
    
        function setInfo(string memory _info) public {
            info = _info;
        }
    
        function getInfo() public view returns (string memory) {
            return info;
        }
}