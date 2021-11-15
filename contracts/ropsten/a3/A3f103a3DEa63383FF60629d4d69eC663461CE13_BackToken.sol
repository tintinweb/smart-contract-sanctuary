//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../claimer/IClaimer.sol';

    struct Referrer {
        address account;
        uint256 startOfReferral;
    }

contract BackToken is IERC20, AccessControl {
    // Roles
    bytes32 public constant REFERRAL_MANAGER_ROLE = keccak256("REFERRAL_MANAGER_ROLE");

    // ERC20 structures
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Fees
    mapping (address => bool) private _excludedFromSendingFees;
    mapping (address => bool) private _excludedFromReceivingFees;
    uint256 private _claimerFeePercentage = 9;
    uint256 private _fundingFeePercentage = 1; // Funding fee percentage is also used to calculate referral fee percentage

    // Referral
    mapping (address => Referrer) private _referrers;
    uint256 private _minReferralBalance = 10 ether;
    uint256 private _referralTimeWindow = 3 * 30 days;

    IClaimer private _claimer; // Claimer contract can be null
    address private _fundingAddress;

    uint256 private constant TOTAL_SUPPLY = 500000000 ether; // 500'000'000 BACKs

    // ERC20 definitions
    string private _name = "BACK";
    string private _symbol = "BACK";
    uint8 private _decimals = 18;

    event ClaimerAddressChanged(address indexed newClaimer);
    event FundingAddressChanged(address indexed newFunding);
    event ReferrerSet(address indexed referrer, address indexed to, uint256 when);
    event ReferralTimeWindowChanged(uint256 newTimeWindow);
    event MinReferralBalanceChanged(uint256 newMinReferralBalance);
    event ClaimerFeePercentageChanged(uint256 newClaimerFeePercentage);
    event FundingFeePercentageChanged(uint256 newFundingFeePercentage);
    event AddressExcludedFromSendingFees(address indexed account, bool excluded);
    event AddressExcludedFromReceivingFees(address indexed account, bool excluded);

    constructor(address initialFundingAddress, address claimerAddress) {
        require(initialFundingAddress != address(0), "BackToken: funding address is the zero address");
        require(claimerAddress != address(0), "BackToken: claimer address is the zero address");

        // Give initial balance to contract creator
        _balances[_msgSender()] = TOTAL_SUPPLY;

        // Exclude the contract itself from fees
        _excludedFromSendingFees[address(this)] = true;
        _excludedFromReceivingFees[address(this)] = true;

        // Exclude the claimer and funding address from fees
        _excludedFromSendingFees[initialFundingAddress] = true;
        _excludedFromReceivingFees[initialFundingAddress] = true;
        _excludedFromSendingFees[claimerAddress] = true;
        _excludedFromReceivingFees[claimerAddress] = true;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REFERRAL_MANAGER_ROLE, _msgSender());

        _claimer = IClaimer(claimerAddress);
        _fundingAddress = initialFundingAddress;

        emit Transfer(address(0), _msgSender(), TOTAL_SUPPLY);
        emit ClaimerAddressChanged(claimerAddress);
    }

    modifier onlyAdmins() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BackToken: address is not an admin");
        _;
    }

    modifier onlyReferralManagers() {
        require(hasRole(REFERRAL_MANAGER_ROLE, _msgSender()), "BackToken: address is not a referral manager");
        _;
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

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() override external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function claimer() external view returns (IClaimer) {
        return _claimer;
    }

    function claimerFeePercentage() external view returns (uint256) {
        return _claimerFeePercentage;
    }

    function fundingFeePercentage() external view returns (uint256) {
        return _fundingFeePercentage;
    }

    function fundingAddress() external view returns (address) {
        return _fundingAddress;
    }

    function isExcludedFromSendingFees(address account) external view returns (bool) {
        return _excludedFromSendingFees[account];
    }

    function isExcludedFromReceivingFees(address account) external view returns (bool) {
        return _excludedFromReceivingFees[account];
    }

    function referralTimeWindow() external view returns (uint256) {
        return _referralTimeWindow;
    }

    function minReferralBalance() external view returns (uint256) {
        return _minReferralBalance;
    }

    function referrer(address account) external view returns (Referrer memory) {
        return _referrers[account];
    }

    function updateClaimer(address newClaimerAddress) external onlyAdmins {
        _excludedFromSendingFees[address(_claimer)] = false;
        _excludedFromReceivingFees[address(_claimer)] = false;
        _claimer = IClaimer(newClaimerAddress);

        if (newClaimerAddress != address(0)) {
            _excludedFromSendingFees[newClaimerAddress] = true;
            _excludedFromReceivingFees[newClaimerAddress] = true;
        }

        emit ClaimerAddressChanged(newClaimerAddress);
    }

    function updateFunding(address newFundingAddress) external onlyAdmins {
        _excludedFromSendingFees[_fundingAddress] = false;
        _excludedFromReceivingFees[_fundingAddress] = false;
        _fundingAddress = newFundingAddress;

        if (newFundingAddress != address(0)) {
            _excludedFromSendingFees[newFundingAddress] = true;
            _excludedFromReceivingFees[newFundingAddress] = true;
        }

        emit FundingAddressChanged(newFundingAddress);
    }

    function updateReferralTimeWindow(uint256 newReferralTimeWindow) external onlyReferralManagers {
        _referralTimeWindow = newReferralTimeWindow;
        emit ReferralTimeWindowChanged(newReferralTimeWindow);
    }

    function updateMinReferralBalance(uint256 newMinReferralBalance) external onlyReferralManagers {
        _minReferralBalance = newMinReferralBalance;
        emit MinReferralBalanceChanged(newMinReferralBalance);
    }

    function updateClaimerFeePercentage(uint256 newClaimerFeePercentage) external onlyAdmins {
        _claimerFeePercentage = newClaimerFeePercentage;
        emit ClaimerFeePercentageChanged(newClaimerFeePercentage);
    }

    function updateFundingFeePercentage(uint256 newFundingFeePercentage) external onlyAdmins {
        _fundingFeePercentage = newFundingFeePercentage;
        emit FundingFeePercentageChanged(newFundingFeePercentage);
    }

    function excludeAddressFromSendingFees(address account) external onlyAdmins {
        _excludeAddressFromSendingFees(account, true);
    }

    function setExcludeAddressFromSendingFees(address account, bool excluded) external onlyAdmins {
        _excludeAddressFromSendingFees(account, excluded);
    }

    function excludeAddressFromReceivingFees(address account) external onlyAdmins {
        _excludeAddressFromReceivingFees(account, true);
    }

    function setExcludeAddressFromReceivingFees(address account, bool excluded) external onlyAdmins {
        _excludeAddressFromReceivingFees(account, excluded);
    }

    function transfer(address recipient, uint256 amount) override external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferWithReferrer(address recipient, address _referrer, uint256 amount) external returns (bool) {
        _setReferrer(_referrer, _msgSender());
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 newAllowance = _allowances[sender][_msgSender()] - amount;
        _approve(sender, _msgSender(), newAllowance);
        return true;
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) override public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function setReferrer(address _referrer, address to) external onlyReferralManagers returns (bool) {
        _setReferrer(_referrer, to);
        return true;
    }

    function unsetReferrer(address to) external onlyReferralManagers returns (bool) {
        _unsetReferrer(to);
        return true;
    }

    function _setReferrer(address _referrer, address to) private {
        require(_referrer != address(0), "BackToken: referrer is the zero address");
        require(_referrers[to].account == address(0), "BackToken: referrer already set");
        require(to != address(0), "BackToken: referree is the zero address");

        Referrer memory ref;
        ref.account = _referrer;
        ref.startOfReferral = block.timestamp;

        _referrers[to] = ref;

        emit ReferrerSet(_referrer, to, block.timestamp);
    }

    function _unsetReferrer(address to) private {
        require(to != address(0), "BackToken: referree is the zero address");

        Referrer memory ref;
        ref.account = address(0);
        ref.startOfReferral = 0;

        _referrers[to] = ref;

        emit ReferrerSet(address(0), to, 0);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 actualAmount = amount;

        if (!_excludedFromSendingFees[from] && !_excludedFromReceivingFees[to]) {
            actualAmount = actualAmount - _applyClaimerFees(from, amount);

            uint256 stackedBalance = _isContract(address(_claimer))
            ? _claimer.balanceOf(_referrers[from].account)
            : 0;

            if (
                _referrers[from].account != address(0) &&
                _referrers[from].startOfReferral + _referralTimeWindow >= block.timestamp &&
                _balances[_referrers[from].account] + stackedBalance >= _minReferralBalance
            ) {
                actualAmount = actualAmount - _applyReferralFees(from, amount);
            } else {
                actualAmount = actualAmount - _applyFundingFees(from, amount);
            }
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + actualAmount;

        emit Transfer(from, to, actualAmount);
    }

    function _applyClaimerFees(address from, uint256 amount) private returns (uint256) {
        uint256 claimerFees = _calculateFee(amount, _claimerFeePercentage);

        address claimerAddr = address(_claimer);
        _balances[claimerAddr] = _balances[claimerAddr] + claimerFees;

        emit Transfer(from, claimerAddr, claimerFees);

        return claimerFees;
    }

    function _applyFundingFees(address from, uint256 amount) private returns (uint256) {
        uint256 fundingFees = _calculateFee(amount, _fundingFeePercentage);

        _balances[_fundingAddress] = _balances[_fundingAddress] + fundingFees;
        emit Transfer(from, _fundingAddress, fundingFees);

        return fundingFees;
    }

    function _applyReferralFees(address from, uint256 amount) private returns (uint256) {
        uint256 fundingFees = _calculateFee(amount, _fundingFeePercentage);

        _balances[_referrers[from].account] = _balances[_referrers[from].account] + fundingFees;
        emit Transfer(from, _referrers[from].account, fundingFees);

        return fundingFees;
    }

    function _calculateFee(uint256 amount, uint256 feePercentage) private pure returns (uint256) {
        return amount * feePercentage / 100;
    }

    function _excludeAddressFromSendingFees(address account, bool excluded) private {
        require(account != address(0), "BackToken: excluding the zero address");

        _excludedFromSendingFees[account] = excluded;
        emit AddressExcludedFromSendingFees(account, excluded);
    }

    function _excludeAddressFromReceivingFees(address account, bool excluded) private {
        require(account != address(0), "BackToken: excluding the zero address");

        _excludedFromReceivingFees[account] = excluded;
        emit AddressExcludedFromReceivingFees(account, excluded);(account, excluded);
    }

    function _isContract(address addr) private view returns (bool) {
        if (addr == address(0)) return false;

        uint32 size;
        assembly {
            size := extcodesize(addr)
        }

        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId
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
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;

import '../token/BackToken.sol';

interface IClaimer {
    function balanceOf(address account) external view returns (uint256);
    function withdraw() external returns (bool);
    function withdrawTo(address receiver) external returns (bool);
    function deposit(address sender, uint256 amount) external returns (bool);

    event Withdraw(address indexed by, address indexed to, uint256 amount);
    event Deposited(address indexed by, address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

