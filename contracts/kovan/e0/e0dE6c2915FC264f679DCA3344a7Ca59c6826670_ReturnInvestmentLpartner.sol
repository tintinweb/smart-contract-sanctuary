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
    mapping(address => mapping(address => uint256[])) private _requests;// Collection request for return investment Limited Partner
    mapping(address => mapping(address => uint256[])) private _requestsAmounts;// Collection _requestsAmounts for return investment Limited Partner
    mapping(address => mapping(address => address[])) private _requestsTokenAddress;// Collection _requestsTokenAddress for return investment Limited Partner
    mapping(address => EnumerableSet.AddressSet) private _requestsLpartner;// Collection of addresses that made the request
    function _request(address pool, address lPartner, uint256 index, uint256 amount, address token) external onlyManager returns(bool) {
        require(IPool(pool).hasRole(LIMITED_PARTNER_ROLE, lPartner), "ReturnInvestmentLpartner: sender has no role Limited Partner");
        require(IPool(pool).getDepositLength(lPartner) > 0, "ReturnInvestmentLpartner: сurrent address has not been invested");
        require(index < IPool(pool).getDepositLength(lPartner), "ReturnInvestmentLpartner: deposit index does not exist");
        uint256 len = _requests[pool][lPartner].length;
        for (uint256 i = 0; i < len; i++) {
          require(_requests[pool][lPartner][i] != index, "ReturnInvestmentLpartner: a query with this index already exists");
        }
        _requests[pool][lPartner].push(index);
        _requestsAmounts[pool][lPartner].push(amount);
        _requestsTokenAddress[pool][lPartner].push(token);
        _requestsLpartner[pool].add(lPartner);
        emit Request(pool, lPartner, index, token);
        return true;
    }
    function _approve(address pool, address lPartner, address sender) external onlyManager returns(bool) {
        if (!_requestsLpartner[pool].contains(lPartner)) {
            emit ApproveError(pool, lPartner,"ReturnInvestmentLpartner: there is no request for this account");
            return false;
        }
        if (!IPool(pool).hasRole(GENERAL_PARTNER_ROLE, sender)) {
            emit ApproveError(pool, lPartner,"ReturnInvestmentLpartner: sender has no role General Partner");
            return false;
        }
        uint256 len = _requests[pool][lPartner].length;
        for (uint256 i = 0; i < len; i++) {
            IPool(pool)._approveWithdrawLpartner(lPartner, _requests[pool][lPartner][i], _requestsAmounts[pool][lPartner][i],_requestsTokenAddress[pool][lPartner][i]);
        }
        delete _requests[pool][lPartner];
        delete _requestsAmounts[pool][lPartner];
        delete _requestsTokenAddress[pool][lPartner];
        _requestsLpartner[pool].remove(lPartner);
        emit Approve(pool, lPartner);
        return true;
    }
    function _disapprove(address pool, address lPartner, address sender) external onlyManager returns(bool) {
        require(IPool(pool).hasRole(GENERAL_PARTNER_ROLE, sender), "ReturnInvestmentLpartner: sender has no role General Partner");
        require(_requestsLpartner[pool].contains(lPartner), "ReturnInvestmentLpartner: there is no request for this account");
        delete _requests[pool][lPartner];
        _requestsLpartner[pool].remove(lPartner);
        emit Disapprove(pool, lPartner);
        return true;
    }
    function getRequests(address pool) public view returns(address[] memory) {
        return _requestsLpartner[pool].collection();
    }
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
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
    }
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
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getDeposit(address owner, uint256 index) external view returns(uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, address investedToken);
    function getDepositLength(address owner) external view returns(uint256);
    function getMembersRole(bytes32 role) external view returns (address[] memory Accounts);
    function getInfoPool() external view returns(string memory name,bool isPublicPool, address token, uint256 locked);
    function getInfoPoolFees() external view returns(uint256 rate, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw, uint256 totalInvestLpartner, uint256 premiumFee);
    function getReferral(address lPartner) external view returns (address);
    function getPoolValues() external view returns(uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue);
    function getPoolPairReserves() external view     returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast, address token0, address token1, address weth,uint price0CumulativeLast,uint price1CumulativeLast);
    function _updatePool(string calldata name,bool isPublicPool, address token, uint256 locked, uint256 depositFixedFee, uint256 referralDepositFee, uint256 anualPrecent, uint256 penaltyEarlyWithdraw) external returns (bool);
    function _setRate(uint256 rate) external returns (bool);
    function _setTeamReward(uint256 teamReward) external returns (bool);
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
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant GENERAL_PARTNER_ROLE = keccak256("GENERAL_PARTNER_ROLE");
    bytes32 public constant LIMITED_PARTNER_ROLE = keccak256("LIMITED_PARTNER_ROLE");
    bytes32 public constant STARTUP_TEAM_ROLE = keccak256("STARTUP_TEAM_ROLE");
    bytes32 public constant POOL_REGISTRY = keccak256("POOL_REGISTRY");
    bytes32 public constant RETURN_INVESTMENT_LPARTNER = keccak256("RETURN_INVESTMENT_LPARTNER");
    bytes32 public constant ORACLE = keccak256("ORACLE");
    bytes32 public constant REFERER_ROLE = keccak256("REFERER_ROLE");
}

pragma solidity ^0.6.0;
library SafeMath {
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

pragma solidity ^0.6.0;
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        address[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)), value);
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}