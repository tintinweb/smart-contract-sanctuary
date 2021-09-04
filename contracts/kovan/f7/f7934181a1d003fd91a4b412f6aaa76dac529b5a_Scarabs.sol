// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
  ___|                       |          
\___ \   __|  _` |  __| _` | __ \   __| 
      | (    (   | |   (   | |   |\__ \ 
_____/ \___|\__,_|_|  \__,_|_.__/ ____/ 
    
      Scarab Army
*/
                                          
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Scarabs is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    uint256 public constant PRESALE_ALLOCATION = 777;
    uint256 public constant PUBLIC_ALLOCATION = 7000;
    uint256 public constant MAX_SUPPLY = PRESALE_ALLOCATION + PUBLIC_ALLOCATION;
    uint256 public constant SCARAB_PRICE = 0.05 ether;
    uint256 public constant MAX_MINT_PER_TX = 10;
    
    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    
    string private _contractURI;
    string private _tokenBaseURI;
    string private _defaultBaseURI;
    address private _artistAddress = 0xB104D7d41DB4dB02eaB506c9c4109Ae842980440;
    address private _devAddress = 0xB104D7d41DB4dB02eaB506c9c4109Ae842980440;
    
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public presalePurchaseLimit = 2;
    bool public presaleLive;
    bool public saleLive;
    
    constructor() ERC721("Scarabs", "SCRB") { }
    
    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            presalerList[entry] = false;
        }
    }
    
    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "Sale is not live");
        require(!presaleLive, "Only presalers can buy");
        require(totalSupply() < MAX_SUPPLY, "All Scarabs have been minted");
        require(publicAmountMinted + tokenQuantity <= PUBLIC_ALLOCATION, "Minting would exceed the max pubic supply");
        require(tokenQuantity <= MAX_MINT_PER_TX, "You can only mint up to 10 Scarabs per transaction");
        require(SCARAB_PRICE * tokenQuantity <= msg.value, "Insufficient ETH sent");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "The presale is closed");
        require(presalerList[msg.sender], "You have not been whitelisted for presale");
        require(totalSupply() < MAX_SUPPLY, "All Vampires are minted");
        require(privateAmountMinted + tokenQuantity <= PRESALE_ALLOCATION, "Minting would exceed the presale allocation");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "You can mint up to 2 Vampires in the presale");
        require(SCARAB_PRICE * tokenQuantity <= msg.value, "Insufficient ETH sent");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_artistAddress).transfer(address(this).balance * 1 / 5);
        payable(_devAddress).transfer(address(this).balance * 1 / 5);
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }
    
    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }

    function isSaleActive() external view returns(bool) {
        return saleLive;
    }
    
    function isPresaleActive() external view returns(bool) {
        return presaleLive;
    }
    // Owner functions for enabling presale, sale, and revealing tokens
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function setDefaultBaseURI(string calldata URI) external onlyOwner {
        _defaultBaseURI = URI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return bytes(_tokenBaseURI).length > 0 ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : _defaultBaseURI;
    }
}