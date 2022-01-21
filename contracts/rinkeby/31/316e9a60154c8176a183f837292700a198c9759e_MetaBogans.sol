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

contract MetaBogans is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable, ERC2981Royalties {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	uint256 public MAX_NFT = 5000;
	uint256 public GIVEAWAY_NFT = 200;
	uint256 public PRESALE_NFT = 1000;
	uint256 public SALE_NFT = MAX_NFT.sub(GIVEAWAY_NFT).sub(PRESALE_NFT);
	
	uint256 public PRESALE_PRICE = 2 * 10**17;
	uint256 public SALE_PRICE = 2 * 10**17;
	
	uint256 public MAX_MINT_PRESALE = PRESALE_NFT;
	uint256 public MAX_MINT_SALE = SALE_NFT;
	uint256 public MAX_BY_MINT_IN_TRANSACTION = 2;
	
	uint256 public PRESALE_MINTED;
	uint256 public SALE_MINTED;
	uint256 public GIVEAWAY_MINTED;
	
	address[] public feeAddress;
	uint256[] public feePart;
	
    string public baseTokenURI;
	bytes32 public merkleRoot;
	
	bool public presaleEnable = false;
	bool public saleEnable = false;
	
    event CreateNFT(uint256 indexed id);
	
	struct User {
		uint256 presalemint;
		uint256 salemint;
    }
	
	mapping (address => User) public users;
	
    constructor(string memory baseURI) ERC721("MetaBogans", "MB") {
		setBaseURI(baseURI);

		feeAddress.push(msg.sender);
		feeAddress.push(msg.sender);
		feeAddress.push(msg.sender);
		feeAddress.push(msg.sender);
		feeAddress.push(msg.sender);

		feePart.push(500);
		feePart.push(125);
		feePart.push(125);
		feePart.push(125);
		feePart.push(125);
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
	
	function mintGiveawayNFT(address _to, uint256 _count) public onlyOwner{
        require(
            GIVEAWAY_MINTED + _count <= GIVEAWAY_NFT, 
            "Max limit"
        );
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			GIVEAWAY_MINTED++;
        }
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
		uint256 partOne = balance.mul(feePart[0]).div(10000);
		uint256 partTwo = balance.mul(feePart[1]).div(10000);
		uint256 partThree = balance.mul(feePart[2]).div(10000);
		uint256 partFour = balance.mul(feePart[3]).div(10000);
		uint256 partFive = balance.sub(partOne).sub(partTwo).sub(partThree).sub(partFour);
		
        payable(feeAddress[0]).transfer(partOne);
		payable(feeAddress[1]).transfer(partTwo);
		payable(feeAddress[2]).transfer(partThree);
		payable(feeAddress[3]).transfer(partFour);
		payable(feeAddress[4]).transfer(partFive);
    }
	
	function withdraw(uint256 amount) public onlyOwner {
		uint256 balance = address(this).balance;
        require(balance >= amount);
		uint256 partOne = amount.mul(feePart[0]).div(10000);
		uint256 partTwo = amount.mul(feePart[1]).div(10000);
		uint256 partThree = amount.mul(feePart[2]).div(10000);
		uint256 partFour = amount.mul(feePart[3]).div(10000);
		uint256 partFive = amount.sub(partOne).sub(partTwo).sub(partThree).sub(partFour);
		
        payable(feeAddress[0]).transfer(partOne);
		payable(feeAddress[1]).transfer(partTwo);
		payable(feeAddress[2]).transfer(partThree);
		payable(feeAddress[3]).transfer(partFour);
		payable(feeAddress[4]).transfer(partFive);
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
	
	function updatePreSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(PRESALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_PRESALE = newLimit;
    }
	
	function updateSaleMintLimit(uint256 newLimit) external onlyOwner {
	    require(SALE_NFT >= newLimit, "Incorrect value");
        MAX_MINT_SALE = newLimit;
    }
	
	function updateGiveawaySupply(uint256 newLimit) external onlyOwner {
	   require(newLimit >= GIVEAWAY_MINTED,  "Incorrect value");
       GIVEAWAY_NFT = newLimit;
    }
	
	function updatePreSaleSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= PRESALE_MINTED, "Incorrect value");
        PRESALE_NFT = newSupply;
    }
	
	function updateMaxSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= GIVEAWAY_NFT.add(PRESALE_NFT).add(SALE_MINTED), "Incorrect value");
        MAX_NFT = newSupply;
    }
	
	function updateMintLimitPerTransection(uint256 newLimit) external onlyOwner {
        MAX_BY_MINT_IN_TRANSACTION = newLimit;
    }
	
	function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
	   merkleRoot = newRoot;
	}
	
	function setRoyalties(address recipient, uint256 value) public onlyOwner{
        _setRoyalties(recipient, value);
    }
	
	function setFeeAddress(address addressOne, address addressTwo, address addressThree, address addressFour, address addressFive) external onlyOwner {
		require(addressOne != address(0) && addressTwo != address(0) && addressThree != address(0) && addressFour != address(0) && addressFive != address(0), "zero address");
		feeAddress[0] = addressOne;
		feeAddress[1] = addressTwo;
		feeAddress[2] = addressThree;
		feeAddress[3] = addressFour;
		feeAddress[4] = addressFive;
	}
	
	function setFeeAddressPart(uint256 addressOnePart, uint256 addressTwoPart, uint256 addressThreePart, uint256 addressFourPart, uint256 addressFivePart) external onlyOwner {
		require(addressOnePart.add(addressTwoPart).add(addressThreePart).add(addressFourPart).add(addressFivePart) == 10000, "Incorrect value");
		feePart[0] = addressOnePart;
		feePart[1] = addressTwoPart;
		feePart[2] = addressThreePart;
		feePart[3] = addressFourPart;
		feePart[4] = addressFivePart;
	}
	
}