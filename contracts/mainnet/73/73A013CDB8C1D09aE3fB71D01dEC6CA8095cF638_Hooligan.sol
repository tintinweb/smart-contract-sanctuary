// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Hooligan is
    ERC721Enumerable,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    using SafeMath for uint256;
    using Strings for uint256;
    
    address proxyRegistryAddress;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public constant mintPrice = 60000000000000000; 

    uint256 public constant maxPurchase = 20;

    uint256 public MAX_SUPPLY;

    bool public saleIsActive = true;

    uint256 public SALE_TIMESTAMP;
    uint256 public REVEAL_TIMESTAMP;

    string private BASE_URI;

    address private brian = 0xCc806ea8292c904a3682cA86Ed4131fe02bC8e29;
    address private dev = 0xAE77beeda3c1BB43B1cAEaE04815F68e1c07e077;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 saleStart,
        address proxyRegistryAddress_
    ) ERC721(name, symbol) {
        MAX_SUPPLY = maxNftSupply;
        SALE_TIMESTAMP = saleStart;
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    function withdraw() public onlyOwner {
        payable(dev).transfer(address(this).balance.div(20));
        payable(brian).transfer(address(this).balance);
    }

    function reserve(address _to) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < 30; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function setSaleTimestamp(uint256 saleTimeStamp) public onlyOwner {
        SALE_TIMESTAMP = saleTimeStamp;
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        BASE_URI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive && block.timestamp >= SALE_TIMESTAMP, "Sale must be active to mint");
        require(
            numberOfTokens <= maxPurchase,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(
            mintPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % MAX_SUPPLY;
        }
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return block.timestamp >= REVEAL_TIMESTAMP 
        ? string(abi.encodePacked(BASE_URI, _tokenId.toString(), ".json")) 
        : "https://ipfs.io/ipfs/QmczY2ZWNaYfq9NX2m8hy8ivFoRFkdsuuXN4ZitNn6imHX";
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function contractURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmPgi5g94h63tn7Ap2CWa2QjCesecSQS1SBJ7LXmG2k85V";
    }
}