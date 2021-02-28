/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.1;
contract ross {
    string public said; // latest thing ross said on ethereum
    function say(string calldata thing) external {
        require(msg.sender == 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20, "!ross");
        said = thing;
    }
}