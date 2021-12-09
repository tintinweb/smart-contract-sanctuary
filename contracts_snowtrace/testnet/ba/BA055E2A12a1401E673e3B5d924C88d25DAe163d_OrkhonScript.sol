/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

contract OrkhonScript {
    string public myOrkhonName = "";


    function setYourName(string memory _myOrkhonName) public {
        myOrkhonName = _myOrkhonName;
    }
}