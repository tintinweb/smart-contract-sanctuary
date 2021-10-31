/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// Part: CryptoTraderInterface

interface CryptoTraderInterface {
    /**
     * Returns a uri for CryptTraderI (BTC) tokens
     */
    function btcTokenURI() external view returns (string memory);

    /**
     * Returns a uri for CryptTraderII (ETH) tokens
     */
    function ethTokenURI() external view returns (string memory);
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: CryptoTraderTokenUriProvider.sol

/**
 * Provides token metadata for CryptoTraderI and CryptoTraderII tokens
 */
contract CryptoTraderTokenUriProvider is CryptoTraderInterface {
    address owner;
    struct PriceRange {
        uint256 low;
        uint256 high;
        string tokenUriUp;
        string tokenUriDown;
    }

    PriceRange[] private btcPriceRanges;
    PriceRange[] private ethPriceRanges;

    AggregatorV3Interface private btcPriceFeed;
    AggregatorV3Interface private ethPriceFeed;
    uint80 private roundInterval = 50;

    /**
     * @dev Public constructor
     * _btcPriceFeed - address for the BTC/USD feed mainnet: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     * _ethPriceFeed - address for the ETH/USD feed mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor(address _btcPriceFeed, address _ethPriceFeed) public {
        owner = msg.sender;

        btcPriceFeed = AggregatorV3Interface(_btcPriceFeed);
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);

        populateRanges();
    }

    function populateRanges() private {
        btcPriceRanges.push(
            PriceRange({
                low: 0,
                high: 30000,
                tokenUriUp: "QmPXt5xgCCYz8BeiYNB46AraVrgEPHMs1bnWhrUCuAa4yp",
                tokenUriDown: "QmfTG6WooW25Ry88a6BkBHic6xeVnmuN8DPTuAU5AAeHJv"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 30001,
                high: 40000,
                tokenUriUp: "QmUgqXRYm5fy1memqr2d3FfEkpaeoziSNLhLE9sYN6Gd8v",
                tokenUriDown: "QmUGVMELqcUjJT2Zk5ED7DgYXfVgu831qMpiNcZL25VQ6r"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 40001,
                high: 65000,
                tokenUriUp: "QmP391qVmmweuQouZzC3WQPEkDKmRmbmzq9vyGGNohjBLY",
                tokenUriDown: "QmVUFkwMsrpsHYx6dEY2ZDWd3ochrgHJpks5iDLSajHpba"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 65001,
                high: 85000,
                tokenUriUp: "QmVJv6iSrM4vjQhuNi4oWiYdFk2MztSspuwuQvP7zzSd41",
                tokenUriDown: "QmbvHqmitVN5jpQDwXMc7M9bcABXVLgdSRp1tPVWQeBmyy"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 85001,
                high: 100000,
                tokenUriUp: "QmfM2wdvEFNqbGpP4gNUqCfE15i8F4ZbCX2VAS3LHGLTbU",
                tokenUriDown: "QmRGQSgJmvgGYpWWTcXytHksGdHfhAu3pcqkNknRj2KTbP"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 100001,
                high: 1000000,
                tokenUriUp: "QmZZaoaaLnYPEnwAwymRCWEdevqKTDFq6UdG26FUDwhqds",
                tokenUriDown: "QmcJQyteLVZwBAdhdZDSv1itMPT3GeicyRvBXDXNwwa8yJ"
            })
        );

        ethPriceRanges.push(
            PriceRange({
                low: 0,
                high: 2000,
                tokenUriUp: "QmYEwKc5P4X5u1GTv8AgGERpLki3feATDPNhXACRR2fSTt",
                tokenUriDown: "QmV2MKJDLU6DYsLAnFVUwB5EtyjpYsAcMfK3N4bQT98XoS"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 2001,
                high: 3500,
                tokenUriUp: "QmbDcmPrDTM3yxk7eEEMj8cs4vEfYywUwKQUZNwhbEy2Nx",
                tokenUriDown: "QmeAHsUnWWXRvPHbYKTmqU6aVyBqEGWQAZYyjL1Uvn4Xen"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 3501,
                high: 5000,
                tokenUriUp: "QmW5XvfMo6AmRuFVBkiijZde3rUN76289nGzcMnfuDnbW9",
                tokenUriDown: "QmPAWc7Gh56rxLgF9KnQbUXmpX7PutL1eB3yn1Vy3K2VJL"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 5001,
                high: 6500,
                tokenUriUp: "QmbaR2251n4J19wVFKJSaZqtntC5oPq4YYKY1WCfot7yPa",
                tokenUriDown: "QmewLCu62dim8PbgFeU1vQy6SyKkt1hUvurB3Fe7p3HQeH"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 6501,
                high: 8000,
                tokenUriUp: "QmbYtK2WFeD6oWqQBRiayZpLjUFjjFGdP9s1aS2RQtHuzi",
                tokenUriDown: "QmTWaiAfRkzWw4rterJaByNE2QcuLcbp7NaprnGSsLiRsk"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 8001,
                high: 100000,
                tokenUriUp: "QmSwxyymXnh3jUjr4aWXZLHJKwtsuhUxe9mPsk35as23GB",
                tokenUriDown: "Qmf7foHZuHZy8w3Adk1jsQdcS5QpJF1aFhYchdCrQwzEfU"
            })
        );
    }

    /**
     * get the price for 0: BTC, 1: ETH
     */
    function getPrice(uint8 priceType) private view returns (uint256, uint256) {
        AggregatorV3Interface feed = priceType == 0
            ? btcPriceFeed
            : ethPriceFeed;
        // current price data
        (uint80 roundId, int256 answer, , , ) = feed.latestRoundData();
        uint256 current = uint256(answer) / (10**uint256(feed.decimals()));

        // previous price data
        (, int256 prevAnswer, , , ) = feed.getRoundData(
            roundId - roundInterval
        );
        uint256 prev = uint256(prevAnswer) / (10**uint256(feed.decimals()));

        return (prev, current);
    }

    /**
     * Return the token uri for the given type BTC=0, ETH=1
     */
    function tokenUri(
        uint8 priceType,
        uint256 prevPrice,
        uint256 currentPrice
    ) private view returns (string memory) {
        PriceRange[] memory ranges = priceType == 0
            ? btcPriceRanges
            : ethPriceRanges;

        for (uint256 i = 0; i < ranges.length; i++) {
            if (
                currentPrice >= ranges[i].low && currentPrice <= ranges[i].high
            ) {
                if (prevPrice < currentPrice) {
                    return
                        string(
                            abi.encodePacked(
                                "https://ipfs.io/ipfs/",
                                ranges[i].tokenUriUp
                            )
                        );
                } else {
                    return
                        string(
                            abi.encodePacked(
                                "https://ipfs.io/ipfs/",
                                ranges[i].tokenUriDown
                            )
                        );
                }
            }
        }

        // by default return the middle case, but still check if we're up or down
        if (prevPrice < currentPrice) {
            return
                priceType == 0
                    ? "https://ipfs.io/ipfs/QmP391qVmmweuQouZzC3WQPEkDKmRmbmzq9vyGGNohjBLY"
                    : "https://ipfs.io/ipfs/QmW5XvfMo6AmRuFVBkiijZde3rUN76289nGzcMnfuDnbW9";
        }
        return
            priceType == 0
                ? "https://ipfs.io/ipfs/QmVUFkwMsrpsHYx6dEY2ZDWd3ochrgHJpks5iDLSajHpba"
                : "https://ipfs.io/ipfs/QmPAWc7Gh56rxLgF9KnQbUXmpX7PutL1eB3yn1Vy3K2VJL";
    }

    /**
     * Test method
     */
    function test(
        uint8 priceType,
        uint256 prevPrice,
        uint256 currentPrice
    ) public view returns (string memory) {
        return tokenUri(priceType, prevPrice, currentPrice);
    }

    /**
     * @dev Adds a BTC price range for the given _low/_high associated with the given
     * _tokenURIs.
     *
     * Requirements:
     * Caller must be contract owner
     */
    function addPriceRange(
        uint8 rangeType,
        uint256 _low,
        uint256 _high,
        string memory _tokenURIUp,
        string memory _tokenURIDown
    ) public {
        require(msg.sender == owner, "OCO");

        if (rangeType == 0) {
            btcPriceRanges.push(
                PriceRange({
                    low: _low,
                    high: _high,
                    tokenUriUp: _tokenURIUp,
                    tokenUriDown: _tokenURIDown
                })
            );
        } else {
            ethPriceRanges.push(
                PriceRange({
                    low: _low,
                    high: _high,
                    tokenUriUp: _tokenURIUp,
                    tokenUriDown: _tokenURIDown
                })
            );
        }
    }

    /**
     * @dev updates an ETH price range at the given _index
     *
     * Requirements:
     * Caller must be contract owner
     */
    function setPriceRange(
        uint256 rangeType,
        uint8 _index,
        uint256 _low,
        uint256 _high,
        string memory _tokenURIUp,
        string memory _tokenURIDown
    ) public {
        require(msg.sender == owner, "OCO");
        if (rangeType == 0) {
            require(_index < btcPriceRanges.length, "IOB");
            btcPriceRanges[_index].low = _low;
            btcPriceRanges[_index].high = _high;
            btcPriceRanges[_index].tokenUriUp = _tokenURIUp;
            btcPriceRanges[_index].tokenUriDown = _tokenURIDown;
        } else {
            require(_index < ethPriceRanges.length, "IOB");
            ethPriceRanges[_index].low = _low;
            ethPriceRanges[_index].high = _high;
            ethPriceRanges[_index].tokenUriUp = _tokenURIUp;
            ethPriceRanges[_index].tokenUriDown = _tokenURIDown;
        }
    }

    /**
     * @dev Set the round interval (how far back we should look for
     * for prev price data.  Typically it seems ~50 rounds per day)
     * Requirements:
     * Only contract owner may call this method
     */
    function setRoundInterval(uint80 _roundInterval) public {
        require(msg.sender == owner, "OCO");
        roundInterval = _roundInterval;
    }

    /**
     * @dev Returns the token metadata URI for CryptoTraderI
     */
    function btcTokenURI() public view override returns (string memory) {
        (uint256 prevPrice, uint256 currentPrice) = getPrice(0);
        return tokenUri(0, prevPrice, currentPrice);
    }

    /**
     * @dev Returns the token metadata URI for CryptoTraderII
     */
    function ethTokenURI() public view override returns (string memory) {
        (uint256 prevPrice, uint256 currentPrice) = getPrice(1);
        return tokenUri(1, prevPrice, currentPrice);
    }

    /**
     * Get the range at index
     */
    function getRange(uint8 index, uint8 forType)
        external
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory
        )
    {
        if (forType == 0) {
            require(index < btcPriceRanges.length, "IOB");
            return (
                btcPriceRanges[index].low,
                btcPriceRanges[index].high,
                btcPriceRanges[index].tokenUriUp,
                btcPriceRanges[index].tokenUriDown
            );
        } else {
            require(index < ethPriceRanges.length, "IOB");
            return (
                ethPriceRanges[index].low,
                ethPriceRanges[index].high,
                ethPriceRanges[index].tokenUriUp,
                ethPriceRanges[index].tokenUriDown
            );
        }
    }
}