// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract MerryApesClub is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public MAX_NFT = 8888;
	uint256 public PRESALE_NFT = 4444;
	uint256 public SALE_NFT = MAX_NFT.sub(PRESALE_NFT);
	
	uint256 public MAX_BY_MINT_PRESALE = 20;
	uint256 public MAX_BY_MINT_SALE = 20;
	
	uint256 public FREE_NFT = 5;
	
	uint256 public PRESALE_MINTED;
	uint256 public SALE_MINTED;
	
	uint256 public PRESALE_PRICE = 7 * 10**16;
	uint256 public SALE_PRICE = 8 * 10**16;
	
    string public baseTokenURI;
	
	struct User {
		uint256 presalemint;
		uint256 salemint;
    }
	
	mapping (address => User) internal users;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
    event CreateApes(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("MerryApesClub", "Apes") {
		setBaseURI(baseURI);
        pause(true);
    }
	
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_NFT, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
	
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
	
	function mintPreSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = PRESALE_MINTED;
		require(
			presaleEnable, 
			"Pre-sale is not enable"
		);
		require(
			isWhiteListed[msg.sender], 
			"Sender is not whitelist to mint in pre-sale"
		);
		require(
			users[msg.sender].presalemint.add(_count) <= MAX_BY_MINT_PRESALE, 
			"Exceeds max mint limit per wallet"
		);
		require(
			msg.value >= PRESALE_PRICE.mul(_count),
			"Value below price"
		);
		if(_count == MAX_BY_MINT_PRESALE)
		{
		   _count = _count.add(FREE_NFT);
		}
		require(
			total.add(_count) <= PRESALE_NFT, 
			"Exceeds max pre-sale limit"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			PRESALE_MINTED++;
        }
		users[msg.sender].presalemint = users[msg.sender].presalemint.add(_count);
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = SALE_MINTED;
		require(
			saleEnable, 
			"Sale is not enable"
		);
		require(
			users[msg.sender].salemint.add(_count) <= MAX_BY_MINT_SALE,
			"Exceeds max mint limit per wallet"
		);
		require(
			msg.value >= SALE_PRICE.mul(_count),
			"Value below price"
		);
		if(_count == MAX_BY_MINT_SALE)
		{
		   _count = _count.add(FREE_NFT);
		}
		require(
			total.add(_count) <= SALE_NFT, 
			"Exceeds max sale limit"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			SALE_MINTED++;
        }
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateApes(id);
    }
   
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
	
	function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
	
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }
	
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
	
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
	
	function updatePreSalePrice(uint256 newPrice) external onlyOwner {
        PRESALE_PRICE = newPrice;
    }

    function updateSalePrice(uint256 newPrice) external onlyOwner {
        SALE_PRICE = newPrice;
    }
	
	function setPreSaleStatus(bool _status) public onlyOwner {
	   require(presaleEnable != _status);
       presaleEnable = _status;
    }
	
	function setSaleStatus(bool _status) public onlyOwner {
        require(saleEnable != _status);
		saleEnable = _status;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_SALE = newLimit;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(PRESALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_PRESALE = newLimit;
    }
	
	function updatePreSaleLimit(uint256 newLimit) external onlyOwner {
	    require(PRESALE_MINTED <= newLimit, "Incorrect value");
		require(MAX_NFT >= SALE_MINTED.add(newLimit), "Incorrect value");
        PRESALE_NFT = newLimit;
    }
	
	function updateFreeNFTLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        FREE_NFT = newLimit;
    }
}