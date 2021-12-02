// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./ERC2981Royalties.sol";

contract ASTRO is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable, ERC2981Royalties {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public MAX_NFT = 7777;
	uint256 public MAX_BY_MINT_PRESALE = 100;
	uint256 public MAX_BY_MINT_SALE = 100;
	
	uint256 public PRICE = 5 * 10**16;
    string public baseTokenURI;
	
	struct User {
		uint256 presalemint;
		uint256 salemint;
    }
	
	mapping (address => User) public users;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
    event CreateASTRO(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("Astro Boy", "ASTRO") {
		setBaseURI(baseURI);
		_setRoyalties(owner(), 250);
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
        uint256 total = _totalSupply();
		require(
			presaleEnable, 
			"Pre-sale is not enable"
		);
        require(
			total.add(_count) <= MAX_NFT, 
			"Exceeds max limit"
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
			msg.value >= price(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
		users[msg.sender].presalemint = users[msg.sender].presalemint.add(_count);
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
		require(
			saleEnable, 
			"Sale is not enable"
		);
        require(
			total.add(_count) <= MAX_NFT, 
			"Exceeds max limit"
		);
		require(
			users[msg.sender].salemint.add(_count) <= MAX_BY_MINT_SALE,
			"Exceeds max mint limit per wallet"
		);
		require(
			msg.value >= price(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateASTRO(id);
    }
	
    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
	
	function setRoyalties(address recipient, uint256 value) public onlyOwner{
        _setRoyalties(recipient, value);
    }
	
	function updatePrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
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
        MAX_BY_MINT_SALE = newLimit;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
        MAX_BY_MINT_PRESALE = newLimit;
    }
}