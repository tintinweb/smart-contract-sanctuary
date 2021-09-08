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

contract HiveMind is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private devAddress;

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply for devs
    uint256 public DEV_TOKENS = 100;

    // Keep track of number of dev tokens that have been minted
    uint256 public numMintedDev;

    // Maximum amount of tokens to supply.
    // Max total tokens is 9900 + 100 = 10000
    uint256 public MAX_TOKENS = DEV_TOKENS + 9900;

    // Current price.
    uint256 public CURRENT_PRICE = 0.08 ether;

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
        // reserveTokens(20);
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
    function reserveTokens(uint256 num) public onlyOwner {
        uint256 tokenId;
        // Too much gas to run in a single transaction to break into 40 NFTs at a time
        uint256 end_index = totalSupply() + num;

        if (numMintedDev + num > DEV_TOKENS) {
            end_index = totalSupply() + (DEV_TOKENS - numMintedDev);
            numMintedDev = DEV_TOKENS;
        } else {
            numMintedDev += num;
        }
	

        for (uint256 i = totalSupply() + 1; i <= end_index; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
            }
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

    /**
     * Mint Hive Mind NFTs
     */
    function mintHM(uint256 numberOfTokens) public payable {
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
            "Purchase would exceed max supply of HiveMind"
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Value does not match required amount"
        );

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
     *
     */
    function getNumMintedDev() public view returns (uint256) {
        return numMintedDev;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }
}