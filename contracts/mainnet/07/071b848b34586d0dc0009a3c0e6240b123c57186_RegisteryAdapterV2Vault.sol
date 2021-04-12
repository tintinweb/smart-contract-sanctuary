/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface IV2Vault {
    function token() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function apiVersion() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function emergencyShutdown() external view returns (bool);

    function depositLimit() external view returns (uint256);
}

interface IV2Registry {
    function numTokens() external view returns (uint256);

    function numVaults(address token) external view returns (uint256);

    function tokens(uint256 tokenIdx) external view returns (address);

    function latestVault(address token) external view returns (address);

    function vaults(address token, uint256 tokenIdx)
        external
        view
        returns (address);
}

interface IOracle {
    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address spender, address owner)
        external
        view
        returns (uint256);
}

interface IHelper {
    // Strategies helper
    function assetStrategiesDelegatedBalance(address)
        external
        view
        returns (uint256);

    // Allowances helper
    struct Allowance {
        address owner;
        address spender;
        uint256 amount;
        address token;
    }

    function allowances(
        address ownerAddress,
        address[] memory tokensAddresses,
        address[] memory spenderAddresses
    ) external view returns (Allowance[] memory);
}

interface ManagementList {
    function isManager(address accountAddress) external returns (bool);
}

/*******************************************************
 *                     Management List                 *
 *******************************************************/

contract Manageable {
    ManagementList public managementList;

    constructor(address _managementListAddress) {
        managementList = ManagementList(_managementListAddress);
    }

    modifier onlyManagers() {
        bool isManager = managementList.isManager(msg.sender);
        require(isManager, "ManagementList: caller is not a manager");
        _;
    }
}

/*******************************************************
 *                     Adapter Logic                   *
 *******************************************************/
contract RegisteryAdapterV2Vault is Manageable {
    /*******************************************************
     *           Common code shared by all adapters        *
     *******************************************************/

    IOracle public oracle; // The oracle is used to fetch USDC normalized pricing data
    IV2Registry public registry; // The registry is used to fetch the list of vaults and migration data
    IHelper public helper; // A helper utility is used for batch allowance fetching and address array merging
    address[] public positionSpenderAddresses; // A settable list of spender addresses with which to fetch asset allowances
    mapping(address => bool) public assetDeprecated; // Support for deprecating assets. If an asset is deprecated it will not appear is results
    uint256 public numberOfDeprecatedAssets; // Used to keep track of the number of deprecated assets for an adapter

    /**
     * High level static information about an asset
     */
    struct AssetStatic {
        address id; // Asset address
        string typeId; // Asset typeId (for example "VAULT_V2" or "IRON_BANK_MARKET")
        string name; // Asset Name
        string version; // Asset version
        Token token; // Static asset underlying token information
    }

    /**
     * High level dynamic information about an asset
     */
    struct AssetDynamic {
        address id; // Asset address
        string typeId; // Asset typeId (for example "VAULT_V2" or "IRON_BANK_MARKET")
        address tokenId; // Underlying token address;
        TokenAmount underlyingTokenBalance; // Underlying token balances
        TokenAmount delegatedBalance; // Delegated balances
        AssetMetadata metadata; // Metadata specific to the asset type of this adapter
    }

    /**
     * Static token data
     */
    struct Token {
        address id; // token address
        string name; // token name
        string symbol; // token symbol
        uint8 decimals; // token decimals
    }

    /**
     * Information about a user's position relative to an asset
     */
    struct Position {
        address assetId; // Asset address
        address tokenId; // Underlying asset token address
        string typeId; // Position typeId (for example "DEPOSIT," "BORROW," "LEND")
        uint256 balance; // asset.balanceOf(account)
        TokenAmount accountTokenBalance; // User account balance of underlying token (token.balanceOf(account))
        TokenAmount underlyingTokenBalance; // Represents a user's asset position in underlying tokens
        Allowance[] tokenAllowances; // Underlying token allowances
        Allowance[] assetAllowances; // Asset allowances
    }

    /**
     * Token amount representation
     */
    struct TokenAmount {
        uint256 amount; // Amount in underlying token decimals
        uint256 amountUsdc; // Amount in USDC (6 decimals)
    }

    /**
     * Allowance information
     */
    struct Allowance {
        address owner; // Allowance owner
        address spender; // Allowance spender
        uint256 amount; // Allowance amount (in underlying token)
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
     * Fetch static information about an array of assets. This method can be used for off-chain pagination.
     */
    function assetsStatic(address[] memory _assetsAddresses)
        public
        view
        returns (AssetStatic[] memory)
    {
        uint256 numberOfAssets = _assetsAddresses.length;
        AssetStatic[] memory _assets = new AssetStatic[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            AssetStatic memory _asset = assetStatic(assetAddress);
            _assets[assetIdx] = _asset;
        }
        return _assets;
    }

    /**
     * Fetch dynamic information about an array of assets. This method can be used for off-chain pagination.
     */
    function assetsDynamic(address[] memory _assetsAddresses)
        public
        view
        returns (AssetDynamic[] memory)
    {
        uint256 numberOfAssets = _assetsAddresses.length;
        AssetDynamic[] memory _assets = new AssetDynamic[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            AssetDynamic memory _asset = assetDynamic(assetAddress);
            _assets[assetIdx] = _asset;
        }
        return _assets;
    }

    /**
     * Fetch static information for all assets
     */
    function assetsStatic() external view returns (AssetStatic[] memory) {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsStatic(_assetsAddresses);
    }

    /**
     * Fetch dynamic information for all assets
     */
    function assetsDynamic() external view returns (AssetDynamic[] memory) {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsDynamic(_assetsAddresses);
    }

    /**
     * Fetch underlying token allowances relative to an asset.
     * This is useful for determining whether or not a user has token approvals
     * to allow depositing into an asset
     */
    function tokenAllowances(
        address accountAddress,
        address tokenAddress,
        address assetAddress
    ) public view returns (Allowance[] memory) {
        address[] memory tokenAddresses = new address[](1);
        address[] memory assetAddresses = new address[](1);
        tokenAddresses[0] = tokenAddress;
        assetAddresses[0] = assetAddress;
        bytes memory allowances =
            abi.encode(
                helper.allowances(
                    accountAddress,
                    tokenAddresses,
                    assetAddresses
                )
            );
        return abi.decode(allowances, (Allowance[]));
    }

    /**
     * Fetch asset allowances based on positionSpenderAddresses (configurable).
     * This is useful to determine if a particular zap contract is approved for the asset (zap out use case)
     */
    function assetAllowances(address accountAddress, address assetAddress)
        public
        view
        returns (Allowance[] memory)
    {
        address[] memory assetAddresses = new address[](1);
        assetAddresses[0] = assetAddress;
        bytes memory allowances =
            abi.encode(
                helper.allowances(
                    accountAddress,
                    assetAddresses,
                    positionSpenderAddresses
                )
            );
        return abi.decode(allowances, (Allowance[]));
    }

    /**
     * Fetch basic static token metadata
     */
    function tokenMetadata(address tokenAddress)
        internal
        view
        returns (Token memory)
    {
        IERC20 _token = IERC20(tokenAddress);
        return
            Token({
                id: tokenAddress,
                name: _token.name(),
                symbol: _token.symbol(),
                decimals: _token.decimals()
            });
    }

    /**
     * Deprecate or undeprecate an asset. Deprecated assets will not appear in any adapter method call response
     */
    function setAssetDeprecated(address assetAddress, bool newDeprecationStatus)
        public
        onlyManagers
    {
        bool currentDeprecationStatus = assetDeprecated[assetAddress];
        if (currentDeprecationStatus == newDeprecationStatus) {
            revert("Adapter: Unable to change asset deprecation status");
        }
        if (newDeprecationStatus == true) {
            numberOfDeprecatedAssets++;
        } else {
            numberOfDeprecatedAssets--;
        }
        assetDeprecated[assetAddress] = newDeprecationStatus;
    }

    /**
     * Set position spender addresses. Used by `assetAllowances(address,address)`.
     */
    function setPositionSpenderAddresses(address[] memory addresses)
        public
        onlyManagers
    {
        positionSpenderAddresses = addresses;
    }

    /**
     * Fetch TVL for adapter
     */
    function assetsTvl() external view returns (uint256) {
        uint256 tvl;
        address[] memory assetAddresses = assetsAddresses();
        uint256 numberOfAssets = assetAddresses.length;
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = assetAddresses[assetIdx];
            uint256 _assetTvl = assetTvl(assetAddress);
            tvl += _assetTvl;
        }
        return tvl;
    }

    /**
     * Configure adapter
     */
    constructor(
        address _registryAddress,
        address _oracleAddress,
        address _managementListAddress,
        address _helperAddress
    ) Manageable(_managementListAddress) {
        require(
            _managementListAddress != address(0),
            "Missing management list address"
        );
        require(_registryAddress != address(0), "Missing registry address");
        require(_oracleAddress != address(0), "Missing oracle address");
        registry = IV2Registry(_registryAddress);
        oracle = IOracle(_oracleAddress);
        helper = IHelper(_helperAddress);
    }

    /*******************************************************
     * Common code shared by v1 vaults, v2 vaults and earn *
     *******************************************************/

    /**
     * Fetch asset positions of an account given an array of assets. This method can be used for off-chain pagination.
     */
    function positionsOf(
        address accountAddress,
        address[] memory _assetsAddresses
    ) public view returns (Position[] memory) {
        uint256 numberOfAssets = _assetsAddresses.length;
        Position[] memory positions = new Position[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            Position memory position = positionOf(accountAddress, assetAddress);
            positions[assetIdx] = position;
        }
        return positions;
    }

    /**
     * Fetch asset positins for an account for all assets
     */
    function positionsOf(address accountAddress)
        external
        view
        returns (Position[] memory)
    {
        address[] memory _assetsAddresses = assetsAddresses();
        return positionsOf(accountAddress, _assetsAddresses);
    }

    /*******************************************************
     *                 V2 Adapter (unique logic)           *
     *******************************************************/
    /**
     * Return information about the adapter
     */
    function adapterInfo() public view returns (AdapterInfo memory) {
        return
            AdapterInfo({
                id: address(this),
                typeId: "VAULT_V2",
                categoryId: "VAULT"
            });
    }

    /**
     * Metadata specific to this asset type
     */
    struct AssetMetadata {
        string symbol; // Vault symbol
        uint256 pricePerShare; // Vault pricePerShare
        bool migrationAvailable; // True if a migration is available for this vault
        address latestVaultAddress; // Latest vault migration address
        uint256 depositLimit; // Deposit limit of asset
        bool emergencyShutdown; // Vault is in emergency shutdown mode
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
        uint256 numTokens = registry.numTokens();
        uint256 numVaults;
        for (uint256 tokenIdx = 0; tokenIdx < numTokens; tokenIdx++) {
            address currentToken = registry.tokens(tokenIdx);
            uint256 numVaultsForToken = registry.numVaults(currentToken);
            numVaults += numVaultsForToken;
        }
        return numVaults - numberOfDeprecatedAssets;
    }

    /**
     * Fetch all asset addresses for this adapter
     */
    function assetsAddresses() public view returns (address[] memory) {
        uint256 numVaults = assetsLength();
        address[] memory _assetsAddresses = new address[](numVaults);
        uint256 numTokens = registry.numTokens();
        uint256 currentVaultIdx;
        for (uint256 tokenIdx = 0; tokenIdx < numTokens; tokenIdx++) {
            address currentTokenAddress = registry.tokens(tokenIdx);
            uint256 numVaultsForToken = registry.numVaults(currentTokenAddress);
            for (
                uint256 vaultTokenIdx = 0;
                vaultTokenIdx < numVaultsForToken;
                vaultTokenIdx++
            ) {
                address currentAssetAddress =
                    registry.vaults(currentTokenAddress, vaultTokenIdx);
                bool assetIsNotDeprecated =
                    assetDeprecated[currentAssetAddress] == false;
                if (assetIsNotDeprecated) {
                    _assetsAddresses[currentVaultIdx] = currentAssetAddress;
                    currentVaultIdx++;
                }
            }
        }
        return _assetsAddresses;
    }

    /**
     * Fetch static information about an asset
     */
    function assetStatic(address assetAddress)
        public
        view
        returns (AssetStatic memory)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        address tokenAddress = underlyingTokenAddress(assetAddress);
        return
            AssetStatic({
                id: assetAddress,
                typeId: adapterInfo().typeId,
                name: vault.name(),
                version: vault.apiVersion(),
                token: tokenMetadata(tokenAddress)
            });
    }

    /**
     * Fetch dynamic information about an asset
     */
    function assetDynamic(address assetAddress)
        public
        view
        returns (AssetDynamic memory)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 totalSupply = vault.totalSupply();
        uint256 pricePerShare = 0;
        bool vaultHasShares = totalSupply != 0;
        if (vaultHasShares) {
            pricePerShare = vault.pricePerShare();
        }

        address latestVaultAddress = registry.latestVault(tokenAddress);
        bool migrationAvailable = latestVaultAddress != assetAddress;

        AssetMetadata memory metadata =
            AssetMetadata({
                symbol: vault.symbol(),
                pricePerShare: pricePerShare,
                migrationAvailable: migrationAvailable,
                latestVaultAddress: latestVaultAddress,
                depositLimit: vault.depositLimit(),
                emergencyShutdown: vault.emergencyShutdown()
            });

        TokenAmount memory underlyingTokenBalance =
            TokenAmount({
                amount: assetBalance(assetAddress),
                amountUsdc: assetTvl(assetAddress)
            });

        uint256 delegatedBalanceAmount =
            helper.assetStrategiesDelegatedBalance(assetAddress);
        TokenAmount memory delegatedBalance =
            TokenAmount({
                amount: delegatedBalanceAmount,
                amountUsdc: oracle.getNormalizedValueUsdc(
                    tokenAddress,
                    delegatedBalanceAmount
                )
            });

        return
            AssetDynamic({
                id: assetAddress,
                typeId: adapterInfo().typeId,
                tokenId: tokenAddress,
                underlyingTokenBalance: underlyingTokenBalance,
                delegatedBalance: delegatedBalance,
                metadata: metadata
            });
    }

    /**
     * Fetch asset position of an account given an asset address
     */
    function positionOf(address accountAddress, address assetAddress)
        public
        view
        returns (Position memory)
    {
        IV2Vault _asset = IV2Vault(assetAddress);
        uint8 assetDecimals = _asset.decimals();
        address tokenAddress = underlyingTokenAddress(assetAddress);
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = _asset.balanceOf(accountAddress);
        uint256 _accountTokenBalance =
            (balance * _asset.pricePerShare()) / 10**assetDecimals;
        uint256 _underlyingTokenBalance = token.balanceOf(accountAddress);
        return
            Position({
                assetId: assetAddress,
                tokenId: tokenAddress,
                typeId: "deposit",
                balance: balance,
                underlyingTokenBalance: TokenAmount({
                    amount: _underlyingTokenBalance,
                    amountUsdc: oracle.getNormalizedValueUsdc(
                        tokenAddress,
                        _underlyingTokenBalance
                    )
                }),
                accountTokenBalance: TokenAmount({
                    amount: _accountTokenBalance,
                    amountUsdc: oracle.getNormalizedValueUsdc(
                        tokenAddress,
                        _accountTokenBalance
                    )
                }),
                tokenAllowances: tokenAllowances(
                    accountAddress,
                    tokenAddress,
                    assetAddress
                ),
                assetAllowances: assetAllowances(accountAddress, assetAddress)
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
     * Fetch TVL of an asset
     */
    function assetTvl(address assetAddress) public view returns (uint256) {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 amount = assetBalance(assetAddress);
        uint256 delegatedBalanceAmount =
            helper.assetStrategiesDelegatedBalance(assetAddress);
        amount -= delegatedBalanceAmount;
        uint256 tvl = oracle.getNormalizedValueUsdc(tokenAddress, amount);
        return tvl;
    }
}