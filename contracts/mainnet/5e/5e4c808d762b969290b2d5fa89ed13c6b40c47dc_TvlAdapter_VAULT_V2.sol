/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface IV2Vault {
    function token() external view returns (address);

    function totalAssets() external view returns (uint256);
}

interface IOracle {
    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

interface IHelper {
    function assetStrategiesDelegatedBalance(address)
        external
        view
        returns (uint256);
}

interface IAddressesGenerator {
    function assetsAddresses() external view returns (address[] memory);

    function assetsLength() external view returns (uint256);
}

/*******************************************************
 *                     Adapter Logic                   *
 *******************************************************/
contract TvlAdapter_VAULT_V2 {
    /*******************************************************
     *           Common code shared by all adapters        *
     *******************************************************/

    IOracle public oracle; // The oracle is used to fetch USDC normalized pricing data
    IHelper public helper; // A helper utility is used for batch allowance fetching and address array merging
    IAddressesGenerator public addressesGenerator; // A utility for fetching assets addresses and length

    /**
     * TVL breakdown for an asset
     */
    struct AssetTvl {
        address assetId; // Asset address
        address tokenId; // Token address
        uint256 tokenPriceUsdc; // Token price in USDC
        TokenAmount underlyingTokenBalance; // Amount of underlying token in asset
        TokenAmount delegatedBalance; // Amount of underlying token balance that is delegated
        TokenAmount adjustedBalance; // TVL = underlyingTokenBalance - delegatedBalance
    }

    /**
     * Token amount representation
     */
    struct TokenAmount {
        uint256 amount; // Amount in underlying token decimals
        uint256 amountUsdc; // Amount in USDC (6 decimals)
    }

    /**
     * Information about the adapter
     */
    struct AdapterInfo {
        address id; // Adapter address
        string typeId; // Adapter typeId (for example "VAULT_V2" or "IRON_BANK_MARKET")
        string categoryId; // Adapter categoryId (for example "VAULT")
    }

    /**
     * Configure adapter
     */
    constructor(
        address _oracleAddress,
        address _helperAddress,
        address _addressesGeneratorAddress
    ) {
        require(_oracleAddress != address(0), "Missing oracle address");
        require(_helperAddress != address(0), "Missing helper address");
        require(
            _addressesGeneratorAddress != address(0),
            "Missing addresses generator address"
        );
        oracle = IOracle(_oracleAddress);
        helper = IHelper(_helperAddress);
        addressesGenerator = IAddressesGenerator(_addressesGeneratorAddress);
    }

    function adapterInfo() public view returns (AdapterInfo memory) {
        return
            AdapterInfo({
                id: address(this),
                typeId: "VAULT_V2",
                categoryId: "VAULT"
            });
    }

    /**
     * Fetch the underlying token address of an asset
     */
    function underlyingTokenAddress(address assetAddress)
        public
        view
        returns (address)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        address tokenAddress = vault.token();
        return tokenAddress;
    }

    /**
     * Fetch the total number of assets for this adapter
     */
    function assetsLength() public view returns (uint256) {
        return addressesGenerator.assetsLength();
    }

    /**
     * Fetch all asset addresses for this adapter
     */
    function assetsAddresses() public view returns (address[] memory) {
        return addressesGenerator.assetsAddresses();
    }

    /**
     * Internal method for constructing a TokenAmount struct given a token balance and address
     */
    function tokenAmount(uint256 amount, address tokenAddress)
        internal
        view
        returns (TokenAmount memory)
    {
        return
            TokenAmount({
                amount: amount,
                amountUsdc: oracle.getNormalizedValueUsdc(tokenAddress, amount)
            });
    }

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        IV2Vault vault = IV2Vault(assetAddress);
        return vault.totalAssets();
    }

    /**
     * Fetch TVL of an asset in USDC
     */
    function assetTvlUsdc(address assetAddress) public view returns (uint256) {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 underlyingBalanceAmount = assetBalance(assetAddress);
        uint256 delegatedBalanceAmount =
            helper.assetStrategiesDelegatedBalance(assetAddress);
        uint256 adjustedBalanceAmount =
            underlyingBalanceAmount - delegatedBalanceAmount;
        uint256 adjustedBalanceUsdc =
            oracle.getNormalizedValueUsdc(tokenAddress, adjustedBalanceAmount);
        return adjustedBalanceUsdc;
    }

    /**
     * Fetch TVL breakdown of an asset
     */
    function assetTvl(address assetAddress)
        public
        view
        returns (AssetTvl memory)
    {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 underlyingBalanceAmount = assetBalance(assetAddress);
        uint256 delegatedBalanceAmount =
            helper.assetStrategiesDelegatedBalance(assetAddress);
        uint256 adjustedBalance =
            underlyingBalanceAmount - delegatedBalanceAmount;
        return
            AssetTvl({
                assetId: assetAddress,
                tokenId: tokenAddress,
                tokenPriceUsdc: oracle.getPriceUsdcRecommended(tokenAddress),
                underlyingTokenBalance: tokenAmount(
                    underlyingBalanceAmount,
                    tokenAddress
                ),
                delegatedBalance: tokenAmount(
                    delegatedBalanceAmount,
                    tokenAddress
                ),
                adjustedBalance: tokenAmount(adjustedBalance, tokenAddress)
            });
    }

    /**
     * Fetch TVL for adapter
     */
    function assetsTvlUsdc() external view returns (uint256) {
        uint256 tvl;
        address[] memory assetAddresses = assetsAddresses();
        uint256 numberOfAssets = assetAddresses.length;
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = assetAddresses[assetIdx];
            uint256 _assetTvl = assetTvlUsdc(assetAddress);
            tvl += _assetTvl;
        }
        return tvl;
    }

    /**
     * Fetch TVL for adapter
     */
    function assetsTvl() external view returns (AssetTvl[] memory) {
        address[] memory _assetsAddresses = assetsAddresses();
        uint256 numberOfAssets = _assetsAddresses.length;

        AssetTvl[] memory tvlData = new AssetTvl[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            AssetTvl memory tvl = assetTvl(assetAddress);
            tvlData[assetIdx] = tvl;
        }
        return tvlData;
    }
}