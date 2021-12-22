// SPDX-License-Identifier: MIT
// A @FlagrantDev Contract.
// Floridaman lottery tickets base NFT contract
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract fmanLotto is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 100;

    // Current price in FMAN. 10 bil for now
    uint256 public CURRENT_PRICE = 10000000000;

    // Define if sale is active
    bool public saleIsActive = false;

    // FMAN Token Contract Addy
    address public fmanAddy = 0xC2aEbbBc596261D0bE3b41812820dad54508575b;

    // Address of "owner" wallet
    address private devAddress;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        devAddress = msg.sender;
    }

    /**
     * Withdraw
     */
    //TODO: make it withdraw FMAN
    function withdraw() public onlyOwner {
//        uint256 balance = address(this).balance;
        uint256 balance = IERC20(fmanAddy).balanceOf(address(this));
        IERC20(fmanAddy).transfer(devAddress, balance);
//        payable(devAddress).transfer(balance);
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
     * Set sale state
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
     * Mint Lottery Ticket NFTs
     */
    //TODO: Make it take FMAN
    function mintLotto(uint256 numberOfTokens) public payable {
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
            "Purchase would exceed max supply of lotto tickets"
        );
        require(
            IERC20(fmanAddy).balanceOf(msg.sender) >= CURRENT_PRICE.mul(numberOfTokens),
            "Get your money up, not your funny up."
        );
        uint256 payableTokens = CURRENT_PRICE.mul(numberOfTokens) * 10**18;
        IERC20(fmanAddy).transferFrom(msg.sender, address(this), payableTokens);
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

//    /**
//     * @FlagrantDev Changes the base URI if we want to move things in the future (Callable by owner only)
//     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

//    /**
//     * @FlagrantDev Base URI for computing {tokenURI}. Empty by default, can be overriden
//     * in child contracts.
//     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


//    /**
//     * @FlagrantDev Set the current token price
//     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

//    /**
//     * @FlagrantDev Update token address for the token to be used to mint.
//     */
    function setFMANAddy(address tokenaddy) public onlyOwner {
        fmanAddy = tokenaddy;
    }
}