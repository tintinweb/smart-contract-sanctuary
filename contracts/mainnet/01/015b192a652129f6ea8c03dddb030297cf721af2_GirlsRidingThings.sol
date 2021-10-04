// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract GirlsRidingThings is Ownable, ERC721Enumerable, ReentrancyGuard {
    using SafeMath for uint8;
    using SafeMath for uint256;

    string private _baseTokenURI;

    uint8 public constant MAX_OWNER_TOKENS = 50;
    uint256 public constant TOKEN_PRICE = 0.02 ether;
    uint8 public constant MAX_PURCHASE = 10;

    bool public saleIsActive;
    uint256 public finalMaxTokens = 3333; // This can only be changed by freeze function
    uint256 public currentMaxTokens = 333;
    uint8 public ownerMintCount;

    constructor() ERC721("Girls Riding Things", "GRT") {
        _baseTokenURI = "https://www.girlsridingthings.io/grt_metadata/";
    }

    function mint(uint8 numberOfTokens) public payable nonReentrant {
        require(saleIsActive, "not allowed");
        require(numberOfTokens <= MAX_PURCHASE, "exceeds purchase limit");
        require(totalSupply().add(numberOfTokens) <= currentMaxTokens, "exceeds supply");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "send more ETH");

        uint256 tokenId;
        for(uint8 i; i < numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            _safeMint(msg.sender, tokenId);
        }
    }

    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintAsOwner(uint8 numberOfTokens) public onlyOwner {
        require(ownerMintCount.add(numberOfTokens) <= MAX_OWNER_TOKENS, "owner limit");
        require(totalSupply().add(numberOfTokens) <= finalMaxTokens, "exceeds supply");

        uint256 tokenId;
        for(uint8 i; i < numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            _safeMint(msg.sender, tokenId);
        }
    }

    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        require(maxTokens <= finalMaxTokens, "exceeds limit");
        currentMaxTokens = maxTokens;
    }

    function toggleSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        require(finalMaxTokens > 0, 'frozen');
        _baseTokenURI = newURI;
    }

    function freeze(uint8 passcode) public onlyOwner {
        require(passcode == 115, 'bad code');
        finalMaxTokens = 0;
        currentMaxTokens = 0;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}