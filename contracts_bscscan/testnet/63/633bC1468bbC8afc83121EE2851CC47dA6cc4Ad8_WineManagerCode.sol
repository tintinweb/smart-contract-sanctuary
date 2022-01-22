// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./WineManagerParts/AccessControlIntegration.sol";
import "./WineManagerParts/FactoryIntegration.sol";
import "./WineManagerParts/FirstSaleMarketIntegration.sol";
import "./WineManagerParts/MarketPlaceIntegration.sol";
import "./WineManagerParts/DeliveryServiceIntegration.sol";
import "./interfaces/IWineManagerPoolIntegration.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract WineManagerCode is
    Initializable,
    AccessControlIntegration,
    FactoryIntegration,
    FirstSaleMarketIntegration,
    MarketPlaceIntegration,
    DeliveryServiceIntegration,
    IWineManagerPoolIntegration
{

    function initialize(
        address owner_,
        address proxyAdmin_,
        address winePoolCode_,
        address wineFactoryCode_,
        address wineFirstSaleMarketCode_,
        address wineMarketPlaceCode_,
        address wineDeliveryServiceCode_,
        string memory baseUri_,
        string memory baseSymbol_,
        address firstSaleCurrency_,
        address[] memory allowedCurrencies_,
        uint256 orderFeeInPromille_
    )
        public
        initializer
    {
        _initializeAccessControlIntegration(owner_);
        _initializeFactory(
            proxyAdmin_,
            winePoolCode_,
            wineFactoryCode_,
            baseUri_,
            baseSymbol_
        );
        _initializeFirstSaleMarket(
            proxyAdmin_,
            wineFirstSaleMarketCode_,
            firstSaleCurrency_
        );
        _initializeMarketPlace(
            proxyAdmin_,
            wineMarketPlaceCode_,
            allowedCurrencies_,
            orderFeeInPromille_
        );
        _initializeDeliveryService(
            proxyAdmin_,
            wineDeliveryServiceCode_
        );
        _initializeAllowance();
    }

//////////////////////////////////////// IWineManagerPoolIntegration

    mapping (address => bool) public override allowMint;
    mapping (address => bool) public override allowInternalTransfers;
    mapping (address => bool) public override allowBurn;

    function _initializeAllowance()
        internal
    {
        allowMint[address(this)] = true;
        allowMint[firstSaleMarket] = true;
        allowInternalTransfers[address(this)] = true;
        allowInternalTransfers[deliveryService] = true;
        allowBurn[deliveryService] = true;
    }

//////////////////////////////////////// FactoryIntegration

    function createWinePool(
        string memory name_,

        uint256 maxTotalSupply_,
        uint256 winePrice_,

        string memory wineName_,
        string memory wineProductionCountry_,
        string memory wineProductionRegion_,
        string memory wineProductionYear_,
        string memory wineProducerName_,
        string memory wineBottleVolume_,
        string memory linkToDocuments_
    )
        public
        onlyRole(FACTORY_MANAGER_ROLE)
        returns (address)
    {
        return _createWinePool(
            name_,

            maxTotalSupply_,
            winePrice_,

            wineName_,
            wineProductionCountry_,
            wineProductionRegion_,
            wineProductionYear_,
            wineProducerName_,
            wineBottleVolume_,
            linkToDocuments_
        );
    }

    function disablePool(uint256 poolId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IWineFactory(factory).disablePool(poolId);
    }

    function updateAllDescriptionFields(
        uint256 poolId,

        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    )
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).updateAllDescriptionFields(
            wineName,
            wineProductionCountry,
            wineProductionRegion,
            wineProductionYear,
            wineProducerName,
            wineBottleVolume,
            linkToDocuments
        );
    }

    function editDescriptionField(uint256 poolId, bytes32 param, string memory value)
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).editDescriptionField(param, value);
    }

    function editWinePoolMaxTotalSupply(uint256 poolId, uint256 value)
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).editMaxTotalSupply(value);
    }

    function editWinePoolWinePrice(uint256 poolId, uint256 value)
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).editWinePrice(value);
    }

    function transferInternalToInternal(uint256 poolId, address internalFrom, address internalTo, uint256 tokenId)
        public
        onlyRole(SYSTEM_ROLE)
    {
        getPoolAsContract(poolId).transferInternalToInternal(internalFrom, internalTo, tokenId);
    }

    function transferInternalToOuter(uint256 poolId, address internalFrom, address outerTo, uint256 tokenId)
        public
        onlyRole(SYSTEM_ROLE)
    {
        getPoolAsContract(poolId).transferInternalToOuter(internalFrom, outerTo, tokenId);
    }

//////////////////////////////////////// FirstSaleMarketIntegration - Treasury

    function editFirstSaleCurrency(
        address firstSaleCurrency_
    )
        public
        onlyRole(FIRST_SALE_MARKET_MANAGER_ROLE)
    {
        IWineFirstSaleMarket(firstSaleMarket)._editFirstSaleCurrency(firstSaleCurrency_);
    }

    function firstSaleMarketTreasuryGetBalance(address currency)
        public
        view
        onlyRole(FIRST_SALE_MARKET_MANAGER_ROLE)
        returns (uint256)
    {
        return IWineFirstSaleMarket(firstSaleMarket)._treasuryGetBalance(currency);
    }

    function firstSaleMarketWithdrawFromTreasury(address currency, uint256 amount, address to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IWineFirstSaleMarket(firstSaleMarket)._withdrawFromTreasury(currency, amount, to);
    }

//////////////////////////////////////// FirstSaleMarketIntegration - Token

    function firstSaleSetBottle(uint256 poolId, address internalUser)
        public
        onlyRole(SYSTEM_ROLE)
        returns (uint256)
    {
        return getPoolAsContract(poolId).mintToInternalUser(internalUser);
    }

//////////////////////////////////////// WineMarketPlace - Settings

    function marketPlaceEditAllowedCurrency(address currency_, bool value)
        public
        onlyRole(MARKET_PLACE_MANAGER_ROLE)
    {
        IWineMarketPlace(marketPlace)._editAllowedCurrency(currency_, value);
    }

    function marketPlaceEditOrderFeeInPromille(uint256 orderFeeInPromille_)
        public
        onlyRole(MARKET_PLACE_MANAGER_ROLE)
    {
        IWineMarketPlace(marketPlace)._editOrderFeeInPromille(orderFeeInPromille_);
    }

//////////////////////////////////////// WineMarketPlace - Owner

    function marketPlaceWithdrawFee(address currencyAddress, address to, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IWineMarketPlace(marketPlace).withdrawFee(currencyAddress, to, amount);
    }


//////////////////////////////////////// DeliverySettings

    function deliveryServiceEditPoolDateBeginOfDelivery(uint256 poolId, uint256 dateBegin)
        public
        onlyRole(DELIVERY_SETTINGS_MANAGER_ROLE)
    {
        IWineDeliveryService(deliveryService)._editPoolDateBeginOfDelivery(poolId, dateBegin);
    }

//////////////////////////////////////// DeliveryTasks view methods

    function deliveryServiceShowSingleDeliveryTask(uint256 deliveryTaskId)
        public view
        onlyRole(DELIVERY_SUPPORT_ROLE)
        returns (IWineDeliveryService.DeliveryTask memory)
    {
        return IWineDeliveryService(deliveryService).showSingleDeliveryTask(deliveryTaskId);
    }

    function deliveryServiceShowLastDeliveryTask(uint256 poolId, uint256 tokenId)
        public view
        onlyRole(DELIVERY_SUPPORT_ROLE)
        returns (IWineDeliveryService.DeliveryTask memory)
    {
        return IWineDeliveryService(deliveryService).showLastDeliveryTask(poolId, tokenId);
    }

    function deliveryServiceShowFullHistory(uint256 poolId, uint256 tokenId)
        public view
        onlyRole(DELIVERY_SUPPORT_ROLE)
        returns (uint256, IWineDeliveryService.DeliveryTask[] memory)
    {
        return IWineDeliveryService(deliveryService).showFullHistory(poolId, tokenId);
    }

//////////////////////////////////////// DeliveryTasks edit methods

    function deliveryServiceRequestDeliveryForInternal(uint256 poolId, uint256 tokenId, string memory deliveryData)
        public
        onlyRole(SYSTEM_ROLE)
        returns (uint256 deliveryTaskId)
    {
        return IWineDeliveryService(deliveryService).requestDeliveryForInternal(poolId, tokenId, deliveryData);
    }

    function deliveryServiceSetSupportResponse(uint256 poolId, uint256 tokenId, string memory supportResponse)
        public
        onlyRole(DELIVERY_SUPPORT_ROLE)
    {
        IWineDeliveryService(deliveryService).setSupportResponse(poolId, tokenId, supportResponse);
    }

    function deliveryServiceCancelDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse)
        public
        onlyRole(DELIVERY_SUPPORT_ROLE)
    {
        IWineDeliveryService(deliveryService).cancelDeliveryTask(poolId, tokenId, supportResponse);
    }

    function deliveryServiceFinishDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse)
        public
        onlyRole(DELIVERY_SUPPORT_ROLE)
    {
        IWineDeliveryService(deliveryService).finishDeliveryTask(poolId, tokenId, supportResponse);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IOwnable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract InitializableOwnable is Context, IOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initializeOwner(address owner_) 
        internal
    {
        _setOwner(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * see openzeppelin/contracts/access/Ownable.sol
 */
interface IOwnable {

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./InitializableOwnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * see openzeppelin/contracts/access/AccessControl.sol
 * @dev modification to add owner and allow DEFAULT_ADMIN_ROLE all actions
 */
abstract contract AccessControlExtended is
    IAccessControl,
    ERC165,
    InitializableOwnable
{

    function _initializeAccessControlExtended(address owner_)
        internal
    {
        _initializeOwner(owner_);
    }

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        override virtual
        public view
        returns (bool)
    {
        if (
            account == owner() ||
            _roles[DEFAULT_ADMIN_ROLE].members[account]
        ) {
            return true;
        }
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1967ProxyInitializable.sol";
import "./ITransparentUpgradeableProxyInitializable.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxyInitializable is
    ERC1967ProxyInitializable,
    ITransparentUpgradeableProxyInitializable
{
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    function initializeProxy(
        address _logic,
        address admin_,
        bytes memory _data
    )
        override
        public
        initializer
    {
        initializeERC1967Proxy(_logic, _data);
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin() || _initialized == false) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITransparentUpgradeableProxyInitializable
{
    function initializeProxy(
        address _logic,
        address admin_,
        bytes memory _data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";


/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967ProxyInitializable is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    function initializeERC1967Proxy(
        address _logic,
        bytes memory _data
    )
        internal
    {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWinePool.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


interface IWinePoolFull is IERC165, IERC721, IERC721Metadata, IWinePool
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWinePool
{
//////////////////////////////////////// DescriptionFields

    function updateAllDescriptionFields(
        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    ) external;
    function editDescriptionField(bytes32 param, string memory value) external;

//////////////////////////////////////// System fields

    function getPoolId() external view returns (uint256);
    function getMaxTotalSupply() external view returns (uint256);
    function getWinePrice() external view returns (uint256);

    function editMaxTotalSupply(uint256 value) external;
    function editWinePrice(uint256 value) external;

//////////////////////////////////////// Pausable

    function pause() external;
    function unpause() external;

//////////////////////////////////////// Initialize

    function initialize(
        string memory name,
        string memory symbol,

        address manager,

        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    ) external payable returns (bool);

//////////////////////////////////////// Disable

    function disabled() external view returns (bool);

    function disablePool() external;

//////////////////////////////////////// default methods

    function tokensCount() external view returns (uint256);

    function burn(uint256 tokenId) external;

    function mint(address to) external returns (uint256);

//////////////////////////////////////// internal users and tokens

    event InternalTransfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function internalUsersExists(address) external view returns (bool);
    function internalOwnedTokens(uint256) external view returns (address);

    function mintToInternalUser(address internalUser) external returns (uint256);

    function transferInternalToInternal(address internalFrom, address internalTo, uint256 tokenId) external;

    function transferOuterToInternal(address outerFrom, address internalTo, uint256 tokenId) external;

    function transferInternalToOuter(address internalFrom, address outerTo, uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineMarketPlace {

    function initialize(
        address manager_,
        address[] memory allowedCurrencies_,
        uint256 orderFeeInPromille_
    ) external;

//////////////////////////////////////// Settings

    function _editAllowedCurrency(address currency_, bool value) external;

    function _editOrderFeeInPromille(uint256 orderFeeInPromille_) external;

//////////////////////////////////////// Owner

    function withdrawFee(address currencyAddress, address to, uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerPoolIntegration {

    function allowMint(address) external view returns (bool);
    function allowInternalTransfers(address) external view returns (bool);
    function allowBurn(address) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerMarketPlaceIntegration {

    function marketPlace() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerFirstSaleMarketIntegration {

    function firstSaleMarket() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWinePoolFull.sol";

interface IWineManagerFactoryIntegration {

    function factory() external view returns (address);

    function getPoolAddress(uint256 poolId) external view returns (address);

    function getPoolAsContract(uint256 poolId) external view returns (IWinePoolFull);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerDeliveryServiceIntegration {

    function deliveryService() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineFirstSaleMarket {

    function initialize(
        address manager_,
        address firstSaleCurrency_
    ) external;

    function firstSaleCurrency() external returns(address);

//////////////////////////////////////// Treasury

    event NewFirstSaleCurrency(address indexed firstSaleCurrency);

    function _editFirstSaleCurrency(address firstSaleCurrency_) external;

    function _treasuryGetBalance(address currency) external view returns (uint256);

    function _withdrawFromTreasury(address currency, uint256 amount, address to) external;

//////////////////////////////////////// Token

    function buyToken(uint256 poolId, address newTokenOwner) external returns (uint256 tokenId);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineFactory {

    event WinePoolCreated(uint256 poolId, address winePool);

    function winePoolCode() external view returns (address);
    function baseUri() external view returns (string memory);
    function baseSymbol() external view returns (string memory);

    function initialize(
        address proxyAdmin_,
        address winePoolCode_,
        address manager_,
        string memory baseUri_,
        string memory baseSymbol_
    ) external;

    function getPool(uint256 poolId) external view returns (address);

    function allPoolsLength() external view returns (uint);

    function createWinePool(
        string memory name_,

        uint256 maxTotalSupply_,
        uint256 winePrice_
    ) external returns (address winePoolAddress);

    function disablePool(uint256 poolId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineDeliveryService {

    function initialize(
        address manager_
    ) external;

//////////////////////////////////////// DeliverySettings

    function getPoolDateBeginOfDelivery(uint256 poolId) external view returns (uint256);

    function _editPoolDateBeginOfDelivery(uint256 poolId, uint256 dateBegin) external;

//////////////////////////////////////// DeliveryTasks public methods

    enum DeliveryTaskStatus {
        New,
        Canceled,
        Executed,
        InProcess
    }

    struct DeliveryTask {
        address tokenOwner;
        bool isInternal;
        string deliveryData;
        string supportResponse;
        DeliveryTaskStatus status;
    }

    function requestDelivery(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function requestDeliveryForInternal(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function showSingleDeliveryTask(uint256 deliveryTaskId) external view returns (DeliveryTask memory);

    function showLastDeliveryTask(uint256 poolId, uint256 tokenId) external view returns (DeliveryTask memory);

    function showFullHistory(uint256 poolId, uint256 tokenId) external view returns (uint256, DeliveryTask[] memory);

    function setSupportResponse(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

    function cancelDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

    function finishDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineManagerMarketPlaceIntegration.sol";
import "../interfaces/IWineMarketPlace.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract MarketPlaceIntegration is IWineManagerMarketPlaceIntegration
{
    address public override marketPlace;

    function _initializeMarketPlace(
        address proxyAdmin_,
        address wineMarketPlaceCode_,
        address[] memory allowedCurrencies_,
        uint256 orderFeeInPromille_
    )
        internal
    {
        marketPlace = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(marketPlace).initializeProxy(wineMarketPlaceCode_, proxyAdmin_, bytes(""));
        IWineMarketPlace(marketPlace).initialize(address(this), allowedCurrencies_, orderFeeInPromille_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineManagerFirstSaleMarketIntegration.sol";
import "../interfaces/IWineFirstSaleMarket.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract FirstSaleMarketIntegration is IWineManagerFirstSaleMarketIntegration
{
    address public override firstSaleMarket;

    function _initializeFirstSaleMarket(
        address proxyAdmin_,
        address wineFirstSaleMarketCode_,
        address firstSaleCurrency_
    )
        internal
    {
        firstSaleMarket = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(firstSaleMarket).initializeProxy(wineFirstSaleMarketCode_, proxyAdmin_, bytes(""));
        IWineFirstSaleMarket(firstSaleMarket).initialize(address(this), firstSaleCurrency_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineFactory.sol";
import "../interfaces/IWinePoolFull.sol";
import "../interfaces/IWineManagerFactoryIntegration.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract FactoryIntegration is IWineManagerFactoryIntegration
{
    address public override factory;

    function _initializeFactory(
        address proxyAdmin_,
        address winePoolCode_,
        address wineFactoryCode_,
        string memory baseUri_,
        string memory baseSymbol_
    )
        internal
    {
        factory = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(factory).initializeProxy(wineFactoryCode_, proxyAdmin_, bytes(""));
        IWineFactory(factory).initialize(proxyAdmin_, winePoolCode_, address(this), baseUri_, baseSymbol_);
    }

    function _createWinePool(
        string memory name_,

        uint256 maxTotalSupply_,
        uint256 winePrice_,

        string memory wineName_,
        string memory wineProductionCountry_,
        string memory wineProductionRegion_,
        string memory wineProductionYear_,
        string memory wineProducerName_,
        string memory wineBottleVolume_,
        string memory linkToDocuments_
    )
        internal
        returns (address)
    {
        (address winePoolAddress) = IWineFactory(factory).createWinePool(
            name_,

            maxTotalSupply_,
            winePrice_
        );
        IWinePoolFull(winePoolAddress).updateAllDescriptionFields(
            wineName_,
            wineProductionCountry_,
            wineProductionRegion_,
            wineProductionYear_,
            wineProducerName_,
            wineBottleVolume_,
            linkToDocuments_
        );
        return winePoolAddress;
    }

    function getPoolAddress(uint256 poolId)
        override
        public view
        returns (address)
    {
        return IWineFactory(factory).getPool(poolId);
    }

    function getPoolAsContract(uint256 poolId)
        override
        public view
        returns (IWinePoolFull)
    {
        return IWinePoolFull(getPoolAddress(poolId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineDeliveryService.sol";
import "../interfaces/IWineManagerDeliveryServiceIntegration.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract DeliveryServiceIntegration is IWineManagerDeliveryServiceIntegration
{
    address public override deliveryService;

    function _initializeDeliveryService(
        address proxyAdmin_,
        address wineDeliveryServiceCode_
    )
        internal
    {
        deliveryService = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(deliveryService).initializeProxy(wineDeliveryServiceCode_, proxyAdmin_, bytes(""));
        IWineDeliveryService(deliveryService).initialize(address(this));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../vendors/access/AccessControlExtended.sol";

abstract contract AccessControlIntegration is AccessControlExtended {

    function _initializeAccessControlIntegration(address owner_)
        internal
    {
        _initializeAccessControlExtended(owner_);
    }

    bytes32 internal constant  SYSTEM_ROLE = "SYSTEM_ROLE";
    bytes32 internal constant  FACTORY_MANAGER_ROLE = "FACTORY_MANAGER_ROLE";
    bytes32 internal constant  FIRST_SALE_MARKET_MANAGER_ROLE = "FIRST_SALE_MARKET_MANAGER_ROLE";
    bytes32 internal constant  MARKET_PLACE_MANAGER_ROLE = "MARKET_PLACE_MANAGER_ROLE";
    bytes32 internal constant  DELIVERY_SETTINGS_MANAGER_ROLE = "DELIVERY_SETTINGS_MANAGER_ROLE";
    bytes32 internal constant  DELIVERY_SUPPORT_ROLE = "DELIVERY_SUPPORT_ROLE";


    function addAdmin(address _address)
        public
    {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function removeAdmin(address _address)
        public
    {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function addSystem(address _address)
        public
    {
        grantRole(SYSTEM_ROLE, _address);
    }

    function removeSystem(address _address)
        public
    {
        revokeRole(SYSTEM_ROLE, _address);
    }

    function addFactoryManager(address _address)
        public
    {
        grantRole(FACTORY_MANAGER_ROLE, _address);
    }

    function removeFactoryManager(address _address)
        public
    {
        revokeRole(FACTORY_MANAGER_ROLE, _address);
    }

    function addFirstSaleMarketManager(address _address)
        public
    {
        grantRole(FIRST_SALE_MARKET_MANAGER_ROLE, _address);
    }

    function removeFirstSaleMarketManager(address _address)
        public
    {
        revokeRole(FIRST_SALE_MARKET_MANAGER_ROLE, _address);
    }

    function addMarketPlaceManager(address _address)
        public
    {
        grantRole(MARKET_PLACE_MANAGER_ROLE, _address);
    }

    function removeMarketPlaceManager(address _address)
        public
    {
        revokeRole(MARKET_PLACE_MANAGER_ROLE, _address);
    }

    function addDeliverySettingsManager(address _address)
        public
    {
        grantRole(DELIVERY_SETTINGS_MANAGER_ROLE, _address);
    }

    function removeDeliverySettingsManager(address _address)
        public
    {
        revokeRole(DELIVERY_SETTINGS_MANAGER_ROLE, _address);
    }

    function addDeliverySupport(address _address)
        public
    {
        grantRole(DELIVERY_SUPPORT_ROLE, _address);
    }

    function removeDeliverySupport(address _address)
        public
    {
        revokeRole(DELIVERY_SUPPORT_ROLE, _address);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
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
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}