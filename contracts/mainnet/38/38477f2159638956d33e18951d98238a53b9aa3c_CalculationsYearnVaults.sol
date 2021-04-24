/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

interface IVault {
    function pricePerShare() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint8);
}

contract CalculationsYearnVaults {
    address public oracleAddress;
    IOracle private oracle;

    constructor(address _oracleAddress) {
        oracleAddress = _oracleAddress;
        oracle = IOracle(_oracleAddress);
    }

    function isYearnV1Vault(address tokenAddress) public view returns (bool) {
        IVault vault = IVault(tokenAddress);
        try vault.getPricePerFullShare() returns (uint256 pricePerShare) {
            return true;
        } catch {}
        return false;
    }

    function isYearnV2Vault(address tokenAddress) public view returns (bool) {
        IVault vault = IVault(tokenAddress);
        try vault.pricePerShare() returns (uint256 pricePerShare) {
            return true;
        } catch {}
        return false;
    }

    function isYearnVault(address tokenAddress) public view returns (bool) {
        return isYearnV1Vault(tokenAddress) || isYearnV2Vault(tokenAddress);
    }

    function getPriceYearnVault(address tokenAddress)
        public
        view
        returns (uint256)
    {
        // v1 vaults use getPricePerFullShare scaled to 18 decimals
        // v2 vaults use pricePerShare scaled to underlying token decimals
        IVault vault = IVault(tokenAddress);
        if (isYearnVault(tokenAddress) == false) {
            revert("CalculationsYearnVaults: Token is not a yearn vault");
        }
        address underlyingTokenAddress = vault.token();
        uint256 underlyingTokenPrice =
            oracle.getPriceUsdcRecommended(underlyingTokenAddress);
        if (isYearnV1Vault(tokenAddress)) {
            uint256 sharePrice = vault.getPricePerFullShare();
            return (underlyingTokenPrice * sharePrice) / 10**18;
        } else if (isYearnV2Vault(tokenAddress)) {
            uint256 sharePrice = vault.pricePerShare();
            uint8 tokenDecimals = IERC20(underlyingTokenAddress).decimals();
            return (underlyingTokenPrice * sharePrice) / 10**tokenDecimals;
        }
        revert();
    }

    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        return getPriceYearnVault(tokenAddress);
    }
}