// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract FinalNFT is ERC721, ERC721Enumerable, Ownable {
    //OpenZeppelin Counter library used for tokenId Counter
    using Counters for Counters.Counter;
    //use OpenZeppelin SafeMath library to prevent overflows etc.
    using SafeMath for uint256;
    //use OpenZeppelin String library to convert uint256s to String
    using Strings for uint256;
    //use OpenZeppelin Address Library to send ether to contract owner
    using Address for address payable;


    //constants
    //provenance hash which is generated before deployment and can never be changed
    string public constant PROVENANCE_HASH = "abcdefg";
    //max supply of nfts ever to be created
    uint256 public constant MAX_NFT_SUPPLY = 4444;
    //max amount of nfts to be minted at once
    uint256 public constant MAX_PURCHASE_QTY = 10;
    //minting costs in wei
    uint256 public constant MINTING_PRICE = 20000000000000000;
    //reveal timestamp; after this date the startingIndexBlock will be set
    //gets set in the constructor and can never be changed, hence the all-caps name
    uint256 public REVEAL_TIMESTAMP;


    //variables
    //Counters.Counter starts at 0 so the first token will have id 1
    Counters.Counter private tokenIdCounter;
    //variables for the random distribution of the indices once the sale has ended
    uint256 private startingIndexBlock;
    uint256 private startingIndex;
    string private baseURI;


    //use constructor to set name and symbol in ERC721 parent contract
    constructor(uint256 revealTimestamp) ERC721("Final NFT", "FNFT") {
        REVEAL_TIMESTAMP = revealTimestamp;
    }


    /**
    * main mint function
    */
    function mint(uint256 numberOfTokens) public payable {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended!");
        require(totalSupply().add(numberOfTokens) <= MAX_NFT_SUPPLY, "Your purchase would exceed the maximum supply!");
        require(numberOfTokens <= MAX_PURCHASE_QTY, "You cannot mint more than 10 NFTs at once!");
        require(numberOfTokens > 0, "You cannot mint 0 NFTs!");
        require(MINTING_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is too small!");

        for (uint i = 0; i < numberOfTokens; i++) {
            tokenIdCounter.increment();
            uint tokenId = tokenIdCounter.current();

            //another safety check
            require(tokenId <= MAX_NFT_SUPPLY, "All NFTs have already been purchased");

            _safeMint(msg.sender, tokenId);
        }

        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;

        payable(msg.sender).sendValue(balance);
    }


    /**
    * tokenURI function, override ERC721
    * (tokenId + startingIndex) % MAX_NFT_SUPPLY -> initialSequenceId
    * example: tokenId = 100, startingIndex = 123, you get the token with id 223
    * https://forum.openzeppelin.com/t/are-nft-projects-doing-starting-index-randomization-and-provenance-wrong-or-is-it-just-me/14147
    *
    * if sale hasn't ended yet, tokenURI will point to metadata with index -1, where the placeholder image is
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (startingIndex != 0) {
            uint256 initialSequenceId = (tokenId + startingIndex) % MAX_NFT_SUPPLY;
            return string(abi.encodePacked(baseURI, initialSequenceId));
        }

        return string(abi.encodePacked(baseURI, "-1"));
    }

    /**
    * override ERC721 _baseURI() function
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //baseURI does not need to be a locked field, since a provenance hash is provided anyway
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function totalSupply() public view override returns (uint256) {
        return tokenIdCounter.current();
    }

    /**
     * Finalize starting index
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
    *
    */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }



    // The following functions are overrides required by Solidity.

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