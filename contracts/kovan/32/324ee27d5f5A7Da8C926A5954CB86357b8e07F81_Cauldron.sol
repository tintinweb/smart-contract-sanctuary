// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "./math/WMul.sol";
import "./math/WDiv.sol";
import "./math/CastU128I128.sol";
import "./math/CastI128U128.sol";
import "./math/CastU256U128.sol";
import "./math/CastU256U32.sol";
import "./math/CastU256I256.sol";

library CauldronMath {
    /// @dev Add a number (which might be negative) to a positive, and revert if the result is negative.
    function add(uint128 x, int128 y) internal pure returns (uint128 z) {
        require (y > 0 || x >= uint128(-y), "Result below zero");
        z = y > 0 ? x + uint128(y) : x - uint128(-y);
    }
}

contract Cauldron is AccessControl() {
    using CauldronMath for uint128;
    using WMul for uint256;
    using WDiv for uint256;
    using CastU128I128 for uint128;
    using CastI128U128 for int128;
    using CastU256U128 for uint256;
    using CastU256U32 for uint256;
    using CastU256I256 for uint256;

    event AssetAdded(bytes6 indexed assetId, address indexed asset);
    event SeriesAdded(bytes6 indexed seriesId, bytes6 indexed baseId, address indexed fyToken);
    event IlkAdded(bytes6 indexed seriesId, bytes6 indexed ilkId);
    event SpotOracleAdded(bytes6 indexed baseId, bytes6 indexed ilkId, address indexed oracle, uint32 ratio);
    event RateOracleAdded(bytes6 indexed baseId, address indexed oracle);
    event DebtLimitsSet(bytes6 indexed baseId, bytes6 indexed ilkId, uint96 max, uint24 min, uint8 dec);

    event VaultBuilt(bytes12 indexed vaultId, address indexed owner, bytes6 indexed seriesId, bytes6 ilkId);
    event VaultTweaked(bytes12 indexed vaultId, bytes6 indexed seriesId, bytes6 indexed ilkId);
    event VaultDestroyed(bytes12 indexed vaultId);
    event VaultGiven(bytes12 indexed vaultId, address indexed receiver);

    event VaultPoured(bytes12 indexed vaultId, bytes6 indexed seriesId, bytes6 indexed ilkId, int128 ink, int128 art);
    event VaultStirred(bytes12 indexed from, bytes12 indexed to, uint128 ink, uint128 art);
    event VaultRolled(bytes12 indexed vaultId, bytes6 indexed seriesId, uint128 art);

    event SeriesMatured(bytes6 indexed seriesId, uint256 rateAtMaturity);

    // ==== Configuration data ====
    mapping (bytes6 => address)                                 public assets;          // Underlyings and collaterals available in Cauldron. 12 bytes still free.
    mapping (bytes6 => DataTypes.Series)                        public series;          // Series available in Cauldron. We can possibly use a bytes6 (3e14 possible series).
    mapping (bytes6 => mapping(bytes6 => bool))                 public ilks;            // [seriesId][assetId] Assets that are approved as collateral for a series

    mapping (bytes6 => IOracle)                                 public rateOracles;     // Rate (borrowing rate) accruals oracle for the underlying
    mapping (bytes6 => mapping(bytes6 => DataTypes.SpotOracle)) public spotOracles;     // [assetId][assetId] Spot price oracles

    // ==== Protocol data ====
    mapping (bytes6 => mapping(bytes6 => DataTypes.Debt))       public debt;            // [baseId][ilkId] Max and sum of debt per underlying and collateral.
    mapping (bytes6 => uint256)                                 public ratesAtMaturity; // Borrowing rate at maturity for a mature series

    // ==== User data ====
    mapping (bytes12 => DataTypes.Vault)                        public vaults;          // An user can own one or more Vaults, each one with a bytes12 identifier
    mapping (bytes12 => DataTypes.Balances)                     public balances;        // Both debt and assets

    // ==== Administration ====

    /// @dev Add a new Asset.
    function addAsset(bytes6 assetId, address asset)
        external
        auth
    {
        require (assetId != bytes6(0), "Asset id is zero");
        require (assets[assetId] == address(0), "Id already used");
        assets[assetId] = asset;
        emit AssetAdded(assetId, address(asset));
    }

    /// @dev Set the maximum and minimum debt for an underlying and ilk pair. Can be reset.
    function setDebtLimits(bytes6 baseId, bytes6 ilkId, uint96 max, uint24 min, uint8 dec)
        external
        auth
    {
        require (assets[baseId] != address(0), "Base not found");
        require (assets[ilkId] != address(0), "Ilk not found");
        DataTypes.Debt memory debt_ = debt[baseId][ilkId];
        debt_.max = max;
        debt_.min = min;
        debt_.dec = dec;
        debt[baseId][ilkId] = debt_;
        emit DebtLimitsSet(baseId, ilkId, max, min, dec);
    }

    /// @dev Set a rate oracle. Can be reset.
    function setRateOracle(bytes6 baseId, IOracle oracle)
        external
        auth
    {
        require (assets[baseId] != address(0), "Base not found");
        rateOracles[baseId] = oracle;
        emit RateOracleAdded(baseId, address(oracle));
    }

    /// @dev Set a spot oracle and its collateralization ratio. Can be reset.
    function setSpotOracle(bytes6 baseId, bytes6 ilkId, IOracle oracle, uint32 ratio)
        external
        auth
    {
        require (assets[baseId] != address(0), "Base not found");
        require (assets[ilkId] != address(0), "Ilk not found");
        spotOracles[baseId][ilkId] = DataTypes.SpotOracle({
            oracle: oracle,
            ratio: ratio                                                                    // With 6 decimals. 1000000 == 100%
        });                                                                                 // Allows to replace an existing oracle.
        emit SpotOracleAdded(baseId, ilkId, address(oracle), ratio);
    }

    /// @dev Add a new series
    function addSeries(bytes6 seriesId, bytes6 baseId, IFYToken fyToken)
        external
        auth
    {
        require (seriesId != bytes6(0), "Series id is zero");
        address base = assets[baseId];
        require (base != address(0), "Base not found");
        require (fyToken != IFYToken(address(0)), "Series need a fyToken");
        require (fyToken.underlying() == base, "Mismatched series and base");
        require (rateOracles[baseId] != IOracle(address(0)), "Rate oracle not found");
        require (series[seriesId].fyToken == IFYToken(address(0)), "Id already used");
        series[seriesId] = DataTypes.Series({
            fyToken: fyToken,
            maturity: fyToken.maturity().u32(),
            baseId: baseId
        });
        emit SeriesAdded(seriesId, baseId, address(fyToken));
    }

    /// @dev Add a new Ilk (approve an asset as collateral for a series).
    function addIlks(bytes6 seriesId, bytes6[] calldata ilkIds)
        external
        auth
    {
        DataTypes.Series memory series_ = series[seriesId];
        require (
            series_.fyToken != IFYToken(address(0)),
            "Series not found"
        );
        for (uint256 i = 0; i < ilkIds.length; i++) {
            require (
                spotOracles[series_.baseId][ilkIds[i]].oracle != IOracle(address(0)),
                "Spot oracle not found"
            );
            ilks[seriesId][ilkIds[i]] = true;
            emit IlkAdded(seriesId, ilkIds[i]);
        }
    }

    // ==== Vault management ====

    /// @dev Create a new vault, linked to a series (and therefore underlying) and a collateral
    function build(address owner, bytes12 vaultId, bytes6 seriesId, bytes6 ilkId)
        external
        auth
        returns(DataTypes.Vault memory vault)
    {
        require (vaultId != bytes12(0), "Vault id is zero");
        require (seriesId != bytes12(0), "Series id is zero");
        require (ilkId != bytes12(0), "Ilk id is zero");
        require (vaults[vaultId].seriesId == bytes6(0), "Vault already exists");   // Series can't take bytes6(0) as their id
        require (ilks[seriesId][ilkId] == true, "Ilk not added to series");
        vault = DataTypes.Vault({
            owner: owner,
            seriesId: seriesId,
            ilkId: ilkId
        });
        vaults[vaultId] = vault;

        emit VaultBuilt(vaultId, owner, seriesId, ilkId);
    }

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vaultId)
        external
        auth
    {
        DataTypes.Balances memory balances_ = balances[vaultId];
        require (balances_.art == 0 && balances_.ink == 0, "Only empty vaults");
        delete vaults[vaultId];
        emit VaultDestroyed(vaultId);
    }

    /// @dev Change a vault series and/or collateral types.
    function _tweak(bytes12 vaultId, DataTypes.Vault memory vault)
        internal
    {
        require (vault.seriesId != bytes6(0), "Series id is zero");
        require (vault.ilkId != bytes6(0), "Ilk id is zero");
        require (ilks[vault.seriesId][vault.ilkId] == true, "Ilk not added to series");

        vaults[vaultId] = vault;
        emit VaultTweaked(vaultId, vault.seriesId, vault.ilkId);
    }

    /// @dev Change a vault series and/or collateral types.
    /// We can change the series if there is no debt, or assets if there are no assets
    function tweak(bytes12 vaultId, bytes6 seriesId, bytes6 ilkId)
        external
        auth
        returns(DataTypes.Vault memory vault)
    {
        DataTypes.Balances memory balances_ = balances[vaultId];
        vault = vaults[vaultId];
        if (seriesId != vault.seriesId) {
            require (balances_.art == 0, "Only with no debt");
            vault.seriesId = seriesId;
        }
        if (ilkId != vault.ilkId) {
            require (balances_.ink == 0, "Only with no collateral");
            vault.ilkId = ilkId;
        }
        _tweak(vaultId, vault);
    }

    /// @dev Transfer a vault to another user.
    function _give(bytes12 vaultId, address receiver)
        internal
        returns(DataTypes.Vault memory vault)
    {
        require (vaultId != bytes12(0), "Vault id is zero");
        vault = vaults[vaultId];
        vault.owner = receiver;
        vaults[vaultId] = vault;
        emit VaultGiven(vaultId, receiver);
    }

    /// @dev Transfer a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        auth
        returns(DataTypes.Vault memory vault)
    {
        vault = _give(vaultId, receiver);
    }

    // ==== Asset and debt management ====

    function vaultData(bytes12 vaultId, bool getSeries)
        internal
        view
        returns (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_)
    {
        vault_ = vaults[vaultId];
        require (vault_.seriesId != bytes6(0), "Vault not found");
        if (getSeries) series_ = series[vault_.seriesId];
        balances_ = balances[vaultId];
    }

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art)
    {
        if (uint32(block.timestamp) >= series[seriesId].maturity) {
            DataTypes.Series memory series_ = series[seriesId];
            art = uint256(base).wdiv(_accrual(seriesId, series_)).u128();
        } else {
            art = base;
        }
    }

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base)
    {
        if (uint32(block.timestamp) >= series[seriesId].maturity) {
            DataTypes.Series memory series_ = series[seriesId];
            base = uint256(art).wmul(_accrual(seriesId, series_)).u128();
        } else {
            base = art;
        }
    }

    /// @dev Move collateral and debt between vaults.
    function stir(bytes12 from, bytes12 to, uint128 ink, uint128 art)
        external
        auth
        returns (DataTypes.Balances memory, DataTypes.Balances memory)
    {
        require (from != to, "Identical vaults");
        (DataTypes.Vault memory vaultFrom, , DataTypes.Balances memory balancesFrom) = vaultData(from, false);
        (DataTypes.Vault memory vaultTo, , DataTypes.Balances memory balancesTo) = vaultData(to, false);

        if (ink > 0) {
            require (vaultFrom.ilkId == vaultTo.ilkId, "Different collateral");
            balancesFrom.ink -= ink;
            balancesTo.ink += ink;
        }
        if (art > 0) {
            require (vaultFrom.seriesId == vaultTo.seriesId, "Different series");
            balancesFrom.art -= art;
            balancesTo.art += art;
        }

        balances[from] = balancesFrom;
        balances[to] = balancesTo;

        if (ink > 0) require(_level(vaultFrom, balancesFrom, series[vaultFrom.seriesId]) >= 0, "Undercollateralized at origin");
        if (art > 0) require(_level(vaultTo, balancesTo, series[vaultTo.seriesId]) >= 0, "Undercollateralized at destination");

        emit VaultStirred(from, to, ink, art);
        return (balancesFrom, balancesTo);
    }

    /// @dev Add collateral and borrow from vault, pull assets from and push borrowed asset to user
    /// Or, repay to vault and remove collateral, pull borrowed asset from and push assets to user
    function _pour(
        bytes12 vaultId,
        DataTypes.Vault memory vault_,
        DataTypes.Balances memory balances_,
        DataTypes.Series memory series_,
        int128 ink,
        int128 art
    )
        internal returns (DataTypes.Balances memory)
    {
        // For now, the collateralization checks are done outside to allow for underwater operation. That might change.
        if (ink != 0) {
            balances_.ink = balances_.ink.add(ink);
        }

        // Modify vault and global debt records. If debt increases, check global limit.
        if (art != 0) {
            DataTypes.Debt memory debt_ = debt[series_.baseId][vault_.ilkId];
            balances_.art = balances_.art.add(art);
            debt_.sum = debt_.sum.add(art);
            uint128 dust = debt_.min * uint128(10) ** debt_.dec;
            uint128 line = debt_.max * uint128(10) ** debt_.dec;
            require (balances_.art == 0 || balances_.art >= dust, "Min debt not reached");
            if (art > 0) require (debt_.sum <= line, "Max debt exceeded");
            debt[series_.baseId][vault_.ilkId] = debt_;
        }
        balances[vaultId] = balances_;

        emit VaultPoured(vaultId, vault_.seriesId, vault_.ilkId, ink, art);
        return balances_;
    }

    /// @dev Manipulate a vault, ensuring it is collateralized afterwards.
    /// To be used by debt management contracts.
    function pour(bytes12 vaultId, int128 ink, int128 art)
        external
        auth
        returns (DataTypes.Balances memory)
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);

        balances_ = _pour(vaultId, vault_, balances_, series_, ink, art);

        if (balances_.art > 0 && (ink < 0 || art > 0))                          // If there is debt and we are less safe
            require(_level(vault_, balances_, series_) >= 0, "Undercollateralized");
        return balances_;
    }

    /// @dev Give an uncollateralized vault to another user.
    /// To be used for liquidation engines.
    function grab(bytes12 vaultId, address receiver)
        external
        auth
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);
        require(_level(vault_, balances_, series_) < 0, "Not undercollateralized");
        _give(vaultId, receiver);
    }

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    /// To be used by liquidation engines.
    function slurp(bytes12 vaultId, uint128 ink, uint128 art)
        external
        auth
        returns (DataTypes.Balances memory)
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);

        balances_ = _pour(vaultId, vault_, balances_, series_, -(ink.i128()), -(art.i128()));

        return balances_;
    }

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(bytes12 vaultId, bytes6 newSeriesId, int128 art)
        external
        auth
        returns (DataTypes.Vault memory, DataTypes.Balances memory)
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory oldSeries_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);
        DataTypes.Series memory newSeries_ = series[newSeriesId];
        require (oldSeries_.baseId == newSeries_.baseId, "Mismatched bases in series");
        
        // Change the vault series
        vault_.seriesId = newSeriesId;
        _tweak(vaultId, vault_);

        // Change the vault balances
        balances_ = _pour(vaultId, vault_, balances_, newSeries_, 0, art);

        require(_level(vault_, balances_, newSeries_) >= 0, "Undercollateralized");
        emit VaultRolled(vaultId, newSeriesId, balances_.art);

        return (vault_, balances_);
    }

    // ==== Accounting ====

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId)
        external
        returns (int256)
    {
        (DataTypes.Vault memory vault_, DataTypes.Series memory series_, DataTypes.Balances memory balances_) = vaultData(vaultId, true);

        return _level(vault_, balances_, series_);
    }

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId)
        external
    {
        require (ratesAtMaturity[seriesId] == 0, "Already matured");
        DataTypes.Series memory series_ = series[seriesId];
        _mature(seriesId, series_);
    }

    /// @dev Record the borrowing rate at maturity for a series
    function _mature(bytes6 seriesId, DataTypes.Series memory series_)
        internal
    {
        require (uint32(block.timestamp) >= series_.maturity, "Only after maturity");
        IOracle rateOracle = rateOracles[series_.baseId];
        (uint256 rateAtMaturity,) = rateOracle.get(series_.baseId, bytes32("rate"), 1e18);
        ratesAtMaturity[seriesId] = rateAtMaturity;
        emit SeriesMatured(seriesId, rateAtMaturity);
    }

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId)
        external
        returns (uint256)
    {
        DataTypes.Series memory series_ = series[seriesId];
        return _accrual(seriesId, series_);
    }

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    /// Note: Call only after checking we are past maturity
    function _accrual(bytes6 seriesId, DataTypes.Series memory series_)
        private
        returns (uint256 accrual_)
    {
        uint256 rateAtMaturity = ratesAtMaturity[seriesId];
        if (rateAtMaturity == 0) {  // After maturity, but rate not yet recorded. Let's record it, and accrual is then 1.
            _mature(seriesId, series_);
        } else {
            IOracle rateOracle = rateOracles[series_.baseId];
            (uint256 rate,) = rateOracle.get(series_.baseId, bytes32("rate"), 1e18);
            accrual_ = rate.wdiv(rateAtMaturity);
        }
        accrual_ = accrual_ >= 1e18 ? accrual_ : 1e18;     // The accrual can't be below 1 (with 18 decimals)
    }

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function _level(
        DataTypes.Vault memory vault_,
        DataTypes.Balances memory balances_,
        DataTypes.Series memory series_
    )
        internal
        returns (int256)
    {
        DataTypes.SpotOracle memory spotOracle_ = spotOracles[series_.baseId][vault_.ilkId];
        uint256 ratio = uint256(spotOracle_.ratio) * 1e12;   // Normalized to 18 decimals
        (uint256 inkValue,) = spotOracle_.oracle.get(series_.baseId, vault_.ilkId, balances_.ink);    // ink * spot

        if (uint32(block.timestamp) >= series_.maturity) {
            uint256 accrual_ = _accrual(vault_.seriesId, series_);
            return inkValue.i256() - uint256(balances_.art).wmul(accrual_).wmul(ratio).i256();
        }

        return inkValue.i256() - uint256(balances_.art).wmul(ratio).i256();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";


interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(bytes32 base, bytes32 quote, uint256 amount) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(bytes32 base, bytes32 quote, uint256 amount) external returns (uint256 value, uint256 updateTime);

    /**
     * @notice Number of decimals in the amounts returned by the oracle.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";


library DataTypes {
    struct Series {
        IFYToken fyToken;                                               // Redeemable token for the series.
        bytes6  baseId;                                                 // Asset received on redemption.
        uint32  maturity;                                               // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max;                                                     // Maximum debt accepted for a given underlying, across all series
        uint24 min;                                                     // Minimum debt accepted for a given underlying, across all series
        uint8 dec;                                                      // Multiplying factor (10**dec) for max and min 
        uint128 sum;                                                    // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle;                                                 // Address for the spot price oracle
        uint32  ratio;                                                  // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6  seriesId;                                                // Each vault is related to only one series, which also determines the underlying.
        bytes6  ilkId;                                                   // Asset accepted as collateral
    }

    struct Balances {
        uint128 art;                                                     // Debt amount
        uint128 ink;                                                     // Collateral amount
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant LOCK = 0xFFFFFFFF; // Used to disable further permissioning of a function

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library WMul {
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Multiply an amount by a fixed point factor with 18 decimals, rounds down.
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked { z /= 1e18; }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library WDiv { // Fixed point arithmetic in 18 decimal units
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Divide an amount by a fixed point factor with 18 decimals
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e18) / y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastI128U128 {
    /// @dev Safely cast an int128 to an uint128
    function u128(int128 x) internal pure returns (uint128 y) {
        require (x >= 0, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastU256U32 {
    /// @dev Safely cast an uint256 to an u32
    function u32(uint256 x) internal pure returns (uint32 y) {
        require (x <= type(uint32).max, "Cast overflow");
        y = uint32(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastU256I256 {
    /// @dev Safely cast an uint256 to an int256
    function i256(uint256 x) internal pure returns (int256 y) {
        require (x <= uint256(type(int256).max), "Cast overflow");
        y = int256(x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

