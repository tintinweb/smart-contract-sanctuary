/**
 * Smart contract to automatically escrow NFT trades.
 * You can offer a trade to some address and only if they accept it is executed.
 * 
 * Developed by @fuwafuwataimu from https://hibiki.finance/
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Auth.sol";
import "./IERC721.sol";

contract NftEscrow is Auth {

	struct BnbOffer {
		address seller;
		uint256 price;
		address buyer;
		address nft;
		uint256 id;
	}

	struct TokenOffer {
		address seller;
		address wantedNft;
		uint256 wantedNftId;
		address buyer;
		address offeredNft;
		uint256 offeredNftId;
	}

	mapping (address => bool) _outstandingTradeBnb;
	mapping (address => bool) _outstandingTradeToken;
	mapping (address => BnbOffer) _bnbOffers;
	mapping (address => TokenOffer) _tokenOffers;

	event BnbTradeOffer(address indexed seller, address indexed buyer, address indexed nft, uint256 nftId, uint256 bnbPrice);
	event NftTradeOffer(address indexed seller, address indexed buyer, address offeredNft, uint256 nftId, address wantedNft, uint256 wantedNftId);
	event BnbTradeAccepted(address indexed seller, address indexed buyer, address indexed nft, uint256 nftId, uint256 bnbPrice);
	event NftTradeAccepted(address indexed seller, address indexed buyer, address offeredNft, uint256 nftId, address wantedNft, uint256 wantedNftId);
	event BnbTradeCancelled(address indexed seller, address indexed buyer, address indexed nft, uint256 nftId, uint256 bnbPrice);
	event NftTradeCancelled(address indexed seller, address indexed buyer, address offeredNft, uint256 nftId, address wantedNft, uint256 wantedNftId);

	constructor() Auth(msg.sender) {}

	modifier noOutstanding {
		require(!_outstandingTradeBnb[msg.sender] && !_outstandingTradeToken[msg.sender], "You can only have one trade active at once!");
		_;
	}

	modifier hasOffer {
		require(_outstandingTradeBnb[msg.sender] || _outstandingTradeToken[msg.sender], "You do not have any trade offer up.");
		_;
	}

	function offerNftForBnb(address nft, uint256 tokenId, uint256 price, address to) external noOutstanding {
		_bnbOffers[msg.sender] = BnbOffer(msg.sender, price, to, nft, tokenId);
		IERC721 n = IERC721(nft);
		n.safeTransferFrom(msg.sender, address(this), tokenId);
		_outstandingTradeBnb[msg.sender] = true;

		emit BnbTradeOffer(msg.sender, to, nft, tokenId, price);
	}

	function offerNftForToken(address offeredNft, uint256 tokenId, address wantedNft, uint256 wantedId, address offerTo) external noOutstanding {
		_tokenOffers[msg.sender] = TokenOffer(msg.sender, wantedNft, wantedId, offerTo, offeredNft, tokenId);
		IERC721 n = IERC721(offeredNft);
		n.safeTransferFrom(msg.sender, address(this), tokenId);
		_outstandingTradeToken[msg.sender] = true;

		emit NftTradeOffer(msg.sender, offerTo, offeredNft, tokenId, wantedNft, wantedId);
	}

	function cancelNftForBnb() external hasOffer {
		require(_outstandingTradeBnb[msg.sender], "You have no offer to cancel.");
		BnbOffer memory offer = _bnbOffers[msg.sender];
		require(msg.sender == offer.seller);
		recoverNft(offer.seller, offer.nft, offer.id);

		emit BnbTradeCancelled(msg.sender, offer.buyer, offer.nft, offer.id, offer.price);

		_outstandingTradeBnb[msg.sender] = false;
		delete _bnbOffers[msg.sender];
	}

	function cancelNftForToken() external hasOffer {
		require(_outstandingTradeToken[msg.sender], "You have no offer to cancel.");
		TokenOffer memory offer = _tokenOffers[msg.sender];
		require(msg.sender == offer.seller);
		recoverNft(offer.seller, offer.offeredNft, offer.offeredNftId);

		emit NftTradeCancelled(msg.sender, offer.buyer, offer.offeredNft, offer.offeredNftId, offer.wantedNft, offer.wantedNftId);

		_outstandingTradeToken[msg.sender] = false;
		delete _tokenOffers[msg.sender];
	}

	function recoverNft(address owner, address nft, uint256 id) internal {
		IERC721 n = IERC721(nft);
		n.safeTransferFrom(address(this), owner, id);
	}

	function acceptNftForBnb(address seller) external payable {
		require(_outstandingTradeBnb[seller], "This address is not trading.");
		BnbOffer memory offer = _bnbOffers[seller];
		require(msg.sender == offer.buyer, "This trade offer is not for you.");
		require(msg.value == offer.price, "You did not pay enough.");
		uint256 price = msg.value;
		IERC721 n = IERC721(offer.nft);
		n.safeTransferFrom(address(this), msg.sender, offer.id);
		payable(seller).transfer(price);

		emit BnbTradeAccepted(seller, msg.sender, offer.nft, offer.id, offer.price);

		_outstandingTradeBnb[seller] = false;
		delete _bnbOffers[seller];
	}

	function acceptNftForToken(address seller) external {
		require(_outstandingTradeToken[seller], "This address is not trading.");
		TokenOffer memory offer = _tokenOffers[seller];
		require(msg.sender == offer.buyer, "This trade offer is not for you.");
		IERC721 offerNft = IERC721(offer.offeredNft);
		IERC721 accepterNft = IERC721(offer.wantedNft);
		offerNft.safeTransferFrom(address(this), msg.sender, offer.offeredNftId);
		accepterNft.safeTransferFrom(msg.sender, seller, offer.wantedNftId);

		emit NftTradeAccepted(seller, msg.sender, offer.offeredNft, offer.offeredNftId, offer.wantedNft, offer.wantedNftId);

		_outstandingTradeToken[seller] = false;
		delete _tokenOffers[seller];
	}

	function forceRecoverNftForBnb(address owner) external authorized {
		BnbOffer memory offer = _bnbOffers[owner];
		recoverNft(offer.seller, offer.nft, offer.id);

		emit BnbTradeCancelled(msg.sender, offer.buyer, offer.nft, offer.id, offer.price);

		_outstandingTradeBnb[msg.sender] = false;
		delete _bnbOffers[msg.sender];
	}

	function forceRecoverNftForToken(address owner) external authorized {
		TokenOffer memory offer = _tokenOffers[owner];
		recoverNft(offer.seller, offer.offeredNft, offer.offeredNftId);

		emit NftTradeCancelled(msg.sender, offer.buyer, offer.offeredNft, offer.offeredNftId, offer.wantedNft, offer.wantedNftId);

		_outstandingTradeToken[msg.sender] = false;
		delete _tokenOffers[msg.sender];
	}

	/**
	 * We are compliant with IERC721Receiver
	 */
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4) {
        return 0x150b7a02;
    }
}