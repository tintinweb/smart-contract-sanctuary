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
	
	uint256 public SALE_NFT = 8888;
	uint256 public RESERVE_NFT = 1112;
	uint256 public MAX_NFT = RESERVE_NFT.add(SALE_NFT);
	
	uint256 public MAX_BY_MINT_SALE = 20;
	
	uint256 public FREE_NFT = 1;
	uint256 public FREE_NFT_RANGE = 5;
	
	uint256 public SALE_MINTED;
	uint256 public RESERVE_MINTED;
	
	uint256 public SALE_PRICE = 8 * 10**16;
	
    string public baseTokenURI;
	
	struct User {
		uint256 salemint;
    }
	
	mapping (address => User) public users;
	bool public saleEnable = false;
	
    event CreateApes(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("Merry Apes Club", "Apes") {
		setBaseURI(baseURI);
        pause(true);
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
	
	function mintReserveNFT(uint256 _count) public onlyOwner{
        require(
            RESERVE_MINTED + _count <= RESERVE_NFT, 
            "Max limit"
        );
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			RESERVE_MINTED++;
        }
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
		if(_count >= FREE_NFT_RANGE)
		{ 
		    uint256 totalFree = _count.div(FREE_NFT_RANGE);
			        totalFree =  totalFree.mul(FREE_NFT);
		    _count = _count.add(totalFree);
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
	
    function updateSalePrice(uint256 newPrice) external onlyOwner {
        SALE_PRICE = newPrice;
    }
	
	function setSaleStatus(bool _status) public onlyOwner {
        require(saleEnable != _status);
		saleEnable = _status;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_SALE = newLimit;
    }
	
	function updateGiveawayLimit(uint256 newLimit) external onlyOwner {
	   require(RESERVE_MINTED <= newLimit, "Incorrect value");
       RESERVE_NFT = newLimit;
    }
	
	function updateSaleLimit(uint256 newLimit) external onlyOwner {
	   require(SALE_MINTED <= newLimit,  "Incorrect value");
       SALE_NFT = newLimit;
    }
	
	function updateFreeNFTLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        FREE_NFT = newLimit;
    }
	
	function updateFreeNFTRange(uint256 newLimit) external onlyOwner {
        FREE_NFT_RANGE = newLimit;
    }
}