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
import "./ERC2981Royalties.sol";

contract TFA is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable, ERC2981Royalties{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public MAX_NFT = 10000;
	uint256 public MAX_BY_MINT_PRESALE = 1;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_PRESALE = 1;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_SALE = 10;
	
	uint256 public SALE_PRICE = 9 * 10**16;
	uint256 public PRESALE_PRICE = 9 * 10**16;

    bytes32 public merkleRoot;
    string public baseTokenURI;
	
	uint256 public PRESALE_MINTED;
	uint256 public PRIVATE_MINTED;
	uint256 public SALE_MINTED;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
	struct User {
	   uint256 presalemint;
    }
	
	mapping (address => User) public users;
    event CreateTFA(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("The First Arabs", "TFA") {
		setBaseURI(baseURI);
		_setRoyalties(owner(), 3000);
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
	
	function mintPrivateSaleNFT(uint256 _count, address _to) public onlyOwner saleIsOpen {
        uint256 total = _totalSupply();
        require(
			total.add(_count) <= MAX_NFT, 
			"Exceeds max limit"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			 PRIVATE_MINTED++;
        }
    }
	
	function mintPreSaleNFT(uint256 _count, bytes32[] calldata merkleProof) public payable saleIsOpen {
        uint256 total = _totalSupply();
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
			total.add(_count) <= MAX_NFT, 
			"Exceeds max limit"
		);
		require(
			_count <= MAX_BY_MINT_IN_TRANSACTION_PRESALE,
			"Exceeds max mint limit per transaction"
		);
		require(
			users[msg.sender].presalemint.add(_count) <= MAX_BY_MINT_PRESALE, 
			"Exceeds max mint limit per wallet"
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
			_count <= MAX_BY_MINT_IN_TRANSACTION_SALE,
			"Exceeds max mint limit per transaction"
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
        emit CreateTFA(_tokenIdTracker.current());
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
	
	function updateSalePrice(uint256 newPrice) external onlyOwner {
        SALE_PRICE = newPrice;
    }
	
	function updatePreSalePrice(uint256 newPrice) external onlyOwner {
        PRESALE_PRICE = newPrice;
    }
	
	function setPreSaleStatus(bool _status) public onlyOwner {
	   require(presaleEnable != _status);
       presaleEnable = _status;
    }
	
	function setSaleStatus(bool _status) public onlyOwner {
        require(saleEnable != _status);
		saleEnable = _status;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_PRESALE = newLimit;
    }
	
	function updateMintLimitPerTransectionPreSale(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_PRESALE = newLimit;
    }
	
	function updateMintLimitPerTransectionSale(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_SALE = newLimit;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
	
	function setRoyalties(address recipient, uint256 value) public onlyOwner{
        _setRoyalties(recipient, value);
    }
}