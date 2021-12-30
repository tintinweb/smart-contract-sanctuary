// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./abstract/AdminAndTangibleAccess.sol";
import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITangiblePriceManager.sol";
import "./interfaces/ITangibleNFTDeployer.sol";
import "./interfaces/IPriceOracle.sol";

contract Factory is AdminAndTangibleAccess, IFactory {
    using SafeERC20 for IERC20;

    IERC20 public immutable override USDC;
    address public override feeStorageAddress;
    address public override marketplace;
    address public override deployer;

    struct Vendor {
        uint128 vendorId;
        address[] categories;
    }

    mapping(string => ITangibleNFT) public override category;
    mapping(address => Vendor) public approvedVendor;

    address[] private vendors;

    ITangibleNFT[] private _tnfts;
    ITangiblePriceManager public override priceManager;

    uint128 public _lastVendorId = 0;
    //to be used in contract upgrades
    uint128 public immutable version = 0;

    /// @dev Restricted to members of the admin role.
    constructor(
        address _usdc,
        address _feeStorageAddress,
        address _priceManager
    ) {
        require(_feeStorageAddress != address(0), "FESZ");
        require(_usdc != address(0), "UZ");
        require(_priceManager != address(0), "ZPM");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VENDOR_ROLE, msg.sender);
        _setupRole(STORAGE_OPERATOR_ROLE, msg.sender);
        // maybe add to marketplace role also?
        // adding Id for admin-vendor
        address[] memory empty;
        approvedVendor[msg.sender] = Vendor({
            vendorId: ++_lastVendorId,
            categories: empty
        });
        vendors.push(msg.sender);

        USDC = IERC20(_usdc);

        feeStorageAddress = _feeStorageAddress;
        priceManager = ITangiblePriceManager(_priceManager);
        emit FeeStorageAddressSet(address(0), _feeStorageAddress);
        emit PriceManagerSet(address(0), _priceManager);
        emit ApprovedVendor(msg.sender, true);
    }

    /// @notice Sets the feeStorageAddress
    /// @dev Will emit FeeStorageAddressSet on change.
    /// @param _feeStorageAddress A new address for fee storage.
    function setFeeStorageAddress(address _feeStorageAddress)
        external
        onlyAdmin
    {
        require(_feeStorageAddress != address(0), "ZFSA");
        if (feeStorageAddress != _feeStorageAddress) {
            emit FeeStorageAddressSet(feeStorageAddress, _feeStorageAddress);
            feeStorageAddress = _feeStorageAddress;
        }
    }

    /// @notice Sets the priceManager
    /// @dev Will emit PriceManagerSet on change.
    /// @param _priceManager A new address for priceManager.
    function setPriceManager(address _priceManager) external onlyAdmin {
        require(_priceManager != address(0), "ZFSA");
        if (address(priceManager) != _priceManager) {
            emit PriceManagerSet(address(priceManager), _priceManager);
            priceManager = ITangiblePriceManager(_priceManager);
        }
    }

    /// @notice Sets the IMarketplace address
    /// @dev Will emit MarketplaceAddressSet on change.
    /// @param _marketplace A new address of the Marketplace
    function setMarketplace(address _marketplace) external onlyAdmin {
        require(_marketplace != address(0), "ZMA");
        if (marketplace != _marketplace) {
            emit MarketplaceAddressSet(marketplace, _marketplace);
            marketplace = _marketplace;
            grantRole(MARKETPLACE_ROLE, marketplace);
        }
    }

    /// @notice Sets the ITangibleNFTDeployer address
    /// @dev Will emit DeployerAddressSet on change.
    /// @param _deployer new address of the TangibleNFTDeployer
    function setDeployer(address _deployer) external onlyAdmin {
        require(
            (_deployer != address(0x0)) && (_deployer != address(deployer)),
            "Wrong deployer"
        );

        emit DeployerAddressSet(address(deployer), _deployer);
        deployer = _deployer;
    }

    function getApprovedVendorInfo(address vendor)
        external
        view
        returns (Vendor memory)
    {
        return approvedVendor[vendor];
    }

    function getCategories() external view returns (ITangibleNFT[] memory) {
        return _tnfts;
    }

    /// @inheritdoc IFactory
    function isFactoryOperator(address operator)
        external
        view
        override
        returns (bool)
    {
        return isStorageOperator(operator);
    }

    /// @inheritdoc IFactory
    function isFactoryAdmin(address admin)
        external
        view
        override
        returns (bool)
    {
        return isAdmin(admin);
    }

    function adjustStorageAndGetAmount(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external override onlyMarketplace returns (uint256) {
        return tnft.adjustStorageAndGetAmount(tokenId, _years, tokenPrice);
    }

    /// @notice Mints the TangibleNFT token from the given MintVoucher
    /// @dev Will revert if the signature is invalid.
    /// @param voucher An MintVoucher describing an unminted TangibleNFT.
    function mint(MintVoucher calldata voucher)
        external
        override
        onlyVendorOrMarketplace
        returns (uint256[] memory)
    {
        // make sure signature is valid and get the address of the vendor
        require(marketplace != address(0), "MZ");
        //make sure that vendor(who is not admin nor marketplace) is minting just for himself
        if (!isAdmin(msg.sender) && !isMarketplace(msg.sender)) {
            require(voucher.vendor == msg.sender, "MFSE");
        } else if (isMarketplace(msg.sender)) {
            require(voucher.buyer != address(0), "BMNBZ");
        }

        // first assign the token to the vendor, to establish provenance on-chain
        uint256 mintCount = isMarketplace(msg.sender) ? 1 : voucher.mintCount;

        uint256[] memory tokenIds = voucher.token.produceMultipleTNFTtoStock(
            approvedVendor[voucher.vendor].vendorId,
            mintCount,
            voucher.vendor,
            voucher.brand
        );
        emit MintedTokens(address(voucher.token), tokenIds);

        // send minted tokens to marketplace. when price is 0 - use oracle
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            IERC721(voucher.token).safeTransferFrom(
                voucher.vendor,
                marketplace,
                tokenIds[i],
                abi.encode(voucher.price)
            );
        }

        //set Vendor struct
        if (
            !_hasVendorMintedInCategory(voucher.vendor, address(voucher.token))
        ) {
            //push to array
            approvedVendor[voucher.vendor].categories.push(
                address(voucher.token)
            );
        }

        return tokenIds;
    }

    /// @notice Burns the TangibleNFT token from the given BurnVoucher
    /// @dev Will revert if the signature is invalid.
    /// @param voucher An BurnVoucher describing an minted TangibleNFT.
    function burn(BurnVoucher calldata voucher)
        external
        override
        onlyStorageOperator
    {
        // need to add some checks for revert
        voucher.token.destroyTNFTs(voucher.tokenIds, msg.sender);
    }

    function getVendors() external view override returns (address[] memory) {
        return vendors;
    }

    function approveBrandForTnft(ITangibleNFT nft, string calldata brand)
        external
        override
        onlyAdmin
    {
        nft.addApprovedBrand(brand);
    }

    function newCategory(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount,
        address priceOracle
    ) external override onlyAdmin returns (ITangibleNFT) {
        require(address(category[name]) == address(0), "CE");
        require(deployer != address(0), "Deployer zero");

        ITangibleNFT tangibleNFT = ITangibleNFTDeployer(deployer).deployTnft(
            msg.sender,
            name,
            symbol,
            uri,
            isStoragePriceFixedAmount
        );
        category[name] = tangibleNFT;
        _tnfts.push(tangibleNFT);

        //set the oracle
        ITangiblePriceManager(priceManager).setOracleForCategory(
            tangibleNFT,
            IPriceOracle(priceOracle)
        );

        emit NewCategoryDeployed(address(tangibleNFT));
        return tangibleNFT;
    }

    function approveVendor(address vendor, bool approved) external onlyAdmin {
        if ((approvedVendor[vendor].vendorId == 0) && approved) {
            //new vendor set new struct
            address[] memory empty;
            approvedVendor[vendor] = Vendor({
                vendorId: ++_lastVendorId,
                categories: empty
            });
            vendors.push(vendor);
        }

        approved
            ? grantRole(VENDOR_ROLE, vendor)
            : revokeRole(VENDOR_ROLE, vendor);
        emit ApprovedVendor(vendor, approved);
    }

    function approveStorageOperator(address storageOperator, bool approved)
        external
        onlyAdmin
    {
        approved
            ? grantRole(STORAGE_OPERATOR_ROLE, storageOperator)
            : revokeRole(STORAGE_OPERATOR_ROLE, storageOperator);
        emit ApprovedStorageOperator(storageOperator, approved);
    }

    function _hasVendorMintedInCategory(address vendor, address _category)
        internal
        view
        returns (bool)
    {
        Vendor memory v = approvedVendor[vendor];
        uint256 vendorCategoriesLength = v.categories.length;
        for (uint256 i = 0; i < vendorCategoriesLength; i++) {
            if (v.categories[i] == _category) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./AdminAccess.sol";

abstract contract AdminAndTangibleAccess is AdminAccess {
    bytes32 public constant VENDOR_ROLE = keccak256("VENDOR");
    bytes32 public constant STORAGE_OPERATOR_ROLE =
        keccak256("STORAGE_OPERATOR");
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE");

    /// @dev Restricted to members of the vendor role.
    modifier onlyVendorOrMarketplace() {
        require(isVendor(msg.sender) || isMarketplace(msg.sender), "NVMR");
        _;
    }

    /// @dev Return `true` if the account belongs to the vendor role.
    function isVendor(address account) internal view returns (bool) {
        return hasRole(VENDOR_ROLE, account);
    }

    /// @dev Restricted to members of the storage operator role.
    modifier onlyStorageOperator() {
        require(isStorageOperator(msg.sender), "NSOR");
        _;
    }

    /// @dev Return `true` if the account belongs to the storage operator role.
    function isStorageOperator(address account) internal view returns (bool) {
        return hasRole(STORAGE_OPERATOR_ROLE, account);
    }

    /// @dev Restricted to members of the marketplace role.
    modifier onlyMarketplace() {
        require(isMarketplace(msg.sender), "NMR!");
        _;
    }

    /// @dev Return `true` if the account belongs to the marketplace role.
    function isMarketplace(address account) internal view returns (bool) {
        return hasRole(MARKETPLACE_ROLE, account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./IVoucher.sol";
import "./ITangiblePriceManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IFactory interface defines the interface of the Factory which creates NFTs.
interface IFactory is IVoucher {
    event FeeStorageAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event PriceManagerSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event DeployerAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event MarketplaceAddressSet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event MintedTokens(address indexed nft, uint256[] tokenIds);
    event ApprovedVendor(address vendorId, bool approved);
    event ApprovedStorageOperator(address storageOperatorId, bool approved);
    event NewCategoryDeployed(address tnftCategory);

    /// @dev The function which does lazy minting.
    function mint(MintVoucher calldata voucher)
        external
        returns (uint256[] memory);

    /// @dev The function lazy-burns tokens.
    function burn(BurnVoucher calldata voucher) external;

    /// @dev The function returns the address of the fee storage.
    function feeStorageAddress() external view returns (address);

    /// @dev The function returns the address of the marketplace.
    function marketplace() external view returns (address);

    /// @dev The function returns the address of the tnft deployer.
    function deployer() external view returns (address);

    /// @dev The function returns the address of the priceManager.
    function priceManager() external view returns (ITangiblePriceManager);

    /// @dev The function returns the address of the USDC token.
    function USDC() external view returns (IERC20);

    /// @dev The function creates new category and returns an address of newly created contract.
    function newCategory(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount,
        address priceOracle
    ) external returns (ITangibleNFT);

    /// @dev The function returns an address of category NFT.
    function category(string calldata name)
        external
        view
        returns (ITangibleNFT);

    /// @dev The function returns if address is operator in Factory
    function isFactoryOperator(address operator) external view returns (bool);

    /// @dev The function returns if address is vendor in Factory
    function isFactoryAdmin(address admin) external view returns (bool);

    /// @dev The function pays for storage, called only by marketplace
    function adjustStorageAndGetAmount(
        ITangibleNFT tnft,
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external returns (uint256);

    //return list of all vendors
    function getVendors() external view returns (address[] memory);

    //adds brand to the provided nft
    function approveBrandForTnft(ITangibleNFT nft, string calldata brand)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";
import "./IPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ITangiblePriceManager interface gives prices for categories added in TangiblePriceManager.
interface ITangiblePriceManager {
    event CategoryPriceOracleAdded(
        address indexed category,
        address indexed priceOracle
    );

    /// @dev The function returns contract oracle for category.
    function getPriceOracleForCategory(ITangibleNFT category)
        external
        view
        returns (IPriceOracle);

    /// @dev The function returns current price from oracle for provided category.
    function setOracleForCategory(ITangibleNFT category, IPriceOracle oracle)
        external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";

interface ITangibleNFTDeployer {
    event SetFactoryDeployer(
        address indexed oldFactory,
        address indexed newFactory
    );

    function deployTnft(
        address admin,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isStoragePriceFixedAmount
    ) external returns (ITangibleNFT);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITangibleNFT.sol";

/// @title ITangiblePriceManager interface gives prices for categories added in TangiblePriceManager.
interface IPriceOracle {
    /// @dev The function latest price from oracle.
    function latestAnswer(ITangibleNFT nft) external view returns (uint256);

    /// @dev The function latest price from oracle.
    function decimals() external view returns (uint8);

    /// @dev The function latest price from oracle.
    function description() external view returns (string memory desc);

    /// @dev The function latest price from oracle.
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AdminAccess is AccessControl {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY");
    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not admin");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Restricted to members of the factory role.
    modifier onlyFactory() {
        require(isFactory(msg.sender), "Not in Factory role!");
        _;
    }

    /// @dev Return `true` if the account belongs to the factory role.
    function isFactory(address account) internal view returns (bool) {
        return hasRole(FACTORY_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the factory role or admin role.
    function isAdminOrFactory(address account) internal view returns (bool) {
        return isFactory(account) || isAdmin(account);
    }

    modifier onlyFactoryOrAdmin() {
        require(isAdminOrFactory(msg.sender), "NFAR");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./ITangibleNFT.sol";

interface IVoucher {
    /// @dev Voucher for lazy-minting
    struct MintVoucher {
        ITangibleNFT token;
        uint256 mintCount;
        uint256 price;
        address vendor;
        address buyer;
        string brand;
    }

    /// @dev Voucher for lazy-burning
    struct BurnVoucher {
        ITangibleNFT token;
        uint256[] tokenIds;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ITangibleNFT interface defines the interface of the TangibleNFT
interface ITangibleNFT is IERC721, IERC721Metadata, IERC721Enumerable {
    event StoragePricePerYearSet(uint256 oldPrice, uint256 newPrice);
    event StoragePercentagePricePerYearSet(
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event StorageFeeToPay(
        uint256 indexed tokenId,
        uint256 _years,
        uint256 amount
    );
    event ProducedTNFT(uint256 tokenId);
    event ProducedTNFTs(uint256[] tokenId);

    // /// @dev Function allows a Factory to mint tokenId for provided vendorId to the given address(stock storage, usualy marketplace).
    // function produceTNFTtoStock(uint128 vendorId, address toStock, string calldata brandName) external returns (uint256);

    /// @dev Function allows a Factory to mint multiple tokenIds for provided vendorId to the given address(stock storage, usualy marketplace)
    /// with provided count.
    function produceMultipleTNFTtoStock(
        uint128 vendorId,
        uint256 count,
        address toStock,
        string calldata brandName
    ) external returns (uint256[] memory);

    /// @dev Function that provides info of how much TNFTs has the vendor produced(minted)
    function vendorProducedTNFTs(uint128 vendorId)
        external
        view
        returns (uint256);

    /// @dev Function that provides lists all TNFTs that vendor ever produced for this category
    function listTNFTsByVendor(uint128 vendorId)
        external
        view
        returns (uint256[] memory);

    /// @dev Function allows the Factory to burn all requested token IDs.
    function destroyTNFTs(uint256[] memory tokenId, address burningFrom)
        external;

    /// @dev The function returns whether storage fee is paid for the current time.
    function isStorageFeePaid(uint256 tokenId) external view returns (bool);

    /// @dev The function returns what is the last timestamp of the paid storage.
    function storageEndTime(uint256 tokenId) external view returns (uint256);

    /// @dev The function returns the price per year for storage.
    function storagePricePerYear() external view returns (uint256);

    /// @dev The function returns the percentage of item price that is used for calculating storage.
    function storagePercentagePricePerYear() external view returns (uint256);

    /// @dev The function returns whether storage for the TNFT is paid in fixed amount or in percentage from price
    function storagePriceFixed() external view returns (bool);

    /// @dev The function accepts takes tokenId, its price and years sets storage and returns amount to pay for.
    function adjustStorageAndGetAmount(
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external returns (uint256);

    /// @dev The function sets the brand name for the token
    function setBrand(uint256 tokenId, string calldata brand) external;

    /// @dev The function approved brands for the nft
    function addApprovedBrand(string calldata brand) external;

    //returns approved brands
    function getApprovedBrands() external view returns (string[] memory);

    /// @dev The function returns the brand name for the token
    function tokenBrand(uint256 tokenId) external returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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