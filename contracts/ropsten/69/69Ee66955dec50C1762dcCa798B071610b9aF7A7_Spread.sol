/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Spread {

    function send (address[] memory _addresses) external payable {
        uint256 amtPerAddr = msg.value / _addresses.length;
        
        for (uint i = 0; i < _addresses.length; i++) {
            (bool success, ) = _addresses[i].call{value: amtPerAddr}("");
            require(success, "Reverted");
        }

        if (msg.value % _addresses.length > 0) {
            (bool success, ) = msg.sender.call{value: msg.value % _addresses.length}("");
            require(success, "Reverted");
        }
    }

}