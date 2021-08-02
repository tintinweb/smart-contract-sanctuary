/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract Log {
    
    string Clue1 = "Log is very pog you know";

    function Clue() public view returns (string memory) {return Clue1;}
    
        uint256 number;

    function setanswer(uint256 num) public {number = num;}

    function getanswer() public view returns (uint256){return number;}
    
}