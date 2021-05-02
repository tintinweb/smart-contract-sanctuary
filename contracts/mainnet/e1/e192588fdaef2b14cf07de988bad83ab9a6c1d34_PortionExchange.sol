// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "./IERC721.sol";
import "./IERC20.sol";
import './IERC1155.sol';

contract PortionExchange {

	string name = "PortionExchange";
	address signer;
	IERC721 public artTokensContract;
	IERC1155 public artTokens1155Contract;
	IERC20 public potionTokensContract;
	uint nonceCounter = 0;

	mapping(uint => uint) public prices;

	struct Erc1155Offer {
		uint tokenId;
		uint quantity;
		uint pricePerToken;
		address seller;
	}
	Erc1155Offer[] public erc1155Offers;

	event TokenListed (uint indexed _tokenId, uint indexed _price, address indexed _owner);
	event TokenSold (uint indexed _tokenId, uint indexed _price, string indexed _currency);
	event TokenDeleted (uint indexed _tokenId, address indexed _previousOwner, uint indexed _previousPrice);
	event TokenOwned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner);

	event Token1155Listed (uint _erc1155OfferId, uint _tokenId, uint _quantity, uint _price, address _owner);
	event Token1155Deleted (
		uint _erc1155OfferId,
		uint _tokenId,
		uint _previousQuantity,
		uint _previousPrice,
		address _previousOwner
	);
	event Token1155Sold(
		uint _erc1155OfferId,
		uint _tokenId,
		uint _quantity,
		uint _price,
		string _currency,
		address _previousOwner,
		address _newOwner
	);
	constructor (address _artTokensAddress, address _artToken1155Address, address _portionTokensAddress) public {
		signer = msg.sender;
		artTokensContract = IERC721(_artTokensAddress);
		artTokens1155Contract = IERC1155(_artToken1155Address);
		potionTokensContract = IERC20(_portionTokensAddress);
		require (_artTokensAddress != address(0), "_artTokensAddress is null");
		require (_artToken1155Address != address(0), "_artToken1155Address is null");
		require (_portionTokensAddress != address(0), "_portionTokensAddress is null");
	}

	function listToken(uint _tokenId, uint _price) external {
		address owner = artTokensContract.ownerOf(_tokenId);
		require(owner == msg.sender, 'message sender is not the owner');
		prices[_tokenId] = _price;
		emit TokenListed(_tokenId, _price, msg.sender);
	}

	function listToken1155(uint _tokenId, uint _quantity, uint _price) external returns (uint) {
		require(artTokens1155Contract.balanceOf(msg.sender, _tokenId) >= _quantity, 'Not enough balance');
		uint tokenListed = 0;
		for (uint i = 0; i < erc1155Offers.length; i++) {
			if (erc1155Offers[i].seller == msg.sender && erc1155Offers[i].tokenId == _tokenId) {
				tokenListed += erc1155Offers[i].quantity;
			}
		}
		require(artTokens1155Contract.balanceOf(msg.sender, _tokenId) >= _quantity + tokenListed, 'Not enough balance');

		erc1155Offers.push(Erc1155Offer({
			tokenId: _tokenId,
			quantity: _quantity,
			pricePerToken: _price,
			seller: msg.sender
		}));
		uint offerId = erc1155Offers.length - 1;

		emit Token1155Listed(offerId, _tokenId, _quantity, _price, msg.sender);

		return offerId;
	}

	function removeListToken(uint _tokenId) external {
		address owner = artTokensContract.ownerOf(_tokenId);
		require(owner == msg.sender, 'message sender is not the owner');
		deleteToken(_tokenId, owner);
	}

	function removeListToken1155(uint _offerId) external {
		require(erc1155Offers[_offerId].seller == msg.sender, 'message sender is not the owner');
		deleteToken1155(_offerId);
	}

	function isValidBuyOrder(uint _tokenId, uint _askPrice) private view returns (bool) {
		require(prices[_tokenId] > 0, "invalid price, token is not for sale");
		return (_askPrice >= prices[_tokenId]);
	}

	function isValidBuyOrder1155(uint _offerId, uint _amount, uint _askPrice) private view returns (bool) {
		require(erc1155Offers[_offerId].pricePerToken > 0, "invalid price, token is not for sale");
		return (_askPrice >= _amount * erc1155Offers[_offerId].pricePerToken);
	}

	function deleteToken(uint _tokenId, address owner) private {
		emit TokenDeleted(_tokenId, owner, prices[_tokenId]);
		delete prices[_tokenId];
	}

	function deleteToken1155(uint _offerId) private {
		emit Token1155Deleted(_offerId, erc1155Offers[_offerId].tokenId, erc1155Offers[_offerId].quantity, erc1155Offers[_offerId].pricePerToken, erc1155Offers[_offerId].seller);
		delete erc1155Offers[_offerId];
	}

	function listingPrice(uint _tokenId) external view returns (uint) {
		return prices[_tokenId];
	}

	function listing1155Price(uint _offerId) external view returns (uint) {
		return erc1155Offers[_offerId].pricePerToken;
	}

	function buyToken(uint _tokenId, uint _nonce) external payable {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");

		require(isValidBuyOrder(_tokenId, msg.value), "invalid price");

		address owner = artTokensContract.ownerOf(_tokenId);
		address payable payableOwner = address(uint160(owner));
		payableOwner.transfer(msg.value);
		artTokensContract.safeTransferFrom(owner, msg.sender, _tokenId);
		emit TokenSold(_tokenId, msg.value, "ETH");
		emit TokenOwned(_tokenId, owner, msg.sender);
		deleteToken(_tokenId, owner);
	}

	function buyToken1155(uint _offerId, uint _quantity, uint _nonce) external payable {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");
		require(_quantity <= erc1155Offers[_offerId].quantity, "invalid quantity");

		require(isValidBuyOrder1155(_offerId, _quantity, msg.value), "invalid price");

		address owner = erc1155Offers[_offerId].seller;
		address payable payableOwner = address(uint160(owner));
		payableOwner.transfer(msg.value);
		artTokens1155Contract.safeTransferFrom(owner, msg.sender, erc1155Offers[_offerId].tokenId, _quantity, "");
		emit Token1155Sold(_offerId,
			erc1155Offers[_offerId].tokenId,
			_quantity,
			erc1155Offers[_offerId].pricePerToken,
			"ETH",
			owner,
			msg.sender
		);
		if (erc1155Offers[_offerId].quantity == _quantity) {
			deleteToken1155(_offerId);
		} else {
			erc1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function buyTokenForPRT(uint _tokenId, uint256 _amountOfPRT, uint256 _nonce, bytes calldata _signature) external {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");

		bytes32 hash = keccak256(abi.encodePacked(_tokenId, _amountOfPRT, _nonce));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		address recoveredSignerAddress = recoverSignerAddress(ethSignedMessageHash, _signature);
		require(recoveredSignerAddress == signer, "invalid secret signer"); // to be sure that the price in PRT is correct

		require(prices[_tokenId] > 0, "invalid price, token is not for sale");

		address owner = artTokensContract.ownerOf(_tokenId);
		potionTokensContract.transferFrom(msg.sender, owner, _amountOfPRT);
		artTokensContract.safeTransferFrom(owner, msg.sender, _tokenId);
		emit TokenSold(_tokenId, _amountOfPRT, "PRT");
		emit TokenOwned(_tokenId, owner, msg.sender);
		deleteToken(_tokenId, owner);
	}

	function buyArtwork1155ForPRT(uint256 _offerId, uint256 _quantity, uint256 _amountOfPRT, uint256 _nonce, bytes calldata _signature) external {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");

		bytes32 hash = keccak256(abi.encodePacked(_offerId, _quantity, _amountOfPRT, _nonce));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		address recoveredSignerAddress = recoverSignerAddress(ethSignedMessageHash, _signature);
		require(recoveredSignerAddress == signer, "invalid secret signer"); // to be sure that the price in PRT is correct

		require(erc1155Offers[_offerId].pricePerToken > 0, "invalid price, token is not for sale");

		address owner = erc1155Offers[_offerId].seller;
		potionTokensContract.transferFrom(msg.sender, owner, _amountOfPRT * _quantity);
		artTokens1155Contract.safeTransferFrom(owner, msg.sender, erc1155Offers[_offerId].tokenId, _quantity, "");
		emit Token1155Sold(_offerId,
			erc1155Offers[_offerId].tokenId,
			_quantity,
			_amountOfPRT,
			"PRT",
			owner,
			msg.sender
		);
		if (erc1155Offers[_offerId].quantity == _quantity) {
			deleteToken1155(_offerId);
		} else {
			erc1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function recoverSignerAddress(bytes32 _hash, bytes memory _signature) public pure returns (address) {
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

	function getName() external view returns (string memory) {
		return name;
	}

	function getSigner() external view returns (address) {
		return signer;
	}

	function setSigner(address _newSigner) external {
		require(msg.sender == signer, "not enough permissions to change the signer");
		signer = _newSigner;
	}

	function getNextNonce() external view returns (uint) {
		return nonceCounter + 1;
	}

	function getArtwork1155Owner(uint _offerId) external view returns (address) {
		return erc1155Offers[_offerId].seller;
	}
}