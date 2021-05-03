/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

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
interface ICyToken {
    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowBalanceStored(address accountAddress)
        external
        view
        returns (uint256);

    function totalReserves() external view returns (uint256);

    function balanceOf(address accountAddress) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IUnitroller {
    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
    }

    function oracle() external view returns (address);

    function getAssetsIn(address accountAddress)
        external
        view
        returns (address[] memory);

    function markets(address marketAddress)
        external
        view
        returns (Market memory);
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

interface IHelper {
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

    function uniqueAddresses(address[] memory input)
        external
        pure
        returns (address[] memory);
}

interface ICreamOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

interface IOracle {
    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) external view returns (uint256);
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function approve(address spender, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function allowance(address spender, address owner)
        external
        view
        returns (uint256);
}

/*******************************************************
 *                     Adapter Logic
 *******************************************************/
contract RegistryAdapterIronBank is Ownable {
    /*******************************************************
     *           Common code shared by all adapters
     *******************************************************/
    address public comptrollerAddress; // Comptroller address
    address public creamOracleAddress; // Cream oracle address
    address public helperAddress; // Helper utility address
    address public oracleAddress; // Yearn oracle address
    uint256 public blocksPerYear = 2102400;
    address[] private _extensionsAddresses; // Optional contract extensions provide a way to add new features at a later date
    ICreamOracle creamOracle; // Cream oracle
    IUnitroller comptroller; // Comptroller
    IOracle oracle; // Yearn oracle
    IHelper helper; // A helper utility is used for batch allowance fetching and address array merging
    IAddressesGenerator public addressesGenerator; // A utility for fetching assets addresses and length

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
        address tokenAddress = underlyingTokenAddress(assetAddress);
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
                    addressesGenerator.getPositionSpenderAddresses()
                )
            );
        return abi.decode(allowances, (Allowance[]));
    }

    /**
     * Internal method for constructing a TokenAmount struct given a token balance and address
     */
    function tokenAmount(
        uint256 amount,
        address tokenAddress,
        uint256 tokenPriceUsdc
    ) internal view returns (TokenAmount memory) {
        return
            TokenAmount({
                amount: amount,
                amountUsdc: oracle.getNormalizedValueUsdc(
                    tokenAddress,
                    amount,
                    tokenPriceUsdc
                )
            });
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
     * Fetch registry address from addresses generator
     */
    function registry() public view returns (address) {
        return addressesGenerator.registry();
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
     * Configure adapter
     */
    constructor(
        address _oracleAddress,
        address _helperAddress,
        address _addressesGeneratorAddress
    ) {
        require(_oracleAddress != address(0), "Missing oracle address");
        oracleAddress = _oracleAddress;
        helperAddress = _helperAddress;
        addressesGenerator = IAddressesGenerator(_addressesGeneratorAddress);
        address _comptrollerAddress = registry();
        comptrollerAddress = _comptrollerAddress;
        comptroller = IUnitroller(comptrollerAddress);
        creamOracleAddress = comptroller.oracle();
        creamOracle = ICreamOracle(creamOracleAddress);
        oracle = IOracle(_oracleAddress);
        helper = IHelper(_helperAddress);
    }

    /*******************************************************
     *                     Iron Bank Adapter
     *******************************************************/
    /**
     * Iron Bank Adapter
     */
    function adapterInfo() public view returns (AdapterInfo memory) {
        return
            AdapterInfo({
                id: address(this),
                typeId: "IRON_BANK_MARKET",
                categoryId: "LENDING"
            });
    }

    // Position types supported by this adapter
    string constant positionLend = "LEND";
    string constant positionBorrow = "BORROW";
    string[] public supportedPositions = [positionLend, positionBorrow];

    /**
     * Metadata specific to this asset type
     */
    struct AssetMetadata {
        uint256 totalSuppliedUsdc;
        uint256 totalBorrowedUsdc;
        uint256 lendApyBips;
        uint256 borrowApyBips;
        uint256 liquidity;
        uint256 liquidityUsdc;
        uint256 collateralFactor;
        bool isActive;
        uint256 reserveFactor;
        uint256 exchangeRate;
    }

    /**
     * High level adapter metadata scoped to a user
     */
    struct AdapterPosition {
        uint256 supplyBalanceUsdc;
        uint256 borrowBalanceUsdc;
        uint256 borrowLimitUsdc;
        uint256 utilizationRatioBips;
    }

    /**
     * Metadata specific to an asset type scoped to a user
     */
    struct AssetUserMetadata {
        address assetId;
        bool enteredMarket;
        uint256 supplyBalanceUsdc;
        uint256 borrowBalanceUsdc;
        uint256 borrowLimitUsdc;
    }

    /**
     * Fetch asset metadata scoped to a user
     */
    function assetUserMetadata(address accountAddress, address assetAddress)
        public
        view
        returns (AssetUserMetadata memory)
    {
        bool enteredMarket;
        address[] memory markets = comptroller.getAssetsIn(accountAddress);
        for (uint256 marketIdx; marketIdx < markets.length; marketIdx++) {
            address marketAddress = markets[marketIdx];
            if (marketAddress == assetAddress) {
                enteredMarket = true;
                break;
            }
        }
        ICyToken asset = ICyToken(assetAddress);
        IUnitroller.Market memory market = comptroller.markets(assetAddress);
        uint256 supplyBalanceShares = asset.balanceOf(accountAddress);
        uint256 supplyBalanceUnderlying =
            (supplyBalanceShares * asset.exchangeRateStored()) / 10**18;
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 tokenPriceUsdc = assetUnderlyingTokenPriceUsdc(assetAddress);
        uint256 supplyBalanceUsdc =
            oracle.getNormalizedValueUsdc(
                tokenAddress,
                supplyBalanceUnderlying,
                tokenPriceUsdc
            );
        uint256 borrowBalanceShares = asset.borrowBalanceStored(accountAddress);
        uint256 borrowBalanceUsdc =
            oracle.getNormalizedValueUsdc(
                tokenAddress,
                borrowBalanceShares,
                tokenPriceUsdc
            );
        uint256 borrowLimitUsdc =
            (supplyBalanceUsdc * market.collateralFactorMantissa) / 10**18;

        return
            AssetUserMetadata({
                assetId: assetAddress,
                enteredMarket: enteredMarket,
                supplyBalanceUsdc: supplyBalanceUsdc,
                borrowBalanceUsdc: borrowBalanceUsdc,
                borrowLimitUsdc: borrowLimitUsdc
            });
    }

    /**
     * Fetch asset metadata scoped to a user
     */
    function assetsUserMetadata(address accountAddress)
        public
        view
        returns (AssetUserMetadata[] memory)
    {
        address[] memory _assetsAddresses = assetsAddresses();
        uint256 numberOfAssets = _assetsAddresses.length;
        AssetUserMetadata[] memory _assetsUserMetadata =
            new AssetUserMetadata[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            _assetsUserMetadata[assetIdx] = assetUserMetadata(
                accountAddress,
                assetAddress
            );
        }
        return _assetsUserMetadata;
    }

    function underlyingTokenAddress(address assetAddress)
        public
        view
        returns (address)
    {
        ICyToken cyToken = ICyToken(assetAddress);
        address tokenAddress = cyToken.underlying();
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
        ICyToken asset = ICyToken(assetAddress);
        address tokenAddress = underlyingTokenAddress(assetAddress);
        return
            AssetStatic({
                id: assetAddress,
                typeId: adapterInfo().typeId,
                tokenId: tokenAddress,
                name: asset.name(),
                version: "2.0.0",
                symbol: asset.symbol(),
                decimals: asset.decimals()
            });
    }

    /**
     * Fetch underlying token price given a cyToken address
     */
    function assetUnderlyingTokenPriceUsdc(address assetAddress)
        public
        view
        returns (uint256)
    {
        address _underlyingTokenAddress = underlyingTokenAddress(assetAddress);
        IERC20 underlyingToken = IERC20(_underlyingTokenAddress);
        uint8 underlyingTokenDecimals = underlyingToken.decimals();
        uint256 underlyingTokenPrice =
            creamOracle.getUnderlyingPrice(assetAddress) /
                (10**(36 - underlyingTokenDecimals - 6));
        return underlyingTokenPrice;
    }

    /**
     * Fetch dynamic information about an asset
     */
    function assetDynamic(address assetAddress)
        public
        view
        returns (AssetDynamic memory)
    {
        ICyToken asset = ICyToken(assetAddress);
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 liquidity = asset.getCash();
        uint256 liquidityUsdc;
        uint256 tokenPriceUsdc = assetUnderlyingTokenPriceUsdc(assetAddress);
        if (liquidity > 0) {
            liquidityUsdc = oracle.getNormalizedValueUsdc(
                tokenAddress,
                liquidity,
                tokenPriceUsdc
            );
        }
        IUnitroller.Market memory market = comptroller.markets(assetAddress);

        uint256 balance = assetBalance(assetAddress);
        TokenAmount memory underlyingTokenBalance =
            tokenAmount(balance, tokenAddress, tokenPriceUsdc);

        uint256 totalBorrowed = asset.totalBorrows();
        uint256 totalBorrowedUsdc =
            oracle.getNormalizedValueUsdc(
                tokenAddress,
                totalBorrowed,
                tokenPriceUsdc
            );

        AssetMetadata memory metadata =
            AssetMetadata({
                totalSuppliedUsdc: underlyingTokenBalance.amountUsdc,
                totalBorrowedUsdc: totalBorrowedUsdc,
                lendApyBips: (asset.supplyRatePerBlock() * blocksPerYear) /
                    10**14,
                borrowApyBips: (asset.borrowRatePerBlock() * blocksPerYear) /
                    10**14,
                liquidity: liquidity,
                liquidityUsdc: liquidityUsdc,
                collateralFactor: market.collateralFactorMantissa,
                isActive: market.isListed,
                reserveFactor: asset.reserveFactorMantissa(),
                exchangeRate: asset.exchangeRateStored()
            });

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
        ICyToken asset = ICyToken(assetAddress);
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 supplyBalanceShares = asset.balanceOf(accountAddress);
        uint256 borrowBalanceShares = asset.borrowBalanceStored(accountAddress);

        uint8 currentPositionIdx;
        Position[] memory positions = new Position[](2);

        uint256 tokenPriceUsdc = assetUnderlyingTokenPriceUsdc(assetAddress);

        if (supplyBalanceShares > 0) {
            uint256 supplyBalanceUnderlying =
                (supplyBalanceShares * asset.exchangeRateStored()) / 10**18;
            positions[currentPositionIdx] = Position({
                assetId: assetAddress,
                tokenId: tokenAddress,
                typeId: positionLend,
                balance: supplyBalanceShares,
                underlyingTokenBalance: tokenAmount(
                    supplyBalanceUnderlying,
                    tokenAddress,
                    tokenPriceUsdc
                ),
                tokenAllowances: tokenAllowances(accountAddress, assetAddress),
                assetAllowances: assetAllowances(accountAddress, assetAddress)
            });
            currentPositionIdx++;
        }
        if (borrowBalanceShares > 0) {
            positions[currentPositionIdx] = Position({
                assetId: assetAddress,
                tokenId: tokenAddress,
                typeId: positionBorrow,
                balance: borrowBalanceShares,
                underlyingTokenBalance: tokenAmount(
                    borrowBalanceShares,
                    tokenAddress,
                    tokenPriceUsdc
                ),
                tokenAllowances: tokenAllowances(accountAddress, assetAddress),
                assetAllowances: assetAllowances(accountAddress, assetAddress)
            });
            currentPositionIdx++;
        }

        // Trim positions
        bytes memory positionsEncoded = abi.encode(positions);
        assembly {
            mstore(add(positionsEncoded, 0x40), currentPositionIdx)
        }
        positions = abi.decode(positionsEncoded, (Position[]));

        return positions;
    }

    /**
     * Fetch positions for an account given an asset address
     */
    function assetsPositionsOf(
        address accountAddress,
        address[] memory _assetsAddresses
    ) public view returns (Position[] memory) {
        uint256 numberOfAssets = _assetsAddresses.length;

        // Maximum of two positions per market: LEND and BORROW
        Position[] memory positions = new Position[](numberOfAssets * 2);
        uint256 currentPositionIdx;
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            Position[] memory assetPositions =
                assetPositionsOf(accountAddress, assetAddress);

            for (
                uint256 assetPositionIdx = 0;
                assetPositionIdx < assetPositions.length;
                assetPositionIdx++
            ) {
                Position memory position = assetPositions[assetPositionIdx];
                if (position.balance > 0) {
                    positions[currentPositionIdx] = position;
                    currentPositionIdx++;
                }
            }
        }

        // Trim positions
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

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        ICyToken cyToken = ICyToken(assetAddress);
        uint256 cash = cyToken.getCash();
        uint256 totalBorrows = cyToken.totalBorrows();
        uint256 totalReserves = cyToken.totalReserves();
        uint256 totalSupplied = (cash + totalBorrows - totalReserves);
        return totalSupplied;
    }

    /**
     * Fetch high level information about an account
     */
    function adapterPositionOf(address accountAddress)
        external
        view
        returns (AdapterPosition memory)
    {
        AssetUserMetadata[] memory _assetsUserMetadata =
            assetsUserMetadata(accountAddress);
        uint256 supplyBalanceUsdc;
        uint256 borrowBalanceUsdc;
        uint256 borrowLimitUsdc;
        for (
            uint256 metadataIdx = 0;
            metadataIdx < _assetsUserMetadata.length;
            metadataIdx++
        ) {
            AssetUserMetadata memory _assetUserMetadata =
                _assetsUserMetadata[metadataIdx];
            supplyBalanceUsdc += _assetUserMetadata.supplyBalanceUsdc;
            borrowBalanceUsdc += _assetUserMetadata.borrowBalanceUsdc;
            borrowLimitUsdc += _assetUserMetadata.borrowLimitUsdc;
        }
        uint256 utilizationRatioBips;
        if (borrowLimitUsdc > 0) {
            utilizationRatioBips =
                (borrowBalanceUsdc * 10000) /
                borrowLimitUsdc;
        }
        return
            AdapterPosition({
                supplyBalanceUsdc: supplyBalanceUsdc,
                borrowBalanceUsdc: borrowBalanceUsdc,
                borrowLimitUsdc: borrowLimitUsdc,
                utilizationRatioBips: utilizationRatioBips
            });
    }

    /**
     * Returns unique list of token addresses associated with this adapter
     */
    function assetsTokensAddresses() public view returns (address[] memory) {
        address[] memory _assetsAddresses = assetsAddresses();
        uint256 numberOfAssets = _assetsAddresses.length;
        address[] memory _tokensAddresses = new address[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            _tokensAddresses[assetIdx] = underlyingTokenAddress(assetAddress);
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