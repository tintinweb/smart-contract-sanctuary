//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Data {

    struct TradeInfo {
        uint256 hash;
        bool inProfit;
        string leverage;
        string side;
        string market;
        Exchange exchange;
        string pnlText;
        string accountSize;
        string lottoGroup;
    }

    struct Exchange {
        string name;
        string color;
    }

    function generateTradeInfo(uint256 _hash) public pure returns (TradeInfo memory tradeInfo) {
        tradeInfo.hash = _hash;
        bool inProfit = _hash % 10 <= 1;
        tradeInfo.inProfit = inProfit;
        (string memory pnlText, string memory accountSize) = generatePnlText(_hash, inProfit);
        tradeInfo.pnlText = pnlText;
        tradeInfo.accountSize = accountSize;
        tradeInfo.leverage = getLeverage(_hash);
        tradeInfo.side = _hash % 100 <= 79 ? 'LONG' : 'SHORT';
        tradeInfo.market = getMarket(_hash);
        tradeInfo.exchange = getExchange(_hash);
        tradeInfo.lottoGroup = toString(uint256(getLottoGroup(_hash)));
        return tradeInfo;
    }

    function getLeverage(uint256 _hash) private pure returns (string memory leverage) {
        string[18] memory leverageOptions = [
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            '20',
            '100',
            '125'
    ];
        uint256 leverageIndex = _hash % 18;
        return leverageOptions[leverageIndex];
    }

    function getMarket(uint256 _hash) private pure returns (string memory market) {
        string[41] memory markets = [
            "ZEC",
            "BTC",
            "ETH",
            "ADA",
            "BNB",
            "ETC",
            "XRP",
            "LTC",
            "DOGE",
            "SHIBA",
            "EOS",
            "TRX",
            "LINK",
            "XMR",
            "ATOM",
            "DOT",
            "SNX",
            "SUSHI",
            "UNI",
            "SOL",
            "CRV",
            "YFI",
            "AXS",
            "GRT",
            "SAND",
            "GALA",
            "MANA",
            "AVAX",
            "FTM",
            "MATIC",
            "LUNA",
            "FIL",
            "1INCH",
            "XLM",
            "AAVE",
            "FTT",
            "ICP",
            "XTZ",
            "ONE",
            "OKB",
            "COMP"
        ];
        uint256 marketIndex = _hash % 41;
        return markets[marketIndex];
    }

     function getExchange(uint256 _hash) private pure returns (Exchange memory exchange) {
        string[8] memory exchangeNames = [
            'Binance',
            'FTX',
            'Bitfinex',
            'Kraken',
            'Huobi',
            'Okex',
            'Bitmex',
            'Bybit'
        ];

        string[8] memory exchangeColors = [
            'rgb(252,213,54)',
            'rgb(0,180,201)',
            'rgb(6,194,147)',
            'rgb(84,71,209)',
            'rgb(5,155,220)',
            'rgb(133,183,239)',
            'rgb(247,3,3)',
            'rgb(236,177,9)'
        ];
        uint256 exchangeIndex = _hash % 8;
        return Exchange(exchangeNames[exchangeIndex], exchangeColors[exchangeIndex]);
    }

    function generatePnlText(uint256 _hash, bool inProfit) private pure returns (string memory pnlText, string memory accountSize) {
        string[5] memory accountSizes = [
            'Fish',
            'Shark',
            'Dolphin',
            'Whale',
            'Humpback'
        ];
        uint256 sizeIndex = _hash % 21;
        uint256 min;
        uint256 max;
        uint8 accountSizeIndex;
         if (sizeIndex <=10) {
            min =1000;
            max = 9999;
            accountSizeIndex = 0;
        } else if (sizeIndex <=13) {
            min =10000;
            max = 99999;
            accountSizeIndex = 1;
        } else if (sizeIndex <=16) {
            min =100000;
            max = 999999;
            accountSizeIndex = 2;
        } else if (sizeIndex <=19) {
            min =1000000;
            max = 9999999;
            accountSizeIndex = 3;
        } else {
            min =10000000;
            max = 99999999;
            accountSizeIndex = 4;
        }
        uint256 number = (_hash % (max - min)) + min;
        string memory cents = toString(_hash % 100);
        string memory pnlNumber = string(abi.encodePacked(toString(number), '.', cents));
        return (string(abi.encodePacked(inProfit ? '+' : '-', '$', pnlNumber)), accountSizes[accountSizeIndex]);
    }

    function getLottoGroup(uint256 _hash) public pure returns (uint8 lottoGroup) {
        lottoGroup = 1;

        //Green PNL
        if (_hash % 10 <= 1) {
            lottoGroup++;
        }
        //Leverage = 125X
        if (_hash % 18 == 17) {
            lottoGroup = lottoGroup + 2;
        }
        // Market = ZEC
        if (_hash % 41 == 0) {
            lottoGroup = lottoGroup + 5;
        }
        // Market = Bitmex
        if (_hash % 8 == 6) {
            lottoGroup++;
        }
        // Size = Humpback
        if (_hash % 21 == 20) {
            lottoGroup = lottoGroup + 3;
        }
        //Side = Short
        if (_hash % 100 > 79) {
            lottoGroup = lottoGroup + 1;
        }
        return lottoGroup;
    }

    // from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
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
}