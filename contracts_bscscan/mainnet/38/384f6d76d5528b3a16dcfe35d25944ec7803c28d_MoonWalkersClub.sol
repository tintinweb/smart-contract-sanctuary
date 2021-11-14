// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract MoonWalkersClub is ERC721, ERC721Enumerable, Ownable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_NFT = 7777;
    uint256 public MAX_BY_MINT = 20;
	uint256 public PRICE = 4 * 10**17;
	
    string public baseTokenURI;
	
    event CreateMoonWalkersClub(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("The Moon Walkers Club", "MoonWalkersClub") {
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
	
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
	
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_NFT, "Max limit");
        require(total <= MAX_NFT, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateMoonWalkersClub(id);
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
	
	function withdraw(uint256 amount) public onlyOwner {
		uint256 balance = address(this).balance;
        require(balance >= amount);
        _widthdraw(owner(), amount);
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
	
	function updateMintLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT = newLimit;
    }
	
	function updateMaxSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= _totalSupply(), "Incorrect value");
        MAX_NFT = newSupply;
    }

}