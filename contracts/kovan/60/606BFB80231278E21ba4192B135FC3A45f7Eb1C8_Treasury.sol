//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/Bank/ITreasury.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Comptroller.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/Bank/IComptroller.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/IValidator.sol";

// Comment this out for production, it's a debug tool
// import "hardhat/console.sol";

contract Treasury is ITreasury, AccessControl, ReentrancyGuard, IValidator {
    using SafeMath for uint256;

    // User address => fxToken address => Vault data
    mapping(address => mapping(address => Vault)) public vaults;
    mapping(address => bool) public depositors;
    address[] public depositorAddresses;

    // tokenAddress=>collateral balance held
    mapping(address => uint256) public totalBalances;

    // collateral address => interest rate
    mapping(address => uint256) public override interestRate;

    // user address => fxToken address => last update date
    mapping(address => mapping(address => uint256))
        public interestLastUpdateDate;

    // Reward tokens
    address public mintToken;

    // Comptroller
    address payable public comptroller;

    // Vault Library
    address public vaultLibrary;

    // Weth address
    address public immutable WETH;

    // Address for sending fees.
    address public override FeeRecipient;

    // Per mille fee settings
    uint256 public override mintFeePerMille;
    uint256 public override burnFeePerMille;
    uint256 public override withdrawFeePerMille;

    // Roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(
        address _comptroller,
        address _router,
        address _weth
    ) {
        comptroller = payable(_comptroller);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, _comptroller);
        _setupRole(OPERATOR_ROLE, _router);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        WETH = _weth;
    }

    receive() external payable {
        require(msg.sender == WETH, "NP"); // only accept ETH via fallback from the WETH contract
    }

    // Functions

    /// @notice updates on a user's debt for a given token
    /// @dev can only be called by the comptroller
    /// @param account the user's address
    /// @param amount the amount to add to their debt
    /// @param fxToken the asset to increase
    /**
     * @notice updates a vault's debt position
     * @dev can only be called by the comptroller
     * @param account vault account
     * @param fxToken vault fxToken
     * @param increase whether to increase or decrease the position
     */
    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external override onlyOperator {
        uint256 debt = vaults[account][fxToken].debt;
        vaults[account][fxToken].debt = increase
            ? debt.add(amount)
            : debt.sub(amount);
        emit UpdateDebt(account, fxToken);
    }

    /// @notice deposits collateral into the user's account
    /// @dev requires the collateral token to have already been transferred to the Treasury.
    /// @param account the account to deposit into
    /// @param depositAmount the amount to add
    /// @param collateralType the type of collateral being deposited
    /// @param fxToken the vault to deposit into
    function depositCollateral(
        address account,
        uint256 depositAmount,
        address collateralType,
        address fxToken
    ) external override nonReentrant {
        require(
            Comptroller(comptroller).isCollateralValid(collateralType),
            "IC"
        );

        // Open a vault if it's a new user
        _createNewVault(account);

        // Update interest.
        _updateVaultInterest(account, fxToken);

        // Update balances
        uint256 currentTotalBalance = totalBalances[collateralType];

        vaults[account][fxToken].collateralBalance[collateralType] = vaults[
            account
        ][fxToken]
            .collateralBalance[collateralType]
            .add(depositAmount);

        totalBalances[collateralType] = totalBalances[collateralType].add(
            depositAmount
        );

        // Transfer collateral into the treasury
        require(
            IERC20(collateralType).transferFrom(
                msg.sender,
                address(this),
                depositAmount
            ),
            "FT"
        );

        // Verify transfer amount
        require(
            IERC20(collateralType).balanceOf(address(this)).sub(
                currentTotalBalance
            ) == depositAmount,
            "IA"
        );

        emit UpdateCollateral(account, fxToken, collateralType);
    }

    /**
     * @notice allows the user to deposit with eth
     * @param account the account to deposit into
     * @param fxToken the fxToken vault to deposit into
     */
    function depositCollateralETH(address account, address fxToken)
        external
        payable
        override
        nonReentrant
    {
        require(Comptroller(comptroller).isCollateralValid(WETH), "IC");

        // Open a vault if it's a new user
        _createNewVault(account);

        // Update interest.
        _updateVaultInterest(account, fxToken);

        // Update balances
        uint256 currentTotalBalance = totalBalances[WETH];
        vaults[account][fxToken].collateralBalance[WETH] = vaults[account][
            fxToken
        ]
            .collateralBalance[WETH]
            .add(msg.value);

        totalBalances[WETH] = totalBalances[WETH].add(msg.value);

        // Wrap incoming ether into WETH
        IWETH(WETH).deposit{value: msg.value}();

        // Verify transfer amount
        require(
            IERC20(WETH).balanceOf(address(this)).sub(currentTotalBalance) ==
                msg.value,
            "IA"
        );

        emit UpdateCollateral(account, fxToken, WETH);
    }

    /**
     * @notice withdraws ERC20 collateral from sender's account
     * @dev can be used for all collateral types
     * @param collateralToken the token to withdraw
     * @param to the address to remit to
     * @param amount the amount of collateral to withdraw
     * @param fxToken the vault to withdraw from
     */
    function withdrawCollateral(
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external override nonReentrant {
        _withdrawCollateralFrom(
            msg.sender,
            collateralToken,
            to,
            amount,
            fxToken
        );
    }

    /**
     * @notice withdraws ERC20 collateral from given account
     * @dev can be used for all collateral types
     * @param from account to withdraw from
     * @param collateralToken the token to withdraw
     * @param to the address to remit to
     * @param amount the amount of collateral to withdraw
     * @param fxToken the vault to withdraw from
     */
    function withdrawCollateralFrom(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external override onlyAddressOrOperatorExcludeAdmin(from) nonReentrant {
        _withdrawCollateralFrom(from, collateralToken, to, amount, fxToken);
    }

    /**
     * @notice withdraws WETH collateral as ETH
     * @param to the address to remit to
     * @param amount the amount of collateral to withdraw
     * @param fxToken the vault to withdraw from
     */
    function withdrawCollateralETH(
        address to,
        uint256 amount,
        address fxToken
    ) external override nonReentrant {
        // Check available collateral
        require(
            VaultLibrary().getFreeCollateralAsEth(msg.sender, fxToken) >=
                amount,
            "CA"
        );

        // getFreeCollateral considers all collateral tokens to be equivalent.
        require(
            vaults[msg.sender][fxToken].collateralBalance[WETH] >= amount,
            "CA" // Not enough WETH available
        );

        // Update user's deposit balance
        vaults[msg.sender][fxToken].collateralBalance[WETH] = vaults[
            msg.sender
        ][fxToken]
            .collateralBalance[WETH]
            .sub(amount);

        // Update totalBalances
        totalBalances[WETH] = totalBalances[WETH].sub(amount);

        // Unwrap weth
        IWETH(WETH).withdraw(amount);
        assert(address(this).balance == amount);

        // Remit eth to user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "FP");

        emit UpdateCollateral(msg.sender, fxToken, WETH);
    }

    /**
     * @notice adds the current delta interest to the user's vault debt
     * @param user the vault user
     * @param fxToken the vault fxToken
     */
    function updateVaultInterest(address user, address fxToken)
        external
        override
        onlyAddressOrOperatorExcludeAdmin(user)
    {
        _updateVaultInterest(user, fxToken);
    }

    /**
     * @notice returns the total vault debt with unpaid delta interest
     * @param user the vault user
     * @param fxToken the vault fxToken
     */
    function getVaultDebtWithDeltaInterest(address user, address fxToken)
        public
        view
        returns (uint256)
    {
        uint256 debt = vaults[user][fxToken].debt;
        uint256 interest = VaultLibrary().calculateInterest(user, fxToken);
        return debt.add(interest);
    }

    // Modifiers
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "NO");
        _;
    }

    modifier onlyAdmin() {
        // Protect user deposits from abuse
        require(hasRole(ADMIN_ROLE, msg.sender), "NA");
        _;
    }

    modifier onlyAddressOrOperatorExcludeAdmin(address addressAllowed) {
        // Protect user deposits from abuse
        require(
            msg.sender == addressAllowed ||
                (hasRole(OPERATOR_ROLE, msg.sender) &&
                    !hasRole(ADMIN_ROLE, msg.sender)),
            "NW"
        );
        _;
    }

    // Admin functions
    function setContracts(address _comptroller, address _vaultLibrary)
        external
        override
        onlyAdmin
    {
        comptroller = payable(_comptroller);
        vaultLibrary = _vaultLibrary;
        grantRole(OPERATOR_ROLE, comptroller);
    }

    function setRewardToken(address token, bytes32 which)
        external
        override
        onlyAdmin
    {
        require(false, "Not implemented yet");
    }

    function setCollateralInterestRate(address collateral, uint256 ratePerMille)
        external
        override
        onlyAdmin
        validAddress(collateral)
    {
        interestRate[collateral] = ratePerMille;
    }

    function setFeeRecipient(address feeRecipient)
        external
        override
        onlyAdmin
        validAddress(feeRecipient)
    {
        FeeRecipient = feeRecipient;
    }

    function setFees(
        uint256 _withdrawFeePerMille,
        uint256 _mintFeePerMille,
        uint256 _burnFeePerMille
    ) external override onlyAdmin {
        burnFeePerMille = _burnFeePerMille;
        withdrawFeePerMille = _withdrawFeePerMille;
        mintFeePerMille = _mintFeePerMille;
    }

    // Getters

    /**
     * @notice Returns a user's collateral balance for a given collateral type
     * @param account the user's address
     * @param fxToken the vault to check
     * @param collateralType the collateral token address
     * @return balance
     */
    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view override returns (uint256 balance) {
        balance = vaults[account][fxToken].collateralBalance[collateralType];
    }

    /**
     * @notice returns the total amount of ETH lodged as collateral
     * @param account the account to check
     * @param fxToken the vault to check
     * @return collateral the collateral checked
     * @return balances the balances
     */
    function getBalance(address account, address fxToken)
        external
        view
        override
        returns (address[] memory collateral, uint256[] memory balances)
    {
        collateral = Comptroller(comptroller).getAllCollateralTypes();
        uint256[] memory _balances = new uint256[](collateral.length);
        for (uint256 i = 0; i < collateral.length; i++) {
            _balances[i] = vaults[account][fxToken].collateralBalance[
                collateral[i]
            ];
        }
        balances = _balances;
    }

    function _createNewVault(address account) private validAddress(account) {
        // Open a vault if it's a new user
        if (depositors[account] == false) {
            depositorAddresses.push(account);
            depositors[account] = true;
        }
    }

    /**
     * @notice withdraws ERC20 collateral from given account
     * @dev can be used for all collateral types
     * @param from account to withdraw from
     * @param collateralToken the token to withdraw
     * @param to the address to remit to
     * @param amount the amount of collateral to withdraw
     * @param fxToken the vault to withdraw from
     */
    function _withdrawCollateralFrom(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) private {
        require(
            VaultLibrary().getFreeCollateralAsEth(from, fxToken) >= amount,
            "CA"
        );

        // getFreeCollateral considers all collateral tokens to be equivalent.
        require(
            vaults[from][fxToken].collateralBalance[collateralToken] >= amount,
            "CA" // Not enough of collateral type
        );

        // Update interest.
        _updateVaultInterest(from, fxToken);

        forceWithdrawCollateral(from, collateralToken, to, amount, fxToken);
    }

    /**
     * @notice atempts to withdraw any collateral type
     * @dev uses the liquidation collateral order from VaultLibrary
     * @param from the owner of the vault to withdraw from
     * @param to the address to remit to
     * @param amount the amount of collateral to withdraw
     * @param fxToken the vault to withdraw from
     */
    function withdrawAnyCollateral(
        address from,
        address to,
        uint256 amount,
        address fxToken
    )
        external
        override
        onlyAddressOrOperatorExcludeAdmin(from)
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        )
    {
        bool metAmount;
        (collateralTypes, collateralAmounts, metAmount) = VaultLibrary()
            .getCollateralForAmount(from, fxToken, amount);
        require(metAmount, "IA");
        for (uint256 i = 0; i < collateralTypes.length; i++) {
            _withdrawCollateralFrom(
                from,
                collateralTypes[i],
                to,
                collateralAmounts[i],
                fxToken
            );
        }
    }

    /**
     * @notice forces a ERC20 collateral withdraw, bypassing vault CR checks.
     * @dev can be used for all collateral types
     * @param from the owner of the vault to withdraw from
     * @param collateralToken the token to withdraw
     * @param to the address to remit to
     * @param amount the amount of collateral to withdraw
     * @param fxToken the vault to withdraw from
     */
    function forceWithdrawCollateral(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) public override onlyAddressOrOperatorExcludeAdmin(from) {
        // Update user's deposit balance
        vaults[from][fxToken].collateralBalance[collateralToken] = vaults[from][
            fxToken
        ]
            .collateralBalance[collateralToken]
            .sub(amount);

        // Update totalBalances
        totalBalances[collateralToken] = totalBalances[collateralToken].sub(
            amount
        );

        // Calculate and transfer fee.
        uint256 balanceBefore = IERC20(collateralToken).balanceOf(to);
        uint256 fee = amount.mul(withdrawFeePerMille).div(1000);
        IERC20(collateralToken).transfer(FeeRecipient, fee);

        // Remit collateral to the user
        IERC20(collateralToken).transfer(to, amount.sub(fee));
        assert(
            IERC20(collateralToken).balanceOf(to) ==
                balanceBefore.add(amount).sub(fee)
        );

        emit UpdateCollateral(from, fxToken, collateralToken);
    }

    function _updateVaultInterest(address user, address fxToken) private {
        // Initialise update date and abort if first update.
        if (interestLastUpdateDate[user][fxToken] == 0) {
            interestLastUpdateDate[user][fxToken] = block.timestamp;
            return;
        }

        // Abort if already called this block.
        if (interestLastUpdateDate[user][fxToken] == block.timestamp) return;

        vaults[user][fxToken].debt = getVaultDebtWithDeltaInterest(
            user,
            fxToken
        );
        interestLastUpdateDate[user][fxToken] = block.timestamp;
    }

    /**
     * @notice getter for interestLastUpdateDate
     * @param account the vault owner
     * @param fxToken the vault to get the debt for
     * @return date the date of the last interest update
     */
    function getInterestLastUpdateDate(address account, address fxToken)
        external
        view
        override
        returns (uint256 date)
    {
        date = interestLastUpdateDate[account][fxToken];
    }

    /**
     * @notice a convenience method to access a user's debt
     * @param owner the vault owner
     * @param fxToken the vault to get the debt for
     * @return _debt the amount of fxToken debt outstanding
     */
    function getDebt(address owner, address fxToken)
        external
        view
        override
        returns (uint256 _debt)
    {
        _debt = vaults[owner][fxToken].debt;
    }

    function VaultLibrary() private view returns (IVaultLibrary) {
        return IVaultLibrary(vaultLibrary);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITreasury {
    // Structs
    struct Vault {
        uint256 debt;
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 issuanceDelta; // Used for charging interest
    }
    // Events
    event UpdateDebt(address indexed account, address indexed fxToken);
    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    // State changing functions
    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

    function depositCollateral(
        address account,
        uint256 depositAmount,
        address collateralType,
        address fxToken
    ) external;

    function depositCollateralETH(address account, address fxToken)
        external
        payable;

    function withdrawCollateral(
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralETH(
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralFrom(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function forceWithdrawCollateral(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawAnyCollateral(
        address from,
        address to,
        uint256 amount,
        address fxToken
    )
        external
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        );

    function updateVaultInterest(address user, address fxToken) external;

    // Variable setters
    function setContracts(address comptroller, address vaultLibrary) external;

    function setRewardToken(address token, bytes32 which) external;

    function setCollateralInterestRate(address collateral, uint256 ratePerMille)
        external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    // Getters
    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view returns (uint256 balance);

    function getBalance(address account, address fxToken)
        external
        view
        returns (address[] memory collateral, uint256[] memory balances);

    function getDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function interestRate(address collateral)
        external
        view
        returns (uint256 rate);

    function getInterestLastUpdateDate(address account, address fxToken)
        external
        view
        returns (uint256 date);

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/Bank/IComptroller.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/Bank/IRegistry.sol";
import "../interfaces/Bank/ITreasury.sol";
import "../interfaces/Bank/IfxToken.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/Bank/IOracle.sol";

// Comment this out for production, it's a debug tool
// import "hardhat/console.sol";

contract Comptroller is
    IComptroller,
    IRegistry,
    IValidator,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    // Registry state variables
    address public mintRewardToken;
    address public poolRewardToken;
    address payable public override treasury;
    address public override vaultLibrary;
    address public immutable override WETH;

    // Comptroller state variables
    address[] public collateralTokens;
    mapping(address => bool) public isCollateralValid;
    mapping(address => CollateralData) public collateralDetails;
    address[] public validFxTokens;
    mapping(address => bool) public override isFxTokenValid;
    mapping(address => TokenData) public tokenDetails;

    // Oracles
    // fxAsset => oracle address
    mapping(address => address) public oracles;

    constructor(
        address _mintRewardToken,
        address _poolRewardToken,
        address _weth
    ) {
        mintRewardToken = _mintRewardToken;
        poolRewardToken = _poolRewardToken;
        WETH = _weth;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // Modifiers
    modifier validFxToken(address token) {
        require(isFxTokenValid[token], "IF");
        _;
    }

    /**
     * @notice allows a user to deposit ETH and mint fxTokens in a single transaction
     * @param tokenAmount the amount of fxTokens the user wants
     * @param token the token to mint
     * @param deadline the time on which the transaction is invalid.
     */
    function mintWithEth(
        uint256 tokenAmount,
        address token,
        uint256 deadline
    )
        external
        payable
        override
        dueBy(deadline)
        validFxToken(token)
        nonReentrant
    {
        require(isCollateralValid[WETH], "WE");

        // Update interest.
        Treasury().updateVaultInterest(msg.sender, token);

        // Calculate fee with current amount and increase token amount to include fee.
        uint256 feeTokens =
            tokenAmount.mul(Treasury().mintFeePerMille()).div(1000);
        tokenAmount = tokenAmount.add(feeTokens);

        // Check the vault ratio is correct (fxToken <-> WETH)
        uint256 quote = getTokenPrice(token);
        require(
            VaultLibrary().getFreeCollateralAsEth(msg.sender, token).add(
                msg.value
            ) >=
                VaultLibrary().getMinimumCollateral(
                    tokenAmount,
                    collateralDetails[WETH].mintCR,
                    quote
                ),
            "CR"
        );

        // Mint tokens and fee
        uint256 balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).mint(msg.sender, tokenAmount.sub(feeTokens));
        IfxToken(token).mint(Treasury().FeeRecipient(), feeTokens);
        assert(
            IfxToken(token).balanceOf(msg.sender) ==
                balanceBefore.add(tokenAmount).sub(feeTokens)
        );

        // Update debt position
        uint256 debtPosition = Treasury().getDebt(msg.sender, token);
        Treasury().updateDebtPosition(msg.sender, tokenAmount, token, true);
        assert(
            debtPosition.add(tokenAmount) ==
                Treasury().getDebt(msg.sender, token)
        );

        // Convert to wETH
        IWETH(WETH).deposit{value: msg.value}();
        assert(IERC20(WETH).approve(treasury, msg.value));

        // Deposit in the treasury
        balanceBefore = Treasury().getCollateralBalance(
            msg.sender,
            WETH,
            token
        );
        Treasury().depositCollateral(msg.sender, msg.value, WETH, token);
        assert(
            Treasury().getCollateralBalance(msg.sender, WETH, token) ==
                msg.value.add(balanceBefore)
        );

        emit MintToken(quote, tokenAmount.sub(feeTokens), token);
    }

    // Mint with ERC20 as collateral
    function mint(
        uint256 tokenAmountDesired,
        address token,
        address collateralToken,
        address to,
        uint256 deadline
    ) external override dueBy(deadline) nonReentrant {
        require(isCollateralValid[collateralToken], "IC");

        // Update interest.
        Treasury().updateVaultInterest(msg.sender, token);
    }

    /**
     * @notice allows an user to mint fxTokens with existing collateral
     * @param tokenAmount the amount of fxTokens the user wants
     * @param token the token to mint
     * @param deadline the time on which the transaction is invalid.
     */
    function mintWithoutCollateral(
        uint256 tokenAmount,
        address token,
        uint256 deadline
    ) external override dueBy(deadline) validFxToken(token) {
        // Update interest.
        Treasury().updateVaultInterest(msg.sender, token);

        // Calculate fee with current amount and increase token amount to include fee.
        uint256 feeTokens =
            tokenAmount.mul(Treasury().mintFeePerMille()).div(1000);
        tokenAmount = tokenAmount.add(feeTokens);

        // Check the vault ratio is correct (fxToken <-> collateral)
        uint256 quote = getTokenPrice(token);
        require(
            VaultLibrary().getFreeCollateralAsEth(msg.sender, token) >=
                VaultLibrary().getMinimumCollateral(
                    tokenAmount,
                    collateralDetails[WETH].mintCR,
                    quote
                ),
            "CR"
        );

        // Mint tokens and fee
        uint256 balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).mint(msg.sender, tokenAmount.sub(feeTokens));
        IfxToken(token).mint(Treasury().FeeRecipient(), feeTokens);
        assert(
            IfxToken(token).balanceOf(msg.sender) ==
                balanceBefore.add(tokenAmount).sub(feeTokens)
        );

        // Update debt position
        uint256 debtPosition = Treasury().getDebt(msg.sender, token);
        Treasury().updateDebtPosition(msg.sender, tokenAmount, token, true);
        assert(
            debtPosition.add(tokenAmount) ==
                Treasury().getDebt(msg.sender, token)
        );

        emit MintToken(quote, tokenAmount, token);
    }

    /**
     * @notice allows an user to burn fxTokens
     * @param amount the amount of fxTokens to burn
     * @param token the token to burn
     * @param deadline the time on which the transaction is invalid.
     */
    function burn(
        uint256 amount,
        address token,
        uint256 deadline
    ) external override dueBy(deadline) validFxToken(token) {
        // Token balance must be higher or equal than burn amount.
        require(IfxToken(token).balanceOf(msg.sender) >= amount, "IA");
        // Treasury debt must be higher or equal to burn amount.
        require(Treasury().getDebt(msg.sender, token) >= amount, "IA");
        // Update vault interest before burning.
        Treasury().updateVaultInterest(msg.sender, token);

        // Withdraw fee.
        uint256 fee = calculateBurnFee(amount, token);
        Treasury().forceWithdrawCollateral(
            msg.sender,
            WETH,
            Treasury().FeeRecipient(),
            fee,
            token
        );

        // Burn tokens
        uint256 balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).burn(msg.sender, amount);
        assert(
            IfxToken(token).balanceOf(msg.sender) == balanceBefore.sub(amount)
        );

        // Update debt position
        uint256 debtPositionBefore = Treasury().getDebt(msg.sender, token);
        Treasury().updateDebtPosition(msg.sender, amount, token, false);
        assert(
            Treasury().getDebt(msg.sender, token) ==
                debtPositionBefore.sub(amount)
        );

        emit BurnToken(amount, token);
    }

    /**
     * @notice buy collateral from a vault at a 1:1 asset/collateral ratio
     * @dev token must have been pre-approved for transfer with input amount
     * @param amount the amount of fxTokens to redeem with
     * @param token the fxToken to buy collateral with
     * @param from the account to purchase from
     * @param deadline the deadline for the transaction
     */
    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline
    )
        external
        override
        dueBy(deadline)
        validFxToken(token)
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes
        )
    {
        {
            // Sender must have enough balance.
            require(IfxToken(token).balanceOf(msg.sender) >= amount, "IA");
            // Update vault interest.
            Treasury().updateVaultInterest(from, token);
            uint256 allowedAmount =
                VaultLibrary().getAllowedBuyCollateralFromTokenAmount(
                    amount,
                    token,
                    from
                );
            require(allowedAmount > 0, "IA");
            if (amount > allowedAmount) amount = allowedAmount;
            // Vault must have a debt >= amount.
            require(Treasury().getDebt(from, token) >= amount, "IA");
        }
        // Vault must have enough collateral.
        uint256 amountEth = getTokenPrice(token).mul(amount).div(1 ether);
        bool metAmount = false;
        (collateralTypes, collateralAmounts, metAmount) = VaultLibrary()
            .getCollateralForAmount(from, token, amountEth);
        require(metAmount, "CA");
        // Burn token.
        IfxToken(token).burn(msg.sender, amount);
        // Reduce vault debt and withdraw collateral to user.
        Treasury().updateDebtPosition(from, amount, token, false);
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            Treasury().forceWithdrawCollateral(
                from,
                collateralTokens[i],
                msg.sender,
                collateralAmounts[i],
                token
            );
        }
        emit Redeem(from, token, amount, collateralAmounts, collateralTypes);
    }

    /**
     * @notice calculates burn fee and requires sender to have enough free collateral to cover fee amount after burning
     * @param tokenAmount the amount of fxTokens being burned
     * @param token the token to burn
     */
    function calculateBurnFee(uint256 tokenAmount, address token)
        private
        view
        returns (uint256 feePrice)
    {
        uint256 unitPrice = getTokenPrice(token);
        // Fee price in ETH from Treasury
        uint256 feePerMille = Treasury().burnFeePerMille();
        feePrice = tokenAmount.mul(feePerMille).div(1000).mul(unitPrice).div(
            1 ether
        );
        uint256 available =
            VaultLibrary().getFreeCollateralAsEth(msg.sender, token).add(
                unitPrice
                    .mul(tokenAmount)
                    .mul(VaultLibrary().getMinimumRatio(msg.sender, token))
                    .div(1 ether)
                    .div(100)
            );
    }

    function setFxToken(
        address token,
        uint256 _liquidateCR,
        uint256 rewardRatio
    ) public override onlyOwner {
        if (!isFxTokenValid[token]) {
            validFxTokens.push(token);
            isFxTokenValid[token] = true;
        }
        tokenDetails[token] = TokenData({
            rewardRatio: rewardRatio,
            liquidateCR: _liquidateCR
        });
    }

    function removeFxToken(address token)
        external
        override
        onlyOwner
        validFxToken(token)
    {
        uint256 tokenIndex = validFxTokens.length + 1;
        for (uint256 i = 0; i < validFxTokens.length; i++) {
            if (validFxTokens[i] == token) {
                tokenIndex = i;
                break;
            }
        }
        delete tokenDetails[token];
        delete isFxTokenValid[token];
        if (tokenIndex < validFxTokens.length - 1) {
            delete validFxTokens[tokenIndex];
            validFxTokens[tokenIndex] = validFxTokens[validFxTokens.length - 1];
            validFxTokens.pop();
        } else {
            delete validFxTokens[tokenIndex];
        }
    }

    function setCollateralToken(
        address _token,
        uint256 _mintCR,
        uint256 _liquidationRank,
        uint256 _stabilityFee,
        uint256 _liquidationFee
    ) public override onlyOwner {
        if (!isCollateralValid[_token]) {
            collateralTokens.push(_token);
            isCollateralValid[_token] = true;
        }
        collateralDetails[_token] = CollateralData({
            mintCR: _mintCR,
            liquidationRank: _liquidationRank,
            stabilityFee: _stabilityFee,
            liquidationFee: _liquidationFee
        });
    }

    function removeCollateralToken(address token) external override onlyOwner {
        // Cannot remove a token, as this would orphan user collateral. Mark it invalid instead.
        delete isCollateralValid[token];
    }

    function setContracts(address _treasury, address _vaultLibrary)
        external
        override
        onlyOwner
    {
        require(_treasury != address(0), "IZ");
        require(_vaultLibrary != address(0), "IZ");
        treasury = payable(_treasury);
        vaultLibrary = _vaultLibrary;
    }

    function setMintToken(address token) external override onlyOwner {
        mintRewardToken = token;
    }

    /**
     * @notice Returns the amount of ETH required to purchase 1 unit of token
     * @param token the fxToken to get the price of
     * @return quote The price of 1 token in ETH
     */
    function getTokenPrice(address token)
        public
        view
        override
        returns (uint256 quote)
    {
        if (token == WETH) return 1 ether;
        if (oracles[token] == address(0)) return 1 ether;

        quote = IOracle(oracles[token]).getRate(token);
    }

    function getAllCollateralTypes()
        external
        view
        override
        returns (address[] memory collateral)
    {
        collateral = collateralTokens;
    }

    /**
     * @notice Returns the entire array of valid fxTokens
     * @return tokens the valid tokens
     */
    function getAllFxTokens()
        external
        view
        override
        returns (address[] memory tokens)
    {
        tokens = validFxTokens;
    }

    function getCollateralDetails(address collateral)
        external
        view
        override
        returns (CollateralData memory)
    {
        return collateralDetails[collateral];
    }

    function getTokenDetails(address token)
        external
        view
        override
        returns (TokenData memory)
    {
        return tokenDetails[token];
    }

    /**
     * @notice sets an oracle for a given fxToken
     * @param _fxToken the fxToken to set the oracle for
     * @param _oracle the oracle to use for the fxToken
     */
    function setOracle(address _fxToken, address _oracle)
        external
        override
        onlyOwner
    {
        require(_fxToken != address(0), "IZ");
        require(_oracle != address(0), "IZ");
        oracles[_fxToken] = _oracle;
    }

    function VaultLibrary() private view returns (IVaultLibrary) {
        return IVaultLibrary(vaultLibrary);
    }

    function Treasury() private view returns (ITreasury) {
        return ITreasury(treasury);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <=0.7.6;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IComptroller {
    // Structs
    struct TokenData {
        uint256 liquidateCR;
        uint256 rewardRatio;
    }
    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationRank;
        uint256 stabilityFee;
        uint256 liquidationFee;
    }
    // Events
    event MintToken(
        uint256 tokenRate,
        uint256 amountMinted,
        address indexed token
    );
    event BurnToken(uint256 amountBurned, address indexed token);
    event Redeem(
        address from,
        address token,
        uint256 tokenAmount,
        uint256[] collateralAmounts,
        address[] collateralTypes
    );

    // Mint with ETH as collateral
    function mintWithEth(
        uint256 tokenAmountDesired,
        address fxToken,
        uint256 deadline
    ) external payable;

    // Mint with ERC20 as collateral
    function mint(
        uint256 amountDesired,
        address fxToken,
        address collateralToken,
        address to,
        uint256 deadline
    ) external;

    function mintWithoutCollateral(
        uint256 tokenAmountDesired,
        address token,
        uint256 deadline
    ) external;

    // Burn to withdraw collateral
    function burn(
        uint256 amount,
        address token,
        uint256 deadline
    ) external;

    // Buy collateral with fxTokens
    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline
    )
        external
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes
        );

    // Add/Update/Remove a token
    function setFxToken(
        address token,
        uint256 _liquidateCR,
        uint256 rewardRatio
    ) external;

    // Update tokens
    function removeFxToken(address token) external;

    function setCollateralToken(
        address _token,
        uint256 _mintCR,
        uint256 _liquidationRank,
        uint256 _stabilityFee,
        uint256 _liquidationFee
    ) external;

    function removeCollateralToken(address token) external;

    // Getters
    function getTokenPrice(address token) external view returns (uint256 quote);

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getAllFxTokens() external view returns (address[] memory tokens);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function getTokenDetails(address token)
        external
        view
        returns (TokenData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function vaultLibrary() external view returns (address);

    function setOracle(address fxToken, address oracle) external;

    function isFxTokenValid(address fxToken) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IVaultLibrary {
    enum CollateralRatioType {Minting, Redeem, Liquidation}

    function setContracts(address comptroller, address treasury) external;

    function doesMeetRatio(
        address account,
        address fxToken,
        CollateralRatioType crt
    ) external view returns (bool);

    function getCollateralRequiredAsEth(
        uint256 assetAmount,
        address fxToken,
        CollateralRatioType crt
    ) external view returns (uint256);

    function getFreeCollateralAsEth(address account, address fxToken)
        external
        view
        returns (uint256);

    function getMinimumRatio(address account, address fxToken)
        external
        view
        returns (uint256 ratio);

    function getMinimumCollateral(
        uint256 tokenAmount,
        uint256 ratio,
        uint256 unitPrice
    ) external view returns (uint256 minimum);

    function getDebtAsEth(address account, address fxToken)
        external
        view
        returns (uint256 debt);

    function getTotalCollateralBalanceAsEth(address account, address fxToken)
        external
        view
        returns (uint256 balance);

    function getCurrentRatio(address account, address fxToken)
        external
        view
        returns (uint256 ratio);

    function getCollateralForAmount(
        address account,
        address fxToken,
        uint256 amountEth
    )
        external
        view
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts,
            bool metAmount
        );

    function calculateInterest(address user, address fxToken)
        external
        view
        returns (uint256 interest);

    function getInterestRate(address user, address fxToken)
        external
        view
        returns (uint256);

    function getLiquidationFee(address account, address fxToken)
        external
        view
        returns (uint256 fee);

    function getCollateralShares(address account, address fxToken)
        external
        view
        returns (uint256[] memory shares);

    function tokensRequiredForCrIncrease(
        uint256 crTarget,
        uint256 debt,
        uint256 collateral
    ) external pure returns (uint256 amount);

    function getCollateralTypesSortedByLiquidationRank()
        external
        view
        returns (address[] memory sortedCollateralTypes);

    function getAllowedBuyCollateralFromTokenAmount(
        uint256 amount,
        address token,
        address from
    ) external view returns (uint256 allowedAmount);

    function quickSort(
        uint256[] memory array,
        int256 left,
        int256 right
    ) external pure;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface IValidator {
    modifier dueBy(uint256 date) {
        require(block.timestamp <= date, "Transaction has exceeded deadline");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid Address");
        _;
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IRegistry {
    function setContracts(address treasury, address vaultLibrary) external;

    function setMintToken(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IfxToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IOracle {
    /**
     * @notice Returns the price of 1 fxAsset in ETH
     * @param fxAsset the asset to get a rate for
     * @return unitPrice the cost of a single fxAsset in ETH
     */
    function getRate(address fxAsset) external view returns (uint256 unitPrice);

    /**
     * @notice A setter function to add or update an oracle for a given fx asset.
     * @param fxAsset the asset to update
     * @param oracle the oracle to set for the fxAsset
     */
    function setOracle(address fxAsset, address oracle) external;
}

