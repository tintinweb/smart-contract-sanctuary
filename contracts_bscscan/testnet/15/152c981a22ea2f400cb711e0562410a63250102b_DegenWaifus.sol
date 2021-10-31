//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./SafeERC20.sol";

contract DegenWaifus is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private devAddress;

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;
    uint256 public MAX_PURCHASE_WHITELIST = 2;
    uint256 public MAX_PURCHASE_FREEMINT = 1;

    // Maximum amount of tokens to supply for devs
    // Note: 4 go to devs, 1 go to airdrop
    uint256 public DEV_TOKENS = 5;

    // Maximum amount of tokens to supply for free mint degens
    uint256 public FREEMINT_USERS = 5;
    uint256 public registeredFreemintUsers;
    mapping (address => bool) public freemintHolders;

    // Maximum amount of tokens to supply for whitelist degens
    uint256 public WHITELIST_USERS = 69;
    mapping (address => bool) public whitelistUsers;
    uint256 public registeredWhitelistUsers;
    uint256 public whitelistUserMinted;
    // If users do not claim whitelist position this flag can be flipped to turn to public claiming
    bool whitelistPhase = true;

    // Keep track of number of dev tokens that have been minted
    uint256 public numMintedDev;

    // Maximum amount of tokens to supply.
    // Max total tokens is 420
    uint256 public MAX_TOKENS = 420;

    // Current price.
    uint256 public CURRENT_PRICE = 0.042 ether;

    // Define if sale is active
    bool public saleIsActive = false;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        devAddress = msg.sender;

        reserveTokens();
    }

    /*
     * Function to add free minters
     */
    function addFreemint(address[] calldata accounts) public onlyOwner() {
        require(registeredFreemintUsers + accounts.length <= FREEMINT_USERS, "Can not add more than the max freemint users");
        registeredFreemintUsers = registeredFreemintUsers + accounts.length;
        for(uint256 i = 0; i < accounts.length; i++) {
            freemintHolders[accounts[i]] = true;
        }
    }

    /*
     * Function to add whitelist minters
     */
    function addWhitelist(address[] calldata accounts) public onlyOwner() {
        require(registeredWhitelistUsers + accounts.length <= (WHITELIST_USERS), "Can not add more than the max whitelist tokens");
        registeredWhitelistUsers = registeredWhitelistUsers + accounts.length;
        for(uint256 i = 0; i < accounts.length; i++) {
            whitelistUsers[accounts[i]] = true;
        }
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(devAddress).transfer(balance);
    }

    /**
     * Reserve first tokens for devs
     */
    function reserveTokens() public onlyOwner {
        uint256 tokenId;
        
        require(numMintedDev < DEV_TOKENS, "Dev cannot mint anymore tokens");

        numMintedDev = DEV_TOKENS;

        for (uint256 i = 0; i < DEV_TOKENS; i++) {
            tokenId = totalSupply().add(1);
            _safeMint(msg.sender, tokenId);
        }
    }

    /*
     * Set dev address
     */
    function setDevAddress(address newDevAddress) public onlyOwner {
        devAddress = newDevAddress;
    }

    /*
     * Set max tokens
     */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /*
     * Change whitelist stage
     */
    function setWhitelistState(bool newState) public onlyOwner {
        whitelistPhase = newState;
    }

    /*
     * Starts the sale
     */
    function getThemTitties(address[] calldata freemint, address[] calldata whitelist) public onlyOwner {
        setSaleState(true);
        addFreemint(freemint);
        addWhitelist(whitelist);
    }

    /**
     * Gets number of minted dev tokens
     */
    function getNumMintedDev() public view returns (uint256) {
	    return numMintedDev;
    }

    /**
     * Gets number of users mint whitelist
     */
    function getWhitelistUserMinted() public view returns (uint256) {
	    return whitelistUserMinted;
    }

    /**
     * Gets number of users mint whitelist
     */
    function getNumRegisteredWhitelistUsers() public view returns (uint256) {
	    return registeredWhitelistUsers;
    }

    function getWhitelistPhase() public view returns (bool) {
        return whitelistPhase;
    }

    /**
     * Mint Degen Waifus NFTs
     */
    function mintDW(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Minting is currently disabled");
        require(
            numberOfTokens >= 1,
            "Must mint at least one token at a time"
        );
        
        uint256 MAX_BUY = MAX_PURCHASE;
        if (whitelistPhase) {
            require(whitelistUsers[msg.sender], "User is not whitelisted");
            whitelistUsers[msg.sender] = false;
            MAX_BUY = MAX_PURCHASE_WHITELIST;
        }

        require(
            numberOfTokens <= MAX_BUY,
            "Can only mint MAX_PURCHASE tokens at a time"
        );

        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of DegenWaifus"
        );
       
        uint256 requiredPrice = CURRENT_PRICE.mul(numberOfTokens);
        if (freemintHolders[msg.sender]) {
            // User is using freemint
            freemintHolders[msg.sender] = false;
            // User saves one price of mint
            requiredPrice = requiredPrice.sub(CURRENT_PRICE);
        }
 
        require(
            requiredPrice <= msg.value,
            "Value does not match required amount"
        );

        if (whitelistPhase) {
            whitelistUserMinted = whitelistUserMinted + 1;

            if (whitelistUserMinted >= registeredWhitelistUsers) {
                whitelistPhase = false;
            }
        }

        uint256 curr_minted = totalSupply();
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, curr_minted.add(i));
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }
}