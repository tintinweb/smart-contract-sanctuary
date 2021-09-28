// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SoulMagicChildZ is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public maxSupply = 5555;
    uint256 public maxMint = 5;
    uint256 public reserved = 5;
    uint256 public phaseCap = 1500;
    uint256 public price = 0.05 ether;

    bool private saleActive;
    uint256 public startingIndex;
    string public baseURI;

    // Withdraw address
    address receiver = 0x3d17c3f656d1EFbe7b21FAbb13535B0863b220B2;

    constructor() ERC721("Soul Magic Child Z", "CHDZ") {
        saleActive = false;
    }

    modifier whenSaleStarted() {
        require(saleActive, "Sale is not active");
        _;
    }
    
    modifier whenSaleStopped() {
        require(saleActive == false, "Sale already started");
        _;
    }

    /**
     * Public mint
     */
    function mintChild(uint256 numTokens) external payable whenSaleStarted {
        uint256 supply = totalSupply();

        require(numTokens <= maxMint, "Cannot mint more than purchase limit");
        require(supply.add(numTokens) <= phaseCap + reserved, "Exceed current phase supply");
        require(supply.add(numTokens) <= maxSupply - reserved, "Exceed max supply");
        require(numTokens.mul(price) <= msg.value, "Incorrect amount sent");

        for (uint256 i; i < numTokens; i++) {
            _safeMint(msg.sender, supply.add(1).add(i));
        }
    }

    /**
     * Allow reservation for team and community
     */
    function reserveChild(address _to, uint256 _reserveAmount) public onlyOwner { 
        uint supply = totalSupply();
        require(_to != address(0), "Cannot mint to null address");
        require(startingIndex != 0, "Starting index not set");
        require(_reserveAmount > 0 && _reserveAmount <= reserved, "Not enough reserve remaining");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply.add(1).add(i));
        }
        reserved = reserved.sub(_reserveAmount);
    }

    /**
     * Finalize sale
     */
    function initSale(uint256 _total, uint256 _mintAmount) external whenSaleStopped onlyOwner {
        setMaxSupply(_total);
        setMaxMint(_mintAmount);
        startSale();
    }
    
    function startSale() public whenSaleStopped onlyOwner {
        saleActive = true;
        
        if (saleActive && startingIndex == 0) {
            setStartingIndex();
        }
    }

    function stopSale() public whenSaleStarted onlyOwner {
        saleActive = false;
    }

    /**
     * Set price and limit for each phase 
     */
    function changeSalePhase(uint256 _cap, uint256 _price) external onlyOwner {
        setPhaseCap(_cap);
        setPrice(_price);
    }

    /**
     * Get remaining of current phase
     */
    function phaseBalance() public view returns (uint256){
        return phaseCap - totalSupply();
    }

    function isSaleStarted() public view returns(bool) {
        return saleActive;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setMaxSupply(uint256 _total) public onlyOwner {
        maxSupply = _total;
    }

    function setMaxMint(uint256 _mintAmount) public onlyOwner {
        maxMint = _mintAmount;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

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
        require(payable(receiver).send(balance));
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