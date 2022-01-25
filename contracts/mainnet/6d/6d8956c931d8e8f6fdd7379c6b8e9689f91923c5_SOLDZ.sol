// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract SOLDZ is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
    uint256 public MAX_NFT = 5376;
	uint256 public GIVEAWAY_NFT = 150;
	uint256 public SALE_NFT = MAX_NFT.sub(GIVEAWAY_NFT);
    uint256 public MAX_BY_MINT = 10;
	uint256 public PRICE = 3 * 10**16;
	
	uint256 public GIVEAWAY_MINTED;
	uint256 public SALE_MINTED;
	
	bool public saleEnable = false;
	
    string public baseTokenURI;
    event CreateSOLDZ(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("Soldierz", "SOLDZ") {
		setBaseURI(baseURI);
    }
	
    modifier saleIsOpen {
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
	
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
	
	function mintGiveawayNFT(address _to, uint256 _count) public onlyOwner{
		require(
            GIVEAWAY_MINTED + _count <= GIVEAWAY_NFT, 
            "Max limit"
        );
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			GIVEAWAY_MINTED++;
        }
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen{
		require(
			saleEnable, 
			"Sale is not enable"
		);
		require(
			_count <= MAX_BY_MINT, 
			"Max limit per txn"
		);
        require(
			SALE_MINTED.add(_count) <= SALE_NFT, 
			"Exceeds max limit"
		);
		require(
			msg.value >= price(_count), 
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			SALE_MINTED++;
        }
    }
	
	function _mintAnElement(address _to) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenIdTracker.current());
        emit CreateSOLDZ(_tokenIdTracker.current());
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
	
	function setSaleStatus(bool _status) public onlyOwner {
        require(saleEnable != _status);
		saleEnable = _status;
    }
	
	function updatePrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }
	
	function updateMintLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT = newLimit;
    }
	
	function updateMaxSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= _totalSupply(), "Incorrect value");
        MAX_NFT = newSupply;
    }
	
	function updateGiveawayLimit(uint256 newLimit) external onlyOwner {
	   require(GIVEAWAY_MINTED <= newLimit, "Incorrect value");
	   require(MAX_NFT >= SALE_MINTED.add(newLimit), "Incorrect value");
       GIVEAWAY_NFT = newLimit;
    }
}