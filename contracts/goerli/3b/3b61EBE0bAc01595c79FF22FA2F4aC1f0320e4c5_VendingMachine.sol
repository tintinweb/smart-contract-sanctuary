// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

error Unauthorized();

contract VendingMachine {
    address payable owner = payable(msg.sender);

    function withdraw() public {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        owner.transfer(address(this).balance);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    receive() external payable {}
}

