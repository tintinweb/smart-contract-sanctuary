// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Forwarder {
    function forward(address payable _to) external payable {
        (bool sent, ) = _to.call{value: msg.value}(""); // solhint-disable-line avoid-low-level-calls
        require(sent, "Failed to send Ether");
    }
}