// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./token-ERC721-ERC721.sol";
import "./access-Ownable.sol";
import "./token-ERC721-extensions-ERC721Burnable.sol";
import "./token-ERC721-extensions-ERC721Enumerable.sol";
import "./BoxNFTData.sol";

contract BoxNFT is ERC721, Ownable, ERC721Burnable, ERC721Enumerable, BoxNFTData {
	uint256 public tradeLockTime = 10 * 365 * 24 * 60 * 60;
	address private marketer;
	address private operator;
	bool private isEnableTrade = true;
	uint256 newestTokenID = 0;
	uint256 private numberCharacter = 4;
	bool private isCheckMaximumCharacter = false;
	
	// Mapping from token ID to banstatus
	mapping(address => uint256) private _ownerbans;
	mapping(uint256 => uint256) private _allowTradingTime;
	mapping(address => bool) private _notAllowForTrading;
	mapping(uint256 => mapping(uint256 => uint256)) public totalNftByRare;
	mapping(uint256 => bool) public isRented;
	mapping(uint256 => uint256) public ContractTime;

	mapping(address => bool) private _authorizedAddresses;

	modifier onlyAuthorizedAccount() {
		require(_authorizedAddresses[msg.sender] || owner() == msg.sender, "NFT: Permission");
		_;
	}
	
	constructor() ERC721("DBS Boxes", "DBSB") {
		_authorizedAddresses[msg.sender] = true;
	}
	
	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable)
	{
		require(!isRented[tokenId], "NFT: Rented");
		require(isEnableTrade, "NFT: disable");
		require(_ownerbans[from] < block.timestamp, "NFT: baned");
		require(from == address(0) || !_notAllowForTrading[from] || !_notAllowForTrading[to], "NFT: Not allow");
		if(isCheckMaximumCharacter && to != address(0))
			require(balanceOf(to) < numberCharacter, "NFT: Max NFT");

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
	
	function evolve( address _to, uint256[] memory _values) external onlyAuthorizedAccount returns( uint256 ){
		require(_values.length == 3,'NFT: INVALID');
		newestTokenID ++;
		_allowTradingTime[newestTokenID] = block.timestamp - 3600;
		super._safeMint(_to, newestTokenID);
		_initAllAttribute(newestTokenID, _values);
		return newestTokenID;
	}
	/**
	 * @dev config.
	 */
	function grantPermission(address account) public onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = true;
	}

	function revokePermission(address account) public onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = false;
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

	function updateBaseURI(string memory newBaseURI) external onlyOwner{
        super.setbaseURI(newBaseURI);
    }
	
	/**
	 * Ban case.
	 */
	function banOwner(address _owner, uint256 _days) external onlyAuthorizedAccount{
		_ownerbans[_owner] = block.timestamp + _days * 86400;
	}

	function unbanOwner(address _owner) external onlyAuthorizedAccount{
		_ownerbans[_owner] = block.timestamp - 60;
	}
	
	function getOnwerBannedStatus(address _owner) external view returns (bool, uint256) {
		if(_ownerbans[_owner] > block.timestamp){
			return (true, _ownerbans[_owner]);
		}else{
			return (false, 0);
		}
	}
	/**
	 * Trade case.
	 */

	function getTimeTradable(uint256 _tokenId) external view returns (uint256) {
		return _allowTradingTime[_tokenId];
	}
	
	function updateTimeTradable(uint256 _tokenId, uint256 _tradableTime) external onlyAuthorizedAccount{
		_allowTradingTime[_tokenId] = _tradableTime;
	}
	
	function includeAllowForTrading(address account) public onlyAuthorizedAccount {
		_notAllowForTrading[account] = false;
	}
	
	function excludeAllowForTrading(address account) public onlyAuthorizedAccount {
		_notAllowForTrading[account] = true;
	}

	function getAllowForTradingStatus(address account) public view returns(bool) {
		return !_notAllowForTrading[account];
	}

	/**
	 * Info case.
	 */
	function initAllAttribute(uint256 _tokenId, uint256[] memory _values) external onlyAuthorizedAccount{
		require(_values.length == 3,'itemdata: INVALID_VALUES');
		_initAllAttribute(_tokenId, _values);
	}

	function updateAllAttribute(uint256 _tokenId, uint256[] memory _values) external onlyAuthorizedAccount{
		require(_values.length == 3,'itemdata: INVALID_VALUES');
		_updateAllAttribute(_tokenId, _values);
	}

    function updatetImg(uint256 _tokenId, uint256 _value) external onlyAuthorizedAccount {
		_updatetImg(_tokenId, _value);
	}

	function updateOpenTime(uint256 _tokenId, uint256 _value) external onlyAuthorizedAccount {
		_updateOpenTime(_tokenId, _value);
	}

	function updateCanOpenTime(uint256 _tokenId, uint256 _value) external onlyAuthorizedAccount {
		_updateCanOpenTime(_tokenId, _value);
	}
	
	function getTokenInfo(uint256 _tokenId) public view returns (uint256 img, uint256 canOpenTime, uint256 openTime){
		return _getTokenInfo(_tokenId);
	}
    
	function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory){
		return super.tokenURI(_tokenId);
	}
}