// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract _316VC is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	string public baseTokenURI;
	
	uint256 public TopTier_Supply = 15;
	uint256 public MidTier_Supply = 50;
	uint256 public LowTier_Supply = 2000;
	
	uint256 public TopTier_Mint_Limit = 1;
	uint256 public MidTier_Mint_Limit = 1;
	uint256 public LowTier_Mint_Limit = 2;
	
	uint256 public TopTier_Minted;
	uint256 public MidTier_Minted;
	uint256 public LowTier_Minted;
	
	uint256 public TopTier_Price = 6 * 10**18;
	uint256 public MidTier_Price = 2 * 10**18;
	uint256 public LowTier_Price = 4 * 10**17;
	
	bool public TopTier_Enable = false;
	bool public MidTier_Enable = false;
	bool public LowTier_Enable = false;
	
    event CreateNFT(uint256 indexed id);
	
    constructor(string memory baseURI) ERC721("316VC", "316VC") {
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
	
	function mintTopTierNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = TopTier_Minted;
		require(
			TopTier_Enable, 
			"TopTier is not enable"
		);
        require(
			total.add(_count) <= TopTier_Supply, 
			"Exceeds max limit"
		);
		require(
			_count <= TopTier_Mint_Limit,
			"Exceeds max mint limit per tnx"
		);
		require(
			msg.value >= TopTier_Price.mul(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			TopTier_Minted++;
        }
    }
	
	function mintMidTierNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = MidTier_Minted;
		require(
			MidTier_Enable, 
			"MidTier is not enable"
		);
        require(
			total.add(_count) <= MidTier_Supply, 
			"Exceeds max limit"
		);
		require(
			_count <= MidTier_Mint_Limit,
			"Exceeds max mint limit per tnx"
		);
		require(
			msg.value >= MidTier_Price.mul(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			MidTier_Minted++;
        }
    }
	
	function mintLowTierNFT(uint256 _count) public payable saleIsOpen {
        uint256 total = LowTier_Minted;
		require(
			LowTier_Enable, 
			"LowTier is not enable"
		);
        require(
			total.add(_count) <= LowTier_Supply, 
			"Exceeds max limit"
		);
		require(
			_count <= LowTier_Mint_Limit,
			"Exceeds max mint limit per tnx"
		);
		require(
			msg.value >= LowTier_Price.mul(_count),
			"Value below price"
		);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
			LowTier_Minted++;
        }
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
	
	function updateTopTierPrice(uint256 newPrice) external onlyOwner {
        TopTier_Price = newPrice;
    }
	
	function updateMidTierPrice(uint256 newPrice) external onlyOwner {
        MidTier_Price = newPrice;
    }
	
	function updateLowTierPrice(uint256 newPrice) external onlyOwner {
        LowTier_Price = newPrice;
    }
	
	function setTopTierStatus(bool status) public onlyOwner {
        require(TopTier_Enable != status);
		TopTier_Enable = status;
    }
	
	function setMidTierStatus(bool status) public onlyOwner {
        require(MidTier_Enable != status);
		MidTier_Enable = status;
    }
	
	function setLowTierStatus(bool status) public onlyOwner {
        require(LowTier_Enable != status);
		LowTier_Enable = status;
    }
	
	function updateTopTierMintLimit(uint256 newLimit) external onlyOwner {
	    require(TopTier_Supply >= newLimit, "Incorrect value");
        TopTier_Mint_Limit = newLimit;
    }
	
	function updateMidTierMintLimit(uint256 newLimit) external onlyOwner {
	    require(MidTier_Supply >= newLimit, "Incorrect value");
        MidTier_Mint_Limit = newLimit;
    }
	
	function updateLowTierMintLimit(uint256 newLimit) external onlyOwner {
	    require(LowTier_Supply >= newLimit, "Incorrect value");
        LowTier_Mint_Limit = newLimit;
    }
	
	function updateTopTierSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= TopTier_Minted, "Incorrect value");
        TopTier_Supply = newSupply;
    }
	
	function updateMidTierSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= MidTier_Minted, "Incorrect value");
        MidTier_Supply = newSupply;
    }
	
	function updateLowTierSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= LowTier_Minted, "Incorrect value");
        LowTier_Supply = newSupply;
    }
}