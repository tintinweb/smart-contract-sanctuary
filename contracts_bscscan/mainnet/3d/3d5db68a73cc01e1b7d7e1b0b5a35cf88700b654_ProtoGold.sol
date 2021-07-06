// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./ProtoType.sol";
import "./ProtoDao.sol";
import "./ProtoBEP20.sol";
import "./ProtoDrop.sol";
import "./ProtoLiquidity.sol";
import "./SafeMath.sol";

contract ProtoGold is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using ProtoDao for ProtoType.Universe;
    using ProtoERC20 for ProtoType.Universe;
    using ProtoDrop for ProtoType.Universe;
    using ProtoLiquidity for ProtoType.Universe;
    using SafeMath for uint256;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event BNBWithdraw(address indexed owner, uint256 value);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    ProtoType.Universe state;
    ProtoType.PreAllocation allocation;

    function initialize(address _lawDao) public initializer {
        __ERC20_init("Proto.Gold Fuel", "PROTO");
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            0x77132d30e3E7dBF2d8d0790090B3113DD3248223
        ); // This will be transfered to Proto.Gold daoCouncil 0x76621B905cf21C4FceF8F4Ae1711c5a7bc040bc1 Binance Gnosis Multisig - BSC after DCE Two
        _setupRole(PAUSER_ROLE, 0x77132d30e3E7dBF2d8d0790090B3113DD3248223);
        state._initProto(allocation);
        state.lawGovernance = _lawDao;
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        view
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(
            state.approvedProposalsExpiry[newImplementation] > block.timestamp
        );
    }

    function approveProposal(address newImplementation) external {
        state.approveProposal(newImplementation);
    }

    function totalSupply()
        public
        override(ERC20Upgradeable)
        view
        returns (uint256)
    {
        return state._tTotal;
    }

    function balanceOf(address account)
        public
        override(ERC20Upgradeable)
        view
        returns (uint256)
    {
        return state.balanceOf(account);
    }

    function enableTranfer() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        state.transferEnabled = true;
    }

    function disableTranfer() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        state.transferEnabled = false;
    }

    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return state._allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
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
    ) internal override {
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
        override
        returns (bool)
    {
        state._transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return state.transferFrom(sender, recipient, amount);
    }

    function claimDCEProtoTokens() external {
        state.claimDCEProtoTokens();
    }

    function claimTokensFromLockedToken() external {
        state.claimTokensFromLockedToken();
    }

    function excludeFromFee(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state._isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state._isExcludedFromFee[account] = false;
    }

    function excludeFromReward(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.excludeFromReward(account);
    }

    function includeInReward(address account) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.includeInReward(account);
    }

    function setswapAndLiquifyEnabled(bool _enabled) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.setswapAndLiquifyEnabled(_enabled);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _ProtoAmount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.numTokensSellToAddToLiquidity = _ProtoAmount;
    }

    function setNumTokensSellToSwapBUSD(uint256 _ProtoAmount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.numTokensSellToSwapBUSD = _ProtoAmount;
    }

    function setMAXTxPercent(uint256 _MAXTxPercent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.setMAXTxPercent(_MAXTxPercent);
    }

    function withdrawBNB() public virtual payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        emit BNBWithdraw(state._daoCouncil, address(this).balance);
        address payable recipient = payable(state._daoCouncil);
        recipient.transfer(address(this).balance);
    }

    function setPancakeAddress(address _v, bool createLiquidityPair) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.setPancakeAddress(_v, createLiquidityPair);
    }

    function setBUSDAddress(address _v) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        state.setBUSDAddress(_v);
    }

    function daoCouncil() external view returns (address) {
        return state._daoCouncil;
    }

    function lawGovernance() public view returns (address) {
        return state.lawGovernance;
    }

    function lockedProto(address account)
        external
        view
        returns (ProtoType.LockedProto memory)
    {
        return state.lockedProto(account);
    }

    function allowedDCELawClaim(address account)
        external
        view
        returns (uint256 amount)
    {
        return state.allowedDCELawClaim(account);
    }

    function stats()
        external
        view
        returns (
            uint256 _tFeeTotal,
            uint256 _tLiquidityFeeTotal,
            uint256 _tBurnTotal
        )
    {
        return (state._tFeeTotal, state._tLiquidityFeeTotal, state._tBurnTotal);
    }

    //to receive BNB from pancakeSwapV2Router when swapping and for receiving BNB
    receive() external payable {}

    function config()
        external
        view
        returns (
            uint256 _taxFee,
            uint256 _liquidityFee,
            uint256 _MAXTxAmount,
            uint256 _numTokensSellToAddToLiquidity,
            uint256 _numTokensSellToSwapBUSD,
            bool _swapAndLiquifyEnabled,
            bool _transferEnabled
        )
    {
        return (
            state._taxFee,
            state._liquidityFee,
            state.MAXTxAmount,
            state.numTokensSellToAddToLiquidity,
            state.numTokensSellToSwapBUSD,
            state.swapAndLiquifyEnabled,
            state.transferEnabled
        );
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

import "./SafeMath.sol";
import "./Address.sol";
import "./Pancake.sol";

library ProtoType {
    using SafeMath for uint256;
    using Address for address;

    struct Universe {
        mapping(address => uint256) _rProtoOwned;
        mapping(address => uint256) _tProtoOwned;
        mapping(address => LockedProto) _lOwned;
        mapping(address => bool) _isExcludedFromFee;
        mapping(address => bool) _isExcluded;
        mapping(address => bool) _dceProtoClaimed;
        mapping(address => bool) _dceLawClaimAllowed;
        mapping(address => uint256) approvedProposalsExpiry;
        mapping(address => mapping(address => uint256)) _allowances;
        address[] _excluded;
        uint256 MAX;
        uint256 _tTotal;
        uint256 _rTotal;
        uint256 _tFeeTotal;
        uint256 _tLiquidityFeeTotal;
        uint256 _tBurnTotal;
        uint256 _taxFee;
        uint256 _previousTaxFee;
        uint256 _liquidityFee;
        uint256 _previousLiquidityFee;
        address pancakeSwapV2Pair;
        IPancakeSwapV2Router02 pancakeSwapV2Router;
        bool inSwapAndLiquify;
        bool inSwapBUSD;
        bool swapAndLiquifyEnabled;
        bool transferEnabled;
        address[2] charity;
        address daoSafe;
        address auditsDevelopmentSafe;
        address marketingSafe;
        address accumulationSafe;
        address[3] aidWallet;
        uint256 _toSwapBUSD;
        uint256 MAXTxAmount;
        uint256 numTokensSellToAddToLiquidity;
        uint256 numTokensSellToSwapBUSD;
        address _daoCouncil;
        address BUSDAddress;
        address pancakeRouterAddress;
        address lawGovernance;
    }

    struct LockedProto {
        bool isUnlocked;
        uint256 unlockedTime;
        uint256 vesting;
        uint256 lastReward;
        uint256 count;
        uint256 amount;
        uint256 lockedAmount;
        uint256 rOwned;
    }

    struct PreAllocation {
        bool isInitialized;
        uint256 totalLock;
        address daoCouncil;
        address accumulationSafe;
        address auditsDevelopmentSafe;
        address marketingSafe;
        address daoSafe;
        address yieldSafe;
        address listingSafe;
        address reserveSafe;
        address[3] aidWallets;
        address[30] coreWallets;
        mapping(address => bool) isCoreWallet;
        mapping(address => bool) isAidWallet;
        mapping(address => bool) isCharityWallet;
        mapping(address => uint256) lockTimes;
        mapping(address => uint256) shares;
    }

    function daoCouncil(ProtoType.Universe storage state)
        public
        view
        returns (address)
    {
        return state._daoCouncil;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Address.sol";
import "./ProtoType.sol";

import "./ProtoDistribution.sol";
import "./ProtoBEP20.sol";
import "./ILawGovernance.sol";

library ProtoDao {
    using SafeMath for uint256;
    using Address for address;
    using ProtoType for ProtoType.Universe;
    using ProtoType for ProtoType.LockedProto;
    using ProtoDistribution for ProtoType.PreAllocation;
    using ProtoERC20 for ProtoType.Universe;

    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address, address, uint256);

    function _initProto(
        ProtoType.Universe storage state,
        ProtoType.PreAllocation storage allocation
    ) external {
        state.MAX = ~uint256(0);
        state._tTotal = 660000000e18;
        state._rTotal = (state.MAX - (state.MAX % state._tTotal));
        state._taxFee = 850; // 8.5
        state._previousTaxFee = state._taxFee;
        state._liquidityFee = 150; // 1.5
        state._previousLiquidityFee = state._liquidityFee;

        state.swapAndLiquifyEnabled = false;
        state.transferEnabled = true;
        state.MAXTxAmount = 120 * 10**6 * 10**18;
        state.numTokensSellToAddToLiquidity = 90000 * 10**18;
        state.numTokensSellToSwapBUSD = 80000 * 10**18;

        state._daoCouncil = 0x77132d30e3E7dBF2d8d0790090B3113DD3248223; // This will be transfered to Proto.Gold daoCouncil 0x76621B905cf21C4FceF8F4Ae1711c5a7bc040bc1 Binance Gnosis Multisig - BSC after DCE Two
        state.BUSDAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        state.pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        state.accumulationSafe = 0xE8a446d95cBDcD548511210628260632C748290a; // Proto Accumulation Safe - BSC
        state
            .auditsDevelopmentSafe = 0x1Ba159A3C1C5aA0a5600d8DCC3Ef3F8de05c9D20; // Proto Audits and Development Safe - BSC
        state.marketingSafe = 0x8fc135fcA69049CDfC982CdC8772c0b432Bc3302; // Proto Marketing Multisig Safe - BSC
        state.daoSafe = 0xfC864d405AfcB40127A2c1555a0C7EE01E172023; // Proto DAO Multisig Safe - BSC

        state.charity = [
            0xd500EF7C6267233ed6711263d8f085e9856dCb23, // Proto Charity 1 Multisig Safe - BSC
            0x303C2B8eF3a12593a90a4cd80Dd0E0Be255B6715 // Proto Charity 2 Multisig Safe – BSC
        ];

        state.aidWallet = [
            0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F, // Aid 1
            0x47fd4076556EB209c616cCD5619393CC913e6E8A, // Aid 2
            0x9b22E636CACA80C9E243E6bDe1fdc198a297a972 // Aid 3
        ];

        allocation.initProtoDistribution(state);
        address[39] memory preAllocatedWallets = allocation
            .preAllocatedWallets();

        for (uint64 i = 0; i < preAllocatedWallets.length; i++) {
            (
                uint256 _share,
                uint256 _unlockTime,
                uint256 _vestingTime
            ) = allocation.getAllocation(preAllocatedWallets[i]);
            uint256 tokens = state.tokenFromReflection(_share);
            state._lOwned[preAllocatedWallets[i]] = ProtoType.LockedProto({
                isUnlocked: false,
                unlockedTime: _unlockTime,
                vesting: _vestingTime,
                lastReward: 0,
                count: 0,
                amount: tokens,
                lockedAmount: tokens,
                rOwned: _share
            });

            state._dceProtoClaimed[preAllocatedWallets[i]] = true;
        }

        state._rProtoOwned[address(this)] = allocation.totalLock;
        uint256 rDceSwapAndPancakeLiquiditySupply = state._rTotal.sub(
            allocation.totalLock
        );
        state._rProtoOwned[state
            .daoCouncil()] = rDceSwapAndPancakeLiquiditySupply;

        emit Transfer(
            address(0),
            state.daoCouncil(),
            state.tokenFromReflection(rDceSwapAndPancakeLiquiditySupply)
        );

        // New Pancake Router 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(
            state.pancakeRouterAddress
        );
        // set the rest of the contract variables
        state.pancakeSwapV2Router = _pancakeSwapV2Router;

        //exclude owner and this contract from fee
        state._isExcludedFromFee[state.daoCouncil()] = true;
        state._isExcludedFromFee[address(this)] = true;
    }

    function setdaoSafe(ProtoType.Universe storage state, address _v) external {
        state.daoSafe = _v;
    }

    function setauditsDevelopmentSafe(
        ProtoType.Universe storage state,
        address _v
    ) external {
        state.auditsDevelopmentSafe = _v;
    }

    function setmarketingSafe(ProtoType.Universe storage state, address _v)
        external
    {
        state.marketingSafe = _v;
    }

    function isProposalAccepted(
        ProtoType.Universe storage state,
        address newImplementation
    ) public view returns (bool) {
        ILawGovernance governor = ILawGovernance(state.lawGovernance);
        return governor.isProposalAccepted(newImplementation);
    }

    function approveProposal(
        ProtoType.Universe storage state,
        address newImplementation
    ) external {
        require(
            state.approvedProposalsExpiry[newImplementation] == 0,
            "Proposal already marked as approved"
        );
        require(
            isProposalAccepted(state, newImplementation),
            "Proposal not accepted"
        );
        state.approvedProposalsExpiry[newImplementation] =
            block.timestamp +
            24 hours;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Address.sol";
import "./IProtoDistribution.sol";
import "./ProtoType.sol";
import "./ProtoDao.sol";

library ProtoERC20 {
    using SafeMath for uint256;
    using Address for address;
    using ProtoType for ProtoType.Universe;
    using ProtoDao for ProtoType.Universe;
    using ProtoType for ProtoType.LockedProto;

    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address, address, uint256);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    function totalSupply(ProtoType.Universe storage state)
        public
        view
        returns (uint256)
    {
        return state._tTotal;
    }

    function balanceOf(ProtoType.Universe storage state, address account)
        public
        view
        returns (uint256)
    {
        if (state._isExcluded[account]) return state._tProtoOwned[account];
        return tokenFromReflection(state, state._rProtoOwned[account]);
    }

    function lockedProto(ProtoType.Universe storage state, address account)
        external
        view
        returns (ProtoType.LockedProto memory)
    {
        return state._lOwned[account];
    }

    function _approve(
        ProtoType.Universe storage state,
        address owner,
        address spender,
        uint256 amount
    ) public {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        state._allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapAndLiquify(
        ProtoType.Universe storage state,
        uint256 toSwapLiquidityProto
    ) public {
        require(!state.inSwapAndLiquify);
        state.inSwapAndLiquify = true;
        // split the contract balance into halves
        uint256 half = toSwapLiquidityProto.div(2);
        uint256 otherHalf = toSwapLiquidityProto.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBNB(state, half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeSwap
        addLiquidity(state, otherHalf, newBalance);

        state._tLiquidityFeeTotal = 0; // reset the accumulation tracker.
        emit SwapAndLiquify(half, newBalance, otherHalf);
        state.inSwapAndLiquify = false;
    }

    function swapTokensForBNB(
        ProtoType.Universe storage state,
        uint256 tokenAmount
    ) public {
        // generate the pancakeSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = state.pancakeSwapV2Router.WETH();

        _approve(
            state,
            address(this),
            address(state.pancakeSwapV2Router),
            tokenAmount
        );

        // make the swap
        state
            .pancakeSwapV2Router
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function shareBUSD(ProtoType.Universe storage state) public {
        require(!state.inSwapAndLiquify);
        state.inSwapAndLiquify = true;
        swapTokenForBUSD(state, state._toSwapBUSD);
        state._toSwapBUSD = 0; // ensures accumulated Proto count is reset once pancake swap of Proto-BUSD is done.
        IBEP20 BUSDtoken = IBEP20(state.BUSDAddress);
        uint256 busdReceived = BUSDtoken.balanceOf(address(this));
        BUSDtoken.transfer(
            state.charity[0],
            ((busdReceived.div(9)).mul(4)).div(2)
        );
        BUSDtoken.transfer(
            state.charity[1],
            ((busdReceived.div(9)).mul(4)).div(2)
        );
        BUSDtoken.transfer(
            state.accumulationSafe,
            (busdReceived.div(9)).mul(5)
        );
        state.inSwapAndLiquify = false;
    }

    function swapTokenForBUSD(ProtoType.Universe storage state, uint256 amount)
        public
    {
        // generate the pancakeSwap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = state.pancakeSwapV2Router.WETH();
        path[2] = state.BUSDAddress; // BUSD address

        _approve(
            state,
            address(this),
            address(state.pancakeSwapV2Router),
            amount
        );

        // make the swap
        state
            .pancakeSwapV2Router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of BUSD
            path,
            address(this),
            block.timestamp + 2 minutes
        );
    }

    function removeAllFee(ProtoType.Universe storage state) public {
        if (state._taxFee == 0 && state._liquidityFee == 0) return;

        state._previousTaxFee = state._taxFee;
        state._previousLiquidityFee = state._liquidityFee;

        state._taxFee = 0;
        state._liquidityFee = 0;
    }

    function restoreAllFee(ProtoType.Universe storage state) public {
        state._taxFee = state._previousTaxFee;
        state._liquidityFee = state._previousLiquidityFee;
    }

    function _transfer(
        ProtoType.Universe storage state,
        address from,
        address to,
        uint256 amount
    ) public {
        require(
            state.transferEnabled || (msg.sender == state.daoCouncil()),
            "BEP20: Token is not transferable"
        );
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != state.daoCouncil() && to != state.daoCouncil())
            require(
                amount <= state.MAXTxAmount,
                "Transfer amount exceeds the state.MAXTxAmount."
            );

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeSwap pair.
        uint256 toSwapLiquidity = state._tLiquidityFeeTotal;
        if (toSwapLiquidity >= state.MAXTxAmount) {
            toSwapLiquidity = state.MAXTxAmount;
        }

        bool overMinTokenBalance = toSwapLiquidity >=
            state.numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !state.inSwapAndLiquify &&
            from != state.pancakeSwapV2Pair &&
            state.swapAndLiquifyEnabled
        ) {
            toSwapLiquidity = state.numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(state, toSwapLiquidity);
        }

        if (
            state._toSwapBUSD >= state.numTokensSellToSwapBUSD &&
            from != state.pancakeSwapV2Pair &&
            !state.inSwapAndLiquify &&
            state.swapAndLiquifyEnabled
        ) {
            shareBUSD(state);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to state._isExcludedFromFee account then remove the fee
        if (state._isExcludedFromFee[from] || state._isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(state, from, to, amount, takeFee);
    }

    function transferFrom(
        ProtoType.Universe storage state,
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
        ProtoType.Universe storage state,
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
        ProtoType.Universe storage state,
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

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) public {
        if (!takeFee) removeAllFee(state);

        if (state._isExcluded[sender] && !state._isExcluded[recipient]) {
            _transferFromExcluded(state, sender, recipient, amount);
        } else if (!state._isExcluded[sender] && state._isExcluded[recipient]) {
            _transferToExcluded(state, sender, recipient, amount);
        } else if (state._isExcluded[sender] && state._isExcluded[recipient]) {
            _transferBothExcluded(state, sender, recipient, amount);
        } else {
            _transferStandard(state, sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee(state);
    }

    function _transferInternal(
        ProtoType.Universe storage state,
        address recipient,
        uint256 tAmount
    ) public {
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            tAmount.mul(_getRate(state))
        );
        if (state._isExcluded[recipient])
            state._tProtoOwned[recipient] = state._tProtoOwned[recipient].add(
                tAmount
            );

        emit Transfer(msg.sender, recipient, tAmount);
    }

    function _transferStandard(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._tProtoOwned[recipient] = state._tProtoOwned[recipient].add(
            tTransferAmount
        );
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._tProtoOwned[sender] = state._tProtoOwned[sender].sub(tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferLockedStandard(
        ProtoType.Universe storage state,
        address receiver,
        uint256 transferRewardAmount,
        uint256 transferVestingAmount
    ) public {
        address sender = address(this);
        uint256 transferAmount = transferRewardAmount.add(
            transferVestingAmount
        );
        require(transferAmount > 0, "Claimable amount is zero");

        uint256 rAmount = reflectionFromToken(state, transferAmount, false);
        require(
            rAmount <= state._lOwned[receiver].rOwned,
            "Not enough tokens to claim"
        );

        require(
            state._rProtoOwned[sender] >= rAmount,
            "Not enough tokens in contract to release"
        );

        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._rProtoOwned[receiver] = state._rProtoOwned[receiver].add(
            rAmount
        );
        state._lOwned[receiver].rOwned = state._lOwned[receiver].rOwned.sub(
            rAmount
        );

        if (transferVestingAmount > 0) {
            state._lOwned[receiver].lockedAmount = state._lOwned[receiver]
                .lockedAmount
                .sub(transferVestingAmount);
        }

        emit Transfer(sender, receiver, transferAmount);
    }

    function _transferBothExcluded(
        ProtoType.Universe storage state,
        address sender,
        address recipient,
        uint256 tAmount
    ) public {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(state, tAmount);
        state._tProtoOwned[sender] = state._tProtoOwned[sender].sub(tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._tProtoOwned[recipient] = state._tProtoOwned[recipient].add(
            tTransferAmount
        );
        state._rProtoOwned[recipient] = state._rProtoOwned[recipient].add(
            rTransferAmount
        );
        _takeLiquidity(state, tLiquidity);
        _reflectFee(state, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(
        ProtoType.Universe storage state,
        uint256 rFee,
        uint256 tFee
    ) public {
        if (rFee > 0 && tFee > 0) {
            uint256 OneFifth = ((tFee.div(state._taxFee)).mul(100)).div(2); //0.5 (variable)
            uint256 halfFifth = ((tFee.div(state._taxFee)).mul(100)).div(4); //0.25 token (variable)
            uint256 rOneFifth = ((rFee.div(state._taxFee)).mul(100)).div(2); //0.5 (variable)
            uint256 aidOnehalf = OneFifth.div(2);
            _transferInternal(state, state.daoSafe, halfFifth.mul(3)); //0.75 to DAO
            _transferInternal(state, state.marketingSafe, halfFifth.mul(3)); //0.75 state.marketingSafe
            _transferInternal(
                state,
                state.auditsDevelopmentSafe,
                halfFifth.mul(3)
            ); // 0.75 dev and audit
            _transferInternal(state, (address(0)), OneFifth.mul(2)); //1 to burn
            _transferInternal(state, state.aidWallet[0], aidOnehalf); // AID  0.25
            _transferInternal(state, state.aidWallet[1], aidOnehalf.div(2)); // AID 2 0.125
            _transferInternal(state, state.aidWallet[2], aidOnehalf.div(2)); // AID 3 0.125
            state._toSwapBUSD = state._toSwapBUSD.add(OneFifth.mul(2)); // 1% state.charity
            state._toSwapBUSD = state._toSwapBUSD.add((halfFifth).mul(5)); // 1.25 Acculamation Safe
            state._rTotal = state._rTotal.sub((rOneFifth.mul(5))); // Instant rewards 2.5
            state._tFeeTotal = state._tFeeTotal.add((OneFifth.mul(5)));
            state._tBurnTotal = state._tBurnTotal.add(OneFifth.mul(2));
            state._tLiquidityFeeTotal = state._tLiquidityFeeTotal.add(
                OneFifth.mul(3)
            ); // 1.5% liquidity fee
        }
    }

    function tokenFromReflection(
        ProtoType.Universe storage state,
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= state._rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate(state);
        return rAmount.div(currentRate);
    }

    function reflectionFromToken(
        ProtoType.Universe storage state,
        uint256 tAmount,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= state._tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(state, tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(state, tAmount);
            return rTransferAmount;
        }
    }

    function _getValues(ProtoType.Universe storage state, uint256 tAmount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(state, tAmount);
        uint256 currentRate = _getRate(state);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            currentRate
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(ProtoType.Universe storage state, uint256 tAmount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(state, tAmount);
        uint256 tLiquidity = calculateLiquidityFee(state, tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate(ProtoType.Universe storage state)
        public
        view
        returns (uint256)
    {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(state);
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply(ProtoType.Universe storage state)
        public
        view
        returns (uint256, uint256)
    {
        uint256 rSupply = state._rTotal;
        uint256 tSupply = state._tTotal;
        for (uint256 i = 0; i < state._excluded.length; i++) {
            if (
                state._rProtoOwned[state._excluded[i]] > rSupply ||
                state._tProtoOwned[state._excluded[i]] > tSupply
            ) return (state._rTotal, state._tTotal);
            rSupply = rSupply.sub(state._rProtoOwned[state._excluded[i]]);
            tSupply = tSupply.sub(state._tProtoOwned[state._excluded[i]]);
        }
        if (rSupply < state._rTotal.div(state._tTotal))
            return (state._rTotal, state._tTotal);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(ProtoType.Universe storage state, uint256 _amount)
        public
        view
        returns (uint256)
    {
        return _amount.mul(state._taxFee).div(10**4);
    }

    function calculateLiquidityFee(
        ProtoType.Universe storage state,
        uint256 _amount
    ) public view returns (uint256) {
        return _amount.mul(state._liquidityFee).div(10**4);
    }

    function excludeFromReward(
        ProtoType.Universe storage state,
        address account
    ) external {
        require(!state._isExcluded[account], "Account is already excluded");
        if (state._rProtoOwned[account] > 0) {
            state._tProtoOwned[account] = tokenFromReflection(
                state,
                state._rProtoOwned[account]
            );
        }
        state._isExcluded[account] = true;
        state._excluded.push(account);
    }

    function includeInReward(ProtoType.Universe storage state, address account)
        external
    {
        require(state._isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < state._excluded.length; i++) {
            if (state._excluded[i] == account) {
                state._excluded[i] = state._excluded[state._excluded.length -
                    1];
                state._tProtoOwned[account] = 0;
                state._isExcluded[account] = false;
                state._excluded.pop();
                break;
            }
        }
    }

    function setswapAndLiquifyEnabled(
        ProtoType.Universe storage state,
        bool _enabled
    ) external {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        state.swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function addLiquidity(
        ProtoType.Universe storage state,
        uint256 tokenAmount,
        uint256 bnbAmount
    ) public {
        // approve token transfer to cover all possible scenarios
        _approve(
            state,
            address(this),
            address(state.pancakeSwapV2Router),
            tokenAmount
        );

        // add the liquidity
        state.pancakeSwapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            state.daoCouncil(),
            block.timestamp
        );
    }

    function isExcludedFromReward(
        ProtoType.Universe storage state,
        address account
    ) public view returns (bool) {
        return state._isExcluded[account];
    }

    function _takeLiquidity(
        ProtoType.Universe storage state,
        uint256 tLiquidity
    ) public {
        uint256 currentRate = _getRate(state);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        state._rProtoOwned[address(this)] = state._rProtoOwned[address(this)]
            .add(rLiquidity);
        if (state._isExcluded[address(this)])
            state._tProtoOwned[address(this)] = state._tProtoOwned[address(
                this
            )]
                .add(tLiquidity);
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./Address.sol";
import "./Pancake.sol";
import "./CrowdContributionInterface.sol";
import "./IBEP20.sol";
import "./IProtoDistribution.sol";
import "./ProtoType.sol";
import "./ProtoBEP20.sol";

library ProtoDrop {
    using SafeMath for uint256;
    using Address for address;
    using ProtoType for ProtoType.Universe;
    using ProtoERC20 for ProtoType.Universe;

    function deliver(ProtoType.Universe storage state, uint256 tAmount)
        external
    {
        address sender = msg.sender;
        require(
            !state._isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = state._getValues(tAmount);
        state._rProtoOwned[sender] = state._rProtoOwned[sender].sub(rAmount);
        state._rTotal = state._rTotal.sub(rAmount);
        state._tFeeTotal = state._tFeeTotal.add(tAmount);
    }

    function unclaimedRewards(ProtoType.Universe storage state)
        external
        view
        returns (uint256)
    {
        return
            state.tokenFromReflection(state._lOwned[msg.sender].rOwned).sub(
                state._lOwned[msg.sender].lockedAmount
            );
    }

    function claimTokensFromLockedToken(ProtoType.Universe storage state)
        external
    {
        require(state.transferEnabled, "Transfers are disabled");
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
                transferVestingAmount = state._lOwned[receiver]
                    .amount
                    .mul(diff)
                    .div(state._lOwned[receiver].vesting);

                state._lOwned[receiver].lastReward = block.timestamp;
                state._lOwned[receiver].count = state._lOwned[receiver]
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
                    transferVestingAmount = state._lOwned[receiver]
                        .amount
                        .mul(diff)
                        .div(state._lOwned[receiver].vesting);

                    state._lOwned[receiver].lastReward = block.timestamp;
                    state._lOwned[receiver].count = state._lOwned[receiver]
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

    function claimDCEProtoTokens(ProtoType.Universe storage state) public {
        require(
            !state._dceProtoClaimed[msg.sender],
            "Your PROTO Tokens already credited"
        );


            CrowdContributionInterface.LockedToken memory tokenFromContribution
         = lockedProtoFromCrowdContribution(msg.sender);
        require(tokenFromContribution.amount > 0, "No tokens to claim");
        state._lOwned[msg.sender] = ProtoType.LockedProto({
            isUnlocked: tokenFromContribution.isUnlocked,
            unlockedTime: tokenFromContribution.unlockedTime,
            vesting: tokenFromContribution.vesting,
            lastReward: tokenFromContribution.lastReward,
            count: tokenFromContribution.count,
            amount: tokenFromContribution.amount,
            lockedAmount: tokenFromContribution.lockedAmount,
            rOwned: state.reflectionFromToken(
                tokenFromContribution.lockedAmount,
                false
            )
        });
        state._dceProtoClaimed[msg.sender] = true;
        state._dceLawClaimAllowed[msg.sender] = true;
    }

    function allowedDCELawClaim(
        ProtoType.Universe storage state,
        address account
    ) external view returns (uint256) {
        if (state._dceLawClaimAllowed[account])
            return state._lOwned[account].amount;
        return 0;
    }

    function lockedProtoFromCrowdContribution(address account)
        public
        pure
        returns (CrowdContributionInterface.LockedToken memory)
    {
        return
            CrowdContributionInterface(
                0x070082b98eDa716c9B0009c14A5650Eb51208796
            )
                .lockedToken(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Address.sol";
import "./IProtoDistribution.sol";
import "./ProtoType.sol";
import "./ProtoBEP20.sol";
import "./ProtoDao.sol";

library ProtoLiquidity {
    using SafeMath for uint256;
    using Address for address;
    using ProtoType for ProtoType.Universe;
    using ProtoType for ProtoType.LockedProto;
    using ProtoERC20 for ProtoType.Universe;
    using ProtoDao for ProtoType.Universe;

    function totalFees(ProtoType.Universe storage state)
        public
        view
        returns (uint256)
    {
        return state._tFeeTotal;
    }

    function isExcludedFromFee(
        ProtoType.Universe storage state,
        address account
    ) external view returns (bool) {
        return state._isExcludedFromFee[account];
    }

    function excludeFromFee(ProtoType.Universe storage state, address account)
        external
    {
        state._isExcludedFromFee[account] = true;
    }

    function includeInFee(ProtoType.Universe storage state, address account)
        external
    {
        state._isExcludedFromFee[account] = false;
    }

    function setNumTokensSellToAddToLiquidity(
        ProtoType.Universe storage state,
        uint256 _ProtoAmount
    ) external {
        state.numTokensSellToAddToLiquidity = _ProtoAmount;
    }

    function setNumTokensSellToSwapBUSD(
        ProtoType.Universe storage state,
        uint256 _ProtoAmount
    ) external {
        state.numTokensSellToSwapBUSD = _ProtoAmount;
    }

    function setTaxFeePercent(ProtoType.Universe storage state, uint256 taxFee)
        external
    {
        require(
            taxFee.add(state._liquidityFee) <= 1000,
            "Fees cannot be more than 10%"
        );
        state._taxFee = taxFee;
    }

    function setLiquidityFeePercent(
        ProtoType.Universe storage state,
        uint256 liquidityFee
    ) external {
        require(
            state._taxFee.add(liquidityFee) <= 1000,
            "Fees cannot be more than 10%"
        );

        state._liquidityFee = liquidityFee;
    }

    function setMAXTxPercent(
        ProtoType.Universe storage state,
        uint256 _MAXTxPercent
    ) external {
        state.MAXTxAmount = state._tTotal.mul(_MAXTxPercent).div(10**2);
    }

    function setPancakeAddress(
        ProtoType.Universe storage state,
        address _v,
        bool createLiquidityPair
    ) external {
        state.pancakeRouterAddress = _v;
        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(
            state.pancakeRouterAddress
        );
        if (createLiquidityPair) {
            // Create a pancakeSwap pair for this new token
            state.pancakeSwapV2Pair = IPancakeSwapV2Factory(
                _pancakeSwapV2Router.factory()
            )
                .createPair(address(this), _pancakeSwapV2Router.WETH());
        }
        state.pancakeSwapV2Router = _pancakeSwapV2Router;
    }

    function setBUSDAddress(ProtoType.Universe storage state, address _v)
        external
    {
        state.BUSDAddress = _v;
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

interface IPancakeSwapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IPancakeSwapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IBEP20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./SafeMath.sol";
import "./Address.sol";
import "./ProtoType.sol";
import "./ProtoBEP20.sol";

library ProtoDistribution {
    using SafeMath for uint256;
    using Address for address;
    using ProtoERC20 for ProtoType.Universe;

    function getProtoShare(
        ProtoType.PreAllocation storage allocation,
        address account
    ) public view returns (uint256) {
        return allocation.shares[account];
    }

    function unlockTime(
        ProtoType.PreAllocation storage allocation,
        address account
    ) public view returns (uint256) {
        if (allocation.isCoreWallet[account]) return block.timestamp + 120 days;
        if (allocation.isAidWallet[account]) return block.timestamp + 95 days;
        return allocation.lockTimes[account];
    }

    function vestingTime(
        ProtoType.PreAllocation storage allocation,
        address account
    ) public view returns (uint256) {
        if (allocation.isCoreWallet[account]) return 730;
        if (allocation.isAidWallet[account]) return 90;
        return 1825;
    }

    function getAllocation(
        ProtoType.PreAllocation storage allocation,
        address account
    )
        public
        view
        returns (
            uint256 _share,
            uint256 _unlockTime,
            uint256 _vestingTime
        )
    {
        return (
            getProtoShare(allocation, account),
            unlockTime(allocation, account),
            vestingTime(allocation, account)
        );
    }

    function preAllocatedWallets(ProtoType.PreAllocation storage allocation)
        external
        pure
        returns (address[39] memory)
    {
        return [
            0x7eE1aEdB31F85600a9061c3C507D4f02439Bcd31,
            0x96cB54D88cDC95bD27c176BA73843b231FA37007,
            0x5D37B29E4Fd931033cac0F08700572edEc4F87a4,
            0x97ED5a2549A6F1DC2348C069a4C33ff1f1B97d31,
            0x7643E2eDa0BE58d5eC4b29EF4cd4F6622abf513a,
            0x5c8736014EefE5B47899a34E81a6A81921b70e9E,
            0x7b27Ff7547cACC48C4BE9c2bf031Af0B7FebdEE0,
            0x61a4CcF4Ed78AFE6aBc1FE074CbA1FD5E7e8b6D6,
            0x0bf368960898DDB4602638eC29d7733e0430f197,
            0xE6160014858e64d22Ba4a1098c4e287f65323438,
            0xc7986e638D670811C5a5E3fc9F2e731afFe51933,
            0xdBf9DC5F9781602E7E4e61B3d39642dDd3C96317,
            0xc9d9aC4C30Ec4bee66004ac942E74Bb11d0Aec1b,
            0x90E75CaF23E99dc6ED56B8EA45c89E23fEfa82d8,
            0xe44f68c38Efd0F065b2CF0B5860CB22ce1303283,
            0xd7040920889bCd7ca43E6ce212298Bb8cc725f6b,
            0xd837a89655dcfA336B289524D5B0bB2cD649feAE,
            0xE4D4205B508918815e7b894D6A1205E9E923Ef23,
            0x78e9Beab0102c3EF9f90b0bE9B7D0e143A76bB18,
            0x822A016190008124f0855EEf5159Bfc5B9F17BaB,
            0xa9Be3399fFe11885c2Cf3E83F6B157eA01cDAb49,
            0x2C94c6a843cDF400A3aCb41e9e776E40712050AB,
            0xC33A0fd7aF52331c31fDE62883365c07E73457fc,
            0x84dDC3A43e85bF6eb450A40c7B8EF51310fcB37d,
            0x578e8c05DF9aCad0127471bc0Cb620f2Da12B725,
            0x9d3cD26da568093fF2d68B5d38c124832DC23cA9,
            0xCc3476b2ED2E4CD65B32F1C1316d69843C1f9C34,
            0x2f3D5B579541903B6A7E61Eeb66Ee45A4d58616f,
            0x93fA1B33C8993345e3597171F5d39D40f036Cd2B,
            0x08E4717a449E175B7bFc1FF71d8228F64677a370,
            0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F,
            0x47fd4076556EB209c616cCD5619393CC913e6E8A,
            0x9b22E636CACA80C9E243E6bDe1fdc198a297a972,
            0x1Ba159A3C1C5aA0a5600d8DCC3Ef3F8de05c9D20,
            0x8fc135fcA69049CDfC982CdC8772c0b432Bc3302,
            0xfC864d405AfcB40127A2c1555a0C7EE01E172023,
            0xb77fCf61E3e97fd0f2f757E66B88D95631b02541,
            0x77a45B76BDAC9A9C4bDd66e400Dd048B1b2C6236,
            0xE180B12EC6dF7EbB24D7C525E8F8b73433542e5a
        ];
    }

    function initProtoDistribution(
        ProtoType.PreAllocation storage allocation,
        ProtoType.Universe storage state
    ) external {
        require(!allocation.isInitialized, "Already Initialized");
        uint256 currentRate = state._getRate();
        require(currentRate > 0, "Rate cannot be zero");

        allocation.aidWallets = [
            0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F,
            0x47fd4076556EB209c616cCD5619393CC913e6E8A,
            0x9b22E636CACA80C9E243E6bDe1fdc198a297a972
        ];

        allocation.coreWallets = [
            0x7eE1aEdB31F85600a9061c3C507D4f02439Bcd31,
            0x96cB54D88cDC95bD27c176BA73843b231FA37007,
            0x5D37B29E4Fd931033cac0F08700572edEc4F87a4,
            0x97ED5a2549A6F1DC2348C069a4C33ff1f1B97d31,
            0x7643E2eDa0BE58d5eC4b29EF4cd4F6622abf513a,
            0x5c8736014EefE5B47899a34E81a6A81921b70e9E,
            0x7b27Ff7547cACC48C4BE9c2bf031Af0B7FebdEE0,
            0x61a4CcF4Ed78AFE6aBc1FE074CbA1FD5E7e8b6D6,
            0x0bf368960898DDB4602638eC29d7733e0430f197,
            0xE6160014858e64d22Ba4a1098c4e287f65323438,
            0xc7986e638D670811C5a5E3fc9F2e731afFe51933,
            0xdBf9DC5F9781602E7E4e61B3d39642dDd3C96317,
            0xc9d9aC4C30Ec4bee66004ac942E74Bb11d0Aec1b,
            0x90E75CaF23E99dc6ED56B8EA45c89E23fEfa82d8,
            0xe44f68c38Efd0F065b2CF0B5860CB22ce1303283,
            0xd7040920889bCd7ca43E6ce212298Bb8cc725f6b,
            0xd837a89655dcfA336B289524D5B0bB2cD649feAE,
            0xE4D4205B508918815e7b894D6A1205E9E923Ef23,
            0x78e9Beab0102c3EF9f90b0bE9B7D0e143A76bB18,
            0x822A016190008124f0855EEf5159Bfc5B9F17BaB,
            0xa9Be3399fFe11885c2Cf3E83F6B157eA01cDAb49,
            0x2C94c6a843cDF400A3aCb41e9e776E40712050AB,
            0xC33A0fd7aF52331c31fDE62883365c07E73457fc,
            0x84dDC3A43e85bF6eb450A40c7B8EF51310fcB37d,
            0x578e8c05DF9aCad0127471bc0Cb620f2Da12B725,
            0x9d3cD26da568093fF2d68B5d38c124832DC23cA9,
            0xCc3476b2ED2E4CD65B32F1C1316d69843C1f9C34,
            0x2f3D5B579541903B6A7E61Eeb66Ee45A4d58616f,
            0x93fA1B33C8993345e3597171F5d39D40f036Cd2B,
            0x08E4717a449E175B7bFc1FF71d8228F64677a370
        ];

        for (uint256 i = 0; i < allocation.coreWallets.length; i++) {
            allocation.isCoreWallet[allocation.coreWallets[i]] = true;
            state._dceLawClaimAllowed[allocation.coreWallets[i]] = true;
        }

        for (uint256 i = 0; i < allocation.aidWallets.length; i++) {
            allocation.isAidWallet[allocation.aidWallets[i]] = true;
            state._dceLawClaimAllowed[allocation.aidWallets[i]] = true;
        }

        allocation.shares[0x7eE1aEdB31F85600a9061c3C507D4f02439Bcd31] = uint256(
            3300000e18
        )
            .mul(currentRate);
        allocation.shares[0x96cB54D88cDC95bD27c176BA73843b231FA37007] = uint256(
            660000e18
        )
            .mul(currentRate);
        allocation.shares[0x5D37B29E4Fd931033cac0F08700572edEc4F87a4] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0x97ED5a2549A6F1DC2348C069a4C33ff1f1B97d31] = uint256(
            1980000e18
        )
            .mul(currentRate);
        allocation.shares[0x7643E2eDa0BE58d5eC4b29EF4cd4F6622abf513a] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0x5c8736014EefE5B47899a34E81a6A81921b70e9E] = uint256(
            5280000e18
        )
            .mul(currentRate);
        allocation.shares[0x7b27Ff7547cACC48C4BE9c2bf031Af0B7FebdEE0] = uint256(
            4620000e18
        )
            .mul(currentRate);
        allocation.shares[0x61a4CcF4Ed78AFE6aBc1FE074CbA1FD5E7e8b6D6] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0x0bf368960898DDB4602638eC29d7733e0430f197] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0xE6160014858e64d22Ba4a1098c4e287f65323438] = uint256(
            7260000e18
        )
            .mul(currentRate);
        allocation.shares[0xc7986e638D670811C5a5E3fc9F2e731afFe51933] = uint256(
            6600000e18
        )
            .mul(currentRate);
        allocation.shares[0xdBf9DC5F9781602E7E4e61B3d39642dDd3C96317] = uint256(
            1650000e18
        )
            .mul(currentRate);
        allocation.shares[0xc9d9aC4C30Ec4bee66004ac942E74Bb11d0Aec1b] = uint256(
            1650000e18
        )
            .mul(currentRate);
        allocation.shares[0x90E75CaF23E99dc6ED56B8EA45c89E23fEfa82d8] = uint256(
            1650000e18
        )
            .mul(currentRate);
        allocation.shares[0xe44f68c38Efd0F065b2CF0B5860CB22ce1303283] = uint256(
            1650000e18
        )
            .mul(currentRate);
        allocation.shares[0xd7040920889bCd7ca43E6ce212298Bb8cc725f6b] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0xd837a89655dcfA336B289524D5B0bB2cD649feAE] = uint256(
            6600000e18
        )
            .mul(currentRate);
        allocation.shares[0xE4D4205B508918815e7b894D6A1205E9E923Ef23] = uint256(
            6600000e18
        )
            .mul(currentRate);
        allocation.shares[0x78e9Beab0102c3EF9f90b0bE9B7D0e143A76bB18] = uint256(
            5940000e18
        )
            .mul(currentRate);
        allocation.shares[0x822A016190008124f0855EEf5159Bfc5B9F17BaB] = uint256(
            7260000e18
        )
            .mul(currentRate);
        allocation.shares[0xa9Be3399fFe11885c2Cf3E83F6B157eA01cDAb49] = uint256(
            6600000e18
        )
            .mul(currentRate);
        allocation.shares[0x2C94c6a843cDF400A3aCb41e9e776E40712050AB] = uint256(
            3300000e18
        )
            .mul(currentRate);
        allocation.shares[0xC33A0fd7aF52331c31fDE62883365c07E73457fc] = uint256(
            3300000e18
        )
            .mul(currentRate);
        allocation.shares[0x84dDC3A43e85bF6eb450A40c7B8EF51310fcB37d] = uint256(
            3300000e18
        )
            .mul(currentRate);
        allocation.shares[0x578e8c05DF9aCad0127471bc0Cb620f2Da12B725] = uint256(
            3300000e18
        )
            .mul(currentRate);
        allocation.shares[0x9d3cD26da568093fF2d68B5d38c124832DC23cA9] = uint256(
            3300000e18
        )
            .mul(currentRate);
        allocation.shares[0xCc3476b2ED2E4CD65B32F1C1316d69843C1f9C34] = uint256(
            2640000e18
        )
            .mul(currentRate);
        allocation.shares[0x2f3D5B579541903B6A7E61Eeb66Ee45A4d58616f] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0x93fA1B33C8993345e3597171F5d39D40f036Cd2B] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0x08E4717a449E175B7bFc1FF71d8228F64677a370] = uint256(
            1320000e18
        )
            .mul(currentRate);
        allocation.shares[0xBeECB48a3ee6a4F6a2E637A12e38C3D567B1575F] = uint256(
            1650000e18
        )
            .mul(currentRate);
        allocation.shares[0x47fd4076556EB209c616cCD5619393CC913e6E8A] = uint256(
            1567500e18
        )
            .mul(currentRate);
        allocation.shares[0x9b22E636CACA80C9E243E6bDe1fdc198a297a972] = uint256(
            825000e18
        )
            .mul(currentRate);

        allocation.shares[0x1Ba159A3C1C5aA0a5600d8DCC3Ef3F8de05c9D20] = uint256(
            33000000e18
        )
            .mul(currentRate);
        allocation.shares[0x8fc135fcA69049CDfC982CdC8772c0b432Bc3302] = uint256(
            33000000e18
        )
            .mul(currentRate);
        allocation.shares[0xfC864d405AfcB40127A2c1555a0C7EE01E172023] = uint256(
            132000000e18
        )
            .mul(currentRate);
        allocation.shares[0xb77fCf61E3e97fd0f2f757E66B88D95631b02541] = uint256(
            26400000e18
        )
            .mul(currentRate);
        allocation.shares[0x77a45B76BDAC9A9C4bDd66e400Dd048B1b2C6236] = uint256(
            33000000e18
        )
            .mul(currentRate);
        allocation.shares[0xE180B12EC6dF7EbB24D7C525E8F8b73433542e5a] = uint256(
            33000000e18
        )
            .mul(currentRate);

        allocation.totalLock = uint256(554400000e18).mul(currentRate);

        allocation.lockTimes[allocation.listingSafe] =
            block.timestamp +
            110 days;
        allocation.lockTimes[allocation.reserveSafe] =
            block.timestamp +
            110 days;
        allocation.lockTimes[allocation.daoSafe] = block.timestamp + 140 days;
        allocation.lockTimes[allocation.auditsDevelopmentSafe] =
            block.timestamp +
            95 days;
        allocation.lockTimes[allocation.marketingSafe] =
            block.timestamp +
            95 days;
        allocation.lockTimes[allocation.yieldSafe] = block.timestamp + 95 days;

        allocation.isInitialized = true;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface ILawGovernance {
    function isProposalAccepted(address implementation)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProtoDistribution {
    function getProtoShare(address account) external view returns (uint256);

    function unlockTime(address account) external view returns (uint256);

    function vestingTime(address account) external view returns (uint256);

    function getAllocation(address account)
        external
        view
        returns (
            uint256 _share,
            uint256 _unlockTime,
            uint256 _vestingTime
        );

    function preAllocatedWallets() external pure returns (address[39] memory);

    function initProtoDistribution(uint256 currentRate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface CrowdContributionInterface {
    struct LockedToken {
        bool isUnlocked;
        uint256 unlockedTime;
        uint256 vesting;
        uint256 lastReward;
        uint256 count;
        uint256 amount;
        uint256 lockedAmount;
        uint256 rOwned;
    }

    function lockedToken(address) external pure returns (LockedToken memory);
}