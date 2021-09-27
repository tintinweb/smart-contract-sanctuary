// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Burnable.sol';

/**
 * @title Ceramic contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract Ceramic is ERC721Burnable {
    using SafeMath for uint256;

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public mintPrice;
    uint256 public maxToMint;
    uint256 public MAX_CERAMIC_SUPPLY;
    uint256 public REVEAL_TIMESTAMP;
    uint256 public currentMintCount;

    bool public saleIsActive;

    address wallet;

    constructor() ERC721("Royal Ceramic Club", "RCCT") {
        MAX_CERAMIC_SUPPLY = 5000;
        REVEAL_TIMESTAMP = block.timestamp + (86400 * 7);
        mintPrice = 0.079 ether;
        maxToMint = 30;
        saleIsActive = false;
        wallet = 0xe2f071Fa6a421c6Bd7DF3635cC001c569182B950;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Set price to mint a Ceramic.
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /**
     * Set maximum count to mint per once.
     */
    function setMaxToMint(uint256 _maxValue) external onlyOwner {
        maxToMint = _maxValue;
    }

    /**
     * Mint Ceramics by owner
     */
    function reserveCeramics(address to, uint256 numberOfTokens) external onlyOwner {
        require(to != address(0), "Invalid address to reserve.");
        require(currentMintCount.add(numberOfTokens) <= MAX_CERAMIC_SUPPLY, "Reserve would exceed max supply");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(numberOfTokens);
    }

    /**
     * Set reveal timestamp when finished the sale.
     */
    function setRevealTimestamp(uint256 _revealTimeStamp) external onlyOwner {
        REVEAL_TIMESTAMP = _revealTimeStamp;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * Mints tokens
    */
    function mintCeramics(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens <= maxToMint, "Invalid amount to mint per once");
        require(currentMintCount.add(numberOfTokens) <= MAX_CERAMIC_SUPPLY, "Purchase would exceed max supply");
        require(mintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(numberOfTokens);

        // If we haven't set the starting index and this is either
        // 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (currentMintCount == MAX_CERAMIC_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() external {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_CERAMIC_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % MAX_CERAMIC_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(wallet).transfer(balance);
    }
}