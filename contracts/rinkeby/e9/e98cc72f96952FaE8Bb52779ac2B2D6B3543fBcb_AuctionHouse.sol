// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface ILANDXNFT is IERC165 {
	function landArea(uint256 id) external view returns (uint256);

	function landOwner(uint256 id) external view returns (address);

    function rent(uint256 id) external view returns (uint256);

	function shardManager(uint256 id) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface ISHARDMANAGER is IERC165 {
	function symbol() external view returns (string memory);
}

interface IRENTFOUNDATION is IERC165 {
    function initialRentApplied(uint256 tokenID) external view returns(bool);
	function payInitialRent(address payer, uint256 tokenID, uint256 amount) external;
}

interface IWTCMINTFOUNDATION is IERC165 {
    function distributeAfterSell(uint256 tokenID, address to) external;
}

contract AuctionHouse is Ownable, Pausable {
	uint256 marketFeeWTC = 300; //3%

	uint256 USD_WTC_Rate = 50; // for now it hardcoded

	uint256 WheatPrice = 27;
	uint256 RicePrice = 70;
	uint256 MaizePrice = 29;
	uint256 SoyPrice = 56;

	uint256 public auctionBoost = 5 minutes;
	uint256 public tickWTC = 1; //bidding tick for WTC

	uint256 public auctionCount = 0;
	uint256 public sellsCount = 0;
	uint256 public offersCount = 0;

	uint256 public maxOfferDuration = 180 days;

	ILANDXNFT public landXNFT; //address for landXNFT
	IERC20 public wtc; //erc20 WTC

	IRENTFOUNDATION public rentFoundation;
    IWTCMINTFOUNDATION public wtcMintFoundation;

	mapping(uint256 => SellListing) public sellListings;
	mapping(uint256 => AuctionListing) public auctions;
	mapping(uint256 => bool) public auctionActive;
	mapping(uint256 => Offer) public offers;

	event AuctionListed(
		uint256 auction_id,
		address auctioneer,
		uint256 nftID,
		uint256 startPrice,
		uint256 endTime
	);
	event BidPlaced(uint256 auction_id, address indexed bidder, uint256 price, uint256 currency, uint256 endTime);
	event AuctionWon(uint256 auction_id, uint256 highestBid, uint256 currency, address winner);
	event AuctionCanceled(uint256 auction_id, address auctioneer);

	event OnSale(uint256 sale_id, uint256 currency, uint256 itemID, uint256 price, uint256 startTime, address privacy);
	event ListingSold(uint256 itemID, uint256 price, uint256 currency, address buyer);
	event SaleCanceled(uint256 sale_id, address seller);

	event OfferMade(uint256 offer_id, uint256 nftID, address maker, uint256 price, uint256 currency, uint256 endTime);
	event OfferAccepted(uint256 offer_id, uint256 nftID, uint256 price, uint256 currency, address maker);
	event OfferCanceled(uint256 offer_id, uint256 nftID, address maker);
	event OfferDeclined(uint256 offer_id, uint256 nftID, address seller);

	struct Offer {
		uint256 nftID;
		uint256 price;
		uint256 listingID;
		address offerMaker;
		uint256 date;
		uint256 endTime;
		bool actual;
	}

	struct AuctionListing {
		address auctioneer;
		uint256 auctionId;
		uint256 nftID;
		uint256 startTime;
		uint256 endTime;
		uint256 startPrice;
		uint256 reservedPrice;
		uint256 currentBid;
		uint256 tick;
		uint256 bidCount;
		address highBidder;
		uint256 auctionPeriod;
	}

	struct SellListing {
		uint256 saleId;
		address seller;
		uint256 nftID;
		uint256 startTime;
		uint256 price;
		bool sold;
		bool removedFromSale;
		address privacy;
	}

	//nothing fancy
	constructor(
		address _landxNFT,
		address _wtc
	) {
		landXNFT = ILANDXNFT(_landxNFT);
		wtc = IERC20(_wtc);
		sellsCount = 0;
		auctionCount = 0;
	}

	function makeOffer(uint256 nftID, uint256 price, uint256 currency, uint256 listingID, uint256 duration) public whenNotPaused {
		require(duration <= maxOfferDuration, "too long duration");
		require((auctionActive[listingID] == true && auctions[listingID].nftID > 0 && auctions[listingID].nftID == nftID && auctions[listingID].endTime >= block.timestamp) || 
			(sellListings[listingID].nftID > 0 && sellListings[listingID].startTime <= block.timestamp && sellListings[listingID].removedFromSale == false && sellListings[listingID].sold == false && sellListings[listingID].nftID == nftID), "token has no active listings");

		if (sellListings[listingID].nftID > 0 && sellListings[listingID].nftID == nftID) {
			if (landXNFT.landOwner(nftID) == sellListings[listingID].seller && rentFoundation.initialRentApplied(nftID) == false) {
			     require(price > getMinimumTokenPrice(nftID), "price less then annual rent");
		    }
		} else {
			if (auctions[listingID].nftID > 0 && auctions[listingID].nftID == nftID) {
				if (landXNFT.landOwner(nftID) == auctions[listingID].auctioneer  && rentFoundation.initialRentApplied(nftID) == false) {
			    	require(price > getMinimumTokenPrice(nftID), "price less then annual rent");
		    	}
			}
		}

		Offer memory o = Offer(
			nftID,
			price,
			listingID,
			msg.sender,
			block.timestamp,
			block.timestamp + duration,
			true
		);
		
		require(wtc.transferFrom(msg.sender, address(this), price), "failed to transfer WTC");

		offers[offersCount] = o;
		offersCount = offersCount + 1;
		emit OfferMade(offersCount -1, nftID, o.offerMaker, price, 0, o.endTime);
	}

	function cancelOffer(uint256 offerID) public {
		require(offers[offerID].offerMaker == msg.sender, "only maker can cancel offer");
		require(offers[offerID].actual == true, "only actual offer can be cancelled");
		require(wtc.transfer(offers[offerID].offerMaker,  offers[offerID].price), "failed to transfer WTC");
		offers[offerID].actual = false;
		emit OfferCanceled(offerID, offers[offerID].nftID, offers[offerID].offerMaker);
	}

	function acceptOffer(uint256 offerID) public {
		require(offers[offerID].actual == true, "only actual offer can be accepted");
		require(offers[offerID].endTime >= block.timestamp, "offer is expired");
		uint256 rent = 0;
		if (sellListings[offers[offerID].listingID].nftID > 0 && sellListings[offers[offerID].listingID].nftID == offers[offerID].nftID) {
			SellListing storage sl = sellListings[offers[offerID].listingID];
			require(sl.sold == false && sl.removedFromSale == false, "listing is not active");

			if (landXNFT.landOwner(sellListings[offers[offerID].listingID].nftID) == msg.sender && !rentFoundation.initialRentApplied(sellListings[offers[offerID].listingID].nftID)) {
            	rent = getAnnualRentAmount(sellListings[offers[offerID].listingID].nftID);
            	wtcMintFoundation.distributeAfterSell(sellListings[offers[offerID].listingID].nftID, offers[offerID].offerMaker);
				rentFoundation.payInitialRent(address(0x0), sellListings[offers[offerID].listingID].nftID, rent);
        	}

			landXNFT.safeTransferFrom(address(this), offers[offerID].offerMaker, sl.nftID, 1, "");

			//transfer funds to old owner
			uint256 _fee = _calcPercentage(offers[offerID].price, marketFeeWTC);
			uint256 amountToTransfer = offers[offerID].price - _fee - rent;
			//require(wtc.transferFrom(offers[offerID].offerMaker, address(this), _fee), "failed to transfer WTC (fee)");
			require(wtc.transfer(sl.seller, amountToTransfer), "transfer failed");

			offers[offerID].actual = false;
			sellListings[sl.saleId].sold = true;
			emit OfferAccepted(offerID, sl.nftID, offers[offerID].price, 0, offers[offerID].offerMaker);
			return;
		}
		if (auctions[offers[offerID].listingID].nftID > 0 && auctions[offers[offerID].listingID].nftID == offers[offerID].nftID) {
			AuctionListing storage auction = auctions[offers[offerID].listingID];
			require(auctionActive[auction.auctionId] == true, "auction is not active");
		    require(block.timestamp < auction.endTime, "auction expired");
			
			if (landXNFT.landOwner(auctions[offers[offerID].listingID].nftID) == msg.sender && !rentFoundation.initialRentApplied(auctions[offers[offerID].listingID].nftID)) {
            	rent = getAnnualRentAmount(auctions[offers[offerID].listingID].nftID);
            	wtcMintFoundation.distributeAfterSell(auctions[offers[offerID].listingID].nftID, offers[offerID].offerMaker);
				rentFoundation.payInitialRent(address(0x0), auctions[offers[offerID].listingID].nftID, rent);
        	}
			landXNFT.safeTransferFrom(address(this), offers[offerID].offerMaker, auction.nftID, 1, "");

			//transfer funds to old owner
			uint256 _fee = _calcPercentage(offers[offerID].price, marketFeeWTC);
			uint256 amountToTransfer = offers[offerID].price - _fee - rent;
			//require(wtc.transferFrom(offers[offerID].offerMaker, address(this), _fee), "failed to transfer wtc (fee)");
			
			require(wtc.transfer(auction.auctioneer, amountToTransfer), "transfer failed");
			
			auctionActive[auction.auctionId] = false;
			offers[offerID].actual = false;
			emit OfferAccepted(offerID, auction.nftID, offers[offerID].price, 0, offers[offerID].offerMaker);
			return;
		}
	}

	function declineOffer(uint256 offerID) public {
		require(offers[offerID].actual == true, "only actual offer can be declined");
		if (sellListings[offers[offerID].listingID].nftID > 0 && sellListings[offers[offerID].listingID].nftID == offers[offerID].nftID) {
			SellListing storage sl = sellListings[offers[offerID].listingID];
			require(sl.seller == msg.sender, "only seller can decline offer");
			require(wtc.transfer(offers[offerID].offerMaker,  offers[offerID].price), "failed to transfer WTC");
			offers[offerID].actual = false;
			emit OfferDeclined(offerID, sl.nftID, sl.seller);
			return;
		}
		if (auctions[offers[offerID].listingID].nftID > 0 && auctions[offers[offerID].listingID].nftID == offers[offerID].nftID) {
			offers[offerID].actual = false;
			AuctionListing storage auction = auctions[offers[offerID].listingID];
			require(auction.auctioneer == msg.sender, "only seller can decline offer");
			require(wtc.transfer(offers[offerID].offerMaker,  offers[offerID].price), "failed to transfer WTC");
			offers[offerID].actual = false;
			emit OfferDeclined(offerID, auction.nftID, auction.auctioneer);
			return;
		}
	}

	/// @notice Create an auction listing and take custody of item
	/// @dev Note - this doesn't start the auction or the timer.
	/// @param nftID Item identifier for NFT listing types
	/// @param startPrice Starting price of auction. For auctions > 0.01 starting price, tick is set to 0.01, else it matches precision of the start price (triangular auction)
	function createAuction(
		uint256 nftID,
		uint256 startPrice,
		uint256 reservedPrice,
		uint256 currency,
		uint256 auctionPeriod
	) public whenNotPaused {
		require(startPrice >= 1, "startprice should be >= 1");
		require(reservedPrice > startPrice, "reserve price > start price");
		if (landXNFT.landOwner(nftID) == msg.sender  && rentFoundation.initialRentApplied(nftID) == false) {
			require(reservedPrice > getMinimumTokenPrice(nftID), "reserved price less then annual rent");
		}

		//transfer the NFT
		landXNFT.safeTransferFrom(msg.sender, address(this), nftID, 1, "");

		AuctionListing memory al = AuctionListing(
			msg.sender,
			auctionCount,
			nftID,
			block.timestamp,
			block.timestamp + auctionPeriod,
			startPrice,
			reservedPrice,
			0,
			0,
			0,
			address(0),
			auctionPeriod
		);

		al.tick = tickWTC;

		auctions[auctionCount] = al;
		auctionActive[auctionCount] = true;

		// event AuctionListed(
		// 		uint256 auction_id,
		// 		address auctioneer,
		// 		uint256 nftID,
		// 		uint256 startPrice,
		// 		uint256 endTime
		// 	);
		emit AuctionListed(al.auctionId, msg.sender, al.nftID, al.startPrice, al.endTime);
		auctionCount = auctionCount + 1;
	}

	/// @notice Place a bid on an auction
	/// @param auctionId uint. Which listing to place bid on.
	function bid(uint256 auctionId, uint256 bidAmount) public {
		require(auctionActive[auctionId] == true, "auctionActive[auctionId] == true");

		AuctionListing storage al = auctions[auctionId];

		require(block.timestamp < al.endTime, "auction expired");

		uint256 currentBid = al.currentBid;

		if (al.bidCount > 0) {
			require(bidAmount >= currentBid + al.tick, "bidAmount >= currentBid + al.tick");
			//refund the previous bidder
			require(wtc.transfer(al.highBidder, al.currentBid), "transfer failed");

			//for eth
			//(bool success, ) = al.highBidder.call{ value: al.currentBid }("");
			//require(success, "Address: unable to send value, recipient may have reverted");
		} else {
			require(bidAmount >= al.startPrice, "bidAmount >= al.startPrice");
		}

		//escrow tokens
	
		require(wtc.transferFrom(msg.sender, address(this), bidAmount), "failed to transfer WTC");

		//require(wtc.transfer(address(this), bidAmount), "transfer failed");
		

		al.currentBid = bidAmount;
		al.highBidder = msg.sender;
		al.bidCount = al.bidCount + 1;

		if (((al.endTime - block.timestamp) + auctionBoost) < al.auctionPeriod)
			al.endTime = al.endTime + auctionBoost;

		auctions[auctionId] = al;

		emit BidPlaced(al.auctionId, msg.sender, bidAmount, 0, al.endTime);
	}

	/// @param auctionId uint.
	function cancelAuction(uint256 auctionId) public {
		require(auctionActive[auctionId] == true, "auctionActive[auctionId] == true");
		AuctionListing storage al = auctions[auctionId];
		require(block.timestamp < al.endTime, "auction expired");
		require(al.auctioneer == msg.sender, "only the auctioneer can cancel");

		//set the auction as inactive
		auctionActive[auctionId] = false;

		//if bids, refund the money to the highest bidder
		if (al.bidCount > 0) {
			require(wtc.transfer(al.highBidder, al.currentBid), "transfer failed");
		}

		//relsease the NFT back to the auctioneer
		landXNFT.safeTransferFrom(address(this), al.auctioneer, auctions[auctionId].nftID, 1, "");

		emit AuctionCanceled(al.auctionId, al.auctioneer);
	}

	/// @notice Claim. Release the goods and send funds to auctioneer. If no bids, item is returned to auctioneer!
	/// @param auctionId uint. What listing to claim.
	function claim(uint256 auctionId) public {
		require(auctionActive[auctionId] == true, "auctionActive[auctionId] == true");

		AuctionListing storage al = auctions[auctionId];

		require(block.timestamp >= al.endTime, "ongoing auction");

		auctionActive[auctionId] = false;
		uint256 rent = 0;


		if (al.bidCount == 0) {
			//Release the item back to the auctioneer
			landXNFT.safeTransferFrom(address(this), al.auctioneer, al.nftID, 1, "");
			return; //nothing else to do
		} else {
			if (al.currentBid < al.reservedPrice) {
				require(wtc.transfer(al.highBidder, al.currentBid), "transfer failed");
				//Release the item back to the auctioneer
				landXNFT.safeTransferFrom(address(this), al.auctioneer, al.nftID, 1, "");
				
				return; //nothing else to do
			}
			//Release the item to highBidder
			landXNFT.safeTransferFrom(address(this), al.highBidder, al.nftID, 1, "");
		}
		if (landXNFT.landOwner(auctions[auctionId].nftID) == msg.sender && !rentFoundation.initialRentApplied(auctions[auctionId].nftID)) {
            rent = getAnnualRentAmount(auctions[auctionId].nftID);
            wtcMintFoundation.distributeAfterSell(auctions[auctionId].nftID, auctions[auctionId].highBidder);
			rentFoundation.payInitialRent(address(0x0), auctions[auctionId].nftID, rent);
        }
		//Release the funds to auctioneer
		uint256 _fee = _calcPercentage(al.currentBid, marketFeeWTC);
		uint256 amtForAuctioneer = al.currentBid - _fee - rent;
		require(wtc.transfer(al.auctioneer, amtForAuctioneer), "transfer failed");

		emit AuctionWon(auctionId, al.currentBid, 0, al.highBidder);
	}

	/// @notice Returns time left in seconds or 0 if auction is over or not active.
	/// @param auctionId uint. Which auction to query.
	function getTimeLeft(uint256 auctionId) public view returns (uint256) {
		require(auctionId < auctionCount);
		uint256 time = block.timestamp;

		AuctionListing memory al = auctions[auctionId];

		return (time > al.endTime) ? 0 : al.endTime - time;
	}

	//puts an NFT for a simple sale
	//must be approved for all
	//saleDurationInSeconds - if you go over it, the sale is canceled and the nft must be removeFromSale
	function putForSale(
		uint256 currency,
		uint256 nftID,
		uint256 price,
		uint256 startTime,
		address privacy
	) public whenNotPaused returns (uint256) {
		if (startTime == 0 || startTime < block.timestamp) {
			startTime = block.timestamp;
		}

		if (landXNFT.landOwner(nftID) == msg.sender) {
			require(price > getMinimumTokenPrice(nftID), "price less then annual rent");
		}

		//transfer the NFT
		landXNFT.safeTransferFrom(msg.sender, address(this), nftID, 1, "");

		//update the storage
		SellListing memory sl = SellListing(
			sellsCount,
			msg.sender,
			nftID,
			startTime,
			price,
			false,
			false,
			privacy
		);

		sellListings[sellsCount] = sl;
		emit OnSale(sellsCount, 0, nftID, price, startTime, privacy);
		sellsCount = sellsCount + 1;
		return sellsCount - 1; //return the saleID
	}

	//removeFromSale returs the item to the owner
	//a seller can remove an item put for sale anytime
	function removeFromSale(uint256 saleID) public {
		SellListing storage sl = sellListings[saleID];
		require(sl.sold == false, "can't claim a sold item");
		require(msg.sender == sl.seller, "only the seller can remove it");

		sl.removedFromSale = true;

		//Release the item back to the auctioneer
		landXNFT.safeTransferFrom(address(this), msg.sender, sl.nftID, 1, "");
		emit SaleCanceled(sl.saleId, sl.seller);
	}

	// buys an NFT from a sale
	function buyItem(uint256 saleID) public {
		SellListing storage sl = sellListings[saleID];
		require(block.timestamp >= sl.startTime, "sale period didn't start");
		require(sl.sold == false, "can't buy a sold item");

		if (sl.privacy != address(0)) {
			require(msg.sender == sl.privacy, "this listing is private");
		}

		uint256 rent = 0;

		if (landXNFT.landOwner(sl.nftID) == msg.sender && !rentFoundation.initialRentApplied(sl.nftID)) {
            rent = getAnnualRentAmount(sl.nftID);
            wtcMintFoundation.distributeAfterSell(sl.nftID, msg.sender);
			rentFoundation.payInitialRent(msg.sender, sl.nftID, rent);
        }

			//WTC
		uint256 _fee = _calcPercentage(sl.price, marketFeeWTC);
		uint256 amtForSeller = sl.price - _fee - rent;

		//transfer all the WTC token to the smart contract
		require(wtc.transferFrom(msg.sender, address(this), _fee), "failed to transfer WTC (fee)");
		require(wtc.transferFrom(msg.sender, sl.seller, amtForSeller), "failed to transfer WTC");

		//transfer the tokens
		landXNFT.safeTransferFrom(address(this), msg.sender, sl.nftID, 1, "");

		sl.sold = true;
		emit ListingSold(sl.nftID, sl.price, 0, msg.sender);
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes memory
	) external pure returns (bytes4) {
		return 0xf23a6e61;
	}

	// withdraw the ETH from this contract (ONLY OWNER). not needed...
	function withdrawETH(uint256 amount) external onlyOwner {
		(bool success, ) = msg.sender.call{ value: amount }("");
		require(success, "transfer failed.");
	}

	//get tokens back. emergency use only.
	function reclaimERC20(address _tokenContract) external onlyOwner {
		IERC20 token = IERC20(_tokenContract);
		uint256 balance = token.balanceOf(address(this));
		require(token.transfer(msg.sender, balance), "transfer failed");
	}

	//get NFT back. emergency use only.
	function reclaimNFT(uint256 _nftID) external onlyOwner {
		landXNFT.safeTransferFrom(address(this), msg.sender, _nftID, 1, "");
	}

	// changes the market fee. 50 = 0.5%
	function changeMarketFeeWTC(uint256 _marketFee) public onlyOwner {
		require(_marketFee < 500, "anti greed protection");
		marketFeeWTC = _marketFee;
	}

	//300 = 3%, 1 = 0.01%
	function _calcPercentage(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
		require(basisPoints >= 0);
		return (amount * basisPoints) / 10000;
	}

	// sets the paused / unpaused state
	function setPaused(bool _setPaused) public onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	//set bid Tick
	function setBidTickWTC(uint256 _newTick) public onlyOwner {
		tickWTC = _newTick;
	}

	function setRentFoundation(address _address) public onlyOwner {
        rentFoundation = IRENTFOUNDATION(_address);
    }

    function setWTCMintFoundation(address _address) public onlyOwner {
        wtcMintFoundation = IWTCMINTFOUNDATION(_address);
    }

	function getAnnualRentAmount(uint256 tokenID)  internal view returns (uint256)
	{
		uint256 rent = landXNFT.rent(tokenID);
		uint256 area = landXNFT.landArea(tokenID);
		ISHARDMANAGER shardManager = ISHARDMANAGER(landXNFT.shardManager(tokenID));
		string memory grainType = shardManager.symbol();
		uint256 price = 0;
		if (keccak256(abi.encodePacked(grainType)) == keccak256(abi.encodePacked("LDXS"))) {
			price = SoyPrice;
		}
		if (keccak256(abi.encodePacked(grainType)) == keccak256(abi.encodePacked("LDXR"))) {
			price = RicePrice;
		}
		if (keccak256(abi.encodePacked(grainType)) == keccak256(abi.encodePacked("LDXM"))) {
			price = MaizePrice;
		}
		if (keccak256(abi.encodePacked(grainType)) == keccak256(abi.encodePacked("LDXW"))) {
			price = WheatPrice;
		}

		return 2 * (price * rent * USD_WTC_Rate * area * (10**uint256(18))) / (10000 * 100 * 100);
	}

	function getMinimumTokenPrice(uint256 tokenID) public view returns (uint256)
	{
		if (rentFoundation.initialRentApplied(tokenID)) {
			return 0;
		}
		uint256 annualRent = getAnnualRentAmount(tokenID);
		return 10000 * annualRent / (10000 - marketFeeWTC);
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}