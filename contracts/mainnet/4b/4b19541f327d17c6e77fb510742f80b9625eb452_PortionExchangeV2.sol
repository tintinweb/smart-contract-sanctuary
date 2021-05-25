// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "./IERC721.sol";
import "./IERC20.sol";
import './IERC1155.sol';

contract PortionExchangeV2 {
	struct ERC1155Offer {
		uint tokenId;
		uint quantity;
		uint price;
		address seller;
	}

	event TokenPriceListed (uint indexed _tokenId, address indexed _owner, uint _price);
	event TokenPriceDeleted (uint indexed _tokenId);
	event TokenSold (uint indexed _tokenId, uint _price, bool _soldForPRT);
	event TokenOwned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner);
	event Token1155OfferListed (uint indexed _tokenId, uint indexed _offerId, address indexed _owner, uint _quantity, uint _price);
	event Token1155OfferDeleted (uint indexed _tokenId, uint indexed _offerId);
	event Token1155Sold(uint indexed _tokenId, uint indexed _offerId, uint _quantity, uint _price, bool _soldForPRT);
	event Token1155Owned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner, uint _quantity);

	address public signer;
	address owner;

	bytes32 public name = "PortionExchangeV2";

	uint public offerIdCounter;

	IERC20 public portionTokenContract;
	IERC721 public artTokenContract;
	IERC1155 public artToken1155Contract;

	mapping(address => uint) public nonces;
	mapping(uint => uint) public ERC721Prices;
	mapping(uint => ERC1155Offer) public ERC1155Offers;
	mapping(address => mapping(uint => uint)) public tokensListed;

	constructor (
		address _signer,
		address _artTokenAddress,
		address _artToken1155Address,
		address _portionTokenAddress
	)
	{
		require (_signer != address(0));
		require (_artTokenAddress != address(0));
		require (_artToken1155Address != address(0));
		require (_portionTokenAddress != address(0));

		owner = msg.sender;
		signer = _signer;
		artTokenContract = IERC721(_artTokenAddress);
		artToken1155Contract = IERC1155(_artToken1155Address);
		portionTokenContract = IERC20(_portionTokenAddress);
	}

	function listToken(
		uint _tokenId,
		uint _price
	)
	external
	{
		require(_price > 0);
		require(artTokenContract.ownerOf(_tokenId) == msg.sender);
		ERC721Prices[_tokenId] = _price;
		emit TokenPriceListed(_tokenId, msg.sender, _price);
	}

	function listToken1155(
		uint _tokenId,
		uint _quantity,
		uint _price
	)
	external
	{
		require(_price > 0);
		require(artToken1155Contract.balanceOf(msg.sender, _tokenId) >= tokensListed[msg.sender][_tokenId] + _quantity);

		uint offerId = offerIdCounter++;
		ERC1155Offers[offerId] = ERC1155Offer({
			tokenId: _tokenId,
			quantity: _quantity,
			price: _price,
			seller: msg.sender
		});

		tokensListed[msg.sender][_tokenId] += _quantity;
		emit Token1155OfferListed(_tokenId, offerId, msg.sender, _quantity, _price);
	}

	function removeListToken(
		uint _tokenId
	)
	external
	{
		require(artTokenContract.ownerOf(_tokenId) == msg.sender);
		deleteTokenPrice(_tokenId);
	}

	function removeListToken1155(
		uint _offerId
	)
	external
	{
		require(ERC1155Offers[_offerId].seller == msg.sender);
		deleteToken1155Offer(_offerId);
	}

	function deleteTokenPrice(
		uint _tokenId
	)
	internal
	{
		delete ERC721Prices[_tokenId];
		emit TokenPriceDeleted(_tokenId);
	}

	function deleteToken1155Offer(
		uint _offerId
	)
	internal
	{
		ERC1155Offer memory offer = ERC1155Offers[_offerId];
		tokensListed[offer.seller][offer.tokenId] -= offer.quantity;

		delete ERC1155Offers[_offerId];
		emit Token1155OfferDeleted(offer.tokenId, _offerId);
	}

	function buyToken(
		uint _tokenId
	)
	external
	payable
	{
		require(ERC721Prices[_tokenId] > 0, "token is not for sale");
		require(ERC721Prices[_tokenId] <= msg.value);

		address tokenOwner = artTokenContract.ownerOf(_tokenId);

		address payable payableTokenOwner = payable(tokenOwner);
		(bool sent, ) = payableTokenOwner.call{value: msg.value}("");
		require(sent);

		artTokenContract.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

		emit TokenSold(_tokenId, msg.value, false);
		emit TokenOwned(_tokenId, tokenOwner, msg.sender);

		deleteTokenPrice(_tokenId);
	}

	function buyToken1155(
		uint _offerId,
		uint _quantity
	)
	external
	payable
	{
		ERC1155Offer memory offer = ERC1155Offers[_offerId];

		require(offer.price > 0, "offer does not exist");
		require(offer.quantity >= _quantity);
		require(offer.price * _quantity <= msg.value);

		address payable payableSeller = payable(offer.seller);
		(bool sent, ) = payableSeller.call{value: msg.value}("");
		require(sent);

		artToken1155Contract.safeTransferFrom(offer.seller, msg.sender, offer.tokenId, _quantity, "");

		emit Token1155Sold(offer.tokenId, _offerId, _quantity, offer.price, false);
		emit Token1155Owned(offer.tokenId, offer.seller, msg.sender, _quantity);

		if (offer.quantity == _quantity) {
			deleteToken1155Offer(_offerId);
		} else {
			ERC1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function buyTokenForPRT(
		uint _tokenId,
		uint _amountOfPRT,
		uint _nonce,
		bytes calldata _signature
	)
	external
	{
		require(ERC721Prices[_tokenId] > 0, "token is not for sale");

		require(nonces[msg.sender] < _nonce, "invalid nonce");
		nonces[msg.sender] = _nonce;

		bytes32 hash = keccak256(abi.encodePacked(_tokenId, _amountOfPRT, _nonce));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		require(recoverSignerAddress(ethSignedMessageHash, _signature) == signer, "invalid secret signer");

		address tokenOwner = artTokenContract.ownerOf(_tokenId);

		bool sent = portionTokenContract.transferFrom(msg.sender, tokenOwner, _amountOfPRT);
		require(sent);

		artTokenContract.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

		emit TokenSold(_tokenId, _amountOfPRT, true);
		emit TokenOwned(_tokenId, tokenOwner, msg.sender);

		deleteTokenPrice(_tokenId);
	}

	function buyToken1155ForPRT(
		uint _offerId,
		uint _quantity,
		uint _amountOfPRT,
		uint _nonce,
		bytes calldata _signature
	)
	external
	{
		ERC1155Offer memory offer = ERC1155Offers[_offerId];

		require(offer.price > 0, "offer does not exist");
		require(offer.quantity >= _quantity);

		require(nonces[msg.sender] < _nonce, "invalid nonce");
		nonces[msg.sender] = _nonce;

		bytes32 hash = keccak256(abi.encodePacked(_offerId, _quantity, _amountOfPRT, _nonce));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		require(recoverSignerAddress(ethSignedMessageHash, _signature) == signer, "invalid secret signer");

		portionTokenContract.transferFrom(msg.sender, offer.seller, _amountOfPRT * _quantity);
		artToken1155Contract.safeTransferFrom(offer.seller, msg.sender, offer.tokenId, _quantity, "");

		emit Token1155Sold(offer.tokenId, _offerId, _quantity, _amountOfPRT, true);
		emit Token1155Owned(offer.tokenId, offer.seller, msg.sender, _quantity);

		if (offer.quantity == _quantity) {
			deleteToken1155Offer(_offerId);
		} else {
			ERC1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function setSigner(
		address _newSigner
	)
	external
	{
		require(msg.sender == owner);
		signer = _newSigner;
	}

	function recoverSignerAddress(
		bytes32 _hash,
		bytes memory _signature
	)
	internal
	pure
	returns (address)
	{
		require(_signature.length == 65, "invalid signature length");

		bytes32 r;
		bytes32 s;
		uint8 v;

		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := and(mload(add(_signature, 65)), 255)
		}

		if (v < 27) {
			v += 27;
		}

		if (v != 27 && v != 28) {
			return address(0);
		}

		return ecrecover(_hash, v, r, s);
	}
}