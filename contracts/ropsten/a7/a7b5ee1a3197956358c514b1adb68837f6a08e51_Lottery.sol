pragma solidity ^0.4.25;


contract Lottery {
    address owner;
    uint constant max = ~uint256(0);
    uint fee = 0;
    
    constructor () public {
        owner = msg.sender;
    }
    
    function () public payable {
        require(msg.value!=0);
        address player = msg.sender;
        uint bet = msg.value;
        uint budget = address(this).balance + bet;
        uint roll = random();
        uint betProportion = budget / bet;
        uint jackPotCondition = max / betProportion;
        uint halfPotCondition = jackPotCondition + (max - jackPotCondition) / betProportion;
        uint winningPayout = 0;
        uint winnings = 0;
        if (roll < jackPotCondition / 10) {
            winnings = (budget - bet) * 4 / 5;
            fee = winnings / 10;
            winningPayout = bet + winnings - fee;
        } else if (roll < halfPotCondition / 5) {
            winnings = (budget - bet) * 4 / 10;
            fee = winnings / 10;
            winningPayout = bet + winnings - fee;
        } else if (roll < max / 10) {
            winnings = bet * 4;
            if (winnings < budget) {
                fee = winnings / 100;
                winningPayout = winnings - fee;
            }
        } else if (roll < max / 3) {
            winnings = bet * 2;
            if (winnings < budget) {
                fee = winnings / 100;
                winningPayout = winnings - fee;
            }
        }
        if (winningPayout > 0) {
            player.transfer(winningPayout);
            owner.transfer(fee);
        }
    }
    
    function random () public view returns (uint) {
        return uint(keccak256(abi.encodePacked(
            block.coinbase, 
            msg.sender, 
            now,
            block.difficulty,
            tx.gasprice
        )));
    }
}