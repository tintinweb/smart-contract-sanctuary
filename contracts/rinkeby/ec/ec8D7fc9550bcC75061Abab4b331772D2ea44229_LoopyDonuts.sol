// SPDX-License-Identifier: UNLICENSED
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.0;

/**
 * @title Loopy Donuts contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract LoopyDonuts is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public PROVENANCE;
    uint256 public MAX_TOKENS;
    uint256 public REVEAL_TIMESTAMP;
    uint public constant RESERVE = 50;

    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    uint256 public donutPrice = 0.07 ether;
    uint256 public discountPrice1 = 0.06 ether;
    uint256 public discountPrice2 = 0.055 ether;

    uint256 public qtyDiscount1 = 5;
    uint256 public qtyDiscount2 = 10;

    uint public constant maxDonutPurchase = 20;

    bool public saleIsActive = false;

    // Base URIs - one for IPFS and the other for Arweave
    string public IpfsBaseURI;
    string public ArweaveBaseURI;

    // Contract lock - when set, prevents altering the base URLs saved in the smart contract
    bool public locked = false;

    enum StorageType { IPFS, ARWEAVE }

    StorageType public mainStorage;

    /**
    @param name - Name of ERC721 as used in openzeppelin
    @param symbol - Symbol of ERC721 as used in openzeppelin
    @param maxNftSupply - Maximum number of tokens to allow minting
    @param revealTs - Timestamp in seconds since epoch of the revealing time
    @param main - The initial StorageType value for mainStorage
     */
    constructor(string memory name,
                string memory symbol,
                uint256 maxNftSupply,
                uint256 revealTs,
                StorageType main,
                string memory provenance,
                string memory ipfsBase,
                string memory arweaveBase) ERC721(name, symbol) {
        MAX_TOKENS = maxNftSupply;
        REVEAL_TIMESTAMP = revealTs;
        mainStorage = main;
        PROVENANCE = provenance;
        IpfsBaseURI = ipfsBase;
        ArweaveBaseURI = arweaveBase;
    }

    /**
    * @dev Throws if the contract is already locked
    */
    modifier notLocked() {
        require(!locked, "Contract already locked");
        _;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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

    /**
     * Reserve Donuts for future activities and for supporters
     */
    function reserveDonuts() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < RESERVE; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * Sets the reveal timestamp
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner notLocked {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    /*     
    * Set provenance hash - just in case there is an error
    * Provenance hash is set in the contract construction time,
    * ideally there is no reason to ever call it.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner notLocked {
        PROVENANCE = provenanceHash;
    }

    /**
    * @dev Returns the base URI. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        if (mainStorage == StorageType.IPFS) {
            return IpfsBaseURI;
        } else {
            return ArweaveBaseURI;
        }
    }

     /**
     * @dev Sets the IPFS Base URI for computing {tokenURI}.
     * Ideally we will have already uploaded everything before deploying the contract.
     * This method - along with {setArweaveBaseURI} - should only be called if we didn't
     * complete uploading the images and metadata to IPFS and Arweave or if there is an unforseen error.
     */
    function setIpfsBaseURI(string memory newURI) public onlyOwner notLocked {
        IpfsBaseURI = newURI;
    }

     /**
     * @dev Sets the Arweave Base URI for computing {arweaveTokenURI}.
     */
    function setArweaveBaseURI(string memory newURI) public onlyOwner notLocked {
        ArweaveBaseURI = newURI;
    }

    /**
    * @dev Returns the URI to the token's metadata stored on Arweave
    */
    function arweaveTokenURI(uint256 tokenId) public view returns (string memory) {
        return getTokenURI(tokenId, StorageType.ARWEAVE);
    }

    /**
    * @dev Returns the URI to the token's metadata stored on IPFS
    */
    function ipfsTokenURI(uint256 tokenId) public view returns (string memory) {
        return getTokenURI(tokenId, StorageType.IPFS);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return getTokenURI(tokenId, mainStorage);
    }

    /**
    * @dev Returns the URI to the token's metadata stored on either Arweave or IPFS.
    * Takes into account the contracts' {startingIndex} which - alone - determines the allocation
    * of Loopy Donuts - ensuring a fair and completely random distribution.
    */
    function getTokenURI(uint256 tokenId, StorageType origin) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory base;
        string memory sequenceId;

        if (origin == StorageType.IPFS) {
            base = IpfsBaseURI;
        } else {
            base = ArweaveBaseURI;
        }

        if (startingIndex > 0) {
            sequenceId = ( (tokenId + startingIndex) % MAX_TOKENS ).toString();
        } else {
            sequenceId = "-1";
        }

        return bytes(base).length > 0 ? string( abi.encodePacked(base, sequenceId, ".json") ) : "";
    }

    /**
     * @dev Pause sale if active, activate if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * @dev Actual function that performs minting
    */
    function _mintDonuts(uint numberOfTokens, address sender) internal {
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_TOKENS || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * Mints Loopy Donuts
    */
    function mintDonut(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Donuts");
        require(numberOfTokens <= maxDonutPurchase, "Can only mint 20 donuts at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Donuts");
        require(getPricePerUnit(numberOfTokens).mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        _mintDonuts(numberOfTokens, msg.sender);
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_TOKENS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKENS;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev locks the contract (prevents changing the metadata base uris)
     */
    function lock() public onlyOwner notLocked {
        require(bytes(IpfsBaseURI).length > 0 &&
                bytes(ArweaveBaseURI).length > 0,
                "Thou shall not lock prematurely!");
        require(totalSupply() == MAX_TOKENS, "Not all Donuts are minted yet!");
        locked = true;
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function manualSetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    /**
     * @dev Sets the prices for minting - in case of cataclysmic ETH price movements
     */
     function setPrices(uint256 single, uint256 discount1, uint256 discount2) external onlyOwner notLocked {
         require(single >= discount1 && discount1 >= discount2 && discount2 > 0, "Invalid prices");
         donutPrice = single;
         discountPrice1 = discount1;
         discountPrice2 = discount2;
     }

     /**
     * @dev Sets the quantities that are eligible for discount.
     */
     function setDiscountQunatities(uint256 qty1, uint256 qty2) external onlyOwner notLocked {
         require( 0 < qty1 && qty1 <= qty2, "Invalid quantities");
         qtyDiscount1 = qty1;
         qtyDiscount2 = qty2;
     }

     /**
      * @dev Gets the available pricing options [qty, pricePerUnit, ...]
      */
      function getPricingOptions() public view returns (uint256[6] memory) {
          uint256[6] memory arr = [1, donutPrice, qtyDiscount1, discountPrice1, qtyDiscount2, discountPrice2];
          return arr;
      }

    /**
     * @dev Get the price per unit based on number of donuts to mint
     */
    function getPricePerUnit(uint numberOfTokens) public view returns (uint256) {
        if (numberOfTokens >= qtyDiscount2) {
            return discountPrice2;
        } else if (numberOfTokens >= qtyDiscount1) {
            return discountPrice1;
        }
        return donutPrice;
    }
}