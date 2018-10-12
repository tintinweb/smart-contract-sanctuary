pragma solidity ^0.4.25;


contract Lottery {
    address admin;
    address tester; // REMOVE ON PRODUCTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    uint fee = 0;
    uint houseFee = 0;
    uint affiliatesFee = 0;
    uint affiliatesFeeTotal = 0;
    uint lastBetBlock;
    uint constant max = ~uint256(0);
    
    uint affRate = 5;
    
    struct Winner {
        address player;
        uint amount;
    }
    
    mapping (address => uint) winnersMapping;
    mapping (address => uint) affiliates; // affiliate balance
    Winner[] TopWinners;
    
    event Win(address player, uint amount, uint8 winType);
    
    constructor () public {
        admin = msg.sender;
        lastBetBlock = block.number;
        for (uint8 i = 0; i < 3; i++) {
            TopWinners.push(Winner(msg.sender, 0));
        }
    }
    
    function () public payable{
        uint bet = msg.value;
        address player = msg.sender;
        if (bet > 0) {
            (uint payout, uint betFee, uint8 wt) = do_bet(bet);
            if (payout > 0) {
                player.transfer(payout);
                houseFee += betFee;
                addToWinners(player, payout);
            }
        } else {
            // This dummyGasBurner() helps MetaMask estimate gas limit better.
            // You shouldn&#39;t actually send 0 to contract or you&#39;ll waste gas here.
            dummyGasBurner();
        }
    }
    
    function betWithAff (address affAddr) public payable returns (uint8, uint) {
        uint bet = msg.value;
        address player = msg.sender;
        uint8 winType = 0;
        uint winAmount = 0;
        if (bet > 0) {
            (uint payout, uint betFee, uint8 wt) = do_bet(bet);
            if (payout > 0) {
                uint bonus = betFee / 3;
                payout += bonus;
                player.transfer(payout);
                houseFee += bonus;
                addToWinners(player, payout);
                affiliates[affAddr] += bonus;
                affiliatesFee += bonus;
                affiliatesFeeTotal += bonus;
                winType = wt;
                winAmount = payout;
                emit Win(player, payout, winType);
            }
        } else {
            dummyGasBurner();
        }
        return (winType, winAmount);
    }
    
    function addToWinners(address player, uint amount) private returns (bool) {
        uint totalAmount = winnersMapping[player] + amount;
        winnersMapping[player] = totalAmount;
        if (totalAmount < TopWinners[2].amount) {
            return false;
        } else if (totalAmount < TopWinners[1].amount) {
            TopWinners[2].player = player;
            TopWinners[2].amount = totalAmount;
        } else if (totalAmount < TopWinners[0].amount) {
            if (TopWinners[1].player == player) {
                TopWinners[1].amount = totalAmount;
            } else {
                TopWinners[2].player = TopWinners[1].player;
                TopWinners[2].amount = TopWinners[1].amount;
                TopWinners[1].player = player;
                TopWinners[1].amount = totalAmount;
            }
        } else if (totalAmount >= TopWinners[0].amount ) {
            if (TopWinners[0].player == player) {
                TopWinners[0].amount = totalAmount;
            } else if (TopWinners[1].player == player) {
                TopWinners[1].player = TopWinners[0].player;
                TopWinners[1].amount = TopWinners[0].amount;
                TopWinners[0].player = player;
                TopWinners[0].amount = totalAmount;
            } else {
                TopWinners[2].player = TopWinners[1].player;
                TopWinners[2].amount = TopWinners[1].amount;
                TopWinners[1].player = TopWinners[0].player;
                TopWinners[1].amount = TopWinners[0].amount;
                TopWinners[0].player = player;
                TopWinners[0].amount = totalAmount;
            }
        }
        return true;
    }
    
    function viewWinners () public view returns (address, uint, address, uint, address, uint){
        return (
            TopWinners[0].player, TopWinners[0].amount,
            TopWinners[1].player, TopWinners[1].amount,
            TopWinners[2].player, TopWinners[2].amount
        );
    }
    
    function do_bet (uint bet) private returns (uint, uint, uint8) {
        uint budget = address(this).balance - houseFee - affiliatesFee;
        uint roll = random();
        uint betProportion = budget / bet;
        uint jackPotCondition = max / betProportion;
        uint halfPotCondition = jackPotCondition + (max - jackPotCondition) / betProportion;
        uint winningPayout = 0;
        uint winnings = 0;
        uint8 winType = 0;
        if (roll < jackPotCondition / 10 || block.number > lastBetBlock + 200000) {
            winnings = (budget - bet) * 4 / 5;
            fee = winnings * 15 / 100;
            winningPayout = bet + winnings - fee;
            winType = 1;
        } else if (roll < halfPotCondition / 5) {
            winnings = (budget - bet) * 4 / 10;
            fee = winnings * 15 / 100;
            winningPayout = bet + winnings - fee;
            winType = 2;
        } else if (roll < max / 10) {
            winnings = bet * 4;
            fee = winnings * 15 / 100;
            if (winnings + fee < budget) {
                winningPayout = winnings;
                winType = 3;
            }
        } else if (roll < max / 3) {
            winnings = bet * 2;
            fee = winnings * 15 / 100;
            if (winnings + fee < budget) {
                winningPayout = winnings;
                winType = 4;
            }
        }
        lastBetBlock = block.number;
        return (winningPayout, fee, winType);
    }
    
    function estimatePots () public view returns (uint, uint) {
        uint budget = address(this).balance - houseFee - affiliatesFee;
        uint jackPot = budget * 4 / 5;
        uint halfPot = budget * 4 / 10;
        return (jackPot, halfPot);
    }
    
    function viewTotalAffiliateCommissions () public view returns (uint) {
        return affiliatesFeeTotal;
    }
    
    function withdrawHouseFee () public {
        if (msg.sender == admin) {
            admin.transfer(houseFee);
            houseFee = 0;
        }
    }
    
    function dummyGasBurner () private pure {
        for (uint i = 0; i < 150; i++) {
            sha256(&#39;Buring gas here!&#39;);
        }
    }
    
    function withdrawAffBonus () public {
        address aff = msg.sender;
        if (affiliates[aff] > 0) {
            affiliatesFee -= affiliates[aff];
            affiliates[aff] = 0;
            aff.transfer(affiliates[aff]);
        }
    }
    
    function random () private view returns (uint) {
        return uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty,
            block.coinbase,
            msg.sender
        )));
    }
    
    //function viewPlayerPayout(address player) public view returns (uint) {return payouts[player];}
    
    function getWinnersLength () public view returns (uint) {return TopWinners.length;}
    
    function getWinnerById (uint id) public view returns (address, uint) {return (TopWinners[id].player, TopWinners[id].amount);}
    
    function viewAffBonus (address aff) public view returns (uint) {return affiliates[aff];}
    
    function viewHouseFee () public view returns (uint) {return houseFee;}
    
    function affRegister () public {
        if (affiliates[msg.sender] == 0) {
            affiliates[msg.sender] = 0;
        }
    }
    
    // REMOVE ON PRODUCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function withrawAll () public {
        if (msg.sender == admin || msg.sender == tester) {
            msg.sender.transfer(address(this).balance);
            houseFee = 0;
            fee = 0;
            houseFee = 0;
            lastBetBlock;
        }
    }
    
    // REMOVE ON PRODUCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function assignTester (address t) public {
        if (msg.sender == admin){
            tester = t;
        }
    }
}