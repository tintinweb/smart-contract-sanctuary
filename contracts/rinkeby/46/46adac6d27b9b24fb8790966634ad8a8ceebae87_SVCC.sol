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

contract SVCC is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public MAX_NFT = 11111;
	uint256 public RESERVED_NFT = 334;
	uint256 public SALE_NFT = MAX_NFT.sub(RESERVED_NFT);
	
	uint256 public MAX_BY_MINT_PRESALE = SALE_NFT;
	uint256 public MAX_BY_MINT_SALE = SALE_NFT;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_PRESALE = 3;
	uint256 public MAX_BY_MINT_IN_TRANSACTION_SALE = 15;
	uint256 public WHALE_PASS_LIMIT = 200;
	
	uint256 public RESERVED_MINTED;
	uint256 public PRESALE_MINTED;
	uint256 public SALE_MINTED;
	
	uint256 public PRESALE_PRICE = 777 * 10**14;
	uint256 public SALE_PRICE = 777 * 10**14;
	
    string public baseTokenURI;
	bytes32 public merkleRoot;
	
	mapping (address => bool) public isWhalePass;
	
	struct User {
		uint256 presalemint;
		uint256 salemint;
    }
	
	mapping (address => User) public users;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
    event CreateSVCC(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("Sand Vegas Casino Club", "SVCC") {
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
	
	function mintGiveawayNFT(uint256 _count) public saleIsOpen onlyOwner{
        uint256 total = RESERVED_MINTED;
        require(
			total.add(_count) <= RESERVED_NFT, 
			"Exceeds max giveaway limit"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
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
			"Exceeds max pre-sale limit"
		);
		if(isWhalePass[msg.sender])
		{
		    require(
				_count <= WHALE_PASS_LIMIT,
				"Exceeds max mint limit per transaction"
		    );
		}
		else
		{
		   require(
				_count <= MAX_BY_MINT_IN_TRANSACTION_PRESALE,
				"Exceeds max mint limit per transaction"
		   );
		}
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
		users[msg.sender].presalemint = users[msg.sender].presalemint.add(_count);
    }
	
	function mintSaleNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = PRESALE_MINTED.add(SALE_MINTED);
		require(
			saleEnable, 
			"Sale is not enable"
		);
		if(isWhalePass[msg.sender])
		{
		    require(
				_count <= WHALE_PASS_LIMIT,
				"Exceeds max mint limit per transaction"
		    );
		}
		else
		{
		   require(
				_count <= MAX_BY_MINT_IN_TRANSACTION_SALE,
				"Exceeds max mint limit per transaction"
		   );
		}
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
		users[msg.sender].salemint = users[msg.sender].salemint.add(_count);
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateSVCC(id);
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
	
	function updateWhalePassLimit(uint256 newLimit) external onlyOwner {
        WHALE_PASS_LIMIT = newLimit;
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
	
	function updateWhaleAddress(address account, bool status) public onlyOwner {
        isWhalePass[account] = status;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
}