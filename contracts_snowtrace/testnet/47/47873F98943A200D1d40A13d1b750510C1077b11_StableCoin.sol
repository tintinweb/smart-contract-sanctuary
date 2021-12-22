// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.1;

import "./Context.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC20.sol";
import "./ExternallyTransferable.sol";

contract StableCoin is
    ContextAware, // provides _msgSender(), _msgData()
    Pausable, // provides _pause(), _unpause()
    Ownable, // Ownable, Claimable
    AccessControl, // RBAC for KYC, Frozen
    ERC20, // ERC20 Functions (transfer, balance, allowance, mint, burn)
    ExternallyTransferable // Supports External Transfers
{
    // Defined Roles
    bytes32 private constant KYC_PASSED = keccak256("KYC_PASSED");
    bytes32 private constant FROZEN = keccak256("FROZEN");

    // Special People
    address private _supplyManager;
    address private _complianceManager;
    address private _enforcementManager;

    // Events Emitted
    event Constructed(
        string tokenName,
        string tokenSymbol,
        uint8 tokenDecimal,
        uint256 totalSupply,
        address supplyManager,
        address complianceManager,
        address enforcementManager
    );

    // Privileged Roles
    event ChangeSupplyManager(address newSupplyManager);
    event ChangeComplianceManager(address newComplianceManager);
    event ChangeEnforcementManager(address newEnforcementManager);

    // ERC20+
    event Wipe(address account, uint256 amount);
    event Mint(address account, uint256 amount);
    event Burn(address account, uint256 amount);
    event Transfer(address sender, address recipient, uint256 amount);
    event Approve(address sender, address spender, uint256 amount);
    event IncreaseAllowance(address sender, address spender, uint256 amount);
    event DecreaseAllowance(address sender, address spender, uint256 amount);

    // KYC
    event Freeze(address account); // Freeze: Freeze this account
    event Unfreeze(address account);
    event SetKycPassed(address account);
    event UnsetKycPassed(address account);

    // Halt
    event Pause(address sender); // Pause: Pause entire contract
    event Unpause(address sender);

    // "External Transfer"
    // Signify to the coin bridge to perform external transfer
    event ApproveExternalTransfer(
        address from,
        string networkURI,
        bytes to,
        uint256 amount
    );
    event ExternalTransfer(
        address from,
        string networkURI,
        bytes to,
        uint256 amount
    );
    event ExternalTransferFrom(
        bytes from,
        string networkURI,
        address to,
        uint256 amount
    );

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimal,
        uint256 totalSupply,
        address supplyManager,
        address complianceManager,
        address enforcementManager
    ) public ERC20(tokenName, tokenSymbol, tokenDecimal) {
        _supplyManager = supplyManager;
        _complianceManager = complianceManager;
        _enforcementManager = enforcementManager;

        // Owner has Admin Privileges on all roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // sudo role

        // Give CM ability to grant/revoke roles (but not admin of this role)
        grantRole(DEFAULT_ADMIN_ROLE, complianceManager);

        // KYC accounts
        grantRole(KYC_PASSED, _msgSender());
        grantRole(KYC_PASSED, supplyManager);
        grantRole(KYC_PASSED, complianceManager);
        grantRole(KYC_PASSED, enforcementManager);

        // Give supply manager all tokens
        mint(totalSupply); // Emits Mint

        // Did it
        emit Constructed(
            tokenName,
            tokenSymbol,
            tokenDecimal,
            totalSupply,
            supplyManager,
            complianceManager,
            enforcementManager
        );
    }

    /*
     * RBAC
     */

    function supplyManager() public view returns (address) {
        return _supplyManager;
    }

    modifier onlySupplyManager() {
        require(
            _msgSender() == supplyManager() || _msgSender() == owner(),
            "Only the supply manager can call this function."
        );
        _;
    }

    function changeSupplyManager(address newSupplyManager) public onlyOwner {
        require(
            newSupplyManager != address(0),
            "Cannot change supply manager to 0x0."
        );
        revokeRole(KYC_PASSED, _supplyManager);
        _supplyManager = newSupplyManager;
        grantRole(KYC_PASSED, _supplyManager);
        revokeRole(FROZEN, _supplyManager);
        emit ChangeSupplyManager(newSupplyManager);
    }

    function complianceManager() public view returns (address) {
        return _complianceManager;
    }

    modifier onlyComplianceManager() {
        require(
            _msgSender() == complianceManager() || _msgSender() == owner(),
            "Only the Compliance Manager can call this function."
        );
        _;
    }

    function changeComplianceManager(address newComplianceManager)
        public
        onlyOwner
    {
        require(
            newComplianceManager != address(0),
            "Cannot change compliance manager to 0x0."
        );
        revokeRole(KYC_PASSED, _complianceManager);
        _complianceManager = newComplianceManager;
        grantRole(KYC_PASSED, _complianceManager);
        revokeRole(FROZEN, _complianceManager);
        emit ChangeComplianceManager(newComplianceManager);
    }

    function enforcementManager() public view returns (address) {
        return _enforcementManager;
    }

    modifier onlyEnforcementManager() {
        require(
            _msgSender() == enforcementManager() || _msgSender() == owner(),
            "Only the Enforcement Manager can call this function."
        );
        _;
    }

    function changeEnforcementManager(address newEnforcementManager)
        public
        onlyOwner
    {
        require(
            newEnforcementManager != address(0),
            "Cannot change enforcement manager to 0x0"
        );
        revokeRole(KYC_PASSED, _enforcementManager);
        _enforcementManager = newEnforcementManager;
        grantRole(KYC_PASSED, _enforcementManager);
        revokeRole(FROZEN, _enforcementManager);
        emit ChangeEnforcementManager(newEnforcementManager);
    }

    function isPrivilegedRole(address account) public view returns (bool) {
        return
            account == supplyManager() ||
            account == complianceManager() ||
            account == enforcementManager() ||
            account == owner();
    }

    modifier requiresKYC() {
        require(
            hasRole(KYC_PASSED, _msgSender()),
            "Calling this function requires KYC approval."
        );
        _;
    }

    function isKycPassed(address account) public view returns (bool) {
        return hasRole(KYC_PASSED, account);
    }

    // KYC: only CM
    function setKycPassed(address account) public onlyComplianceManager {
        grantRole(KYC_PASSED, account);
        emit SetKycPassed(account);
    }

    // Un-KYC: only CM, only non-privileged accounts
    function unsetKycPassed(address account) public onlyComplianceManager {
        require(
            !isPrivilegedRole(account),
            "Cannot unset KYC for administrator account."
        );
        require(account != address(0), "Cannot unset KYC for address 0x0.");
        revokeRole(KYC_PASSED, account);
        emit UnsetKycPassed(account);
    }

    modifier requiresNotFrozen() {
        require(
            !hasRole(FROZEN, _msgSender()),
            "Your account has been frozen, cannot call function."
        );
        _;
    }

    function isFrozen(address account) public view returns (bool) {
        return hasRole(FROZEN, account);
    }

    // Freeze an account: only CM, only non-privileged accounts
    function freeze(address account) public onlyComplianceManager {
        require(
            !isPrivilegedRole(account),
            "Cannot freeze administrator account."
        );
        require(account != address(0), "Cannot freeze address 0x0.");
        grantRole(FROZEN, account);
        emit Freeze(account);
    }

    // Unfreeze an account: only CM
    function unfreeze(address account) public onlyComplianceManager {
        revokeRole(FROZEN, account);
        emit Unfreeze(account);
    }

    // Check Transfer Allowed (user facing)
    function checkTransferAllowed(address account) public view returns (bool) {
        return isKycPassed(account) && !isFrozen(account);
    }

    // Pause: Only CM
    function pause() public onlyComplianceManager {
        _pause();
        emit Pause(_msgSender());
    }

    // Unpause: Only CM
    function unpause() public onlyComplianceManager {
        _unpause();
        emit Unpause(_msgSender());
    }

    // Claim Ownership
    function claimOwnership() public override(Ownable) onlyProposedOwner {
        address prevOwner = owner();
        super.claimOwnership(); // emits ClaimOwnership
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(KYC_PASSED, _msgSender());
        revokeRole(FROZEN, _msgSender());
        revokeRole(KYC_PASSED, prevOwner);
    }

    // Wipe
    function wipe(address account, uint256 amount) public onlyEnforcementManager {
        uint256 balance = balanceOf(account);
        require(
            amount <= balance,
            "Amount cannot be greater than balance"
        );
        super._transfer(account, _supplyManager, amount);
        _burn(_supplyManager, amount);
        emit Wipe(account, amount);
    }

    /*
     * Transfers
     */

    // Mint
    function mint(uint256 amount) public onlySupplyManager {
        _mint(supplyManager(), amount);
        emit Mint(_msgSender(), amount);
    }

    // Burn
    function burn(uint256 amount) public onlySupplyManager {
        _burn(_supplyManager, amount);
        emit Burn(_msgSender(), amount);
    }

    // Check Transfer Allowed (internal)
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) requiresKYC requiresNotFrozen whenNotPaused {
        if (from == supplyManager() && to == address(0)) {
            // allowed (burn)
            super._beforeTokenTransfer(from, to, amount);
            return;
        }

        if (to == supplyManager() && from == address(0)) {
            // allowed (mint)
            super._beforeTokenTransfer(from, to, amount);
            return;
        }

        if (
            to == supplyManager() &&
            hasRole(FROZEN, from) &&
            amount == balanceOf(from)
        ) {
            // allowed (wipe account)
            super._beforeTokenTransfer(from, to, amount);
            return;
        }

        // All other transfers
        require(isKycPassed(from), "Sender account requires KYC to continue.");
        require(isKycPassed(to), "Receiver account requires KYC to continue.");
        require(!isFrozen(from), "Sender account is frozen.");
        require(!isFrozen(to), "Receiver account is frozen.");
        super._beforeTokenTransfer(from, to, amount); // callbacks from above (if any)
    }

    function transfer(address to, uint256 amount) public override(ERC20) {
        super._transfer(_msgSender(), to, amount);
        emit Transfer(_msgSender(), to, amount);
    }

    /*
     * External Transfers
     */

    // approve an allowance for transfer to an external network
    function approveExternalTransfer(
        string memory networkURI,
        bytes memory externalAddress,
        uint256 amount
    )
        public
        override(ExternallyTransferable)
        requiresKYC
        requiresNotFrozen
        whenNotPaused
    {
        require(
            amount <= balanceOf(_msgSender()),
            "Cannot approve more than balance."
        );
        super.approveExternalTransfer(networkURI, externalAddress, amount);
        emit ApproveExternalTransfer(
            _msgSender(),
            networkURI,
            externalAddress,
            amount
        );
    }

    function externalTransfer(
        address from,
        string memory networkURI,
        bytes memory to,
        uint256 amount
    ) public override(ExternallyTransferable) onlySupplyManager whenNotPaused {
        require(isKycPassed(from), "Spender account requires KYC to continue.");
        require(!isFrozen(from), "Spender account is frozen.");
        uint256 exAllowance = externalAllowanceOf(from, networkURI, to);
        require(amount <= exAllowance, "Amount greater than allowance.");
        super._transfer(from, _supplyManager, amount);
        _burn(_supplyManager, amount);
        _approveExternalAllowance(
            from,
            networkURI,
            to,
            exAllowance.sub(amount)
        );
        emit ExternalTransfer(from, networkURI, to, amount);
    }

    function externalTransferFrom(
        bytes memory from,
        string memory networkURI,
        address to,
        uint256 amount
    ) public override(ExternallyTransferable) onlySupplyManager whenNotPaused {
        require(isKycPassed(to), "Recipient account requires KYC to continue.");
        require(!isFrozen(to), "Recipient account is frozen.");
        _mint(_supplyManager, amount);
        super._transfer(_supplyManager, to, amount);
        emit ExternalTransferFrom(from, networkURI, to, amount);
    }

    /*
     * Allowances
     */

    // Check Allowance Allowed (internal)
    function _beforeTokenAllowance(
        address sender,
        address spender,
        uint256 amount
    ) internal override(ERC20) requiresKYC requiresNotFrozen whenNotPaused {
        require(isKycPassed(spender), "Spender account requires KYC to continue.");
        require(isKycPassed(sender), "Sender account requires KYC to continue.");
        require(!isFrozen(spender), "Spender account is frozen.");
        require(!isFrozen(sender), "Sender account is frozen.");
        require(amount >= 0, "Allowance must be greater than 0.");
    }

    // Transfer From (allowance --> user)
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(ERC20) requiresKYC requiresNotFrozen {
        super.transferFrom(from, to, amount);
        emit Transfer(from, to, amount);
        emit Approve(from, _msgSender(), allowance(from, _msgSender()));
    }

    // Approve Allowance
    function approveAllowance(address spender, uint256 amount)
        public
        override(ERC20)
        requiresKYC
        requiresNotFrozen
    {
        super._approve(_msgSender(), spender, amount);
        emit Approve(_msgSender(), spender, amount);
    }

    // Increase Allowance
    function increaseAllowance(address spender, uint256 amount)
        public
        override(ERC20)
        requiresKYC
        requiresNotFrozen
    {
        uint256 newAllowance = allowance(_msgSender(), spender).add(amount);
        _approve(_msgSender(), spender, newAllowance);
        emit IncreaseAllowance(_msgSender(), spender, newAllowance);
    }

    // Decrease Allowance
    function decreaseAllowance(address spender, uint256 amount)
        public
        override(ERC20)
        requiresKYC
        requiresNotFrozen
    {
        uint256 newAllowance = allowance(_msgSender(), spender).sub(
            amount,
            "Amount greater than allowance."
        );
        _approve(_msgSender(), spender, newAllowance);
        emit DecreaseAllowance(_msgSender(), spender, newAllowance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21;

contract ContextAware {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21;

import "./Context.sol";

contract Pausable is ContextAware {
    bool private _paused;

    constructor() public {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21;

import "./Context.sol";

contract Ownable is ContextAware {
    address private _owner;
    address private _proposedOwner;

    event ProposeOwner(address indexed proposedOwner);
    event ClaimOwnership(address newOwner);

    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ClaimOwnership(msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function proposedOwner() public view returns (address) {
        return _proposedOwner;
    }

    modifier onlyOwner() {
        require(
            _owner == _msgSender(),
            "Only the owner can call this function."
        );
        _;
    }

    modifier onlyProposedOwner() {
        require(
            _msgSender() == _proposedOwner,
            "Only the proposed owner can call this function."
        );
        _;
    }

    function disregardProposedOwner() private onlyOwner {
        _proposedOwner = address(0);
    }

    function proposeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Cannot propose 0x0 as new owner.");
        _proposedOwner = newOwner;
        emit ProposeOwner(_proposedOwner);
    }

    function claimOwnership() public virtual onlyProposedOwner {
        _owner = _proposedOwner;
        _proposedOwner = address(0);
        emit ClaimOwnership(_owner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

import "./Context.sol";

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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
 * NOTE: This contract is a stripped down version of the OZ AccessControl
 * contract that does not emit events or allow for external access
 */
contract AccessControl is ContextAware {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    constructor() public {}

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function grantRole(bytes32 role, address account) internal virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) internal virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        _roles[role].members.add(account);
    }

    function _revokeRole(bytes32 role, address account) private {
        _roles[role].members.remove(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.1;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

import "./Context.sol";

/*
 * NOTE: This is a stripped down version of the OZ ERC20 Contract that does not
 * emit events and that renames approve --> approveAllowance
 */
abstract contract ERC20 is ContextAware {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual {
        _transfer(_msgSender(), recipient, amount);
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approveAllowance(address spender, uint256 amount) public virtual {
        _approve(_msgSender(), spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }

    function _beforeTokenAllowance(address owner, address spender, uint256 amount) internal virtual { }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _beforeTokenAllowance(owner, spender, amount);

        _allowances[owner][spender] = amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.1;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./Context.sol";

abstract contract ExternallyTransferable is ContextAware {
    using SafeMath for uint256;

    // address => string (network URI) => bytes (external address) => amount
    mapping(address => mapping(string => mapping(bytes => uint256)))
        private _externalAllowances;

    function externalAllowanceOf(
        address owner,
        string memory networkURI,
        bytes memory externalAddress
    ) public view returns (uint256) {
        return _externalAllowances[owner][networkURI][externalAddress];
    }

    // User calls to allocate external transfer
    function approveExternalTransfer(
        string memory networkURI,
        bytes memory externalAddress,
        uint256 amount
    ) public virtual {
        _approveExternalAllowance(_msgSender(), networkURI, externalAddress, amount);
    }

    // Bridge calls after externalTransfer
    function _approveExternalAllowance(
        address from,
        string memory networkURI,
        bytes memory to,
        uint256 amount
    ) internal virtual {
        require(_msgSender() != address(0), "Approve from the zero address");
        require(from != address(0), "Approve for the zero address");
        _externalAllowances[from][networkURI][to] = amount;
    }

    // Bridge calls to burn coins on this network (sending external transfer)
    function externalTransfer(
        address from,
        string memory networkURI,
        bytes memory to, // external address
        uint256 amount
    ) public virtual {}

    // Bridge calls to mint coins on this network (receiving external transfer)
    function externalTransferFrom(
        bytes memory from, // external address
        string memory networkURI,
        address to,
        uint256 amount
    ) public virtual {}
}

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

pragma solidity ^0.6.2;

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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}