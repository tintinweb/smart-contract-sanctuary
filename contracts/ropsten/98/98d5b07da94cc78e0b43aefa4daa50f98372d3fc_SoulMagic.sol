// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SoulMagic is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    // Event when public sale begins
    event BeginSale();

    // Event when sale period ends
    event EndSale();

    uint256 public maxSupply = 50;
    uint256 public reserved = 10;
    uint256 public phaseCap = 20;
    uint256 public maxMint = 5;
    uint256 public price = 0.01 ether;

    bool private saleStarted;
    uint256 public startingIndex;
    string public baseURI;

    constructor() ERC721("SoulMagic", "SOUL") {
        saleStarted = false;
    }

    modifier whenSaleStarted() {
        require(saleStarted, "Sale is not active");
        _;
    }
    
    modifier whenSaleStopped() {
        require(saleStarted == false, "Sale already started");
        _;
    }
    
    function mintChild(uint256 numTokens) external payable whenSaleStarted {
        uint256 supply = totalSupply();
        uint256 phaseSupply = currentSupply();

        require(numTokens <= maxMint, "Cannot mint more than 5 tokens at once");
        require(phaseSupply.add(numTokens) <= phaseCap, "Exceed current phase supply");
        require(supply.add(numTokens) <= maxSupply - reserved, "Exceed max supply");
        require(numTokens.mul(price) <= msg.value, "Incorrect amount sent");

        for (uint256 i; i < numTokens; i++) {
            _safeMint(msg.sender, supply.add(1).add(i));
        }
    }

    function startSale(uint256 _total, uint256 _mintAmount) external whenSaleStopped onlyOwner {
        require(_total > 0, "Missing total supply");
        require(_mintAmount > 0, "Missing total mint");
        saleStarted = true;
        
        if (saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
        if (_total != maxSupply) {
            setMaxSupply(_total);
        }
        if (_mintAmount != maxMint) {
            setMaxMint(_mintAmount);
        }
        emit BeginSale();
    }

    // Set token limit for each sale phase 
    function changeSalePhase(uint256 _cap, uint256 _price) external whenSaleStopped onlyOwner {
        setPrice(_price);
        setPhaseCap(_cap);
    }

    function stopSale() public whenSaleStarted onlyOwner {
        saleStarted = false;
        emit EndSale();
    }

    function isSaleStarted() public view returns(bool) {
        return saleStarted;
    }
    
    function isSaleStopped() public view returns(bool) {
        return !saleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    // Calculate current sale phase's supply
    function currentSupply() public view returns (uint256){
        return phaseCap - totalSupply();
    }

    // List all tokens in a specific wallet
    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Allow early reservation for team and community
    function reserveChild(address _to, uint256 _reserveAmount) public whenSaleStopped() onlyOwner { 
        uint supply = totalSupply();
        require(_to != address(0), "Cannot mint to null address");
        require(startingIndex != 0, "Starting index not set");
        require(_reserveAmount > 0 && _reserveAmount <= reserved, "Not enough reserve remaining");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply.add(1).add(i));
        }
        reserved = reserved.sub(_reserveAmount);
    }

    // Set final supply at sale start
    function setMaxSupply(uint256 total) public onlyOwner {
        maxSupply = total;
    }

    // Set mint limit at sale start
    function setMaxMint(uint256 _mintAmount) public onlyOwner {
        maxMint = _mintAmount;
    }

    // Update price for next sale phase
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Update supply for next sale phase
    function setPhaseCap(uint256 _newCap) public onlyOwner {
        phaseCap = _newCap;
    }

    function setReserved(uint256 _newReserved) public onlyOwner {
        reserved = _newReserved;
    }

    function setStartingIndex() public onlyOwner{
        require(startingIndex == 0, "Starting index is already set");

        // BlockHash only works for the most 256 recent blocks.
        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % maxSupply;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}