// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleRewards {
    event ReceiverRefusedReward(address indexed);

    function distribute(address[] memory receivers, uint256[] memory values)
        public
        payable
        virtual
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            (bool success, ) = receivers[i].call{value: values[i], gas: 3000}(
                ""
            );
            if (!success) {
                emit ReceiverRefusedReward(receivers[i]);
            }
        }

        uint256 remaining = address(this).balance;
        if (remaining > 0) {
            (bool success, ) = msg.sender.call{value: remaining, gas: 3000}("");
            success; // prevent warnings without generaing bytecode
        }
    }
}