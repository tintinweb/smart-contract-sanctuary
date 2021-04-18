// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC721.sol";

contract RareApes is ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant NFT_PRICE = 10**17;

    uint256 public constant MAX_NFT_SUPPLY = 5000;

    uint256 public immutable SALE_START_TIMESTAMP;

    uint256 public immutable REVEAL_TIMESTAMP;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address payable private immutable _owner;

    address payable private immutable _partner;

    constructor (
        string memory name, 
        string memory symbol, 
        string memory baseURI,
        uint256 saleStartTimestamp,
        address payable partner
        ) public ERC721 (name, symbol) {
            SALE_START_TIMESTAMP = saleStartTimestamp;
            REVEAL_TIMESTAMP = saleStartTimestamp + (86400 * 14);
            _owner = msg.sender;
            _partner = partner;
            _setBaseURI(baseURI);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(startingIndex > 0, "Tokens have not been revealed yet");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 realTokenId = tokenId.add(startingIndex) % MAX_NFT_SUPPLY;
        string memory base = baseURI();

        return string(abi.encodePacked(base, realTokenId.toString(), ".json"));
    }

    /**
    * @dev Mints NFT
    */
    function mintNFT(uint256 numberOfNfts) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(NFT_PRICE.mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
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
     * @dev Withdraw ether from this contract (Callable by owner and partner)
    */
    function withdraw() public {
        require(_msgSender() == _owner || _msgSender() == _partner, "Caller is neither the owner nor the withdrawal address");
        uint balance = address(this).balance;
        uint ownerAmount = balance.div(5);
        uint partnerAmount = balance - ownerAmount;
        _owner.transfer(ownerAmount);
        _partner.transfer(partnerAmount);
    }
}