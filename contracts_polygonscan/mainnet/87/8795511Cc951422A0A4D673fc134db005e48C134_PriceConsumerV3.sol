/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT

// This example code is designed to quickly deploy an example contract using Remix.

pragma solidity ^0.8.0;



interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
interface VTokenInterface {
    function symbol() external view returns (string memory);
}


contract PriceConsumerV3 {

    mapping(string => address) chainlink;
    mapping(string => uint16) underlyingDecimals;

    constructor() {
        // /**
        // * Network: BSC Mainnet (decimals: 18)
        // */
        // chainlink["vUSDT"] = 0xf9d5AAC6E5572AEFa6bd64108ff86a222F69B64d; // USDT / BNB
        // chainlink["vBTC"] = 0xA338e0492B2F944E9F8C0653D3AD1484f2657a37; // BTC / BNB
        // chainlink["vETH"] = 0x63D407F32Aa72E63C7209ce1c2F5dA40b3AaE726; // ETH / BNB
        // chainlink["vLTC"] = 0x4e5a43A79f53c0a8e83489648Ea7e429278f8b2D; // LTC / BNB
        // chainlink["vDOT"] = 0xBA8683E9c3B1455bE6e18E7768e8cAD95Eb5eD49; // DOT / BNB

        // /**
        // * Network: BSC Testnet (decimals: 6)
        // */
        // chainlink["xGM"] = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526; // BNB / USD
        // chainlink["xUSDT"] = 0xEca2605f0BCF2BA5966372C99837b1F182d3D620; // USDT / USD
        // chainlink["xBTC"] = 0x5741306c21795FdCBb9b265Ea0255F499DFe515C; // BTC / USD
        // chainlink["xETH"] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7; // ETH / USD
        // chainlink["xLTC"] = 0x9Dcf949BCA2F4A8a62350E0065d18902eE87Dca3; // LTC / USD
        // chainlink["xGM_USD"] = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526; // BNB / USD
        // DOT not available on test net
        
        /**
        * Network: MATIC Mainnet (decimals: 8)
        */
        chainlink["xGM"] = 	0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // MATIC / USD
        chainlink["xUSDT"] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545; // USDT / USD
        chainlink["xBTC"] = 0xc907E116054Ad103354f2D350FD2514433D57F6f; // BTC / USD
        chainlink["xETH"] = 0xF9680D99D6C9589e2a93a78A04A279e509205945; // ETH / USD
        chainlink["xUSDC"] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7; // USDC / USD
        chainlink["xDAI"] = 0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D; // DAI / USD
        chainlink["xLINK"] = 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665; // LINK / USD
        chainlink["xGM_USD"] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // MATIC / USD


        underlyingDecimals["xGM"] = 18;
        underlyingDecimals["xUSDT"] = 6;
        underlyingDecimals["xBTC"] = 8;
        underlyingDecimals["xETH"] = 18;
        underlyingDecimals["xUSDC"] = 6;
        underlyingDecimals["xDAI"] = 18;
        underlyingDecimals["xLINK"] = 18;
    }

    /**
     * Returns the latest price
     */
    // function getUnderlyingPrice(VTokenInterface vToken) external view returns (uint256) {
    //     if (compareStrings(vToken.symbol(), "vBNB")) {
    //         return 1e18;
    //     } else {
    //         AggregatorV3Interface priceFeed = AggregatorV3Interface(chainlink[vToken.symbol()]);
    //         (
    //             uint80 roundID, 
    //             int price,
    //             uint startedAt,
    //             uint timeStamp,
    //             uint80 answeredInRound
    //         ) = priceFeed.latestRoundData();
    //         return uint256(price);
            
    //     }
    // }

    function getUnderlyingPrice(VTokenInterface vToken) external view returns (uint256) {
        string memory symbol = vToken.symbol();
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(chainlink[symbol]);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        uint16 scaleUpFactor = 10 + 18 - underlyingDecimals[symbol];

        return uint256(uint256(price) * 10 ** scaleUpFactor);
    }
    
    function getGMPriceInUSD() external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(chainlink["xGM_USD"]);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        return uint256(price * 1e10);
    }
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}