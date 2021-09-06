// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract BFT is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_NFT = 1000;
	uint256 public constant MAX_BY_MINT = 20;
	
    address public creatorAddress;
    string public baseTokenURI;
	
    event CreateFungibleBites(uint256 indexed id);
	
    constructor(string memory baseURI, address payable creator) ERC721("Fungible Bites", "BFT") {
        setBaseURI(baseURI);
		creatorAddress = creator;
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
        emit CreateFungibleBites(id);
    }
	
    function price(uint256 _count) public view returns (uint256) {
	    uint256 total = _totalSupply();
		uint256 priceAllNFT;
		for(uint256 i = 1; i <= _count; i++) 
		{
			if(total + i > 800) 
			{
				priceAllNFT = priceAllNFT.add(2 * 10**18);
			}
			else if(total + i > 500) 
			{
				priceAllNFT = priceAllNFT.add(15 * 10**17);
			}
			else if(total + i > 200) 
			{
				priceAllNFT = priceAllNFT.add(1 * 10**18);
			}
			else 
			{
				priceAllNFT = priceAllNFT.add(5 * 10**17);
			}
        }
        return priceAllNFT; 		
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setCreatorAddress(address payable creator) public onlyOwner {
        creatorAddress = creator;
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

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
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
}