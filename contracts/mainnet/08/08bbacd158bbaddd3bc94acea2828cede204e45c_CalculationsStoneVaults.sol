/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
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

    function token() external view returns (address);

    function decimals() external view returns (uint8);
}

contract CalculationsStoneVaults {
    address public oracleAddress;
    IOracle private oracle;

    constructor(address _oracleAddress) public {
        oracleAddress = _oracleAddress;
        oracle = IOracle(_oracleAddress);
    }

    function isStoneVault(address tokenAddress) public view returns (bool) {
        IVault vault = IVault(tokenAddress);
        try vault.pricePerShare() returns (uint256 pricePerShare) {
            return true;
        } catch {}
        return false;
    }

    function getPriceStoneVault(address tokenAddress)
        public
        view
        returns (uint256)
    {
        // v2 vaults use pricePerShare scaled to underlying token decimals
        IVault vault = IVault(tokenAddress);
        if (isStoneVault(tokenAddress) == false) {
            revert("CalculationsStoneVaults: Token is not a stone vault");
        }
        address underlyingTokenAddress = vault.token();
        uint256 underlyingTokenPrice =
            oracle.getPriceUsdcRecommended(underlyingTokenAddress);
        uint256 sharePrice = vault.pricePerShare();
        uint256 tokenDecimals = IERC20Metadata(underlyingTokenAddress).decimals();
        return (underlyingTokenPrice * sharePrice) / 10**tokenDecimals;
    }

    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        return getPriceStoneVault(tokenAddress);
    }
}