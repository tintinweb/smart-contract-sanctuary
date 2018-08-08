pragma solidity ^0.4.13;

/**
 * This contract handles the actions for every collectible on DADA...
 */

contract DadaCollectible {

  // DADA&#39;s account
  address owner;


  // starts turned off to prepare the drawings before going public
  bool isExecutionAllowed = false;

  // ERC20 token standard attributes
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  struct Offer {
      bool isForSale;
      uint drawingId;
      uint printIndex;
      address seller; 
      uint minValue;          // in ether
      address onlySellTo;     // specify to sell only to a specific person
      uint lastSellValue;
  }

  struct Bid {
      bool hasBid;
      uint drawingId;
      uint printIndex;
      address bidder;
      uint value;
  }

  struct Collectible{
    uint drawingId;
    string checkSum; // digest of the drawing, created using  SHA2
    uint totalSupply;
    uint nextPrintIndexToAssign;
    bool allPrintsAssigned;
    uint initialPrice;
    uint initialPrintIndex;
    string collectionName;
    uint authorUId; // drawing creator id 
    string scarcity; // denotes how scarce is the drawing
  }    

  // key: printIndex
  // the value is the user who owns that specific print
  mapping (uint => address) public DrawingPrintToAddress;
  
  // A record of collectibles that are offered for sale at a specific minimum value, 
  // and perhaps to a specific person, the key to access and offer is the printIndex.
  // since every single offer inside the Collectible struct will be tied to the main
  // drawingId that identifies that collectible.
  mapping (uint => Offer) public OfferedForSale;

  // A record of the highest collectible bid, the key to access a bid is the printIndex
  mapping (uint => Bid) public Bids;


  // "Hash" list of the different Collectibles available in the market place
  mapping (uint => Collectible) public drawingIdToCollectibles;

  mapping (address => uint) public pendingWithdrawals;

  mapping (address => uint256) public balances;

  // returns the balance of a particular account
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  } 

  // Events
  event Assigned(address indexed to, uint256 collectibleIndex, uint256 printIndex);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event CollectibleTransfer(address indexed from, address indexed to, uint256 collectibleIndex, uint256 printIndex);
  event CollectibleOffered(uint indexed collectibleIndex, uint indexed printIndex, uint minValue, address indexed toAddress, uint lastSellValue);
  event CollectibleBidEntered(uint indexed collectibleIndex, uint indexed printIndex, uint value, address indexed fromAddress);
  event CollectibleBidWithdrawn(uint indexed collectibleIndex, uint indexed printIndex, uint value, address indexed fromAddress);
  event CollectibleBought(uint indexed collectibleIndex, uint printIndex, uint value, address indexed fromAddress, address indexed toAddress);
  event CollectibleNoLongerForSale(uint indexed collectibleIndex, uint indexed printIndex);

  // The constructor is executed only when the contract is created in the blockchain.
  function DadaCollectible () { 
    // assigns the address of the account creating the contract as the 
    // "owner" of the contract. Since the contract doesn&#39;t have 
    // a "set" function for the owner attribute this value will be immutable. 
    owner = msg.sender;

    // Update total supply
    totalSupply = 16600;
    // Give to DADA all initial drawings
    balances[owner] = totalSupply;

    // Set the name for display purposes
    name = "DADA Collectible";
    // Set the symbol for display purposes
    symbol = "Ɖ";
    // Amount of decimals for display purposes
    decimals = 0;
  }

  // main business logic functions
  
  // buyer&#39;s functions
  function buyCollectible(uint drawingId, uint printIndex) payable {
    require(isExecutionAllowed);
    // requires the drawing id to actually exist
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) &&  (printIndex >= collectible.initialPrintIndex));
    Offer storage offer = OfferedForSale[printIndex];
    require(offer.drawingId != 0);
    require(offer.isForSale); // drawing actually for sale
    require(offer.onlySellTo == 0x0 || offer.onlySellTo == msg.sender);  // drawing can be sold to this user
    require(msg.value >= offer.minValue); // Didn&#39;t send enough ETH
    require(offer.seller == DrawingPrintToAddress[printIndex]); // Seller still owner of the drawing
    require(DrawingPrintToAddress[printIndex] != msg.sender);

    address seller = offer.seller;
    address buyer = msg.sender;

    DrawingPrintToAddress[printIndex] = buyer; // "gives" the print to the buyer

    // decrease by one the amount of prints the seller has of this particullar drawing
    balances[seller]--;
    // increase by one the amount of prints the buyer has of this particullar drawing
    balances[buyer]++;

    // launch the Transfered event
    Transfer(seller, buyer, 1);

    // transfer ETH to the seller
    // profit delta must be equal or greater than 1e-16 to be able to divide it
    // between the involved entities (art creator -> 30%, seller -> 60% and dada -> 10%)
    // profit percentages can&#39;t be lower than 1e-18 which is the lowest unit in ETH
    // equivalent to 1 wei.
    // if(offer.lastSellValue < msg.value && (msg.value - offer.lastSellValue) >= uint(0.0000000000000001) ){ commented because we&#39;re assuming values are expressed in  "weis", adjusting in relation to that
    if(offer.lastSellValue < msg.value && (msg.value - offer.lastSellValue) >= 100 ){ // assuming 100 (weis) wich is equivalent to 1e-16
      uint profit = msg.value - offer.lastSellValue;
      // seller gets base value plus 60% of the profit
      pendingWithdrawals[seller] += offer.lastSellValue + (profit*60/100); 
      // dada gets 10% of the profit
      // pendingWithdrawals[owner] += (profit*10/100);
      // dada receives 30% of the profit to give to the artist
      // pendingWithdrawals[owner] += (profit*30/100);
      // going manual for artist and dada percentages (30 + 10)
      pendingWithdrawals[owner] += (profit*40/100);
    }else{
      // if the seller doesn&#39;t make a profit of the sell he gets the 100% of the traded
      // value.
      pendingWithdrawals[seller] += msg.value;
    }
    makeCollectibleUnavailableToSale(buyer, drawingId, printIndex, msg.value);

    // launch the CollectibleBought event    
    CollectibleBought(drawingId, printIndex, msg.value, seller, buyer);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid storage bid = Bids[printIndex];
    if (bid.bidder == buyer) {
      // Kill bid and refund value
      pendingWithdrawals[buyer] += bid.value;
      Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);
    }
  }

  function alt_buyCollectible(uint drawingId, uint printIndex) payable {
    require(isExecutionAllowed);
    // requires the drawing id to actually exist
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) &&  (printIndex >= collectible.initialPrintIndex));
    Offer storage offer = OfferedForSale[printIndex];
    require(offer.drawingId == 0);
    
    require(msg.value >= collectible.initialPrice); // Didn&#39;t send enough ETH
    require(DrawingPrintToAddress[printIndex] == 0x0); // should be equal to a "null" address (0x0) since it shouldn&#39;t have an owner yet

    address seller = owner;
    address buyer = msg.sender;

    DrawingPrintToAddress[printIndex] = buyer; // "gives" the print to the buyer

    // decrease by one the amount of prints the seller has of this particullar drawing
    // commented while we decide what to do with balances for DADA
    balances[seller]--;
    // increase by one the amount of prints the buyer has of this particullar drawing
    balances[buyer]++;

    // launch the Transfered event
    Transfer(seller, buyer, 1);

    // transfer ETH to the seller
    // profit delta must be equal or greater than 1e-16 to be able to divide it
    // between the involved entities (art creator -> 30%, seller -> 60% and dada -> 10%)
    // profit percentages can&#39;t be lower than 1e-18 which is the lowest unit in ETH
    // equivalent to 1 wei.

    pendingWithdrawals[owner] += msg.value;
    
    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, buyer, msg.value, 0x0, msg.value);

    // launch the CollectibleBought event    
    CollectibleBought(drawingId, printIndex, msg.value, seller, buyer);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid storage bid = Bids[printIndex];
    if (bid.bidder == buyer) {
      // Kill bid and refund value
      pendingWithdrawals[buyer] += bid.value;
      Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);
    }
  }
  
  function enterBidForCollectible(uint drawingId, uint printIndex) payable {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] != 0x0); // Print is owned by somebody
    require(DrawingPrintToAddress[printIndex] != msg.sender); // Print is not owned by bidder
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));

    require(msg.value > 0); // Bid must be greater than 0
    // get the current bid for that print if any
    Bid storage existing = Bids[printIndex];
    // Must outbid previous bid by at least 5%. Apparently is not possible to 
    // multiply by 1.05, that&#39;s why we do it manually.
    require(msg.value >= existing.value+(existing.value*5/100));
    if (existing.value > 0) {
        // Refund the failing bid from the previous bidder
        pendingWithdrawals[existing.bidder] += existing.value;
    }
    // add the new bid
    Bids[printIndex] = Bid(true, collectible.drawingId, printIndex, msg.sender, msg.value);
    CollectibleBidEntered(collectible.drawingId, printIndex, msg.value, msg.sender);
  }

  // used by a user who wants to cancell a bid placed by her/him
  function withdrawBidForCollectible(uint drawingId, uint printIndex) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    require(DrawingPrintToAddress[printIndex] != 0x0); // Print is owned by somebody
    require(DrawingPrintToAddress[printIndex] != msg.sender); // Print is not owned by bidder
    Bid storage bid = Bids[printIndex];
    require(bid.bidder == msg.sender);
    CollectibleBidWithdrawn(drawingId, printIndex, bid.value, msg.sender);

    uint amount = bid.value;
    Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);
    // Refund the bid money
    msg.sender.transfer(amount);
  }

  // seller&#39;s functions
  function offerCollectibleForSale(uint drawingId, uint printIndex, uint minSalePriceInWei) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    uint lastSellValue = OfferedForSale[printIndex].lastSellValue;
    OfferedForSale[printIndex] = Offer(true, collectible.drawingId, printIndex, msg.sender, minSalePriceInWei, 0x0, lastSellValue);
    CollectibleOffered(drawingId, printIndex, minSalePriceInWei, 0x0, lastSellValue);
  }

  function withdrawOfferForCollectible(uint drawingId, uint printIndex){
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));

    uint lastSellValue = OfferedForSale[printIndex].lastSellValue;

    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, msg.sender, 0, 0x0, lastSellValue);
    // launch the CollectibleNoLongerForSale event 
    CollectibleNoLongerForSale(collectible.drawingId, printIndex);

  }

  function offerCollectibleForSaleToAddress(uint drawingId, uint printIndex, uint minSalePriceInWei, address toAddress) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    uint lastSellValue = OfferedForSale[printIndex].lastSellValue;
    OfferedForSale[printIndex] = Offer(true, collectible.drawingId, printIndex, msg.sender, minSalePriceInWei, toAddress, lastSellValue);
    CollectibleOffered(drawingId, printIndex, minSalePriceInWei, toAddress, lastSellValue);
  }

  function acceptBidForCollectible(uint drawingId, uint minPrice, uint printIndex) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    address seller = msg.sender;

    Bid storage bid = Bids[printIndex];
    require(bid.value > 0); // Will be zero if there is no actual bid
    require(bid.value >= minPrice); // Prevent a condition where a bid is withdrawn and replaced with a lower bid but seller doesn&#39;t know

    DrawingPrintToAddress[printIndex] = bid.bidder;
    balances[seller]--;
    balances[bid.bidder]++;
    Transfer(seller, bid.bidder, 1);
    uint amount = bid.value;

    Offer storage offer = OfferedForSale[printIndex];
    // transfer ETH to the seller
    // profit delta must be equal or greater than 1e-16 to be able to divide it
    // between the involved entities (art creator -> 30%, seller -> 60% and dada -> 10%)
    // profit percentages can&#39;t be lower than 1e-18 which is the lowest unit in ETH
    // equivalent to 1 wei.
    // if(offer.lastSellValue > msg.value && (msg.value - offer.lastSellValue) >= uint(0.0000000000000001) ){ commented because we&#39;re assuming values are expressed in  "weis", adjusting in relation to that
    if(offer.lastSellValue < amount && (amount - offer.lastSellValue) >= 100 ){ // assuming 100 (weis) wich is equivalent to 1e-16
      uint profit = amount - offer.lastSellValue;
      // seller gets base value plus 60% of the profit
      pendingWithdrawals[seller] += offer.lastSellValue + (profit*60/100); 
      // dada gets 10% of the profit
      // pendingWithdrawals[owner] += (profit*10/100);
      // dada receives 30% of the profit to give to the artist
      // pendingWithdrawals[owner] += (profit*30/100);
      pendingWithdrawals[owner] += (profit*40/100);

    }else{
      // if the seller doesn&#39;t make a profit of the sell he gets the 100% of the traded
      // value.
      pendingWithdrawals[seller] += amount;
    }
    // does the same as the function makeCollectibleUnavailableToSale
    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, bid.bidder, 0, 0x0, amount);
    CollectibleBought(collectible.drawingId, printIndex, bid.value, seller, bid.bidder);
    Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);

  }

  // used by a user who wants to cashout his money
  function withdraw() {
    require(isExecutionAllowed);
    uint amount = pendingWithdrawals[msg.sender];
    // Remember to zero the pending refund before
    // sending to prevent re-entrancy attacks
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

  // Transfer ownership of a punk to another user without requiring payment
  function transfer(address to, uint drawingId, uint printIndex) returns (bool success){
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    // checks that the user making the transfer is the actual owner of the print
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    makeCollectibleUnavailableToSale(to, drawingId, printIndex, OfferedForSale[printIndex].lastSellValue);
    // sets the new owner of the print
    DrawingPrintToAddress[printIndex] = to;
    balances[msg.sender]--;
    balances[to]++;
    Transfer(msg.sender, to, 1);
    CollectibleTransfer(msg.sender, to, drawingId, printIndex);
    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid storage bid = Bids[printIndex];
    if (bid.bidder == to) {
      // Kill bid and refund value
      pendingWithdrawals[to] += bid.value;
      Bids[printIndex] = Bid(false, drawingId, printIndex, 0x0, 0);
    }
    return true;
  }

  // utility functions
  function makeCollectibleUnavailableToSale(address to, uint drawingId, uint printIndex, uint lastSellValue) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, to, 0, 0x0, lastSellValue);
    // launch the CollectibleNoLongerForSale event 
    CollectibleNoLongerForSale(collectible.drawingId, printIndex);
  }

  function newCollectible(uint drawingId, string checkSum, uint256 _totalSupply, uint initialPrice, uint initialPrintIndex, string collectionName, uint authorUId, string scarcity){
    // requires the sender to be the same address that compiled the contract,
    // this is ensured by storing the sender address
    // require(owner == msg.sender);
    require(owner == msg.sender);
    // requires the drawing to not exist already in the scope of the contract
    require(drawingIdToCollectibles[drawingId].drawingId == 0);
    drawingIdToCollectibles[drawingId] = Collectible(drawingId, checkSum, _totalSupply, initialPrintIndex, false, initialPrice, initialPrintIndex, collectionName, authorUId, scarcity);
  }

  function flipSwitchTo(bool state){
    // require(owner == msg.sender);
    require(owner == msg.sender);
    isExecutionAllowed = state;
  }

  function mintNewDrawings(uint amount){
    require(owner == msg.sender);
    totalSupply = totalSupply + amount;
    balances[owner] = balances[owner] + amount;

    Transfer(0, owner, amount);
  }

}