//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ACPI1.sol";
import "./ACPI2.sol";
import "./ACPI3.sol";
import "./ACPI4.sol";
import "./IACPIMaster.sol";

// github.com/chichke

contract ACPIMaster is IACPIMaster, AccessControl {
    using SafeERC20 for IERC20;

    /**
     * @dev currentACPI is 0 before ACPI start
     * @dev currentACPI is 1 on phase 1
     * @dev currentACPI is 2 on phase 2
     * @dev currentACPI is 3 on phase 3
     * @dev currentACPI is 4 on phase 4
     * @dev currentACPI is 5 when ACPI ends, REG Token price will then be calculated
     */
    uint8 private _currentACPI;

    ACPI private _acpiOne;
    ACPI private _acpiTwo;
    ACPI private _acpiThree;
    ACPI private _acpiFour;

    uint256 private _initialTokenPrice;
    uint256 private _crossChainPrice;
    uint256 private _crossChainPriceUSD;

    bytes32 private constant _ACPI_MODERATOR = keccak256("ACPI_MODERATOR");
    bytes32 private constant _ACPI_MASTER = keccak256("ACPI_MASTER");

    IERC20 private _regToken;

    constructor(address regTokenAddress, address admin, address moderator) {
        _setupRole(_ACPI_MODERATOR, moderator);
        _setupRole(_ACPI_MASTER, address(this));
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        _regToken = IERC20(regTokenAddress);
    }

    function tokenContract() external view override returns (address) {
        return address(_regToken);
    }

    function acpiOneContract() external view override returns (address) {
        return address(_acpiOne);
    }

    function acpiTwoContract() external view override returns (address) {
        return address(_acpiTwo);
    }

    function acpiThreeContract() external view override returns (address) {
        return address(_acpiThree);
    }

    function acpiFourContract() external view override returns (address) {
        return address(_acpiFour);
    }

    function ACPI_MODERATOR() external pure override returns (bytes32) {
        return _ACPI_MODERATOR;
    }

    function ACPI_MASTER() external pure override returns (bytes32) {
        return _ACPI_MASTER;
    }

    function initialTokenPrice() external view override returns (uint256) {
        return _initialTokenPrice;
    }

    function crossChainPriceUSD() external view override returns (uint256) {
        return _crossChainPriceUSD;
    }

    function crossChainPrice() external view override returns (uint256) {
        return _crossChainPrice;
    }

    function getACPI() external view override returns (uint8) {
        return _currentACPI;
    }

    // Generate average price of ACPIs using the initialTokenPrice on three differents blockchains
    function generateCrossChainPrice(uint256 crossChainPrice_, uint256 crossChainPriceUSD_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(
            _currentACPI == 5,
            "ACPI event need to be over to set cross chain price"
        );

        _crossChainPrice = crossChainPrice_;
        _crossChainPriceUSD = crossChainPriceUSD_;
        emit CrossChainPrice(crossChainPrice_, crossChainPriceUSD_);
        return true;
    }

    function totalWins() external override view returns (uint256) {
        return
            _acpiOne.totalWins() +
            _acpiTwo.totalWins() +
            _acpiThree.totalWins() +
            _acpiFour.totalWins();
    }

    function totalReturns() external override view returns (uint256) {
        return _acpiOne.totalReturns();
    }

    function _generatePrice() private {
        _initialTokenPrice =
            (((_acpiOne.acpiPrice() * 15) / 100)) +
            (((_acpiTwo.acpiPrice() * 25) / 100)) +
            (((_acpiThree.acpiPrice() * 35) / 100)) +
            (((_acpiFour.acpiPrice() * 25) / 100));

        emit GeneratedPrice(_initialTokenPrice);
    }

    function setACPI(uint8 newACPI)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(newACPI < 7, "Allowed value is 0-6");
        _currentACPI = newACPI;
        if (newACPI == 5) {
            _generatePrice();
        }

        emit ACPIChanged(newACPI);

        return true;
    }

    function _getACPIWins(address account) private view returns (uint256) {
        return
            _acpiOne.pendingWins(account) +
            _acpiTwo.pendingWins(account) +
            _acpiThree.pendingWins(account) +
            _acpiFour.pendingWins(account);
    }

    function getACPIWins() external view override returns (uint256) {
        return _getACPIWins(_msgSender());
    }

    function _getACPIReturns(address account) private view returns (uint256) {
        return _acpiOne.pendingReturns(account);
    }

    function getACPIReturns() external view override returns (uint256) {
        return _getACPIReturns(_msgSender());
    }

    function _tokenToClaim() private view returns (uint256) {
        require(
            _currentACPI == 6,
            "ACPI event need to be over to claim your tokens"
        );

        uint256 userReturns = _getACPIReturns(_msgSender());
        uint256 userWins = _getACPIWins(_msgSender());

        if (userReturns == 0 && userWins == 0) return 0;

        return userWins + (1 ether * userReturns) / _crossChainPrice;
    }

    function tokenToClaim() external view override returns (uint256) {
        return _tokenToClaim();
    }

    function claimTokens() external override returns (bool) {
        uint256 tokenAmount = _tokenToClaim();
        require(tokenAmount > 0, "You don't have any tokens to claim");

        (
            bool successOne,
            bool successTwo,
            bool successThree,
            bool successFour
        ) = (
                _acpiOne.resetAccount(_msgSender()),
                _acpiTwo.resetAccount(_msgSender()),
                _acpiThree.resetAccount(_msgSender()),
                _acpiFour.resetAccount(_msgSender())
            );

        require(successOne && successTwo && successThree && successFour, "Reset function must not fail");

        _regToken.safeTransfer(_msgSender(), tokenAmount);
        return true;
    }

    function withdrawTokens(address payable vault, uint256 amount)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _regToken.safeTransfer(vault, amount);
        return true;
    }

    function withdraw(address payable vault, uint256[4] calldata amounts)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _acpiOne.withdraw(vault, amounts[0]);
        _acpiTwo.withdraw(vault, amounts[1]);
        _acpiThree.withdraw(vault, amounts[2]);
        _acpiFour.withdraw(vault, amounts[3]);

        return true;
    }

    function withdrawAll(address payable vault)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _acpiOne.withdraw(vault, address(_acpiOne).balance);
        _acpiTwo.withdraw(vault, address(_acpiTwo).balance);
        _acpiThree.withdraw(vault, address(_acpiThree).balance);
        _acpiFour.withdraw(vault, address(_acpiFour).balance);

        return true;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        IERC20(tokenAddress).safeTransfer(_msgSender(), tokenAmount);
        return true;
    }

    function setTokenAddress(address tokenAddress)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _regToken = IERC20(tokenAddress);
        return true;
    }

    function setACPIOne(address acpiAddress)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _acpiOne = ACPI(acpiAddress);
        return true;
    }

    function setACPITwo(address acpiAddress)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _acpiTwo = ACPI(acpiAddress);
        return true;
    }

    function setACPIThree(address acpiAddress)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _acpiThree = ACPI(acpiAddress);
        return true;
    }

    function setACPIFour(address acpiAddress)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _acpiFour = ACPI(acpiAddress);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";
import "./Median.sol";

contract ACPIOne is ACPI {
    address private _highestBidder;
    uint256 private _highestBid;

    uint256 private _bidIncrement = 250 gwei;

    mapping(address => uint256) private _pendingReturns;

    uint256 private _totalReturns;

    // Address => _currentRound => balance
    mapping(address => mapping(uint16 => uint256)) private _balance;

    event RoundWinWithUser(address user, uint256 amount);

    constructor(address acpiMaster) ACPI(acpiMaster, 1) {}

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound() external override onlyModerator onlyCurrentACPI returns (bool) {
        require(_currentRound < _totalRound, "START: All rounds have been done");

        emit RoundWinWithUser(_highestBidder, _highestBid);

        if (_highestBidder != address(0)) {
            // Award Winner
            _pendingWins[_highestBidder] += 1 ether;
            _priceHistory.push(_highestBid);
            _totalWins += 1 ether;
            // Reset state
            _highestBid = 0;
            _highestBidder = address(0);
        }

        _currentRound += 1;
        if (_currentRound == _totalRound) setAcpiPrice();
        return true;
    }

    function bid(uint16 targetRound) external override payable onlyCurrentACPI returns (bool) {
        require(_currentRound < _totalRound, "BID: All rounds have been done");
        require(targetRound == _currentRound, "BID: Current round is over");
        require(
            msg.value + _balance[msg.sender][_currentRound] >=
                _highestBid + _bidIncrement,
            "BID: value is too low"
        );

        if (_highestBidder != address(0)) {
            // Refund the previously highest bidder.
            _pendingReturns[_highestBidder] += _highestBid;
            _totalReturns += _highestBid;
        }

        if (_balance[msg.sender][_currentRound] > 0) {
            _pendingReturns[msg.sender] -= _balance[msg.sender][_currentRound];
            _totalReturns -= _balance[msg.sender][_currentRound];
        }

        _balance[msg.sender][_currentRound] += msg.value;

        _highestBid = _balance[msg.sender][_currentRound];
        _highestBidder = msg.sender;

        emit Bid(msg.sender, _highestBid);

        return true;
    }
    
    /**
     * @dev Set bidIncrement value
     */
    function setBidIncrement(uint256 newValue) external onlyModerator returns (bool) {
        _bidIncrement = newValue;
        return true;
    }

    function pendingReturns(address account) external override view returns (uint256) {
        return _pendingReturns[account];
    }

    function totalReturns() external override view returns (uint256) {
        return _totalReturns;
    }

    function highestBid() external view returns (uint256) {
        return _highestBid;
    }

    function highestBidder() external view returns (address) {
        return _highestBidder;
    }

    function bidIncrement() external view returns (uint256) {
        return _bidIncrement;
    }

    function setAcpiPrice() internal override {
        if (_priceHistory.length == 0) return;

        _acpiPrice = Median.from(_priceHistory);
    }

    function getBid() external view onlyCurrentACPI returns (uint256) {
        return _balance[msg.sender][_currentRound];
    }

    /**
     * @dev Set target user wins to 0 {onlyACPIMaster}
     * note called after a claimTokens from the parent contract
     */
    function resetAccount(address account) external override onlyACPIMaster returns (bool) {
        _pendingReturns[account] = 0;
        _pendingWins[account] = 0;
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";

contract ACPITwo is ACPI {
    // Address => _currentRound => balance
    mapping(address => mapping(uint16 => uint256)) private _balance;

    uint8 private _rewardMultiplicator;

    address[] private _bidders;

    uint256 private _minBid;
    uint256 private _roundPot;
    uint256 private _reward;

    constructor(address acpiMaster) ACPI(acpiMaster, 2) {
        _minBid = 250 gwei;
        _reward = 1 ether;
        _rewardMultiplicator = 0;
    }

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound()
        external
        override
        onlyModerator
        onlyCurrentACPI
        returns (bool)
    {
        require(_currentRound < _totalRound, "START: All rounds have been done");

        if (_bidders.length > 0) {
            _priceHistory.push(_roundPot);

            for (uint256 i = 0; i < _bidders.length; i++) {
                _pendingWins[_bidders[i]] +=
                    (_balance[_bidders[i]][_currentRound] * _reward) /
                    _roundPot;
            }
            delete _bidders;
            emit RoundWin(_roundPot);

            _totalWins += _reward;
            _roundPot = 0;
            _reward += (_reward * _rewardMultiplicator) / 100;
        }

        _currentRound += 1;
        if (_currentRound == _totalRound) setAcpiPrice();

        return true;
    }
    
    /**
     * @dev bid to enter the round {onlyCurrentACPI}
     */
    function bid(uint16 targetRound)
        external
        override
        payable
        onlyCurrentACPI
        returns (bool)
    {
        require(_currentRound < _totalRound, "BID: All rounds have been done");
        require(
            targetRound == _currentRound,
            "BID: Current round is over"
        );

        require(msg.value >= _minBid, "BID: Amount sent should be higher");

        if (_balance[msg.sender][_currentRound] == 0)
            _bidders.push(msg.sender);
        _balance[msg.sender][_currentRound] += msg.value;
        _roundPot += msg.value;

        emit Bid(msg.sender, _balance[msg.sender][_currentRound]);

        return true;
    }

    function roundPot() external view returns (uint256) {
        return _roundPot;
    }

    function reward() external view returns (uint256) {
        return _reward;
    }

    function minBid() external view returns (uint256) {
        return _minBid;
    }

    /**
     * @dev increase reward between each turn in %
     */
    function setRewardMultiplicator(uint8 newValue)
        external
        onlyModerator
        returns (bool)
    {
        _rewardMultiplicator = newValue;
        return true;
    }


    /**
     * @dev increase reward between each turn in %
     */
    function setReward(uint256 newValue)
        external
        onlyModerator
        returns (bool)
    {
        _reward = newValue;
        return true;
    }

    function setMinBid(uint256 newValue) external onlyModerator returns (bool) {
        _minBid = newValue;
        return true;
    }

    function getBid() external view onlyCurrentACPI returns (uint256) {
        return _balance[msg.sender][_currentRound];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";

contract ACPIThree is ACPI {
    uint256 private _bidAmount;

    address[] private _bidders;

    // Address => _currentRound => didBet
    mapping(address => mapping(uint16 => bool)) private _hasAlreadyBid;

    constructor(address acpiMaster) ACPI(acpiMaster, 3) {
        _bidAmount = 250 gwei;
    }

    /**
     * @dev Start round of ACPI ending the last one. {onlyModerator}
     */
    function startRound()
        external
        override
        onlyModerator
        onlyCurrentACPI
        returns (bool)
    {
        require(_currentRound < _totalRound, "START: All rounds have been done");

        if (_bidders.length > 0) {
            _totalWins += 1 ether;
            _priceHistory.push(_bidders.length * _bidAmount);
            for (uint256 i = 0; i < _bidders.length; i++) {
                _pendingWins[_bidders[i]] +=
                    1 ether /
                    _bidders.length;
            }
            delete _bidders;

            emit RoundWin(_bidders.length * _bidAmount);
        }
        _currentRound += 1;
        if (_currentRound == _totalRound) setAcpiPrice();

        return true;
    }

    /**
     * @dev bid to enter the round {onlyCurrentACPI}
     */
    function bid(uint16 targetRound) external override payable onlyCurrentACPI returns (bool) {
        require(_currentRound < _totalRound, "BID: All rounds have been done");
        require(
            targetRound == _currentRound,
            "BID: Current round is over"
        );

        require(
            msg.value == _bidAmount,
            "BID: Amount sent doesn't match expected value"
        );
        require(
            !_hasAlreadyBid[msg.sender][_currentRound],
            "BID: You can only bet once per round"
        );

        _bidders.push(msg.sender);
        _hasAlreadyBid[msg.sender][_currentRound] = true;

        emit Bid(msg.sender, _bidAmount);

        return true;
    }
    
    /**
     * @dev Returns the value each user needs to bet to enter a round.
     */
    function bidAmount() external view returns (uint256) {
        return _bidAmount;
    }

    /**
     * @dev Set the bid amount value {onlyModerator}
     */
    function setBidAmount(uint256 newValue)
        external
        onlyModerator
        returns (bool)
    {
        _bidAmount = newValue;
        return true;
    }

    function getBiddersNumber() external view returns (uint256) {
        return _bidders.length;
    }

    function hasBid() external view returns (bool) {
        return _hasAlreadyBid[msg.sender][_currentRound];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPI.sol";
import "./Median.sol";

contract ACPIFour is ACPI {
    // Address => _currentRound => _currentTurn => didBet
    mapping(address => mapping(uint16 => mapping(uint16 => bool)))
        private _hasAlreadyBid;

    uint8 private _priceIncrease;

    uint16 private _currentTurn;

    uint56 private _rewardPerTurn;
    uint56 private _rewardLeft;

    uint256 private _price;
    uint256 private _lastPrice;
    uint256 private _defaultPrice;

    constructor(address acpiMaster) ACPI(acpiMaster, 4) {
        _priceIncrease = 60; // 60% increase
        _defaultPrice = 0.1 ether;
        _rewardPerTurn = 50;
        _rewardLeft = _rewardPerTurn;
        _price = _defaultPrice;
        _lastPrice = 0 ether;
        _roundTime = 60 * 10;
        _totalRound = 11;
    }

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound()
        external
        override
        onlyModerator
        onlyCurrentACPI
        returns (bool)
    {
        require(
            _currentRound < _totalRound,
            "START: All rounds have been done"
        );

        if (_rewardLeft > 0) {
            if (_currentTurn == 0) {
                _priceHistory.push(_price);
            } else if (_rewardPerTurn - _rewardLeft > 0) {
                _priceHistory.push(
                    (_lastPrice *
                        _rewardPerTurn +
                        _price *
                        (_rewardPerTurn - _rewardLeft)) /
                        (2 * _rewardPerTurn - _rewardLeft)
                );
            } else {
                _priceHistory.push(_lastPrice);
            }

            _currentRound += 1;
            _currentTurn = 0;
            _price = _defaultPrice;
            _lastPrice = _defaultPrice;
        } else {
            _lastPrice = _price;
            _currentTurn += 1;
            _price += (_price * _priceIncrease) / 100;
        }

        emit RoundWin(_price);

        _rewardLeft = _rewardPerTurn;

        if (_currentRound == _totalRound) setAcpiPrice();

        return true;
    }

   function bid(uint16 targetTurn)
        external
        payable
        override
        onlyCurrentACPI
        returns (bool)
    {
        require(_currentRound < _totalRound, "BID: All rounds have been done");
        require(_currentTurn == targetTurn, "BID: Current round is over");

        require(
            !_hasAlreadyBid[msg.sender][_currentRound][_currentTurn],
            "BID: You can only bet once per turn"
        );

        require(
            msg.value == _price,
            "BID: Amount sent doesn't match expected value"
        );

        require(
            _rewardLeft > 0,
            "BID: All tokens have been sold for this turn"
        );

        _hasAlreadyBid[msg.sender][_currentRound][_currentTurn] = true;
        _pendingWins[msg.sender] += 1 ether;
        _totalWins += 1 ether;
        _rewardLeft -= 1;

        emit Bid(msg.sender, _price);

        return true;
    }
    
    /**
     * @dev Price per token in native currency
     */
    function setDefaultPrice(uint256 newValue)
        external
        onlyModerator
        returns (bool)
    {
        _defaultPrice = newValue;
        return true;
    }

    /**
     * @dev Reward for each turn in number of tokens
     */
    function setReward(uint56 newValue) external onlyModerator returns (bool) {
        _rewardPerTurn = newValue;
        _rewardLeft = newValue;
        return true;
    }

    /**
     * @dev Price increase between each turn in %
     */
    function setPriceIncrease(uint8 newValue)
        external
        onlyModerator
        returns (bool)
    {
        _priceIncrease = newValue;
        return true;
    }

    function defaultPrice() external view returns (uint256) {
        return _defaultPrice;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function priceIncrease() external view returns (uint8) {
        return _priceIncrease;
    }

    function rewardLeft() external view returns (uint256) {
        return _rewardLeft;
    }

    function rewardPerTurn() external view returns (uint256) {
        return _rewardPerTurn;
    }

    function currentTurn() external view returns (uint256) {
        return _currentTurn;
    }

    function hasBid() external view returns (bool) {
        return _hasAlreadyBid[msg.sender][_currentRound][_currentTurn];
    }

    function setAcpiPrice() internal override {
        _acpiPrice = Median.from(_priceHistory);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Real Token
 */

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IACPIMaster is IAccessControl {
    /**
     * @dev Emitted when admin input other chains price to calculate crosschainprice
     */
    event CrossChainPrice(uint256 indexed crossChainPrice, uint256 indexed crossChainPriceUSD);

    /**
     * @dev Emitted when acpi ends and contract calculate ACPI price
     */
    event GeneratedPrice(uint256 indexed price);

    event ACPIChanged(uint8 indexed newAcpi);

    function tokenContract() external view returns (address);

    function acpiOneContract() external view returns (address);

    function acpiTwoContract() external view returns (address);

    function acpiThreeContract() external view returns (address);

    function acpiFourContract() external view returns (address);

    function ACPI_MASTER() external view returns (bytes32);

    function ACPI_MODERATOR() external view returns (bytes32);

    function initialTokenPrice() external view returns (uint256);

    function crossChainPrice() external view returns (uint256);

    function crossChainPriceUSD() external view returns (uint256);

    function getACPI() external view returns (uint8);

    function generateCrossChainPrice(uint256 crossChainPrice_, uint256 crossChainPriceUSD_) external returns (bool);

    function setACPI(uint8 newACPI) external returns (bool);

    function getACPIWins() external view returns (uint256);

    function getACPIReturns() external view returns (uint256);

    function totalWins() external view returns (uint256);

    function totalReturns() external view returns (uint256);
    
    function tokenToClaim() external view returns (uint256);

    function claimTokens() external returns (bool);

    function withdrawTokens(address payable vault, uint256 amount)
        external
        returns (bool);

    function withdrawAll(address payable vault)
        external
        returns (bool);

    function withdraw(address payable vault, uint256[4] calldata amounts)
        external
        returns (bool);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external returns (bool);

    function setTokenAddress(address tokenAddress) external returns (bool);

    function setACPIOne(address acpiAddress) external returns (bool);

    function setACPITwo(address acpiAddress) external returns (bool);

    function setACPIThree(address acpiAddress) external returns (bool);


    function setACPIFour(address acpiAddress) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IACPIMaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Abstract contract of the ACPI standard
 */

abstract contract ACPI {
    using SafeERC20 for IERC20;

    IACPIMaster internal _acpiMaster;
    uint256[] internal _priceHistory;

    // User Address => User balance
    mapping(address => uint256) internal _pendingWins;

    uint256 internal _totalWins;

    uint16 internal _currentRound;
    uint16 internal _totalRound;
    uint256 internal _roundTime;

    uint256 internal _acpiPrice;

    uint8 internal _acpiNumber;

    /**
     * @dev Setup Abstract contract must be called only in the child contract
     */
    constructor(address acpiMaster, uint8 acpiNumber) {
        _acpiMaster = IACPIMaster(acpiMaster);
        _acpiNumber = acpiNumber;
        _roundTime = 60 * 60;
        _totalRound = 336;
    }

    modifier onlyCurrentACPI() {
        require(
            _acpiMaster.getACPI() == _acpiNumber,
            "Only Current ACPI Method"
        );
        _;
    }

    modifier onlyACPIMaster() {
        require(
            _acpiMaster.hasRole(_acpiMaster.ACPI_MASTER(), msg.sender),
            "Only ACPI Master Method"
        );
        _;
    }

    modifier onlyModerator() {
        require(
            _acpiMaster.hasRole(_acpiMaster.ACPI_MODERATOR(), msg.sender),
            "Only ACPI Moderator Method"
        );
        _;
    }

    /**
     * @dev Returns the current round.
     */
    function currentRound() external view virtual returns (uint16) {
        return _currentRound;
    }

    /**
     * @dev Returns the amount of rounds per ACPI.
     */
    function totalRound() external view virtual returns (uint16) {
        return _totalRound;
    }

    /**
     * @dev Returns the time between two consecutive round in seconds
     */
    function roundTime() external view virtual returns (uint256) {
        return _roundTime;
    }

    /**
     * @dev Returns the price of the current ACPI
     */
    function acpiPrice() external view virtual returns (uint256) {
        return _acpiPrice;
    }

    /**
     * @dev Returns the pendingWins of {account}
     * pendingWins can be withdrawed at the end of all APCIs
     */
    function pendingWins(address account)
        external
        view
        virtual
        returns (uint256)
    {
        return _pendingWins[account];
    }

    /**
     * @dev Returns the totalWins of ACPI
     */
    function totalWins()
        external
        view
        virtual
        returns (uint256)
    {
        return _totalWins;
    }

   function totalReturns()
        external
        view
        virtual
        returns (uint256)
    {}


    /**
     * @dev Set totalRound value
     */
    function setTotalRound(uint16 newValue)
        external
        virtual
        onlyModerator
        returns (bool)
    {
        _totalRound = newValue;
        return true;
    }

    /**
     * @dev Set time between two consecutive round in seconds
     */
    function setRoundTime(uint256 newValue)
        external
        virtual
        onlyModerator
        returns (bool)
    {
        _roundTime = newValue;
        return true;
    }

    function bid(uint16 targetRound) external payable virtual returns (bool);

    /**
     * @dev Start round of ACPI ending the last one.
     */
    function startRound() external virtual returns (bool);

    /**
     * @dev Set the ACPI price when all the rounds have been done
     */
    function setAcpiPrice() internal virtual {
        if (_priceHistory.length == 0) return;
        uint256 sum = 0;
        for (uint256 i = 0; i < _priceHistory.length; i++) {
            sum += _priceHistory[i] / _priceHistory.length;
        }
        _acpiPrice = sum;
    }

    /**
     * @dev Set target user wins to 0 {onlyACPIMaster}
     * note called after a claimTokens from the parent contract
     */
    function resetAccount(address account)
        external
        virtual
        onlyACPIMaster
        returns (bool)
    {
        _pendingWins[account] = 0;
        return true;
    }

    /**
     * @dev Emitted when a user win a round of any ACPI
     * `amount` is the amount of REG Token awarded
     */
    event RoundWin(uint256 amount);

    /**
     * @dev Emitted when a user bid
     */
    event Bid(address user, uint256 amount);

    /**
     * @dev Withdraw native currency {onlyACPIMaster}
     */
    function withdraw(address payable recipient, uint256 amount)
        external
        virtual
        onlyACPIMaster
        returns (bool)
    {
        require(recipient != address(0), "Can't burn token");

        recipient.transfer(amount);
        return true;
    }

    function pendingReturns(address account)
        external
        view
        virtual
        returns (uint256)
    {}

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        virtual
        onlyACPIMaster
        returns (bool)
    {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

library Median {
    function _swap(
        uint256[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function _sort(
        uint256[] memory array,
        uint256 begin,
        uint256 end
    ) private pure {
        if (begin < end) {
            uint256 j = begin;
            uint256 pivot = array[j];
            for (uint256 i = begin + 1; i < end; ++i) {
                if (array[i] < pivot) {
                    _swap(array, i, ++j);
                }
            }
            _swap(array, begin, j);
            _sort(array, begin, j);
            _sort(array, j + 1, end);
        }
    }

    function from(uint256[] memory array) internal pure returns (uint256) {
        _sort(array, 0, array.length);
        return
            array.length % 2 == 0
                ? Math.average(
                    array[array.length / 2 - 1],
                    array[array.length / 2]
                )
                : array[array.length / 2];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}