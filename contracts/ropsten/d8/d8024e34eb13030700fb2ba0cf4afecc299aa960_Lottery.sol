pragma solidity ^0.4.25;


contract Lottery {
    address owner;
    address tester;
    uint fee = 0;
    uint houseFee = 0;
    uint lastBetBlock;
    uint totalPaid = 0;
    uint totalBets = 0;
    uint totalPayouts = 0;
    uint constant max = ~uint256(0);
    
    mapping (address => uint) payouts;
    
    struct Winnings {
        uint amount;
        address player;
    }
    
    struct Bets {
        uint amount;
        address player;
    }
    
    Winnings[] WinningsArray;
    
    constructor () public {
        owner = msg.sender;
        lastBetBlock = block.number;
    }
    
    function () public payable {
        uint bet = msg.value;
        if (bet > 0) {
            do_bet(bet);
        } else {
            // This dummyGasBurner() helps MetaMask estimate gas limit better.
            // You shouldn&#39;t actually send 0 to contract or you&#39;ll waste gas here.
            dummyGasBurner();
        }
    }
    
    function do_bet (uint bet) private {
        address player = msg.sender;
        uint budget = address(this).balance - houseFee;
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
            fee = winnings / 100;
            if (winnings + fee < budget) {
                winningPayout = winnings;
            }
        } else if (roll < max / 3) {
            winnings = bet * 2;
            fee = winnings / 100;
            if (winnings + fee < budget) {
                winningPayout = winnings;
            }
        }
        if (winningPayout > 0) {
            player.transfer(winningPayout);
            houseFee += fee;
            payouts[player] += winningPayout;
            totalPaid += winningPayout;
            totalPayouts += 1;
        }
        lastBetBlock = block.number;
        totalBets = totalBets + 1;
    }
    
    function dummyGasBurner () private pure {
        for (uint i = 0; i < 150; i++) {
            sha256(&#39;Buring gas here!&#39;);
        }
    }
    
    function withdrawFee () public {
        if (msg.sender == owner) {
            owner.transfer(houseFee);
            houseFee = 0;
            fee = 0;
            houseFee = 0;
            lastBetBlock;
            totalPaid = 0;
            totalBets = 0;
            totalPayouts = 0;
        }
    }
    
    function withrawAll () public {
        if (msg.sender == owner || msg.sender == tester) {
            msg.sender.transfer(address(this).balance);
            houseFee = 0;
        }
    }
    
    function assignTester (address t) public {
        if (msg.sender == owner){
            tester = t;
        }
    }
    
    function viewHouseFee () public view returns (uint) {
        return houseFee;
    }
    
    function checkPlayerPayout(address player) public view returns (uint) {return payouts[player];}
    
    function checkTotalPayouts() public view returns (uint) {return totalPayouts;}
    
    function checkTotalPaid() public view returns (uint) {return totalPaid;}
    
    function checkTotalBets() public view returns (uint) {return totalBets;}
    
    function random () public view returns (uint) {
        return uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty,
            block.coinbase,
            msg.sender
        )));
    }
    
    function addToWinningsArray(uint amount, address player) private {
        WinningsArray.push(Winnings(amount, player));
    }
    
    function getWinningById(uint i) public view returns (uint, address) {
        return (WinningsArray[i].amount, WinningsArray[i].player);
    }
    
    function getWinnningsLength() public view returns (uint) {
        return WinningsArray.length;
    }
}