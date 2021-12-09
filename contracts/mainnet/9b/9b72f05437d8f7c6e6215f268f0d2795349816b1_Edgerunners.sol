// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Edgerunners is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and phases
    uint256 public availSupply;
    uint256 public reservedSupply;
    uint256 public mintIndex;
    bool public presaleEnded = false;
    bool public publicSaleEnded = false;
    bool public mintPaused = true;

    // presale whitelist
    mapping(address => bool) public isWhitelisted;
    event SetWhitelist(address[] added, address[] removed);
    
    // price
    uint256 public price = 0.05 ether;

    // limits
    uint256 public maxPerTx = 8;
    uint256 public maxPerTxPresale = 5;
    
    // shareholder withdraw
    uint256 public withdrawnByOwner;
    uint256 public withdrawnByShareholder;
    address public shareholderAddress;
    uint256 public constant SHAREHOLDER_PERCENTAGE = 30;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and by setting supply caps, mint indexes, and reserves
     */
    constructor()
        ERC721("Edgerunners", "EDGE")
    {
        availSupply = 8888;
        reservedSupply = 250;
        shareholderAddress = 0xbCc4CD9BDdaCeFff7e0E7B9dd7a7d7FbC622a960;
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
     * @dev Edit whitelist
     */
    function editWhitelist(address[] calldata walletsToAdd, address[] calldata walletsToRemove) external onlyOwner {
        for (uint256 i = 0; i < walletsToAdd.length; i++) {
            isWhitelisted[walletsToAdd[i]] = true;
        }
        for (uint256 i = 0; i < walletsToRemove.length; i++) {
            isWhitelisted[walletsToRemove[i]] = false;
        }

        emit SetWhitelist(walletsToAdd, walletsToRemove);
    }

    /**
     * @dev Edit sale parameters: price points and count limits
     */
    function editParameters(uint256 _price, uint256 _maxPerTx, uint256 _maxPerTxPresale) external onlyOwner {
        price = _price;
        maxPerTx = _maxPerTx;
        maxPerTxPresale = _maxPerTxPresale;
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
     * @dev Manual minting by owner, callable by owner
     */
    function mintOwner(address[] calldata owners, uint256[] calldata counts) external onlyOwner {
        require(owners.length == counts.length, "Bad length");
         
        for (uint256 i = 0; i < counts.length; i++) {
            require(reservedSupply >= counts[i], "Reserve exceeded");
            
            mintInternal(owners[i], counts[i]);
            reservedSupply -= counts[i];
            availSupply -= counts[i];
        }
    }
    
    /**
     * @dev Public minting during public sale or presale
     */
    function mint(uint256 count) public payable{
        require(!mintPaused, "Minting is currently paused");
        require(publicSaleEnded == false, "Sale ended");

        require(msg.value == count * price, "Ether value incorrect");
        require(availSupply - reservedSupply >= count, "Supply exceeded");

        if (!presaleEnded) {
            // presale checks
            require(isWhitelisted[msg.sender], "You are not whitelisted");
            require(count <= maxPerTxPresale, "Too many tokens");
        }
        else {
            // public sale
            require(count <= maxPerTx, "Too many tokens");
        }

        availSupply -= count;
        mintInternal(msg.sender, count);
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 availableToWithdraw = ((balance + withdrawnByOwner + withdrawnByShareholder) * (100 - SHAREHOLDER_PERCENTAGE) / 100) - withdrawnByOwner;
        require(availableToWithdraw > 0, "Nothing to withdraw");
        withdrawnByOwner += availableToWithdraw;

        payable(msg.sender).transfer(availableToWithdraw);
    }

    /**
     * @dev Withdraw ether from this contract, callable by shareholder
     */
    function withdrawShareholder() external {
        require(msg.sender == shareholderAddress, "Only Shareholder");

        uint256 balance = address(this).balance;
        uint256 availableToWithdraw = ((balance + withdrawnByOwner + withdrawnByShareholder) * SHAREHOLDER_PERCENTAGE / 100) - withdrawnByShareholder;
        require(availableToWithdraw > 0, "Nothing to withdraw");
        withdrawnByShareholder += availableToWithdraw;

        payable(msg.sender).transfer(availableToWithdraw);
    }
}