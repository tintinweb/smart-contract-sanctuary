/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-14
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface CyToken {
    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function borrowBalanceStored() external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IOracle {
    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) external view returns (uint256);

    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

interface IDelegationMapping {
    function assetBalanceIsDelegated(address) external view returns (bool);
}

interface IAddressesGenerator {
    function assetsAddresses() external view returns (address[] memory);

    function assetsLength() external view returns (uint256);
}

/*******************************************************
 *                     Adapter Logic                   *
 *******************************************************/
contract TvlAdapterIronBank {
    /*******************************************************
     *           Common code shared by all adapters        *
     *******************************************************/

    IOracle public oracle; // The oracle is used to fetch USDC normalized pricing data
    IAddressesGenerator public addressesGenerator; // A utility for fetching assets addresses and length
    IDelegationMapping public delegationMapping;

    /**
     * TVL breakdown for an asset
     */
    struct AssetTvlBreakdown {
        address assetId; // Asset address
        address tokenId; // Token address
        uint256 tokenPriceUsdc; // Token price in USDC
        uint256 underlyingTokenBalance; // Amount of underlying token in asset
        uint256 delegatedBalance; // Amount of underlying token balance that is delegated
        uint256 adjustedBalance; // underlyingTokenBalance - delegatedBalance
        uint256 adjustedBalanceUsdc; // TVL
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
        address _addressesGeneratorAddress,
        address _delegationMappingAddress
    ) {
        oracle = IOracle(_oracleAddress);
        addressesGenerator = IAddressesGenerator(_addressesGeneratorAddress);
        delegationMapping = IDelegationMapping(_delegationMappingAddress);
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

    // Fetch TVL breakdown for adapter given an array of addresses
    function assetsTvlBreakdown(address[] memory _assetsAddresses)
        public
        view
        returns (AssetTvlBreakdown[] memory)
    {
        uint256 numberOfAssets = _assetsAddresses.length;

        AssetTvlBreakdown[] memory tvlData =
            new AssetTvlBreakdown[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            tvlData[assetIdx] = assetTvlBreakdown(assetAddress);
        }
        return tvlData;
    }

    /**
     * Fetch TVL breakdown for adapter
     */
    function assetsTvlBreakdown()
        external
        view
        returns (AssetTvlBreakdown[] memory)
    {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsTvlBreakdown(_assetsAddresses);
    }

    /**
     * Fetch TVL breakdown of an asset
     */
    function assetTvlBreakdown(address assetAddress)
        public
        view
        returns (AssetTvlBreakdown memory)
    {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 underlyingBalanceAmount = assetBalance(assetAddress);
        uint256 delegatedBalanceAmount = assetDelegatedBalance(assetAddress);
        uint256 adjustedBalance =
            underlyingBalanceAmount - delegatedBalanceAmount;
        uint256 tokenPriceUsdc = oracle.getPriceUsdcRecommended(tokenAddress);
        return
            AssetTvlBreakdown({
                assetId: assetAddress,
                tokenId: tokenAddress,
                tokenPriceUsdc: tokenPriceUsdc,
                underlyingTokenBalance: underlyingBalanceAmount,
                delegatedBalance: delegatedBalanceAmount,
                adjustedBalance: adjustedBalance,
                adjustedBalanceUsdc: oracle.getNormalizedValueUsdc(
                    tokenAddress,
                    adjustedBalance,
                    tokenPriceUsdc
                )
            });
    }

    /**
     * Fetch TVL for adapter in USDC
     */
    function assetsTvlUsdc(address[] memory _assetsAddresses)
        public
        view
        returns (uint256)
    {
        uint256 tvl;
        uint256 numberOfAssets = assetsLength();
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            uint256 _assetTvl = assetTvlUsdc(assetAddress);
            tvl += _assetTvl;
        }
        return tvl;
    }

    /**
     * Fetch TVL for adapter in USDC given an array of addresses
     */
    function assetsTvlUsdc() external view returns (uint256) {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsTvlUsdc(_assetsAddresses);
    }

    /*******************************************************
     *                   Asset-specific Logic              *
     *******************************************************/

    /**
     * Fetch adapter info
     */
    function adapterInfo() public view returns (AdapterInfo memory) {
        return
            AdapterInfo({
                id: address(this),
                typeId: "IRON_BANK_MARKET",
                categoryId: "LENDING"
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
        CyToken cyToken = CyToken(assetAddress);
        address tokenAddress = cyToken.underlying();
        return tokenAddress;
    }

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        CyToken cyToken = CyToken(assetAddress);
        uint256 cash = cyToken.getCash();
        uint256 totalBorrows = cyToken.totalBorrows();
        uint256 totalReserves = cyToken.totalReserves();
        uint256 totalSupplied = (cash + totalBorrows - totalReserves);
        return totalSupplied;
    }

    /**
     * Fetch TVL of an asset in USDC
     */
    function assetTvlUsdc(address assetAddress) public view returns (uint256) {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 underlyingBalanceAmount = assetBalance(assetAddress);
        uint256 delegatedBalanceAmount = assetDelegatedBalance(assetAddress);
        uint256 adjustedBalanceAmount =
            underlyingBalanceAmount - delegatedBalanceAmount;
        uint256 adjustedBalanceUsdc =
            oracle.getNormalizedValueUsdc(tokenAddress, adjustedBalanceAmount);
        return adjustedBalanceUsdc;
    }

    function assetDelegatedBalance(address assetAddress)
        public
        view
        returns (uint256)
    {
        bool balanceIsDelegated =
            delegationMapping.assetBalanceIsDelegated(assetAddress);
        if (balanceIsDelegated) {
            return assetBalance(assetAddress);
        }
        return 0;
    }
}