/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface Unitroller {
    function getAllMarkets() external view returns (address[] memory);
}

interface CyToken {
    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IOracle {
    function getPriceUsdc(address tokenAddress) external view returns (uint256);
}

contract CalculationsIronBank {
    address public unitrollerAddress;
    address public oracleAddress;

    constructor(address _unitrollerAddress, address _oracleAddress) {
        unitrollerAddress = _unitrollerAddress;
        oracleAddress = _oracleAddress;
    }

    function getIronBankMarkets() public view returns (address[] memory) {
        return Unitroller(unitrollerAddress).getAllMarkets();
    }

    function isIronBankMarket(address tokenAddress) public view returns (bool) {
        address[] memory ironBankMarkets = getIronBankMarkets();
        uint256 numIronBankMarkets = ironBankMarkets.length;
        for (
            uint256 marketIdx = 0;
            marketIdx < numIronBankMarkets;
            marketIdx++
        ) {
            address marketAddress = ironBankMarkets[marketIdx];
            if (tokenAddress == marketAddress) {
                return true;
            }
        }
        return false;
    }

    function getIronBankMarketPriceUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        CyToken cyToken = CyToken(tokenAddress);
        uint256 exchangeRateStored = cyToken.exchangeRateStored();
        address underlyingTokenAddress = cyToken.underlying();
        uint256 decimals = cyToken.decimals();
        IERC20 underlyingToken = IERC20(underlyingTokenAddress);
        uint8 underlyingTokenDecimals = underlyingToken.decimals();
        IOracle oracle = IOracle(oracleAddress);
        uint256 underlyingTokenPrice =
            oracle.getPriceUsdc(underlyingTokenAddress);

        uint256 price =
            (underlyingTokenPrice * exchangeRateStored) /
                10**(underlyingTokenDecimals + decimals);
        return price;
    }

    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        if (isIronBankMarket(tokenAddress)) {
            return getIronBankMarketPriceUsdc(tokenAddress);
        }
        revert();
    }
}