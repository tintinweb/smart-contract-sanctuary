// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// PERSISTENCE ALONE IS OMNIPOTENT!

// S: CHIPAPIMONANO
// A: EMPATHETIC
// F: Pex-Pef
// E: ETHICAL

// Proto.Gold: $PROTO - $LAW - $DORE
// A DEFLATIONARY, CHARITABLE, SAVINGS & REWARDS PROTOCOL.
// BY THE PEOPLE, FOR THE PEOPLE.

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./LawType.sol";
import "./LawBEP20V2.sol";
import "./LawDao.sol";
import "./LawDrop.sol";
import "../SafeMath.sol";
import "./LawGovernance.sol";

contract ProtoLawV2 is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using LawBEP20V2 for LawType.Universe;
    using LawDao for LawType.Universe;
    using LawDrop for LawType.Universe;
    using LawGovernance for LawType.Universe;
    using SafeMath for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    LawType.Universe state;

    function initialize() public initializer {
        __ERC20_init("Proto.Gold DAO", "LAW");
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            0x77132d30e3E7dBF2d8d0790090B3113DD3248223
        ); // This will be transfered to Proto.Gold daoCouncil 0x76621B905cf21C4FceF8F4Ae1711c5a7bc040bc1 Binance Gnosis Multisig - BSC after DCE Two
        _setupRole(PAUSER_ROLE, 0x77132d30e3E7dBF2d8d0790090B3113DD3248223);
        state._initLaw();
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function totalSupply()
        public
        view
        virtual
        override(ERC20Upgradeable)
        returns (uint256)
    {
        return state._tTotal;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override(ERC20Upgradeable)
        returns (uint256)
    {
        return state.balanceOf(account);
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return state._allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        state._approve(msg.sender, spender, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _beforeTokenTransfer(from, to, amount);
        state._transfer(from, to, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        returns (bool)
    {
        return state.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        returns (bool)
    {
        return state.decreaseAllowance(spender, subtractedValue);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _beforeTokenTransfer(msg.sender, recipient, amount);
        state._transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return state.transferFrom(sender, recipient, amount);
    }

    function lockedLaw(address account)
        external
        view
        virtual
        returns (LawType.LockedLaw memory)
    {
        return state.lockedLaw(account);
    }

    function claimDCELawTokens() external virtual {
        state.claimDCELawTokens();
    }

    function claimTokensFromLockedToken() external virtual {
        state.claimTokensFromLockedToken();
    }

    function createProposal(address implementation)
        external
        virtual
        returns (uint256)
    {
        return state.createProposal(implementation);
    }

    function voteProposal(
        uint256 proposalId,
        uint256 stakeAmount,
        bool isAccepted
    ) external virtual returns (uint256) {
        return state.voteProposal(proposalId, stakeAmount, isAccepted);
    }

    function withdrawStakeFromVote(uint256 proposalId) external virtual {
        state.withdrawStakeFromVote(proposalId);
    }

    function getProposalFromImplementation(address implementation)
        external
        view
        virtual
        returns (LawType.Proposal memory)
    {
        return state.getProposalFromImplementation(implementation);
    }

    function getProposalFromId(uint256 proposalId)
        external
        view
        virtual
        returns (LawType.Proposal memory)
    {
        return state.getProposalFromId(proposalId);
    }

    function getProposals(uint256 pageNumber, uint256 perPage)
        external
        view
        virtual
        returns (LawType.Proposal[] memory)
    {
        return state.getProposals(pageNumber, perPage);
    }

    function isProposalAccepted(address implementation)
        external
        view
        virtual
        returns (bool)
    {
        return state.isProposalAccepted(implementation);
    }

    function daoCouncil() external view virtual returns (address) {
        return state._daoCouncil;
    }

    function setProtoGoldFuel(address proxyAddress) external virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.setProtoGoldFuel(proxyAddress);
    }

    //to receive BNB from pancakeSwapV2Router when swapping and for receiving BNB
    receive() external payable virtual {}

    function stats()
        external
        view
        virtual
        returns (uint256 _proposalCounter, uint256 _voteCounter)
    {
        return state.stats();
    }

    function enableProtoUpgrades()
        external
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        state.enableProtoUpgrades();
    }

    function getVoteStake(uint256 voteId)
        external
        view
        virtual
        returns (LawType.VoteStake memory)
    {
        return state.getVoteStake(voteId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
     * All two of these values are immutable: they can only be set once during
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LawType {
    struct LockedLaw {
        bool isUnlocked;
        uint256 unlockedTime;
        uint256 vesting;
        uint256 lastReward;
        uint256 count;
        uint256 amount;
        uint256 lockedAmount;
        uint256 rOwned;
    }

    struct VoteStake {
        uint256 id;
        address voter;
        uint256 amount;
        uint256 rAmount;
        uint256 stakedSince;
        bool isAccepted;
        bool isClaimed;
        address implementation;
    }

    struct Proposal {
        uint256 id;
        address implementation;
        uint256 startTime;
        uint256 endTime;
        uint256 acceptedLaws;
        uint256 deniedLaws;
        uint256 acceptedAccountCount;
        uint256 deniedAccountCount;
        address creator;
    }

    struct Universe {
        uint256 MAX;
        uint256 _tTotal;
        uint256 _rTotal;
        address _daoCouncil;
        address protoGoldFuel;
        uint256 MAXTxAmount;
        mapping(uint256 => bool) usedNonces;
        mapping(address => bool) _dceLawClaimed;
        mapping(address => uint256) _rLawOwned;
        mapping(address => uint256) _tLawOwned;
        mapping(address => bool) _isExcluded;
        address[] _excluded;
        mapping(address => LockedLaw) _lOwned;
        mapping(address => mapping(address => uint256)) _allowances;
        uint256 _voteCounter;
        uint256 _proposalCounter;
        mapping(address => uint256) proposalIdFromImplementation; // implementation => proposalId
        uint256[] proposals; // proposalIds
        uint256[] createdProposals;
        mapping(uint256 => Proposal) proposalFromId; // proposalId => Proposal
        mapping(address => mapping(uint256 => uint256)) createdVotes; // account => proposalId => voteId
        mapping(uint256 => VoteStake) voteStakeFromId; // voteId => VoteStake
    }

    function daoCouncil(LawType.Universe storage state)
        public
        view
        returns (address)
    {
        return state._daoCouncil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../SafeMath.sol";
import "./LawType.sol";

library LawBEP20V2 {
    using SafeMath for uint256;
    using LawType for LawType.Universe;
    using LawType for LawType.LockedLaw;

    event Approval(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function totalSupply(LawType.Universe storage state)
        public
        view
        returns (uint256)
    {
        return state._tTotal;
    }

    function balanceOf(LawType.Universe storage state, address account)
        public
        view
        returns (uint256)
    {
        if (state._isExcluded[account]) return state._tLawOwned[account];
        return tokenFromReflection(state, state._rLawOwned[account]);
    }

    function _transfer(
        LawType.Universe storage state,
        address from,
        address to,
        uint256 amount
    ) public {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != state.daoCouncil() && to != state.daoCouncil())
            require(
                amount <= state.MAXTxAmount,
                "Transfer amount exceeds the state.MAXTxAmount."
            );

        _tokenTransfer(state, from, to, amount);
    }

    function transferFrom(
        LawType.Universe storage state,
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(state, sender, recipient, amount);
        _approve(
            state,
            sender,
            msg.sender,
            state._allowances[sender][msg.sender].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        LawType.Universe storage state,
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            state,
            msg.sender,
            spender,
            state._allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        LawType.Universe storage state,
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            state,
            msg.sender,
            spender,
            state._allowances[msg.sender][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _tokenTransfer(
        LawType.Universe storage state,
        address sender,
        address recipient,
        uint256 amount
    ) public {
        if (state._isExcluded[sender] && !state._isExcluded[recipient]) {
            _transferFromExcluded(state, sender, recipient, amount);
        } else if (!state._isExcluded[sender] && state._isExcluded[recipient]) {
            _transferToExcluded(state, sender, recipient, amount);
        } else if (state._isExcluded[sender] && state._isExcluded[recipient]) {
            _transferBothExcluded(state, sender, recipient, amount);
        } else {
            _transferStandard(state, sender, recipient, amount);
        }
    }

    function _transferInternal(
        LawType.Universe storage state,
        address recipient,
        uint256 tAmount
    ) public {
        state._rLawOwned[recipient] = state._rLawOwned[recipient].add(
            tAmount.mul(_getRate(state))
        );
        if (state._isExcluded[recipient])
            state._tLawOwned[recipient] = state._tLawOwned[recipient].add(
                tAmount
            );

        emit Transfer(msg.sender, recipient, tAmount);
    }

    function _transferStandard(
        LawType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        uint256 rAmount = tAmount.mul(_getRate(state));
        state._rLawOwned[sender] = state._rLawOwned[sender].sub(rAmount);
        state._rLawOwned[recipient] = state._rLawOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferToExcluded(
        LawType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        uint256 rAmount = tAmount.mul(_getRate(state));

        state._rLawOwned[sender] = state._rLawOwned[sender].sub(rAmount);
        state._tLawOwned[recipient] = state._tLawOwned[recipient].add(tAmount);
        state._rLawOwned[recipient] = state._rLawOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferFromExcluded(
        LawType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        uint256 rAmount = tAmount.mul(_getRate(state));

        state._tLawOwned[sender] = state._tLawOwned[sender].sub(tAmount);
        state._rLawOwned[sender] = state._rLawOwned[sender].sub(rAmount);
        state._rLawOwned[recipient] = state._rLawOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferLockedStandard(
        LawType.Universe storage state,
        address receiver,
        uint256 transferRewardAmount,
        uint256 transferVestingAmount
    ) public {
        address sender = address(this);
        uint256 transferAmount = transferRewardAmount.add(
            transferVestingAmount
        );
        require(transferAmount > 0, "Claimable amount is zero");

        uint256 rAmount = reflectionFromToken(state, transferAmount);
        require(
            rAmount <= state._lOwned[receiver].rOwned,
            "Not enough tokens to claim"
        );

        require(
            state._rLawOwned[sender] >= rAmount,
            "Not enough tokens in contract to release"
        );

        state._rLawOwned[sender] = state._rLawOwned[sender].sub(rAmount);
        state._rLawOwned[receiver] = state._rLawOwned[receiver].add(rAmount);
        state._lOwned[receiver].rOwned = state._lOwned[receiver].rOwned.sub(
            rAmount
        );

        if (transferVestingAmount > 0) {
            state._lOwned[receiver].lockedAmount = state
            ._lOwned[receiver]
            .lockedAmount
            .sub(transferVestingAmount);
        }

        emit Transfer(sender, receiver, transferAmount);
    }

    function _transferBothExcluded(
        LawType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        uint256 rAmount = tAmount.mul(_getRate(state));

        state._tLawOwned[sender] = state._tLawOwned[sender].sub(tAmount);
        state._rLawOwned[sender] = state._rLawOwned[sender].sub(rAmount);
        state._tLawOwned[recipient] = state._tLawOwned[recipient].add(tAmount);
        state._rLawOwned[recipient] = state._rLawOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function lockedLaw(LawType.Universe storage state, address account)
        external
        view
        returns (LawType.LockedLaw memory)
    {
        return state._lOwned[account];
    }

    function _approve(
        LawType.Universe storage state,
        address owner,
        address spender,
        uint256 amount
    ) public {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        state._allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function reflectionFromToken(
        LawType.Universe storage state,
        uint256 tAmount
    ) public view returns (uint256) {
        require(tAmount <= state._tTotal, "Amount must be less than supply");
        return tAmount.mul(_getRate(state));
    }

    function tokenFromReflection(
        LawType.Universe storage state,
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= state._rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate(state);
        return rAmount.div(currentRate);
    }

    function _getRate(LawType.Universe storage state)
        public
        view
        returns (uint256)
    {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(state);
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply(LawType.Universe storage state)
        public
        view
        returns (uint256, uint256)
    {
        uint256 rSupply = state._rTotal;
        uint256 tSupply = state._tTotal;
        for (uint256 i = 0; i < state._excluded.length; i++) {
            if (
                state._rLawOwned[state._excluded[i]] > rSupply ||
                state._tLawOwned[state._excluded[i]] > tSupply
            ) return (state._rTotal, state._tTotal);
            rSupply = rSupply.sub(state._rLawOwned[state._excluded[i]]);
            tSupply = tSupply.sub(state._tLawOwned[state._excluded[i]]);
        }
        if (rSupply < state._rTotal.div(state._tTotal))
            return (state._rTotal, state._tTotal);
        return (rSupply, tSupply);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../SafeMath.sol";
import "../Address.sol";
import "./LawType.sol";
import "./LawBEP20V2.sol";

library LawDao {
    using SafeMath for uint256;
    using Address for address;
    using LawType for LawType.Universe;
    using LawBEP20V2 for LawType.Universe;

    event Approval(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function _initLaw(LawType.Universe storage state) external {
        state.MAX = ~uint256(0);
        state._tTotal = 660000000e18;
        state._rTotal = (state.MAX - (state.MAX % state._tTotal));
        state.MAXTxAmount = 120 * 10**6 * 10**18;

        state._daoCouncil = 0x77132d30e3E7dBF2d8d0790090B3113DD3248223; // This will be transfered to Proto.Gold daoCouncil 0x76621B905cf21C4FceF8F4Ae1711c5a7bc040bc1 Binance Gnosis Multisig - BSC after DCE Two

        state._rLawOwned[address(this)] = state.reflectionFromToken(
            state._tTotal
        );

        emit Transfer(address(0), address(this), state._tTotal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../SafeMath.sol";
import "../Address.sol";
import "./LawType.sol";
import "./LawBEP20V2.sol";
import "./IProto.sol";

library LawDrop {
    using SafeMath for uint256;
    using Address for address;
    using LawType for LawType.Universe;
    using LawBEP20V2 for LawType.Universe;

    function claimDCELawTokens(LawType.Universe storage state) public {
        require(
            !state._dceLawClaimed[msg.sender],
            "Your LAW Tokens already credited"
        );

        uint256 tokenAmountFromContribution = allowedDCELawClaim(
            state,
            msg.sender
        );
        require(tokenAmountFromContribution > 0, "No tokens to claim");
        uint256 instantLaws = tokenAmountFromContribution.div(10); // instant 10% law tokens credit
        uint256 lockedLaws = tokenAmountFromContribution.mul(90).div(100); // locked 90% tokens with 365 days vesting
        state._lOwned[msg.sender] = LawType.LockedLaw({
            isUnlocked: false,
            unlockedTime: block.timestamp, // start vesting instantly
            vesting: 365,
            lastReward: 0,
            count: 0,
            amount: lockedLaws,
            lockedAmount: lockedLaws,
            rOwned: state.reflectionFromToken(lockedLaws)
        });

        state._transfer(address(this), msg.sender, instantLaws);
        state._dceLawClaimed[msg.sender] = true;
    }

    function allowedDCELawClaim(LawType.Universe storage state, address account)
        public
        view
        returns (uint256)
    {
        return IProto(state.protoGoldFuel).allowedDCELawClaim(account);
    }

    function claimTokensFromLockedToken(LawType.Universe storage state)
        external
    {
        address receiver = msg.sender;

        require(state._lOwned[receiver].rOwned > 0, "No tokens to claim");

        uint256 transferRewardAmount = state
        .tokenFromReflection(state._lOwned[receiver].rOwned)
        .sub(state._lOwned[receiver].lockedAmount);
        uint256 transferVestingAmount = 0;

        if (state._lOwned[receiver].lockedAmount > 0) {
            if (state._lOwned[receiver].unlockedTime > block.timestamp) {
                // no-op
            } else if (!state._lOwned[receiver].isUnlocked) {
                state._lOwned[receiver].isUnlocked = true;
                uint256 diff = (
                    block.timestamp.sub(state._lOwned[receiver].unlockedTime)
                )
                .div(60)
                .div(60)
                .div(24);
                if (diff <= 1) diff = 1;
                if (
                    state._lOwned[receiver].count.add(diff) >
                    state._lOwned[receiver].vesting
                ) {
                    diff = state._lOwned[receiver].vesting.sub(
                        state._lOwned[receiver].count
                    );
                }
                transferVestingAmount = state
                ._lOwned[receiver]
                .amount
                .mul(diff)
                .div(state._lOwned[receiver].vesting);

                state._lOwned[receiver].lastReward = block.timestamp;
                state._lOwned[receiver].count = state
                ._lOwned[receiver]
                .count
                .add(diff);
            } else {
                if (
                    block.timestamp >
                    (state._lOwned[receiver].lastReward + 1 days) &&
                    state._lOwned[receiver].count <
                    state._lOwned[receiver].vesting
                ) {
                    uint256 diff = (
                        block.timestamp.sub(state._lOwned[receiver].lastReward)
                    )
                    .div(60)
                    .div(60)
                    .div(24);
                    if (diff <= 1) diff = 1;
                    if (
                        state._lOwned[receiver].count.add(diff) >
                        state._lOwned[receiver].vesting
                    ) {
                        diff = state._lOwned[receiver].vesting.sub(
                            state._lOwned[receiver].count
                        );
                    }
                    transferVestingAmount = state
                    ._lOwned[receiver]
                    .amount
                    .mul(diff)
                    .div(state._lOwned[receiver].vesting);

                    state._lOwned[receiver].lastReward = block.timestamp;
                    state._lOwned[receiver].count = state
                    ._lOwned[receiver]
                    .count
                    .add(diff);
                }
            }
            require(
                state._lOwned[receiver].count <=
                    state._lOwned[receiver].vesting,
                "Cannot claim amount more than vested days"
            );
        }

        state._transferLockedStandard(
            receiver,
            transferRewardAmount,
            transferVestingAmount
        );
    }

    function setProtoGoldFuel(
        LawType.Universe storage state,
        address proxyAddress
    ) external {
        state.protoGoldFuel = proxyAddress;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../SafeMath.sol";
import "../Address.sol";
import "./LawType.sol";
import "./LawBEP20V2.sol";

library LawGovernance {
    using SafeMath for uint256;
    using Address for address;
    using LawBEP20V2 for LawType.Universe;

    event CreatedProposal(
        uint256 _id,
        address indexed _implementation,
        uint256 _startTime,
        uint256 _endTime,
        address _creator
    );

    event VotedProposal(
        uint256 _id,
        address indexed _implementation,
        uint256 _stakeAmount,
        bool _isAccepted,
        uint256 _acceptedLawsSoFar,
        uint256 _deniedLawsSoFar,
        uint256 _acceptedAccountCountSoFar,
        uint256 _deniedAccountCountSoFar
    );

    event WithdrawnVotedStake(
        address indexed _voter,
        uint256 _proposalId,
        uint256 _voteId,
        uint256 _stakeAmount
    );

    function createProposal(
        LawType.Universe storage state,
        address implementation
    ) external returns (uint256) {
        require(
            state.proposalIdFromImplementation[implementation] == 0,
            "Proposal already exists"
        );
        uint256 nextProposalId = ++state._proposalCounter;
        state.proposalFromId[nextProposalId] = LawType.Proposal({
            id: nextProposalId,
            implementation: implementation,
            startTime: block.timestamp,
            endTime: block.timestamp + 24 hours,
            creator: msg.sender,
            acceptedLaws: 0,
            deniedLaws: 0,
            acceptedAccountCount: 0,
            deniedAccountCount: 0
        });

        state.proposalIdFromImplementation[implementation] = nextProposalId;
        state.proposals.push(nextProposalId);
        state.createdProposals.push(nextProposalId);

        emit CreatedProposal(
            nextProposalId,
            implementation,
            state.proposalFromId[nextProposalId].startTime,
            state.proposalFromId[nextProposalId].endTime,
            state.proposalFromId[nextProposalId].creator
        );
        return nextProposalId;
    }

    function voteProposal(
        LawType.Universe storage state,
        uint256 proposalId,
        uint256 stakeAmount,
        bool isAccepted
    ) external returns (uint256) {
        require(
            state.proposalFromId[proposalId].startTime < block.timestamp,
            "Proposal hasn't begun yet"
        );

        require(
            state.proposalFromId[proposalId].endTime > block.timestamp,
            "Proposal has ended"
        );

        require(
            state.createdVotes[msg.sender][proposalId] == 0,
            "Already voted this proposal"
        );
        uint256 rStakeAmount = state.reflectionFromToken(stakeAmount);
        state._rLawOwned[msg.sender] = state._rLawOwned[msg.sender].sub(
            rStakeAmount
        );
        uint256 nextVoteId = ++state._voteCounter;
        state.voteStakeFromId[nextVoteId] = LawType.VoteStake({
            id: nextVoteId,
            voter: msg.sender,
            amount: stakeAmount,
            rAmount: rStakeAmount,
            stakedSince: block.timestamp,
            isAccepted: isAccepted,
            implementation: state.proposalFromId[proposalId].implementation,
            isClaimed: false
        });
        if (isAccepted) {
            state.proposalFromId[proposalId].acceptedLaws = state
            .proposalFromId[proposalId]
            .acceptedLaws
            .add(stakeAmount);
            state.proposalFromId[proposalId].acceptedAccountCount++;
        } else {
            state.proposalFromId[proposalId].deniedLaws = state
            .proposalFromId[proposalId]
            .deniedLaws
            .add(stakeAmount);
            state.proposalFromId[proposalId].deniedAccountCount++;
        }

        state.createdVotes[msg.sender][proposalId] = nextVoteId;

        emit VotedProposal(
            nextVoteId,
            state.proposalFromId[proposalId].implementation,
            stakeAmount,
            isAccepted,
            state.proposalFromId[proposalId].acceptedLaws,
            state.proposalFromId[proposalId].deniedLaws,
            state.proposalFromId[proposalId].acceptedAccountCount,
            state.proposalFromId[proposalId].deniedAccountCount
        );
        return nextVoteId;
    }

    function withdrawStakeFromVote(
        LawType.Universe storage state,
        uint256 proposalId
    ) external {
        require(
            state.proposalFromId[proposalId].endTime + 1 hours <
                block.timestamp,
            "Cannot withdraw stake until after 1 hour from proposal end time"
        );

        uint256 voteId = state.createdVotes[msg.sender][proposalId];

        require(voteId != 0, "You have not voted this proposal");
        require(
            !state.voteStakeFromId[voteId].isClaimed,
            "Stake already claimed"
        );
        state.voteStakeFromId[voteId].isClaimed = true;
        state._rLawOwned[msg.sender] = state._rLawOwned[msg.sender].add(
            state.voteStakeFromId[voteId].rAmount
        );

        emit WithdrawnVotedStake(
            msg.sender,
            proposalId,
            voteId,
            state.voteStakeFromId[voteId].amount
        );
    }

    function getProposalFromImplementation(
        LawType.Universe storage state,
        address implementation
    ) external view returns (LawType.Proposal memory) {
        uint256 proposalId = state.proposalIdFromImplementation[implementation];
        return state.proposalFromId[proposalId];
    }

    function getProposalFromId(
        LawType.Universe storage state,
        uint256 proposalId
    ) external view returns (LawType.Proposal memory) {
        return state.proposalFromId[proposalId];
    }

    function getProposals(
        LawType.Universe storage state,
        uint256 pageNumber,
        uint256 perPage
    ) external view returns (LawType.Proposal[] memory) {
        LawType.Proposal[] memory currentPage = new LawType.Proposal[](perPage);
        uint256 startIndex = pageNumber.mul(perPage);
        uint256 endIndex = pageNumber.mul(perPage).add(perPage);
        for (uint256 i = startIndex; i < endIndex; i++) {
            currentPage[i] = state.proposalFromId[state.proposals[i]];
        }
        return currentPage;
    }

    function isProposalAccepted(
        LawType.Universe storage state,
        address implementation
    ) external view returns (bool) {
        uint256 proposalId = state.proposalIdFromImplementation[implementation];
        LawType.Proposal memory currentProposal = state.proposalFromId[
            proposalId
        ];
        if (currentProposal.endTime + 1 hours > block.timestamp) return false;
        return currentProposal.acceptedLaws > currentProposal.deniedLaws;
    }

    function enableProtoUpgrades(LawType.Universe storage state) external {
        // The authorize mechanism in the PROTO smart contracts uses the Proto DAO LAW token to permit any upgrades.
        // Due to the requirement for UUPS upgrades to pass rollback checks during upgrades, the previous implementation will also need to pass the authorization.
        // The above has been addressed in the Proto Genesis Upgrade (Proposal ID: 3) and will affect future proposals.
        // But to execute Proposal ID 3, LAW should allow the current implementation address of PROTO to be approved to upgrade along with Proposal ID 3.
        // This function allows extending the voting time for the proposal with the current implementation address by one hour after calling this function, thus allowing the community to vote.
        // As a safety measure, the function becomes uncallable after 2021-07-21 23:19:22 UTC, before which Proto.Gold Fuel, the protocol has to be upgraded.
        require(block.timestamp < 1626909562);
        state.proposalFromId[2].endTime = block.timestamp + 1 hours;
    }

    function stats(LawType.Universe storage state)
        external
        view
        returns (uint256 _proposalCounter, uint256 _voteCounter)
    {
        return (state._proposalCounter, state._voteCounter);
    }

    function getVoteStake(LawType.Universe storage state, uint256 voteId)
        external
        view
        returns (LawType.VoteStake memory)
    {
        return state.voteStakeFromId[voteId];
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

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

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /*
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
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
library StorageSlotUpgradeable {
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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IProto {
    function allowedDCELawClaim(address account)
        external
        view
        returns (uint256);
}

