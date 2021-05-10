// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
import "./access/ManagerRole.sol";
import "./interface/IERC20.sol";
import "./interface/IPool.sol";
import "./interface/IRoleModel.sol";
import "./utils/EnumerableSet.sol";
import "./math/SafeMath.sol";
contract AssetsManageTeam is ManagerRole, IRoleModel {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    event Request(address indexed pool, address from, uint256 maxValue);
    event Approve(address indexed pool, address to, uint256 maxValueToken, uint256 maxValue);
    event Disapprove(address indexed pool, address to);
    event Lock(address indexed pool, address to);
    event Unlock(address indexed pool, address to);
    event DepositERC20(address indexed pool, address from, address token, uint256 value);
    event Withdraw(address indexed pool, address to, uint256 value, address token);
    struct TeamOperation {
        address token;                 // Address token
        uint256 amountToken;           // Count token deposit
        uint256 withdraw;         // Count withdraw main network coin (ETH,BNB)
        uint256 time;                  // Time deposit
    }
    struct TeamAccount {
        bool lock;                     // Lock operation
        uint256 maxValueToken;         // Max value deposit token
        uint256 madeValueToken;        // Already made value
        uint256 maxValue;         // Max value withdraw main network coin (ETH,BNB)
        uint256 madeValue;        // Already withdrawn main network coin (ETH,BNB)
        address token;                 // Address token for withdrawal
    }
    mapping(address => mapping(address => TeamOperation[])) private _performedOperations;// Collection of investors who made a deposit token
    mapping(address => mapping(address => TeamAccount)) private _requests; // A collection of those who made the request
    mapping(address => mapping(address => TeamAccount)) private _approval;// Collection of those to whom the request was confirmed
    mapping(address => EnumerableSet.AddressSet) private _requestsTeam;// Collection of addresses that made the request
    mapping(address => EnumerableSet.AddressSet) private _approvalTeam;// Collection of addresses to which the request was confirmed
    function _depositToken(address pool, address team, address token, uint256 amount) external onlyManager returns (bool) {
        require(amount > 0, "AssetsManageTeam: the number of sent token is 0");
        require(!_approval[pool][team].lock, "AssetsManageTeam: deposit token locked");
        uint256 newAmount = _approval[pool][team].madeValueToken.add(amount);
        require(newAmount <= _approval[pool][team].maxValueToken, "AssetsManageTeam: token deposit not confirmed");
        IERC20(token).transferFrom(team, pool, amount);
        _approval[pool][team].madeValueToken = newAmount;
        _performedOperations[pool][team].push(TeamOperation(token,amount,0,block.timestamp));
        emit DepositERC20(pool, team, token, amount);
        return true;
    }
    function _withdrawInternal(address pool,address token, address team, uint256 amount) private returns (bool) {
        require(amount > 0, "AssetsManageTeam: the number of sent token is 0");
        require(!_approval[pool][team].lock, "AssetsManageTeam: deposit token locked");
        uint256 newAmount = _approval[pool][team].madeValue.add(amount);
        require(newAmount <= _approval[pool][team].maxValue, "AssetsManageTeam: withdraw not confirmed");
        _approval[pool][team].madeValue = newAmount;
        _performedOperations[pool][team].push(TeamOperation(token,0,amount,block.timestamp));
        emit Withdraw(pool, team, amount,token);
        return true;
    }
    function _withdraw(address pool, address team, uint256 amount) external onlyManager returns (bool) {
        return _withdrawInternal(pool, address(0), team, amount);
    }
    function _withdrawTokensToStartup(address pool,address token, address team, uint256 amount) external onlyManager returns (bool) {
        return _withdrawInternal(pool, token, team, amount);
    }
    function _requestInternal(bool withdraw, address pool, address team, uint256 maxValue,address token) private returns (bool) {
        require(pool != address(0), "AssetsManageTeam: pool zero address");
        require(team != address(0), "AssetsManageTeam: team zero address");
        require(maxValue > 0, "AssetsManageTeam: value is zero");
        require(IPool(pool).hasRole(STARTUP_TEAM_ROLE, team), "AssetsManageTeam: sender has no role TEAM");
        if (withdraw) {
            _requests[pool][team] = TeamAccount(true, 0, 0, maxValue, 0, token);
        } else {
            _requests[pool][team] = TeamAccount(true, maxValue, 0, 0, 0, token);
        }
        _requestsTeam[pool].add(team);
        emit Request(pool, team, maxValue);
        return true;
    }
    function _request(bool withdraw, address pool, address team, uint256 maxValue) external onlyManager returns(bool) {
        return _requestInternal(withdraw, pool, team, maxValue, address(0));
    }
    function _requestTokensWidthdrawalFromStartup(address pool, address token, address team, uint256 maxValue) external onlyManager returns(bool) {
        return _requestInternal(true, pool, team, maxValue, token);
    }
    function _approveTokensWidthdrawalFromStartup(address pool, address token, address team, address owner) external onlyManager returns(bool) {
        require(pool != address(0), "AssetsManageTeam: pool zero address");
        require(team != address(0), "AssetsManageTeam: team zero address");
        require(IPool(pool).hasRole(GENERAL_PARTNER_ROLE, owner), "AssetsManageTeam: owner has no role GPartner");
        uint256 maxValueToken = _requests[pool][team].maxValueToken;
        uint256 maxValue = _requests[pool][team].maxValue;
        if(_requests[pool][team].maxValue > 0) {
            if (_approvalTeam[pool].contains(team)) {
                _approval[pool][team].maxValue = (_approval[pool][team].maxValue).add(maxValue);
            } else {
                _approval[pool][team] = TeamAccount(false, 0, 0, maxValue, 0, token);
                _approvalTeam[pool].add(team);
            }
        }
        delete _requests[pool][team];
        _requestsTeam[pool].remove(team);
        emit Approve(pool, team, maxValueToken, maxValue);
        return true;
    }
    function _approve(address pool, address team, address owner) external onlyManager returns(bool) {
        require(pool != address(0), "AssetsManageTeam: pool zero address");
        require(team != address(0), "AssetsManageTeam: team zero address");
        require(IPool(pool).hasRole(GENERAL_PARTNER_ROLE, owner), "AssetsManageTeam: owner has no role GPartner");
        uint256 maxValueToken = _requests[pool][team].maxValueToken;
        uint256 maxValue = _requests[pool][team].maxValue;
        if (_requests[pool][team].maxValueToken > 0) {
            if (_approvalTeam[pool].contains(team)) {
                _approval[pool][team].maxValueToken = (_approval[pool][team].maxValueToken).add(maxValueToken);
            } else {
                _approval[pool][team] = TeamAccount(false, maxValueToken, 0, 0, 0,address(0));
                _approvalTeam[pool].add(team);
            }
        } else  if(_requests[pool][team].maxValue > 0) {
            if (_approvalTeam[pool].contains(team)) {
                _approval[pool][team].maxValue = (_approval[pool][team].maxValue).add(maxValue);
            } else {
                _approval[pool][team] = TeamAccount(false, 0, 0, maxValue, 0,address(0));
                _approvalTeam[pool].add(team);
            }
        }
        delete _requests[pool][team];
        _requestsTeam[pool].remove(team);
        emit Approve(pool, team, maxValueToken, maxValue);
        return true;
    }
    function _disapprove(address pool, address team, address owner) external onlyManager returns(bool) {
        require(_requestsTeam[pool].contains(team), "AssetsManageTeam: there is no request for this account");
        require(IPool(pool).hasRole(GENERAL_PARTNER_ROLE, owner), "AssetsManageTeam: owner has no role GPartner");
        delete _requests[pool][team];
        _requestsTeam[pool].remove(team);
        emit Disapprove(pool, team);
        return true;
    }
    function _lock(address pool, address team, address owner) external onlyManager returns(bool) {
        require(_approvalTeam[pool].contains(team), "AssetsManageTeam: team address not exists");
        require(!_approval[pool][team].lock, "AssetsManageTeam: the account is already blocked");
        require(IPool(pool).hasRole(GENERAL_PARTNER_ROLE, owner), "AssetsManageTeam: owner has no role GPartner");
        _approval[pool][team].lock = true;
        emit Lock(pool, team);
        return true;
    }
    function _unlock(address pool, address team, address owner) external onlyManager returns(bool) {
        require(_approvalTeam[pool].contains(team), "AssetsManageTeam: team address not exists");
        require(_approval[pool][team].lock, "AssetsManageTeam: the account is already blocked");
        require(IPool(pool).hasRole(GENERAL_PARTNER_ROLE, owner), "AssetsManageTeam: owner has no role GPartner");
        _approval[pool][team].lock = false;
        emit Unlock(pool, team);
        return true;
    }
    function getPerformedOperationsLength(address pool, address owner) public view returns(uint256 length) {
        return _performedOperations[pool][owner].length;
    }
    function getPerformedOperations(address pool, address owner, uint256 index) public view returns(address token, uint256 amountToken, uint256 withdraw, uint256 time) {
        return (_performedOperations[pool][owner][index].token,_performedOperations[pool][owner][index].amountToken, _performedOperations[pool][owner][index].withdraw,_performedOperations[pool][owner][index].time);
    }
    function getRequests(address pool) public view returns(address[] memory) {
        return _requestsTeam[pool].collection();
    }
    function getApproval(address pool) public view returns(address[] memory) {
        return _approvalTeam[pool].collection();
    }
    function getRequestTeamAddress(address pool, address team) public view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValue) {
        return (_requests[pool][team].lock,_requests[pool][team].maxValueToken,_requests[pool][team].madeValueToken,_requests[pool][team].maxValue,_requests[pool][team].madeValue);
    }
    function getApproveTeamAddress(address pool, address team) public view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValue) {
        return ( _approval[pool][team].lock,_approval[pool][team].maxValueToken,_approval[pool][team].madeValueToken,_approval[pool][team].maxValue,_approval[pool][team].madeValue);
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
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

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
        mapping (bytes32 => uint256) _indexes;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
        role._indexes[bytes32(uint256(account))] = role.accounts.length;
    }
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        uint256 valueIndex = role._indexes[bytes32(uint256(account))];
        if (valueIndex != 0) { // Equivalent to contains()
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = role.accounts.length - 1;
            address lastValue = role.accounts[lastIndex];
            role.accounts[toDeleteIndex] = lastValue;
            role.accounts.pop();
            delete role._indexes[bytes32(uint256(account))];
        }
//        for (uint256 i; i < role.accounts.length; i++) {
//            if (role.accounts[i] == account) {
//                _removeIndexArray(i, role.accounts);
//                break;
//            }
//        }
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
//    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
//        for(uint256 i = index; i < array.length-1; i++) {
//            array[i] = array[i+1];
//        }
//        array.pop();
//    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
interface IPool {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getDeposit(address owner, uint256 index) external view returns(uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, address investedToken);
    function getDepositLength(address owner) external view returns(uint256);
    function getMembersRole(bytes32 role) external view returns (address[] memory Accounts);
    function getInfoPool() external view returns(string memory name,bool isPublicPool, address token, uint256 locked);
    function getInfoPoolFees() external view returns(uint256 rate, uint256 depositFixedFee, uint256 referralDepositFee, uint256 annualPercent, uint256 penaltyEarlyWithdraw, uint256 totalInvestLpartner, uint256 premiumFee);
    function getReferral(address lPartner) external view returns (address);
    function getPoolValues() external view returns(uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue);
    function getPoolPairReserves() external view     returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast, address token0, address token1, address weth,uint price0CumulativeLast,uint price1CumulativeLast);
    function _updatePool(string calldata name,bool isPublicPool, address token, uint256 locked, uint256 depositFixedFee, uint256 referralDepositFee, uint256 annualPercent, uint256 penaltyEarlyWithdraw) external returns (bool);
    function _setRate(uint256 rate) external returns (bool);
    function _setTeamReward(uint256 teamReward) external returns (bool);
    function _setPoolValues(uint256 poolValueUSD,uint256 poolValue, string calldata proofOfValue) external returns (bool);
    function _depositPoolRegistry(address sender, uint256 amount, uint256 feesMultipier) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
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

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
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

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
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
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            address lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
//            for(uint256 i = 0; i < set._collection.length; i++) {
//                if (set._collection[i] == addressValue) {
//                    _removeIndexArray(i, set._collection);
//                    break;
//                }
//            }
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
//    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
//        for(uint256 i = index; i < array.length-1; i++) {
//            array[i] = array[i+1];
//        }
//        array.pop();
//    }
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
        return _remove(set._inner, bytes32(uint256(value)));
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}