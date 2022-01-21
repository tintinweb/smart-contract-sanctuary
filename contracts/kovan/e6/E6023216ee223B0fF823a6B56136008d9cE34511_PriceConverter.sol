// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../interface/IPriceConverter.sol";

contract PriceConverter is IPriceConverter {
    function getDerivedPrice(int256 basePrice, uint8 baseDecimals, int256 quotePrice, uint8 quoteDecimals, uint8 _decimals)
        external
        pure
        override
        returns (int256)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        int256 decimals = int256(10 ** uint256(_decimals));
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return basePrice * decimals / quotePrice;
    }

    /**
        e.g. X ETH / 1 LINK * X USD/1 ETH = USD / 1 LINK
    */
    function getExchangePrice(int256 basePrice, uint8 baseDecimals, int256 quotePrice, uint8 quoteDecimals, uint8 _decimals)
        external
        pure
        override
        returns (int256)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        int256 exchangedPrice = basePrice * quotePrice;

        return scalePrice(exchangedPrice, (baseDecimals + quoteDecimals), _decimals);
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IPriceConverter {
    function getDerivedPrice(int256 basePrice, uint8 baseDecimals, int256 quotePrice, uint8 quoteDecimals, uint8 _decimals)
        external
        pure
        returns (int256);

    function getExchangePrice(int256 basePrice, uint8 baseDecimals, int256 quotePrice, uint8 quoteDecimals, uint8 _decimals)
        external
        pure
        returns (int256);
}