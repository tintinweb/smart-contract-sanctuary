/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;


contract Question {

    string public question = "How many Prolog developers does it take to change a lightbulb?";
    string private answer = "none";

    constructor(string memory _answer) payable {
        require(msg.value == 1 ether);
        answer = _answer;
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }
    
    function guess(string calldata _answer) external payable {
        require(msg.value == 1 ether);

        if (keccak256(abi.encodePacked(_answer)) == keccak256(abi.encodePacked(answer))) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}