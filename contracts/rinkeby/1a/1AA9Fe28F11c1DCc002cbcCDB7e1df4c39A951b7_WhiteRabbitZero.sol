// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC1155.sol";

contract WhiteRabbitZero is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and phases
    uint256 public mintIndex;
    uint256 public availSupply = 765;
    bool public presaleEnded = false;
    bool public publicSaleEnded = false;
    bool public mintPaused = true;
    
    // price
    uint256 public pricePre = 0.06 ether;
    uint256 public priceMain = 0.08 ether;

    // limits
    uint256 public maxPerTx = 3;
    uint256 public maxPerWalletPre = 3;
    uint256 public maxPerWalletTotal = 10;
    
    // presale access
    IERC1155 public PresaleAccessToken;

    // tracking per wallet
    mapping(address => uint256) public mintedPresale;
    mapping(address => uint256) public mintedTotal;


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and by setting supply caps, mint indexes, and reserves
     */
    constructor()
        ERC721("WhiteRabbitZero", "WR0")
    {}
    
    /**
     * ------------ METADATA ------------ 
     */

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(metadataLocked == false);
        baseURI = _uri;
    }
    
    /**
     * @dev Lock metadata URI forever, callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(metadataLocked == false);
        metadataLocked = true;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    /**
     * ------------ SALE AND PRESALE ------------ 
     */
     
    /**
     * @dev Ends public sale forever, callable by owner
     */
    function endSaleForever() external onlyOwner {
        publicSaleEnded = true;
    }
    
    /**
     * @dev Ends the presale, callable by owner
     */
    function endPresale() external onlyOwner {
        presaleEnded = true;
    }

    /**
     * @dev Pause/unpause sale or presale
     */
    function togglePauseMinting() external onlyOwner {
        mintPaused = !mintPaused;
    }

    /**
     * ------------ CONFIGURATION ------------ 
     */

    /**
     * @dev Set presale access token address
     */
    function setPresaleAccessToken(address addr) external onlyOwner {
        PresaleAccessToken = IERC1155(addr);
    }
     
    /**
     * ------------ MINTING ------------ 
     */
    
    /**
     * @dev Mints `count` tokens to `to` address; internal
     */
    function mintInternal(address to, uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            _mint(to, mintIndex);
            mintIndex++;
        }
    }
    
    /**
     * @dev Public minting during public sale or presale
     */
    function mint(uint256 count) public payable{
        require(!mintPaused, "Minting is currently paused");
        require(publicSaleEnded == false, "Sale ended");
        require(availSupply >= count, "Supply exceeded");
        require(count <= maxPerTx, "Too many tokens");

        if (!presaleEnded) {
            // presale checks
            require(PresaleAccessToken.balanceOf(msg.sender, 1) > 0, "Not whitelisted");
            require(msg.value == count * pricePre, "Ether value incorrect");
            require(mintedPresale[msg.sender] + count <= maxPerWalletPre * PresaleAccessToken.balanceOf(msg.sender, 1), "Count exceeded during presale");
            mintedPresale[msg.sender] += count;
        } else {
            require(msg.value == count * priceMain, "Ether value incorrect");
            require(mintedTotal[msg.sender] + count <= maxPerWalletTotal, "Count exceeded during presale");
        }
        
        mintedTotal[msg.sender] += count;
        availSupply -= count;
        mintInternal(msg.sender, count);
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}