/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ByteCode {

    string public myStateString = "Initial string. Carpe diem.";
    string public myStateString2 = "Initial string2. Carpe diem2.";
    
    event AndiEvent(string _andistring);
    
    function changeSting(string memory _newString, string memory _new2) public {
        myStateString = _newString;
        myStateString2 = _new2;
        emit AndiEvent("Andi string should be visible in logs.");
    }

}