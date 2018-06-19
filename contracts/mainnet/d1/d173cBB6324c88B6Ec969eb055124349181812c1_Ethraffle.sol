pragma solidity ^0.4.15;

contract Ethraffle {
    struct Contestant {
        address addr;
        uint raffleId;
        uint remainingGas;
    }

    event RaffleResult(
        uint indexed raffleId,
        uint winningNumber,
        address winningAddress
    );

    event TicketPurchase(
        uint indexed raffleId,
        address contestant,
        uint number
    );

    event TicketRefund(
        uint indexed raffleId,
        address contestant,
        uint number
    );

    // Constants
    address public rakeAddress;
    uint constant public prize = 0.1 ether;
    uint constant public rake = 0.02 ether;
    uint constant public totalTickets = 6;
    uint constant public pricePerTicket = (prize + rake) / totalTickets;

    // Other internal variables
    uint public raffleId = 1;
    uint public nextTicket = 0;
    mapping (uint => Contestant) public contestants;
    uint[] public gaps;
    bool public paused = false;
    Contestant randCt1;
    Contestant randCt2;
    Contestant randCt3;

    // Initialization
    function Ethraffle() public {
        rakeAddress = msg.sender;
    }

    // Call buyTickets() when receiving Ether outside a function
    function () payable public {
        buyTickets();
    }

    function buyTickets() payable public {
        if (paused) {
            msg.sender.transfer(msg.value);
            return;
        }

        uint moneySent = msg.value;

        while (moneySent >= pricePerTicket && nextTicket < totalTickets) {
            uint currTicket = 0;
            if (gaps.length > 0) {
                currTicket = gaps[gaps.length-1];
                gaps.length--;
            } else {
                currTicket = nextTicket++;
            }

            contestants[currTicket] = Contestant(msg.sender, raffleId, msg.gas);
            TicketPurchase(raffleId, msg.sender, currTicket);
            moneySent -= pricePerTicket;
        }

        // Choose winner if we sold all the tickets
        if (nextTicket == totalTickets) {
            chooseWinner();
        }

        // Send back leftover money
        if (moneySent > 0) {
            msg.sender.transfer(moneySent);
        }
    }

    function chooseWinner() private {
        // Pseudorandom number generator
        randCt1 = contestants[uint(msg.gas) % totalTickets];
        randCt2 = contestants[uint(block.coinbase) % totalTickets];
        randCt3 = contestants[(randCt1.remainingGas + randCt2.remainingGas) % totalTickets];
        bytes32 sha = sha3(randCt1.addr, randCt2.addr, randCt3.addr, randCt3.remainingGas);

        uint winningNumber = uint(sha) % totalTickets;
        address winningAddress = contestants[winningNumber].addr;
        RaffleResult(raffleId, winningNumber, winningAddress);

        // Start next raffle and distribute prize
        raffleId++;
        nextTicket = 0;
        winningAddress.transfer(prize);
        rakeAddress.transfer(rake);
    }

    // Get your money back before the raffle occurs
    function getRefund() public {
        uint refunds = 0;
        for (uint i = 0; i < totalTickets; i++) {
            if (msg.sender == contestants[i].addr && raffleId == contestants[i].raffleId) {
                refunds++;
                contestants[i] = Contestant(address(0), 0, 0);
                gaps.push(i);
                TicketRefund(raffleId, msg.sender, i);
            }
        }

        if (refunds > 0) {
            msg.sender.transfer(refunds * pricePerTicket);
        }
    }

    // Refund everyone&#39;s money, start a new raffle, then pause it
    function endRaffle() public {
        if (msg.sender == rakeAddress) {
            paused = true;

            for (uint i = 0; i < totalTickets; i++) {
                if (raffleId == contestants[i].raffleId) {
                    TicketRefund(raffleId, contestants[i].addr, i);
                    contestants[i].addr.transfer(pricePerTicket);
                }
            }

            RaffleResult(raffleId, totalTickets + 1, address(0));
            raffleId++;
            nextTicket = 0;
            gaps.length = 0;
        }
    }

    function togglePause() public {
        if (msg.sender == rakeAddress) {
            paused = !paused;
        }
    }

    function kill() public {
        if (msg.sender == rakeAddress) {
            selfdestruct(rakeAddress);
        }
    }
}