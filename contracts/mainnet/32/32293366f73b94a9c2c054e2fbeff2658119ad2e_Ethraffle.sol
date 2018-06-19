pragma solidity ^0.4.0;

contract Ethraffle {
    // Structs
    struct Contestant {
        address addr;
        uint raffleId;
    }

    // Constants
    address public creatorAddress;
    address constant public rakeAddress = 0x15887100f3b3cA0b645F007c6AA11348665c69e5;
    uint constant public prize = 0.1 ether;
    uint constant public rake = 0.02 ether;
    uint constant public totalTickets = 6;
    uint constant public pricePerTicket = (prize + rake) / totalTickets;

    // Variables
    uint public raffleId = 0;
    uint public nextTicket = 0;
    mapping (uint => Contestant) public contestants;
    uint[] public gaps;

    // Initialization
    function Ethraffle() public {
        creatorAddress = msg.sender;
        resetRaffle();
    }

    function resetRaffle() private {
        raffleId++;
        nextTicket = 1;
    }

    // Call buyTickets() when receiving Ether outside a function
    function () payable public {
        buyTickets();
    }

    function buyTickets() payable public {
        uint moneySent = msg.value;

        while (moneySent >= pricePerTicket && nextTicket <= totalTickets) {
            uint currTicket = 0;
            if (gaps.length > 0) {
                currTicket = gaps[gaps.length-1];
                gaps.length--;
            } else {
                currTicket = nextTicket++;
            }

            contestants[currTicket] = Contestant(msg.sender, raffleId);
            moneySent -= pricePerTicket;
        }

        // Choose winner if we sold all the tickets
        if (nextTicket > totalTickets) {
            chooseWinner();
        }

        // Send back leftover money
        if (moneySent > 0) {
            msg.sender.transfer(moneySent);
        }
    }

    function chooseWinner() private {
        uint winningTicket = getRandom();
        address winningAddress = contestants[winningTicket].addr;
        resetRaffle();
        winningAddress.transfer(prize);
        rakeAddress.transfer(rake);
    }

    // Choose a random int between 1 and totalTickets
    function getRandom() private returns (uint) {
        return (uint(sha3(block.timestamp + block.number + block.gaslimit + block.difficulty + msg.gas + uint(msg.sender) + uint(block.coinbase))) % totalTickets) + 1;
    }

    function getRefund() public {
        uint refunds = 0;
        for (uint i = 1; i <= totalTickets; i++) {
            if (msg.sender == contestants[i].addr && raffleId == contestants[i].raffleId) {
                refunds++;
                contestants[i] = Contestant(address(0), 0);
                gaps.push(i);
            }
        }

        if (refunds > 0) {
            msg.sender.transfer(refunds * pricePerTicket);
        }
    }

    function kill() public {
        if (msg.sender == creatorAddress) {
            selfdestruct(creatorAddress);
        }
    }
}