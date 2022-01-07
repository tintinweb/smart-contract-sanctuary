// SPDX-License-Identifier: MIT
// File: contracts/MoodyMushrooms.sol


pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

/**
 * @title MoodyMushrooms contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MoodyMushrooms is ERC721, Ownable, PaymentSplitter{
    using SafeMath for uint256;

    string public MM_PROVENANCE = "";

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant mushroomMintPrice = 50000000000000000; //0.05 ETH

    uint256 public constant whitelistMintPrice = 40000000000000000; //0.04 ETH

    uint public constant maxShroomPurchase = 3;

    uint256 public MAX_SHROOM_SUPPLY;

    uint256 public MAX_PRESALE_SHROOM_SUPPLY;

    bool public saleIsActive = false;

    bool public presaleIsActive = false;

    uint256 public REVEAL_TIMESTAMP;

    struct Account {
        uint mintedNFTs;
    }

    mapping(address => Account) public accounts;

    IERC721Enumerable public GigaGardenPass;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 maxPresaleNftSupply, uint256 saleStart, address[] memory addrs, uint256[] memory shares_) ERC721(name, symbol) PaymentSplitter(addrs,shares_){
        MAX_SHROOM_SUPPLY = maxNftSupply;
        MAX_PRESALE_SHROOM_SUPPLY = maxPresaleNftSupply;
        REVEAL_TIMESTAMP = saleStart;
        GigaGardenPass = IERC721Enumerable(0xc856ba90DB4AE83C1E73B2F43585ff56987DB272);
    }


    /**
     * Set some Moody Mushrooms aside for giveaways and promotions
     */
    function reserveMushrooms() public onlyOwner {        
        uint supply = totalSupply()+1;
        uint i;
        for (i = 0; i < 10; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * DM ImEmmy in Discord that you're standing right behind him.
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        MM_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setPassAddress(address contractAddr) public onlyOwner {
        GigaGardenPass = IERC721Enumerable(contractAddr);
    }
    function hasPass(address _address) public view returns(bool) {
        if(GigaGardenPass.balanceOf(_address)>0)
            return true;
        return false;
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
        require(saleIsActive || presaleIsActive, "Sale must be active to mint Moody Mushrooms");
        if(presaleIsActive && !saleIsActive){
            require(hasPass(msg.sender),"Must be Whitelisted to mint before Jan 15, 2022 11:00:00 PM GMT");
            require(totalSupply().add(numberOfTokens) <= MAX_PRESALE_SHROOM_SUPPLY, "Purchase would exceed pre-sale max supply of Moody Mushrooms");
        }
        require(numberOfTokens <= maxShroomPurchase, "Can only mint 3 Moody Mushrooms at a time");
        require((numberOfTokens.add(accounts[msg.sender].mintedNFTs)) <= maxShroomPurchase, "Sorry purchase would exceed 3 mints per wallet");
        require(totalSupply().add(numberOfTokens) <= MAX_SHROOM_SUPPLY, "Purchase would exceed max supply of Moody Mushrooms");
        if(hasPass(msg.sender))
            require(whitelistMintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        else
            require(mushroomMintPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(!isContract(msg.sender), "Contracts can't mint");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply()+1;
            if (totalSupply() <= MAX_SHROOM_SUPPLY) {
                accounts[msg.sender].mintedNFTs++;
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
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}