/**
 *Submitted for verification at arbiscan.io on 2022-01-07
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:ADD_OVERFLOW");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:SUB_UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath:MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:DIV_ZERO");
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;

            set._values.pop();

            delete set._indexes[value];

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

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
}

abstract contract AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, msg.sender), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, msg.sender), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    modifier roleCheck(bytes32 role) {
        require(hasRole(role, msg.sender), "COMMISSION:DON'T_HAVE_PERMISSION");
        _;
    }
}

contract CommissionData is AccessControl{
    using SafeMath for uint;
    using Address for address payable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    // 收取佣金费用地址
    address payable receiveCommissionAddress;
    // 违约金收取地址
    address payable receiveViolateAddress;
    // 交易服务费
    address payable exchangeReceiveAddress;

    function setReceiveCommissionAddress(address payable addr) public roleCheck(ADMIN_ROLE) {
        receiveCommissionAddress = addr;
    }

    function setReceiveViolateAddress(address payable _addr) public roleCheck(ADMIN_ROLE) {
        receiveViolateAddress = _addr;
    }

    function setExchangeReceiveAddress(address payable deal) public roleCheck(ADMIN_ROLE) {
        exchangeReceiveAddress = deal;
    }
}

contract Commission is CommissionData {
    event CommissionCostReceiveLog(address factoryAddr, address receiveAddr, address tokenAddr, uint tokenNum);
    event ExchangeCostReceiveLog(address exchangeAddr, address receiveAddr, address tokenAddr, uint tokenNum);
    event ViolateReceiveLog(address factoryAddr, address receiveAddr, address tokenAddr, uint tokenNum);

    constructor(
        address payable _receiveCommissionAddress,
        address payable _receiveViolateAddress,
        address payable _exchangeReceiveAddress
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        setReceiveCommissionAddress(_receiveCommissionAddress);
        setReceiveViolateAddress(_receiveViolateAddress);
        setExchangeReceiveAddress(_exchangeReceiveAddress);
    }

    /*
     * 收取违约金
     * _erc20Addr  USD  或者 BTC 地址
     * num 收取的总费用
     */
    function violateCost(address _tokenAddr, uint _num) external payable {
        address payable _receiveViolateAddress = receiveViolateAddress;
        require(_receiveViolateAddress != address(0), "COMMISSION_ADDRESS_ZERO");

        uint _sendValue = msg.value;

        if (_sendValue > 0) {
            _receiveViolateAddress.sendValue(_sendValue);
            _num = _sendValue;
        } else {
            IERC20(_tokenAddr).transferFrom(msg.sender, _receiveViolateAddress, _num);
        }
        emit ViolateReceiveLog(msg.sender, _receiveViolateAddress, _tokenAddr, _num);
    }

    /*
     * 收取佣金费用
     * _erc20Addr  USD  或者 BTC 地址
     * num 收取的总费用
     */
    function commissionCost(address _tokenAddr, uint _num) external payable {
        address payable _oneselfCommissionAddress = receiveCommissionAddress;
        require(_oneselfCommissionAddress != address(0), "COMMISSION_ADDRESS_ZERO");

        uint _sendValue = msg.value;

        if (_sendValue > 0) {
            _oneselfCommissionAddress.sendValue(_sendValue);
            _num = _sendValue;
        } else {
            IERC20(_tokenAddr).transferFrom(msg.sender, _oneselfCommissionAddress, _num);
        }
        emit CommissionCostReceiveLog(msg.sender, _oneselfCommissionAddress, _tokenAddr, _num);
    }

    // 收取交易服务费  BTC USD
    function exchangeCost(address _tokenAddr, uint256 _num) external payable {
        address payable _exchangeReceiveAddress = exchangeReceiveAddress;
        require(_exchangeReceiveAddress != address(0), "EXCHANGE_SERVICE_ADDRESS_ZERO");

        uint _sendValue = msg.value;

        if (_sendValue > 0) {
            _exchangeReceiveAddress.sendValue(_sendValue);
            _num = _sendValue;
        } else {
            IERC20(_tokenAddr).transferFrom(msg.sender, _exchangeReceiveAddress, _num);
        }
        emit ExchangeCostReceiveLog(msg.sender, _exchangeReceiveAddress, _tokenAddr, _num);
    }
}