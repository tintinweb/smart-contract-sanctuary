// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./MerkleProof.sol";

contract MetaMVPClub is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public SALE_NFT = 8800;
	uint256 public RESERVED_NFT = 88;
	uint256 public MAX_NFT = SALE_NFT.add(RESERVED_NFT);
	
	uint256 public PRESALE_PRICE = 88 * 10**15;
	uint256 public SALE_PRICE = 88 * 10**15;
	
	uint256 public MAX_MINT_PRESALE = 3;
	uint256 public MAX_MINT_SALE = 5;
	
	uint256 public PRESALE_MINTED;
	uint256 public RESERVED_MINTED;
	uint256 public SALE_MINTED;
	
    string public baseTokenURI;
	bytes32 public merkleRoot;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
    event CreateNFT(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("Meta MVP Club", "MMC") {
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
	
	function mintReservedSaleNFT(uint256 _count, address _to) public onlyOwner saleIsOpen {
        uint256 total = RESERVED_MINTED;
        require(
			total.add(_count) <= RESERVED_NFT, 
			"Exceeds max limit"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			RESERVED_MINTED++;
        }
    }
	
	function mintPreSaleNFT(uint256 _count, bytes32[] calldata merkleProof) public payable saleIsOpen {
        uint256 total = PRESALE_MINTED.add(SALE_MINTED);
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			presaleEnable, 
			"Pre-sale is not enable"
		);
		require(
			MerkleProof.verify(merkleProof, merkleRoot, node), 
			"MerkleDistributor: Invalid proof."
		);
		require(
			total.add(_count) <= SALE_NFT, 
			"Exceeds max limit"
		);
		require(
			_count <= MAX_MINT_PRESALE, 
			"Exceeds max mint limit per trx"
		);
		require(
			msg.value >= PRESALE_PRICE.mul(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			PRESALE_MINTED++;
        }
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = SALE_MINTED.add(PRESALE_MINTED);
		require(
			saleEnable, 
			"Sale is not enable"
		);
        require(
			total.add(_count) <= SALE_NFT, 
			"Exceeds max limit"
		);
		require(
			_count <= MAX_MINT_SALE,
			"Exceeds max mint limit per tnx"
		);
		require(
			msg.value >= SALE_PRICE.mul(_count),
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
        emit CreateNFT(_tokenIdTracker.current());
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
        payable(msg.sender).transfer(balance);
    }
	
	function withdraw(uint256 amount) public onlyOwner {
		uint256 balance = address(this).balance;
        require(balance >= amount);
		payable(msg.sender).transfer(amount);
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
	
	function setPreSaleStatus(bool status) public onlyOwner {
	   require(presaleEnable != status);
       presaleEnable = status;
    }
	
	function setSaleStatus(bool status) public onlyOwner {
        require(saleEnable != status);
		saleEnable = status;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_MINT_SALE = newLimit;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_MINT_PRESALE = newLimit;
    }
	
	function updateMaxSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= PRESALE_MINTED.add(SALE_MINTED), "Incorrect value");
        SALE_NFT = newSupply;
    }
	
	function updateReservedSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= RESERVED_MINTED, "Incorrect value");
        RESERVED_NFT = newSupply;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
}