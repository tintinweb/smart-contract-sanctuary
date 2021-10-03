// SPDX-License-Identifier: MIT
// File: contracts/GigaGardenShrooms.sol


pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Whitelist.sol";

/**
 * @title GigaGardenShrooms contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract GigaGardenShrooms is ERC721, Ownable, PaymentSplitter, Whitelist {
    using SafeMath for uint256;

    string public GGLSD_PROVENANCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant shroomPrice = 40000000000000000; //0.04 ETH

    uint public constant maxShroomPurchase = 5;

    uint256 public MAX_SHROOM_SUPPLY;

    uint256 public MAX_PRESALE_SHROOM_SUPPLY;

    bool public saleIsActive = false;

    bool public presaleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 maxPresaleNftSupply, uint256 saleStart, address[] memory addrs, uint256[] memory shares_, address[] memory wl_addrs) ERC721(name, symbol) PaymentSplitter(addrs,shares_) Whitelist(wl_addrs){
        MAX_SHROOM_SUPPLY = maxNftSupply;
        MAX_PRESALE_SHROOM_SUPPLY = maxPresaleNftSupply;
        REVEAL_TIMESTAMP = saleStart;
    }


    /**
     * Set some Flowers aside for giveaways and promotions
     */
    function reserveFlowers() public onlyOwner {        
        uint supply = totalSupply()+1;
        uint i;
        for (i = 0; i < 120; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * DM Samii in Discord that you're standing right behind him.
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        GGLSD_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        presaleIsActive = false;
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipPreSaleState() public onlyOwner {
        saleIsActive = false;
        presaleIsActive = !presaleIsActive;
    }
    /**
    * Mints Self Rising Flowers
    */
    function mintFlower(uint numberOfTokens) public payable {
        require(saleIsActive || presaleIsActive, "Sale must be active to mint Flowers");
        if(presaleIsActive && !saleIsActive){
            require(isWhitelisted(msg.sender),"Must be Whitelisted to mint before September 15, 2021 7:00:00 PM GMT");
            require(totalSupply().add(numberOfTokens) <= MAX_PRESALE_SHROOM_SUPPLY, "Purchase would exceed pre-sale max supply of 3000 Flowers");
        }
        require(numberOfTokens <= maxShroomPurchase, "Can only mint 5 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_SHROOM_SUPPLY, "Purchase would exceed max supply of 12000 Flowers");
        require(shroomPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply()+1;
            if (totalSupply() <= MAX_SHROOM_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_SHROOM_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SHROOM_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_SHROOM_SUPPLY;
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
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}