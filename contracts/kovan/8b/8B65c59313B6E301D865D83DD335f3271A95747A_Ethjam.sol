// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Encoding.sol";

import "./Fetcher.sol";
import "./Metadata.sol";
import "./SVG.sol";
import "./DateTimeAPI.sol";

contract Ethjam is ERC721 {

    using Counters for Counters.Counter;
    Counters.Counter public tokenIdTracker;

    // TODO: Set contractOwner in a more dynamic way?
    address payable constant contractOwner = payable(0xeBf90f3f11475166460890eF953D9141FD6174bC);

    // TODO: use correct deployed DateTimeAPI instance based on network
    // DateTimeAPI dates = DateTimeAPI(0x92482Ba45A4D2186DafB486b322C6d0B88410FE7); // rinkeby
    DateTimeAPI dates = DateTimeAPI(0x5C3D0ABABf110CdC54af47445D9739F5C1776E9E); // kovan
    // DateTimeAPI dates = DateTimeAPI(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce); // mainnet

    Metadata metadata = new Metadata(dates);
    Fetcher fetcher;
    SVG svg = new SVG();
    uint80 constant SECONDS_PER_DAY = 3600*24;
    uint mintPrice = 0.01 * 10**18; 

    mapping (uint256 /*tokenId*/ => uint /*timestamp*/) public fromTimestamps;

    mapping (uint /*timestamp*/ => uint256[]) internal tokenIdsForDate;

    constructor() ERC721("Etherjam", "EJ") {
        _mint(msg.sender, 0);
    }

    function setFetcher(Fetcher f) public {
        require(msg.sender == contractOwner, 'Only contractOwner can set NFT price');
        fetcher = f;
    }

    function getStartOfDay(uint timestamp) internal view returns (uint) {
        uint16 year = dates.getYear(timestamp);
        uint8 month = dates.getMonth(timestamp);
        uint8 day = dates.getDay(timestamp);
        return dates.toTimestamp(year,month,day);
    }

    function dateToString(uint timestamp) internal view returns (string memory) {
        uint16 year = dates.getYear(timestamp);
        uint8 month = dates.getMonth(timestamp);
        uint8 day = dates.getDay(timestamp);

        string memory displayDate = string(
            abi.encodePacked(
                Encoding.uint2str(month), '/', Encoding.uint2str(day), '/', Encoding.uint2str(year)
            ));
        return displayDate;
    }

    // This should fail
    /*
    function aa_testMintWithBadTimestamp() public returns (uint256) {
        uint badTimestamp = 1639633472;
        return mint(badTimestamp);
    }*/

	function getNFTPrice() public view returns (uint) /*wei*/ {
		return mintPrice; 
	}

    function setNFTPrice(uint newPrice) public {
        require(msg.sender == contractOwner, 'Only contractOwner can set NFT price');
        mintPrice = newPrice;
    }

	function withdraw() public payable {
        require(msg.sender == contractOwner, 'Only contractOwner can withdraw');
        contractOwner.transfer(payable(address(this)).balance);
	}

    function mint(uint fromTimestamp) public payable returns (uint256) {
        // Verify that this timestamp represents the start of a day
        require(fromTimestamp == getStartOfDay(fromTimestamp));

        // Verify that this day has completed
        require(fromTimestamp + SECONDS_PER_DAY < block.timestamp);

        // Verify that we haven't exceeded the token supply for this day
        uint existingTokensForDate = tokenIdsForDate[fromTimestamp].length;
        require(existingTokensForDate == 0);

				require(getNFTPrice() <= msg.value, "The Amount of Ether sent is not correct.");

        tokenIdTracker.increment();
        uint256 newItemId = tokenIdTracker.current();
        fromTimestamps[newItemId] = fromTimestamp;

        _mint(msg.sender, newItemId);
        tokenIdsForDate[fromTimestamp].push(newItemId);
        return newItemId;

    }

    // Will fetch perpetual data if tokenId is zero
    function getPriceDataForCoin(uint256 tokenId, Fetcher.Coin coin) internal view returns (int32[] memory) {
        uint256 fromTimestamp;
        if (tokenId == 0) {
            fromTimestamp = 0;
        } else {
            fromTimestamp = fromTimestamps[tokenId];
        }
        return fetcher.fetchCoinPriceData(fromTimestamp, coin);
    }

    function getDisplayDateForTokenId(uint256 tokenId) internal view returns (string memory) {
        uint fromTimestamp = fromTimestamps[tokenId];

        string memory displayDate;

        if (tokenId == 0) {
            displayDate = "Gold Master";
        } else {
            return dateToString(fromTimestamp);
        }

        return displayDate;
    }

    struct DayData {
        uint fromTimestamp;
        uint256[] tokenIds;
        string ethData;
        string btcData;
        string bgHue;
    }

    function bgHueForPriceData(string memory priceData) internal pure returns (uint256) {
        uint256 hue = uint256(keccak256(bytes(priceData)))%360;
        return hue;
    }

    // Will return an array of DayData structs for all minted days + all days within the specified time period
    // Note:
    // - array is not sorted by timestamp
    // - some timestamps may be represented by multiple dayData structs

    function getAllDataForNumDays(uint256 startTimestamp, uint256 numDays) external view returns (DayData[] memory) {
        DayData[] memory dayData = new DayData[](numDays + tokenIdTracker.current());
        for (uint i = 0; i < numDays; i++) {
            uint fromTimestamp = startTimestamp + (i * SECONDS_PER_DAY);
            dayData[i] = getAllDataForDay(fromTimestamp);
        }
        return dayData;
    }

    function getAllDataForDay(uint256 fromTimestamp) public view returns (DayData memory) {
        require(fromTimestamp == getStartOfDay(fromTimestamp));

        uint256[] memory tokenIds = tokenIdsForDate[fromTimestamp];
        int32[] memory ethData = fetcher.fetchCoinPriceData(fromTimestamp, Fetcher.Coin.ETH);
        int32[] memory btcData = fetcher.fetchCoinPriceData(fromTimestamp, Fetcher.Coin.BTC);
        string memory ethDataString = Encoding.encode(ethData);
        string memory btcDataString = Encoding.encode(btcData);

        string memory bgHue = Encoding.uint2str(bgHueForPriceData(ethDataString));

        return DayData(fromTimestamp, tokenIds, ethDataString, btcDataString, bgHue);
    }


    function getSVGImageWith(uint256 tokenId, uint256 bgHue, int32[] memory ethPriceData) internal view returns (string memory) {
        int32 displayPrice = ethPriceData[ethPriceData.length - 1];

        return tokenId == 0 ? svg.masterImageWith(displayPrice) : svg.printImageWith(displayPrice, bgHue);
    }


    // NOTE: OpenSea will choke if the animation_url is too long.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory displayDate = getDisplayDateForTokenId(tokenId);
        uint fromTimestamp = (tokenId == 0 ? fetcher.perpetualDataStartTime() : fromTimestamps[tokenId]);
        string memory ethPriceDataString;
        string memory svgImage;
        string memory attributesStr;
        uint256 bgHue;
        {
            int32[] memory ethPriceData = getPriceDataForCoin(tokenId, Fetcher.Coin.ETH);
            ethPriceDataString = Encoding.encode(ethPriceData);
            bgHue = bgHueForPriceData(ethPriceDataString);
            svgImage = getSVGImageWith(tokenId, bgHue, ethPriceData);
            attributesStr = metadata.getAttributes(ethPriceData, fromTimestamp, tokenId);
        }
        int32[] memory btcPriceData = getPriceDataForCoin(tokenId, Fetcher.Coin.ETH);

        return string(
            abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                abi.encodePacked(
                    '{',
                    '"description":"Generated from Ethereum price data"',
                    unicode', "name":"Etherjam · ', displayDate,
                    '"',
                    ', "image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svgImage)),
                    '"',
                    ', "animation_url":"',
                    // TODO: replace with IPFS URL before deploying, per below
                    //'ipfs://QmSWKmtG8AdgvbuqeWYmMDGxpArkZRoqgwgpJnvnkhebCC/?',
                    'https://ethjam-36605.web.app/j?',
                    tokenId == 0 ? "master=1&" : "",
                    'c=', Encoding.uint2str(bgHue),
                    '&ETH=', ethPriceDataString,
                    '&BTC=', Encoding.encode(btcPriceData),
                    '"',
                    ', "attributes": ', attributesStr,
                    '}'
                )
                )
            )
            )
        );
    }

    function contractURI() external pure returns (string memory) {
        // TODO: move to ipfs before launch
        return 'https://ethjam-36605.web.app/contract.json';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Encoding.sol";

contract SVG {
    string internal constant svg1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" fill="none"><style>.priceTicker{font-size:6px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol";fill:#fff;text-shadow:0 1px 5px rgba(0,0,0,10%)}.dollarSign,.priceLabel{font-size:3em}.priceField{font-size:5em;font-weight:700}';
    string internal constant svg2 = '</style><defs><linearGradient id="bgGradient" gradientTransform="rotate(90)"><stop offset="0%" class="stop1"/><stop offset="33%" class="stop2"/><stop offset="67%" class="stop1"/><stop offset="100%" class="stop2"/></linearGradient><filter id="white-glow" x="-5000%" y="-5000%" width="10000%" height="10000%"><feFlood result="flood" flood-color="#ffffff" flood-opacity="1"/><feComposite in="flood" result="mask" in2="SourceGraphic" operator="in"/><feMorphology in="mask" result="dilated" operator="dilate" radius="2"/><feGaussianBlur in="dilated" result="blurred" stdDeviation="5"/><feMerge><feMergeNode in="blurred"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs><path d="M0 0h6e2v6e2H0z" fill="url(#bgGradient)"/><rect id="theDot" filter="url(#white-glow)" x="75%" y="44.4%" width="3.84615%" height="5.6%" ry="3" fill="#fff"/><text class="priceTicker" x="95%" y="44.9%" text-anchor="end"><tspan x="95.5%" class="dollarSign">$</tspan><tspan dy="0" class="priceField">';
    string internal constant svg3 = '</tspan><tspan x="95.2%" dy="4%" class="priceLabel">ETH/USD</tspan></text></svg>';
    function printImageWith(int32 displayPrice, uint256 bgHue) external pure returns (string memory) {
        uint256 bgHue2 = (bgHue + 40) % 360;
        return string(
            abi.encodePacked(
                svg1,
                '.stop1 { stop-color: hsl(', Encoding.uint2str(bgHue), ',100%,70%); }',
                '.stop2 { stop-color: hsl(', Encoding.uint2str(bgHue2), ',100%,70%); }',
                svg2,
                Encoding.uint2str(uint32(displayPrice)),
                svg3));
    }
    function masterImageWith(int32 displayPrice) external pure returns (string memory) {
        return string(
            abi.encodePacked(
                svg1,
                '.stop1 { stop-color: hsl(0,0%,10%); }',
                '.stop2 { stop-color: hsl(0,0%,40%); }',
                svg2,
                Encoding.uint2str(uint32(displayPrice)),
                svg3));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Encoding.sol";
import "./Base64.sol";
import "./DateTimeAPI.sol";

// TODO: Make this a library - all functions must be internal
contract Metadata {
    DateTimeAPI dates;

    constructor(DateTimeAPI d) {
        dates = d;
    }

    function getStats(int32[] memory ethPriceData) internal pure returns (uint32, uint32, uint, uint) {
        uint sum = 0;
        uint32 hi = 0;
        uint32 lo = type(uint32).max;
        uint numValues = 0;
        for (uint i = 0; i < ethPriceData.length; i++) {
            uint32 price = uint32(ethPriceData[i]);
            sum += uint32(price);

            if (price > 0) {
                if (price > hi) {
                    hi = price;
                }
                if (price < lo) {
                    lo = price;
                }
                numValues++;
            }
        }
        uint mean = sum/numValues;
        uint deviations = 0;
        for (uint i = 0; i < ethPriceData.length; i++) {
            if (ethPriceData[i] > 0) {
                int256 delta = ethPriceData[i] - int32(int256(mean));
                deviations += uint256(delta*delta);
            }
        }
        uint vari = deviations/numValues;

        return (hi,lo,mean,vari);
    }

    function getVolatilityString(uint mean, uint variance) internal pure returns (string memory) {
        string memory volaStr = '';
        uint vola = 100*variance/mean;
        if (vola < 20) {
            volaStr = "Very Low";
        } else if (vola < 50) {
            volaStr = "Low";
        } else if (vola < 250) {
            volaStr = "Medium";
        } else if (vola < 500) {
            volaStr = "High";
        } else {
            volaStr = "Very High";
        }
        return volaStr;
    }

    function getDirectionString(int32 open, int32 close) internal pure returns (string memory) {
        int32 delta = close - open;
        int32 increase = 100*delta/open; /*pct*/
        string memory directionStr = '';
        if (increase < -10) {
            directionStr = "Down >10%";
        } else if (increase < -5) {
            directionStr = "Down 5-10%";
        } else if (increase < 0) {
            directionStr = "Down <5%";
        } else if (increase == 0) {
            directionStr = "Flat";
        } else if (increase < 5) {
            directionStr = "Up <5%";
        } else if (increase < 10) {
            directionStr = "Up 5-10%";
        } else {
            directionStr = "Up >10%";
        }
        return directionStr;
    }

    function getAttributes(int32[] memory ethPriceData, uint fromTimestamp, uint tokenId) external pure returns (string memory) {
        (uint32 high, uint32 low, uint mean, uint variance) = getStats(ethPriceData);

        int32 open = 0;
         for (uint i = 0; i < ethPriceData.length; i++) {
            if (ethPriceData[i] > 0) {
                open = ethPriceData[i];
                break;
            }
        }
        int32 close = ethPriceData[ethPriceData.length - 1];
            
        if (tokenId == 0) {
            // TODO: Omit attributes that aren't applicable to gold master
        }
        return string(
            abi.encodePacked(
                '[',
                '{',
                    '"display_type": "date",',
                    '"trait_type": "Date (UTC)",',
                    '"value": ', Encoding.uint2str(fromTimestamp),
                '},',
                '{',
                    '"trait_type": "Direction",',
                    '"value": "', getDirectionString(ethPriceData[0], close), '"',
                '},',
                '{',
                    '"trait_type": "Volatility",',
                    '"value": "', getVolatilityString(mean, variance), '"',
                '},',
                '{',
                    '"trait_type": "High",',
                    '"value": ', Encoding.uint2str(high),
                '},',
                '{',
                    '"trait_type": "Low",',
                    '"value": ', Encoding.uint2str(low),
                '}',

                ']'
            ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract Fetcher {
    enum Coin{ ETH, BTC }

    struct FeedInfo {
        AggregatorV2V3Interface feed;
        uint dataPointsToFetchPerDay;
    }

    // TODO: use address for correct chain before launch

    // Rinkeby price feed info 
    // FeedInfo internal priceFeedETH = FeedInfo(
    //     AggregatorV2V3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e),
    //     8*MEASURES
    // );
    // FeedInfo internal priceFeedBTC = FeedInfo(
    //     AggregatorV2V3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404),
    //     4*MEASURES
    // );

    // Kovan price feed info
    FeedInfo internal priceFeedETH = FeedInfo(
        AggregatorV2V3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331),
        8*MEASURES
    );
    FeedInfo internal priceFeedBTC = FeedInfo(
        AggregatorV2V3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e),
        4*MEASURES
    );
    
    /* // Polygon mumbai price feed info 
    FeedInfo internal priceFeedETH = FeedInfo(
        AggregatorV2V3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A),
        8*MEASURES
    );
    FeedInfo internal priceFeedBTC = FeedInfo(
        AggregatorV2V3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b),
        4*MEASURES
    );
    */

    function feedInfoForCoin(Coin coin) internal view returns (FeedInfo memory) {
        if (coin == Coin.ETH) {
            return priceFeedETH;
        } else {
            return priceFeedBTC;
        }
    }

    uint80 constant PERPETUAL_JAM_DAYS = 2;

    uint80 constant MEASURES = 3;
    uint80 constant SECONDS_PER_DAY = 3600*24;

    function perpetualDataStartTime() public view returns (uint256) {
        return (block.timestamp - PERPETUAL_JAM_DAYS*SECONDS_PER_DAY);
    }

    // function aa_testGuessRoundForTimestamp() public view returns (uint80 firstRoundToSearch, uint80 numRoundsToSearch) {
    //     uint256 testTimestamp = 1637625600; /* 11/23/2021 */
    //     return guessSearchRoundsForTimestamp(priceFeedBTC, testTimestamp, 1);
    // }

    // Given a timestamp, return the first round to search and the number of rounds to search for that timestamp.

    function guessSearchRoundsForTimestamp(Coin coin, uint256 fromTime, uint80 daysToFetch) internal view returns (uint80 firstRoundToSearch, uint80 numRoundsToSearch) {
        FeedInfo memory priceFeed = feedInfoForCoin(coin);

        uint256 toTime = fromTime + SECONDS_PER_DAY*daysToFetch;

        // TODO: Do simple backwards search to find correct phase

        (uint80 rhRound,,uint256 rhTime,,) = priceFeed.feed.latestRoundData();
        uint80 lhRound;
        uint256 lhTime;
        {
            uint16 phase = uint16(rhRound >> 64); // Assume current phase
            lhRound = uint80(phase << 64) + 1;
            lhTime = priceFeed.feed.getTimestamp(lhRound);
        }
        
        uint80 fromRound = binarySearchForTimestamp(coin, fromTime, lhRound, lhTime, rhRound, rhTime);
        uint80 toRound = binarySearchForTimestamp(coin, toTime, fromRound, fromTime, rhRound, rhTime);
        return (fromRound, toRound-fromRound);
    }

    function binarySearchForTimestamp(Coin coin, uint256 targetTime, uint80 lhRound, uint256 lhTime, uint80 rhRound, uint256 rhTime) internal view returns (uint80 targetRound) {
        AggregatorV2V3Interface feed = feedInfoForCoin(coin).feed;
        if (targetTime >= rhTime) {
            return rhRound;
        }
        require(lhTime <= targetTime);

        uint80 guessRound = rhRound;
        while (rhRound - lhRound > 1) {
            guessRound = uint80(int80(lhRound) + int80(rhRound - lhRound)/2);
            uint256 guessTime = feed.getTimestamp(uint256(guessRound));
            if (guessTime == 0) {
                return 0;
            } else if (guessTime > targetTime) {
                (rhRound, rhTime) = (guessRound, guessTime);
            } else if (guessTime < targetTime) {
                (lhRound, lhTime) = (guessRound, guessTime);
            }
        }
        return guessRound;
    }

    // function aa_testFetchPriceData() public view returns (int32[] memory) {
    //     return fetchPriceData(priceFeedETH, 48, 1, 1639257591);
    // }

    function roundIdsToSearch(Coin coin, uint256 fromTimestamp, uint80 daysToFetch, uint dataPointsToFetchPerDay) internal view returns (uint80[] memory ) {
        (uint80 startingId, uint80 numRoundsToSearch) = guessSearchRoundsForTimestamp(coin, fromTimestamp, daysToFetch);
        uint80 fetchFilter = uint80(numRoundsToSearch / (daysToFetch*dataPointsToFetchPerDay));
        if (fetchFilter < 1) {
            fetchFilter = 1;
        }
        uint80[] memory roundIds = new uint80[](numRoundsToSearch / fetchFilter);

        // Snap startingId to a round that is a multiple of fetchFilter. This prevents the perpetual jam from changing more often than
        // necessary, and keeps it aligned with the daily prints.
        startingId -= startingId % fetchFilter;

        for (uint80 i = 0; i < roundIds.length; i++) {
            roundIds[i] = startingId + i*fetchFilter;
        }
        return roundIds;
    }

    // TODO: need tests for fetchFilter to make sure this doesn't misbehave on mainnet
    // TODO: implement multiple fetch since this will inefficiently fetch the same Chainlink data a bunch of times?

    function fetchPriceData(Coin coin, uint80 daysToFetch, uint256 fromTimestamp) internal view returns (int32[] memory) {
        FeedInfo memory priceFeed = feedInfoForCoin(coin);
        uint80[] memory roundIds = roundIdsToSearch(coin, fromTimestamp, daysToFetch, priceFeed.dataPointsToFetchPerDay);
        uint dataPointsToReturn = priceFeed.dataPointsToFetchPerDay * daysToFetch; // Number of data points to return
        uint secondsBetweenDataPoints = SECONDS_PER_DAY / priceFeed.dataPointsToFetchPerDay;

        int32[] memory prices = new int32[](dataPointsToReturn);

        uint80 latestRoundId = uint80(priceFeed.feed.latestRound());
        for (uint80 i = 0; i < roundIds.length; i++) {
            if (roundIds[i] != 0 && roundIds[i] < latestRoundId) {
                (
                    ,
                    int price,
                    uint timestamp,,
                ) = priceFeed.feed.getRoundData(roundIds[i]);

                if (timestamp >= fromTimestamp) {
                    uint segmentsSinceStart = (timestamp - fromTimestamp) / secondsBetweenDataPoints;
                    if (segmentsSinceStart < prices.length) {
                        prices[segmentsSinceStart] = int32(price / 10**8);
                    }
                }
            }
        }

        return prices;
    }

    function fetchCoinPriceData(uint fromTimestamp, Coin coin) external view returns (int32[] memory) {
        uint80 daysToFetch = 1;
        if (fromTimestamp == 0) {
            fromTimestamp = perpetualDataStartTime();
            daysToFetch = PERPETUAL_JAM_DAYS;
        }

        int32[] memory prices = fetchPriceData(coin, daysToFetch, fromTimestamp);
        return prices;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base64.sol";

library Encoding {

    function encode(int32[] memory prices) internal pure returns (string memory) {
        uint256 encodedLen = prices.length * 3;

        // Round up to the nearest length divisible by 4. Otherwise it's not a valid base64 string
        if (encodedLen % 4 > 0) {
            encodedLen += (4 - (encodedLen % 4));
        }
        bytes memory data = new bytes(encodedLen);
        uint80 i;
        // TODO : should return a multiple of 4 padded with =
        for (i = 0; i < prices.length; i++) {
            int32 price = prices[i];
            
            int32 lgByte = (price >> 12) % 64;
            int32 medByte = (price >> 6) % 64;
            int32 smByte = price % 64;

            data[3*i] = Base64.TABLE[uint32(lgByte)];
            data[3*i + 1] = Base64.TABLE[uint32(medByte)];
            data[3*i + 2] = Base64.TABLE[uint32(smByte)];
        }  
        for (i = uint80(3*prices.length); i < encodedLen; i++) {
            data[i] = '='; // ASCII '='
        }
        return string(data);
    }

    // function testEncodedArraysAreDivisibleBy4() public pure returns (int32[] memory) {
    //     int32[] memory testData = new int32[](5);
    //     testData[0] = 4160;
    //     testData[1] = 4224;
    //     testData[2] = 4133;
    //     testData[3] = 4187;
    //     testData[4] = 4112;

    //     int32[][] memory testArrays;
    //     int32[] memory results = new int32[](5);
    //     for (uint i = 0; i < testArrays.length; i++) {
    //         uint len = i+1;
    //         testArrays[i] = new int32[](len);
    //         for (uint j = 0; j < len; j++) {
    //             testArrays[i][j] = testData[j];
    //         }
    //         results[i] = bytes(encode(testArrays[i])).length % 4;
    //     }
      
    //     return results;
    // }

    // function testEncoding() public pure returns (string memory) {
    //     int32[] memory prices = new int32[](5);
    //     prices[0] = 4160;
    //     prices[1] = 4224;
    //     prices[2] = 4133;
    //     prices[3] = 4187;
    //     prices[4] = 4112;
      
    //     return encode(prices);

    //     // result should be BBABCABAlBBbBAQ
    // }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// See https://github.com/pipermerriam/ethereum-datetime/blob/master/contracts/api.sol

interface DateTimeAPI  {
        /*
         *  Abstract contract for interfacing with the DateTime contract.
         *
         */
        function isLeapYear(uint16 year) pure external returns (bool);
        function getYear(uint timestamp) pure external returns (uint16);
        function getMonth(uint timestamp) pure external returns (uint8);
        function getDay(uint timestamp) pure external returns (uint8);
        function getHour(uint timestamp) pure external returns (uint8);
        function getMinute(uint timestamp) pure external returns (uint8);
        function getSecond(uint timestamp) pure external returns (uint8);
        function getWeekday(uint timestamp) pure external returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) pure external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) pure external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) pure external returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) pure external returns (uint timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return '';

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}