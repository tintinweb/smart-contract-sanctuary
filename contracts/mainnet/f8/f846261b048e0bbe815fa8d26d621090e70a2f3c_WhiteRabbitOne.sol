// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract WhiteRabbitOne is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and phases
    uint256 public mintIndex;
    uint256 public availSupply = 8765;
    bool public presaleEnded = false;
    bool public publicSaleEnded = false;
    bool public mintPaused = true;
    
    // price
    uint256 public constant PRICE_PRESALE = 0.06 ether;
    uint256 public constant PRICE_MAINSALE = 0.08 ether;

    // limits
    uint256 public constant MINTS_PER_PASS = 3;
    uint256 public constant MAX_PER_TX_PUBLIC_SALE = 15;
    uint256 public constant MAX_PER_WALLET_PUBLIC_SALE = 100;
    
    // presale access
    ERC1155Burnable public MintPass;
    uint256 public MintPassTokenId;

    // tracking per wallet
    mapping(address => uint256) public mintedPublicSale;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and by setting supply caps, mint indexes, and reserves
     */
    constructor()
        ERC721("WhiteRabbitOne", "WR1")
    {
        MintPass = ERC1155Burnable(0x29e99baEfeaC4FE2b3dDDBBfC18A517fb7D6DDf8);
        MintPassTokenId = 1;
    }
    
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
    function setMintPass(address addr, uint256 tokenId) external onlyOwner {
        MintPass = ERC1155Burnable(addr);
        MintPassTokenId = tokenId;
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
        require(count > 0, "Count can't be 0");
        require(!mintPaused, "Minting is currently paused");
        require(publicSaleEnded == false, "Sale ended");
        require(mintIndex + count <= availSupply, "Supply exceeded");

        if (!presaleEnded) {
            // presale checks
            uint256 mintPassBalance = MintPass.balanceOf(msg.sender, MintPassTokenId);
            require(count <= mintPassBalance * MINTS_PER_PASS, "Count too high");
            require(msg.value == count * PRICE_PRESALE, "Ether value incorrect");

            uint256 valueToBurn = (count+MINTS_PER_PASS-1)/MINTS_PER_PASS;
            MintPass.burn(msg.sender, MintPassTokenId, valueToBurn);
        } else {
            require(count <= MAX_PER_TX_PUBLIC_SALE, "Too many tokens");
            require(msg.value == count * PRICE_MAINSALE, "Ether value incorrect");
            require(mintedPublicSale[msg.sender] + count <= MAX_PER_WALLET_PUBLIC_SALE, "Count exceeded during public sale");
            mintedPublicSale[msg.sender] += count;
        }
        
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