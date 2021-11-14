// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract Pixelcolors is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_NFT;
    uint256 public MAX_BY_MINT;
	uint256 public PRICE;
	uint256 public GIVEAWAY_NFT;
	uint256 public GIVEAWAY_MINTED;

    string public baseTokenURI;
    event CreatePXCL(uint256 indexed id);
 
	constructor(string memory baseURI, uint256 maxNFT, uint256 maxByMint, uint256 GiveawayNFT, uint256 Price) ERC721("PXCL", "Pixelcolors") {
        MAX_NFT = maxNFT;
		MAX_BY_MINT = maxByMint;
		GIVEAWAY_NFT = GiveawayNFT;
		PRICE = Price;
		setBaseURI(baseURI);
        pause(true);
    }
	
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_NFT, "Sale end");
        if (_msgSender() != owner() && !isWhiteListed[_msgSender()]) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
	
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
	
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
	
	function __mint(address _to, uint256 _count) public onlyOwner{
        uint256 total = GIVEAWAY_MINTED;
        require(total + _count <= GIVEAWAY_NFT, "Max limit");
        for (uint256 i = 0; i < _count; i++) {
		     GIVEAWAY_MINTED++;
            _mintAnElement(_to);
        }
    }

	function mint(address _to, uint256 _count) public payable saleIsOpen{
        uint256 total = _totalSupply();
		uint256 tokenCount = balanceOf(_to);
        require(total + _count <= MAX_NFT, "Max limit");
        require(total <= MAX_NFT, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
		require(tokenCount + _count <= MAX_HOLDING_NFT, "Max limit per address");
        require(msg.value >= price(_count), "Value below price");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreatePXCL(id);
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

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
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
	
	function updatePrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }
	
	function updateHoldingLimit(uint256 newLimit) public onlyOwner{
	    MAX_HOLDING_NFT = newLimit;
    }
	
	function updateMintLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT = newLimit;
    }
	
	function updateMaxSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply > _totalSupply(), "Incorrect value");
        MAX_NFT = newSupply;
    }
	
	function updateGiveawayLimit(uint256 newLimit) external onlyOwner {
	    require(GIVEAWAY_MINTED <= newLimit, "Incorrect value");
        GIVEAWAY_NFT = newLimit;
    }
}