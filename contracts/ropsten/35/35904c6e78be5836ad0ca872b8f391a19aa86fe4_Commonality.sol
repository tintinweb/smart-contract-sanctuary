/**
 *Submitted for verification at Etherscan.io on 2021-09-27
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswapRouterV2 {
    // 获取汇率
    function getAmountsOut(uint _tokenNum, address[] memory _symbolAddress) external view returns (uint[] memory);
    // ETH兑换token
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
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
        require(hasRole(role, msg.sender), "INCOME:DON'T_HAVE_PERMISSION");
        _;
    }
}

contract Commonality is AccessControl{
    using SafeMath for uint;

    event distributeCharge(
        address _tokenAddr,
        address _addr,
        address _platformAddr,
        uint _platformCharge,
        address _fundAddr,
        uint _fundCharge,
        address _deployAddr,
        uint _deployNum,
        string contractNo
    );

    address public uniswapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bytes32 public constant ADMIN_ROLE = 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;

    constructor() public {
       _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
       _setupRole(ADMIN_ROLE, msg.sender);
    }

    function getAmounts(uint _tokenNum, address _addr1, address _addr2) external view returns (uint){
        IUniswapRouterV2 _uniswap = IUniswapRouterV2(uniswapAddress);
        address[] memory addr = new address[](2);
        addr[0] = _addr1;
        addr[1] = _addr2;
        uint[] memory amounts = _uniswap.getAmountsOut(_tokenNum, addr);
        return amounts[1];
    }

    function distributeChargeEth(
        uint _chargeNum,
        address payable _platformAddr,
        uint _platformRate,
        address payable _fundAddr,
        address payable _deployAddr,
        string memory contractNo
    ) external payable {
        uint _value = msg.value;
        uint _platformCharge = 0;
        uint _fundCharge = 0;

        if (_fundAddr != address(0)) {
            _platformCharge = _chargeNum.mul(_platformRate).div(100);
            _fundCharge = _chargeNum.sub(_platformCharge);
        } else {
            _platformCharge = _chargeNum;
        }

        _platformAddr.transfer(_platformCharge);
        if (_fundCharge > 0) {
            _fundAddr.transfer(_fundCharge);
        }

        uint _deployNum = _value.sub(_chargeNum);
        _deployAddr.transfer(_deployNum);

        emit distributeCharge(
            address(0),
            msg.sender,
            _platformAddr,
            _platformCharge,
            _fundAddr,
            _fundCharge,
            _deployAddr,
            _deployNum,
            contractNo
        );
    }

    function distributeChargeERC20(
        address _tokenAddr,
        uint _chargeNum,
        address _fundAddr,
        uint _platformRate,
        address _platformAddr,
        address _deployAddr,
        uint _deployNum,
        string memory contractNo
    ) external {
        IERC20 _erc20 = IERC20(_tokenAddr);
        uint _platformCharge = 0;
        uint _fundCharge = 0;

        if (_fundAddr != address(0)) {
            _platformCharge = _chargeNum.mul(_platformRate).div(100);
            _fundCharge = _chargeNum.sub(_platformCharge);
        } else {
            _platformCharge = _chargeNum;
        }

        _erc20.transferFrom(msg.sender, _platformAddr, _platformCharge);
        if (_fundCharge > 0) {
            _erc20.transferFrom(msg.sender, _fundAddr, _fundCharge);
        }

        _erc20.transferFrom(msg.sender, _deployAddr, _deployNum);

        emit distributeCharge(
            _tokenAddr,
            msg.sender,
            _platformAddr,
            _platformCharge,
            _fundAddr,
            _fundCharge,
            _deployAddr,
            _deployNum,
            contractNo
        );
    }
}