pragma solidity ^0.4.16;

contract Ethraffle_v2b {
    struct Contestant {
        address addr;
        uint raffleId;
    }

    event RaffleResult(
        uint indexed raffleId,
        uint winningNumber,
        address winningAddress,
        address seed1,
        address seed2,
        uint seed3,
        bytes32 randHash
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
    uint public constant prize = 2.5 ether;
    uint public constant fee = 0.03 ether;
    uint public constant totalTickets = 50;
    uint public constant pricePerTicket = (prize + fee) / totalTickets; // Make sure this divides evenly
    address feeAddress;

    // Other internal variables
    bool public paused = false;
    uint public raffleId = 1;
    uint nextTicket = 0;
    mapping (uint => Contestant) contestants;
    uint[] gaps;

    // Initialization
    function Ethraffle_v2b() public {
        feeAddress = msg.sender;
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

            contestants[currTicket] = Contestant(msg.sender, raffleId);
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
        address seed1 = contestants[uint(block.coinbase) % totalTickets].addr;
        address seed2 = contestants[uint(msg.sender) % totalTickets].addr;
        uint seed3 = block.difficulty;
        bytes32 randHash = keccak256(seed1, seed2, seed3);

        uint winningNumber = uint(randHash) % totalTickets;
        address winningAddress = contestants[winningNumber].addr;
        RaffleResult(raffleId, winningNumber, winningAddress, seed1, seed2, seed3, randHash);

        // Start next raffle
        raffleId++;
        nextTicket = 0;

        // gaps.length = 0 isn&#39;t necessary here,
        // because buyTickets() eventually clears
        // the gaps array in the loop itself.

        // Distribute prize and fee
        winningAddress.transfer(prize);
        feeAddress.transfer(fee);
    }

    // Get your money back before the raffle occurs
    function getRefund() public {
        uint refund = 0;
        for (uint i = 0; i < totalTickets; i++) {
            if (msg.sender == contestants[i].addr && raffleId == contestants[i].raffleId) {
                refund += pricePerTicket;
                contestants[i] = Contestant(address(0), 0);
                gaps.push(i);
                TicketRefund(raffleId, msg.sender, i);
            }
        }

        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

    // Refund everyone&#39;s money, start a new raffle, then pause it
    function endRaffle() public {
        if (msg.sender == feeAddress) {
            paused = true;

            for (uint i = 0; i < totalTickets; i++) {
                if (raffleId == contestants[i].raffleId) {
                    TicketRefund(raffleId, contestants[i].addr, i);
                    contestants[i].addr.transfer(pricePerTicket);
                }
            }

            RaffleResult(raffleId, totalTickets, address(0), address(0), address(0), 0, 0);
            raffleId++;
            nextTicket = 0;
            gaps.length = 0;
        }
    }

    function togglePause() public {
        if (msg.sender == feeAddress) {
            paused = !paused;
        }
    }

    function kill() public {
        if (msg.sender == feeAddress) {
            selfdestruct(feeAddress);
        }
    }
}