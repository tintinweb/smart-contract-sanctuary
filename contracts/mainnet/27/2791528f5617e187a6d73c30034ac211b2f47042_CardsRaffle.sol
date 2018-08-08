pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The MagicAcademy Project.  All rights reserved.
/* 
/* https://www.magicacademy.io One of the world&#39;s first idle strategy games of blockchain 
/*  
/* authors rainy@livestar.com/Jony.Fu@livestar.com
/*                 
/* ==================================================================== */
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /*
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract AccessAdmin is Ownable {

  /// @dev Admin Address
  mapping (address => bool) adminContracts;

  /// @dev Trust contract
  mapping (address => bool) actionContracts;

  function setAdminContract(address _addr, bool _useful) public onlyOwner {
    require(_addr != address(0));
    adminContracts[_addr] = _useful;
  }

  modifier onlyAdmin {
    require(adminContracts[msg.sender]); 
    _;
  }

  function setActionContract(address _actionAddr, bool _useful) public onlyAdmin {
    actionContracts[_actionAddr] = _useful;
  }

  modifier onlyAccess() {
    require(actionContracts[msg.sender]);
    _;
  }
}

interface CardsInterface {
  function balanceOf(address player) public constant returns(uint256);
  function updatePlayersCoinByOut(address player) external;
  function updatePlayersCoinByPurchase(address player, uint256 purchaseCost) public;
  function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external;
  function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external;
}
interface RareInterface {
  function getRareItemsOwner(uint256 rareId) external view returns (address);
  function getRareItemsPrice(uint256 rareId) external view returns (uint256);
    function getRareInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  ); 
  function transferToken(address _from, address _to, uint256 _tokenId) external;
  function transferTokenByContract(uint256 _tokenId,address _to) external;
  function setRarePrice(uint256 _rareId, uint256 _price) external;
  function rareStartPrice() external view returns (uint256);
}
contract CardsRaffle is AccessAdmin {
  using SafeMath for SafeMath;

  function CardsRaffle() public {
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }
  //data contract
  CardsInterface public cards ;
  RareInterface public rare;

  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }

  //rare cards
  function setRareAddress(address _address) external onlyOwner {
    rare = RareInterface(_address);
  }

  function getRareAddress() public view returns (address) {
    return rare;
  }

  //event
  event UnitBought(address player, uint256 unitId, uint256 amount);
  event RaffleSuccessful(address winner);

  // Raffle structures
  struct TicketPurchases {
    TicketPurchase[] ticketsBought;
    uint256 numPurchases; // Allows us to reset without clearing TicketPurchase[] (avoids potential for gas limit)
    uint256 raffleRareId;
  }
    
  // Allows us to query winner without looping (avoiding potential for gas limit)
  struct TicketPurchase {
    uint256 startId;
    uint256 endId;
  }
    
  // Raffle tickets
  mapping(address => TicketPurchases) private ticketsBoughtByPlayer;
  mapping(uint256 => address[]) private rafflePlayers; // Keeping a seperate list for each raffle has it&#39;s benefits. 

  uint256 private constant RAFFLE_TICKET_BASE_PRICE = 10000;

  // Current raffle info  
  uint256 private raffleEndTime;
  uint256 private raffleRareId;
  uint256 private raffleTicketsBought;
  address private raffleWinner; // Address of winner
  bool private raffleWinningTicketSelected;
  uint256 private raffleTicketThatWon;

  // Raffle for rare items  
  function buyRaffleTicket(uint256 amount) external {
    require(raffleEndTime >= block.timestamp);  //close it if need test
    require(amount > 0);
        
    uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_PRICE, amount);
    require(cards.balanceOf(msg.sender) >= ticketsCost);
        
    // Update player&#39;s jade  
    cards.updatePlayersCoinByPurchase(msg.sender, ticketsCost);
        
    // Handle new tickets
    TicketPurchases storage purchases = ticketsBoughtByPlayer[msg.sender];
        
    // If we need to reset tickets from a previous raffle
    if (purchases.raffleRareId != raffleRareId) {
      purchases.numPurchases = 0;
      purchases.raffleRareId = raffleRareId;
      rafflePlayers[raffleRareId].push(msg.sender); // Add user to raffle
    }
        
    // Store new ticket purchase 
    if (purchases.numPurchases == purchases.ticketsBought.length) {
      purchases.ticketsBought.length = SafeMath.add(purchases.ticketsBought.length,1);
    }
    purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(raffleTicketsBought, raffleTicketsBought + (amount - 1)); // (eg: buy 10, get id&#39;s 0-9)
        
    // Finally update ticket total
    raffleTicketsBought = SafeMath.add(raffleTicketsBought,amount);
    //event
    UnitBought(msg.sender,raffleRareId,amount);
  } 

  /// @dev start raffle
  function startRareRaffle(uint256 endTime, uint256 rareId) external onlyAdmin {
    require(rareId>0);
    require(rare.getRareItemsOwner(rareId) == getRareAddress());
    require(block.timestamp < endTime); //close it if need test

    if (raffleRareId != 0) { // Sanity to assure raffle has ended before next one starts
      require(raffleWinner != 0);
    }

    // Reset previous raffle info
    raffleWinningTicketSelected = false;
    raffleTicketThatWon = 0;
    raffleWinner = 0;
    raffleTicketsBought = 0;
        
    // Set current raffle info
    raffleEndTime = endTime;
    raffleRareId = rareId;
  }

  function awardRafflePrize(address checkWinner, uint256 checkIndex) external { 
    require(raffleEndTime < block.timestamp);  //close it if need test
    require(raffleWinner == 0);
    require(rare.getRareItemsOwner(raffleRareId) == getRareAddress());
        
    if (!raffleWinningTicketSelected) {
      drawRandomWinner(); // Ideally do it in one call (gas limit cautious)
    }
        
  // Reduce gas by (optionally) offering an address to _check_ for winner
    if (checkWinner != 0) {
      TicketPurchases storage tickets = ticketsBoughtByPlayer[checkWinner];
      if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleRareId == raffleRareId) {
        TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
        if (raffleTicketThatWon >= checkTicket.startId && raffleTicketThatWon <= checkTicket.endId) {
          assignRafflePrize(checkWinner); // WINNER!
          return;
        }
      }
    }
        
  // Otherwise just naively try to find the winner (will work until mass amounts of players)
    for (uint256 i = 0; i < rafflePlayers[raffleRareId].length; i++) {
      address player = rafflePlayers[raffleRareId][i];
      TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
            
      uint256 endIndex = playersTickets.numPurchases - 1;
      // Minor optimization to avoid checking every single player
      if (raffleTicketThatWon >= playersTickets.ticketsBought[0].startId && raffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
        for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
          TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
          if (raffleTicketThatWon >= playerTicket.startId && raffleTicketThatWon <= playerTicket.endId) {
            assignRafflePrize(player); // WINNER!
            return;
          }
        }
      }
    }
  }

  function assignRafflePrize(address winner) internal {
    raffleWinner = winner;
    uint256 newPrice = (rare.rareStartPrice() * 25) / 20;
    rare.transferTokenByContract(raffleRareId,winner);
    rare.setRarePrice(raffleRareId,newPrice);
       
    cards.updatePlayersCoinByOut(winner);
    uint256 upgradeClass;
    uint256 unitId;
    uint256 upgradeValue;
    (,,,,upgradeClass, unitId, upgradeValue) = rare.getRareInfo(raffleRareId);
    
    cards.upgradeUnitMultipliers(winner, upgradeClass, unitId, upgradeValue);
    //event
    RaffleSuccessful(winner);
  }
  
  // Random enough for small contests (Owner only to prevent trial & error execution)
  function drawRandomWinner() public onlyAdmin {
    require(raffleEndTime < block.timestamp); //close it if need to test
    require(!raffleWinningTicketSelected);
        
    uint256 seed = SafeMath.add(raffleTicketsBought , block.timestamp);
    raffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, raffleTicketsBought);
    raffleWinningTicketSelected = true;
  }  

  // To allow clients to verify contestants
  function getRafflePlayers(uint256 raffleId) external constant returns (address[]) {
    return (rafflePlayers[raffleId]);
  }

    // To allow clients to verify contestants
  function getPlayersTickets(address player) external constant returns (uint256[], uint256[]) {
    TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
        
    if (playersTickets.raffleRareId == raffleRareId) {
      uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
      uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
      for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
        startIds[i] = playersTickets.ticketsBought[i].startId;
        endIds[i] = playersTickets.ticketsBought[i].endId;
      }
    }
        
    return (startIds, endIds);
  }


  // To display on website
  function getLatestRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
    return (raffleEndTime, raffleRareId, raffleTicketsBought, raffleWinner, raffleTicketThatWon);
  }    
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