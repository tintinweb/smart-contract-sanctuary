/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity ^0.4.23;

// Simple "dice" game
// This smart contract act as shooter for a virtual 20-faces dice.
//
// A player can ask the shooter to roll the dice paying any amount (with a
// minimum 5 Wei) using the `bet` function.
//
// After rolling the dice, if the sum of the number is greater or equal
// to 14, the player wins the jackpot. In any case his bet becomes part of the
// jackpot itself.
//
// The jackpot is 50% of the total funds received by this contract
//
// WARNING:
// As a source for randomness, block's timestamp and difficulty are used.
// Note that miner could alter this value so they cannot be trusted in real
// world.

contract DiceGame {
    uint8 DICE_FACES = 20; // Number of faces of the dice
    uint8 DICE_TRESHOLD = 14; // Minimum result of dice that count as a win
    uint MIN_BET = 5; // Minimum amount of Wei valid for a bet

    uint funds = 0; // Current funds held by this contract

    // Check if a bet is valid, throwing an exception otherwise
    modifier isValidBet() {
        require(msg.value >= MIN_BET);
        _;
    }

    // Generate a random number in the range [0, 6], using block timestamp
    // and difficulty as a random source.
    function random() private view returns (uint8) {
        return uint8(
            uint(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % (DICE_FACES + 1)
        );
    }

    // Get the current jackpot available in case of win.
    function getJackpot()
        public
        view
        returns (uint)
    {
        return funds / 2;
    }

    // Place a bet. A minimum amount of 5 Wei is required.
    // The bet becomes part of the new jackpot.
    // The dice results are returned, together with a bool indicating if the
    // player won or not.
    // In case of win the jackpost is transferred to the player.
    function bet()
        public
        isValidBet()
        payable
        returns (uint8, bool)
    {
        funds += msg.value;
        uint8 dice = random();
        bool win = dice > DICE_TRESHOLD;
        if (win) {
            uint jackpot = getJackpot();
            funds -= jackpot;
            msg.sender.transfer(jackpot);
        }
        return (dice, win);
    }

}