/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;



// File: BetTenGetHalf.sol

contract BetTenGetHalf {
    uint256 public constant BET_AMOUNT = 10*17;
    uint256 public pile;

    constructor(){

    }

    function bet() payable external {
        require(msg.value == BET_AMOUNT);
        pile += msg.value;
        //TODO process user request
    }

    function fulfillRandomness(uint256 r) public {
        //TODO do the bet and send wins to users
    }
}