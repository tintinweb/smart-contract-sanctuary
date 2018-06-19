pragma solidity ^0.4.16;

contract koth_v1b {
    event NewKoth(
        uint gameId,
        uint betNumber,
        address bettor,
        uint bet,
        uint pot,
        uint lastBlock,
        uint minBet,
        uint maxBet
    );

    event KothWin(
        uint gameId,
        uint totalBets,
        address winner,
        uint winningBet,
        uint pot,
        uint fee,
        uint firstBlock,
        uint lastBlock
    );

    // Constants
    uint public constant minPot = 0.001 ether; // Contract needs to be endowed with this amount
    uint public constant minRaise = 0.001 ether;
    address feeAddress;

    // Other internal variables
    uint public gameId = 0;
    uint public betId;
    uint public highestBet;
    uint public pot;
    uint public firstBlock;
    uint public lastBlock;
    address public koth;

    // Initialization
    function koth_v1b() public {
        feeAddress = msg.sender;
        resetKoth();
    }

    function () payable public {
        // We&#39;re past the block target, but new game hasn&#39;t been activated
        if (lastBlock > 0 && block.number > lastBlock) {
            msg.sender.transfer(msg.value);
            return;
        }

        // Check for minimum bet (at least minRaise over current highestBet)
        uint minBet = highestBet + minRaise;
        if (msg.value < minBet) {
            msg.sender.transfer(msg.value);
            return;
        }

        // Check for maximum bet
        uint maxBet;
        if (pot < 1 ether) {
            maxBet = 3 * pot;
        } else {
            maxBet = 5 * pot / 4;
        }

        // Check for maximum bet
        if (msg.value > maxBet) {
            msg.sender.transfer(msg.value);
            return;
        }

        // Bet was successful
        betId++;
        highestBet = msg.value;
        koth = msg.sender;
        pot += highestBet;

        // Equation expects pot to be in Ether
        uint blocksRemaining = uint( 10 ** ((64-5*pot/1000000000000000000) / 40) );
        if (blocksRemaining < 3) {
            blocksRemaining = 3;
        }

        lastBlock = block.number + blocksRemaining;

        NewKoth(gameId, betId, koth, highestBet, pot, lastBlock, minBet, maxBet);
    }

    function resetKoth() private {
        gameId++;
        highestBet = 0;
        koth = address(0);
        pot = minPot;
        lastBlock = 0;
        betId = 0;
        firstBlock = block.number;
    }

    // Called to reward current KOTH winner and start new game
    function rewardKoth() public {
        if (msg.sender == feeAddress && lastBlock > 0 && block.number > lastBlock) {
            uint fee = pot / 20; // 5%
            KothWin(gameId, betId, koth, highestBet, pot, fee, firstBlock, lastBlock);

            uint netPot = pot - fee;
            address winner = koth;
            resetKoth();
            winner.transfer(netPot);

            // Make sure we never go below minPot
            if (this.balance - fee >= minPot) {
                feeAddress.transfer(fee);
            }
        }
    }

    function addFunds() payable public {
        if (msg.sender != feeAddress) {
            msg.sender.transfer(msg.value);
        }
    }

    function kill() public {
        if (msg.sender == feeAddress) {
            selfdestruct(feeAddress);
        }
    }
}