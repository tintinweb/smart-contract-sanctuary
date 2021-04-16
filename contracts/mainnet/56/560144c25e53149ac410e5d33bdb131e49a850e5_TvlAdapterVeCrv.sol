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
interface IOracle {
    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) external view returns (uint256);

    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

interface IVotingEscrow {
    function balanceOf(address account) external view returns (uint256);
}

/*******************************************************
 *                     Adapter Logic                   *
 *******************************************************/
contract TvlAdapterVeCrv {
    IOracle public oracle; // The oracle is used to fetch USDC normalized pricing data

    address public yveCrvDaoAddress =
        0xc5bDdf9843308380375a611c18B50Fb9341f502A; // veCRV-DAO "Vault"
    address public curveVotingEscrowAddress =
        0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2; // veCRV
    address public curveYCrvVoterAddress =
        0xF147b8125d2ef93FB6965Db97D6746952a133934; // Yearn voter proxy
    uint256 public assetsLength = 1;

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
    constructor(address _oracleAddress) {
        require(_oracleAddress != address(0), "Missing oracle address");
        oracle = IOracle(_oracleAddress);
    }

    /**
     * Fetch adapter info
     */
    function adapterInfo() public view returns (AdapterInfo memory) {
        return
            AdapterInfo({
                id: address(this),
                typeId: "VE_CRV",
                categoryId: "SPECIAL"
            });
    }

    /**
     * Fetch all asset addresses for this adapter
     */
    function assetsAddresses() public view returns (address[] memory) {
        address[] memory addresses = new address[](1);
        addresses[0] = yveCrvDaoAddress;
        return addresses;
    }

    /**
     * Fetch the underlying token address of an asset
     */
    function underlyingTokenAddress(address assetAddress)
        public
        view
        returns (address)
    {
        return 0xD533a949740bb3306d119CC777fa900bA034cd52; // CRV
    }

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        IVotingEscrow votingEscrow = IVotingEscrow(curveVotingEscrowAddress);
        return votingEscrow.balanceOf(curveYCrvVoterAddress);
    }

    /**
     * Fetch delegated balance of an asset
     */
    function assetDelegatedBalance(address assetAddress)
        public
        view
        returns (uint256)
    {
        return 0;
    }

    /**
     * Fetch TVL of an asset in USDC
     */
    function assetTvlUsdc(address assetAddress) public view returns (uint256) {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 underlyingBalanceAmount = assetBalance(assetAddress);
        uint256 adjustedBalanceUsdc =
            oracle.getNormalizedValueUsdc(
                tokenAddress,
                underlyingBalanceAmount
            );
        return adjustedBalanceUsdc;
    }

    /**
     * Fetch TVL for adapter in USDC
     */
    function assetsTvlUsdc(address[] memory _assetsAddresses)
        public
        view
        returns (uint256)
    {
        return assetTvlUsdc(_assetsAddresses[0]);
    }

    /**
     * Fetch TVL for adapter in USDC given an array of addresses
     */
    function assetsTvlUsdc() external view returns (uint256) {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsTvlUsdc(_assetsAddresses);
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
        uint256 tokenPriceUsdc = oracle.getPriceUsdcRecommended(tokenAddress);
        uint256 delegatedBalanceAmount = 0;
        return
            AssetTvlBreakdown({
                assetId: assetAddress,
                tokenId: tokenAddress,
                tokenPriceUsdc: tokenPriceUsdc,
                underlyingTokenBalance: underlyingBalanceAmount,
                delegatedBalance: delegatedBalanceAmount,
                adjustedBalance: underlyingBalanceAmount -
                    delegatedBalanceAmount,
                adjustedBalanceUsdc: oracle.getNormalizedValueUsdc(
                    tokenAddress,
                    underlyingBalanceAmount,
                    tokenPriceUsdc
                )
            });
    }

    // Fetch TVL breakdown for adapter given an array of addresses
    function assetsTvlBreakdown(address[] memory _assetsAddresses)
        public
        view
        returns (AssetTvlBreakdown[] memory)
    {
        AssetTvlBreakdown[] memory tvlData = new AssetTvlBreakdown[](1);
        tvlData[0] = assetTvlBreakdown(_assetsAddresses[0]);
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
}