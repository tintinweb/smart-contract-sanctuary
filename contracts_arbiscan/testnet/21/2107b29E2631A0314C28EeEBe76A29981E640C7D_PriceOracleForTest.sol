pragma solidity ^0.8.0;

import "./interfaces/IPriceOracle.sol";

contract PriceOracleForTest is IPriceOracle {
    struct Reserves {
        uint256 base;
        uint256 quote;
    }
    mapping(address => mapping(address => Reserves)) public getReserves;

    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view override returns (uint256 quoteAmount) {
        Reserves memory reserves = getReserves[baseToken][quoteToken];
        quoteAmount = quote(baseAmount, reserves.base, reserves.quote);
    }

    function setReserve(
        address baseToken,
        address quoteToken,
        uint256 reserveBase,
        uint256 reserveQuote
    ) external {
        getReserves[baseToken][quoteToken] = Reserves(reserveBase, reserveQuote);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IPriceOracle {
    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);
}