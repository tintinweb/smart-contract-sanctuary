// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./MerkleProof.sol";

contract EGHCLUB is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public MAX_NFT = 3500;
	uint256 public MAX_BY_MINT_PRESALE_L1 = 2;
	uint256 public MAX_BY_MINT_PRESALE_L2 = 3;
	uint256 public MAX_BY_MINT_SALE = 5;
	uint256 public PRESALE_PRICE = 5 * 10**16;
	uint256 public SALE_PRICE = 5 * 10**16;

    bytes32 public merkleRootL1;
	bytes32 public merkleRootL2;
    string public baseTokenURI;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
	struct User {
		uint256 presalemint;
		uint256 salemint;
    }
	mapping (address => User) public users;
	
    constructor(string memory baseURI) ERC721("Egg Heads Club", "EGHCLUB") {
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
	
	function mintPreSaleNFT(uint256 _count, bytes32[] calldata merkleProof, uint256 _type) public payable saleIsOpen {
        uint256 total = _totalSupply();
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			presaleEnable, 
			"Pre-sale is not enable"
		);
		if(_type==1)
		{
		   require(
				MerkleProof.verify(merkleProof, merkleRootL1, node), 
				"MerkleDistributor: Invalid proof."
			);
			require(
				users[msg.sender].presalemint + _count <= MAX_BY_MINT_PRESALE_L1, 
				"Exceeds max mint limit per wallet"
			);
		}
		else
		{
		    require(
				MerkleProof.verify(merkleProof, merkleRootL2, node), 
				"MerkleDistributor: Invalid proof."
			);
			require(
				users[msg.sender].presalemint + _count <= MAX_BY_MINT_PRESALE_L2, 
				"Exceeds max mint limit per wallet"
			);
		}
        require(
			total + _count <= MAX_NFT, 
			"Exceeds max limit"
		);
		require(
			msg.value >= PRESALE_PRICE * _count,
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
		users[msg.sender].presalemint = users[msg.sender].presalemint + _count;
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
		require(
			saleEnable, 
			"Sale is not enable"
		);
        require(
			total + _count <= MAX_NFT, 
			"Exceeds max limit"
		);
		require(
			users[msg.sender].salemint +_count <= MAX_BY_MINT_SALE,
			"Exceeds max mint limit per wallet"
		);
		require(
			msg.value >= SALE_PRICE * _count,
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }
		users[msg.sender].salemint = users[msg.sender].salemint + _count;
    }
	
    function _mintAnElement(address _to) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenIdTracker.current());
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
	    require(_totalSupply() >= newLimit, 'Invalid limit');
        MAX_BY_MINT_SALE = newLimit;
    }
	
	function updatePreSaleMintLimitL1(uint256 newLimit) external onlyOwner {
	    require(_totalSupply() >= newLimit, 'Invalid limit');
        MAX_BY_MINT_PRESALE_L1 = newLimit;
    }
	
	function updatePreSaleMintLimitL2(uint256 newLimit) external onlyOwner {
	    require(_totalSupply() >= newLimit, 'Invalid limit');
        MAX_BY_MINT_PRESALE_L2 = newLimit;
    }
	
	function updateSupplyLimit(uint256 newLimit) external onlyOwner {
	    require(_totalSupply() <= newLimit, 'Invalid limit');
        MAX_NFT = newLimit;
    }
	
	function updateMerkleRootL1(bytes32 newRoot) external onlyOwner {
	   merkleRootL1 = newRoot;
	}
	
	function updateMerkleRootL2(bytes32 newRoot) external onlyOwner {
	   merkleRootL2 = newRoot;
	}
}