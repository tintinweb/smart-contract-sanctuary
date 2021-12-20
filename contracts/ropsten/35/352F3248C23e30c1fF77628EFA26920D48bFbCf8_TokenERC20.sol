//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IBurnable {
  function burn(uint256) external;
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IBurnable} from "./IBurnable.sol";
import {ISaleSupply} from "./ISaleSupply.sol";
import {IVestingSupply} from "./IVestingSupply.sol";

interface IToken is IBurnable, ISaleSupply, IVestingSupply {}

//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface ISaleSupply {
  function saleSupply() external view returns (uint256);
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IVestingSupply {
  function vestingSupply() external view returns (uint256);
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IToken} from "../interfaces/IToken.sol";

contract TokenERC20 is ERC20, AccessControl, IToken {
  // roles
  bytes32 public constant CAN_MINT_ROLE = keccak256("CAN MINT");
  bytes32 public constant CAN_BURN_ROLE = keccak256("CAN BURN");

  // basic
  uint8 private immutable _decimals;
  uint256 private immutable _cap;

  // tax
  uint8 public immutable tax;

  // sale
  address public immutable saleAddress;
  uint256 private immutable _saleSupply;

  // vesting
  address public immutable vestingAddress;
  uint256 private immutable _vestingSupply;

  // internal
  mapping(address => bool) public internalContracts;

  // errors
  error InvalidDecimals(uint8 decimals_);
  error SupplyGreaterThanCap(
    uint256 supply_,
    uint256 saleSupply_,
    uint256 vestingSupply_,
    uint256 cap_
  );
  error CapExceeded(uint256 amount_, uint256 cap_);
  error InvalidTransactionTax(uint256 percentage_);
  error InvalidAllowance(uint256 allowance_, uint256 amount_);
  error InvalidSaleConfig(address sale_, uint256 saleSupply_);
  error InvalidVestingConfig(address vesting_, uint256 vestingSupply_);

  constructor(
    string memory name_,
    string memory symbol_,
    bytes memory arguments_
  ) ERC20(name_, symbol_) {
    // tx members
    address sender = tx.origin;

    // decode
    (
      uint8 decimals_,
      uint256 cap_,
      uint256 initialSupply_,
      bool canMint_,
      bool canBurn_,
      uint8 tax_,
      address sale_,
      uint256 saleSupply_,
      address vesting_,
      uint256 vestingSupply_
    ) = abi.decode(
        arguments_,
        (uint8, uint256, uint256, bool, bool, uint8, address, uint256, address, uint256)
      );

    // verify decimals
    if (decimals_ > 18) {
      revert InvalidDecimals(decimals_);
    }

    // for uncapped use max uint256
    if (cap_ == 0) {
      cap_ = type(uint256).max;
    }

    // verify supply
    if (initialSupply_ + saleSupply_ + vestingSupply_ > cap_) {
      revert SupplyGreaterThanCap(initialSupply_, saleSupply_, vestingSupply_, cap_);
    }

    // verify transaction tax
    if (tax_ > 100) {
      revert InvalidTransactionTax(tax_);
    }

    if ((saleSupply_ > 0 && sale_ == address(0x0)) || (saleSupply_ == 0 && sale_ != address(0x0))) {
      revert InvalidSaleConfig(sale_, saleSupply_);
    }

    if (
      (vestingSupply_ > 0 && vesting_ == address(0x0)) ||
      (vestingSupply_ == 0 && vesting_ != address(0x0))
    ) {
      revert InvalidVestingConfig(vesting_, vestingSupply_);
    }

    // token
    _decimals = decimals_;
    _cap = cap_;
    tax = tax_;

    // mint supply
    if (initialSupply_ > 0) {
      _mint(sender, initialSupply_);
    }

    // setup sale
    saleAddress = sale_;
    _saleSupply = saleSupply_;
    if (sale_ != address(0x0)) {
      // internal
      internalContracts[sale_] = true;

      // mint
      _mint(sale_, saleSupply_);
    } else {
      if (saleSupply_ != 0) revert InvalidSaleConfig(sale_, saleSupply_);
    }

    // setup vesting
    vestingAddress = vesting_;
    _vestingSupply = vestingSupply_;
    if (vesting_ != address(0x0)) {
      // internal
      internalContracts[vesting_] = true;

      // mint
      _mint(vesting_, vestingSupply_);
    } else {
      if (vestingSupply_ != 0) revert InvalidVestingConfig(vesting_, vestingSupply_);
    }

    // base role setup
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setRoleAdmin(CAN_MINT_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(CAN_BURN_ROLE, DEFAULT_ADMIN_ROLE);

    // mint role
    if (canMint_) {
      _setupRole(CAN_MINT_ROLE, sender);
    }

    // burn role
    if (canBurn_) {
      _setupRole(CAN_BURN_ROLE, sender);
    }

    // burn for sale
    if (sale_ != address(0x0)) {
      _setupRole(CAN_BURN_ROLE, sale_);
    }
  }

  // getters
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  function saleSupply() external view override returns (uint256) {
    return _saleSupply;
  }

  function vestingSupply() external view override returns (uint256) {
    return _vestingSupply;
  }

  // mint & burn
  function mint(address account, uint256 amount) external onlyRole(CAN_MINT_ROLE) {
    _mint(account, amount);
  }

  function burn(uint256 amount) external override onlyRole(CAN_BURN_ROLE) {
    _burn(msg.sender, amount);
  }

  function _mint(address account, uint256 amount) internal virtual override {
    uint256 sum = ERC20.totalSupply() + amount;
    if (sum > _cap) {
      revert CapExceeded(sum, _cap);
    }
    super._mint(account, amount);
  }

  // transfer
  function _calculateTax(uint256 amount) internal view returns (uint256, uint256) {
    uint256 burned = (amount * tax) / 100;
    uint256 untaxed = amount - burned;
    return (burned, untaxed);
  }

  function isNotInternalTransfer() private view returns (bool) {
    return !internalContracts[msg.sender];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    if (tax > 0 && isNotInternalTransfer()) {
      // calculate tax
      (uint256 burned, uint256 untaxed) = _calculateTax(amount);

      // burn and transfer
      _burn(msg.sender, burned);
      return super.transfer(recipient, untaxed);
    } else {
      return super.transfer(recipient, amount);
    }
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    if (tax > 0 && isNotInternalTransfer()) {
      // calculate tax
      (uint256 burned, uint256 untaxed) = _calculateTax(amount);

      // allowance for burn
      uint256 currentAllowance = allowance(sender, _msgSender());
      if (currentAllowance < amount) {
        revert InvalidAllowance(currentAllowance, amount);
      }
      unchecked {
        _approve(sender, _msgSender(), currentAllowance - burned);
      }

      // burn and transfer
      _burn(sender, burned);
      return super.transferFrom(sender, recipient, untaxed);
    } else {
      return super.transferFrom(sender, recipient, amount);
    }
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Configurable} from "../utils/Configurable.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

contract Whitelist is AccessControl, Configurable, IWhitelist {
  // roles
  bytes32 public constant CAN_MANAGE_ROLE = keccak256("CAN MANAGE");

  // structs
  struct Member {
    address account;
    uint256 allowance; // zero allowance -> inf allowance
  }
  struct Whitelisted {
    uint256 allowance; // zero allowance -> not whitelisted
    uint256 used;
  }

  // storage
  mapping(address => Whitelisted) public members;
  address public sale;

  // events
  event AccountNotWhitelisted(address account);
  event NotEnoughAllowance(address account, uint256 allowance, uint256 amount);
  event WhitelistUpdated(uint256 created, uint256 updated, uint256 deleted);

  // errors
  error InvalidAccount(address account, uint8 i);
  error AccountAlreadyWhitelisted(address account);
  error AccountDoesNotExist(address account);
  error InvalidSender(address account);
  error UsedBiggerThanAllowance(address account, uint256 used, uint256 newAllowance);

  modifier onlySale() {
    address sender = msg.sender;
    if (sender != sale) {
      revert InvalidSender(sender);
    }
    _;
  }

  constructor(bytes memory arguments_) {
    // tx members
    address sender = tx.origin;

    // decode
    Member[] memory members_ = abi.decode(arguments_, (Member[]));

    for (uint8 i = 0; i < members_.length; i++) {
      // member
      Member memory member = members_[i];

      // check address
      if (member.account == address(0x0)) {
        revert InvalidAccount(member.account, i);
      }
      if (member.allowance == 0) {
        member.allowance = type(uint256).max;
      }

      members[member.account] = Whitelisted(member.allowance, 0);
    }

    // role setup
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setRoleAdmin(CAN_MANAGE_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(CAN_MANAGE_ROLE, sender);
  }

  function configure(address sale_)
    external
    onlyInState(State.UNCONFIGURED)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // storage
    sale = sale_;

    // state
    state = State.CONFIGURED;
  }

  function update(
    Member[] memory toCreate,
    Member[] memory toUpdate,
    address[] memory toDelete
  ) external onlyRole(CAN_MANAGE_ROLE) {
    // bulk create
    for (uint8 i = 0; i < toCreate.length; i++) {
      // create member if not exists
      Member memory member = toCreate[i];
      if (members[member.account].allowance != 0) {
        revert AccountAlreadyWhitelisted(member.account);
      }
      if (member.allowance == 0) {
        member.allowance = type(uint256).max;
      }

      // optional allowance, used 0
      members[member.account] = Whitelisted(member.allowance, 0);
    }

    // bulk update
    for (uint8 i = 0; i < toUpdate.length; i++) {
      // update member if exists
      Member memory member = toUpdate[i];
      if (members[member.account].allowance == 0) {
        revert AccountDoesNotExist(member.account);
      }

      // zero allowance in input is max allowance
      if (member.allowance == 0) {
        member.allowance = type(uint256).max;
      }

      // revert if allowance limited and smaller than used
      uint256 used = members[member.account].used;
      if (used > member.allowance) {
        revert UsedBiggerThanAllowance(member.account, used, member.allowance);
      }

      // allowance updated, preserve used
      members[member.account].allowance = member.allowance;
    }

    // bulk delete
    for (uint8 i = 0; i < toDelete.length; i++) {
      // delete member if exists
      address account = toDelete[i];
      if (members[account].allowance == 0) {
        revert AccountDoesNotExist(account);
      }

      // empty storage
      members[account] = Whitelisted(0, 0);
    }

    // event
    emit WhitelistUpdated(toCreate.length, toUpdate.length, toDelete.length);
  }

  function use(uint256 amount)
    external
    override
    onlyInState(State.CONFIGURED)
    onlySale
    returns (bool)
  {
    // tx.members
    address sender = tx.origin;

    // member
    Whitelisted memory whitelisted = members[sender];

    // not whitelisted
    if (whitelisted.allowance == 0) {
      emit AccountNotWhitelisted(sender);
      return false;
    }

    // limit not enough
    uint256 allowance = whitelisted.allowance;
    if (allowance < whitelisted.used + amount) {
      emit NotEnoughAllowance(sender, allowance, amount);
      return false;
    }

    // storage and return
    members[sender].used += amount;
    return true;
  }
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

abstract contract Configurable {
  // enum
  enum State {
    UNCONFIGURED,
    CONFIGURED
  }

  // storage
  State public state = State.UNCONFIGURED;

  // modifier
  modifier onlyInState(State _state) {
    require(state == _state, "Invalid state");
    _;
  }
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWhitelist {
  function use(uint256) external returns (bool);
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Configurable} from "../utils/Configurable.sol";
import {ITokenERC20} from "../interfaces/ITokenERC20.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

contract Sale is AccessControl, Configurable {
  // stage
  struct Stage {
    uint256 supply; // stage supply
    uint256 rate; // tokens per wei (example: value 20 -> for 1 ETH gives 20 tokens)
    uint256 minAlloc; // minimum wei invested
    uint256 openingTime;
    uint256 closingTime;
  }
  struct Phase {
    Stage stage;
    uint256 soldTokens;
    uint256 weiRaised;
  }

  // storage
  Phase[] public stages;
  ITokenERC20 public erc20;
  IWhitelist public whitelist;

  address payable public immutable wallet;
  uint256 public immutable supply; // sale supply
  uint256 public immutable hardCap; // ether value of sale supply
  uint256 public weiRaised;

  // events
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );
  event TokenBurn(uint256 amount);

  // basic errors
  error SaleNotActive(uint256 timestamp);
  error SaleNotFinished(uint256 timestamp);
  error NoTokensLeft();

  // sale errors
  error InvalidConfig(uint256 supply, uint256 cap, address wallet, uint256 stagesCount);
  error SupplyMismatch(uint256 supply, uint256 totalSupply);
  error ValueMismatch(uint256 hardCap, uint256 totalValue);

  // stage errors
  error InvalidStageConfig(uint256 rate, uint8 i);
  error StartDateInThePast(uint256 start, uint256 now_, uint8 i);
  error StartDateNotBeforeEndDate(uint256 start, uint256 end, uint8 i);
  error SupplySmallerThanRate(uint256 supply, uint256 rate, uint8 i);

  // configuration errors
  error SupplyConfigurationMishmatch(uint256 saleSupply, uint256 supply);
  error BalanceNotEqualSupply(uint256 balance, uint256 supply);

  // buy errors
  error InvalidReceiver(address receiver);
  error NotEnoughBigInvestment(uint256 amount, uint256 minimum);
  error HardCapExceeded(uint256 amount, uint256 hardCap);
  error StageSupplyDrained(uint256 amount, uint256 supply);
  error WhitelistNotPassed(address member, uint256 weiAmount);

  // modifiers
  modifier onlyWhenActive() {
    getCurrentStage();
    _;
  }
  modifier onlyWhenFinished() {
    uint256 timestamp = block.timestamp;
    if (timestamp < closingTime()) {
      revert SaleNotFinished(timestamp);
    }
    _;
  }

  constructor(bytes memory arguments_) {
    // tx members
    address sender = tx.origin;

    // decode
    (uint256 supply_, uint256 hardCap_, address wallet_, Stage[] memory stages_) = abi.decode(
      arguments_,
      (uint256, uint256, address, Stage[])
    );

    // sale config
    uint256 stagesCount = stages_.length;
    if (
      supply_ == 0 ||
      hardCap_ == 0 ||
      wallet_ == address(0x0) ||
      stagesCount == 0 ||
      stagesCount > 16
    ) {
      revert InvalidConfig(supply_, hardCap_, wallet_, stages_.length);
    }

    uint256 totalSupply;
    uint256 totalValue;
    uint256 lastClosingTime = block.timestamp;
    for (uint8 i = 0; i < stages_.length; i++) {
      Stage memory stage = stages_[i];

      // stage config
      if (stage.rate == 0) {
        revert InvalidStageConfig(stage.rate, i);
      }

      // stage opening
      if (stage.openingTime < lastClosingTime) {
        revert StartDateInThePast(stage.openingTime, lastClosingTime, i);
      }

      // stage closing
      if (stage.openingTime >= stage.closingTime) {
        revert StartDateNotBeforeEndDate(stage.openingTime, stage.closingTime, i);
      }

      // requirement of OpenZeppelin crowdsale from V2
      // FIXME: to discuss if support for other rates is needed
      // 1 token (decimals 0) -> MAX 1 wei
      // 1 token (decimals 1) -> MAX 10 wei
      // 1 token (decimals 5) -> MAX 100 000 wei
      // 1 MLN token (decimals 0) -> MAX 1 MLN wei
      if (stage.supply < stage.rate) {
        revert SupplySmallerThanRate(stage.supply, stage.rate, i);
      }

      // increment counters
      totalValue += stage.supply / stage.rate;
      lastClosingTime = stage.closingTime;
      totalSupply += stage.supply;

      // storage
      stages.push(Phase(stage, 0, 0));
    }

    // sum of stages supply
    if (supply_ != totalSupply) {
      revert SupplyMismatch(supply_, totalSupply);
    }

    // sum of stages hard caps
    if (hardCap_ != totalValue) {
      revert ValueMismatch(hardCap_, totalValue);
    }

    // save storage
    supply = supply_;
    hardCap = hardCap_;
    wallet = payable(wallet_);

    // base role
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
  }

  function configure(address erc20_, address whitelist_)
    external
    onlyInState(State.UNCONFIGURED)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // storage
    erc20 = ITokenERC20(erc20_);
    whitelist = IWhitelist(whitelist_);

    // check supply vs params
    uint256 saleSupply = erc20.saleSupply();
    if (saleSupply != supply) {
      revert SupplyConfigurationMishmatch(saleSupply, supply);
    }

    // check configuration vs balance
    uint256 balance = erc20.balanceOf(address(this));
    if (saleSupply != balance) {
      revert BalanceNotEqualSupply(balance, saleSupply);
    }

    // state
    state = State.CONFIGURED;
  }

  function buyTokens(address _beneficiary)
    external
    payable
    onlyInState(State.CONFIGURED)
    onlyWhenActive
  {
    // current state
    uint8 currentStage = getCurrentStage();
    Phase memory phase = stages[currentStage];

    // tx members
    uint256 weiAmount = msg.value;

    // validate receiver
    if (_beneficiary == address(0)) {
      revert InvalidReceiver(_beneficiary);
    }

    // check min invesment
    if (weiAmount < phase.stage.minAlloc) {
      revert NotEnoughBigInvestment(weiAmount, phase.stage.minAlloc);
    }

    // check hardcap
    uint256 raised = weiRaised + weiAmount;
    if (raised > hardCap) {
      revert HardCapExceeded(raised, hardCap);
    }

    // calculate token amount to be sold
    uint256 tokenAmount = weiAmount * phase.stage.rate;

    // check supply
    uint256 sold = phase.soldTokens + tokenAmount;
    if (sold > phase.stage.supply) {
      revert StageSupplyDrained(sold, phase.stage.supply);
    }

    // use whitelist
    if (address(whitelist) != address(0x0)) {
      bool success = whitelist.use(weiAmount);
      if (!success) {
        revert WhitelistNotPassed(msg.sender, weiAmount);
      }
    }

    // update state
    weiRaised = raised;
    stages[currentStage].weiRaised += weiAmount;
    stages[currentStage].soldTokens = sold;

    // store profits
    wallet.transfer(weiAmount);

    // send tokens
    erc20.transfer(_beneficiary, tokenAmount);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
  }

  receive() external payable {
    this.buyTokens(msg.sender);
  }

  function stageCount() external view returns (uint256) {
    // frontend view
    return stages.length;
  }

  function rate() external view returns (uint256) {
    // rate from current stage
    return stages[getCurrentStage()].stage.rate;
  }

  function openingTime() external view returns (uint256) {
    // opening time of first stage
    return stages[0].stage.openingTime;
  }

  function closingTime() public view returns (uint256) {
    // closing time of last stage
    return stages[getLastStage()].stage.closingTime;
  }

  function tokensLeft() public view onlyInState(State.CONFIGURED) returns (uint256) {
    // tokens left on sale contract
    return erc20.balanceOf(address(this));
  }

  function getLastStage() internal view returns (uint8) {
    return uint8(stages.length - 1);
  }

  function getCurrentStage() public view returns (uint8) {
    // tx.members
    uint256 timestamp = block.timestamp;

    // return active stage
    for (uint8 i = 0; i < stages.length; i++) {
      if (stages[i].stage.openingTime <= timestamp && timestamp <= stages[i].stage.closingTime) {
        return i;
      }
    }

    // revert if no active stage
    revert SaleNotActive(timestamp);
  }

  function hasClosed() external view returns (bool) {
    // OpenZeppelin standard method
    return block.timestamp > closingTime();
  }

  function finalize() external onlyInState(State.CONFIGURED) onlyWhenFinished {
    // check tokens left
    uint256 tokenAmount = tokensLeft();

    // revert if no tokens left
    if (tokenAmount == 0) {
      revert NoTokensLeft();
    }

    // burn remaining tokens
    erc20.burn(tokenAmount);
    emit TokenBurn(tokenAmount);
  }
}

//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IToken} from "./IToken.sol";

interface ITokenERC20 is IERC20, IToken {}

//Made with Student Coin Terminal
//SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Configurable} from "../utils/Configurable.sol";
import {ITokenERC20} from "../interfaces/ITokenERC20.sol";

contract Vesting is AccessControl, Configurable {
  // structs
  struct Shareholder {
    address account;
    uint8 shares;
  }
  struct Member {
    Shareholder shareholder;
    uint256 collected;
    uint8 lastCheckpoint;
  }

  // storage
  ITokenERC20 public erc20;
  mapping(address => Member) public members;

  // config
  uint256 public immutable supply;
  uint8 public immutable duration; // 1-60
  uint256 public startTime;

  // events
  event Collected(address sender, uint256 amount, uint8 lastCheckpoint, uint8 newCheckpoint);

  // errors
  error InvalidConfig(uint256 supply_, uint8 duration_);
  error SharesNotInTheRange(address account, uint256 shares);
  error SharesNotSumTo100(uint256 total);
  error InvalidMember(address member);
  error NothingToCollect(address member, uint8 collected, uint8 checkpoint);
  error SupplyMismatch(uint256 balance, uint256 declared);
  error ConfigurationBalanceMishmatch(uint256 amount, uint256 balance);

  // modifiers
  modifier onlyMember() {
    if (members[msg.sender].shareholder.shares == 0) {
      revert InvalidMember(msg.sender);
    }
    _;
  }

  constructor(bytes memory arguments_) {
    // tx members
    address sender = tx.origin;

    (uint256 supply_, uint8 duration_, Shareholder[] memory shareholders_) = abi.decode(
      arguments_,
      (uint256, uint8, Shareholder[])
    );

    // check supply and duration
    if (supply_ == 0 || duration_ == 0 || duration_ > 60) {
      revert InvalidConfig(supply_, duration_);
    }

    // check members
    uint8 totalShares = 0;
    for (uint8 i = 0; i < shareholders_.length; i++) {
      Member memory member = Member(shareholders_[i], 0, 0);
      uint8 shares = member.shareholder.shares;
      address account = member.shareholder.account;

      // check address and individual shares
      if (account == address(0x0)) {
        revert InvalidMember(account);
      }
      if (shares == 0 || shares > 100) {
        revert SharesNotInTheRange(account, shares);
      }

      members[account] = member;
      totalShares += shares;
    }

    // check sum of shares
    if (totalShares != 100) {
      revert SharesNotSumTo100(totalShares);
    }

    // storage
    supply = supply_;
    duration = duration_;

    // base role
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
  }

  function configure(address erc20_)
    external
    onlyInState(State.UNCONFIGURED)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // tx.members
    startTime = block.timestamp;

    // token
    erc20 = ITokenERC20(erc20_);

    // check balance vs supply
    uint256 balance = erc20.balanceOf(address(this));
    if (balance != supply) {
      revert SupplyMismatch(balance, supply);
    }

    // check configuration vs balance
    uint256 vestingSupply = erc20.vestingSupply();
    if (vestingSupply != balance) {
      revert ConfigurationBalanceMishmatch(vestingSupply, balance);
    }

    // state
    state = State.CONFIGURED;
  }

  function endTime() public view onlyInState(State.CONFIGURED) returns (uint256) {
    // start time + X months (where X is duration)
    return startTime + (30 days * duration);
  }

  function currentCheckpoint() public view onlyInState(State.CONFIGURED) returns (uint8) {
    // not started case -> 0
    if (startTime > block.timestamp) return 0;

    // checkpoint = (now - start time) / month
    uint256 checkpoint = (block.timestamp - startTime) / 30 days;

    // checkpoint or cap to duration -> 0 ~ duration
    return uint8(Math.min(checkpoint, uint256(duration)));
  }

  function collect() external onlyInState(State.CONFIGURED) onlyMember {
    // tx.members
    address sender = msg.sender;

    // checkpoints
    uint8 checkpoint = currentCheckpoint();
    uint8 lastCheckpoint = members[sender].lastCheckpoint;

    // revert if nothing to collect
    if (checkpoint <= lastCheckpoint) {
      revert NothingToCollect(sender, lastCheckpoint, checkpoint);
    }

    uint256 amount;
    if (checkpoint == duration) {
      // calculate remaining amount
      amount = (supply * members[sender].shareholder.shares) / 100 - members[sender].collected;
    } else {
      // current checkpoint - last checkpoint
      uint8 checkpointsToCollect = checkpoint - lastCheckpoint;

      // single batch amount
      uint256 partialSupply = supply / duration;

      // shares of single batch
      uint256 singleCheckpointAmount = (partialSupply * members[sender].shareholder.shares) / 100;

      // amount based on shares and checkpoints
      amount = checkpointsToCollect * singleCheckpointAmount;
    }

    // update state and transfer
    members[sender].lastCheckpoint = checkpoint;
    members[sender].collected += amount;
    erc20.transfer(sender, amount);

    // events
    emit Collected(sender, amount, lastCheckpoint, checkpoint);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

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