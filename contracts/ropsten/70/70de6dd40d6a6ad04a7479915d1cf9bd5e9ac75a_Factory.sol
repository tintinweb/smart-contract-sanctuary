/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: SimPL-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;


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
    function transfer(address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
}

//佣金收取合约
interface commission {
    function commissionCost(address coin, uint num, uint _penalNum) external;
    function commissionETH(uint _penalNum) external payable;

    function buildCost(address coin, uint256 num)  external;

    function buildETH() external payable;
}

interface IFundManage {
    function withdraw() external  returns (uint, uint);

    function applyUnlock(address _addr) external ;

    function closeApplyUnlock(address _addr) external;

    function position(uint _tokenNum, uint _defaultAssertNum, address _addr) external;

    function positionEth(uint _defaultAssertNum, address _addr) external payable;

    function WETH() external view returns (address);

    function signAddress1() external view returns (address);

    function signAddress2() external view returns (address);

    function defaultAssertAddress() external view returns (address);
    function positionAddress() external view returns (address);
    function initAssert() external  view returns (uint);

    // 设置地址多签状态
    function setSignStatus(address _signAddr, bool _status) external;

    function getAssert() external view returns (uint _eth, address[] memory _erc20Contract, uint[] memory _balance);
}

interface ICommonality {
    function getAmounts(uint _tokenNum, address _addr1, address _addr2) external view returns (uint);
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
        require(hasRole(role, msg.sender), "FACTORY:DON'T_HAVE_PERMISSION");
        _;
    }
}

contract FactoryStorage is AccessControl {
    using SafeMath for uint;
    //佣金服务费收取合约
    address public commissionAddress;

    //公共合约地址
    address public commonalityAddress;

    address public defaultAddress;
    address public positionAddress;

    mapping(address => mapping(address => bool)) isApprove;

    uint tagNonce;

    // 提现佣金收取比例  千分之
    uint withdrawCommissionRate;

    //基金公司多签地址
    address public signFund;

    //平台多签地址
    address public signPlat;

    //资产管理合约地址
    IFundManage FundManage;

    bytes32 public constant ADMIN_ROLE = 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    bytes32 public constant ROUTER_ROLE = 0x7a05a596cb0ce7fdea8a1e1ec73be300bdb35097c944ce1897202f7a13122eb2;

    function setWithdrawRate(uint _rate) public roleCheck(ADMIN_ROLE) {
        withdrawCommissionRate = _rate;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

}

contract FactoryView is FactoryStorage {
    // 生产hash
    function getSignHash(address _addr) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _addr, tagNonce));
    }

    function generateSignHash(address _addr) internal view returns (bytes32) {
        bytes32 hashedUnsignedMessage = getSignHash(_addr);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
    }

    function getWithdrawCommissionValue() external view returns (uint){
        uint initAssert = FundManage.initAssert();

        ICommonality common = ICommonality(commonalityAddress);

        address defaultAssertAddr = FundManage.defaultAssertAddress();
        (uint _eth, address[] memory _erc20Contract, uint[] memory _balance) = FundManage.getAssert();

        uint nowAssert = 0;

        if (defaultAssertAddr == address(0)) {
            nowAssert = nowAssert.add(_eth);
        } else if (_eth > 0) {
            nowAssert = nowAssert.add(common.getAmounts(_eth, FundManage.WETH(), defaultAssertAddr));
        }

        uint _len = _erc20Contract.length;
        for (uint i = 0; i < _len; i++) {
            if (_erc20Contract[i] == defaultAssertAddr) {
                nowAssert = nowAssert.add(_balance[i]);
            } else if (_balance[i] > 0) {
                nowAssert = nowAssert.add(common.getAmounts(_balance[i], _erc20Contract[i], defaultAssertAddr));
            }
        }
        if (nowAssert <= initAssert) {
            return 0;
        } else {
            return nowAssert.sub(initAssert).mul(withdrawCommissionRate).div(1000);
        }
    }
}

contract Factory is FactoryView {
    //xx提现了多少
    event withdrawAccount(address _addr, address _tokenAddr, uint _balance);

    constructor(
        address _fundManage,
        address _commissionAddr,
        address _commonalityAddr,
        uint _commissionRate
    ) public {
        IFundManage _fund = IFundManage(_fundManage);
        FundManage = _fund;
        signFund = _fund.signAddress2();
        signPlat = _fund.signAddress1();
        defaultAddress = _fund.defaultAssertAddress();
        positionAddress = _fund.positionAddress();
        commissionAddress = _commissionAddr;
        commonalityAddress = _commonalityAddr;

        setWithdrawRate(_commissionRate);
    }

    //USD BTC 建仓
    function openPosition(
        address _build,
        uint valueNum
    ) external roleCheck(ROUTER_ROLE) returns (bool){
        require(_build != address(0), "BUILD_ADDRESS_NULL");

        address _erc20Addr = positionAddress;
        require(_erc20Addr != address(0), "POSITION_ASSERT_TYPE_INVALID");

        IERC20(_erc20Addr).transferFrom(msg.sender, address(this), valueNum);

        address _fundAddr = address(FundManage);
        if(!isApprove[_erc20Addr][_fundAddr]) {
            IERC20(_erc20Addr).approve(address(_fundAddr), 1e66);
            isApprove[_erc20Addr][_fundAddr] = true;
        }

        address _defaultAddress = defaultAddress;
        uint defaultAssertNum = valueNum;
        if(_defaultAddress != _erc20Addr){
            defaultAssertNum =  ICommonality(commonalityAddress).getAmounts(valueNum, _erc20Addr, _defaultAddress);
        }

        FundManage.position(valueNum, defaultAssertNum, _build);

        return true;
    }

    // ETH 建仓
    function openPosition(address _build) external payable roleCheck(ROUTER_ROLE) returns (bool){
        require(_build != address(0), "BUILD_ADDRESS_NULL");
        require(positionAddress == address(0), "POSITION_ASSERT_TYPE_INVALID");

        uint positionNum = msg.value;

        uint defaultAssertNum = positionNum;

        address _defaultAddress = defaultAddress;
        if(_defaultAddress != address(0)) {
            defaultAssertNum = ICommonality(commonalityAddress).getAmounts(positionNum, FundManage.WETH(), _defaultAddress);
        }

        FundManage.positionEth{value:positionNum}(defaultAssertNum, _build);

        return true;
    }

    //提现 BTC USD
    function withdraw(address payable _addr, uint _penalNumRate) external roleCheck(ROUTER_ROLE){
        //1.进行资产的结算（平台，基金公司的结算）

        //2.佣金收取 盈利收取 盈利的10% 没盈利 不收取
        (uint initAssert, uint _balance) = IFundManage(FundManage).withdraw();

        address _defaultAddress = defaultAddress;

        uint withdrawNum = _balance;
        uint profitNum = 0;
        if(initAssert < _balance){
            //赚钱收取佣金  收取盈利的10%
            profitNum = _balance.sub(initAssert).mul(withdrawCommissionRate).div(1000);
            withdrawNum = _balance.sub(profitNum);
        }

        uint _penalNum = 0;
        if (_penalNumRate > 0) {
            _penalNum = _balance.mul(_penalNumRate).div(1000);
            withdrawNum = withdrawNum.sub(_penalNum);
        }

        address _commissionAddress = commissionAddress;
        if (_defaultAddress != address(0)) {
            IERC20(_defaultAddress).transfer(_addr, withdrawNum);

            if(!isApprove[_defaultAddress][_commissionAddress]) {
                IERC20(_defaultAddress).approve(address(_commissionAddress), 1e66);
                isApprove[_defaultAddress][_commissionAddress] = true;
            }

            if (profitNum > 0 || _penalNum > 0) {
                commission(_commissionAddress).commissionCost(_defaultAddress, profitNum, _penalNum);
            }
        } else {
            _addr.transfer(withdrawNum);
            if (profitNum > 0 || _penalNum > 0) {
                uint _pay = profitNum.add(_penalNum);
                commission(_commissionAddress).commissionETH{value:_pay}(_penalNum);
            }
        }

        emit withdrawAccount(_addr, _defaultAddress, withdrawNum);
    }

    // 提前开仓
    function advanceLock(address _addr) external roleCheck(ROUTER_ROLE){
        FundManage.applyUnlock(_addr);
    }

    function closeApplyUnlock(address _addr) external roleCheck(ROUTER_ROLE) {
        FundManage.closeApplyUnlock(_addr);
    }

    // 基金公司签名
    function signatureFund(address _addr, uint8 v, bytes32 r, bytes32 s) external roleCheck(ROUTER_ROLE) {
        require(_addr == signFund, "INVALID_FUND_SIGN_ADDRESS");

        IFundManage _fund = FundManage;
        address _coverAddr = ecrecover(generateSignHash(address(_addr)), v, r, s);
        require(_coverAddr == _addr, "SIGN_ERROR");
        tagNonce++;

        _fund.setSignStatus(_coverAddr, true);
    }

    // 平台签名
    function signatureTerrace(address _addr, uint8 v, bytes32 r, bytes32 s) external roleCheck(ROUTER_ROLE){
        require(_addr == signPlat, "INVALID_TERRACE_SIGN_ADDRESS");

        IFundManage _fund = FundManage;
        address _coverAddr = ecrecover(generateSignHash(address(_addr)), v,r, s);
        require(_coverAddr == _addr, "SIGN_ERROR");
        tagNonce++;

        _fund.setSignStatus(_coverAddr, true);
    }

    receive() external payable {}
}