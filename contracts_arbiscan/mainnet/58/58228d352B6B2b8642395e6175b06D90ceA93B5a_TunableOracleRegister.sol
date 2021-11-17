// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "@openzeppelin/contracts/proxy/IBeacon.sol";
import "@openzeppelin/contracts/proxy/BeaconProxy.sol";

import "../../interface/IOracle.sol";
import "../../interface/ILiquidityPoolGetter.sol";
import "../../libraries/SafeMathExt.sol";

/**
 * @dev TunableOracleRegister is managed by MCDEX DAO, who can add some ExternalOracles.
 *      TunableOracle selects one of the registered ExternalOracles and set FineTunedPrice
 *      to improve the precision.
 */
contract TunableOracleRegister is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    IBeacon
{
    struct ExternalOracle {
        bool isAdded;
        bool isTerminated;
        uint64 deviation; // decimals = 18. index price will be truncated to mark price * (1 ± deviation).
        uint64 timeout; // seconds. the effective timespan of FineTunedPrice.
    }

    mapping(address => ExternalOracle) internal _externalOracles;
    bool public isAllTerminated;
    address private _tunableOracleImplementation;
    mapping(address => bool) public tunableOracles;

    event SetExternalOracle(address indexed externalOracle, uint64 deviation, uint64 timeout);
    event Terminated(address indexed externalOracle);
    event AllTerminated();
    event Upgraded(address indexed implementation);
    event TunableOracleCreated(
        address indexed liquidityPool,
        address indexed externalOracle,
        address newOracle
    );

    /**
     * @dev TERMINATER_ROLE can shutdown the oracle service and never online again.
     */
    bytes32 public constant TERMINATER_ROLE = keccak256("TERMINATER_ROLE");

    function initialize() external virtual initializer {
        __TunableOracleRegister_init();
    }

    function __TunableOracleRegister_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __TunableOracleRegister_init_unchained();
    }

    function __TunableOracleRegister_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(TERMINATER_ROLE, _msgSender());
        _setTunableOracleImplementation(address(new TunableOracle()));
    }

    /**
     * @dev Read an ExternalOracle config.
     */
    function getExternalOracle(address externalOracle)
        external
        view
        returns (ExternalOracle memory)
    {
        return _externalOracles[externalOracle];
    }

    /**
     * @dev The ExternalOracle was shutdown and never online again.
     */
    function isTerminated(address externalOracle) external view returns (bool) {
        ExternalOracle storage m = _externalOracles[externalOracle];
        return isAllTerminated || m.isTerminated;
    }

    /**
     * @dev Beacon implementation of a TunableOracle.
     *
     *      CAUTION: if TunableOracleRegister is proxied by a TransparentUpgradeableProxy,
     *               the ProxyAdmin will get the TunableOracleRegister implementation and
     *               other address will get TunableOracle implementation.
     */
    function implementation() public view virtual override returns (address) {
        return _tunableOracleImplementation;
    }

    /**
     * @dev Anyone can create an TunableOracle.
     */
    function newTunableOracle(address liquidityPool, address externalOracle)
        external
        returns (address)
    {
        BeaconProxy newOracle = new BeaconProxy(
            address(this), // beacon
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                address(this), // register
                liquidityPool,
                externalOracle
            )
        );
        tunableOracles[address(newOracle)] = true;
        emit TunableOracleCreated(liquidityPool, externalOracle, address(newOracle));
        return address(newOracle);
    }

    /**
     * @dev Admin can add or overwrite an ExternalOracle.
     */
    function setExternalOracle(
        address externalOracle,
        uint64 deviation, // decimals = 18
        uint64 timeout
    ) external {
        require(!isAllTerminated, "all terminated");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "role");
        ExternalOracle storage config = _externalOracles[externalOracle];
        config.isAdded = true;
        config.deviation = deviation;
        config.timeout = timeout;
        emit SetExternalOracle(externalOracle, deviation, timeout);
    }

    /**
     * @dev Admin can upgrade all TunableOracles.
     */
    function upgradeTunableOracle(address newImplementation) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "role");
        _setTunableOracleImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Terminater can stop an ExternalOracle.
     */
    function setTerminated(address externalOracle) external {
        require(!isAllTerminated, "all terminated");
        require(hasRole(TERMINATER_ROLE, _msgSender()), "role");
        ExternalOracle storage m = _externalOracles[externalOracle];
        m.isTerminated = true;
        emit Terminated(externalOracle);
    }

    /**
     * @dev Terminater can stop all ExternalOracles.
     */
    function setAllTerminated() external {
        require(!isAllTerminated, "all terminated");
        require(hasRole(TERMINATER_ROLE, _msgSender()), "role");
        isAllTerminated = true;
        emit AllTerminated();
    }

    function _setTunableOracleImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "not a contract");
        _tunableOracleImplementation = newImplementation;
    }
}

/**
 * @dev TunableOracle uses an ExternalOracle as MarkPrice and backup IndexPrice (AMM reference price).
 *      IndexPrice can be set by FineTuner unless timeout or given up (released) by FineTuner.
 *
 *      CAUTION: TunableOracle only uses externalOracle.markPrice.
 *
 *               +--------+--------+-----------+--------+---------+--------+
 * FineTunePrice | Price1 |        | (timeout) | Price4 | Release |        |
 *               +--------+--------+-----------+--------+---------+--------+
 * ExternalPrice | Price2 | Price3 |           |        |         | Price5 |
 *               +--------+--------+-----------+--------+---------+--------+
 * IndexPrice    | Price1 | Price1 | Price3    | Price4 | Price3  | Price5 |
 *               +--------+--------+-----------+--------+---------+--------+
 */
contract TunableOracle is Initializable, ContextUpgradeable, IOracle {
    using SignedSafeMathUpgradeable for int256;
    using SafeMathExt for int256;
    using SafeMathExt for uint256;
    using SafeCastUpgradeable for int256;
    using SafeCastUpgradeable for uint256;

    TunableOracleRegister public register;
    ILiquidityPoolGetter public liquidityPool;
    IOracle public externalOracle;

    // in order to save gas
    struct Price {
        int192 price;
        uint64 timestamp;
    }
    Price public externalPrice;
    Price public fineTunedPrice;
    bool public isReleased;
    address public fineTuner;

    event SetFineTuner(address fineTuner);
    event SetPrice(int256 price, uint256 timestamp);
    event Released();

    modifier onlyOperator() {
        require(_msgSender() == _getOperator(), "only Operator");
        _;
    }

    modifier onlyFineTuner() {
        require(_msgSender() == fineTuner, "only FineTuner");
        _;
    }

    function blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function initialize(
        address tunableOracleRegister_,
        address liquidityPool_,
        address externalOracle_
    ) external virtual initializer {
        __TunableOracle_init(tunableOracleRegister_, liquidityPool_, externalOracle_);
    }

    function __TunableOracle_init(
        address tunableOracleRegister_,
        address liquidityPool_,
        address externalOracle_
    ) internal initializer {
        __Context_init_unchained();
        __TunableOracle_init_unchained(tunableOracleRegister_, liquidityPool_, externalOracle_);
    }

    function __TunableOracle_init_unchained(
        address tunableOracleRegister_,
        address liquidityPool_,
        address externalOracle_
    ) internal initializer {
        require(AddressUpgradeable.isContract(tunableOracleRegister_), "not a contract");
        require(AddressUpgradeable.isContract(liquidityPool_), "not a contract");
        register = TunableOracleRegister(tunableOracleRegister_);
        liquidityPool = ILiquidityPoolGetter(liquidityPool_);
        externalOracle = IOracle(externalOracle_);

        // must registered
        TunableOracleRegister.ExternalOracle memory config = register.getExternalOracle(
            address(externalOracle)
        );
        require(config.isAdded, "not registered");

        // must have operator
        require(_getOperator() != address(0), "no operator");

        // must not terminated
        require(!register.isTerminated(address(externalOracle)), "terminated");
        require(!externalOracle.isTerminated(), "external terminated");

        // save the initial mark price to make sure everything is working
        _forceUpdateExternalOracle();
    }

    /**
     * @dev Get collateral symbol. Also known as quote.
     */
    function collateral() external view override returns (string memory) {
        return externalOracle.collateral();
    }

    /**
     * @dev Get underlying asset symbol. Also known as base.
     */
    function underlyingAsset() external view override returns (string memory) {
        return externalOracle.underlyingAsset();
    }

    /**
     * @dev Mark price. Used to evaluate the account margin balance and liquidation.
     *
     *      Mark price is always ExternalOracle price.
     *      It does not need to be a TWAP. This name is only for backward compatibility.
     */
    function priceTWAPLong() public override returns (int256, uint256) {
        if (!isTerminated()) {
            _forceUpdateExternalOracle();
        } else {
            // leave the last price unchanged
        }
        return (externalPrice.price, externalPrice.timestamp);
    }

    /**
     * @dev Index price. It is AMM reference price.
     *
     *      It does not need to be a TWAP. This name is only for backward compatibility.
     */
    function priceTWAPShort() external override returns (int256, uint256) {
        // update external
        bool isTerminated_ = isTerminated();
        if (!isTerminated_) {
            _forceUpdateExternalOracle();
        } else {
            // leave the last price unchanged
        }
        int256 markPrice = int256(externalPrice.price);

        // pause the timestamp if terminated
        uint256 currentTime;
        if (!isTerminated_) {
            currentTime = blockTimestamp();
        } else {
            currentTime = uint256(externalPrice.timestamp).max(uint256(fineTunedPrice.timestamp));
        }

        // use ExternalOracle
        TunableOracleRegister.ExternalOracle memory config = register.getExternalOracle(
            address(externalOracle)
        );
        uint256 timeToDie = uint256(fineTunedPrice.timestamp) + uint256(config.timeout);
        if (currentTime >= timeToDie || isReleased) {
            return (
                markPrice,
                // time can not turn back
                uint256(externalPrice.timestamp).max(currentTime)
            );
        }

        // use FineTuner
        int256 width = int256(config.deviation).wmul(markPrice);
        int256 price = int256(fineTunedPrice.price);
        price = price.min(markPrice.add(width));
        price = price.max(markPrice.sub(width));
        return (price, fineTunedPrice.timestamp);
    }

    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external override returns (bool) {
        return externalOracle.isMarketClosed();
    }

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() public override returns (bool) {
        return register.isTerminated(address(externalOracle)) || externalOracle.isTerminated();
    }

    /**
     * @dev Operator can grant a FineTuner.
     */
    function setFineTuner(address newFineTuner) external onlyOperator {
        require(fineTuner != newFineTuner, "already set");
        fineTuner = newFineTuner;
        emit SetFineTuner(newFineTuner);
    }

    /**
     * @dev FineTuner can set price.
     *
     *      Implies timestamp = block.timestamp.
     */
    function setPrice(int256 newPrice) external onlyFineTuner {
        require(newPrice > 0, "price <= 0");
        require(!isTerminated(), "terminated");
        uint256 currentTime = blockTimestamp();
        fineTunedPrice = Price(_toInt192(newPrice), currentTime.toUint64());
        isReleased = false;
        emit SetPrice(newPrice, currentTime);
    }

    /**
     * @dev FineTuner can give up the FineTunedPrice.
     */
    function release() external onlyFineTuner {
        require(!isTerminated(), "terminated");
        isReleased = true;
        emit Released();
    }

    function _getOperator() internal view returns (address) {
        address[7] memory poolAddresses;
        uint256[6] memory uintNums;
        (, , poolAddresses, , uintNums) = liquidityPool.getLiquidityPoolInfo();
        return
            blockTimestamp() <= uintNums[3] /* operatorExpiration */
                ? poolAddresses[1] /* operator */
                : address(0);
    }

    function _forceUpdateExternalOracle() internal {
        (int256 p, uint256 t) = externalOracle.priceTWAPLong();
        require(p > 0, "external price <= 0");
        require(t > 0, "external time = 0");
        require(externalPrice.timestamp <= t, "external time reversed");
        // truncate timestamp to block.timestamp, so that when FineTuner sets price,
        // FineTuned price timestamp will >= markPrice.timestamp.
        t = t.min(blockTimestamp());
        externalPrice = Price(_toInt192(p), t.toUint64());
    }

    function _toInt192(int256 value) internal pure returns (int192) {
        require(value >= -2**191 && value < 2**191, "can not fit in int192");
        return int192(value);
    }
}

/**
 * @dev A simple tool to call setPrice of multiple TunableOracles.
 */
contract MultiTunableOracleSetter is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable
{
    mapping(uint32 => address) public tunableOracles;

    event SetTunableOracle(uint32 indexed id, address tunableOracle);
    
    /**
     * @dev FINE_TUNER_ROLE can set price.
     */
    bytes32 public constant FINE_TUNER_ROLE = keccak256("FINE_TUNER_ROLE");

    function initialize() external virtual initializer {
        __MultiTunableOracleSetter_init();
    }

    function __MultiTunableOracleSetter_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __MultiTunableOracleSetter_init_unchained();
    }

    function __MultiTunableOracleSetter_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FINE_TUNER_ROLE, _msgSender());
    }

    /**
     * @dev Admin can refer an id to a TunableOracle.
     */
    function setOracle(
        uint32 id,
        address tunableOracle
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "role");
        tunableOracles[id] = tunableOracle;
        emit SetTunableOracle(id, tunableOracle);
    }

    /**
     * @dev FineTuner can set prices.
     *
     * @param price1 is a packed structure.
     *         255     224 223         192 191           0
     *        +-----------+---------------+---------------+
     *        | id 32bits | unused 32bits | price 192bits |
     *        +-----------+---------------+---------------+
     */
    function setPrice1(bytes32 price1) external {
        require(hasRole(FINE_TUNER_ROLE, _msgSender()), "role");
        _setPrice(price1);
    }

    function setPrice2(bytes32 price1, bytes32 price2) external {
        require(hasRole(FINE_TUNER_ROLE, _msgSender()), "role");
        _setPrice(price1);
        _setPrice(price2);
    }

    function setPrices(bytes32[] memory prices) external {
        require(hasRole(FINE_TUNER_ROLE, _msgSender()), "role");
        for (uint256 i = 0; i < prices.length; i++) {
            _setPrice(prices[i]);
        }
    }

    function _setPrice(bytes32 price1) internal {
        uint32 id = uint32(uint256(price1) >> 224);
        int192 price = int192(uint256(price1));
        TunableOracle oracle = TunableOracle(tunableOracles[id]);
        require(oracle != TunableOracle(0), "unregistered");
        oracle.setPrice(price);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
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
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";
import "./IBeacon.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) public payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _setBeacon(beacon, data);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_beacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        require(
            Address.isContract(beacon),
            "BeaconProxy: beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(beacon).implementation()),
            "BeaconProxy: beacon implementation is not a contract"
        );
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(_implementation(), data, "BeaconProxy: function call failed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface IOracle {
    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external returns (bool);

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external returns (bool);

    /**
     * @dev Get collateral symbol. Also known as quote.
     */
    function collateral() external view returns (string memory);

    /**
     * @dev Get underlying asset symbol. Also known as base.
     */
    function underlyingAsset() external view returns (string memory);

    /**
     * @dev Mark price. Used to evaluate the account margin balance and liquidation.
     *
     *      It does not need to be a TWAP. This name is only for backward compatibility.
     */
    function priceTWAPLong() external returns (int256 newPrice, uint256 newTimestamp);

    /**
     * @dev Index price. It is AMM reference price.
     *
     *      It does not need to be a TWAP. This name is only for backward compatibility.
     */
    function priceTWAPShort() external returns (int256 newPrice, uint256 newTimestamp);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../Type.sol";

interface ILiquidityPoolGetter {
    /**
     * @notice Get the info of the liquidity pool
     * @return isRunning True if the liquidity pool is running
     * @return isFastCreationEnabled True if the operator of the liquidity pool is allowed to create new perpetual
     *                               when the liquidity pool is running
     * @return addresses The related addresses of the liquidity pool
     * @return intNums Int type properties, see below for details.
     * @return uintNums Uint type properties, see below for details.
     */
    function getLiquidityPoolInfo()
        external
        view
        returns (
            bool isRunning,
            bool isFastCreationEnabled,
            // [0] creator,
            // [1] operator,
            // [2] transferringOperator,
            // [3] governor,
            // [4] shareToken,
            // [5] collateralToken,
            // [6] vault,
            address[7] memory addresses,
            // [0] vaultFeeRate,
            // [1] poolCash,
            // [2] insuranceFundCap,
            // [3] insuranceFund,
            // [4] donatedInsuranceFund,
            int256[5] memory intNums,
            // [0] collateralDecimals,
            // [1] perpetualCount,
            // [2] fundingTime,
            // [3] operatorExpiration,
            // [4] liquidityCap,
            // [5] shareTransferDelay,
            uint256[6] memory uintNums
        );

    /**
     * @notice Get the info of the perpetual. Need to update the funding state and the oracle price
     *         of each perpetual before and update the funding rate of each perpetual after
     * @param perpetualIndex The index of the perpetual in the liquidity pool
     * @return state The state of the perpetual
     * @return oracle The oracle's address of the perpetual
     * @return nums The related numbers of the perpetual
     */
    function getPerpetualInfo(uint256 perpetualIndex)
        external
        view
        returns (
            PerpetualState state,
            address oracle,
            // [0] totalCollateral
            // [1] markPrice, (return settlementPrice if it is in EMERGENCY state)
            // [2] indexPrice,
            // [3] fundingRate,
            // [4] unitAccumulativeFunding,
            // [5] initialMarginRate,
            // [6] maintenanceMarginRate,
            // [7] operatorFeeRate,
            // [8] lpFeeRate,
            // [9] referralRebateRate,
            // [10] liquidationPenaltyRate,
            // [11] keeperGasReward,
            // [12] insuranceFundRate,
            // [13-15] halfSpread value, min, max,
            // [16-18] openSlippageFactor value, min, max,
            // [19-21] closeSlippageFactor value, min, max,
            // [22-24] fundingRateLimit value, min, max,
            // [25-27] ammMaxLeverage value, min, max,
            // [28-30] maxClosePriceDiscount value, min, max,
            // [31] openInterest,
            // [32] maxOpenInterestRate,
            // [33-35] fundingRateFactor value, min, max,
            // [36-38] defaultTargetLeverage value, min, max,
            // [39-41] baseFundingRate value, min, max,
            int256[42] memory nums
        );

    /**
     * @notice Get the account info of the trader. Need to update the funding state and the oracle price
     *         of each perpetual before and update the funding rate of each perpetual after
     * @param perpetualIndex The index of the perpetual in the liquidity pool
     * @param trader The address of the trader
     * @return cash The cash(collateral) of the account
     * @return position The position of the account
     * @return availableMargin The available margin of the account
     * @return margin The margin of the account
     * @return settleableMargin The settleable margin of the account
     * @return isInitialMarginSafe True if the account is initial margin safe
     * @return isMaintenanceMarginSafe True if the account is maintenance margin safe
     * @return isMarginSafe True if the total value of margin account is beyond 0
     * @return targetLeverage   The target leverage for openning position.
     */
    function getMarginAccount(uint256 perpetualIndex, address trader)
        external
        view
        returns (
            int256 cash,
            int256 position,
            int256 availableMargin,
            int256 margin,
            int256 settleableMargin,
            bool isInitialMarginSafe,
            bool isMaintenanceMarginSafe,
            bool isMarginSafe, // bankrupt
            int256 targetLeverage
        );

    /**
     * @notice Get the number of active accounts in the perpetual.
     *         Active means the trader's account is not empty in the perpetual.
     *         Empty means cash and position are zero
     * @param perpetualIndex The index of the perpetual in the liquidity pool
     * @return activeAccountCount The number of active accounts in the perpetual
     */
    function getActiveAccountCount(uint256 perpetualIndex) external view returns (uint256);

    /**
     * @notice Get the active accounts in the perpetual whose index between begin and end.
     *         Active means the trader's account is not empty in the perpetual.
     *         Empty means cash and position are zero
     * @param perpetualIndex The index of the perpetual in the liquidity pool
     * @param begin The begin index
     * @param end The end index
     * @return result The active accounts in the perpetual whose index between begin and end
     */
    function listActiveAccounts(
        uint256 perpetualIndex,
        uint256 begin,
        uint256 end
    ) external view returns (address[] memory result);

    /**
     * @notice Get the progress of clearing active accounts.
     *         Return the number of total active accounts and the number of active accounts not cleared
     * @param perpetualIndex The index of the perpetual in the liquidity pool
     * @return left The left active accounts
     * @return total The total active accounts
     */
    function getClearProgress(uint256 perpetualIndex)
        external
        view
        returns (uint256 left, uint256 total);

    /**
     * @notice Get the pool margin of the liquidity pool.
     *         Pool margin is how much collateral of the pool considering the AMM's positions of perpetuals
     * @return poolMargin The pool margin of the liquidity pool
     */
    function getPoolMargin() external view returns (int256 poolMargin, bool isSafe);

    /**
     * @notice  Query the price, fees and cost when trade agaist amm.
     *          The trading price is determined by the AMM based on the index price of the perpetual.
     *          This method should returns the same result as a 'read-only' trade.
     *          WARN: the result of this function is base on current storage of liquidityPool, not the latest.
     *          To get the latest status, call `syncState` first.
     *
     *          Flags is a 32 bit uint value which indicates: (from highest bit)
     *            - close only      only close position during trading;
     *            - market order    do not check limit price during trading;
     *            - stop loss       only available in brokerTrade mode;
     *            - take profit     only available in brokerTrade mode;
     *          For stop loss and take profit, see `validateTriggerPrice` in OrderModule.sol for details.
     *
     * @param   perpetualIndex  The index of the perpetual in liquidity pool.
     * @param   trader          The address of trader.
     * @param   amount          The amount of position to trader, positive for buying and negative for selling. The amount always use decimals 18.
     * @param   referrer        The address of referrer who will get rebate from the deal.
     * @param   flags           The flags of the trade.
     * @return  tradePrice      The average fill price.
     * @return  totalFee        The total fee collected from the trader after the trade.
     * @return  cost            Deposit or withdraw to let effective leverage == targetLeverage if flags contain USE_TARGET_LEVERAGE. > 0 if deposit, < 0 if withdraw.
     */
    function queryTrade(
        uint256 perpetualIndex,
        address trader,
        int256 amount,
        address referrer,
        uint32 flags
    )
        external
        returns (
            int256 tradePrice,
            int256 totalFee,
            int256 cost
        );

    /**
     * @notice  Query cash to add / share to mint when adding liquidity to the liquidity pool.
     *          Only one of cashToAdd or shareToMint may be non-zero.
     *
     * @param   cashToAdd         The amount of cash to add, always use decimals 18.
     * @param   shareToMint       The amount of share token to mint, always use decimals 18.
     * @return  cashToAddResult   The amount of cash to add, always use decimals 18. Equal to cashToAdd if cashToAdd is non-zero.
     * @return  shareToMintResult The amount of cash to add, always use decimals 18. Equal to shareToMint if shareToMint is non-zero.
     */
    function queryAddLiquidity(int256 cashToAdd, int256 shareToMint)
        external
        view
        returns (int256 cashToAddResult, int256 shareToMintResult);

    /**
     * @notice  Query cash to return / share to redeem when removing liquidity from the liquidity pool.
     *          Only one of shareToRemove or cashToReturn may be non-zero.
     *          Can only called when the pool is running.
     *
     * @param   shareToRemove       The amount of share token to redeem, always use decimals 18.
     * @param   cashToReturn        The amount of cash to return, always use decimals 18.
     * @return  shareToRemoveResult The amount of share token to redeem, always use decimals 18. Equal to shareToRemove if shareToRemove is non-zero.
     * @return  cashToReturnResult  The amount of cash to return, always use decimals 18. Equal to cashToReturn if cashToReturn is non-zero.
     */
    function queryRemoveLiquidity(int256 shareToRemove, int256 cashToReturn)
        external
        view
        returns (int256 shareToRemoveResult, int256 cashToReturnResult);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

import "./Constant.sol";
import "./Utils.sol";

enum Round {
    CEIL,
    FLOOR
}

library SafeMathExt {
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    /*
     * @dev Always half up for uint256
     */
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y).add(Constant.UNSIGNED_ONE / 2) / Constant.UNSIGNED_ONE;
    }

    /*
     * @dev Always half up for uint256
     */
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(Constant.UNSIGNED_ONE).add(y / 2).div(y);
    }

    /*
     * @dev Always half up for uint256
     */
    function wfrac(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256 r) {
        r = x.mul(y).add(z / 2).div(z);
    }

    /*
     * @dev Always half up if no rounding parameter
     */
    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = roundHalfUp(x.mul(y), Constant.SIGNED_ONE) / Constant.SIGNED_ONE;
    }

    /*
     * @dev Always half up if no rounding parameter
     */
    function wdiv(int256 x, int256 y) internal pure returns (int256 z) {
        if (y < 0) {
            y = neg(y);
            x = neg(x);
        }
        z = roundHalfUp(x.mul(Constant.SIGNED_ONE), y).div(y);
    }

    /*
     * @dev Always half up if no rounding parameter
     */
    function wfrac(
        int256 x,
        int256 y,
        int256 z
    ) internal pure returns (int256 r) {
        int256 t = x.mul(y);
        if (z < 0) {
            z = neg(z);
            t = neg(t);
        }
        r = roundHalfUp(t, z).div(z);
    }

    function wmul(
        int256 x,
        int256 y,
        Round round
    ) internal pure returns (int256 z) {
        z = div(x.mul(y), Constant.SIGNED_ONE, round);
    }

    function wdiv(
        int256 x,
        int256 y,
        Round round
    ) internal pure returns (int256 z) {
        z = div(x.mul(Constant.SIGNED_ONE), y, round);
    }

    function wfrac(
        int256 x,
        int256 y,
        int256 z,
        Round round
    ) internal pure returns (int256 r) {
        int256 t = x.mul(y);
        r = div(t, z, round);
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : neg(x);
    }

    function neg(int256 a) internal pure returns (int256) {
        return SignedSafeMathUpgradeable.sub(int256(0), a);
    }

    /*
     * @dev ROUND_HALF_UP rule helper.
     *      You have to call roundHalfUp(x, y) / y to finish the rounding operation.
     *      0.5 ≈ 1, 0.4 ≈ 0, -0.5 ≈ -1, -0.4 ≈ 0
     */
    function roundHalfUp(int256 x, int256 y) internal pure returns (int256) {
        require(y > 0, "roundHalfUp only supports y > 0");
        if (x >= 0) {
            return x.add(y / 2);
        }
        return x.sub(y / 2);
    }

    /*
     * @dev Division, rounding ceil or rounding floor
     */
    function div(
        int256 x,
        int256 y,
        Round round
    ) internal pure returns (int256 divResult) {
        require(y != 0, "division by zero");
        divResult = x.div(y);
        if (x % y == 0) {
            return divResult;
        }
        bool isSameSign = Utils.hasTheSameSign(x, y);
        if (round == Round.CEIL && isSameSign) {
            divResult = divResult.add(1);
        }
        if (round == Round.FLOOR && !isSameSign) {
            divResult = divResult.sub(1);
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

/**
 * @notice  Perpetual state:
 *          - INVALID:      Uninitialized or not non-existent perpetual;
 *          - INITIALIZING: Only when LiquidityPoolStorage.isRunning == false. Traders cannot perform operations;
 *          - NORMAL:       Full functional state. Traders is able to perform all operations;
 *          - EMERGENCY:    Perpetual is unsafe and only clear is available;
 *          - CLEARED:      All margin account is cleared. Trade could withdraw remaining margin balance.
 */
enum PerpetualState {
    INVALID,
    INITIALIZING,
    NORMAL,
    EMERGENCY,
    CLEARED
}
enum OrderType {
    LIMIT,
    MARKET,
    STOP
}

/**
 * @notice  Data structure to store risk parameter value.
 */
struct Option {
    int256 value;
    int256 minValue;
    int256 maxValue;
}

/**
 * @notice  Data structure to store oracle price data.
 */
struct OraclePriceData {
    int256 price;
    uint256 time;
}

/**
 * @notice  Data structure to store user margin information. See MarginAccountModule.sol for details.
 */
struct MarginAccount {
    int256 cash;
    int256 position;
    int256 targetLeverage;
}

/**
 * @notice  Data structure of an order object.
 */
struct Order {
    address trader;
    address broker;
    address relayer;
    address referrer;
    address liquidityPool;
    int256 minTradeAmount;
    int256 amount;
    int256 limitPrice;
    int256 triggerPrice;
    uint256 chainID;
    uint64 expiredAt;
    uint32 perpetualIndex;
    uint32 brokerFeeLimit;
    uint32 flags;
    uint32 salt;
}

/**
 * @notice  Core data structure, a core .
 */
struct LiquidityPoolStorage {
    bool isRunning;
    bool isFastCreationEnabled;
    // addresses
    address creator;
    address operator;
    address transferringOperator;
    address governor;
    address shareToken;
    address accessController;
    bool reserved3; // isWrapped
    uint256 scaler;
    uint256 collateralDecimals;
    address collateralToken;
    // pool attributes
    int256 poolCash;
    uint256 fundingTime;
    uint256 reserved5;
    uint256 operatorExpiration;
    mapping(address => int256) reserved1;
    bytes32[] reserved2;
    // perpetuals
    uint256 perpetualCount;
    mapping(uint256 => PerpetualStorage) perpetuals;
    // insurance fund
    int256 insuranceFundCap;
    int256 insuranceFund;
    int256 donatedInsuranceFund;
    address reserved4;
    uint256 liquidityCap;
    uint256 shareTransferDelay;
    // reserved slot for future upgrade
    bytes32[14] reserved;
}

/**
 * @notice  Core data structure, storing perpetual information.
 */
struct PerpetualStorage {
    uint256 id;
    PerpetualState state;
    address oracle;
    int256 totalCollateral;
    int256 openInterest;
    // prices
    OraclePriceData indexPriceData;
    OraclePriceData markPriceData;
    OraclePriceData settlementPriceData;
    // funding state
    int256 fundingRate;
    int256 unitAccumulativeFunding;
    // base parameters
    int256 initialMarginRate;
    int256 maintenanceMarginRate;
    int256 operatorFeeRate;
    int256 lpFeeRate;
    int256 referralRebateRate;
    int256 liquidationPenaltyRate;
    int256 keeperGasReward;
    int256 insuranceFundRate;
    int256 reserved1;
    int256 maxOpenInterestRate;
    // risk parameters
    Option halfSpread;
    Option openSlippageFactor;
    Option closeSlippageFactor;
    Option fundingRateLimit;
    Option fundingRateFactor;
    Option ammMaxLeverage;
    Option maxClosePriceDiscount;
    // users
    uint256 totalAccount;
    int256 totalMarginWithoutPosition;
    int256 totalMarginWithPosition;
    int256 redemptionRateWithoutPosition;
    int256 redemptionRateWithPosition;
    EnumerableSetUpgradeable.AddressSet activeAccounts;
    // insurance fund
    int256 reserved2;
    int256 reserved3;
    // accounts
    mapping(address => MarginAccount) marginAccounts;
    Option defaultTargetLeverage;
    // keeper
    address reserved4;
    EnumerableSetUpgradeable.AddressSet ammKeepers;
    EnumerableSetUpgradeable.AddressSet reserved5;
    Option baseFundingRate;
    // reserved slot for future upgrade
    bytes32[9] reserved;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

library Constant {
    address internal constant INVALID_ADDRESS = address(0);

    int256 internal constant SIGNED_ONE = 10**18;
    uint256 internal constant UNSIGNED_ONE = 10**18;

    uint256 internal constant PRIVILEGE_DEPOSIT = 0x1;
    uint256 internal constant PRIVILEGE_WITHDRAW = 0x2;
    uint256 internal constant PRIVILEGE_TRADE = 0x4;
    uint256 internal constant PRIVILEGE_LIQUIDATE = 0x8;
    uint256 internal constant PRIVILEGE_GUARD =
        PRIVILEGE_DEPOSIT | PRIVILEGE_WITHDRAW | PRIVILEGE_TRADE | PRIVILEGE_LIQUIDATE;
    // max number of uint256
    uint256 internal constant SET_ALL_PERPETUALS_TO_EMERGENCY_STATE =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./SafeMathExt.sol";

library Utils {
    using SafeMathExt for int256;
    using SafeMathExt for uint256;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    /*
     * @dev Check if two numbers have the same sign. Zero has the same sign with any number
     */
    function hasTheSameSign(int256 x, int256 y) internal pure returns (bool) {
        if (x == 0 || y == 0) {
            return true;
        }
        return (x ^ y) >> 255 == 0;
    }

    /**
     * @dev     Check if the trader has opened position in the trade.
     *          Example: 2, 1 => true; 2, -1 => false; -2, -3 => true
     * @param   amount  The position of the trader after the trade
     * @param   delta   The update position amount of the trader after the trade
     * @return  True if the trader has opened position in the trade
     */
    function hasOpenedPosition(int256 amount, int256 delta) internal pure returns (bool) {
        if (amount == 0) {
            return false;
        }
        return Utils.hasTheSameSign(amount, delta);
    }

    /*
     * @dev Split the delta to two numbers.
     *      Use for splitting the trading amount to the amount to close position and the amount to open position.
     *      Examples: 2, 1 => 0, 1; 2, -1 => -1, 0; 2, -3 => -2, -1
     */
    function splitAmount(int256 amount, int256 delta) internal pure returns (int256, int256) {
        if (Utils.hasTheSameSign(amount, delta)) {
            return (0, delta);
        } else if (amount.abs() >= delta.abs()) {
            return (delta, 0);
        } else {
            return (amount.neg(), amount.add(delta));
        }
    }

    /*
     * @dev Check if amount will be away from zero or cross zero if added the delta.
     *      Use for checking if trading amount will make trader open position.
     *      Example: 2, 1 => true; 2, -1 => false; 2, -3 => true
     */
    function isOpen(int256 amount, int256 delta) internal pure returns (bool) {
        return Utils.hasTheSameSign(amount, delta) || amount.abs() < delta.abs();
    }

    /*
     * @dev Get the id of the current chain
     */
    function chainID() internal pure returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    // function toArray(
    //     EnumerableSet.AddressSet storage set,
    //     uint256 begin,
    //     uint256 end
    // ) internal view returns (address[] memory result) {
    //     require(end > begin, "begin should be lower than end");
    //     uint256 length = set.length();
    //     if (begin >= length) {
    //         return result;
    //     }
    //     uint256 safeEnd = end.min(length);
    //     result = new address[](safeEnd.sub(begin));
    //     for (uint256 i = begin; i < safeEnd; i++) {
    //         result[i.sub(begin)] = set.at(i);
    //     }
    //     return result;
    // }

    function toArray(
        EnumerableSetUpgradeable.AddressSet storage set,
        uint256 begin,
        uint256 end
    ) internal view returns (address[] memory result) {
        require(end > begin, "begin should be lower than end");
        uint256 length = set.length();
        if (begin >= length) {
            return result;
        }
        uint256 safeEnd = end.min(length);
        result = new address[](safeEnd.sub(begin));
        for (uint256 i = begin; i < safeEnd; i++) {
            result[i.sub(begin)] = set.at(i);
        }
        return result;
    }

    function toArray(
        EnumerableSetUpgradeable.Bytes32Set storage set,
        uint256 begin,
        uint256 end
    ) internal view returns (bytes32[] memory result) {
        require(end > begin, "begin should be lower than end");
        uint256 length = set.length();
        if (begin >= length) {
            return result;
        }
        uint256 safeEnd = end.min(length);
        result = new bytes32[](safeEnd.sub(begin));
        for (uint256 i = begin; i < safeEnd; i++) {
            result[i.sub(begin)] = set.at(i);
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}