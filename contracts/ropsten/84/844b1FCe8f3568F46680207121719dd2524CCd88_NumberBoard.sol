/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity ^0.4.13;

contract NumberBoard {

	struct ANumberCard {
		address			owner;
		uint			lookupIdx;
		string  		theMessage;
		bool			buyNowActive;
		uint 			buyNowPrice;
		address			currentBidder;
		uint			currentBid;
	}

	mapping(uint => ANumberCard) 	public ownership;
	mapping(address => uint[]) 		public ownershipLookup;

	uint constant					public minPrice = 1 finney;
	uint							public houseEarnings;
	mapping(address => uint)		public earnings;
	mapping(address => uint)		public deadbids;

	address houseOwner;

	event NumberTaken(uint indexed number);
	event PriceSet(uint indexed number, uint price);
	event BidPlaced(uint indexed number, uint price);
	event BidCanceled(uint indexed number, uint price);
	event BidAccepted(uint indexed number, uint price);
	event PriceAccepted(uint indexed number, uint price);

	function NumberBoard() {
		houseOwner = msg.sender;
	}

	function isOwner(address addr, uint theNum) constant returns (bool) {
		return ownership[theNum].owner == addr;
	}

	function hasOwner(uint theNum) constant returns (bool) {
		return ownership[theNum].owner > 0;
	}

	function ownedNumbers(address addr) constant returns (uint[]) {
		uint l = ownershipLookup[addr].length;
		uint[] memory ret = new uint[](l);
		for (uint i = 0; i < l; i++) {
			ret[i] = ownershipLookup[addr][i];
		}
		return ret;
	}

	function takeNumber(uint theNum) {
		require(!hasOwner(theNum));
		require(!isOwner(msg.sender, theNum));

		ownership[theNum] = ANumberCard(msg.sender, 0, "", false, 0, 0, 0);
		ownershipLookup[msg.sender].push(theNum);
		ownership[theNum].lookupIdx = ownershipLookup[msg.sender].length - 1;

		NumberTaken(theNum);
	}

	function transferNumberOwnership(uint theNum, address from, address to) private {
		require(isOwner(from, theNum));

		ANumberCard storage card = ownership[theNum];

		card.owner = to;
		uint len = ownershipLookup[from].length;
		ownershipLookup[from][card.lookupIdx] = ownershipLookup[from][len - 1];
		ownershipLookup[from].length--;

		ownershipLookup[to].push(theNum);
		ownership[theNum].lookupIdx = ownershipLookup[to].length - 1;
	}

	function updateMessage(uint theNum, string aMessage) {
		require(isOwner(msg.sender, theNum));

		ownership[theNum].theMessage = aMessage;
	}

//---------------------
// Buy now
//---------------------

	function hasBuyNowOffer(uint theNum) constant returns (bool) {
		return ownership[theNum].buyNowActive;
	}

	function canAcceptBuyNow(uint theNum, address buyer) constant returns (bool) {
		return ownership[theNum].owner != buyer && hasBuyNowOffer(theNum);
	}

	function placeBuyNowOffer(uint theNum, uint price) {
		require(isOwner(msg.sender, theNum));
		require(price >= minPrice);

		ANumberCard storage numCard = ownership[theNum];
		numCard.buyNowPrice = price;
		numCard.buyNowActive = true;

		PriceSet(theNum, price);
	}

	function cancelBuyNowOffer(uint theNum) {
		require(isOwner(msg.sender, theNum));
		cancelBuyNowOfferInternal(ownership[theNum]);
	}

	function acceptBuyNowOffer(uint theNum) payable {
		require (canAcceptBuyNow(theNum, msg.sender));
		ANumberCard storage numCard = ownership[theNum];
		require (msg.value == numCard.buyNowPrice);

		addEarnings(msg.value, numCard.owner);
		cancelBidInternal(theNum);

		transferNumberOwnership(theNum, numCard.owner, msg.sender);
		cancelBuyNowOfferInternal(numCard);

		PriceAccepted(theNum, msg.value);
	}

	function cancelBuyNowOfferInternal(ANumberCard storage numCard) private {
		numCard.buyNowPrice = 0;
		numCard.buyNowActive = false;		
	}

//---------------------
// Bidding
//---------------------

	function placeNewBid(uint theNum) payable {
		require(hasOwner(theNum));
		require(!isOwner(msg.sender, theNum));
		require(msg.value >= minPrice);

		ANumberCard storage numCard = ownership[theNum];
		require(msg.value > numCard.currentBid + minPrice);

		deadbids[numCard.currentBidder] += numCard.currentBid;

		numCard.currentBid = msg.value;
		numCard.currentBidder = msg.sender;

		BidPlaced(theNum, msg.value);
	}

	function cancelBid(uint theNum) {
		ANumberCard storage numCard = ownership[theNum];
		require(msg.sender == numCard.currentBidder);

		uint amount = numCard.currentBid;
		cancelBidInternal(theNum);
		BidCanceled(theNum, amount);
	}

	function cancelBidInternal(uint theNum) private {
		ANumberCard storage numCard = ownership[theNum];
		deadbids[numCard.currentBidder] += numCard.currentBid;
		numCard.currentBid = 0;
		numCard.currentBidder = 0;
	}

	function acceptBid(uint theNum) {
		require(isOwner(msg.sender, theNum));

		ANumberCard storage numCard = ownership[theNum];
		require(numCard.currentBid > 0);
		require(numCard.currentBidder != 0);

		uint amount = numCard.currentBid;
		addEarnings(amount, numCard.owner);
		transferNumberOwnership(theNum, numCard.owner, numCard.currentBidder);

		numCard.currentBidder = 0;
		numCard.currentBid = 0;

		BidAccepted(theNum, amount);
	}

	function addEarnings(uint amount, address to) private {
		uint interest = amount / 100;
		earnings[to] += amount - interest;
		houseEarnings += interest;
	}

	function withdrawDeadBids() {
 		uint amount = deadbids[msg.sender];
        deadbids[msg.sender] = 0;
        msg.sender.transfer(amount);
	}

	function withdrawEarnings() {
 		uint amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(amount);
	}

	function withdrawHouseEarnings() {
		require(msg.sender == houseOwner);

		uint amount = houseEarnings;
		houseEarnings = 0;
        msg.sender.transfer(amount);
	}
}