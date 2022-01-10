/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Demand {

    event Success();

    function executeMe() public payable {
        require(msg.value == 1 ether);

        emit Success();
    }

}