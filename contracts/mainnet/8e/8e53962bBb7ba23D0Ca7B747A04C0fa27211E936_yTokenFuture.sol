pragma solidity 0.7.6;

import "contracts/protocol/futures/RateFuture.sol";
import "contracts/interfaces/platforms/yearn/IyToken.sol";

/**
 * @title Contract for yToken Future
 * @author Gaspard Peduzzi
 * @notice Handles the future mechanisms for the Aave platform
 * @dev Implement directly the stream future abstraction as it fits the aToken IBT
 */
contract yTokenFuture is RateFuture {
    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view override returns (uint256) {
        return yToken(address(ibt)).getPricePerFullShare();
    }
}

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "contracts/protocol/futures/Future.sol";

/**
 * @title Main future abstraction contract for the rate futures
 * @author Gaspard Peduzzi
 * @notice Handles the rates future mecanisms
 * @dev Basis of all mecanisms for futures (registrations, period switch)
 */
abstract contract RateFuture is Future {
    using SafeMathUpgradeable for uint256;

    uint256[] private IBTRates;

    /**
     * @notice Intializer
     * @param _controller the address of the controller
     * @param _ibt the address of the corresponding IBT
     * @param _periodDuration the length of the period (in days)
     * @param _platformName the name of the platform and tools
     * @param _admin the address of the ACR admin
     */
    function initialize(
        address _controller,
        address _ibt,
        uint256 _periodDuration,
        string memory _platformName,
        address _deployerAddress,
        address _admin
    ) public virtual override initializer {
        super.initialize(_controller, _ibt, _periodDuration, _platformName, _deployerAddress, _admin);
        IBTRates.push();
        IBTRates.push();
    }

    /**
     * @notice Sender registers an amount of IBT for the next period
     * @param _user address to register to the future
     * @param _amount amount of IBT to be registered
     * @dev called by the controller only
     */
    function register(address _user, uint256 _amount) public virtual override periodsActive nonReentrant {
        super.register(_user, _amount);
    }

    /**
     * @notice Sender unregisters an amount of IBT for the next period
     * @param _user user addresss
     * @param _amount amount of IBT to be unregistered
     * @dev 0 unregisters all
     */
    function unregister(address _user, uint256 _amount) public virtual override nonReentrant {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to unregister");

        uint256 nextIndex = getNextPeriodIndex();
        require(registrations[_user].startIndex == nextIndex, "The is not ongoing registration for the next period");

        uint256 currentRegistered = registrations[_user].scaledBalance;
        uint256 toRefund;

        if (_amount == 0) {
            delete registrations[_user];
            toRefund = currentRegistered;
        } else {
            require(currentRegistered >= _amount, "Invalid amount to unregister");
            registrations[_user].scaledBalance = registrations[_user].scaledBalance.sub(currentRegistered);
            toRefund = _amount;
        }

        ibt.transfer(_user, toRefund);
    }

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() public virtual override nextPeriodAvailable periodsActive nonReentrant {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to start the next period");

        uint256 nextPeriodID = getNextPeriodIndex();
        uint256 currentRate = getIBTRate();

        IBTRates[nextPeriodID] = currentRate;
        registrationsTotals[nextPeriodID] = ibt.balanceOf(address(this));

        /* Yield */
        uint256 yield =
            (ibt.balanceOf(address(futureVault)).mul(currentRate.sub(IBTRates[nextPeriodID - 1]))).div(currentRate);
        if (yield > 0) assert(ibt.transferFrom(address(futureVault), address(futureWallet), yield));
        futureWallet.registerExpiredFuture(yield); // Yield deposit in the futureWallet contract

        /* Period Switch*/
        if (registrationsTotals[nextPeriodID] > 0) {
            apwibt.mint(address(this), registrationsTotals[nextPeriodID].mul(IBTRates[nextPeriodID])); // Mint new apwIBTs
            ibt.transfer(address(futureVault), registrationsTotals[nextPeriodID]); // Send IBT to future for the new period
        }

        registrationsTotals.push();
        IBTRates.push();

        /* Future Yield Token */
        address fytAddress = deployFutureYieldToken(nextPeriodID);
        emit NewPeriodStarted(nextPeriodID, fytAddress);
    }

    /**
     * @notice Getter for user registered amount
     * @param _user user to return the registered funds of
     * @return the registered amount, 0 if no registrations
     * @dev the registration can be older than the next period
     */
    function getRegisteredAmount(address _user) public view override returns (uint256) {
        uint256 periodID = registrations[_user].startIndex;
        if (periodID == getNextPeriodIndex()) {
            return registrations[_user].scaledBalance;
        } else {
            return 0;
        }
    }

    function scaleIBTAmount(
        uint256 _initialAmount,
        uint256 _initialRate,
        uint256 _newRate
    ) public pure returns (uint256) {
        return (_initialAmount.mul(_initialRate)).div(_newRate);
    }

    /**
     * @notice Getter for the amount of apwIBT that the user can claim
     * @param _user user to check the check the claimable apwIBT of
     * @return the amount of apwIBT claimable by the user
     */
    function getClaimableAPWIBT(address _user) public view override returns (uint256) {
        if (!hasClaimableAPWIBT(_user)) return 0;
        return
            scaleIBTAmount(
                registrations[_user].scaledBalance,
                IBTRates[registrations[_user].startIndex],
                IBTRates[getNextPeriodIndex() - 1]
            );
    }

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) public view override returns (uint256) {
        return scaleIBTAmount(super.getUnlockableFunds(_user), IBTRates[getNextPeriodIndex() - 1], getIBTRate());
    }

    /**
     * @notice Getter for yield that is generated by the user funds during the current period
     * @param _user user to check the unrealised yield of
     * @return the yield (amount of IBT) currently generated by the locked funds of the user
     */
    function getUnrealisedYield(address _user) public view override returns (uint256) {
        return
            apwibt.balanceOf(_user).sub(
                scaleIBTAmount(apwibt.balanceOf(_user), IBTRates[getNextPeriodIndex() - 1], getIBTRate())
            );
    }

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view virtual returns (uint256);
}

pragma solidity 0.7.6;

import "contracts/interfaces/ERC20.sol";

interface yToken is ERC20 {
    function getPricePerFullShare() external view returns (uint256);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../GSN/ContextUpgradeable.sol";
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

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "contracts/interfaces/IProxyFactory.sol";
import "contracts/interfaces/apwine/tokens/IFutureYieldToken.sol";
import "contracts/interfaces/apwine/utils/IAPWineMath.sol";

import "contracts/interfaces/apwine/tokens/IAPWineIBT.sol";
import "contracts/interfaces/apwine/IFutureWallet.sol";
import "contracts/interfaces/apwine/IFuture.sol";

import "contracts/interfaces/apwine/IController.sol";
import "contracts/interfaces/apwine/IFutureVault.sol";
import "contracts/interfaces/apwine/ILiquidityGauge.sol";
import "contracts/interfaces/apwine/IRegistry.sol";

/**
 * @title Main future abstraction contract
 * @author Gaspard Peduzzi
 * @notice Handles the future mechanisms
 * @dev Basis of all mecanisms for futures (registrations, period switch)
 */
abstract contract Future is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    /* Structs */
    struct Registration {
        uint256 startIndex;
        uint256 scaledBalance;
    }

    uint256[] internal registrationsTotals;

    /* ACR */
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant FUTURE_PAUSER = keccak256("FUTURE_PAUSER");
    bytes32 public constant FUTURE_DEPLOYER = keccak256("FUTURE_DEPLOYER");

    /* State variables */
    mapping(address => uint256) internal lastPeriodClaimed;
    mapping(address => Registration) internal registrations;
    IFutureYieldToken[] public fyts;

    /* External contracts */
    IFutureVault internal futureVault;
    IFutureWallet internal futureWallet;
    ILiquidityGauge internal liquidityGauge;
    ERC20 internal ibt;
    IAPWineIBT internal apwibt;
    IController internal controller;

    /* Settings */
    uint256 public PERIOD_DURATION;
    string public PLATFORM_NAME;
    bool public PAUSED;

    /* Events */
    event UserRegistered(address _userAddress, uint256 _amount, uint256 _periodIndex);
    event NewPeriodStarted(uint256 _newPeriodIndex, address _fytAddress);
    event FutureVaultSet(address _futureVault);
    event FutureWalletSet(address _futureWallet);
    event LiquidityGaugeSet(address _liquidityGauge);
    event FundsWithdrawn(address _user, uint256 _amount);
    event PeriodsPaused();
    event PeriodsResumed();

    /* Modifiers */
    modifier nextPeriodAvailable() {
        uint256 controllerDelay = controller.STARTING_DELAY();
        require(
            controller.getNextPeriodStart(PERIOD_DURATION) < block.timestamp.add(controllerDelay),
            "Next period start range not reached yet"
        );
        _;
    }

    modifier periodsActive() {
        require(!PAUSED, "New periods are currently paused");
        _;
    }

    /* Initializer */
    /**
     * @notice Intializer
     * @param _controller the address of the controller
     * @param _ibt the address of the corresponding IBT
     * @param _periodDuration the length of the period (in days)
     * @param _platformName the name of the platform and tools
     * @param _admin the address of the ACR admin
     */
    function initialize(
        address _controller,
        address _ibt,
        uint256 _periodDuration,
        string memory _platformName,
        address _deployerAddress,
        address _admin
    ) public virtual initializer {
        controller = IController(_controller);
        ibt = ERC20(_ibt);
        PERIOD_DURATION = _periodDuration * (1 days);
        PLATFORM_NAME = _platformName;
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(CONTROLLER_ROLE, _controller);
        _setupRole(FUTURE_PAUSER, _controller);
        _setupRole(FUTURE_DEPLOYER, _deployerAddress);

        registrationsTotals.push();
        registrationsTotals.push();
        fyts.push();

        IRegistry registry = IRegistry(controller.getRegistryAddress());

        string memory ibtSymbol = controller.getFutureIBTSymbol(ibt.symbol(), _platformName, _periodDuration);
        bytes memory payload =
            abi.encodeWithSignature("initialize(string,string,address)", ibtSymbol, ibtSymbol, address(this));
        apwibt = IAPWineIBT(
            IProxyFactory(registry.getProxyFactoryAddress()).deployMinimal(registry.getAPWineIBTLogicAddress(), payload)
        );
    }

    /* Period functions */

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() public virtual;

    /**
     * @notice Sender registers an amount of IBT for the next period
     * @param _user address to register to the future
     * @param _amount amount of IBT to be registered
     * @dev called by the controller only
     */
    function register(address _user, uint256 _amount) public virtual periodsActive {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to register");
        uint256 nextIndex = getNextPeriodIndex();
        if (registrations[_user].scaledBalance == 0) {
            // User has no record
            _register(_user, _amount);
        } else {
            if (registrations[_user].startIndex == nextIndex) {
                // User has already an existing registration for the next period
                registrations[_user].scaledBalance = registrations[_user].scaledBalance.add(_amount);
            } else {
                // User had an unclaimed registation from a previous period
                _claimAPWIBT(_user);
                _register(_user, _amount);
            }
        }
        emit UserRegistered(_user, _amount, nextIndex);
    }

    function _register(address _user, uint256 _initialScaledBalance) internal virtual {
        registrations[_user] = Registration({startIndex: getNextPeriodIndex(), scaledBalance: _initialScaledBalance});
    }

    /**
     * @notice Sender unregisters an amount of IBT for the next period
     * @param _user user address
     * @param _amount amount of IBT to be unregistered
     */
    function unregister(address _user, uint256 _amount) public virtual;

    /* Claim functions */

    /**
     * @notice Send the user their owed FYT (and apwIBT if there are some claimable)
     * @param _user address of the user to send the FYT to
     */
    function claimFYT(address _user) public virtual nonReentrant {
        require(hasClaimableFYT(_user), "No FYT claimable for this address");
        if (hasClaimableAPWIBT(_user)) _claimAPWIBT(_user);
        else _claimFYT(_user);
    }

    function _claimFYT(address _user) internal virtual {
        uint256 nextIndex = getNextPeriodIndex();
        for (uint256 i = lastPeriodClaimed[_user] + 1; i < nextIndex; i++) {
            claimFYTforPeriod(_user, i);
        }
    }

    function claimFYTforPeriod(address _user, uint256 _periodIndex) internal virtual {
        assert((lastPeriodClaimed[_user] + 1) == _periodIndex);
        assert(_periodIndex < getNextPeriodIndex());
        assert(_periodIndex != 0);
        lastPeriodClaimed[_user] = _periodIndex;
        fyts[_periodIndex].transfer(_user, apwibt.balanceOf(_user));
    }

    function _claimAPWIBT(address _user) internal virtual {
        uint256 nextIndex = getNextPeriodIndex();
        uint256 claimableAPWIBT = getClaimableAPWIBT(_user);

        if (_hasOnlyClaimableFYT(_user)) _claimFYT(_user);
        apwibt.transfer(_user, claimableAPWIBT);

        for (uint256 i = registrations[_user].startIndex; i < nextIndex; i++) {
            // get unclaimed fyt
            fyts[i].transfer(_user, claimableAPWIBT);
        }

        lastPeriodClaimed[_user] = nextIndex - 1;
        delete registrations[_user];
    }

    /**
     * @notice Sender unlocks the locked funds corresponding to their apwIBT holding
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev will require a transfer of FYT of the ongoing period corresponding to the funds unlocked
     */
    function withdrawLockFunds(address _user, uint256 _amount) public virtual nonReentrant {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Caller is not allowed to withdraw locked funds");
        require((_amount > 0) && (_amount <= apwibt.balanceOf(_user)), "Invalid amount");
        if (hasClaimableAPWIBT(_user)) {
            _claimAPWIBT(_user);
        } else if (hasClaimableFYT(_user)) {
            _claimFYT(_user);
        }

        uint256 unlockableFunds = getUnlockableFunds(_user);
        uint256 unrealisedYield = getUnrealisedYield(_user);

        uint256 fundsToBeUnlocked = _amount.mul(unlockableFunds).div(apwibt.balanceOf(_user));
        uint256 yieldToBeUnlocked = _amount.mul(unrealisedYield).div(apwibt.balanceOf(_user));

        uint256 yieldToBeRedeemed = yieldToBeUnlocked.mul(controller.getUnlockYieldFactor(PERIOD_DURATION));

        ibt.transferFrom(address(futureVault), _user, fundsToBeUnlocked.add(yieldToBeRedeemed));

        ibt.transferFrom(
            address(futureVault),
            IRegistry(controller.getRegistryAddress()).getTreasuryAddress(),
            unrealisedYield.sub(yieldToBeRedeemed)
        );
        apwibt.burnFrom(_user, _amount);
        fyts[getNextPeriodIndex() - 1].burnFrom(_user, _amount);
        emit FundsWithdrawn(_user, _amount);
    }

    /* Utilitary functions */

    function deployFutureYieldToken(uint256 _internalPeriodID) internal returns (address) {
        IRegistry registry = IRegistry(controller.getRegistryAddress());
        string memory tokenDenomination = controller.getFYTSymbol(apwibt.symbol(), PERIOD_DURATION);
        bytes memory payload =
            abi.encodeWithSignature(
                "initialize(string,string,uint256,address)",
                tokenDenomination,
                tokenDenomination,
                _internalPeriodID,
                address(this)
            );
        IFutureYieldToken newToken =
            IFutureYieldToken(
                IProxyFactory(registry.getProxyFactoryAddress()).deployMinimal(registry.getFYTLogicAddress(), payload)
            );
        fyts.push(newToken);
        newToken.mint(address(this), apwibt.totalSupply().mul(10**(uint256(18 - ibt.decimals()))));
        return address(newToken);
    }

    /* Getters */

    /**
     * @notice Check if a user has unclaimed FYT
     * @param _user the user to check
     * @return true if the user can claim some FYT, false otherwise
     */
    function hasClaimableFYT(address _user) public view returns (bool) {
        return hasClaimableAPWIBT(_user) || _hasOnlyClaimableFYT(_user);
    }

    function _hasOnlyClaimableFYT(address _user) internal view returns (bool) {
        return lastPeriodClaimed[_user] != 0 && lastPeriodClaimed[_user] < getNextPeriodIndex() - 1;
    }

    /**
     * @notice Check if a user has IBT not claimed
     * @param _user the user to check
     * @return true if the user can claim some IBT, false otherwise
     */
    function hasClaimableAPWIBT(address _user) public view returns (bool) {
        return (registrations[_user].startIndex < getNextPeriodIndex()) && (registrations[_user].scaledBalance > 0);
    }

    /**
     * @notice Getter for next period index
     * @return next period index
     * @dev index starts at 1
     */
    function getNextPeriodIndex() public view virtual returns (uint256) {
        return registrationsTotals.length - 1;
    }

    /**
     * @notice Getter for the amount of apwIBT that the user can claim
     * @param _user user to check the check the claimable apwIBT of
     * @return the amount of apwIBT claimable by the user
     */
    function getClaimableAPWIBT(address _user) public view virtual returns (uint256);

    /**
     * @notice Getter for the amount of FYT that the user can claim for a certain period
     * @param _user the user to check the claimable FYT of
     * @param _periodID period ID to check the claimable FYT of
     * @return the amount of FYT claimable by the user for this period ID
     */
    function getClaimableFYTForPeriod(address _user, uint256 _periodID) public view virtual returns (uint256) {
        if (
            _periodID >= getNextPeriodIndex() ||
            registrations[_user].startIndex == 0 ||
            registrations[_user].scaledBalance == 0 ||
            registrations[_user].startIndex > _periodID
        ) {
            return 0;
        } else {
            return getClaimableAPWIBT(_user);
        }
    }

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user the user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) public view virtual returns (uint256) {
        return apwibt.balanceOf(_user);
    }

    /**
     * @notice Getter for user registered amount
     * @param _user the user to return the registered funds of
     * @return the registered amount, 0 if no registrations
     * @dev the registration can be older than the next period
     */
    function getRegisteredAmount(address _user) public view virtual returns (uint256);

    /**
     * @notice Getter for yield that is generated by the user funds during the current period
     * @param _user the user to check the unrealized yield of
     * @return the yield (amount of IBT) currently generated by the locked funds of the user
     */
    function getUnrealisedYield(address _user) public view virtual returns (uint256);

    /**
     * @notice Getter for controller address
     * @return the controller address
     */
    function getControllerAddress() public view returns (address) {
        return address(controller);
    }

    /**
     * @notice Getter for future wallet address
     * @return future wallet address
     */
    function getFutureVaultAddress() public view returns (address) {
        return address(futureVault);
    }

    /**
     * @notice Getter for futureWallet address
     * @return futureWallet address
     */
    function getFutureWalletAddress() public view returns (address) {
        return address(futureWallet);
    }

    /**
     * @notice Getter for liquidity gauge address
     * @return liquidity gauge address
     */
    function getLiquidityGaugeAddress() public view returns (address) {
        return address(liquidityGauge);
    }

    /**
     * @notice Getter for the IBT address
     * @return IBT address
     */
    function getIBTAddress() public view returns (address) {
        return address(ibt);
    }

    /**
     * @notice Getter for future apwIBT address
     * @return apwIBT address
     */
    function getAPWIBTAddress() public view returns (address) {
        return address(apwibt);
    }

    /**
     * @notice Getter for FYT address of a particular period
     * @param _periodIndex period index
     * @return FYT address
     */
    function getFYTofPeriod(uint256 _periodIndex) public view returns (address) {
        require(_periodIndex < getNextPeriodIndex(), "No FYT for this period yet");
        return address(fyts[_periodIndex]);
    }

    /* Admin function */

    /**
     * @notice Pause registrations and the creation of new periods
     */
    function pausePeriods() public {
        require(hasRole(FUTURE_PAUSER, msg.sender), "Caller is not allowed to pause future");
        PAUSED = true;
        emit PeriodsPaused();
    }

    /**
     * @notice Resume registrations and the creation of new periods
     */
    function resumePeriods() public {
        require(hasRole(FUTURE_PAUSER, msg.sender), "Caller is not allowed to resume future");
        PAUSED = false;
        emit PeriodsResumed();
    }

    /**
     * @notice Set future wallet address
     * @param _futureVault the address of the new future wallet
     * @dev needs corresponding permissions for sender
     */
    function setFutureVault(address _futureVault) public {
        require(hasRole(FUTURE_DEPLOYER, msg.sender), "Caller is not allowed to set the future vault address");
        futureVault = IFutureVault(_futureVault);
        emit FutureVaultSet(_futureVault);
    }

    /**
     * @notice Set futureWallet address
     * @param _futureWallet the address of the new futureWallet
     * @dev needs corresponding permissions for sender
     */
    function setFutureWallet(address _futureWallet) public {
        require(hasRole(FUTURE_DEPLOYER, msg.sender), "Caller is not allowed to set the future wallet address");
        futureWallet = IFutureWallet(_futureWallet);
        emit FutureWalletSet(_futureWallet);
    }

    /**
     * @notice Set liquidity gauge address
     * @param _liquidityGauge the address of the new liquidity gauge
     * @dev needs corresponding permissions for sender
     */
    function setLiquidityGauge(address _liquidityGauge) public {
        require(hasRole(FUTURE_DEPLOYER, msg.sender), "Caller is not allowed to set the liquidity gauge address");
        liquidityGauge = ILiquidityGauge(_liquidityGauge);
        emit LiquidityGaugeSet(_liquidityGauge);
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
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

pragma solidity 0.7.6;

interface IProxyFactory {
    function deployMinimal(address _logic, bytes memory _data) external returns (address proxy);
}

pragma solidity 0.7.6;

import "contracts/interfaces/ERC20.sol";

interface IFutureYieldToken is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external;
}

pragma solidity 0.7.6;

interface IAPWineMaths {
    /**
     * @notice scale an input
     * @param _actualValue the original value of the input
     * @param _initialSum the scaled value of the sum of the inputs
     * @param _actualSum the current value of the sum of the inputs
     */
    function getScaledInput(
        uint256 _actualValue,
        uint256 _initialSum,
        uint256 _actualSum
    ) external pure returns (uint256);

    /**
     * @notice scale back a value to the output
     * @param _scaledOutput the current scaled output
     * @param _initialSum the scaled value of the sum of the inputs
     * @param _actualSum the current value of the sum of the inputs
     */
    function getActualOutput(
        uint256 _scaledOutput,
        uint256 _initialSum,
        uint256 _actualSum
    ) external pure returns (uint256);
}

pragma solidity 0.7.6;

import "contracts/interfaces/ERC20.sol";

interface IAPWineIBT is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

pragma solidity 0.7.6;

interface IFutureWallet {
    /**
     * @notice Intializer
     * @param _futureAddress the address of the corresponding future
     * @param _adminAddress the address of the ACR admin
     */
    function initialize(address _futureAddress, address _adminAddress) external;

    /**
     * @notice register the yield of an expired period
     * @param _amount the amount of yield to be registered
     */
    function registerExpiredFuture(uint256 _amount) external;

    /**
     * @notice redeem the yield of the underlying yield of the FYT held by the sender
     * @param _periodIndex the index of the period to redeem the yield from
     */
    function redeemYield(uint256 _periodIndex) external;

    /**
     * @notice return the yield that could be redeemed by an address for a particular period
     * @param _periodIndex the index of the corresponding period
     * @param _tokenHolder the FYT holder
     * @return the yield that could be redeemed by the token holder for this period
     */
    function getRedeemableYield(uint256 _periodIndex, address _tokenHolder) external view returns (uint256);

    /**
     * @notice getter for the address of the future corresponding to this future wallet
     * @return the address of the future
     */
    function getFutureAddress() external view returns (address);

    /**
     * @notice getter for the address of the IBT corresponding to this future wallet
     * @return the address of the IBT
     */
    function getIBTAddress() external view returns (address);
}

pragma solidity 0.7.6;

interface IFuture {
    struct Registration {
        uint256 startIndex;
        uint256 scaledBalance;
    }

    /**
     * @notice Getter for the PAUSE future parameter
     * @return true if new periods are paused, false otherwise
     */
    function PAUSED() external view returns (bool);

    /**
     * @notice Getter for the PERIOD future parameter
     * @return returns the period duration of the future
     */
    function PERIOD_DURATION() external view returns (uint256);

    /**
     * @notice Getter for the PLATFORM_NAME future parameter
     * @return returns the platform of the future
     */
    function PLATFORM_NAME() external view returns (uint256);

    /**
     * @notice Initializer
     * @param _controller the address of the controller
     * @param _ibt the address of the corresponding IBT
     * @param _periodDuration the length of the period (in days)
     * @param _platformName the name of the platform and tools
     * @param _deployerAddress the future deployer address
     * @param _admin the address of the ACR admin
     */
    function initialize(
        address _controller,
        address _ibt,
        uint256 _periodDuration,
        string memory _platformName,
        address _deployerAddress,
        address _admin
    ) external;

    /**
     * @notice Set future wallet address
     * @param _futureVault the address of the new future wallet
     * @dev needs corresponding permissions for sender
     */
    function setFutureVault(address _futureVault) external;

    /**
     * @notice Set futureWallet address
     * @param _futureWallet the address of the new futureWallet
     * @dev needs corresponding permissions for sender
     */
    function setFutureWallet(address _futureWallet) external;

    /**
     * @notice Set liquidity gauge address
     * @param _liquidityGauge the address of the new liquidity gauge
     * @dev needs corresponding permissions for sender
     */
    function setLiquidityGauge(address _liquidityGauge) external;

    /**
     * @notice Sender registers an amount of IBT for the next period
     * @param _user address to register to the future
     * @param _amount amount of IBT to be registered
     * @dev called by the controller only
     */
    function register(address _user, uint256 _amount) external;

    /**
     * @notice Sender unregisters an amount of IBT for the next period
     * @param _user user addresss
     * @param _amount amount of IBT to be unregistered
     */
    function unregister(address _user, uint256 _amount) external;

    /**
     * @notice Sender unlocks the locked funds corresponding to their apwIBT holding
     * @param _user the user address
     * @param _amount amount of funds to unlocked
     * @dev will require a transfer of FYT of the ongoing period corresponding to the funds unlocked
     */
    function withdrawLockFunds(address _user, uint256 _amount) external;

    /**
     * @notice Send the user their owed FYT (and apwIBT if there are some claimable)
     * @param _user address of the user to send the FYT to
     */
    function claimFYT(address _user) external;

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() external;

    /**
     * @notice Check if a user has unclaimed FYT
     * @param _user the user to check
     * @return true if the user can claim some FYT, false otherwise
     */
    function hasClaimableFYT(address _user) external view returns (bool);

    /**
     * @notice Check if a user has unclaimed apwIBT
     * @param _user the user to check
     * @return true if the user can claim some apwIBT, false otherwise
     */
    function hasClaimableAPWIBT(address _user) external view returns (bool);

    /**
     * @notice Getter for user registered amount
     * @param _user user to return the registered funds of
     * @return the registered amount, 0 if no registrations
     * @dev the registration can be older than the next period
     */
    function getRegisteredAmount(address _user) external view returns (uint256);

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) external view returns (uint256);

    /**
     * @notice Getter for yield that is generated by the user funds during the current period
     * @param _user user to check the unrealized yield of
     * @return the yield (amount of IBT) currently generated by the locked funds of the user
     */
    function getUnrealisedYield(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount of apwIBT that the user can claim
     * @param _user the user to check the claimable apwIBT of
     * @return the amount of apwIBT claimable by the user
     */
    function getClaimableAPWIBT(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount of FYT that the user can claim for a certain period
     * @param _user user to check the check the claimable FYT of
     * @param _periodID period ID to check the claimable FYT of
     * @return the amount of FYT claimable by the user for this period ID
     */
    function getClaimableFYTForPeriod(address _user, uint256 _periodID) external view returns (uint256);

    /**
     * @notice Getter for next period index
     * @return next period index
     * @dev index starts at 1
     */
    function getNextPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for controller address
     * @return the controller address
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for future wallet address
     * @return future wallet address
     */
    function getFutureVaultAddress() external view returns (address);

    /**
     * @notice Getter for futureWallet address
     * @return futureWallet address
     */
    function getFutureWalletAddress() external view returns (address);

    /**
     * @notice Getter for liquidity gauge address
     * @return liquidity gauge address
     */
    function getLiquidityGaugeAddress() external view returns (address);

    /**
     * @notice Getter for the IBT address
     * @return IBT address
     */
    function getIBTAddress() external view returns (address);

    /**
     * @notice Getter for future apwIBT address
     * @return apwIBT address
     */
    function getAPWIBTAddress() external view returns (address);

    /**
     * @notice Getter for FYT address of a particular period
     * @param _periodIndex period index
     * @return FYT address
     */
    function getFYTofPeriod(uint256 _periodIndex) external view returns (address);

    /* Admin functions*/

    /**
     * @notice Pause registrations and the creation of new periods
     */
    function pausePeriods() external;

    /**
     * @notice Resume registrations and the creation of new periods
     */
    function resumePeriods() external;
}

pragma solidity 0.7.6;

interface IController {
    /* Getters */

    function STARTING_DELAY() external view returns (uint256);

    /* Initializer */

    /**
     * @notice Initializer of the Controller contract
     * @param _admin the address of the admin
     */
    function initialize(address _admin) external;

    /* Future Settings Setters */

    /**
     * @notice Change the delay for starting a new period
     * @param _startingDelay the new delay (+-) to start the next period
     */
    function setPeriodStartingDelay(uint256 _startingDelay) external;

    /**
     * @notice Set the next period switch timestamp for the future with corresponding duration
     * @param _periodDuration the duration of a period
     * @param _nextPeriodTimestamp the next period switch timestamp
     */
    function setNextPeriodSwitchTimestamp(uint256 _periodDuration, uint256 _nextPeriodTimestamp) external;

    /**
     * @notice Set a new factor for the portion of the yield that is claimable when withdrawing funds during an ongoing period
     * @param _periodDuration the duration of the periods
     * @param _claimableYieldFactor the portion of the yield that is claimable
     */
    function setUnlockClaimableFactor(uint256 _periodDuration, uint256 _claimableYieldFactor) external;

    /* User Methods */

    /**
     * @notice Register an amount of IBT from the sender to the corresponding future
     * @param _future the address of the future to be registered to
     * @param _amount the amount to register
     */
    function register(address _future, uint256 _amount) external;

    /**
     * @notice Unregister an amount of IBT from the sender to the corresponding future
     * @param _future the address of the future to be unregistered from
     * @param _amount the amount to unregister
     */
    function unregister(address _future, uint256 _amount) external;

    /**
     * @notice Withdraw deposited funds from APWine
     * @param _future the address of the future to withdraw the IBT from
     * @param _amount the amount to withdraw
     */
    function withdrawLockFunds(address _future, uint256 _amount) external;

    /**
     * @notice Claim FYT of the msg.sender
     * @param _future the future from which to claim the FYT
     */
    function claimFYT(address _future) external;

    /**
     * @notice Get the list of futures from which a user can claim FYT
     * @param _user the user to check
     */
    function getFuturesWithClaimableFYT(address _user) external view returns (address[] memory);

    /**
     * @notice Getter for the registry address of the protocol
     * @return the address of the protocol registry
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Getter for the symbol of the apwIBT of one future
     * @param _ibtSymbol the IBT of the external protocol
     * @param _platform the external protocol name
     * @param _periodDuration the duration of the periods for the future
     * @return the generated symbol of the apwIBT
     */
    function getFutureIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) external pure returns (string memory);

    /**
     * @notice Getter for the symbol of the FYT of one future
     * @param _apwibtSymbol the apwIBT symbol for this future
     * @param _periodDuration the duration of the periods for this future
     * @return the generated symbol of the FYT
     */
    function getFYTSymbol(string memory _apwibtSymbol, uint256 _periodDuration) external view returns (string memory);

    /**
     * @notice Getter for the period index depending on the period duration of the future
     * @param _periodDuration the periods duration
     * @return the period index
     */
    function getPeriodIndex(uint256 _periodDuration) external view returns (uint256);

    /**
     * @notice Getter for beginning timestamp of the next period for the futures with a defined periods duration
     * @param _periodDuration the periods duration
     * @return the timestamp of the beginning of the next period
     */
    function getNextPeriodStart(uint256 _periodDuration) external view returns (uint256);

    /**
     * @notice Getter for the factor of claimable yield when unlocking
     * @param _periodDuration the periods duration
     * @return the factor of claimable yield of the last period
     */
    function getUnlockYieldFactor(uint256 _periodDuration) external view returns (uint256);

    /**
     * @notice Getter for the list of future durations registered in the contract
     * @return the list of futures duration
     */
    function getDurations() external view returns (uint256[] memory);

    /**
     * @notice Register a newly created future in the registry
     * @param _newFuture the address of the new future
     */
    function registerNewFuture(address _newFuture) external;

    /**
     * @notice Unregister a future from the registry
     * @param _future the address of the future to unregister
     */
    function unregisterFuture(address _future) external;

    /**
     * @notice Start all the futures that have a defined periods duration to synchronize them
     * @param _periodDuration the periods duration of the futures to start
     */
    function startFuturesByPeriodDuration(uint256 _periodDuration) external;

    /**
     * @notice Getter for the futures by periods duration
     * @param _periodDuration the periods duration of the futures to return
     */
    function getFuturesWithDuration(uint256 _periodDuration) external view returns (address[] memory);

    /**
     * @notice Register the sender to the corresponding future
     * @param _user the address of the user
     * @param _futureAddress the addresses of the futures to claim the fyts from
     */
    function claimSelectedYield(address _user, address[] memory _futureAddress) external;

    function getRoleMember(bytes32 role, uint256 index) external view returns (address); // OZ ACL getter

    /**
     * @notice Interrupt a future avoiding news registrations
     * @param _future the address of the future to pause
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function pauseFuture(address _future) external;

    /**
     * @notice Resume a future that has been paused
     * @param _future the address of the future to resume
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function resumeFuture(address _future) external;
}

pragma solidity 0.7.6;

interface IFutureVault {
    /**
     * @notice Intializer
     * @param _futureAddress the address of the corresponding future
     * @param _adminAddress the address of the corresponding admin
     */
    function initialize(address _futureAddress, address _adminAddress) external;

    /**
     * @notice Getter for the future address
     * @return the future address linked to this vault
     */
    function getFutureAddress() external view returns (address);

    /**
     * @notice Approve another token to be transfered from this contract by the future
     */
    function approveAdditionalToken(address _tokenAddress) external;
}

pragma solidity 0.7.6;

interface ILiquidityGauge {
    /**
     * @notice Contract Initializer
     * @param _gaugeController the address of the gauge controller
     * @param _future the address of the corresponding future
     */
    function initialize(address _gaugeController, address _future) external;

    /**
     * @notice Register new liquidity added to the future
     * @param _amount the liquidity amount added
     * @dev must be called from the future contract
     */
    function registerNewFutureLiquidity(uint256 _amount) external;

    /**
     * @notice Unregister liquidity withdrawn from to the future
     * @param _amount the liquidity amount withdrawn
     * @dev must be called from the future contract
     */
    function unregisterFutureLiquidity(uint256 _amount) external;

    /**
     * @notice update gauge and user liquidity state then return the new redeemable
     * @param _user the user to update and return the redeemable of
     */
    function updateAndGetRedeemable(address _user) external returns (uint256);

    /**
     * @notice Log an update of the inflated volume
     */
    function updateInflatedVolume() external;

    /**
     * @notice Getter for the last inflated amount
     * @return the last inflated amount
     */
    function getLastInflatedAmount() external view returns (uint256);

    /**
     * @notice Getter for redeemable APWs of one user
     * @param _user the user to check the redeemable APW of
     * @return the amount of redeemable APW
     */
    function getUserRedeemable(address _user) external view returns (uint256);

    /**
     * @notice Register new user liquidity
     * @param _user the user to register the liquidity of
     */
    function registerUserLiquidity(address _user) external;

    /**
     * @notice Delete a user liquidity registration
     * @param _user the user to delete the liquidity registration of
     */
    function deleteUserLiquidityRegistration(address _user) external;

    /**
     * @notice Register new user liquidity
     * @param _sender the user to transfer the liquidity from
     * @param _receiver the user to transfer the liquidity to
     * @param _amount the amount of liquidity to transfer
     */
    function transferUserLiquidty(
        address _sender,
        address _receiver,
        uint256 _amount
    ) external;

    /**
     * @notice Update the current stored liquidity of one user
     * @param _user the user to update the liquidity of
     */
    function updateUserLiquidity(address _user) external;

    /**
     * @notice Remove liquidity from on user address
     * @param _user the user to remove the liquidity from
     * @param _amount the amount of liquidity to remove
     */
    function removeUserLiquidity(address _user, uint256 _amount) external;
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IRegistry {
    /**
     * @notice Initializer of the contract
     * @param _admin the address of the admin of the contract
     */
    function initialize(address _admin) external;

    /* Setters */

    /**
     * @notice Setter for the treasury address
     * @param _newTreasury the address of the new treasury
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice Setter for the gauge controller address
     * @param _newGaugeController the address of the new gauge controller
     */
    function setGaugeController(address _newGaugeController) external;

    /**
     * @notice Setter for the controller address
     * @param _newController the address of the new controller
     */
    function setController(address _newController) external;

    /**
     * @notice Setter for the APW token address
     * @param _newAPW the address of the APW token
     */
    function setAPW(address _newAPW) external;

    /**
     * @notice Setter for the proxy factory address
     * @param _proxyFactory the address of the new proxy factory
     */
    function setProxyFactory(address _proxyFactory) external;

    /**
     * @notice Setter for the liquidity gauge address
     * @param _liquidityGaugeLogic the address of the new liquidity gauge logic
     */
    function setLiquidityGaugeLogic(address _liquidityGaugeLogic) external;

    /**
     * @notice Setter for the APWine IBT logic address
     * @param _APWineIBTLogic the address of the new APWine IBT logic
     */
    function setAPWineIBTLogic(address _APWineIBTLogic) external;

    /**
     * @notice Setter for the APWine FYT logic address
     * @param _FYTLogic the address of the new APWine FYT logic
     */
    function setFYTLogic(address _FYTLogic) external;

    /**
     * @notice Setter for the maths utils address
     * @param _mathsUtils the address of the new math utils
     */
    function setMathsUtils(address _mathsUtils) external;

    /**
     * @notice Setter for the naming utils address
     * @param _namingUtils the address of the new naming utils
     */
    function setNamingUtils(address _namingUtils) external;

    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for the treasury address
     * @return the address of the treasury
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @notice Getter for the gauge controller address
     * @return the address of the gauge controller
     */
    function getGaugeControllerAddress() external view returns (address);

    /**
     * @notice Getter for the DAO address
     * @return the address of the DAO that has admin rights on the APW token
     */
    function getDAOAddress() external returns (address);

    /**
     * @notice Getter for the APW token address
     * @return the address the APW token
     */
    function getAPWAddress() external view returns (address);

    /**
     * @notice Getter for the vesting contract address
     * @return the vesting contract address
     */
    function getVestingAddress() external view returns (address);

    /**
     * @notice Getter for the proxy factory address
     * @return the proxy factory address
     */
    function getProxyFactoryAddress() external view returns (address);

    /**
     * @notice Getter for liquidity gauge logic address
     * @return the liquidity gauge logic address
     */
    function getLiquidityGaugeLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine IBT logic address
     * @return the APWine IBT logic address
     */
    function getAPWineIBTLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine FYT logic address
     * @return the APWine FYT logic address
     */
    function getFYTLogicAddress() external view returns (address);

    /**
     * @notice Getter for math utils address
     * @return the math utils address
     */
    function getMathsUtils() external view returns (address);

    /**
     * @notice Getter for naming utils address
     * @return the naming utils address
     */
    function getNamingUtils() external view returns (address);

    /* Future factory */

    /**
     * @notice Register a new future factory in the registry
     * @param _futureFactory the address of the future factory contract
     * @param _futureFactoryName the name of the future factory
     */
    function addFutureFactory(address _futureFactory, string memory _futureFactoryName) external;

    /**
     * @notice Getter to check if a future factory is registered
     * @param _futureFactory the address of the future factory contract to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFutureFactory(address _futureFactory) external view returns (bool);

    /**
     * @notice Getter for the future factory registered at an index
     * @param _index the index of the future factory to return
     * @return the address of the corresponding future factory
     */
    function getFutureFactoryAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for number of future factories registered
     * @return the number of future factory registered
     */
    function futureFactoryCount() external view returns (uint256);

    /**
     * @notice Getter for name of a future factory contract
     * @param _futureFactory the address of a future factory
     * @return the name of the corresponding future factory contract
     */
    function getFutureFactoryName(address _futureFactory) external view returns (string memory);

    /* Future platform */
    /**
     * @notice Register a new future platform in the registry
     * @param _futureFactory the address of the future factory
     * @param _futurePlatformName the name of the future platform
     * @param _future the address of the future contract logic
     * @param _futureWallet the address of the future wallet contract logic
     * @param _futureVault the name of the future vault contract logic
     */
    function addFuturePlatform(
        address _futureFactory,
        string memory _futurePlatformName,
        address _future,
        address _futureWallet,
        address _futureVault
    ) external;

    /**
     * @notice Getter to check if a future platform is registered
     * @param _futurePlatformName the name of the future platform to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFuturePlatform(string memory _futurePlatformName) external view returns (bool);

    /**
     * @notice Getter for the future platform contracts
     * @param _futurePlatformName the name of the future platform
     * @return the addresses of 0) the future logic 1) the future wallet logic 2) the future vault logic
     */
    function getFuturePlatform(string memory _futurePlatformName) external view returns (address[3] memory);

    /**
     * @notice Getter the total count of future platftroms registered
     * @return the number of future platforms registered
     */
    function futurePlatformsCount() external view returns (uint256);

    /**
     * @notice Getter the list of platforms names registered
     * @return the list of platform names registered
     */
    function getFuturePlatformNames() external view returns (string[] memory);

    /**
     * @notice Remove a future platform from the registry
     * @param _futurePlatformName the name of the future platform to remove from the registry
     */
    function removeFuturePlatform(string memory _futurePlatformName) external;

    /* Futures */
    /**
     * @notice Add a future to the registry
     * @param _future the address of the future to add to the registry
     */
    function addFuture(address _future) external;

    /**
     * @notice Remove a future from the registry
     * @param _future the address of the future to remove from the registry
     */
    function removeFuture(address _future) external;

    /**
     * @notice Getter to check if a future is registered
     * @param _future the address of the future to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFuture(address _future) external view returns (bool);

    /**
     * @notice Getter for the future registered at an index
     * @param _index the index of the future to return
     * @return the address of the corresponding future
     */
    function getFutureAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for number of future registered
     * @return the number of future registered
     */
    function futureCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ERC20 is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external returns (uint8);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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