// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleEthTransporter {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transportTo(address _toAddress, uint256 _tip) public payable {
        // Keep all msg.value as tip.
        if (_toAddress == address(0) || _toAddress == address(this)) {
            return;
        }

        // Contract keeps msg.value as tip if value is less than tip.
        if (msg.value <= _tip) {
            return;
        }

        // Contract keeps tip.
        uint256 amountToTransfer = msg.value - _tip;

        (bool success, ) = _toAddress.call{value: amountToTransfer}("");
        require(success, "Failed to send Ether.");
    }

    function receiveTips() public payable {
        require(msg.sender == owner);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send Tips to owner.");
    }

    function getTipAmount() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {}
}