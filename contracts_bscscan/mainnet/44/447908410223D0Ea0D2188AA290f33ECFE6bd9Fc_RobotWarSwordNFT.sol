// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./token-ERC721-ERC721.sol";
import "./access-Ownable.sol";
import "./token-ERC721-extensions-ERC721Burnable.sol";
import "./token-ERC721-extensions-ERC721Enumerable.sol";
import "./item-data.sol";

contract RobotWarSwordNFT is ERC721, Ownable, ERC721Burnable, ERC721Enumerable, itemdata {
	uint256 public tradeLockTime = 5 * 60;
	address private marketer;
	address private operator;
	bool private isEnableTrade = true;
	uint256 newestTokenID = 0;
	uint256 private numberCharacter = 100;
	bool private isCheckMaximumCharacter = false;
	
	// Mapping from token ID to banstatus
	mapping(uint256 => bool) private _bans;
	mapping(address => bool) private _ownerbans;
	mapping(uint256 => uint256) private _allowTradingTime;
	mapping(address => bool) private _allowForTrading;
	
	modifier isMarketer() {
		require(msg.sender == marketer, "NFT: Service for marketer only");
		_;
	}
	
	modifier isOperator() {
		require(msg.sender == operator, "NFT: Service for Operator only");
		_;
	}
	
	modifier isAllowCall() {
		require(
			msg.sender == operator||
			msg.sender == marketer
			, "NFT: Service is block"
		);
		_;
	}
	
	constructor() ERC721("RobotWars Sword NFT", "WARS") {
		marketer = msg.sender;
		operator = msg.sender;
	}
	
	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable)
	{
		require(isEnableTrade, "NFT: Markets is disable");
		require(!(_bans[tokenId] == true), "NFT: This character is baned");
		require(!(_ownerbans[from] == true), "NFT: This owner is baned");
		require(_allowTradingTime[tokenId] < block.timestamp, "NFT: Its not the time for trading");
		require(from != address(0) || !_allowForTrading[from] || !_allowForTrading[to], "NFT: Not allow for trading");
		if(isCheckMaximumCharacter)
			require(balanceOf(to) < numberCharacter, "NFT: Max Item");

		super._beforeTokenTransfer(from, to, tokenId);
		_allowTradingTime[tokenId] = block.timestamp + tradeLockTime;
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
	
	function evolve( address _to, uint256[] memory _values) external isOperator returns( uint256 ){
		require(_values.length == 6,'item: INVALID_VALUES');
		newestTokenID ++;
		_allowTradingTime[newestTokenID] = block.timestamp - 3600;
		super._safeMint(_to, newestTokenID);
		_initAllAttribute(newestTokenID, _values);
		return newestTokenID;
	}
	/**
	 * @dev config.
	 */
	function updateMarketer(address _marketer) external onlyOwner{
		marketer = _marketer;
	}

	function updateOperator(address newOperator) external onlyOwner{
		operator = newOperator;
	}

	function enableTrade() external onlyOwner{
		isEnableTrade = true;
	}

	function disableTrade() external onlyOwner{
		isEnableTrade = false;
	}

	function updateTimeLockAfterTrade(uint256 _tradeLockTime) external onlyOwner{
		tradeLockTime = _tradeLockTime;
	}

	function updateNumberItem(uint256 _numberCharacter, bool _isCheckMaximumCharacter) external onlyOwner{
		numberCharacter = _numberCharacter;
		isCheckMaximumCharacter = _isCheckMaximumCharacter;
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

	function getTimeTradable(uint256 _tokenId) external view returns (uint256) {
		return _allowTradingTime[_tokenId];
	}
	
	function updateTimeTradable(uint256 _tokenId, uint256 _tradableTime) external isMarketer{
		_allowTradingTime[_tokenId] = _tradableTime;
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
	function updateOnSale(uint256 _tokenId, bool _value) external isAllowCall{
		_updateOnSale(_tokenId, _value);
	}
	function getTokenInfo(uint256 _tokenId) public view  returns (uint256,uint256,uint256,uint256,uint256,uint256) {
		return _getTokenInfo(_tokenId);
	}
}