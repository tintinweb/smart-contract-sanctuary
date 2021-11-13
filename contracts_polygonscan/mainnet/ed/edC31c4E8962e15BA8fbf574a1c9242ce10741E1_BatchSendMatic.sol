// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract BatchSendMatic {
    function multisend(address payable[] calldata to, uint256[] calldata values)
        external
        payable
    {
        require(
            to.length == values.length,
            "To and values should have matching lengths"
        );
        uint256 total = 0;

        for (uint256 i = 0; i < to.length; i++) {
            require(values[i] > 0, "value must be positive");
            bool success = to[i].send(values[i]);
            require(success, "Transfer failed.");
            total += values[i];
        }
        require(total <= msg.value, "Invalid matic");
    }
}