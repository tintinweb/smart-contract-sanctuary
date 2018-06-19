pragma solidity ^0.4.15;

/// @title Ethereum Lottery Game.

contract EtherLotto {

    // Amount of ether needed for participating in the lottery.
    uint constant TICKET_AMOUNT = 10;

    // Fixed amount fee for each lottery game.
    uint constant FEE_AMOUNT = 1;

    // Address where fee is sent.
    address public bank;

    // Public jackpot that each participant can win (minus fee).
    uint public pot;

    // Lottery constructor sets bank account from the smart-contract owner.
    function EtherLotto() {
        bank = msg.sender;
    }

    // Public function for playing lottery. Each time this function
    // is invoked, the sender has an oportunity for winning pot.
    function play() payable {

        // Participants must spend some fixed ether before playing lottery.
        assert(msg.value == TICKET_AMOUNT);

        // Increase pot for each participant.
        pot += msg.value;

        // Compute some *almost random* value for selecting winner from current transaction.
        var random = uint(sha3(block.timestamp)) % 2;

        // Distribution: 50% of participants will be winners.
        if (random == 0) {

            // Send fee to bank account.
            bank.transfer(FEE_AMOUNT);

            // Send jackpot to winner.
            msg.sender.transfer(pot - FEE_AMOUNT);

            // Restart jackpot.
            pot = 0;
        }
    }

}