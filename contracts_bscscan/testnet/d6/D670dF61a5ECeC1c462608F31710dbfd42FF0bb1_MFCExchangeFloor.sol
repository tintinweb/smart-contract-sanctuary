// SPDX-License-Identifier: MIT
//
// MFCExchangeFloor [BUSD_MFC]
//

pragma solidity ^0.8.4;

import "./lib/token/BEP20/IBEP20.sol";
import "./token/MFCToken.sol";
import "./lib/utils/Context.sol";
import "./treasury/BUSDT.sol";

contract MFCExchangeFloor is Context {

  uint256 public constant MINIMUM_SWAP_IN_BUSD = 100000000000000000000;
  uint256 public constant MFC_FEE = 20000000000000000;
  uint256 public constant BUSD_FEE = 20000000000000000;
  uint256 public constant MULTIPLIER = 10**18;

  MFCToken private _mfc;
  IBEP20 private _busd;
  BUSDT private _busdt;
  address private _mfcTreasuryAddress;
  address private _mfcCoTreasuryAddress;
  address private _busdTreasuryAddress;
  address private _busdComptrollerAddress;
  address private _mfcExchangeCapAddress;
  address private _deployer;
  uint256 private _mfcCirculation = 0;
  uint256 private _initialPrice = 0;

  event TradeOffer(address buyer, uint256 price, uint256 sellerQuantity, uint256 buyerQuantity, uint256 timestamp);

  constructor(
    address mfcAddress_,
    address busdAddress_,
    address mfcTreasuryAddress_,
    address mfcCoTreasuryAddress_,
    address busdComptrollerAddress_,
    uint256 initialPrice_
  ) {
    _mfc = MFCToken(mfcAddress_);
    _busd = IBEP20(busdAddress_);
    _mfcTreasuryAddress = mfcTreasuryAddress_;
    _mfcCoTreasuryAddress = mfcCoTreasuryAddress_;
    _busdComptrollerAddress = busdComptrollerAddress_;
    _initialPrice = initialPrice_;
    _deployer = _msgSender();
  }

  modifier onlyDeployer() {
    require(_deployer == _msgSender(), "Caller is not the deployer");
    _;
  }

  function getMfcCirculation() external view returns (uint256) {
    return _mfcCirculation;
  }

  function getInitialPrice() external view returns (uint256) {
    return _initialPrice;
  }

  function setBusdTreasuryAddress(address _address) external onlyDeployer {
    require(_busdTreasuryAddress == address(0), "Already set");
    _busdt = BUSDT(_address);
    _busdTreasuryAddress = _address;
  }

  function setExchangeCapAddress(address _address) external onlyDeployer {
    require(_mfcExchangeCapAddress == address(0), "Already set");
    _mfcExchangeCapAddress = _address;
  }

  function setInitialPrice(uint256 price) external onlyDeployer {
    require(_mfcCirculation == 0, "Can no longer set");
    _initialPrice = price;
  }

  function increaseMfcCirculation(uint256 quantity) external {
    require(_mfcExchangeCapAddress == _msgSender(), "No permission");
    _increaseMfcCirculation(quantity);
  }

  function getPrice() external view returns (uint256) {
    return _getPrice();
  }

  function getAmountOut(uint256 quantity) external view returns (uint256) {
    return _getAmountOut(quantity);
  }

  function tradeOffer(uint256 quantity, uint256 minimumOut) external {
    require(quantity > 0, "Invalid quantity");
    _tradeOffer(quantity, minimumOut);
  }

  function tradeOffer(uint256 quantity, uint256 minimumOut, uint8 v, bytes32 r, bytes32 s) external {
    require(quantity > 0, "Invalid quantity");
    _mfc.permit(_msgSender(), address(this), quantity, v, r, s);
    _tradeOffer(quantity, minimumOut);
  }

  function _tradeOffer(uint256 quantity, uint256 minimumOut) private {
    require(_mfc.allowance(_msgSender(), address(this)) >= quantity, "Insufficient allowance");
    require(_mfc.balanceOf(_msgSender()) >= quantity, "Insufficient balance");
    uint256 price = _getPrice();
    uint256 amountOut = _getAmountOut(quantity);
    require(amountOut >= minimumOut, "Insufficient output amount");
    require(amountOut >= MINIMUM_SWAP_IN_BUSD, "Minimum swap not reached");

    uint256 mfcFee = quantity * MFC_FEE / MULTIPLIER;
    uint256 sellerReceives = quantity - mfcFee;
    uint256 busdFee = amountOut * BUSD_FEE / MULTIPLIER;
    uint256 buyerReceives = amountOut - busdFee;

    _mfc.transferFrom(_msgSender(), _mfcTreasuryAddress, mfcFee);
    _mfc.transferFrom(_msgSender(), _mfcCoTreasuryAddress, sellerReceives);
    _busdt.withdrawTo(_busdComptrollerAddress, busdFee);
    _busdt.withdrawTo(_msgSender(), buyerReceives);
    _decreaseMfcCirculation(quantity);

    emit TradeOffer(_msgSender(), price, amountOut, quantity, block.timestamp);
  }

  function _getAmountOut(uint256 quantity) private view returns (uint256) {
    uint256 busdBalance = _busd.balanceOf(_busdTreasuryAddress);
    uint256 amountOut = 0;
    if (_mfcCirculation > 0) {
      amountOut = quantity * busdBalance / _mfcCirculation;
    } else {
      amountOut = quantity * MULTIPLIER / _initialPrice;
    }
    if (amountOut > busdBalance) {
      amountOut = busdBalance;
    }
    return amountOut;
  }

  function _getPrice() private view returns (uint256) {
    uint256 busdBalance = _busd.balanceOf(_busdTreasuryAddress);
    if (busdBalance == 0) {
      return 0;
    }
    if (_mfcCirculation > 0) {
      return MULTIPLIER * _mfcCirculation / busdBalance;
    } else {
      return _initialPrice;
    }
  }

  function _increaseMfcCirculation(uint256 quantity) private {
    _mfcCirculation += quantity;
  }

  function _decreaseMfcCirculation(uint256 quantity) private {
    if (quantity > _mfcCirculation) {
      _mfcCirculation = 0;
    } else {
      _mfcCirculation -= quantity;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../lib/utils/Context.sol";

contract AdminAgent is Context {

  mapping(address => bool) private _adminAgents;

  constructor(address[] memory adminAgents_) {
    for (uint i = 0; i < adminAgents_.length; i++) {
      _adminAgents[adminAgents_[i]] = true;
    }
  }

  modifier onlyAdminAgents() {
    require(_adminAgents[_msgSender()], "Unauthorized");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../lib/token/BEP20/BEP20.sol";
import "../lib/utils/Context.sol";

contract WithdrawAgent is Context {

  mapping(address => bool) private _adminAgents;
  mapping(address => bool) private _withdrawAgents;
  BEP20 private _token;

  event SetWithdrawAgent(address agent);
  event RevokeWithdrawAgent(address agent);
  event Withdraw(address recipient, uint256 amount, BEP20 token);

  constructor(
    address tokenContractAddress_,
    address[] memory adminAgents_,
    address[] memory withdrawAgents_
  ) {
    _token = BEP20(tokenContractAddress_);
    for (uint i = 0; i < adminAgents_.length; i++) {
      _adminAgents[adminAgents_[i]] = true;
    }
    for (uint i = 0; i < withdrawAgents_.length; i++) {
      _withdrawAgents[withdrawAgents_[i]] = true;
    }
  }

  modifier onlyWithdrawAdminAgents() virtual {
    require(_adminAgents[_msgSender()], "Unauthorized");
    _;
  }

  modifier onlyWithdrawAgents() {
    require(_withdrawAgents[_msgSender()], "Unauthorized");
    _;
  }

  function setWithdrawAgent(address _agent) external onlyWithdrawAdminAgents {
    _withdrawAgents[_agent] = true;
    emit SetWithdrawAgent(_agent);
  }

  function revokeWithdrawAgent(address _agent) external onlyWithdrawAdminAgents {
    _withdrawAgents[_agent] = false;
    emit RevokeWithdrawAgent(_agent);
  }

  function withdraw(uint256 amount) external onlyWithdrawAgents {
    _withdrawTo(_msgSender(), amount);
  }

  function withdrawTo(address recipient, uint256 amount) external onlyWithdrawAgents {
    _withdrawTo(recipient, amount);
  }

  function _withdrawTo(address recipient, uint256 amount) internal {
    require(_token.balanceOf(address(this)) >= amount, "Insufficient balance");
    _token.transfer(recipient, amount);
    emit Withdraw(recipient, amount, _token);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
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

pragma solidity ^0.8.4;

import "../../access/Ownable.sol";
import "../../utils/Context.sol";
import "./IBEP20.sol";

/**
 * @dev @dev Implementation of the {IBEP20} interface.
 */
contract BEP20 is Context, IBEP20, Ownable {
  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
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
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

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
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] -= amount;
    _totalSupply -= amount;
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()] - amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.8.4;

import "../../access/AccessControl.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "./IBEP20.sol";

/**
 * @dev Implementation of the {IBEP20} interface.
 * 
 * With an addition of AccessControl:
 * https://docs.openzeppelin.com/contracts/4.x/access-control
 * 
 * Tokens derived from this contract should initiate
 * by calling `_setupRole` to initialize the role for deployer
 * 
 * role can be DEFAULT_ADMIN_ROLE which has access
 * to all roles or you can setup your own role, which
 * require you to call `_setRoleAdmin` to specify
 * which role has grant and revoke access to which role
 */
contract MFCBEP20 is Context, IBEP20, AccessControl {
  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  address private _owner;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    _owner = _msgSender();
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return _owner;
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
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
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must have the admin role
   */
  function mint(uint256 amount) public virtual returns (bool) {
    _mint(_msgSender(), amount);
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
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

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
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] -= amount;
    _totalSupply -= amount;
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()] - amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

import "../lib/token/BEP20/MFCBEP20.sol";

contract MFCToken is MFCBEP20 {

  // EIP712 Precomputed hashes:
  // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 private constant EIP712DOMAINTYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

  // keccak256("MFCToken")
  bytes32 private constant NAME_HASH = 0xdb4db5fa560f82db369fcd92e192fd316a82e907eaf9c98c16090611a9914217;

  // keccak256("1")
  bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

  // keccak256("MFCPermit(address owner,address spender,uint256 amount,uint256 nonce)");
  bytes32 private constant TXTYPE_HASH = 0xc6eadd329a3e2aac488e2cfafe9dc8060a0b814e9352e8484f04a656f2d69158;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  mapping(address => uint) public nonces;

  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

  uint8 public constant DECIMALS = 18;
  uint256 public constant MAX_SUPPLY = 7000000000000000000000000000; // 7 billion hard cap

  mapping(address => bool) private _users;
  mapping(address => bool) private _agents;

  event UserWhitelisted(address recipient);
  event AgentWhitelisted(address recipient);
  event UserWhitelistRevoked(address recipient);
  event AgentWhitelistRevoked(address recipient);

  /**
   * @dev Constructor that setup all the role admins.
   */
  constructor(
    string memory name,
    string memory symbol
  ) MFCBEP20(name, symbol, DECIMALS) {
    // make OWNER_ROLE the admin role for each role (only people with the role of an admin role can manage that role)
    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(WHITELISTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    // setup deployer to be part of OWNER_ROLE which allow deployer to manage all roles
    _setupRole(OWNER_ROLE, _msgSender());

    // Setup EIP712
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712DOMAINTYPE_HASH,
        NAME_HASH,
        VERSION_HASH,
        block.chainid,
        address(this)
      )
    );
  }

  modifier onlyTransferable(address sender, address recipient) {
    // sender and recipient must both be whitelisted
    require((_users[sender] || _agents[sender]) && (_users[recipient] || _agents[recipient]), "Address not whitelisted");
    // either address must be an agent address, user to user transfer is not allowed
    require(_agents[sender] || _agents[recipient], "Transfer not allowed");
    _;
  }

  function transfer(address recipient, uint256 amount) public override onlyTransferable(_msgSender(), recipient) returns (bool) {
    return super.transfer(recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override onlyTransferable(sender, recipient) returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }

  function mint(uint256 amount) public override onlyRole(MINTER_ROLE) returns (bool) {
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
    return super.mint(amount);
  }

  function mintTo(address recipient, uint256 amount) public onlyRole(MINTER_ROLE) onlyTransferable(_msgSender(), recipient) returns (bool) {
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
    super._mint(recipient, amount);
    return true;
  }

  function grantOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(OWNER_ROLE, _address);
  }

  function grantMinterRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(MINTER_ROLE, _address);
  }

  function grantWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(WHITELISTER_ROLE, _address);
  }

  function revokeOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(OWNER_ROLE, _address);
  }

  function revokeMinterRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(MINTER_ROLE, _address);
  }

  function revokeWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(WHITELISTER_ROLE, _address);
  }

  function isWhitelistedUser(address _address) external view returns (bool) {
    return _users[_address];
  }

  function isWhitelistedAgent(address _address) external view returns (bool) {
    return _agents[_address];
  }

  function whitelistUser(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_users[_address] == false, "Already whitelisted");
    _users[_address] = true;
    emit UserWhitelisted(_address);
  }

  function whitelistAgent(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_agents[_address] == false, "Already whitelisted");
    _agents[_address] = true;
    emit AgentWhitelisted(_address);
  }

  function revokeWhitelistedUser(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_users[_address] == true, "Not whitelisted");
    delete _users[_address];
    emit UserWhitelistRevoked(_address);
  }

  function revokeWhitelistedAgent(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_agents[_address] == true, "Not whitelisted");
    delete _agents[_address];
    emit AgentWhitelistRevoked(_address);
  }

  function permit(address owner, address spender, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
    // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
    bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, owner, spender, amount, nonces[owner]));
    bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));

    address recoveredAddress = ecrecover(totalHash, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "MFCToken: INVALID_SIGNATURE");

    nonces[owner] = nonces[owner] + 1;
    _approve(owner, spender, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../access/AdminAgent.sol";
import "../access/WithdrawAgent.sol";
import "./Treasury.sol";

contract BUSDT is Treasury, AdminAgent, WithdrawAgent {

  address private _governanceAddress;
  address private _migration;
  address private _collateralLoan;

  constructor(
    address tokenContractAddress,
    address governanceAddress,
    address[] memory adminAgents,
    address[] memory withdrawAgents
  ) Treasury(tokenContractAddress)
    AdminAgent(adminAgents)
    WithdrawAgent(tokenContractAddress, adminAgents, withdrawAgents) {
    _governanceAddress = governanceAddress;
  }

  modifier onlyGovernance() {
    require(_governanceAddress == _msgSender(), "Unauthorized");
    _;
  }

  modifier onlyCollateralLoan() {
    require(_collateralLoan == _msgSender(), "Unauthorized");
    _;
  }

  function getGovernanceAddress() external view returns (address) {
    return _governanceAddress;
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function getCollateralLoan() external view returns (address) {
    return _collateralLoan;
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminAgents {
    require(_migration != address(0), "Migration not set");
    _withdrawTo(_migration, amount);
  }

  function setCollateralLoanAddress(address destination) external onlyAdminAgents {
    require(_collateralLoan == address(0), "Already set");
    _collateralLoan = destination;
  }

  function collateralTransfer(address recipient, uint256 amount) external onlyCollateralLoan {
    _withdrawTo(recipient, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../lib/token/BEP20/BEP20.sol";
import "../lib/utils/Context.sol";

contract Treasury is Context {

  BEP20 private _token;

  constructor(address tokenContractAddress_) {
    _token = BEP20(tokenContractAddress_);
  }

  function getTreasuryToken() internal view returns (BEP20) {
    return _token;
  }
}