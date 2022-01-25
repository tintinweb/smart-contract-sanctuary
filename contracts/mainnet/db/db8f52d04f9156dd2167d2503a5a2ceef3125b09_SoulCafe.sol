// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract SoulCafe is
    ERC721Enumerable,
    Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;
    
    address proxyRegistryAddress;

    uint256 public mintPrice = 0.03 ether; 
    uint256 public maxSupply = 3333;
    
    uint256 public saleTimeStamp;
    uint256 public revealTimeStamp;

    string private BASE_URI = "";

    address private sc = 0x78Cd6C571DeA180529C86ed42689dBDd0e5319ce;
    address private dev = 0xe97D9622C7189C2A2e7eC39A71cf77Bb25344082;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 saleStart,
        address proxyRegistryAddress_
    ) ERC721(name, symbol) {
        maxSupply = maxNftSupply;
        saleTimeStamp = saleStart;
        revealTimeStamp = saleStart + (86400 * 2);
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    function withdraw() public onlyOwner {
        payable(dev).transfer(address(this).balance.div(5));
        payable(sc).transfer(address(this).balance);
    }

    function reserve(uint256 num, address _to) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < num; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function setSaleTimestamp(uint256 timeStamp) public onlyOwner {
        saleTimeStamp = timeStamp;
    }

    function setRevealTimestamp(uint256 timeStamp) public onlyOwner {
        revealTimeStamp = timeStamp;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        BASE_URI = baseURI;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(block.timestamp >= saleTimeStamp, "Sale must be active to mint");
        require(
            totalSupply().add(numberOfTokens) <= maxSupply,
            "Purchase would exceed max supply"
        );
        require(
            mintPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _mint(msg.sender, mintIndex);
            }
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return block.timestamp >= revealTimeStamp 
        ? string(abi.encodePacked(BASE_URI, _tokenId.toString(), ".json")) 
        : contractURI() ;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmYacSSWSpfSraRsnQjR8gNbGwAk92F94UE4apgeFzQs6B";
    }
}