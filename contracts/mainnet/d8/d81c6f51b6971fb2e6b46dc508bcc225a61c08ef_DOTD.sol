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

contract DOTD is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private devAddress;

    // Token detail
    struct DOTDDetail {
        uint256 first_encounter;
        address first_owner;
    }

    //Token Received Detail
    struct ReceivedDOTD {
        address owner;
        uint256 receivedTime;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => DOTDDetail) private _dotdDetails;

    // Token Received Tracking
    mapping(uint256 => ReceivedDOTD) private _receivedDOTD;

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply for devs
    uint256 public DEV_TOKENS = 101;
    // Keep track of number of dev tokens that have been minted
    uint256 public num_minted_dev;

    // Maximum amount of tokens to supply.
    // Max total tokens is 10000 + 101 = 10101 
    uint256 public MAX_TOKENS = DEV_TOKENS + 10000;

    // Current price.
    uint256 public CURRENT_PRICE = 0.03 ether;

    // Define if sale is active
    bool public saleIsActive = false;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        devAddress = msg.sender;

        // Too much gas to run here make sure to run reserve right after deploy :(
        // reserveTokens();
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
        uint256 first_encounter = block.timestamp;

        // Too much gas to run in a single transaction to break into 40 NFTs at a time
        uint256 end_index = totalSupply() + 40;

        if (num_minted_dev + 40 > DEV_TOKENS) {
            end_index = totalSupply() + (DEV_TOKENS - num_minted_dev);
	        num_minted_dev = DEV_TOKENS;
        } else {
	        num_minted_dev += 40;
	    }
	

        for (uint256 i = totalSupply() + 1; i <= end_index; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _dotdDetails[tokenId] = DOTDDetail(first_encounter, msg.sender);
                _receivedDOTD[tokenId] = ReceivedDOTD(
                    msg.sender,
                    block.timestamp
                );
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Mint a specific token.
     */
    function mintTokenId(uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId), "Token was minted");
        uint256 first_encounter = block.timestamp;
        _receivedDOTD[tokenId] = ReceivedDOTD(msg.sender, block.timestamp);
        _safeMint(msg.sender, tokenId);
        _dotdDetails[tokenId] = DOTDDetail(first_encounter, msg.sender);
        emit TokenMinted(tokenId, msg.sender, first_encounter);
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

    /**
     * Mint Day Of The Dead NFT
     */
    function mintDOTD(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Minting is currently disabled");
        require(
            numberOfTokens >= 1,
            "Must mint at least one token at a time"
        );
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of DOTD"
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Value does not match required amount"
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _dotdDetails[tokenId] = DOTDDetail(first_encounter, msg.sender);
                _receivedDOTD[tokenId] = ReceivedDOTD(
                    msg.sender,
                    block.timestamp
                );
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, "");
        _receivedDOTD[tokenId] = ReceivedDOTD(to, block.timestamp);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, _data);
        _receivedDOTD[tokenId] = ReceivedDOTD(to, block.timestamp);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
        _receivedDOTD[tokenId] = ReceivedDOTD(to, block.timestamp);
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
     *
     */
    function getNumMintedDev() public view returns (uint256) {
	return num_minted_dev;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /**
     * Get the token detail
     */
    function getDOTDDetail(uint256 tokenId)
        public
        view
        returns (DOTDDetail memory detail)
    {
        require(_exists(tokenId), "Token was not minted");

        return _dotdDetails[tokenId];
    }
}