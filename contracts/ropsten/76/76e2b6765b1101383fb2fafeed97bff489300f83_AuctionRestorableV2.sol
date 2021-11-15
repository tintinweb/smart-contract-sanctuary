// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "@openzeppelin/contracts-upgradeable/contracts/proxy/Initializable.sol";
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
/** Local Interfaces */
import '../AuctionV2.sol';

contract AuctionRestorableV2 is AuctionV2 {
    using SafeMathUpgradeable for uint256;

    function init(
        uint256 _stepTimestamp,
        address _mainTokenAddress,
        address _stakingAddress,
        address payable _uniswapAddress,
        address payable _recipientAddress,
        address _nativeSwapAddress,
        address _auctionV1Address
    ) external onlyMigrator {
        require(!init_, 'Init is active');
        init_ = true;
        /** Roles */
        _setupRole(CALLER_ROLE, _nativeSwapAddress);
        _setupRole(CALLER_ROLE, _stakingAddress);

        // Timer
        if (start == 0) {
            start = block.timestamp;
        }

        stepTimestamp = _stepTimestamp;

        // Options
        options = Options({
            autoStakeDays: 14,
            referrerPercent: 20,
            referredPercent: 10,
            referralsOn: true,
            discountPercent: 20,
            premiumPercent: 0
        });

        // Addresses
        auctionV1 = IAuctionV1(_auctionV1Address);
        addresses = Addresses({
            mainToken: _mainTokenAddress,
            staking: _stakingAddress,
            uniswap: _uniswapAddress,
            recipient: _recipientAddress
        });
    }

    /** Setter methods for contract migration */
    function setNormalVariables(uint256 _lastAuctionEventId, uint256 _start) external onlyMigrator {
        start = _start;
        lastAuctionEventId = _lastAuctionEventId;
        lastAuctionEventIdV1 = _lastAuctionEventId;
    }

    /** TESTING ONLY */
    function setLastSessionId(uint256 _lastSessionId) external onlyMigrator {
        lastAuctionEventIdV1 = _lastSessionId.sub(1);
        lastAuctionEventId = _lastSessionId;
    }

    function setReservesOf(
        uint256[] calldata sessionIds,
        uint256[] calldata eths,
        uint256[] calldata tokens,
        uint256[] calldata uniswapLastPrices,
        uint256[] calldata uniswapMiddlePrices
    ) external onlyMigrator {
        for (uint256 i = 0; i < sessionIds.length; i = i.add(1)) {
            reservesOf[sessionIds[i]] = AuctionReserves({
                eth: eths[i],
                token: tokens[i],
                uniswapLastPrice: uniswapLastPrices[i],
                uniswapMiddlePrice: uniswapMiddlePrices[i]
            });
        }
    }

    function setAuctionsOf(
        address[] calldata _userAddresses,
        uint256[] calldata _sessionPerAddressCounts,
        uint256[] calldata _sessionIds
    ) external onlyMigrator {
        uint256 sessionIdIdx = 0;
        for (uint256 i = 0; i < _userAddresses.length; i = i + 1) {
            address userAddress = _userAddresses[i];
            uint256 sessionCount = _sessionPerAddressCounts[i];
            uint256[] memory sessionIds = new uint256[](sessionCount);
            for (uint256 j = 0; j < sessionCount; j = j + 1) {
                sessionIds[j] = _sessionIds[sessionIdIdx];
                sessionIdIdx = sessionIdIdx + 1;
            }
            auctionsOf[userAddress] = sessionIds;
        }
    }

    function setExistAuctionsOf(
        uint256 sessionId,
        address[] calldata userAddresses,
        bool[] calldata exists
    ) external onlyMigrator {
        for (uint256 i = 0; i < userAddresses.length; i = i.add(1)) {
            existAuctionsOf[sessionId][userAddresses[i]] = exists[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/** OpenZeppelin Dependencies */
// import "@openzeppelin/contracts-upgradeable/contracts/proxy/Initializable.sol";
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
/** Uniswap */
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
/** Local Interfaces */
import '../../interfaces/IToken.sol';
import './interfaces/IAuctionV2.sol';
import './interfaces/IStakingV2.sol';
import './interfaces/IAuctionV1.sol';

contract AuctionV2 is IAuctionV2, Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    /** Events */
    event Bid(address indexed account, uint256 value, uint256 indexed auctionId, uint256 time);

    event VentureBid(
        address indexed account,
        uint256 ethBid,
        uint256 indexed auctionId,
        uint256 time,
        address[] coins,
        uint256[] amountBought
    );

    event Withdraval(
        address indexed account,
        uint256 value,
        uint256 indexed auctionId,
        uint256 time,
        uint256 stakeDays
    );

    event AuctionIsOver(uint256 eth, uint256 token, uint256 indexed auctionId);

    /** Structs */
    struct AuctionReserves {
        uint256 eth; // Amount of Eth in the auction
        uint256 token; // Amount of Axn in auction for day
        uint256 uniswapLastPrice; // Last kblock.timestampn uniswap price from last bid
        uint256 uniswapMiddlePrice; // Using middle price days to calculate avg price
    }

    struct UserBid {
        uint256 eth; // Amount of ethereum
        address ref; // Referrer address for bid
        bool withdrawn; // Determine withdrawn
    }

    struct Addresses {
        address mainToken; // Axion token address
        address staking; // Staking platform
        address payable uniswap; // Uniswap Main Router
        address payable recipient; // Origin address for excess ethereum in auction
    }

    struct Options {
        uint256 autoStakeDays; // # of days bidder must stake once axion is won from auction
        uint256 referrerPercent; // Referral Bonus %
        uint256 referredPercent; // Referral Bonus %
        bool referralsOn; // If on referrals are used on auction
        uint256 discountPercent; // Discount in comparison to uniswap price in auction
        uint256 premiumPercent; // Premium in comparions to unsiwap price in auction
    }

    /** Roles */
    bytes32 public constant MIGRATOR_ROLE = keccak256('MIGRATOR_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    bytes32 public constant CALLER_ROLE = keccak256('CALLER_ROLE');

    /** Mapping */
    mapping(uint256 => AuctionReserves) public reservesOf; // [day],
    mapping(address => uint256[]) public auctionsOf;
    mapping(uint256 => mapping(address => UserBid)) public auctionBidOf;
    mapping(uint256 => mapping(address => bool)) public existAuctionsOf;

    /** Simple types */
    uint256 public lastAuctionEventId; // Index for Auction
    uint256 public lastAuctionEventIdV1; // Last index for layer 1 auction
    uint256 public start; // Beginning of contract
    uint256 public stepTimestamp; // # of seconds per "axion day" (86400)

    Options public options; // Auction options (see struct above)
    Addresses public addresses; // (See Address struct above)
    IAuctionV1 public auctionV1; // V1 Auction contract for backwards compatibility

    bool public init_; // Unneeded legacy variable to ensure init is only called once.

    mapping(uint256 => mapping(address => uint256)) public autoStakeDaysOf; // NOT USED

    uint256 public middlePriceDays; // When calculating auction price this is used to determine average

    struct VentureToken {
        address coin; // address of token to buy from swap
        uint96 percentage; // % of token to buy NOTE: (On a VCA day all Venture tokens % should add up to 100%)
    }

    struct AuctionData {
        uint8 mode; // 1 = VCA, 0 = Normal Auction
        VentureToken[] tokens; // Tokens to buy in VCA
    }

    AuctionData[7] internal auctions; // 7 values for 7 days of the week
    uint8 internal ventureAutoStakeDays; // # of auto stake days for VCA Auction

    /* UGPADEABILITY: New variables must go below here. */

    /** modifiers */
    modifier onlyCaller() {
        require(hasRole(CALLER_ROLE, _msgSender()), 'Caller is not a caller role');
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), 'Caller is not a manager role');
        _;
    }

    modifier onlyMigrator() {
        require(hasRole(MIGRATOR_ROLE, _msgSender()), 'Caller is not a migrator');
        _;
    }

    /** Update Price of current auction
        Get current axion day
        Get uniswapLastPrice
        Set middlePrice
     */
    function _updatePrice() internal {
        uint256 currentAuctionId = getCurrentAuctionId();

        /** Set reserves of */
        reservesOf[currentAuctionId].uniswapLastPrice = getUniswapLastPrice();
        reservesOf[currentAuctionId].uniswapMiddlePrice = getUniswapMiddlePriceForDays();
    }

    /**
        Get token paths
        Use uniswap to buy tokens back and send to staking platform using (addresses.staking)

        @param tokenAddress {address} - Token to buy from uniswap
        @param amountOutMin {uint256} - Slippage tolerance for router
        @param amount {uint256} - Min amount expected
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
     */
    function _swapEthForToken(
        address tokenAddress,
        uint256 amountOutMin,
        uint256 amount,
        uint256 deadline
    ) private returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(addresses.uniswap).WETH();
        path[1] = tokenAddress;

        return
            IUniswapV2Router02(addresses.uniswap).swapExactETHForTokens{value: amount}(
                amountOutMin,
                path,
                addresses.staking,
                deadline
            )[1];
    }

    /**
        Bid function which routes to either venture bid or bid internal

        @param amountOutMin {uint256[]} - Slippage tolerance for uniswap router 
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
        @param ref {address} - Referrer Address to get % axion from bid
     */
    function bid(
        uint256[] calldata amountOutMin,
        uint256 deadline,
        address ref
    ) external payable {
        uint256 currentDay = getCurrentDay();
        uint8 auctionMode = auctions[currentDay].mode;

        if (auctionMode == 0) {
            bidInternal(amountOutMin[0], deadline, ref);
        } else if (auctionMode == 1) {
            ventureBid(amountOutMin, deadline, currentDay);
        }
    }

    /**
        BidInternal - Buys back axion from uniswap router and sends to staking platform

        @param amountOutMin {uint256} - Slippage tolerance for uniswap router 
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
        @param ref {address} - Referrer Address to get % axion from bid
     */
    function bidInternal(
        uint256 amountOutMin,
        uint256 deadline,
        address ref
    ) internal {
        _saveAuctionData();
        _updatePrice();

        /** Can not refer self */
        require(_msgSender() != ref, 'msg.sender == ref');

        /** Get percentage for recipient and uniswap (Extra function really unnecessary) */
        (uint256 toRecipient, uint256 toUniswap) = _calculateRecipientAndUniswapAmountsToSend();

        /** Buy back tokens from uniswap and send to staking contract */
        _swapEthForToken(addresses.mainToken, amountOutMin, toUniswap, deadline);

        // Get Auction ID
        uint256 auctionId = getCurrentAuctionId();

        /** If referralsOn is true allow to set ref */
        if (options.referralsOn == true) {
            auctionBidOf[auctionId][_msgSender()].ref = ref;
        }

        /** Run common shared functionality between VCA and Normal */
        bidCommon(auctionId);

        /** Transfer any eithereum in contract to recipient address */
        addresses.recipient.transfer(toRecipient);

        /** Send event to blockchain */
        emit Bid(msg.sender, msg.value, auctionId, block.timestamp);
    }

    /**
        BidInternal - Buys back axion from uniswap router and sends to staking platform

        @param amountOutMin {uint256[]} - Slippage tolerance for uniswap router 
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
        @param currentDay {uint256} - currentAuctionId
     */
    function ventureBid(
        uint256[] memory amountOutMin,
        uint256 deadline,
        uint256 currentDay
    ) internal {
        _saveAuctionData();
        _updatePrice();

        /** Get the token(s) of the day */
        VentureToken[] storage tokens = auctions[currentDay].tokens;
        /** Create array to determine amount bought for each token */
        address[] memory coinsBought = new address[](tokens.length);
        uint256[] memory amountsBought = new uint256[](tokens.length);

        /** Loop over tokens to purchase */
        for (uint8 i = 0; i < tokens.length; i++) {
            // Determine amount to purchase based on ethereum bid
            uint256 amountBought;
            uint256 amountToBuy = msg.value.mul(tokens[i].percentage).div(100);

            /** If token is 0xFFfFfF... we buy no token and just distribute the bidded ethereum */
            if (tokens[i].coin != address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)) {
                amountBought = _swapEthForToken(
                    tokens[i].coin,
                    amountOutMin[i],
                    amountToBuy,
                    deadline
                );

                IStakingV2(addresses.staking).updateTokenPricePerShare(
                    msg.sender,
                    addresses.recipient,
                    tokens[i].coin,
                    amountBought
                );
            } else {
                amountBought = amountToBuy;

                IStakingV2(addresses.staking).updateTokenPricePerShare{value: amountToBuy}(
                    msg.sender,
                    addresses.recipient,
                    tokens[i].coin,
                    amountToBuy
                ); // Payable amount
            }

            coinsBought[i] = tokens[i].coin;
            amountsBought[i] = amountBought;
        }

        uint256 currentAuctionId = getCurrentAuctionId();
        bidCommon(currentAuctionId);

        emit VentureBid(
            msg.sender,
            msg.value,
            currentAuctionId,
            block.timestamp,
            coinsBought,
            amountsBought
        );
    }

    /**
        Bid Common - Set common values for bid

        @param auctionId (uint256) - ID of auction
     */
    function bidCommon(uint256 auctionId) internal {
        /** Set auctionBid for bidder */
        auctionBidOf[auctionId][_msgSender()].eth = auctionBidOf[auctionId][_msgSender()].eth.add(
            msg.value
        );

        /** Set existsOf in order to include all auction bids for current user into one */
        if (!existAuctionsOf[auctionId][_msgSender()]) {
            auctionsOf[_msgSender()].push(auctionId);
            existAuctionsOf[auctionId][_msgSender()] = true;
        }

        reservesOf[auctionId].eth = reservesOf[auctionId].eth.add(msg.value);
    }

    /**
        getUniswapLastPrice - Use uniswap router to determine current price based on ethereum
    */
    function getUniswapLastPrice() internal view returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(addresses.uniswap).WETH();
        path[1] = addresses.mainToken;

        uint256 price = IUniswapV2Router02(addresses.uniswap).getAmountsOut(1e18, path)[1];

        return price;
    }

    /**
        getUniswapMiddlePriceForDays
            Use the "last kblock.timestampn price" for the last {middlePriceDays} days to determine middle price by taking an average
     */
    function getUniswapMiddlePriceForDays() internal view returns (uint256) {
        uint256 currentAuctionId = getCurrentAuctionId();

        uint256 index = currentAuctionId;
        uint256 sum;
        uint256 points;

        while (points != middlePriceDays) {
            if (reservesOf[index].uniswapLastPrice != 0) {
                sum = sum.add(reservesOf[index].uniswapLastPrice);
                points = points.add(1);
            }

            if (index == 0) break;

            index = index.sub(1);
        }

        if (sum == 0) return getUniswapLastPrice();
        else return sum.div(points);
    }

    /**
        withdraw - Withdraws an auction bid and stakes axion in staking contract

        @param auctionId {uint256} - Auction to withdraw from
        @param stakeDays {uint256} - # of days to stake in portal
     */
    function withdraw(uint256 auctionId, uint256 stakeDays) external {
        _saveAuctionData();
        _updatePrice();

        // Require the # of days staking > options
        uint8 auctionMode = auctions[auctionId.mod(7)].mode;
        if (auctionMode == 0) {
            require(stakeDays >= options.autoStakeDays, 'Auction: stakeDays < minimum days');
        } else if (auctionMode == 1) {
            require(stakeDays >= ventureAutoStakeDays, 'Auction: stakeDays < minimum days');
        }

        /** Require # of staking days < 5556 */
        require(stakeDays <= 5555, 'Auction: stakeDays > 5555');

        uint256 currentAuctionId = getCurrentAuctionId();
        UserBid storage userBid = auctionBidOf[auctionId][_msgSender()];

        /** Ensure auctionId of withdraw is not todays auction, and user bid has not been withdrawn and eth > 0 */
        require(currentAuctionId > auctionId, 'Auction: Auction is active');
        require(userBid.eth > 0 && userBid.withdrawn == false, 'Auction: Zero bid or withdrawn');

        /** Set Withdrawn to true */
        userBid.withdrawn = true;

        /** Call common withdraw functions */
        withdrawInternal(userBid.ref, userBid.eth, auctionId, currentAuctionId, stakeDays);
    }

    /**
        withdraw - Withdraws an auction bid and stakes axion in staking contract

        @param auctionId {uint256} - Auction to withdraw from
        @param stakeDays {uint256} - # of days to stake in portal
        NOTE: No longer needed, as there is most likely not more bids from v1 that have not been withdraw 
     */
    function withdrawV1(uint256 auctionId, uint256 stakeDays) external {
        _saveAuctionData();
        _updatePrice();

        // Backward compatability with v1 auction
        require(auctionId <= lastAuctionEventIdV1, 'Auction: Invalid auction id');
        /** Ensure stake days > options  */
        require(stakeDays >= options.autoStakeDays, 'Auction: stakeDays < minimum days');
        require(stakeDays <= 5555, 'Auction: stakeDays > 5555');

        uint256 currentAuctionId = getCurrentAuctionId();
        require(currentAuctionId > auctionId, 'Auction: Auction is active');

        // This stops a user from using WithdrawV1 twice, since the bid is put into memory at the end */
        UserBid storage userBid = auctionBidOf[auctionId][_msgSender()];
        require(userBid.eth == 0 && userBid.withdrawn == false, 'Auction: Invalid auction ID');

        (uint256 eth, address ref) = auctionV1.auctionBetOf(auctionId, _msgSender());
        require(eth > 0, 'Auction: Zero balance in auction/invalid auction ID');

        /** Common withdraw functionality */
        withdrawInternal(ref, eth, auctionId, currentAuctionId, stakeDays);

        /** Bring v1 auction bid to v2 */
        auctionBidOf[auctionId][_msgSender()] = UserBid({eth: eth, ref: ref, withdrawn: true});

        auctionsOf[_msgSender()].push(auctionId);
    }

    function withdrawInternal(
        address ref,
        uint256 eth,
        uint256 auctionId,
        uint256 currentAuctionId,
        uint256 stakeDays
    ) internal {
        // Calculate payout for bidder */
        uint256 payout = _calculatePayout(auctionId, eth);
        uint256 uniswapPayoutWithPercent = _calculatePayoutWithUniswap(auctionId, eth, payout);

        /** If auction is undersold, send overage to weekly auction */
        if (payout > uniswapPayoutWithPercent) {
            uint256 nextWeeklyAuction = calculateNearestWeeklyAuction();

            reservesOf[nextWeeklyAuction].token = reservesOf[nextWeeklyAuction].token.add(
                payout.sub(uniswapPayoutWithPercent)
            );

            payout = uniswapPayoutWithPercent;
        }

        /** If referrer is empty simple task */
        if (address(ref) == address(0)) {
            /** Burn tokens and then call external stake on staking contract */
            IToken(addresses.mainToken).burn(address(this), payout);
            IStakingV2(addresses.staking).externalStake(payout, stakeDays, _msgSender());

            emit Withdraval(msg.sender, payout, currentAuctionId, block.timestamp, stakeDays);
        } else {
            /** Burn tokens and determine referral amount */
            IToken(addresses.mainToken).burn(address(this), payout);
            (uint256 toRefMintAmount, uint256 toUserMintAmount) =
                _calculateRefAndUserAmountsToMint(payout);

            /** Add referral % to payout */
            payout = payout.add(toUserMintAmount);

            /** Call external stake for referrer and bidder */
            IStakingV2(addresses.staking).externalStake(payout, stakeDays, _msgSender());

            /** We do not want to mint if the referral address is the dEaD address */
            if (address(ref) != address(0x000000000000000000000000000000000000dEaD)) {
                IStakingV2(addresses.staking).externalStake(toRefMintAmount, 14, ref);
            }

            emit Withdraval(msg.sender, payout, currentAuctionId, block.timestamp, stakeDays);
        }
    }

    /** External Contract Caller functions 
        @param amount {uint256} - amount to add to next dailyAuction
    */
    function callIncomeDailyTokensTrigger(uint256 amount) external override onlyCaller {
        // Adds a specified amount of axion to tomorrows auction
        uint256 currentAuctionId = getCurrentAuctionId();
        uint256 nextAuctionId = currentAuctionId + 1;

        reservesOf[nextAuctionId].token = reservesOf[nextAuctionId].token.add(amount);
    }

    /** Add Reserves to specified Auction
        @param daysInFuture {uint256} - CurrentAuctionId + daysInFuture to send Axion to
        @param amount {uint256} - Amount of axion to add to auction
     */
    function addReservesToAuction(uint256 daysInFuture, uint256 amount)
        external
        override
        onlyCaller
        returns (uint256)
    {
        // Adds a specified amount of axion to a future auction
        require(daysInFuture <= 365, 'AUCTION: Days in future can not be greater then 365');

        uint256 currentAuctionId = getCurrentAuctionId();
        uint256 auctionId = currentAuctionId + daysInFuture;

        reservesOf[auctionId].token = reservesOf[auctionId].token.add(amount);

        return auctionId;
    }

    /** Add reserves to next weekly auction
        @param amount {uint256} - Amount of axion to add to auction
     */
    function callIncomeWeeklyTokensTrigger(uint256 amount) external override onlyCaller {
        // Adds a specified amount of axion to the next nearest weekly auction
        uint256 nearestWeeklyAuction = calculateNearestWeeklyAuction();

        reservesOf[nearestWeeklyAuction].token = reservesOf[nearestWeeklyAuction].token.add(amount);
    }

    /** Calculate functions */
    function calculateNearestWeeklyAuction() public view returns (uint256) {
        uint256 currentAuctionId = getCurrentAuctionId();
        return currentAuctionId.add(uint256(7).sub(currentAuctionId.mod(7)));
    }

    /** Get current day of week
     * EX: friday = 0, saturday = 1, sunday = 2 etc...
     */
    function getCurrentDay() internal view returns (uint256) {
        uint256 currentAuctionId = getCurrentAuctionId();
        return currentAuctionId.mod(7);
    }

    function getCurrentAuctionId() public view returns (uint256) {
        return block.timestamp.sub(start).div(stepTimestamp);
    }

    function calculateStepsFromStart() public view returns (uint256) {
        return block.timestamp.sub(start).div(stepTimestamp);
    }

    /** Determine payout and overage
        @param auctionId {uint256} - Auction id to calculate price from
        @param amount {uint256} - Amount to use to determine overage
        @param payout {uint256} - payout
     */
    function _calculatePayoutWithUniswap(
        uint256 auctionId,
        uint256 amount,
        uint256 payout
    ) internal view returns (uint256) {
        // Get payout for user
        uint256 uniswapPayout = reservesOf[auctionId].uniswapMiddlePrice.mul(amount).div(1e18);

        // Get payout with percentage based on discount, premium
        uint256 uniswapPayoutWithPercent =
            uniswapPayout.add(uniswapPayout.mul(options.discountPercent).div(100)).sub(
                uniswapPayout.mul(options.premiumPercent).div(100)
            );

        if (payout > uniswapPayoutWithPercent) {
            return uniswapPayoutWithPercent;
        } else {
            return payout;
        }
    }

    /** Determine payout based on amount of token and ethereum
        @param auctionId {uint256} - auction to determine payout of
        @param amount {uint256} - amount of axion
     */
    function _calculatePayout(uint256 auctionId, uint256 amount) internal view returns (uint256) {
        return amount.mul(reservesOf[auctionId].token).div(reservesOf[auctionId].eth);
    }

    /** Get Percentages for recipient and uniswap for ethereum bid Unnecessary function */
    function _calculateRecipientAndUniswapAmountsToSend() private returns (uint256, uint256) {
        uint256 toRecipient = msg.value.mul(20).div(100);
        uint256 toUniswap = msg.value.sub(toRecipient);

        return (toRecipient, toUniswap);
    }

    /** Determine amount of axion to mint for referrer based on amount
        @param amount {uint256} - amount of axion

        @return (uint256, uint256)
     */
    function _calculateRefAndUserAmountsToMint(uint256 amount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 toRefMintAmount = amount.mul(options.referrerPercent).div(100);
        uint256 toUserMintAmount = amount.mul(options.referredPercent).div(100);

        return (toRefMintAmount, toUserMintAmount);
    }

    /** Save auction data
        Determines if auction is over. If auction is over set lastAuctionId to currentAuctionId
    */
    function _saveAuctionData() internal {
        uint256 currentAuctionId = getCurrentAuctionId();
        AuctionReserves memory reserves = reservesOf[lastAuctionEventId];

        if (lastAuctionEventId < currentAuctionId) {
            emit AuctionIsOver(reserves.eth, reserves.token, lastAuctionEventId);
            lastAuctionEventId = currentAuctionId;
        }
    }

    function initialize(address _manager, address _migrator) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }

    /** Public Setter Functions */
    function setReferrerPercentage(uint256 percent) external onlyManager {
        options.referrerPercent = percent;
    }

    function setReferredPercentage(uint256 percent) external onlyManager {
        options.referredPercent = percent;
    }

    function setReferralsOn(bool _referralsOn) external onlyManager {
        options.referralsOn = _referralsOn;
    }

    function setAutoStakeDays(uint256 _autoStakeDays) external onlyManager {
        options.autoStakeDays = _autoStakeDays;
    }

    function setVentureAutoStakeDays(uint8 _autoStakeDays) external onlyManager {
        ventureAutoStakeDays = _autoStakeDays;
    }

    function setDiscountPercent(uint256 percent) external onlyManager {
        options.discountPercent = percent;
    }

    function setPremiumPercent(uint256 percent) external onlyManager {
        options.premiumPercent = percent;
    }

    function setMiddlePriceDays(uint256 _middleDays) external onlyManager {
        middlePriceDays = _middleDays;
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    /** VCA Setters */
    /**
        @param _day {uint8} 0 - 6 value. 0 represents Saturday, 6 Represents Friday
        @param _mode {uint8} 0 or 1. 1 VCA, 0 Normal
     */
    function setAuctionMode(uint8 _day, uint8 _mode) external onlyManager {
        auctions[_day].mode = _mode;
    }

    /**
        @param day {uint8} 0 - 6 value. 0 represents Saturday, 6 Represents Friday
        @param coins {address[]} - Addresses to buy from uniswap
        @param percentages {uint8[]} - % of coin to buy, must add up to 100%
     */
    function setTokensOfDay(
        uint8 day,
        address[] calldata coins,
        uint8[] calldata percentages
    ) external onlyManager {
        AuctionData storage auction = auctions[day];

        auction.mode = 1;
        delete auction.tokens;

        uint8 percent = 0;
        for (uint8 i; i < coins.length; i++) {
            auction.tokens.push(VentureToken(coins[i], percentages[i]));
            percent = percentages[i] + percent;
            IStakingV2(addresses.staking).addDivToken(coins[i]);
        }

        require(percent == 100, 'AUCTION: Percentage for venture day must equal 100');
    }

    /** Getter functions */
    function auctionsOf_(address account) external view returns (uint256[] memory) {
        return auctionsOf[account];
    }

    function getAuctionModes() external view returns (uint8[7] memory) {
        uint8[7] memory auctionModes;

        for (uint8 i; i < auctions.length; i++) {
            auctionModes[i] = auctions[i].mode;
        }

        return auctionModes;
    }

    function getTokensOfDay(uint8 _day) external view returns (address[] memory, uint256[] memory) {
        VentureToken[] memory ventureTokens = auctions[_day].tokens;

        address[] memory tokens = new address[](ventureTokens.length);
        uint256[] memory percentages = new uint256[](ventureTokens.length);

        for (uint8 i; i < ventureTokens.length; i++) {
            tokens[i] = ventureTokens[i].coin;
            percentages[i] = ventureTokens[i].percentage;
        }

        return (tokens, percentages);
    }

    function getVentureAutoStakeDays() external view returns (uint8) {
        return ventureAutoStakeDays;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
interface IERC165Upgradeable {
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IToken is IERC20Upgradeable {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAuctionV2 {
    function callIncomeDailyTokensTrigger(uint256 amount) external;

    function callIncomeWeeklyTokensTrigger(uint256 amount) external;

    function addReservesToAuction(uint256 daysInFuture, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IStakingV2 {
    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external;

    function updateTokenPricePerShare(
        address bidderAddress,
        address originAddress,
        address tokenAddress,
        uint256 amountBought
    ) external payable;

    function addDivToken(address tokenAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAuctionV1 {
    function auctionsOf_(address) external view returns (uint256[] memory);

    function auctionBetOf(uint256, address) external view returns (uint256, address);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

