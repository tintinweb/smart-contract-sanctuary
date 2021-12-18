// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "ReentrancyGuard.sol";
import "ERC721.sol";
import "Ownable.sol";
import "Counters.sol";
import "Address.sol";

contract FunnyMonkeys is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    constructor(string memory customBaseURI_) ERC721("FunnyMonkeys", "FNMK") {
        customBaseURI = customBaseURI_;
    }

    /** MINTING **/

    uint256 public constant MAX_SUPPLY = 4200;

    uint256 public constant MAX_MULTIMINT = 20;

    uint256 public constant PRICE = 10000000000000000;

    Counters.Counter private supplyCounter;

    function mint(uint256 count) public payable nonReentrant {
        require(saleIsActive, "Sale not active");

        require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

        require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

        require(
            msg.value >= PRICE * count,
            "Insufficient payment, 0.01 ETH per item"
        );

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), totalSupply());

            supplyCounter.increment();
        }
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    /** ACTIVATION **/

    bool public saleIsActive = true;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    /** URI HANDLING **/

    string private customBaseURI;

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    /** PAYOUT **/

    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), balance);
    }
}

// Contract created with Studio 721 v1.4.0
// https://721.so