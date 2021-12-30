/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.4.22;

contract Gamble {
    uint256 private number;
    uint256 phase;
    address winner;

    constructor(uint256 num) public {
        require(num < 100);
        number = num;
        phase = 0; // 0: guessing 1: start a new game
    }

    function guess(uint256 fee) external payable {
        require(phase == 0);
        require(fee == 10 finney);
        if (address(this).balance == number * 10) {
            winner = msg.sender;
            phase = 1;
        }
    }

    function newGame(uint256 num) external {
        require(phase == 1);
        require(msg.sender == winner);
        winner.transfer(address(this).balance);
        require(num < 100);
        number = num;
        phase = 0;
    }
}