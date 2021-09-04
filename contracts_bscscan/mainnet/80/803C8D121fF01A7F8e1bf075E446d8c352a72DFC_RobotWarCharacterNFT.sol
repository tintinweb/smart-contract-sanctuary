// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./token-ERC721-ERC721.sol";
import "./access-Ownable.sol";
import "./tokens-nf-infomation.sol";
import "./token-character.sol";
import "./token-ERC721-extensions-ERC721Burnable.sol";
import "./token-ERC721-extensions-ERC721Enumerable.sol";

contract RobotWarCharacterNFT is ERC721, Ownable, infomation, ERC721Burnable, ERC721Enumerable {
	uint256 public tradeLockTime = 5 * 60;
    address private eventAdrress;
    address private marketer;
    address private operator;
    bool private isEnableTrade = true;
    uint256 newestTokenID = 0;
	uint256 private numberCharacter = 8;
	bool private isCheckMaximumCharacter = true;
    
    // Mapping from token ID to banstatus
    mapping(uint256 => bool) private _bans;
    mapping(address => bool) private _ownerbans;
    mapping(uint256 => uint256) private _allowTradingTime;
    mapping(address => bool) private _allowForTrading;
	
	modifier isEventAdrress() {
		require(msg.sender == eventAdrress, "Service for event only");
		_;
	}
	
	modifier isMarketer() {
		require(msg.sender == marketer, "Service for marketer only");
		_;
	}
	
	modifier isOperator() {
		require(msg.sender == operator, "Service for marketer only");
		_;
	}
	
	modifier isAllowCall() {
		require(msg.sender == operator||msg.sender == marketer||msg.sender == eventAdrress, "Service for marketer only");
		_;
	}
    
    constructor() ERC721("RobotWars Character NFT", "WARC") {
		eventAdrress = msg.sender;
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
			require(balanceOf(to) < numberCharacter, "NFT: Max character");

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
    
    function evolve( address _to) external isOperator {
        newestTokenID ++;
        _allowTradingTime[newestTokenID] = block.timestamp - 3600;
		super._safeMint(_to, newestTokenID);
		initNFT(newestTokenID);
	}

	function hatch(uint256 _tokenId, uint256 _rare, uint256 _class) external isOperator{
		doHatch(_tokenId, _rare, _class);
	}
	
	function doneCombat(uint256 _tokenId, uint256 _receivedExp) external isOperator returns (uint256, uint256){
		require(!getSaleInfo(_tokenId), "NFT: on sale");
		return doCombat(_tokenId, _receivedExp);
	}
	
	function doUpdateRegenerateStaminaTime(uint256 _regenerateStaminaTime) external onlyOwner{
		updateRegenerateStaminaTime(_regenerateStaminaTime);
	}
	
	function doAddMoreStamina(uint256 _tokenId , uint256 staminaAdd) external isAllowCall{
		addMoreStamina( _tokenId , staminaAdd);
	}

	function dopUpdateExp(uint256 _tokenId , uint256 _newExp) external isAllowCall{
		updateExp( _tokenId , _newExp);
	}
	
	function updateEventAdrress(address _eventAdrress) external onlyOwner{
		eventAdrress = _eventAdrress;
	}
	
	function doUpdateStaminaPerCombat(uint256 _staminaPerCombat) external onlyOwner{
		updateStaminaPerCombat(_staminaPerCombat);
	}
	
	function getBannerStatus(uint256 _tokenId) external view returns (bool) {
		return _bans[_tokenId];
	}
	
	function getNumberCharacter() external view returns (uint256) {
		if(isCheckMaximumCharacter)
			return numberCharacter;
		else
			return 999999999;
	}
	
	function getTimeTradable(uint256 _tokenId) external view returns (uint256) {
		return _allowTradingTime[_tokenId];
	}
	
	function updateTimeTradable(uint256 _tokenId, uint256 _tradableTime) external isMarketer{
		_allowTradingTime[_tokenId] = _tradableTime;
	}
	
	function updateOnSale(uint256 _tokenId,bool status) external isMarketer{
		_updateOnSale(_tokenId, status);
	}
	
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

	function updateNumberCharacter(uint256 _numberCharacter, bool _isCheckMaximumCharacter) external onlyOwner{
		numberCharacter = _numberCharacter;
		isCheckMaximumCharacter = _isCheckMaximumCharacter;
	}

	function updateTimeLockAfterTrade(uint256 _tradeLockTime) external onlyOwner{
		tradeLockTime = _tradeLockTime;
	}
	
	function updateBanOwnerStatus(address _owner, bool _status) external isOperator{
		_ownerbans[_owner] = _status;
	}
	
	function updateBanStatus(uint256 _tokenId,bool status) external isOperator{
		_bans[_tokenId] = status;
	}

	function includeAllowForTrading(address account) public isAllowCall {
        _allowForTrading[account] = true;
    }
    
    function excludeAllowForTrading(address account) public isAllowCall {
        _allowForTrading[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _allowForTrading[account];
    }
}