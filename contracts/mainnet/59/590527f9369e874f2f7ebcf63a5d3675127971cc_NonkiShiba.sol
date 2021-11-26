// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract NonkiShiba is ERC721, ERC721Enumerable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxSupply = 7777;
    //address private ipfs = ;
    uint256 private gasForIPFS = 3;
    string public baseTokenURI = "ipfs://QmQ7Yhkd26EHJCCtmPvHjpFsymjG9D4xatasgZADxBkzg5/";

    bool public isPreSale = true;
    bool public isPubickSale = false;

    uint256 public preSalePrice = 0.05 ether;
    uint256 public preSaleMaxMint = 5;
    uint256 public preSaleMaxhold = 5;

    uint256 public pubSalePrice = 0.06 ether;
    uint256 public pubSaleMaxMint = 10;
    uint256 public pubSaleMaxhold = 250;
    
    constructor() ERC721("Nonki Shiba", "NONKISHIBA") {
        setBaseURI(baseTokenURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function mintPreSale(uint256 amt) public payable {
        require(isPreSale, "Can't mint for PreSale");
        require(amt>0 && amt<=preSaleMaxMint, "Not invalid amount");
        require(balanceOf(msg.sender)+amt > preSaleMaxhold, "Exceed max amount of hold");
        require(maxSupply>=totalSupply()+amt, "Exceed Max supply");
        require(msg.value >= preSalePrice * amt, "Not enough balance");
        
        for (uint256 i=0; i<amt; i++){
            safeMint(msg.sender);
        }

        uint256 _val1;
        (_val1, ) = prices();
        payable(owner()).transfer(_val1 * amt);
    }

    function mintPubSale(uint256 amt) public payable {
        require(isPubickSale, "Can't mint for PublicSale");
        require(amt>0 && amt<=pubSaleMaxMint, "Not invalid amount");
        require(balanceOf(msg.sender)+amt > pubSaleMaxhold, "Exceed max amount of hold");
        require(maxSupply>=totalSupply()+amt, "Exceed Max supply");
        require(msg.value >= pubSalePrice * amt, "Not enough balance");
        
        for (uint256 i=0; i<amt; i++){
            safeMint(msg.sender);
        }
        
        uint256 _val1;
        (_val1, ) = prices();
        payable(owner()).transfer(_val1 * amt);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setActivePublicSale() public onlyOwner {
        isPreSale = false;
        isPubickSale = true;
    }

    function setActivePreSale() public onlyOwner {
        require(!isPreSale, "Already actived");
        require(!isPubickSale, "Can't turn to presale from publicsale");
        isPreSale = true;
    }

    function setPreSalePrice(uint256 price) public onlyOwner {
        require(price>0, "Invalid Presale price");
        preSalePrice = price;
    }

    function setPublicSalePrice(uint256 price) public onlyOwner {
        require(price>0, "Invalid PublicSale price");
        require(pubSalePrice > preSalePrice, "Invalid PublicSale Price");
        pubSalePrice = price;
    }

    function setPresaleMaxMint( uint256 amt) public onlyOwner {
        require(amt>0, "Invalid amount");
        preSaleMaxMint = amt;
    }

    function setPresaleMaxHold( uint256 amt) public onlyOwner {
        require(amt>0, "Invalid amount");
        preSaleMaxhold = amt;
    }

    function setPublicSaleMaxMint( uint256 amt) public onlyOwner {
        require(amt>0, "Invalid amount");
        pubSaleMaxMint = amt;
    }

    function setPublicSaleMaxHold( uint256 amt) public onlyOwner {
        require(amt>0, "Invalid amount");
        pubSaleMaxhold = amt;
    }

    function prices() private view returns (uint256 , uint256) {
        if ( isPreSale ) {
             return (preSalePrice, 0);
        }
        if ( isPubickSale ) {
            return (pubSalePrice, 0);
        }
        return (0,0);
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

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");

        uint256 _balance = address(this).balance;
        payable(owner()).transfer(_balance);
    }
}