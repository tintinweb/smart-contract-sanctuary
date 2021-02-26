/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX-License-Identifier: GPL-3.0-only

// 0x919162C79480B3551baA5AB4160d7B9B8c9DC0d6
pragma solidity >=0.4.10 <0.9.0;

// ToDo
contract Lab5 {

    address payable owner;
    mapping (uint => bool) public students;

    constructor() {
        owner = payable(msg.sender);
    }

    // students need to call this
    function task(uint student_id) external payable {

        require(msg.value >= 1 ether);
        students[student_id] = true;

    }

    function clear() external {

        require(msg.sender == owner);
        owner.transfer(address(this).balance);

    }

    // Accept any incoming amount
    receive() external payable {}

}