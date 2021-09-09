// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";

contract OneDao is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public goldenCardCounter;
    Counters.Counter public silverCardCounter;

    uint256 private constant GOLDEN_CARD_PRICE = 5 * 10**17; // 0.5 ETH
    uint256 private constant SILVER_CARD_PRICE = 1 * 10**17; // 0.1 ETH

    uint256 private constant MAX_GOLDEN_CARD_COUNT = 100;
    uint256 private constant MAX_SILVER_CARD_COUNT = 5000;

    uint256 private constant MAX_TOKENS_PERTRANSACTION = 10;

    string private baseURIstring;

    event Withdraw(uint256 value);
    event SetBaseURI(string baseURI);

    constructor(string memory baseURI) ERC721("one dao", "DAO") {
        baseURIstring = baseURI;
    }

    function buyGoldenCard() external payable virtual {
        require(
            goldenCardCounter.current() < MAX_GOLDEN_CARD_COUNT,
            "OneDao: Exceed MAX_GOLDEN_CARD_COUNT"
        );
        require(
            GOLDEN_CARD_PRICE == msg.value,
            "OneDao: Ether value sent is too low"
        );

        _safeMint(msg.sender, goldenCardCounter.current());
        goldenCardCounter.increment();
    }

    function buySilverCard(uint256 tokensNumber) external payable virtual {
        require(tokensNumber > 0, "Wrong amount");
        require(
            silverCardCounter.current() + tokensNumber <= MAX_SILVER_CARD_COUNT,
            "OneDao: Exceed MAX_SILVER_CARD_COUNT"
        );
        require(
            tokensNumber <= MAX_TOKENS_PERTRANSACTION,
            "Max tokens per transaction number exceeded"
        );
        require(
            SILVER_CARD_PRICE * tokensNumber == msg.value,
            "OneDao: Ether value sent is too low"
        );

        for (uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, silverCardCounter.current() + 100);
            silverCardCounter.increment();
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
}