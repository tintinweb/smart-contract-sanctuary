/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-16
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

contract Contract {
    int uuint = 1;
    string sttr = "1";

    function funme(int oi, string memory aa) external {
        uuint = oi;
        sttr = aa;
    }

    function setValue(string memory aa) external {
        sttr = aa;
    }
}