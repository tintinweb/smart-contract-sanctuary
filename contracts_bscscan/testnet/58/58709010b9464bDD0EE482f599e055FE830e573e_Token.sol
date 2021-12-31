// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IToken.sol";

contract Token is ERC20, Ownable, IToken {
    AggregatorV3Interface internal priceFeed;
    uint8 constant public priceUsdDecimals = 8;

    mapping (uint32 => Item) public items;
    uint32 public itemsCount;

    constructor() ERC20("STELS", "STL") {
        _mint(msg.sender, 100 * 10 ** 9 * 10 ** 18);
        itemsCount = 0;
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }

    event AddItem(string name, uint256 priceUsd, uint256 activeAfter);
    event UpdatePrice(uint32 indexed itemId, uint256 priceUsd);

    function itemAdd(string memory name, uint256 priceUsd, uint256 activeAfterDelay) external onlyOwner {
        items[itemsCount++] = Item(name, priceUsd, block.timestamp, block.timestamp + activeAfterDelay);

        emit AddItem(name, priceUsd, items[itemsCount-1].activeAfter);
    }

    function updateFeedAddress(address feedAddress) external onlyOwner {
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    function getPriceUSD() external view returns (uint256) {
        uint256 sum = 0;

        for (uint32 i = 0; i < itemsCount; i++) {
            if (items[i].activeAfter >= block.timestamp)
                continue;

            sum += items[i].priceUsd;
        }

        return sum / 100;
    }

    function getPriceBNB() external view returns (uint256) {
        uint256 price = scalePrice(this.getPriceUSD(), priceUsdDecimals, this.decimals());

        ( , int256 basePrice, , , ) = priceFeed.latestRoundData();
        uint8 baseDecimals = priceFeed.decimals();
        uint256 quotePrice = scalePrice(uint256(basePrice), baseDecimals, this.decimals());

        uint256 decimals = 10 ** uint256(this.decimals());

        return price * decimals / quotePrice;
    }

    function updatePrice(uint32 itemId, uint256 priceUsd) external onlyOwner {
        require(itemId < itemsCount, "TokenId must be not high tokens count");
        require(items[itemId].activeAfter < block.timestamp, "The token is not active");

        items[itemId].priceUsd = priceUsd;
        items[itemId].lastUpdate = block.timestamp;

        emit UpdatePrice(itemId, priceUsd);
    }

    function scalePrice(uint256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_priceDecimals < _decimals) {
            return _price * (10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / (10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function getLatestPrice() external view returns (uint256) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return uint256(price);
    }
}