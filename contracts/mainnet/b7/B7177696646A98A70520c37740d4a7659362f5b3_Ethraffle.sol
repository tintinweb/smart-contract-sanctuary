pragma solidity ^0.4.0;

contract Ethraffle {
    struct Contestant {
        address addr;
        uint raffleId;
    }

    event RaffleResult(
        uint indexed raffleId,
        uint winningNumber,
        address winningAddress,
        uint blockTimestamp,
        uint blockNumber,
        uint gasLimit,
        uint difficulty,
        uint gas,
        uint value,
        address msgSender,
        address blockCoinbase,
        bytes32 sha
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
    uint public nextTicket = 1;
    mapping (uint => Contestant) public contestants;
    uint[] public gaps;

    // Initialization
    function Ethraffle() public {
        rakeAddress = msg.sender;
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
            TicketPurchase(raffleId, msg.sender, currTicket);
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
        // Pseudorandom number generator
        bytes32 sha = sha3(
            block.timestamp,
            block.number,
            block.gaslimit,
            block.difficulty,
            msg.gas,
            msg.value,
            msg.sender,
            block.coinbase
        );

        uint winningNumber = (uint(sha) % totalTickets) + 1;
        address winningAddress = contestants[winningNumber].addr;
        RaffleResult(
            raffleId, winningNumber, winningAddress, block.timestamp,
            block.number, block.gaslimit, block.difficulty, msg.gas,
            msg.value, msg.sender, block.coinbase, sha
        );

        // Start next raffle and distribute prize
        raffleId++;
        nextTicket = 1;
        winningAddress.transfer(prize);
        rakeAddress.transfer(rake);
    }

    function getRefund() public {
        uint refunds = 0;
        for (uint i = 1; i <= totalTickets; i++) {
            if (msg.sender == contestants[i].addr && raffleId == contestants[i].raffleId) {
                refunds++;
                contestants[i] = Contestant(address(0), 0);
                gaps.push(i);
                TicketRefund(raffleId, msg.sender, i);
            }
        }

        if (refunds > 0) {
            msg.sender.transfer(refunds * pricePerTicket);
        }
    }

    function kill() public {
        if (msg.sender == rakeAddress) {
            selfdestruct(rakeAddress);
        }
    }
}