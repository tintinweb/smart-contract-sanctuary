// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract ObscureOctopusClub is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public GIVEAWAY_NFT = 50;
	uint256 public GIVEAWAY_NFT_MINTED;
	
	uint256 public PRESALE_NFT = 1000;
	uint256 public PRESALE_NFT_MINTED;
	
	uint256 public SALE_NFT = 8950;
	uint256 public SALE_NFT_MINTED;
	
    uint256 public MAX_MINT_IN_PRESALE = 4;
	uint256 public MAX_MINT_IN_SALE = 10;

	uint256 public PRESALE_PRICE = 7 * 10**16;
	uint256 public SALE_PRICE = 8 * 10**16;
	uint256 public MAX_NFT = GIVEAWAY_NFT.add(PRESALE_NFT).add(SALE_NFT);
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
    string public baseTokenURI;
	
    event CreateObscureOctopusClub(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("Obscure Octopus Club", "OOC") {
		setBaseURI(baseURI);
        pause(true);
    }
	
    function _totalSupply() public view returns (uint) {
        return _tokenIdTracker.current();
    }
	
	function mintGiveawayNFT(address _to, uint256 _count) public onlyOwner{
        require(
            GIVEAWAY_NFT_MINTED + _count <= GIVEAWAY_NFT, 
            "Max limit"
        );
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			GIVEAWAY_NFT_MINTED++;
        }
    }
	
	function mintPreSaleNFT(uint256 _count) public payable{
		require(
			!paused(), 
			"Contract is paused"
		);
		require(
			presaleEnable, 
			"Presale is not enable"
		);
		require(
			isWhiteListed[msg.sender], 
			"Sender is not whitelist to mint"
		);
		require(
			_count <= MAX_MINT_IN_PRESALE, 
			"Exceeds mint limit"
		);
        require(
			PRESALE_NFT_MINTED.add(_count) <= PRESALE_NFT, 
			"Exceeds max limit"
		);
		require(
			msg.value >= PRESALE_PRICE.mul(_count), 
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			PRESALE_NFT_MINTED++;
        }
    }
	
    function mintSaleNFT(uint256 _count) public payable{
		require(
			!paused(), 
			"Contract is paused"
		);
		require(
			saleEnable, 
			"Sale is not enable"
		);
		require(
			_count <= MAX_MINT_IN_SALE, 
			"Exceeds mint limit"
		);
        require(
			SALE_NFT_MINTED.add(_count) <= SALE_NFT, 
			"Exceeds max limit"
		);
		require(
			msg.value >= SALE_PRICE.mul(_count), 
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			SALE_NFT_MINTED++;
        }
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateObscureOctopusClub(id);
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
	
	function setPreSaleStatus(bool _status) public onlyOwner {
	   require(presaleEnable != _status);
       presaleEnable = _status;
    }
	
	function setSaleStatus(bool _status) public onlyOwner {
        require(saleEnable != _status);
		saleEnable = _status;
    }
	
	function updateSalePrice(uint256 newPrice) external onlyOwner {
        SALE_PRICE = newPrice;
    }
	
	function updatePreSalePrice(uint256 newPrice) external onlyOwner {
        PRESALE_PRICE = newPrice;
    }
	
	function updateGiveawayLimit(uint256 newLimit) external onlyOwner {
	   require(
		   GIVEAWAY_NFT_MINTED <= newLimit, 
		   "Incorrect value"
	   );
       GIVEAWAY_NFT = newLimit;
    }
	
	function updatePreSaleLimit(uint256 newLimit) external onlyOwner {
	   require(
			PRESALE_NFT_MINTED <= newLimit, 
			"Incorrect value"
	   );
       PRESALE_NFT = newLimit;
    }
	
	function updateSaleLimit(uint256 newLimit) external onlyOwner {
	   require(
		    SALE_NFT_MINTED <= newLimit, 
		   "Incorrect value"
	   );
       SALE_NFT = newLimit;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
         MAX_MINT_IN_PRESALE = newLimit;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
        MAX_MINT_IN_SALE = newLimit;
    }
	
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}