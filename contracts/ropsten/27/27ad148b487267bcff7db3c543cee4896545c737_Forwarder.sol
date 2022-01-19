/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier: None

pragma solidity 0.8.11;

contract Forwarder {
    address payable[] private _forwardTo;

    constructor(address payable[] memory forwardTo) {
        _forwardTo = forwardTo;
    }

    receive() external payable {
        uint256 amt = msg.value / _forwardTo.length;
        for (uint i=0; i<_forwardTo.length; i++) {
            _forwardTo[i].transfer(amt);
        }
    }
}