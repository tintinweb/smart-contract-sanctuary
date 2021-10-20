// SPDX-License-Identifier: MIT
/*
 _______  __   __  _______  _______  ______    ___   _  _______  ___       ___  __   __  _______ 
|       ||  | |  ||  _    ||       ||    _ |  |   | | ||   _   ||   |     |   ||  | |  ||       |
|       ||  |_|  || |_|   ||    ___||   | ||  |   |_| ||  |_|  ||   |     |   ||  | |  ||____   |
|       ||       ||       ||   |___ |   |_||_ |      _||       ||   |     |   ||  |_|  | ____|  |
|      _||_     _||  _   | |    ___||    __  ||     |_ |       ||   |  ___|   ||       || ______|
|     |_   |   |  | |_|   ||   |___ |   |  | ||    _  ||   _   ||   | |       ||       || |_____ 
|_______|  |___|  |_______||_______||___|  |_||___| |_||__| |__||___| |_______||_______||_______|

Discord: https://discord.gg/UtrRQavuzR
Twitter: https://twitter.com/cyberkaijuz

*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";


contract CyberKaijuzDeployer is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event MintNft(address indexed sender, uint256 startWith, uint256 times);

    //Important Variables
    uint256 public priceToMint = 0.05 * 10 ** 18;
    uint256 public totalNfts;
    uint256 public totalCount = 9999;
    uint256 public maxBatchPurchase = 20;
    bool private saleStarted;
    string public baseURI;
    

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    //Using a modifier to check minting paramaters 
    modifier canMint(uint256 _times) {
        require(saleStarted, "The minting sale has not started yet!");
        require(_times > 0 && _times <= maxBatchPurchase, "The maxmium minting batch is 20!");
        require(totalNfts + _times <= totalCount, "We have sold out!");
        require(msg.value == _times * priceToMint, "Incorrect ETH value received!");
        _;
    }
    
    function hasStarted() public view returns (bool)  {
        return saleStarted;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }


    //erc721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

        string memory baseURI2 = _baseURI();
        return bytes(baseURI2).length > 0 ? string(abi.encodePacked(baseURI2, tokenId.toString(), ".json")) : '.json';
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        priceToMint = newPrice;
    }
    
    function startSale(bool _start) public onlyOwner {
        saleStarted = _start;
    }
    
    function amountTokensOwned(address owner) public view returns (uint256) {
        uint256 count = balanceOf(owner);
        return count;
    }
    
    function mint(uint256 _times) payable public canMint(_times) {
        payable(owner()).transfer(msg.value);
       _mintToken(_times);
    }

    
    function _mintToken(uint256 _times) private {
        emit MintNft(_msgSender(), totalNfts + 1, _times);
        for(uint256 i = 0; i< _times; i++){
            _mint(_msgSender(), 1 + totalNfts++);
        }
    }
    
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    
}