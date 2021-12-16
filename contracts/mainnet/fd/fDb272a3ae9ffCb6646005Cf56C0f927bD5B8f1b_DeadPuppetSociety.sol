// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC1155.sol";

contract DeadPuppetSociety is ERC721, Ownable {
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
    
    // price
    uint256 public price = 0.07 ether;

    // limits
    uint256 public maxPerTx = 50;
    
    // shareholder withdraw
    uint256 public withdrawnByOwner;
    uint256 public withdrawnByShareholder;
    address public shareholderAddress;
    uint256 public constant SHAREHOLDER_PERCENTAGE = 15;

    // presale access
    IERC1155 public PresaleAccessToken;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and by setting supply caps, mint indexes, and reserves
     */
    constructor()
        ERC721("DeadPuppetSocietyNFT", "DPS")
    {
        availSupply = 7000;
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
     * @dev Edit sale parameters: price points and count limits
     */
    function editParameters(uint256 _price, uint256 _maxPerTx) external onlyOwner {
        price = _price;
        maxPerTx = _maxPerTx;
    }

    /**
     * @dev Increase available (total) or reserved supply
     */
    function supplyAdd(uint256 _totalSupplyIncrease, uint256 _reservedSupplyIncrease) external onlyOwner {
        availSupply += _totalSupplyIncrease;
        reservedSupply += _reservedSupplyIncrease;
    }

    /**
     * @dev Decrease available (total) or reserved supply
     */
    function supplySubtract(uint256 _totalSupplyDecrease, uint256 _reservedSupplyDecrease) external onlyOwner {
        availSupply -= _totalSupplyDecrease;
        reservedSupply -= _reservedSupplyDecrease;
    }

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
            require(PresaleAccessToken.balanceOf(msg.sender, 1) > 0, "Not whitelisted");
        } else {
            // per tx limit during sale
            require(count <= maxPerTx, "Too many tokens");
        }
        
        availSupply -= count;
        mintInternal(msg.sender, count);
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external {
        require(msg.sender == shareholderAddress || msg.sender == owner(), "Only Shareholder");

        uint256 balance = address(this).balance;

        uint256 availableToWithdrawShareholder = balance * SHAREHOLDER_PERCENTAGE / 100;
        uint256 availableToWithdrawOwner = balance * (100-SHAREHOLDER_PERCENTAGE) / 100;

        require(balance > 0, "Nothing to withdraw");
        
        payable(owner()).transfer(availableToWithdrawOwner);
        payable(shareholderAddress).transfer(availableToWithdrawShareholder);
    }
}