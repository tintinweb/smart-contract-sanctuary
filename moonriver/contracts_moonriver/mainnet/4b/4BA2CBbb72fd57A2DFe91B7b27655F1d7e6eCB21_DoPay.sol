/**
 *Submitted for verification at moonriver.moonscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract DoPay {
    function destruct(address payable _to) external {
        selfdestruct(_to);
    }

    receive() external payable{

    }
}