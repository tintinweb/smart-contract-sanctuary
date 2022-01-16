/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
contract KillerCotract {
    constructor() payable{}

    function kill() external {
        selfdestruct (payable(msg.sender));
    }
    function Call () external pure returns (uint) {
        return 123;
    }

}