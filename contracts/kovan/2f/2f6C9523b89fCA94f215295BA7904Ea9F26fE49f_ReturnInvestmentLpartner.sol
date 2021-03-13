pragma solidity ^0.6.0;

import "./access/ManagerRole.sol";

import "./interface/IPool.sol";
import "./interface/IRoleModel.sol";

import "./utils/EnumerableSet.sol";
import "./math/SafeMath.sol";

contract ReturnInvestmentLpartner is ManagerRole, IRoleModel {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    event Request(address indexed pool, address from, uint256 index, address token);
    event Approve(address indexed pool, address to);
    event ApproveError(address indexed pool, address to, string error);
    event Disapprove(address indexed pool, address to);

    // Collection request for return investment Limited Partner
    mapping(address => mapping(address => uint256[])) private _requests;
    // Collection _requestsAmounts for return investment Limited Partner
    mapping(address => mapping(address => uint256[])) private _requestsAmounts;
    // Collection _requestsTokenAddress for return investment Limited Partner
    mapping(address => mapping(address => address[])) private _requestsTokenAddress;
    // Collection of addresses that made the request
    mapping(address => EnumerableSet.AddressSet) private _requestsLpartner;

    /**
    * @dev Creating a request for a return investment Limited partner.
    * @param pool The address Investment Pool contract.
    * @param lPartner The address account with role Limited partner.
    * @param index Investment index.
    * @return A boolean that indicates if the operation was successful.
    */
    function _request(address pool, address lPartner, uint256 index, uint256 amount, address token) external onlyManager returns(bool) {
        IPool _poolContract = IPool(pool);

        require(_poolContract.hasRole(LIMITED_PARTNER_ROLE, lPartner), "ReturnInvestmentLpartner: sender has no role Limited Partner");
        require(_poolContract.getDepositLength(lPartner) > 0, "ReturnInvestmentLpartner: сurrent address has not been invested");
        require(index < _poolContract.getDepositLength(lPartner), "ReturnInvestmentLpartner: deposit index does not exist");

        for (uint256 i = 0; i < _requests[pool][lPartner].length; i++) {
          require(_requests[pool][lPartner][i] != index, "ReturnInvestmentLpartner: a query with this index already exists");
        }

        _requests[pool][lPartner].push(index);
        _requestsAmounts[pool][lPartner].push(amount);
        _requestsTokenAddress[pool][lPartner].push(token);
        _requestsLpartner[pool].add(lPartner);

        emit Request(pool, lPartner, index, token);
        return true;
    }

    /**
    * @dev Approve of a request for return investment.
    * @param pool The address Investment Pool contract.
    * @param lPartner Address to confirm the request.
    * @param sender Address with general partner role.
    * @return A boolean that indicates if the operation was successful.
    */
    function _approve(address pool, address lPartner, address sender) external onlyManager returns(bool) {
//        require(_requestsLpartner[pool].contains(lPartner), "ReturnInvestmentLpartner: there is no request for this account");
        if (!_requestsLpartner[pool].contains(lPartner)) {
            emit ApproveError(pool, lPartner,"ReturnInvestmentLpartner: there is no request for this account");
            return false;
        }

        IPool _poolContract = IPool(pool);

//        require(_poolContract.hasRole(GENERAL_PARTNER_ROLE, sender), "ReturnInvestmentLpartner: sender has no role General Partner");
        if (!_poolContract.hasRole(GENERAL_PARTNER_ROLE, sender)) {
            emit ApproveError(pool, lPartner,"ReturnInvestmentLpartner: sender has no role General Partner");
            return false;
        }

        for (uint256 i = 0; i < _requests[pool][lPartner].length; i++) {
          _poolContract._approveWithdrawLpartner(lPartner, _requests[pool][lPartner][i], _requestsAmounts[pool][lPartner][i],_requestsTokenAddress[pool][lPartner][i]);
        }

        delete _requests[pool][lPartner];
        delete _requestsAmounts[pool][lPartner];
        delete _requestsTokenAddress[pool][lPartner];
        _requestsLpartner[pool].remove(lPartner);
        
        emit Approve(pool, lPartner);
        return true;
    }
    
    /**
    * @dev Disapprove of a request.
    * @param pool The address Investment Pool contract.
    * @param lPartner Address to disapprove.
    * @param sender Address with general partner role.
    * @return A boolean that indicates if the operation was successful.
    */
    function _disapprove(address pool, address lPartner, address sender) external onlyManager returns(bool) {
        IPool _poolContract = IPool(pool);

        require(_poolContract.hasRole(GENERAL_PARTNER_ROLE, sender), "ReturnInvestmentLpartner: sender has no role General Partner");
        require(_requestsLpartner[pool].contains(lPartner), "ReturnInvestmentLpartner: there is no request for this account");

        delete _requests[pool][lPartner];
        _requestsLpartner[pool].remove(lPartner);
 
        emit Disapprove(pool, lPartner);
        return true;
    }

    /**
    * @dev Get all requests.
    * @param pool address investment pool contract.
    */
    function getRequests(address pool) public view returns(address[] memory) {
        return _requestsLpartner[pool].collection();
    }

    /**
    * @dev Get all requests current LPartner.
    * @param pool address investment pool contract.
    * @param lPartner address limited parner role.
    */
    function getRequestsLpartner(address pool, address lPartner) public view returns(uint256[] memory) {
        return _requests[pool][lPartner];
    }
}

pragma solidity ^0.6.0;

import "./lib/Roles.sol";

contract ManagerRole {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private _managers;

    constructor () internal {
        _addManager(msg.sender);
    }

    modifier onlyManager() {
        require(isManager(msg.sender), "ManagerRole: caller does not have the Manager role");
        _;
    }

    function isManager(address account) public view returns (bool) {
        return _managers.has(account);
    }

    function getManagerAddresses() public view returns (address[] memory) {
        return _managers.accounts;
    }

    function addManager(address account) public onlyManager {
        _addManager(account);
    }

    function renounceManager() public {
        _removeManager(msg.sender);
    }

    function _addManager(address account) internal {
        _managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        _managers.remove(account);
        emit ManagerRemoved(account);
    }
}

pragma solidity ^0.6.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        
        for (uint256 i; i < role.accounts.length; i++) {
            if (role.accounts[i] == account) {
                _removeIndexArray(i, role.accounts);
                break;
            }
        }
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }

    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        
        array.pop();
    }
}

pragma solidity ^0.6.0;

interface IPool {

    // ***** GET INFO ***** //

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getDeposit(address owner, uint256 index) external view returns(uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, address investedToken);

    function getDepositLength(address owner) external view returns(uint256);

    function getMembersRole(bytes32 role) external view returns (address[] memory Accounts);

    function getInfoPool() external view returns(string memory name,bool isPublicPool, address token, uint256 locked);

    function getInfoPoolFees() external view returns(uint256 rate, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw, uint256 totalInvestLpartner, uint256 premiumFee);

    function getReferral(address lPartner) external view returns (address);

    function getPoolValues() external view returns(uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue);

    function getPoolPairReserves() external view returns (uint112 reserve0, uint112 reserve1, address token0, address token1, address weth);
// ***** SET INFO ***** //

    function _updatePool(string calldata name,bool isPublicPool, address token, uint256 locked, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw) external returns (bool);

    function _setRate(uint256 rate) external returns (bool);

    function _setPoolValues(uint256 poolValueUSD,uint256 poolValue, string calldata proofOfValue) external returns (bool);

    function _depositPoolRegistry(address sender, uint256 amount, uint256 feesMulitpier) external returns (bool);

    function _depositTokenPoolRegistry(address payable sender, uint256 amount) external returns (bool);

    function _depositInvestmentInTokensToPool(address payable sender, uint256 amount, address token) external returns (bool);

    function _withdrawTeam(address payable sender, uint256 amount) external returns (bool);

    function _withdrawTokensToStartup(address payable sender,address token, uint256 amount) external returns (bool);

    function _returnsInTokensFromTeam(address payable sender,address token, uint256 amount) external returns (bool);

    function _activateDepositToPool() external returns (bool);

    function _disactivateDepositToPool() external returns (bool);

    function _setReferral(address sender, address lPartner, address referral) external returns (bool);

    function _approveWithdrawLpartner(address lPartner, uint256 index, uint256 amount, address investedToken) external returns (bool);

    function _withdrawLPartner(address payable sender) external returns (bool, uint256, address);

    function _withdrawSuperAdmin(address payable sender,address token, uint256 amount) external returns (bool);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;
}

pragma solidity ^0.6.0;

contract IRoleModel {
    /**
     * SUPER_ADMIN_ROLE - The Role controls adding a new wallet addresses to according roles arrays
     */
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");

    /**
     * GENERAL_PARTNER_ROLE - The Role controls the approval process to transfer money inside
     *               investment pools and control Limited Partners adding, investment
     *               pools adding
     */
    bytes32 public constant GENERAL_PARTNER_ROLE = keccak256("GENERAL_PARTNER_ROLE");

    /**
     * LIMITED_PARTNER_ROLE - The Role allows the wallet of LP to invest money in the
     *               investment pool and withdraw money from there (access to limited pools)
     */
    bytes32 public constant LIMITED_PARTNER_ROLE = keccak256("LIMITED_PARTNER_ROLE");

    /**
     * TEAM_ROLE - Role that exposes access to wallets (the team member), were
     *           distributed all fees, fines, and success premiums from investment pools
     */
    bytes32 public constant STARTUP_TEAM_ROLE = keccak256("STARTUP_TEAM_ROLE");

    /**
     * POOL_REGISTRY - Registry of contract, which manage contract;
     */
    bytes32 public constant POOL_REGISTRY = keccak256("POOL_REGISTRY");

    /**
     * RETURN_INVESTMENT_LPARTNER - Management returns investment for Limitited partner role.
     */
    bytes32 public constant RETURN_INVESTMENT_LPARTNER = keccak256("RETURN_INVESTMENT_LPARTNER");

    bytes32 public constant ORACLE = keccak256("ORACLE");

    bytes32 public constant REFERER_ROLE = keccak256("REFERER_ROLE");

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
}

pragma solidity ^0.6.0;

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
        // Collection addresses
        address[] _collection;
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
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
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
    function _remove(Set storage set, bytes32 value, address addressValue) private returns (bool) {
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
            
            for(uint256 i = 0; i < set._collection.length; i++) {
                if (set._collection[i] == addressValue) {
                    _removeIndexArray(i, set._collection);
                    break;
                }
            }
            
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
    
    function _collection(Set storage set) private view returns (address[] memory) {
        return set._collection;    
    }
    
    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        
        array.pop();
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
        return _add(set._inner, bytes32(uint256(value)), value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)), value);
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
    
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
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
}