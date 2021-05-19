/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*******************************************************
 *                     Ownable
 *******************************************************/
contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

/*******************************************************
 *                       Interfaces
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

interface IAddressesGenerator {
    function assetsAddresses() external view returns (address[] memory);

    function assetsLength() external view returns (uint256);

    function registry() external view returns (address);

    function getPositionSpenderAddresses()
        external
        view
        returns (address[] memory);
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

/*******************************************************
 *                     Adapter Logic
 *******************************************************/
contract RegisteryAdapterV2Vaults is Ownable {
    /*******************************************************
     *           Common code shared by all adapters
     *******************************************************/
    address public oracleAddress; // The oracle is used to fetch USDC normalized pricing data
    address public helperAddress; // A helper utility is used for batch allowance fetching and address array merging
    address public addressesGeneratorAddress; // A utility for fetching assets addresses and length
    address[] private _extensionsAddresses; // Optional contract extensions provide a way to add new features at a later date

    /**
     * High level static information about an asset
     */
    struct AssetStatic {
        address id; // Asset address
        string typeId; // Asset typeId (for example "VAULT_V2" or "IRON_BANK_MARKET")
        address tokenId; // Underlying token address
        string name; // Asset Name
        string version; // Asset version
        string symbol; // Asset symbol
        uint8 decimals; // Asset decimals
    }

    /**
     * High level dynamic information about an asset
     */
    struct AssetDynamic {
        address id; // Asset address
        string typeId; // Asset typeId (for example "VAULT_V2" or "IRON_BANK_MARKET")
        address tokenId; // Underlying token address;
        TokenAmount underlyingTokenBalance; // Underlying token balances
        AssetMetadata metadata; // Metadata specific to the asset type of this adapter
    }

    /**
     * Information about a user's position relative to an asset
     */
    struct Position {
        address assetId; // Asset address
        address tokenId; // Underlying asset token address
        string typeId; // Position typeId (for example "DEPOSIT," "BORROW," "LEND")
        uint256 balance; // asset.balanceOf(account)
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
    function tokenAllowances(address accountAddress, address assetAddress)
        public
        view
        returns (Allowance[] memory)
    {
        address tokenAddress = assetUnderlyingTokenAddress(assetAddress);
        address[] memory tokenAddresses = new address[](1);
        address[] memory assetAddresses = new address[](1);
        tokenAddresses[0] = tokenAddress;
        assetAddresses[0] = assetAddress;
        bytes memory allowances =
            abi.encode(
                IHelper(helperAddress).allowances(
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
                IHelper(helperAddress).allowances(
                    accountAddress,
                    assetAddresses,
                    IAddressesGenerator(addressesGeneratorAddress)
                        .getPositionSpenderAddresses()
                )
            );
        return abi.decode(allowances, (Allowance[]));
    }

    /**
     * Fetch the total number of assets for this adapter
     */
    function assetsLength() public view returns (uint256) {
        return IAddressesGenerator(addressesGeneratorAddress).assetsLength();
    }

    /**
     * Fetch all asset addresses for this adapter
     */
    function assetsAddresses() public view returns (address[] memory) {
        return IAddressesGenerator(addressesGeneratorAddress).assetsAddresses();
    }

    /**
     * Fetch registry address from addresses generator
     */
    function registryAddress() public view returns (address) {
        return IAddressesGenerator(addressesGeneratorAddress).registry();
    }

    /**
     * Allow storage slots to be manually updated
     */
    function updateSlot(bytes32 slot, bytes32 value) external onlyOwner {
        assembly {
            sstore(slot, value)
        }
    }

    /**
     * Set optional fallback extension addresses
     */
    function setExtensionsAddresses(address[] memory _newExtensionsAddresses)
        external
        onlyOwner
    {
        _extensionsAddresses = _newExtensionsAddresses;
    }

    /**
     * Fetch fallback extension addresses
     */
    function extensionsAddresses() external view returns (address[] memory) {
        return (_extensionsAddresses);
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
                amountUsdc: IOracle(oracleAddress).getNormalizedValueUsdc(
                    tokenAddress,
                    amount
                )
            });
    }

    /*******************************************************
     * Common code shared by v1 vaults, v2 vaults and earn
     *******************************************************/

    /**
     * Fetch asset positions of an account given an array of assets. This method can be used for off-chain pagination.
     */
    function assetsPositionsOf(
        address accountAddress,
        address[] memory _assetsAddresses
    ) public view returns (Position[] memory) {
        uint256 numberOfAssets = _assetsAddresses.length;
        Position[] memory positions = new Position[](numberOfAssets);
        uint256 currentPositionIdx;
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            Position memory position =
                assetPositionsOf(accountAddress, assetAddress)[0];
            if (position.balance > 0) {
                positions[currentPositionIdx] = position;
                currentPositionIdx++;
            }
        }
        bytes memory encodedData = abi.encode(positions);
        assembly {
            mstore(add(encodedData, 0x40), currentPositionIdx)
        }
        positions = abi.decode(encodedData, (Position[]));
        return positions;
    }

    /**
     * Fetch asset positions for an account for all assets
     */
    function assetsPositionsOf(address accountAddress)
        public
        view
        returns (Position[] memory)
    {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsPositionsOf(accountAddress, _assetsAddresses);
    }

    /*******************************************************
     *                 V2 Adapter (unique logic)
     *******************************************************/
    /**
     * Configure adapter
     */
    constructor(
        address _oracleAddress,
        address _helperAddress,
        address _addressesGeneratorAddress
    ) {
        require(_oracleAddress != address(0), "Missing oracle address");
        oracleAddress = _oracleAddress;
        addressesGeneratorAddress = _addressesGeneratorAddress;
        helperAddress = _helperAddress;
    }

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

    // Position types supported by this adapter
    string positionDeposit = "DEPOSIT";
    string[] public supportedPositions = [positionDeposit];

    /**
     * Metadata specific to this asset type
     */
    struct AssetMetadata {
        uint256 pricePerShare; // Vault pricePerShare
        bool migrationAvailable; // True if a migration is available for this vault
        address latestVaultAddress; // Latest vault migration address
        uint256 depositLimit; // Deposit limit of asset
        bool emergencyShutdown; // Vault is in emergency shutdown mode
    }

    /**
     * High level adapter metadata scoped to a user
     */
    struct AdapterPosition {
        uint256 balanceUsdc;
    }

    /**
     * Metadata specific to an asset type scoped to a user.
     * Not used in this adapter.
     */
    struct AssetUserMetadata {
        address depositBalance;
    }

    /**
     * Fetch asset metadata scoped to a user
     */
    function assetUserMetadata(address assetAddress, address accountAddress)
        public
        view
        returns (AssetUserMetadata memory)
    {}

    /**
     * Fetch asset metadata scoped to a user
     */
    function assetsUserMetadata(address accountAddress)
        public
        view
        returns (AssetUserMetadata[] memory)
    {}

    /**
     * Fetch the underlying token address of an asset
     */
    function assetUnderlyingTokenAddress(address assetAddress)
        public
        view
        returns (address)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        address tokenAddress = vault.token();
        return tokenAddress;
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
        address tokenAddress = assetUnderlyingTokenAddress(assetAddress);
        return
            AssetStatic({
                id: assetAddress,
                typeId: adapterInfo().typeId,
                tokenId: tokenAddress,
                name: vault.name(),
                version: vault.apiVersion(),
                symbol: vault.symbol(),
                decimals: vault.decimals()
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
        address tokenAddress = assetUnderlyingTokenAddress(assetAddress);
        uint256 totalSupply = vault.totalSupply();
        uint256 pricePerShare = 0;
        bool vaultHasShares = totalSupply != 0;
        if (vaultHasShares) {
            pricePerShare = vault.pricePerShare();
        }

        address latestVaultAddress =
            IV2Registry(registryAddress()).latestVault(tokenAddress);
        bool migrationAvailable = latestVaultAddress != assetAddress;

        AssetMetadata memory metadata =
            AssetMetadata({
                pricePerShare: pricePerShare,
                migrationAvailable: migrationAvailable,
                latestVaultAddress: latestVaultAddress,
                depositLimit: vault.depositLimit(),
                emergencyShutdown: vault.emergencyShutdown()
            });

        uint256 balance = assetBalance(assetAddress);
        TokenAmount memory underlyingTokenBalance =
            tokenAmount(balance, tokenAddress);

        return
            AssetDynamic({
                id: assetAddress,
                typeId: adapterInfo().typeId,
                tokenId: tokenAddress,
                underlyingTokenBalance: underlyingTokenBalance,
                metadata: metadata
            });
    }

    /**
     * Fetch asset positions of an account given an asset address
     */
    function assetPositionsOf(address accountAddress, address assetAddress)
        public
        view
        returns (Position[] memory)
    {
        IV2Vault _asset = IV2Vault(assetAddress);
        uint8 assetDecimals = _asset.decimals();
        address tokenAddress = assetUnderlyingTokenAddress(assetAddress);
        uint256 balance = _asset.balanceOf(accountAddress);
        uint256 _underlyingTokenBalance =
            (balance * _asset.pricePerShare()) / 10**assetDecimals;
        Position[] memory positions = new Position[](1);
        positions[0] = Position({
            assetId: assetAddress,
            tokenId: tokenAddress,
            typeId: positionDeposit,
            balance: balance,
            underlyingTokenBalance: tokenAmount(
                _underlyingTokenBalance,
                tokenAddress
            ),
            tokenAllowances: tokenAllowances(accountAddress, assetAddress),
            assetAllowances: assetAllowances(accountAddress, assetAddress)
        });
        return positions;
    }

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        IV2Vault vault = IV2Vault(assetAddress);
        return vault.totalAssets();
    }

    /**
     * Fetch high level information about an account
     */
    function adapterPositionOf(address accountAddress)
        external
        view
        returns (AdapterPosition memory)
    {
        Position[] memory positions = assetsPositionsOf(accountAddress);
        uint256 balanceUsdc;
        for (
            uint256 positionIdx;
            positionIdx < positions.length;
            positionIdx++
        ) {
            Position memory position = positions[positionIdx];
            balanceUsdc += position.underlyingTokenBalance.amountUsdc;
        }
        return AdapterPosition({balanceUsdc: balanceUsdc});
    }

    /**
     * Returns unique list of tokens associated with this adapter
     */
    function assetsTokensAddresses() public view returns (address[] memory) {
        IV2Registry _registry = IV2Registry(registryAddress());
        uint256 numberOfTokens = _registry.numTokens();
        address[] memory _tokensAddresses = new address[](numberOfTokens);
        for (uint256 tokenIdx = 0; tokenIdx < numberOfTokens; tokenIdx++) {
            address tokenAddress = _registry.tokens(tokenIdx);
            _tokensAddresses[tokenIdx] = tokenAddress;
        }
        return _tokensAddresses;
    }

    /**
     * Cascading fallback proxy provides the contract with the ability to add new features at a later time
     */
    fallback() external {
        for (uint256 i = 0; i < _extensionsAddresses.length; i++) {
            address extension = _extensionsAddresses[i];
            assembly {
                let _target := extension
                calldatacopy(0, 0, calldatasize())
                let success := staticcall(
                    gas(),
                    _target,
                    0,
                    calldatasize(),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                if success {
                    return(0, returndatasize())
                }
            }
        }
        revert("Extensions: Fallback proxy failed to return data");
    }
}