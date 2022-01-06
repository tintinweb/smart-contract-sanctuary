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

contract BeautyBunch is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public MAX_NFT = 10000;
	uint256 public RESERVED_NFT = 200;
	uint256 public SALE_NFT = MAX_NFT.sub(RESERVED_NFT);
	
	uint256 public MAX_BY_MINT_PRESALE = 20;
	uint256 public MAX_BY_MINT_SALE = 20;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_PRESALE = 20;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_SALE = 20;
	
	uint256 public RESERVED_MINTED;
	uint256 public PRESALE_MINTED;
	uint256 public SALE_MINTED;
	
	uint256 public PRESALE_PRICE = 4 * 10**16;
	uint256 public SALE_PRICE = 7 * 10**16;
	
	address public beneficiaryOne = 0x6a6b2824CF078d6627b220E84Cf71918c6383150;
	address public beneficiaryTwo = 0x6a6b2824CF078d6627b220E84Cf71918c6383150;
	
	uint256 public maxShare = 10000;
	uint256 public beneficiaryOneShare = 8750;
	uint256 public beneficiaryTwoShare = maxShare.sub(beneficiaryOneShare);

    string public baseTokenURI;
	bytes32 public merkleRoot;
	
	struct User {
		uint256 presalemint;
		uint256 salemint;
		uint256 lastMintTime;
    }
	
	mapping (address => User) public users;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
    event CreateNFT(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("The Beauty Bunch", "Beautybunch") {
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
	
	function mintReservedNFT(uint256 _count) public saleIsOpen onlyOwner{
        uint256 total = RESERVED_MINTED;
        require(
			total.add(_count) <= RESERVED_NFT, 
			"Exceeds max reserved limit"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			RESERVED_MINTED++;
        }
    }
	
	function mintPreSaleNFT(uint256 _count, bytes32[] calldata merkleProof) public payable saleIsOpen {
        uint256 total = PRESALE_MINTED.add(SALE_MINTED);
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		if(users[msg.sender].lastMintTime != 0)
		{
		   require(
			   block.timestamp >= users[msg.sender].lastMintTime.add(300), 
			   "Pre-sale is not enable"
		   );
		}
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
			"Exceeds max pre-sale limit"
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
		users[msg.sender].lastMintTime = block.timestamp;
		users[msg.sender].presalemint  = users[msg.sender].presalemint.add(_count);
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = PRESALE_MINTED.add(SALE_MINTED);
		if(users[msg.sender].lastMintTime != 0)
		{
		   require(
			   block.timestamp >= users[msg.sender].lastMintTime.add(300), 
			   "Pre-sale is not enable"
		   );
		}
		require(
			saleEnable, 
			"Sale is not enable"
		);
		require(
		    _count <= MAX_BY_MINT_IN_TRANSACTION_SALE,
			"Exceeds max mint limit per transaction"
		);
		require(
			users[msg.sender].salemint.add(_count) <= MAX_BY_MINT_SALE,
			"Exceeds max mint limit per wallet"
		);
		require(
			total.add(_count) <= SALE_NFT, 
			"Exceeds max sale limit"
		);
		require(
			msg.value >= SALE_PRICE.mul(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			SALE_MINTED++;
        }
		users[msg.sender].lastMintTime = block.timestamp;
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateNFT(id);
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
		uint256 shareOne = balance.mul(beneficiaryOneShare).div(10000);
		uint256 shareTwo = balance.sub(shareOne);
        payable(beneficiaryOne).transfer(shareOne);
		payable(beneficiaryTwo).transfer(shareTwo);
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
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_SALE = newLimit;
    }
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_PRESALE = newLimit;
    }
	
	function updateMintLimitPerTransectionPreSale(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_PRESALE = newLimit;
    }
	
	function updateMintLimitPerTransectionSale(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT_IN_TRANSACTION_SALE = newLimit;
    }
	
	function updateReservedLimit(uint256 newLimit) external onlyOwner {
	    require(RESERVED_MINTED <= newLimit, "Incorrect value");
		require(MAX_NFT >= PRESALE_MINTED.add(SALE_MINTED).add(newLimit), "Incorrect value");
        RESERVED_NFT = newLimit;
    }
	
	function updateSupply(uint256 newSupply) external onlyOwner {
		require(newSupply >= RESERVED_NFT.add(SALE_MINTED).add(PRESALE_MINTED), "Incorrect value");
        MAX_NFT = newSupply;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	    merkleRoot = newRoot;
	}
	
	function setBeneficiaryOne(address payable newBeneficiary) external onlyOwner{
        beneficiaryOne = newBeneficiary;
    }
	
	function setBeneficiaryTwo(address payable newBeneficiary) external onlyOwner{
        beneficiaryTwo = newBeneficiary;
    }
	
	function setBeneficiaryOneShare(uint256 share) external onlyOwner{
	   require(maxShare >= share, "Incorrect value");
	   beneficiaryOneShare = share;
	}
}