// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract OneDao is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public goldCounter;
    Counters.Counter public silverCounter;

    uint256 private constant GOLD_PRICE = 5 * 10**17; // 0.5 ETH
    uint256 private constant SILVER_PRICE = 1 * 10**17; // 0.1 ETH

    uint256 private constant MAX_GOLD_COUNT = 100;
    uint256 private constant MAX_SILVER_COUNT = 5000;

    uint256 private constant MAX_SILVER_PERTRANSACTION = 10;

    string private baseURIstring;

    event Withdraw(uint256 value);
    event SetBaseURI(string baseURI);

    constructor(string memory baseURI) ERC721("One Dao", "DAO") {
        baseURIstring = baseURI;
    }

    function buyGold() external payable virtual {
        require(
            goldCounter.current() < MAX_GOLD_COUNT,
            "OneDao: Exceed MAX_GOLDE_COUNT"
        );
        require(GOLD_PRICE == msg.value, "OneDao: Ether value sent is too low");

        _safeMint(msg.sender, goldCounter.current());
        goldCounter.increment();
    }

    function buySilver(uint256 tokensNumber) external payable virtual {
        require(tokensNumber > 0, "Wrong amount");
        require(
            silverCounter.current() + tokensNumber <= MAX_SILVER_COUNT,
            "OneDao: Exceed MAX_SILVER_COUNT"
        );
        require(
            tokensNumber <= MAX_SILVER_PERTRANSACTION,
            "Max tokens per transaction number exceeded"
        );
        require(
            SILVER_PRICE * tokensNumber == msg.value,
            "OneDao: Ether value sent is too low"
        );

        for (uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, silverCounter.current() + 100);
            silverCounter.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIstring;
    }

    function setBaseURI(string memory baseURI) external virtual onlyOwner {
        baseURIstring = baseURI;
        emit SetBaseURI(baseURI);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "OneDao: The balance is 0");
        payable(msg.sender).transfer(balance);
        emit Withdraw(balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}