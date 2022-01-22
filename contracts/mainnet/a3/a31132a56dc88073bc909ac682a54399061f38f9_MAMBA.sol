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

contract MAMBA is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public GIVEAWAY_NFT = 20;
	uint256 public EARLYRISER_NFT = 200;
	uint256 public PRESALE_NFT = 2000;
	uint256 public SALE_NFT = 6668;
	
	uint256 public MAX_NFT = SALE_NFT.add(PRESALE_NFT).add(EARLYRISER_NFT).add(GIVEAWAY_NFT);
	
	uint256 public EARLYRISER_PRICE = 4 * 10**16;
	uint256 public PRESALE_PRICE = 8 * 10**16;
	uint256 public SALE_PRICE = 8 * 10**16;
	
	uint256 public MAX_MINT_EARLYRISER = EARLYRISER_NFT;
	uint256 public MAX_MINT_PRESALE = PRESALE_NFT;
	uint256 public MAX_MINT_SALE = SALE_NFT;
	uint256 public MAX_BY_MINT_IN_TRANSACTION = 24;
	
	uint256 public EARLYRISER_MINTED;
	uint256 public PRESALE_MINTED;
	uint256 public SALE_MINTED;
	uint256 public GIVEAWAY_MINTED;
	
    string public baseTokenURI;
	bytes32 public merkleRoot;
	
	bool public earlyRiserEnable = false;
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
    event CreateNFT(uint256 indexed id);
	
	struct User {
	    uint256 earlyrisermint;
		uint256 presalemint;
		uint256 salemint;
    }
	mapping (address => User) public users;
	
    constructor(string memory baseURI, bytes32 newRoot) ERC721("The Mamba's", "MAMBA") {
		setBaseURI(baseURI);
		merkleRoot = newRoot;
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
        uint256 total = GIVEAWAY_MINTED;
		require(
            total.add(_count) <= GIVEAWAY_NFT, 
            "Max limit"
        );
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			GIVEAWAY_MINTED++;
        }
    }
	
	function mintEarlyRiserNFT(uint256 _count, bytes32[] calldata merkleProof) public payable saleIsOpen {
        uint256 total = EARLYRISER_MINTED;
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			earlyRiserEnable, 
			"early riser is not enable"
		);
		require(
			MerkleProof.verify(merkleProof, merkleRoot, node), 
			"MerkleDistributor: Invalid proof."
		);
		require(
			total.add(_count) <= EARLYRISER_NFT, 
			"Exceeds max limit"
		);
		require(
			_count <= MAX_BY_MINT_IN_TRANSACTION, 
			"Exceeds max mint limit per trx"
		);
		require(
			users[msg.sender].earlyrisermint.add(_count) <= MAX_MINT_EARLYRISER, 
			"Exceeds max mint limit per wallet"
		);
		require(
			msg.value >= EARLYRISER_PRICE.mul(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			EARLYRISER_MINTED++;
        }
		users[msg.sender].earlyrisermint = users[msg.sender].earlyrisermint.add(_count);
    }
	
	function mintPreSaleNFT(uint256 _count, bytes32[] calldata merkleProof) public payable saleIsOpen {
        uint256 total = PRESALE_MINTED;
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
			total.add(_count) <= PRESALE_NFT, 
			"Exceeds max limit"
		);
		require(
			_count <= MAX_BY_MINT_IN_TRANSACTION, 
			"Exceeds max mint limit per trx"
		);
		require(
			users[msg.sender].presalemint.add(_count) <= MAX_MINT_PRESALE, 
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
		users[msg.sender].presalemint = users[msg.sender].presalemint.add(_count);
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = SALE_MINTED;
		require(
			saleEnable, 
			"Sale is not enable"
		);
        require(
			total.add(_count) <= SALE_NFT, 
			"Exceeds max limit"
		);
		require(
			_count <= MAX_BY_MINT_IN_TRANSACTION,
			"Exceeds max mint limit per tnx"
		);
		require(
			users[msg.sender].salemint.add(_count) <= MAX_MINT_SALE,
			"Exceeds max mint limit per wallet"
		);
		require(
			msg.value >= SALE_PRICE.mul(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			SALE_MINTED++;
        }
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
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
	
	function updateEarlyRiserPrice(uint256 newPrice) external onlyOwner {
        EARLYRISER_PRICE = newPrice;
    }
	
	function updatePreSalePrice(uint256 newPrice) external onlyOwner {
        PRESALE_PRICE = newPrice;
    }

    function updateSalePrice(uint256 newPrice) external onlyOwner {
        SALE_PRICE = newPrice;
    }
	
	function setEarlyRiserEnableStatus(bool status) public onlyOwner {
	   require(earlyRiserEnable != status);
       earlyRiserEnable = status;
    }
	
	function setPreSaleStatus(bool status) public onlyOwner {
	   require(presaleEnable != status);
       presaleEnable = status;
    }
	
	function setSaleStatus(bool status) public onlyOwner {
        require(saleEnable != status);
		saleEnable = status;
    }
	
	function updateEarlyRiserMintLimit(uint256 newLimit) external onlyOwner {
	    require(EARLYRISER_NFT >= newLimit, "Incorrect value");
        MAX_MINT_EARLYRISER = newLimit;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(PRESALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_PRESALE = newLimit;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_SALE = newLimit;
    }
	
	function updateGiveawaySupply(uint256 newSupply) external onlyOwner {
	   require(newSupply >= GIVEAWAY_MINTED,  "Incorrect value");
       GIVEAWAY_NFT = newSupply;
    }
	
	function updateEarlyRiserSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= EARLYRISER_MINTED, "Incorrect value");
        EARLYRISER_NFT = newSupply;
    }
	
	function updatePreSaleSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= PRESALE_MINTED, "Incorrect value");
        PRESALE_NFT = newSupply;
    }
	
	function updateSaleSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= SALE_MINTED, "Incorrect value");
        SALE_NFT = newSupply;
    }
	
	function updateMintLimitPerTransection(uint256 newLimit) external onlyOwner {
        MAX_BY_MINT_IN_TRANSACTION = newLimit;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
}