// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract JCorp is ERC721Enumerable, Ownable {
	using Strings for uint256;
	
	event BaseURIChanged(string newBaseURI);
	event TokenPriceChanged(uint256 newTokenPrice);
	event TreasuryChanged(address newTreasury);
	
	event SaleConfigChanged(uint256 startTime, uint256 maxMintCountPerTX, uint256 maxMintCountPerOwner);
	event PresaleConfigChanged(uint256 startTime, uint256 endTime);
	event SaleTokens(address minter, uint256 mintAmount);
	event PresaleTokens(address minter, uint256 mintAmount);
	
	uint256 public JCORP_GIFT = 150;
	uint256 public JCORP_PUBLIC = 9850;
	uint256 public JCORP_MAX = JCORP_GIFT + JCORP_PUBLIC;
	uint256 public tokenPrice;
	
	uint256 public totalGiftSupply;
	uint256 public totalPublicSupply;
	
	struct SaleConfig {
        uint256 startTime;
        uint256 maxMintCountPerTX;
		uint256 maxMintCountPerOwner;
    }
	struct PresaleConfig {
        uint256 startTime;
		uint256 endTime;
    }
	struct AllowListArray {
		address owner;
		uint256 maxMintCount;
    }
	struct AllowListConfig {
		bool isAllowed;
        uint256 currentMintCount;
		uint256 maxMintCount;
    }
	
	mapping(address => AllowListConfig) public _allowListTab;
	SaleConfig public saleConfig;
	PresaleConfig public presaleConfig;
	
	string public baseURI;
	
	address payable public treasury;	
	
	
    constructor(
		string memory _name,
		string memory _symbol,
		uint256 _tokenPrice
    ) ERC721(_name, _symbol) {
		tokenPrice = _tokenPrice;
    }
	
	
	function giftTokens(address[] calldata to) external onlyOwner {
		require(totalSupply() < JCORP_MAX, "All tokens have been minted");
		require(totalGiftSupply + to.length <= JCORP_GIFT, 'Not enough tokens left to gift');

		for(uint256 i = 0; i < to.length; i++) {
			totalGiftSupply += 1;
			_safeMint(to[i], totalGiftSupply);
		}
	}
	
	function mintAllowListTokens(uint256 _mintCount) external payable {
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(_presaleConfig.startTime > 0, "Presale not configured");
		
		require(treasury != address(0), "Treasury not set");
		require(tokenPrice > 0, "Token price not set");
		require(_mintCount > 0, "Invalid mint count");
		require(block.timestamp >= _presaleConfig.startTime, "Presale not started");
		require(block.timestamp < _presaleConfig.endTime, "Presale ended");
		
		require(_allowListTab[msg.sender].isAllowed, 'You are not on the Allow List');
		require(_allowListTab[msg.sender].currentMintCount + _mintCount <= _allowListTab[msg.sender].maxMintCount, 'Purchase would exceed max allowed');
		
		require(totalSupply() < JCORP_MAX, "All tokens have been minted");
		require(totalPublicSupply + _mintCount <= JCORP_PUBLIC, 'Purchase would exceed JCORP_PUBLIC');
		require(msg.value >= tokenPrice * _mintCount, "ETH amount is not sufficient");
		
		for (uint256 i = 0; i < _mintCount; i++) {
			totalPublicSupply += 1;
			_allowListTab[msg.sender].currentMintCount += 1;
			_safeMint(msg.sender, JCORP_GIFT + totalPublicSupply);
		}
		
		emit PresaleTokens(msg.sender, _mintCount);
    }

    function mintTokens(uint256 _mintCount) external payable {
		uint256 ownerTokenCount = balanceOf(msg.sender);
		
        SaleConfig memory _saleConfig = saleConfig;
        require(_saleConfig.startTime > 0, "Sale not configured");
		
		require(treasury != address(0), "Treasury not set");
		require(tokenPrice > 0, "Token price not set");
		require(_mintCount > 0, "Invalid mint count");
		require(block.timestamp >= _saleConfig.startTime, "Sale not started");		
		
		require(_mintCount <= _saleConfig.maxMintCountPerTX, "Purchase would exceed max allowed per TX");
		require(ownerTokenCount + _mintCount <= _saleConfig.maxMintCountPerOwner, "Purchase would exceed max allowed");
		
		require(totalSupply() < JCORP_MAX, "All tokens have been minted");
		require(totalPublicSupply + _mintCount <= JCORP_PUBLIC, 'Purchase would exceed JCORP_PUBLIC');
		require(msg.value >= tokenPrice * _mintCount, "ETH amount is not sufficient");
		
		for (uint256 i = 0; i < _mintCount; i++) {
			totalPublicSupply += 1;
			_safeMint(msg.sender, JCORP_GIFT + totalPublicSupply);
		}
		
		emit SaleTokens(msg.sender, _mintCount);
    }
	
	
	function walletOfOwner(address owner) external view returns (uint256[] memory)
    {
		uint256 ownerTokenCount = balanceOf(owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(owner, i);
		}
		return tokenIds;
    }
	
	
	function onAllowList(address owner) external view returns (bool) {
		return _allowListTab[owner].isAllowed;
	}
	
	function allowListCurrentClaim(address owner) external view returns (uint256){
		require(owner != address(0), 'Null address not on Allow List');
		return _allowListTab[owner].currentMintCount;
	}
	
	function allowListMaxClaim(address owner) external view returns (uint256){
		require(owner != address(0), 'Null address not on Allow List');
		return _allowListTab[owner].maxMintCount;
	}
	
	function addToAllowList(AllowListArray[] calldata _allowListArray) external onlyOwner {
		for (uint256 i = 0; i < _allowListArray.length; i++) {
			require(_allowListArray[i].owner != address(0), "Can't add the null address");
			
			_allowListTab[_allowListArray[i].owner].isAllowed = true;
			_allowListTab[_allowListArray[i].owner].currentMintCount > 0 ? _allowListTab[_allowListArray[i].owner].currentMintCount : 0;
			_allowListTab[_allowListArray[i].owner].maxMintCount = _allowListArray[i].maxMintCount;
		}
	}

	function removeFromAllowList(address[] calldata addresses) external onlyOwner {
		for (uint256 i = 0; i < addresses.length; i++) {
			require(addresses[i] != address(0), "Can't remove the null address");
			
			_allowListTab[addresses[i]].isAllowed = false;
		}
	}
		
	
	function setBaseURI(string calldata _newBaseURI) external onlyOwner {
		baseURI = _newBaseURI;
		emit BaseURIChanged(_newBaseURI);
    }
	
	function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
        emit TokenPriceChanged(_tokenPrice);
    }
	
    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }
	
	function transfer() external onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to transfer the funds, aborting.");
    }
	
	function setUpPresale(
        uint256 startTime,
		uint256 endTime
    ) external onlyOwner {
        uint256 _startTime = startTime;
		uint256 _endTime = endTime;
		
        require(_startTime > 0, "startTime not set");
		require(_endTime > 0, "endTime not set");

        presaleConfig = PresaleConfig({
            startTime: _startTime,
			endTime: _endTime
        });

        emit PresaleConfigChanged(_startTime, _endTime);
    }
	
	function setUpSale(
        uint256 startTime,
        uint256 maxMintCountPerTX,
		uint256 maxMintCountPerOwner
    ) external onlyOwner {
        uint256 _startTime = startTime;
        uint256 _maxMintCountPerTX = maxMintCountPerTX;
		uint256 _maxMintCountPerOwner = maxMintCountPerOwner;
		
        require(_maxMintCountPerTX > 0, "maxMintCountPerTX not set");
		require(_maxMintCountPerOwner > 0, "maxMintCountPerOwner not set");
        require(_startTime > 0, "startTime not set");
		
        saleConfig = SaleConfig({
            startTime: _startTime,
            maxMintCountPerTX: _maxMintCountPerTX,
			maxMintCountPerOwner: _maxMintCountPerOwner
        });
		
        emit SaleConfigChanged(_startTime, _maxMintCountPerTX, _maxMintCountPerOwner);
    }
	
	function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}