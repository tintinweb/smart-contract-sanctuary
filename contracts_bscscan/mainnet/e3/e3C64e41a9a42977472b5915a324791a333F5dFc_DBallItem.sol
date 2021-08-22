// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./token-ERC721-ERC721.sol";
import "./access-Ownable.sol";
import "./token-ERC721-extensions-ERC721Burnable.sol";
import "./token-ERC721-extensions-ERC721Enumerable.sol";
import "./item-data.sol";

contract DBallItem is ERC721, Ownable, ERC721Burnable, ERC721Enumerable, itemdata {
	uint256 public tradeLockTime = 24;
	address private marketer;
	address private operator;
	bool private isEnableTrade = true;
	uint256 newestTokenID = 0;
	
	// Mapping from token ID to banstatus
	mapping(uint256 => bool) private _bans;
	mapping(address => bool) private _ownerbans;
	mapping(uint256 => uint256) private _allowTradingTime;
	mapping(address => bool) private _allowForTrading;
	
	modifier isMarketer() {
		require(msg.sender == marketer, "iTemNFT: Service for marketer only");
		_;
	}
	
	modifier isOperator() {
		require(msg.sender == operator, "iTemNFT: Service for Operator only");
		_;
	}
	
	modifier isAllowCall() {
		require(msg.sender == operator||msg.sender == marketer, "iTemNFT: Service for chosen one only");
		_;
	}
	
	constructor() ERC721("DBall Item", "DBI") {
		marketer = msg.sender;
		operator = msg.sender;
	}
	
	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable)
	{
		require(isEnableTrade, "iTemNFT: Markets is disable");
		require(!(_bans[tokenId] == true), "iTemNFT: This character is baned");
		require(!(_ownerbans[from] == true), "iTemNFT: This owner is baned");
		require(_allowTradingTime[tokenId] < block.timestamp, "iTemNFT: Its not the time for trading");
		require(from != address(0) || !_allowForTrading[from] || !_allowForTrading[to], "iTemNFT: Not allow for trading");

		super._beforeTokenTransfer(from, to, tokenId);
		_allowTradingTime[tokenId] = block.timestamp + 3600 * tradeLockTime;
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
	
	function evolve( address _to, uint256[] memory _values) external isOperator	{
		require(_values.length == 6,'item: INVALID_VALUES');
		newestTokenID ++;
		_allowTradingTime[newestTokenID] = block.timestamp - 3600;
		super._safeMint(_to, newestTokenID);
		_initAllAttribute(newestTokenID, _values);
	}
	/**
	 * @dev config.
	 */
	function updateMarketer(address _marketer) external onlyOwner{
		marketer = _marketer;
	}

	function updateOperator(address _operator) external onlyOwner{
		operator = _operator;
	}

	function enableTrade() external onlyOwner{
		isEnableTrade = true;
	}

	function disableTrade() external onlyOwner{
		isEnableTrade = false;
	}
	/**
	 * Ban case.
	 */
	function banOwner(address _owner) external isOperator{
		_ownerbans[_owner] = true;
	}

	function unbanOwner(address _owner) external isOperator{
		_ownerbans[_owner] = false;
	}
	
	function banCharacter(uint256 _tokenId) external isOperator{
		_bans[_tokenId] = true;
	}

	function unbanCharacter(uint256 _tokenId) external isOperator{
		_bans[_tokenId] = false;
	}

	function getOnwerBannedStatus(address _owner) external view returns (bool) {
		return _ownerbans[_owner];
	}

	function getCharacterBannedStatus(uint256 _tokenId) external view returns (bool) {
		return _bans[_tokenId];
	}

	/**
	 * Trade case.
	 */

	function getTimeTradeable(uint256 _tokenId) external view returns (uint256) {
		return _allowTradingTime[_tokenId];
	}
	
	function updateTimeTradeable(uint256 _tokenId, uint256 _tradeableTime) external isMarketer{
		_allowTradingTime[_tokenId] = _tradeableTime;
	}
	
	function includeAllowForTrading(address account) public isAllowCall {
		_allowForTrading[account] = true;
	}
	
	function excludeAllowForTrading(address account) public isAllowCall {
		_allowForTrading[account] = false;
	}

	function getAllowForTradingStatus(address account) public view returns(bool) {
		return _allowForTrading[account];
	}

	/**
	 * Info case.
	 */
	function initAllAttribute(uint256 _tokenId, uint256[] memory _values) external isAllowCall{
		require(_values.length == 6,'itemdata: INVALID_VALUES');
		_initAllAttribute(_tokenId, _values);
	}

	function updateAllAttribute(uint256 _tokenId, uint256[] memory _values) external isAllowCall{
		require(_values.length == 6,'itemdata: INVALID_VALUES');
		_updateAllAttribute(_tokenId, _values);
	}

	function updateStamina(uint256 _tokenId, uint256 _value) external isAllowCall{
		_updateStamina(_tokenId, _value);
	}
	function updateRare(uint256 _tokenId, uint256 _value) external isAllowCall{
		_updateRare(_tokenId, _value);
	}
	function updateOption1(uint256 _tokenId, uint256 _value) external isAllowCall{
		_updateOption1(_tokenId, _value);
	}
	function updateOption2(uint256 _tokenId, uint256 _value) external isAllowCall{
		_updateOption2(_tokenId, _value);
	}
	function updateOption3(uint256 _tokenId, uint256 _value) external isAllowCall{
		_updateOption3(_tokenId, _value);
	}
	function updateOption4(uint256 _tokenId, uint256 _value) external isAllowCall{
		_updateOption4(_tokenId, _value);
	}
	function getTokenInfo(uint256 _tokenId) public view  returns (uint256,uint256,uint256,uint256,uint256,uint256) {
		return _getTokenInfo(_tokenId);
	}
}