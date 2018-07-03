pragma solidity ^0.4.0;

contract SponsoredItemGooRaffle {
    
    Goo goo = Goo(0x57b116da40f21f91aec57329ecb763d29c1b2355);
    
    address owner;
    
    // Raffle tickets
    mapping(address => TicketPurchases) private ticketsBoughtByPlayer;
    mapping(uint256 => address[]) private rafflePlayers;

    // Current Raffle info
    uint256 private constant RAFFLE_TICKET_BASE_GOO_PRICE = 1000;
    uint256 private raffleEndTime;
    uint256 private raffleTicketsBought;
    uint256 private raffleId;
    address private raffleWinner;
    bool private raffleWinningTicketSelected;
    uint256 private raffleTicketThatWon;
    
    
    // Raffle structures
    struct TicketPurchases {
        TicketPurchase[] ticketsBought;
        uint256 numPurchases; // Allows us to reset without clearing TicketPurchase[] (avoids potential for gas limit)
        uint256 raffleId;
    }
    
    // Allows us to query winner without looping (avoiding potential for gas limit)
    struct TicketPurchase {
        uint256 startId;
        uint256 endId;
    }
    
    function SponsoredItemGooRaffle() public {
        owner = msg.sender;
    }
    
    function startTokenRaffle(uint256 endTime, address tokenContract, uint256 id, bool hasItemAlready) external {
        require(msg.sender == owner);
        require(block.timestamp < endTime);
        
        if (raffleId != 0) { // Sanity to assure raffle has ended before next one starts
            require(raffleWinner != 0);
        }
        
        // Reset previous raffle info
        raffleWinningTicketSelected = false;
        raffleTicketThatWon = 0;
        raffleWinner = 0;
        raffleTicketsBought = 0;
        
        // Set current raffle info
        raffleEndTime = endTime;
        raffleId++;
    }
    

    function buyRaffleTicket(uint256 amount) external {
        require(raffleEndTime >= block.timestamp);
        require(amount > 0);
        
        uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_GOO_PRICE, amount);
        goo.transferFrom(msg.sender, this, ticketsCost);
        // Burn 95% of the Goo (save 5% for contests / marketing fund)
        goo.transfer(address(0), (ticketsCost * 95) / 100);
        
        // Handle new tickets
        TicketPurchases storage purchases = ticketsBoughtByPlayer[msg.sender];
        
        // If we need to reset tickets from a previous raffle
        if (purchases.raffleId != raffleId) {
            purchases.numPurchases = 0;
            purchases.raffleId = raffleId;
            rafflePlayers[raffleId].push(msg.sender); // Add user to raffle
        }
        
        // Store new ticket purchase
        if (purchases.numPurchases == purchases.ticketsBought.length) {
            purchases.ticketsBought.length += 1;
        }
        purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(raffleTicketsBought, raffleTicketsBought + (amount - 1)); // (eg: buy 10, get id&#39;s 0-9)
        
        // Finally update ticket total
        raffleTicketsBought += amount;
    }
    
    function awardRafflePrize(address checkWinner, uint256 checkIndex) external {
        require(raffleEndTime < block.timestamp);
        require(raffleWinner == 0);
        
        if (!raffleWinningTicketSelected) {
            drawRandomWinner(); // Ideally do it in one call (gas limit cautious)
        }
        
        // Reduce gas by (optionally) offering an address to _check_ for winner
        if (checkWinner != 0) {
            TicketPurchases storage tickets = ticketsBoughtByPlayer[checkWinner];
            if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleId == raffleId) {
                TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
                if (raffleTicketThatWon >= checkTicket.startId && raffleTicketThatWon <= checkTicket.endId) {
                    assignRaffleWinner(checkWinner); // WINNER!
                    return;
                }
            }
        }
        
        // Otherwise just naively try to find the winner (will work until mass amounts of players)
        for (uint256 i = 0; i < rafflePlayers[raffleId].length; i++) {
            address player = rafflePlayers[raffleId][i];
            TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
            
            uint256 endIndex = playersTickets.numPurchases - 1;
            // Minor optimization to avoid checking every single player
            if (raffleTicketThatWon >= playersTickets.ticketsBought[0].startId && raffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
                for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
                    TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
                    if (raffleTicketThatWon >= playerTicket.startId && raffleTicketThatWon <= playerTicket.endId) {
                        assignRaffleWinner(player); // WINNER!
                        return;
                    }
                }
            }
        }
    }
    
    function assignRaffleWinner(address winner) internal {
        raffleWinner = winner;
    }
    
    // Random enough for small contests (Owner only to prevent trial & error execution)
    function drawRandomWinner() public {
        require(msg.sender == owner);
        require(raffleEndTime < block.timestamp);
        require(!raffleWinningTicketSelected);
        
        uint256 seed = raffleTicketsBought + block.timestamp;
        raffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, (raffleTicketsBought + 1));
        raffleWinningTicketSelected = true;
    }
    
    // 5% of Goo gained will be reinvested into the game (contests / marketing / acquiring more raffle assets)
    function transferGoo(address recipient, uint256 amount) external {
        require(msg.sender == owner);
        goo.transfer(recipient, amount);
    }
    
     // To display on website
    function getLatestRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
        return (raffleEndTime, raffleId, raffleTicketsBought, raffleWinner, raffleTicketThatWon);
    }
    
    // To allow clients to verify contestants
    function getRafflePlayers(uint256 raffle) external constant returns (address[]) {
        return (rafflePlayers[raffle]);
    }
    
     // To allow clients to verify contestants
    function getPlayersTickets(address player) external constant returns (uint256[], uint256[]) {
        TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
        
        if (playersTickets.raffleId == raffleId) {
            uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
            uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
            for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
                startIds[i] = playersTickets.ticketsBought[i].startId;
                endIds[i] = playersTickets.ticketsBought[i].endId;
            }
        }
        
        return (startIds, endIds);
    }
}


interface Goo {
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}