/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

contract Property {

    string  private value;
    address public owner;

    event Received(address, uint);

    constructor() {
        owner = msg.sender;
        value = "qwerty";
    }

    function getValue() public view returns (string memory) {
        return value;
    }

    function setValue(string memory _value) public payable {
        value = _value;
        emit Received(msg.sender, msg.value);
    }

    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(payable(address(owner)));
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}