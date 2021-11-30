// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract CosmicCritters is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and phases
    mapping(uint256 => uint256) public supplyForPhase;
    mapping(uint256 => uint256) public reserveForPhase;
    mapping(uint256 => uint256) public mintIndexForPhase;
    bool public presaleEnded = true;
    bool public publicSaleEnded = false;
    bool public mintPaused = false;
    uint256 public currentPhase = 0;

    // presale whitelist
    mapping(address => bool) public isWhitelisted;
    mapping(uint256 => mapping(address => uint256)) public mintedDuringPresaleAtPhase;
    event SetWhitelist(address[] added, address[] removed);
    
    // price
    uint256 public price12 = 0.07 ether;
    uint256 public price34 = 0.065 ether;
    uint256 public price56 = 0.06 ether;

    // limits
    uint256 public maxPerTxDuringSale = 6;
    uint256 public maxPerWalletDuringPresale = 2;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and by setting supply caps, mint indexes, and reserves
     */
    constructor()
        ERC721("CosmicCritters", "CRITTER")
    {
        supplyForPhase[1] = 2222;
        supplyForPhase[2] = 2222;
        supplyForPhase[3] = 2222;
        supplyForPhase[4] = 1111;

        reserveForPhase[1] = 55 + 110;
        reserveForPhase[2] = 55;
        reserveForPhase[3] = 55;
        reserveForPhase[4] = 35;

        mintIndexForPhase[1] = 0;
        mintIndexForPhase[2] = 2222;
        mintIndexForPhase[3] = 4444;
        mintIndexForPhase[4] = 6666;
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
    function endPresaleForCurrentPhase() external onlyOwner {
        presaleEnded = true;
    }

    /**
     * @dev Advance sale phase
     */
    function advanceToPresaleOfNextPhase() external onlyOwner {
        require(presaleEnded);
        require(currentPhase < 4);
        currentPhase++;
        presaleEnded = false;
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
    function editParameters(uint256 _price12, uint256 _price34, uint256 _price56, uint256 _maxPerTxDuringSale, uint256 _maxPerWalletDuringPresale) external onlyOwner {
        price12 = _price12;
        price34 = _price34;
        price56 = _price56;
        maxPerTxDuringSale = _maxPerTxDuringSale;
        maxPerWalletDuringPresale = _maxPerWalletDuringPresale;
    }
     
    /**
     * ------------ MINTING ------------ 
     */
    
    /**
     * @dev Mints `count` tokens to `to` address in `phase` phase of sale; phase can be one of [1,2,3,4]; internal
     */
    function mintInternal(address to, uint256 count, uint256 phase) internal {
        for (uint256 i = 0; i < count; i++) {
            _mint(to, mintIndexForPhase[phase]);
            mintIndexForPhase[phase]++;
        }
    }
    
    /**
     * @dev Manual minting by owner, callable by owner; phase can be one of [1,2,3,4]
     */
    function mintOwner(address[] calldata owners, uint256[] calldata counts, uint256 phase) external onlyOwner {
        require(owners.length == counts.length, "Bad length");
         
        for (uint256 i = 0; i < counts.length; i++) {
            require(reserveForPhase[phase] >= counts[i], "Reserve exceeded");
            
            mintInternal(owners[i], counts[i], phase);
            reserveForPhase[phase] -= counts[i];
            supplyForPhase[phase] -= counts[i];
        }
    }
    
    /**
     * @dev Gets the price tier from token count
     */
    function getPrice(uint256 count) public view returns (uint256) {
        if (count <= 2) {
            return price12;
        } else if (count <= 4) {
            return price34;
        } else {
            return price56;
        }
    }
    
    /**
     * @dev Public minting during public sale or presale
     */
    function mint(uint256 count) public payable{
        require(!mintPaused, "Minting is currently paused");
        require(currentPhase > 0, "Sale not started");
        require(publicSaleEnded == false, "Sale ended");

        require(msg.value == count * getPrice(count), "Ether value incorrect");
        require(supplyForPhase[currentPhase] - reserveForPhase[currentPhase] >= count, "Supply exceeded");
        
        if (presaleEnded) {
            // public sale checks
            require(count <= maxPerTxDuringSale, "Too many tokens");
        } else {
            // presale checks
            require(isWhitelisted[msg.sender], "You are not whitelisted");
            require(mintedDuringPresaleAtPhase[currentPhase][msg.sender] + count <= maxPerWalletDuringPresale, "Count exceeded during presale");
            mintedDuringPresaleAtPhase[currentPhase][msg.sender] += count;
        }
        
        supplyForPhase[currentPhase] -= count;
        mintInternal(msg.sender, count, currentPhase);
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}