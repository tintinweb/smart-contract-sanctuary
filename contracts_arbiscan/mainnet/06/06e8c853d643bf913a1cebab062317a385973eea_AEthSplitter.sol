/**
 *Submitted for verification at arbiscan.io on 2021-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

// Receives AETH and sends it to the given addresses
contract AEthSplitter {

    /// @notice accepts some amount of ETH, and splits it evenly amongst the given addresses
    /// @dev For simplicity the msg.value must be evenly divisible by the number of _addrs, or else it reverts
    function split(address[] calldata _addrs) external payable {
        require(msg.value > 0, "must send in non-zero amount of ETH");

        uint256 numAddrs = _addrs.length;
        uint256 ethAmountToSend = msg.value / _addrs.length;
        require(ethAmountToSend * numAddrs == msg.value, "msg.value must be evenly divisible by the number of input addresses");

        // disburse funds
        for (uint256 i = 0; i < numAddrs; i++) {
            (bool sent,) = payable(_addrs[i]).call{ value: ethAmountToSend }("");
            require(sent, "send failed :(");
        }
    }
}