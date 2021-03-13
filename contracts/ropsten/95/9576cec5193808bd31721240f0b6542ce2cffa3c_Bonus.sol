/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;
contract Bonus {
address payable labtask = payable(0x919162C79480B3551baA5AB4160d7B9B8c9DC0d6);
Lab5 lab5;
constructor() {
lab5 = Lab5(labtask);
}
// Successfully execute this method with your student id to receive extra marks

function solved_task(uint student_id) public {
    student_id = 2039034;
lab5.task{value: 1 ether}(student_id);
}
// Accept any incoming amount
receive () external payable {}
}
// Interface to Lab5 evaluation contract
contract Lab5 {
mapping (uint => bool) public students;
function task(uint) external payable {}
receive () external payable {}
}