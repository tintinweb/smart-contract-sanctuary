/**
 *Submitted for verification at polygonscan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Emails {
    string[] public emails;
    address public owner = 0x7f6392A9048a0951d87e03E088d2d9B64719dE85;
    string public winner;
    
    function push(string memory str) public {
        emails.push(str);
    }
        
    function pickAWinner() public returns(string memory) {
        bytes memory winnerBytes = bytes(winner);
        require(msg.sender == owner, "You are not an owner");
        require(winnerBytes.length == 0, "Winner already picked");
        uint randomNumber = getRandomNumber();
        winner = emails[randomNumber];
        return winner;
    }
    
    function getRandomNumber() public view returns (uint) {
        require(emails.length > 0, "Please add email first");
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % emails.length;
        return randomNumber;
    }
}