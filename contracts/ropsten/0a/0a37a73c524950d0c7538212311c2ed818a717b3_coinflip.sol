/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

pragma solidity ^0.8.7;

contract coinflip {
    uint rollNumber = 1;
    uint guess = 1;
    address payable winner;
    uint bet;
    event Roll(address payable indexed, uint, bool);

    function roll() public payable {
        bet = msg.value;
        require(guess == 1 || guess == 2);
        if (guess == rollNumber) {
            winner.transfer(bet);
            emit Roll(winner, bet, true);
        }
        else {
            emit Roll(winner, bet, false);
        }
    }
}