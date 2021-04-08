/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

contract PricesHelper {
    IOracle public oracle;

    struct TokenPrice {
        address tokenId;
        uint256 priceUsdc;
    }

    constructor(address oracleAddress) {
        require(oracleAddress != address(0), "Missing oracle address");
        oracle = IOracle(oracleAddress);
    }

    function tokensPrices(address[] memory tokensAddresses)
        external
        view
        returns (TokenPrice[] memory)
    {
        TokenPrice[] memory _tokensPrices =
            new TokenPrice[](tokensAddresses.length);
        for (
            uint256 tokenIdx = 0;
            tokenIdx < tokensAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = tokensAddresses[tokenIdx];
            _tokensPrices[tokenIdx] = TokenPrice({
                tokenId: tokenAddress,
                priceUsdc: oracle.getPriceUsdcRecommended(tokenAddress)
            });
        }
        return _tokensPrices;
    }
}