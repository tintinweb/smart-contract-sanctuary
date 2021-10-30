/**
 *Submitted for verification at Etherscan.io on 2021-10-30
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

        populateBTCPriceRanges();
        populateETHPriceRanges();
    }

    /**
     * Populate the BTC price ranges with their initial values
     */
    function populateBTCPriceRanges() private {
        btcPriceRanges.push(
            PriceRange({
                low: 0,
                high: 30000,
                tokenUriUp: "https://ipfs.io/ipfs/QmPXt5xgCCYz8BeiYNB46AraVrgEPHMs1bnWhrUCuAa4yp",
                tokenUriDown: "https://ipfs.io/ipfs/QmfTG6WooW25Ry88a6BkBHic6xeVnmuN8DPTuAU5AAeHJv"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 30001,
                high: 40000,
                tokenUriUp: "https://ipfs.io/ipfs/QmUgqXRYm5fy1memqr2d3FfEkpaeoziSNLhLE9sYN6Gd8v",
                tokenUriDown: "https://ipfs.io/ipfs/QmUGVMELqcUjJT2Zk5ED7DgYXfVgu831qMpiNcZL25VQ6r"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 40001,
                high: 65000,
                tokenUriUp: "https://ipfs.io/ipfs/QmP391qVmmweuQouZzC3WQPEkDKmRmbmzq9vyGGNohjBLY",
                tokenUriDown: "https://ipfs.io/ipfs/QmVUFkwMsrpsHYx6dEY2ZDWd3ochrgHJpks5iDLSajHpba"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 65001,
                high: 85000,
                tokenUriUp: "https://ipfs.io/ipfs/QmVJv6iSrM4vjQhuNi4oWiYdFk2MztSspuwuQvP7zzSd41",
                tokenUriDown: "https://ipfs.io/ipfs/QmbvHqmitVN5jpQDwXMc7M9bcABXVLgdSRp1tPVWQeBmyy"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 85001,
                high: 100000,
                tokenUriUp: "https://ipfs.io/ipfs/QmfM2wdvEFNqbGpP4gNUqCfE15i8F4ZbCX2VAS3LHGLTbU",
                tokenUriDown: "https://ipfs.io/ipfs/QmRGQSgJmvgGYpWWTcXytHksGdHfhAu3pcqkNknRj2KTbP"
            })
        );
        btcPriceRanges.push(
            PriceRange({
                low: 100001,
                high: 150000,
                tokenUriUp: "https://ipfs.io/ipfs/QmZZaoaaLnYPEnwAwymRCWEdevqKTDFq6UdG26FUDwhqds",
                tokenUriDown: "https://ipfs.io/ipfs/QmcJQyteLVZwBAdhdZDSv1itMPT3GeicyRvBXDXNwwa8yJ"
            })
        );
    }

    /**
     * Populate the ETH price ranges with their initial values
     */
    function populateETHPriceRanges() private {
        ethPriceRanges.push(
            PriceRange({
                low: 0,
                high: 2000,
                tokenUriUp: "https://ipfs.io/ipfs/QmYEwKc5P4X5u1GTv8AgGERpLki3feATDPNhXACRR2fSTt",
                tokenUriDown: "https://ipfs.io/ipfs/QmV2MKJDLU6DYsLAnFVUwB5EtyjpYsAcMfK3N4bQT98XoS"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 2001,
                high: 3500,
                tokenUriUp: "https://ipfs.io/ipfs/QmbDcmPrDTM3yxk7eEEMj8cs4vEfYywUwKQUZNwhbEy2Nx",
                tokenUriDown: "https://ipfs.io/ipfs/QmeAHsUnWWXRvPHbYKTmqU6aVyBqEGWQAZYyjL1Uvn4Xen"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 3501,
                high: 5000,
                tokenUriUp: "https://ipfs.io/ipfs/QmW5XvfMo6AmRuFVBkiijZde3rUN76289nGzcMnfuDnbW9",
                tokenUriDown: "https://ipfs.io/ipfs/QmPAWc7Gh56rxLgF9KnQbUXmpX7PutL1eB3yn1Vy3K2VJL"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 5001,
                high: 6500,
                tokenUriUp: "https://ipfs.io/ipfs/QmbaR2251n4J19wVFKJSaZqtntC5oPq4YYKY1WCfot7yPa",
                tokenUriDown: "https://ipfs.io/ipfs/QmewLCu62dim8PbgFeU1vQy6SyKkt1hUvurB3Fe7p3HQeH"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 6501,
                high: 8000,
                tokenUriUp: "https://ipfs.io/ipfs/QmbYtK2WFeD6oWqQBRiayZpLjUFjjFGdP9s1aS2RQtHuzi",
                tokenUriDown: "https://ipfs.io/ipfs/QmTWaiAfRkzWw4rterJaByNE2QcuLcbp7NaprnGSsLiRsk"
            })
        );
        ethPriceRanges.push(
            PriceRange({
                low: 8001,
                high: 10000,
                tokenUriUp: "https://ipfs.io/ipfs/QmSwxyymXnh3jUjr4aWXZLHJKwtsuhUxe9mPsk35as23GB",
                tokenUriDown: "https://ipfs.io/ipfs/Qmf7foHZuHZy8w3Adk1jsQdcS5QpJF1aFhYchdCrQwzEfU"
            })
        );
    }

    /**
     * @dev Adds a BTC price range for the given _low/_high associated with the given
     * _tokenURIs.
     *
     * Requirements:
     * Caller must be contract owner
     */
    function addBTCPriceRange(
        uint256 _low,
        uint256 _high,
        string memory _tokenURIUp,
        string memory _tokenURIDown
    ) public {
        require(
            msg.sender == owner,
            "ONLY contract owner may call this method."
        );
        btcPriceRanges.push(
            PriceRange({
                low: _low,
                high: _high,
                tokenUriUp: _tokenURIUp,
                tokenUriDown: _tokenURIDown
            })
        );
    }

    /**
     * @dev Adds an ETH price range for the given _low/_high associated with the given
     * _tokenURIs.
     *
     * Requirements:
     * Caller must be contract owner
     */
    function addETHPriceRange(
        uint256 _low,
        uint256 _high,
        string memory _tokenURIUp,
        string memory _tokenURIDown
    ) public {
        require(
            msg.sender == owner,
            "ONLY contract owner may call this method."
        );
        ethPriceRanges.push(
            PriceRange({
                low: _low,
                high: _high,
                tokenUriUp: _tokenURIUp,
                tokenUriDown: _tokenURIDown
            })
        );
    }

    /**
     * @dev updates an ETH price range at the given _index
     *
     * Requirements:
     * Caller must be contract owner
     */
    function setETHPriceRange(
        uint8 _index,
        uint256 _low,
        uint256 _high,
        string memory _tokenURIUp,
        string memory _tokenURIDown
    ) public {
        require(
            msg.sender == owner,
            "ONLY contract owner may call this method."
        );
        ethPriceRanges[_index].low = _low;
        ethPriceRanges[_index].high = _high;
        ethPriceRanges[_index].tokenUriUp = _tokenURIUp;
        ethPriceRanges[_index].tokenUriDown = _tokenURIDown;
    }

    /**
     * @dev updates a BTC price range at the given _index
     *
     * Requirements:
     * Caller must be contract owner
     */
    function setBTCPriceRange(
        uint8 _index,
        uint256 _low,
        uint256 _high,
        string memory _tokenURIUp,
        string memory _tokenURIDown
    ) public {
        require(
            msg.sender == owner,
            "ONLY contract owner may call this method."
        );
        btcPriceRanges[_index].low = _low;
        btcPriceRanges[_index].high = _high;
        btcPriceRanges[_index].tokenUriUp = _tokenURIUp;
        btcPriceRanges[_index].tokenUriDown = _tokenURIDown;
    }

    /**
     * @dev Set the round interval (how far back we should look for
     * for prev price data.  Typically it seems ~50 rounds per day)
     * Requirements:
     * Only contract owner may call this method
     */
    function setRoundInterval(uint80 _roundInterval) public {
        require(
            msg.sender == owner,
            "ONLY contract owner may call this method."
        );
        roundInterval = _roundInterval;
    }

    /**
     * @dev Returns the prev and current price of BTC in USD
     * prev price is the price for round: current round - round interval
     */
    function getBTCPrice() public view returns (uint256, uint256) {
        // current price data
        (uint80 roundId, int256 answer, , , ) = btcPriceFeed.latestRoundData();
        uint256 current = uint256(answer) /
            (10**uint256(btcPriceFeed.decimals()));

        // previous price data
        (, int256 prevAnswer, , , ) = btcPriceFeed.getRoundData(
            roundId - roundInterval
        );
        uint256 prev = uint256(prevAnswer) /
            (10**uint256(btcPriceFeed.decimals()));

        return (prev, current);
    }

    /**
     * @dev Returns the prev and current price of ETH in USD
     * prev price is the price for round: current round - round interval
     */
    function getETHPrice() public view returns (uint256, uint256) {
        // current price data
        (uint80 roundId, int256 answer, , , ) = ethPriceFeed.latestRoundData();
        uint256 current = uint256(answer) /
            (10**uint256(ethPriceFeed.decimals()));

        // previous price data
        (, int256 prevAnswer, , , ) = ethPriceFeed.getRoundData(
            roundId - roundInterval
        );
        uint256 prev = uint256(prevAnswer) /
            (10**uint256(ethPriceFeed.decimals()));

        return (prev, current);
    }

    /**
     * @dev Returns the token metadata URI for CryptoTraderI
     */
    function btcTokenURI() public view override returns (string memory) {
        // We're going to return a tokenURI that will correspond to the
        // the price of BTC in USD. and whether or not the price has
        // gone up or down over the previous ~24 hours
        (uint256 prevPrice, uint256 currentPrice) = getBTCPrice();

        for (uint256 i = 0; i < btcPriceRanges.length; i++) {
            PriceRange memory p = btcPriceRanges[i];
            if (currentPrice >= p.low && currentPrice <= p.high) {
                if (prevPrice < currentPrice) {
                    return p.tokenUriUp;
                } else {
                    return p.tokenUriDown;
                }
            }
        }

        // by default return the middle case, but still check if we're up or down
        if (prevPrice < currentPrice) {
            return
                "https://ipfs.io/ipfs/Qmdgq6F74pGTrXLWKphAdJg9et1ddEow2bTFbxJgaANEdA";
        }
        return
            "https://ipfs.io/ipfs/Qmd2LMpHqMF4AzMmRD1XWdsk2HN6dfU7UBvwx7qnRTxnn8";
    }

    /**
     * @dev Returns the token metadata URI for CryptoTraderII
     */
    function ethTokenURI() public view override returns (string memory) {
        // We're going to return a tokenURI that will correspond to the
        // the price of ETH in USD. and whether or not the price has
        // gone up or down over the previous ~24 hours
        (uint256 prevPrice, uint256 currentPrice) = getETHPrice();

        for (uint256 i = 0; i < ethPriceRanges.length; i++) {
            PriceRange memory p = ethPriceRanges[i];
            if (currentPrice >= p.low && currentPrice <= p.high) {
                if (prevPrice < currentPrice) {
                    return p.tokenUriUp;
                } else {
                    return p.tokenUriDown;
                }
            }
        }

        // by default return the middle case, but still check if we're up or down
        if (prevPrice < currentPrice) {
            return
                "https://ipfs.io/ipfs/QmbFLzv4iDYzVRrtCw6firZQSeniLtw3AZ62xX86PvekGW";
        }
        return
            "https://ipfs.io/ipfs/QmTjJTui5ddstnqHyRM26zmajfGLwjAH7cqweCRdjSgTWL";
    }

    function btcTestTokenURI(uint256 prevPrice, uint256 currentPrice)
        public
        returns (string memory)
    {
        // We're going to return a tokenURI that will correspond to the
        // the price of BTC in USD. and whether or not the price has
        // gone up or down over the previous ~24 hours
        (uint256 prevPrice, uint256 currentPrice) = getBTCPrice();

        for (uint256 i = 0; i < btcPriceRanges.length; i++) {
            PriceRange memory p = btcPriceRanges[i];
            if (currentPrice >= p.low && currentPrice <= p.high) {
                if (prevPrice < currentPrice) {
                    return p.tokenUriUp;
                } else {
                    return p.tokenUriDown;
                }
            }
        }

        // by default return the middle case, but still check if we're up or down
        if (prevPrice < currentPrice) {
            return
                "https://ipfs.io/ipfs/Qmdgq6F74pGTrXLWKphAdJg9et1ddEow2bTFbxJgaANEdA";
        }
        return
            "https://ipfs.io/ipfs/Qmd2LMpHqMF4AzMmRD1XWdsk2HN6dfU7UBvwx7qnRTxnn8";
    }

    function ethTestTokenURI(uint256 prevPrice, uint256 currentPrice)
        public
        returns (string memory)
    {
        for (uint256 i = 0; i < ethPriceRanges.length; i++) {
            PriceRange memory p = ethPriceRanges[i];
            if (currentPrice >= p.low && currentPrice <= p.high) {
                if (prevPrice < currentPrice) {
                    return p.tokenUriUp;
                } else {
                    return p.tokenUriDown;
                }
            }
        }

        // by default return the middle case, but still check if we're up or down
        if (prevPrice < currentPrice) {
            return
                "https://ipfs.io/ipfs/QmbFLzv4iDYzVRrtCw6firZQSeniLtw3AZ62xX86PvekGW";
        }
        return
            "https://ipfs.io/ipfs/QmTjJTui5ddstnqHyRM26zmajfGLwjAH7cqweCRdjSgTWL";
    }
}