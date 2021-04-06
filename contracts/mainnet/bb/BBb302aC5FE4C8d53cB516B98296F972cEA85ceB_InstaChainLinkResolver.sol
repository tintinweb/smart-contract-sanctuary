/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
    function description() external view returns (string memory);
}

contract Basic {
    ChainLinkInterface ethUsdPriceFeed = ChainLinkInterface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
}

contract Resolver is Basic {
    struct PriceData {
        uint price;
        uint decimals;
        string description;
    }

    function getPrice(address[] memory priceFeeds)
    public
    view
    returns (
        PriceData memory ethPriceInUsd,
        PriceData[] memory tokensPriceInETH
    ) {
        tokensPriceInETH = new PriceData[](priceFeeds.length);
        for (uint i = 0; i < priceFeeds.length; i++) {
            ChainLinkInterface feedContract = ChainLinkInterface(priceFeeds[i]);
            tokensPriceInETH[i] = PriceData({
                price: uint(feedContract.latestAnswer()),
                decimals: feedContract.decimals(),
                description: feedContract.description()
            });
        }
        ethPriceInUsd = PriceData({
            price: uint(ethUsdPriceFeed.latestAnswer()),
            decimals: ethUsdPriceFeed.decimals(),
            description: ethUsdPriceFeed.description()
        });
    }
}

contract InstaChainLinkResolver is Resolver {
    string public constant name = "ChainLink-Aggregator-Resolver-v1";
}