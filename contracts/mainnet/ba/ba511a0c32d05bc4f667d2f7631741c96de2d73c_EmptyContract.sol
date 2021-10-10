/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract EmptyContract {
    function init() public {
        // this completely fixes overflow in treasury even before the protocol upgrade
	    // this must be locked, so that this contract can't suddenly be upgraded, and claim something maliciously
    }
}