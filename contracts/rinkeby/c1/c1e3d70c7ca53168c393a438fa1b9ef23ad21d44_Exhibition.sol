// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Tools.sol";
import "./IERC1155.sol";
import "./IERC721.sol";

contract Exhibition is Ownable, WhitelistAdminRole {

	struct Card {
		address tokenAddress;
		uint8 tokenType;
		bool tradable;
		uint256 price;
		uint256 releaseTime;
		uint256 supply;
	}

	struct CardLink{
		address tokenAddress;
		uint8 tokenType;
		uint256 tokenId;
	}

	bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
	bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
	bytes4 constant internal ERC721_RECEIVED = 0x150b7a02;
	bytes4 constant internal RECEIVED_ERR_VALUE = 0x0;

	address public controller;
	address public uniftyFeeAddress;
	uint256 public uniftyFee;
	address public unifty;
	string public exhibitionUri;
	bool public isArtistExhibition;
	uint256 public version;

	mapping(address => mapping ( uint256 => Card ) ) public cards;
	CardLink[] public cardList;

	event CardAdded(address indexed tokenAddress, uint256 indexed tokenId, uint8 tokenType, uint256 amount, uint256 price, uint256 releaseTime, bool tradable);
	event Removed(address indexed tokenAddress, uint256 indexed tokenId, uint8 tokenType, address indexed recipient, uint256 amount);
	event Sold(address indexed tokenAddress, uint256 indexed tokenId, uint8 tokenType, address to, uint256 price, uint256 amount);
	event ExhibitionUri(address indexed exhibition, string uri);

	uint private unlocked = 1;

	modifier lock() {
		require(unlocked == 1, 'Exhibition: LOCKED');
		unlocked = 0;
		_;
		unlocked = 1;
	}

	constructor(bool _isArtistExhibition) {
		isArtistExhibition = _isArtistExhibition;
		unifty = msg.sender;
		uniftyFeeAddress = msg.sender;
		uniftyFee = 1500;
		version = 1;
	}

	function remove(address _tokenAddress, uint256 _tokenId, uint256 _amount, address _recipient) external lock onlyWhitelistAdmin{

		require(cards[_tokenAddress][_tokenId].tokenAddress != address(0), "Nothing to remove.");

		if(cards[_tokenAddress][_tokenId].tokenType == 0){

			_amount = 1;

			cards[_tokenAddress][_tokenId].supply = 0;

			IERC721(_tokenAddress).safeTransferFrom(address(this), _recipient, _tokenId);

		} else {

			if(cards[_tokenAddress][_tokenId].supply >= _amount){

				cards[_tokenAddress][_tokenId].supply -= _amount;
			}

			IERC1155(_tokenAddress).safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");
		}

		emit Removed(_tokenAddress, _tokenId, cards[_tokenAddress][_tokenId].tokenType, _recipient, _amount);
	}

	function add(
		address _tokenAddress,
		uint256 _tokenId,
		uint8 _tokenType,
		uint256 _amount,
		uint256 _price,
		uint256 _releaseTime,
		bool _tradable
	) external lock onlyWhitelistAdmin returns (uint256) {

		require(_amount > 0, "Invalid card amount");
		require(_tokenType == 0 || _tokenType == 1, "Invalid token type. use 0 for erc721 and 1 for erc1155.");

		Card storage c = cards[_tokenAddress][_tokenId];

		if(c.tokenAddress == address(0)){
			cardList.push(CardLink({
			tokenAddress: _tokenAddress,
			tokenType: _tokenType,
			tokenId: _tokenId
			}));
		}

		c.price = _price;
		c.releaseTime = _releaseTime;
		c.tokenAddress = _tokenAddress;
		c.tokenType = _tokenType;
		c.tradable = _tradable;

		if(_tokenType == 0){

			_amount = 1;
			c.supply = 1;
			IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

		}else{

			c.supply += _amount;
			IERC1155(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
		}

		emit CardAdded(_tokenAddress, _tokenId, _tokenType, _amount, _price, _releaseTime, _tradable);
		return _tokenId;
	}

	function update(
		address _tokenAddress,
		uint256 _tokenId,
		uint256 _price,
		uint256 _releaseTime,
		bool _tradable
	) external lock onlyWhitelistAdmin{
		require(cards[_tokenAddress][_tokenId].tokenAddress != address(0), "Nothing to update.");
		Card storage c = cards[_tokenAddress][_tokenId];
		c.price = _price;
		c.releaseTime = _releaseTime;
		c.tradable = _tradable;
	}

	function buy(address _tokenAddress, uint256 _tokenId, uint256 _amount) public payable lock {

		require(cards[_tokenAddress][_tokenId].tokenAddress != address(0), "Nothing to buy.");
		require(cards[_tokenAddress][_tokenId].tradable == true, "Not tradable.");
		require(block.timestamp >= cards[_tokenAddress][_tokenId].releaseTime, "Not released yet.");
		require(cards[_tokenAddress][_tokenId].supply >= _amount, "Insufficient funds.");
		require(msg.value == cards[_tokenAddress][_tokenId].price * _amount, "Not enough eth sent.");

		if(cards[_tokenAddress][_tokenId].tokenType == 0){

			_amount = 1;

			cards[_tokenAddress][_tokenId].supply = 0;

			IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

		} else {

			cards[_tokenAddress][_tokenId].supply -= _amount;

			IERC1155(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
		}

		uint256 fee = ( ( ( msg.value * 10**18 ) / 100 ) * uniftyFee ) / 10**20;
		payable(uniftyFeeAddress).transfer(fee);
		payable(controller).transfer(msg.value - fee);

		emit Sold(_tokenAddress, _tokenId, cards[_tokenAddress][_tokenId].tokenType, msg.sender, cards[_tokenAddress][_tokenId].price, _amount);
	}

	function reorderCards(uint256 _indexA, uint256 _indexB) external lock onlyWhitelistAdmin{
		require(cardList.length > 1 && _indexA != _indexB && _indexA < cardList.length && _indexB < cardList.length, "swapCards: invalid indexes.");
		CardLink memory linkA = cardList[_indexA];
		cardList[_indexA] = cardList[_indexB];
		cardList[_indexB] = linkA;
	}

	function deleteCard(uint256 _index) external lock onlyWhitelistAdmin{
		require(cardList.length > 0, "deleteCard: nothing to delete.");

		if(cardList[_index].tokenType == 0){

			require(
				IERC721(cardList[_index].tokenAddress).ownerOf(cardList[_index].tokenId) != address(this)
			, "deleteCard: card still contains erc721 tokens. Remove them first.");

		}else{

			require(
				IERC1155(cardList[_index].tokenAddress).balanceOf(address(this), cardList[_index].tokenId) == 0
			, "deleteCard: card still contains erc1155 tokens. Remove them first.");
		}

		cards[cardList[_index].tokenAddress][cardList[_index].tokenId].tokenAddress = address(0);
		cards[cardList[_index].tokenAddress][cardList[_index].tokenId].supply = 0;
		cardList[_index] = cardList[ cardList.length - 1 ];
		cardList.pop();
	}

	function getCard(address _tokenAddress, uint256 _tokenId) public view returns (Card memory) {
		return cards[_tokenAddress][_tokenId];
	}

	function getCardByIndex(uint256 _index) external view returns (Card memory) {
		return getCard(cardList[_index].tokenAddress, cardList[_index].tokenId);
	}

	function getCardsLength() external view returns(uint256){
		return cardList.length;
	}

	function setController(address _controller) external onlyWhitelistAdmin {
		require(address(0) != _controller, "setController: null address not allowed.");
		controller = _controller;
	}

	function setExhibitionUri(string calldata _uri) external onlyWhitelistAdmin{
		exhibitionUri = _uri;
		emit ExhibitionUri(address(this), _uri);
	}

	function setUnifty(address _address) external {
		require(msg.sender == unifty && address(0) != _address, "setUnifty: not unifty.");
		unifty = _address;
	}

	function setUniftyFeeAddress(address _feeAddress) external {
		require(msg.sender == unifty && address(0) != _feeAddress, "setUniftyFeeAddress: not unifty.");
		uniftyFeeAddress = _feeAddress;
	}

	function setUniftyFee(uint256 _fee) external {
		require(msg.sender == unifty, "setUniftyFee: not unifty.");
		uniftyFee = _fee;
	}

	function rescue721(address _tokenAddress, uint256 _tokenId, address _recipient) external{
		require(msg.sender == unifty, "rescue721: not unifty.");
		IERC721(_tokenAddress).safeTransferFrom(address(this), _recipient, _tokenId);
	}

	function rescue1155(address _tokenAddress, uint256 _tokenId, uint256 _amount, address _recipient) external{
		require(msg.sender == unifty, "rescue1155: not unifty.");
		IERC1155(_tokenAddress).safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");
	}

	function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external view returns(bytes4){

		if(IERC1155(_operator) == IERC1155(address(this))){

			return ERC1155_RECEIVED_VALUE;

		}

		return RECEIVED_ERR_VALUE;
	}

	function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external view returns(bytes4){

		if(IERC1155(_operator) == IERC1155(address(this))){

			return ERC1155_BATCH_RECEIVED_VALUE;

		}

		return RECEIVED_ERR_VALUE;
	}

	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external view returns (bytes4){

		if(IERC721(_operator) == IERC721(address(this))){

			return ERC721_RECEIVED;

		}

		return RECEIVED_ERR_VALUE;
	}
}