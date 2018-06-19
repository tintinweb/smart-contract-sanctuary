pragma solidity ^0.4.0;

contract raffle {
    // Constants
    address rakeAddress = 0x15887100f3b3cA0b645F007c6AA11348665c69e5;
    uint prize = 0.1 ether;
    uint rake = 0.02 ether;
    uint totalTickets = 6;

    // Variables
    address creatorAddress;
    uint pricePerTicket;
    uint nextTicket;
    mapping(uint => address) purchasers;

    function raffle() {
        creatorAddress = msg.sender;
        pricePerTicket = (prize + rake) / totalTickets;
        resetRaffle();
    }

    function resetRaffle() private {
        nextTicket = 1;
    }

    function chooseWinner() private {
        uint winningTicket = 1; // TODO: Randomize
        address winningAddress = purchasers[winningTicket];
        winningAddress.transfer(prize);
        rakeAddress.transfer(rake);
        resetRaffle();
    }

    function buyTickets() payable public {
        uint moneySent = msg.value;

        while (moneySent >= pricePerTicket && nextTicket <= totalTickets) {
            purchasers[nextTicket] = msg.sender;
            moneySent -= pricePerTicket;
            nextTicket++;
        }

        // Send back leftover money
        if (moneySent > 0) {
            msg.sender.transfer(moneySent);
        }

        // Choose winner if we sold all the tickets
        if (nextTicket > totalTickets) {
            chooseWinner();
        }
    }

    // TODO
    function getRefund() public {
        return;
    }

    function kill() public {
        if (msg.sender == creatorAddress) {
            selfdestruct(creatorAddress);
        }
    }
}