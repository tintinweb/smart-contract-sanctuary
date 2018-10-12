pragma solidity ^0.4.25;


contract Lottery {
    address owner;
    uint constant max = ~uint256(0);
    uint fee = 0;
    uint lastBetBlock;
    
    mapping (address => uint) payouts;
    
    constructor () public {
        owner = msg.sender;
        lastBetBlock = block.number;
    }
    
    
    function () public payable {
        uint bet = msg.value;
        if (bet > 0) {
            do_bet(bet);
        } else {
            // This gasBurner helps MetaMask estimate gas limit better.
            // You shouldn&#39;t actually send 0 to contract or you&#39;ll waste gas here.
            dummyGasBurner();
        }
    }
    
    
    function do_bet (uint bet) private {
        address player = msg.sender;
        uint budget = address(this).balance + bet;
        uint roll = random();
        uint betProportion = budget / bet;
        uint jackPotCondition = max / betProportion;
        uint halfPotCondition = jackPotCondition + (max - jackPotCondition) / betProportion;
        uint winningPayout = 0;
        uint winnings = 0;
        if (roll < jackPotCondition / 10 || block.number > lastBetBlock + 200000) {
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
            payouts[player] = payouts[player] + winningPayout;
        }
        lastBetBlock = block.number;
    }
    
    
    function dummyGasBurner () private view {
        for (uint i = 0; i < 200; i++) {
            random();
        }
    }
    
    
    function checkTotalPayout(address player) public view returns (uint) {
        return payouts[player];
    }
    
    
    function random () public view returns (uint) {
        return uint(keccak256(
            block.timestamp,
            block.number,
            block.difficulty,
            block.coinbase,
            msg.sender
        ));
    }
}