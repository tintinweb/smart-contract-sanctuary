//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/Bank/ITreasury.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Comptroller.sol";
import "../interfaces/IWETH.sol";

// Comment this out for production, it's a debug tool
// import "hardhat/console.sol";

contract Treasury is ITreasury, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    // State variables
    address[] public debtors;
    // debtor address => collateral address => collateral balance
    mapping(address=>mapping(address=>uint)) public deposits;

    // Debtor address => fxToken => debt amount
    mapping(address=>mapping(address=>uint)) public debts;
    
    // Debtor => has collateral on deposit
    mapping(address=>bool) public depositors;

    // debtor=>array of collateral deposited
    mapping(address=>address[]) public collateralAvailable;

    // tokenAddress=>collateral balance held
    mapping(address=>uint256) public totalBalances;
    
    // Reward tokens
    address public mintToken;

    // Comptroller
    address payable public comptroller;

    // Weth address
    address public immutable WETH;

    // Roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address _comptroller, address _router, address _weth) {
        comptroller = payable(_comptroller);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, _comptroller);
        _setupRole(OPERATOR_ROLE, _router);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        WETH = _weth;
    }

    receive() external payable {        
        require(msg.sender == WETH, "Contract not payable"); // only accept ETH via fallback from the WETH contract
    }
    
    // Functions

    /// @notice increases a user's debt for a given token
    /// @dev can only be called by the comptroller
    /// @param account the user's address
    /// @param amount the amount to add to their debt
    /// @param fxToken the asset to increase
    function increaseDebtPosition(address account, uint amount, address fxToken) external override onlyOperator {
        debts[account][fxToken] = debts[account][fxToken].add(amount);
    }

    /// @notice deposits collateral into the user's account
    /// @dev requires the collateral token to have already been transferred to the Treasury.
    /// @param account the account to deposit into
    /// @param depositAmount the amount to add
    /// @param collateralType the type of collateral being deposited
    function depositCollateral(address account, uint depositAmount, address collateralType) external nonReentrant override {
        require(Comptroller(comptroller).isCollateralValid(collateralType), "Collateral is invalid"); 
        
        // Open a vault if it's a new user
        _createNewVault(account);

        // Update balances 
        uint currentTotalBalance = totalBalances[collateralType];

        deposits[account][collateralType] = deposits[account][collateralType].add(depositAmount);
        totalBalances[collateralType] = totalBalances[collateralType].add(depositAmount);
        
        // Transfer collateral into the treasury 
        require(IERC20(collateralType).transferFrom(msg.sender, address(this), depositAmount), "Transfer of collateral failed");

        // Verify transfer amount
        require(IERC20(collateralType).balanceOf(address(this)).sub(currentTotalBalance) == depositAmount, "Deposit amount is invalid");
 
        emit Deposit(account, depositAmount, collateralType);
    }

    /**
     * @notice allows the user to deposit with eth
     * @param account the account to deposit into
     */
    function depositCollateralETH(address account) external payable override nonReentrant {
        require(Comptroller(comptroller).isCollateralValid(WETH), "Collateral is invalid"); 
        
        // Open a vault if it's a new user
        _createNewVault(account);
        
        // Update balances 
        uint currentTotalBalance = totalBalances[WETH];
        deposits[account][WETH] = deposits[account][WETH].add(msg.value);
        totalBalances[WETH] = totalBalances[WETH].add(msg.value);

        // Wrap incoming ether into WETH
        IWETH(WETH).deposit{value: msg.value}();

        // Verify transfer amount
        require(IERC20(WETH).balanceOf(address(this)).sub(currentTotalBalance) == msg.value, "Deposit amount is invalid");
 
        emit DepositETH(account, msg.value);
    }

    /// @notice decreases a user's debt for a given token
    /// @dev can only be called by the comptroller
    /// @param account the user's address
    /// @param amount the amount to remove from their debt
    /// @param fxToken the asset to decrease
    function decreaseDebtPosition(address account, uint amount, address fxToken) external override onlyOperator {
        debts[account][fxToken] = debts[account][fxToken].sub(amount);
    }

    /**
    * @notice withdraws ERC20 collateral 
    * @dev can be used for all collateral types
    * @param collateralToken the token to withdraw
    * @param to the address to remit to
    * @param amount the amount of collateral to withdraw
    */
    function withdrawCollateral(address collateralToken, address to, uint amount) external nonReentrant override {
        require(Comptroller(comptroller).getFreeCollateral(msg.sender) >= amount, "Not enough free collateral to withdraw");

        // getFreeCollateral considers all collateral tokens to be equivalent.
        require(deposits[msg.sender][collateralToken]>= amount, "Not enough of collateral type to withdraw");
        
        // Update user's deposit balance
        deposits[msg.sender][collateralToken] = deposits[msg.sender][collateralToken].sub(amount);
        
        // Update totalBalances 
        totalBalances[collateralToken] = totalBalances[collateralToken].sub(amount);

        // Remit collateral to the user
        uint balanceBefore = IERC20(collateralToken).balanceOf(to);
        IERC20(collateralToken).transfer(to, amount);
        assert(IERC20(collateralToken).balanceOf(to) == balanceBefore.add(amount));

        emit Withdrawal(collateralToken, to, amount);
    }
    /**
    * @notice withdraws WETH collateral as ETH
    * @param to the address to remit to
    * @param amount the amount of collateral to withdraw
    */
    function withdrawCollateralETH(address to, uint amount) external nonReentrant override {
        // Check available collateral
        require(Comptroller(comptroller).getFreeCollateral(msg.sender) >= amount, "Not enough free collateral to withdraw");
        
        // getFreeCollateral considers all collateral tokens to be equivalent.
        require(deposits[msg.sender][WETH]>= amount, "Not enough WETH to withdraw");
        
        // Update user's deposit balance
        deposits[msg.sender][WETH] = deposits[msg.sender][WETH].sub(amount);
        
        // Update totalBalances 
        totalBalances[WETH] = totalBalances[WETH].sub(amount);

        // Unwrap weth
        IWETH(WETH).withdraw(amount);
        assert(address(this).balance == amount);

        // Remit eth to user
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed");
        
        emit WithdrawalETH(to, amount);
    }
  
    // Modifiers
    modifier onlyOperator(){
        require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");
        _;
    }

    modifier onlyAdmin(){
        // Protect user deposits from abuse
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }
    
    // Admin functions
    function setComptroller(address _comptroller) external override onlyAdmin {
        comptroller = payable(_comptroller);
        grantRole(OPERATOR_ROLE, comptroller);
    }

    function setRewardToken(address token, bytes32 which) external override onlyAdmin {
        require(false, "Not implemented yet");
    }

    // Getters
    /// @notice Returns a user's collateral balance for a given collateral type
    /// @param account the user's address
    /// @param collateralType the collateral token address
    /// @return balance 
    function getCollateralBalance(address account, address collateralType) external view override returns(uint balance) {
        balance = deposits[account][collateralType];
    }

    function getBalance(address account) external view override returns (address[] memory collateral, uint[] memory balances) {
        collateral = Comptroller(comptroller).getAllCollateralTypes();
        uint[] memory _balances = new uint[](collateral.length);
        for (uint i=0; i < collateral.length; i++) {
            _balances[i] = deposits[account][collateral[i]];
        }

        balances = _balances;
    }

    function _createNewVault(address account) private {
        require(account != address(0), "Invalid address");
        // Open a vault if it's a new user
        if (depositors[account] == false) {
            debtors.push(account);
            depositors[account] = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITreasury {
    // Events
    event Withdrawal(address indexed collateralToken, address indexed to, uint amount);
    event WithdrawalETH(address indexed to, uint amount);
    event Deposit(address indexed owner, uint amount, address indexed collateralType);
    event DepositETH(address indexed account, uint amount);

    // State changing functions
    function increaseDebtPosition(address account, uint amount, address fxToken) external;
    function decreaseDebtPosition(address account, uint amount, address fxToken) external;
    function depositCollateral(address account, uint depositAmount, address collateralType) external;
    function depositCollateralETH(address account) external payable;
    function withdrawCollateral(address collateralToken, address to, uint amount) external;
    function withdrawCollateralETH(address to, uint amount) external;

    // Variable setters
    function setComptroller(address comptroller) external;
    function setRewardToken(address token, bytes32 which) external;

    // Getters
    function getCollateralBalance(address account, address collateralType) external view returns(uint balance);
    function getBalance(address account) external view returns (address[] memory collateral, uint[] memory balances);
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

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/Bank/IComptroller.sol";
import "../interfaces/Bank/IRegistry.sol";
import {Treasury as ITreasury} from "./Treasury.sol";
import "../interfaces/Bank/IfxToken.sol";
import "../interfaces/IDeadline.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/Bank/IOracle.sol";

// Comment this out for production, it's a debug tool
// import "hardhat/console.sol";

contract Comptroller is IComptroller, IRegistry, IDeadline, Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // Registry state variables
    address public MintRewardToken;
    address public PoolRewardToken;
    address payable public Treasury;
    address public immutable WETH;
    uint constant minMintDeviation = 5;

    // Comptroller state variables
    address[] public collateralTokens;
    mapping(address=>bool) public isCollateralValid;
    address[] public validFxTokens;
    mapping(address=>bool) public isFxTokenValid;
    mapping(address => TokenData) public tokenDetails;

    // Oracles
    // fxAsset => oracle address
    mapping(address=>address) public oracles;
    
    constructor(
        address _MintRewardToken,
        address _PoolRewardToken,
        address _weth
    ) {
        MintRewardToken = _MintRewardToken;
        PoolRewardToken = _PoolRewardToken;
        WETH = _weth;

    }
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /**
     * @notice allows a user to deposit ETH and mint fxTokens in a single transaction
     * @param tokenAmountDesired the amount of fxTokens the user wants
     * @param token the token to mint
     * @param deadline the time on which the transaction is invalid. 
     */
    function mintWithEth(
        uint tokenAmountDesired,
        address token,
        uint deadline
    ) external override payable dueBy(deadline) nonReentrant {
        require(isFxTokenValid[token], "fxToken is not valid");
        require(isCollateralValid[WETH], "wETH is not accepted");

        // Check the vault ratio is correct (fxToken <-> WETH)
        uint quote = getTokenPrice(token);
        require(
            getFreeCollateral(msg.sender).add(msg.value) >= getMinimumCollateralETH(
                tokenAmountDesired,
                tokenDetails[token].mintCR,
                quote
            ),
            "Minimum collateral ratio not met"
        );

        // Mint tokens
        uint balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).mint(msg.sender, tokenAmountDesired);
        assert(IfxToken(token).balanceOf(msg.sender) == balanceBefore.add(tokenAmountDesired));
        
        // Update debt position
        uint debtPosition = ITreasury(Treasury).debts(msg.sender, token);
        ITreasury(Treasury).increaseDebtPosition(msg.sender, tokenAmountDesired, token);
        assert(debtPosition.add(tokenAmountDesired) == ITreasury(Treasury).debts(msg.sender, token));
        
        // Convert to wETH
        IWETH(WETH).deposit{value: msg.value}();
        assert(IERC20(WETH).approve(Treasury, msg.value));

        // Deposit in the treasury
        balanceBefore = ITreasury(Treasury).getCollateralBalance(msg.sender, WETH);
        ITreasury(Treasury).depositCollateral(msg.sender, msg.value, WETH);
        assert(ITreasury(Treasury).getCollateralBalance(msg.sender, WETH) == msg.value.add(balanceBefore));
        
        emit MintToken(quote, msg.value);
    }

    // Mint with ERC20 as collateral
    function mint(
        uint tokenAmountDesired,
        address token,
        address collateralToken,
        address to,
        uint deadline
    ) external override dueBy(deadline) nonReentrant {
        require(isCollateralValid[collateralToken], "Collateral token is not valid");
    }

    /**
     * @notice allows an user to mint fxTokens with existing collateral
     * @param tokenAmountDesired the amount of fxTokens the user wants
     * @param token the token to mint
     * @param deadline the time on which the transaction is invalid. 
     */
    function mintWithoutCollateral(
        uint tokenAmountDesired,
        address token,
        uint deadline
    ) external override dueBy(deadline) {
        require(isFxTokenValid[token], "fxToken is not valid");

        // Check the vault ratio is correct (fxToken <-> collateral)
        uint quote = getTokenPrice(token);
        require(
            getFreeCollateral(msg.sender) >= getMinimumCollateralETH(
            tokenAmountDesired,
            tokenDetails[token].mintCR,
            quote
        ),
            "Minimum collateral ratio not met"
        );

        // Mint tokens
        uint balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).mint(msg.sender, tokenAmountDesired);
        assert(IfxToken(token).balanceOf(msg.sender) == balanceBefore.add(tokenAmountDesired));

        // Update debt position
        uint debtPosition = ITreasury(Treasury).debts(msg.sender, token);
        ITreasury(Treasury).increaseDebtPosition(msg.sender, tokenAmountDesired, token);
        assert(debtPosition.add(tokenAmountDesired) == ITreasury(Treasury).debts(msg.sender, token));
        
        emit MintToken(quote, 0);
    }

    /**
     * @notice allows an user to burn fxTokens
     * @param amount the amount of fxTokens to burn
     * @param token the token to burn
     * @param deadline the time on which the transaction is invalid. 
     */
    function burn(uint amount, address token, uint deadline) external override dueBy(deadline) {
        require(isFxTokenValid[token], "fxToken is not valid");
        require(IfxToken(token).balanceOf(msg.sender) >= amount, "Token balance is lower than burn amount");
        require(ITreasury(Treasury).debts(msg.sender, token) >= amount, "Treasury debt is lower than burn amount");
        
        // Burn tokens
        uint balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).burn(msg.sender, amount);
        assert(IfxToken(token).balanceOf(msg.sender) == balanceBefore.sub(amount));
        
        // Update debt position
        uint debtPositionBefore = ITreasury(Treasury).debts(msg.sender, token);
        ITreasury(Treasury).decreaseDebtPosition(msg.sender, amount, token);
        assert(ITreasury(Treasury).debts(msg.sender, token) == debtPositionBefore.sub(amount));
        
        emit BurnToken(amount);
    }

    function setFxToken(
        address token,
        uint _mintCR,
        uint _liquidateCR,
        uint _rewardCR,
        uint rewardRatio
    ) public override onlyOwner {
        if (!isFxTokenValid[token]) {
            validFxTokens.push(token);
            isFxTokenValid[token] = true;
        }
        tokenDetails[token] = TokenData({
            mintCR: _mintCR,
            liquidateCR: _liquidateCR,
            rewardCR: _rewardCR,
            rewardRatio: rewardRatio
        });
    }

    function removeFxToken(address token) external override onlyOwner {
        uint tokenIndex = validFxTokens.length + 1;
        for (uint i = 0; i < validFxTokens.length; i++) {
            if (validFxTokens[i] == token) {
                tokenIndex = i;
                break;
            }
        }
        require(tokenIndex < validFxTokens.length, "Cannot remove an invalid token");
        delete tokenDetails[token];
        delete isFxTokenValid[token];
        if(tokenIndex < validFxTokens.length -1){
            delete validFxTokens[tokenIndex];
            validFxTokens[tokenIndex] = validFxTokens[validFxTokens.length - 1];
            validFxTokens.pop();
        } else {
            delete validFxTokens[tokenIndex];
        }
    }

    function setValidTokens(
        address[] memory _collateralTokens,
        address[] memory _validFxTokens,
        uint _mintCR,
        uint _liquidateCR,
        uint _rewardCR,
        uint defaultRewardRatio
    ) external override onlyOwner returns (bool) {
        collateralTokens = _collateralTokens;
        for (uint i = 0; i < _collateralTokens.length; i++) {
            isCollateralValid[_collateralTokens[i]] = true;
        }
        for (uint i = 0; i < _validFxTokens.length; i++) {
            setFxToken(
                _validFxTokens[i],
                _mintCR,
                _liquidateCR,
                _rewardCR,
                defaultRewardRatio
            );
        }
        return true;
    }
    
    function addCollateralToken(address token) external override onlyOwner {
        if(!isCollateralValid[token]){
            isCollateralValid[token] = true;
            collateralTokens.push(token);
        }
    }
    
    function removeCollateralToken(address token) external override onlyOwner{
        // Cannot remove a token, as this would orphan user collateral. Mark it invalid instead.
        delete isCollateralValid[token];
    }
    
    function setTreasury(address treasury) external override onlyOwner  {
        require(treasury != address(0), "Treasury cannot be address 0");
        Treasury = payable(treasury);
    }
    
    function setMintToken(address token) external onlyOwner override {
        MintRewardToken = token;
    }
    
    function getRewardAmount(uint rate, uint tokenAmount) internal pure returns (uint reward){
        reward = tokenAmount.mul(rate).div(100);
    }
    
    function getTokenPrice(address token) public view override returns (uint quote){
        quote = IOracle(oracles[token]).getRate(token);
    }

    function getMinimumCollateralETH(uint tokenAmount, uint ratio, uint unitPrice) public pure override returns (uint minimum){
        minimum = unitPrice.mul(tokenAmount).div(1 ether).mul(ratio.sub(minMintDeviation)).div(100);
    }
    
    function getAllCollateralTypes() external view override returns (address[] memory collateral){
        collateral = collateralTokens;
    }
    
    function getAllFxTokens() external view override returns (address[] memory tokens){
        tokens = validFxTokens;
    }
    
    function getAllMintCR() external view override returns (uint[] memory ratios){
        uint[] memory _ratios = new uint[](validFxTokens.length);
        for(uint i = 0; i < _ratios.length; i++){
            _ratios[i] = tokenDetails[validFxTokens[i]].mintCR;
        }
        ratios = _ratios;
    }

    /**
    @notice calculates the amount of free collateral a given account has available
    @dev assumes that there's only one collateral type/all collateral types are equivalent. It will handle multiple collateral types, but only if the rate for all fxtokens for a given collateral type is the same for all collateral types.
    @param account the user to fetch the free collateral balance for
    @return free the amount of free collateral
     */
    function getFreeCollateral(address account) public view override returns (uint free){
        uint locked = 0;
        for(uint i = 0; i<validFxTokens.length; i++){
            locked = locked.add(
                getMinimumCollateralETH(
                    ITreasury(Treasury).debts(
                        account,
                        validFxTokens[i]
                    ),
                    tokenDetails[validFxTokens[i]].mintCR,
                    getTokenPrice(validFxTokens[i])
                )
            );
        }
        // Get total amount of collateral available.
        uint deposit = 0;
        for(uint i = 0; i<collateralTokens.length; i++){
            deposit = deposit.add(ITreasury(Treasury).getCollateralBalance(account, collateralTokens[i]));
        }

        if(locked >= deposit){
            free = 0;
        } else {
            free = deposit.sub(locked);
        }
    }

    /**
     * @notice sets an oracle for a given fxToken
     * @param _fxToken the fxToken to set the oracle for
     * @param _oracle the oracle to use for the fxToken
     */
    function setOracle(address _fxToken, address _oracle) external override onlyOwner{
        oracles[_fxToken] = _oracle;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <=0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

interface IComptroller {
    // Structs
    struct TokenData {
        uint mintCR;
        uint liquidateCR;
        uint rewardCR;
        uint rewardRatio;
    }
    
    // Events
    event MintToken(
        uint tokenRate,
        uint amountSpent
    );
    event BurnToken(
        uint amount
    );

    // Mint with ETH as collateral
    function mintWithEth(
        uint tokenAmountDesired, 
        address fxToken,
        uint deadline
    ) external payable;

    // Mint with ERC20 as collateral
    function mint(
        uint amountDesired,
        address fxToken,
        address collateralToken,
        address to,
        uint deadline
    ) external;

    function mintWithoutCollateral(
        uint tokenAmountDesired,
        address token,
        uint deadline
    ) external;
    
    // Burn to withdraw collateral
    function burn(
        uint amount,
        address token,
        uint deadline
    ) external;

    // Add/Update/Remove a token
    function setFxToken(
        address token,
        uint _mintCR, uint _liquidateCR, uint _rewardCR,
        uint rewardRatio
    ) external;

    // Update collateral tokens
    function setValidTokens(
        address[] memory _validCollateralTokens,
        address[] memory _validFxTokens,
        uint _mintCR, uint liquidateCR, uint rewardCR,
        uint defaultRewardRatio
    ) external returns (bool);
    function removeFxToken(address token) external;

    function addCollateralToken(address token) external;
    function removeCollateralToken(address token) external;

    // Getters
    function getTokenPrice(address token) external view returns (uint quote);
    function getMinimumCollateralETH(uint tokenAmount, uint ratio, uint unitPrice) external pure returns (uint minimum);
    function getAllCollateralTypes() external view returns (address[] memory collateral);
    function getAllMintCR() external view returns (uint[] memory ratios);
    function getAllFxTokens() external view returns (address[] memory tokens);
    function getFreeCollateral(address account) external view returns (uint free);
    function setOracle(address fxToken, address oracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IRegistry {
    function setTreasury(address treasury) external;
    function setMintToken(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IfxToken is IERC20 {
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface IDeadline {
    modifier dueBy(uint date) {
        require(block.timestamp <= date, "Transaction has exceeded deadline");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IOracle {
    /**
     * @notice Returns the cost for 1 fxAsset in ETH
     * @param fxAsset the asset to get a rate for
     * @return unitPrice the cost of a single fxAsset in ETH
     */
    function getRate(address fxAsset) external view returns (uint unitPrice);
    
    /**
     * @notice A setter function to add or update an oracle for a given fx asset.
     * @param fxAsset the asset to update 
     * @param oracle the oracle to set for the fxAsset 
     */
    function setOracle(address fxAsset, address oracle) external;
}