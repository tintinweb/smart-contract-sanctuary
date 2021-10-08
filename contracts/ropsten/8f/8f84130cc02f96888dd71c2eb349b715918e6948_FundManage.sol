/**
 *Submitted for verification at Etherscan.io on 2021-10-08
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
    function balanceOf(address _addr) external view returns (uint);

    function transfer(address _to, uint _value) external returns (bool);
    function symbol() external view returns (string memory);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Exchange{
    function getAmounts(uint _tokenNum,address _symbolAddress, address _returnSymbolAddress) external view returns (uint);
}

interface FundExchange {
    function fundToken2TokenCallback(
        address _fetch_address,
        address _return_address,
        uint _tokenNum,
        uint _queryId
    ) external returns (uint);

    function fundToken2ETHCallback(
        address _fetch_address,
        uint _tokenNum,
        uint _queryId
    ) external returns (uint);

    function fundETH2TokenCallback(
        address _return_address,
        uint _tokenNum,
        uint _queryId
    ) external payable returns (uint);
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
        require(hasRole(role, msg.sender), "FUNDMANAGE:DON'T_HAVE_PERMISSION");
        _;
    }
}

contract FundManageData is AccessControl {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    event PositionLog(string _contractNo, address _tokenAddr, uint _tokenNum, uint _defaultAssertNum, address _addr, uint _timeLock, uint _timestamp);

    EnumerableSet.AddressSet ERC20Address;

    address public _exchangeRateAddress;

    bytes32 public constant ADMIN_ROLE = 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    bytes32 public constant FACTORY_ROLE = 0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a73;
    bytes32 public constant EXCHANGE_ROLE = 0x8c855f644849358c1f76f3c3b48219643c81f4d79dbe9db70636e573a2d134c8;

    uint public _deviation = 10;

    // WETH地址
    address public WETH;
    // USDC地址
    address public USDC;
    //WBTC地址
    address public WBTC;

    function setWETH(address _WETHAddress) public roleCheck(ADMIN_ROLE) {
        address _weth = WETH;
        if (_weth != address(0)) {
            ERC20Address.remove(_weth);
        }
        ERC20Address.add(_WETHAddress);
        WETH = _WETHAddress;
    }

    function setWBTC(address _WBTCAddress) public roleCheck(ADMIN_ROLE) {
        address _wbtc = WBTC;
        if (_wbtc != address(0)) {
            ERC20Address.remove(_wbtc);
        }
        ERC20Address.add(_WBTCAddress);
        WBTC = _WBTCAddress;
    }

    function setUSDC(address _USDCAddress) public roleCheck(ADMIN_ROLE) {
        address _usdc = USDC;
        if (_usdc != address(0)) {
            ERC20Address.remove(_usdc);
        }
        ERC20Address.add(_USDCAddress);
        USDC = _USDCAddress;
    }

    function setExchangeRateAddress(address _exchangeRateContract) external roleCheck(ADMIN_ROLE) {
        _exchangeRateAddress = _exchangeRateContract;
    }

    function addFundERC20(address _addr) public roleCheck(ADMIN_ROLE) returns (bool) {
        return ERC20Address.add(_addr);
    }

    function removeFundERC20(address _addr) external roleCheck(ADMIN_ROLE) returns (bool) {
        return ERC20Address.remove(_addr);
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }
}

library MergeSplit{
    function merge_128_128(uint a, uint b) internal pure returns (uint) {
        a |= b << 128;
        return a;
    }

    function split_128_128(uint value) internal pure returns (uint, uint) {
        uint value1 = uint(uint128(value));
        uint value2 = uint(uint128(value >> 128));
        return (value1, value2);
    }
}

contract FundController is FundManageData {
    event ApplyUnlockLog(address _addr, bool _isExpire, uint _timestamp);
    event UnlockLog(uint _timestamp);

    // 开仓时间锁
    uint public lockTime;

    // 时间锁间隔
    uint public lockTimeInterval;

    // 是否解锁
    bool public isUnlock;

    // 是否申请解锁
    bool public isApplyUnlock;

    // 多签状态
    bool public signStatus1;
    bool public signStatus2;

    // 多签地址
    address public signAddress1;
    address public signAddress2;

    // 用户地址
    address public userAddress;
    // 用户备用地址
    address public userBackAddress;

    // 默认资产合约地址 （金本位=》usdc，币本位=》wbtc或weth）
    address public defaultAssertAddress;

    // 建仓资产token地址
    address public positionAddress;

    uint public positionTokenMax;
    uint public positionTokenNum;
    // 初始资产总量
    uint public initAssert;

    string crontabId;

    // 初始化建仓状态
    function _init() internal {
        lockTime = 0;
        signStatus1 = false;
        signStatus2 = false;
        isUnlock = false;
        isApplyUnlock = false;
        initAssert = 0;
        positionTokenNum = 0;
    }

    // 申请解锁
    function applyUnlock(address _addr) external roleCheck(FACTORY_ROLE) {
        require(_addr == userAddress || _addr == userBackAddress, "UNLOCK_APPLY_ADDRESS_ERROR");
        isApplyUnlock = true;
        uint _time = block.timestamp;

        bool _isUnlock = _time >= lockTime;

        if (_isUnlock) {
            isUnlock = _isUnlock;
            emit UnlockLog(block.timestamp);
        }

        emit ApplyUnlockLog(_addr, _isUnlock, _time);
    }

    // 设置建仓时间锁周期
    function setLockTimeInterval(uint _interval) external roleCheck(ADMIN_ROLE) {
        lockTimeInterval = _interval;
    }

    function setCrontabId(string memory _crontabId) external roleCheck(ADMIN_ROLE) {
        crontabId = _crontabId;
    }

    // 设置地址多签状态
    function setSignStatus(address _signAddr, bool _status) external roleCheck(FACTORY_ROLE) {
        require(isApplyUnlock, "NOT_APPLY_UNLOCK");
        require(_signAddr != address(0), "ZERO_SIGN_ADDRESS");

        address _signAddr2 = signAddress2;
        bool _isUnlock;

        if (_signAddr == signAddress1) {
            signStatus1 = _status;
            if (_signAddr2 == address(0)) {
                _isUnlock = true;
            }
        } else if (_signAddr == _signAddr2) {
            require(signStatus1, "ADDRESS_1_NO_SIGN");
            signStatus2 = _status;
            _isUnlock = true;
        } else {
            revert("INVALID_SIGN_ADDRESS");
        }

        if (_isUnlock) {
            isUnlock = _isUnlock;
            emit UnlockLog(block.timestamp);
        }
    }
}

contract FundManageView is FundController {
    function getAssert() public view returns (uint _eth, address[] memory _erc20Contract, uint[] memory _balance) {
        _eth = address(this).balance;
        _erc20Contract = getFundERC20Address();
        uint _len = _erc20Contract.length;
        _balance = new uint[](_len);
        for (uint i = 0; i < _len; i++) {
            IERC20 _erc20 = IERC20(_erc20Contract[i]);
            _balance[i] = _erc20.balanceOf(address(this));
        }
    }

    function getFundERC20Address() public view returns (address[] memory) {
        uint _len = ERC20Address.length();
        address[] memory res = new address[](_len);
        for (uint i = 0; i < _len; i++) {
            res[i] = ERC20Address.at(i);
        }
        return res;
    }

    /*
     * 判断erc20是否在白名单内
     * @param _addr erc20合约地址
     */
    function containsErc20Address(address _addr) internal view returns (bool) {
        return ERC20Address.contains(_addr);
    }

    /*
     * 检测是否是用户地址
     * @param _addr 用户地址
     */
    function isUserAddress(address _addr) internal view returns (bool) {
        return _addr == userAddress || _addr == userBackAddress;
    }
}

contract FundManage is FundManageView {
    constructor(
        address _wbtcAddress,
        address _usdcAddress,
        address _WETHAddress,
        address _defaultAssertAddress,
        address _positionAddress,
        address _exchangeAddr,
        address _signAddrPlat,
        address _signAddrFund,
        address _userAddr,
        address _userAddrBack,
        uint _positionTokenMax,
        uint _lockTimeInterval
    ) public {
        setWBTC(_wbtcAddress);
        setUSDC(_usdcAddress);
        setWETH(_WETHAddress);
        defaultAssertAddress = _defaultAssertAddress;
        positionAddress = _positionAddress;
        _exchangeRateAddress = _exchangeAddr;
        signAddress1 = _signAddrPlat;
        signAddress2 = _signAddrFund;
        userAddress = _userAddr;
        userBackAddress = _userAddrBack;
        positionTokenMax = _positionTokenMax;
        lockTimeInterval = _lockTimeInterval;
    }

    // 提现
    function withdraw() external roleCheck(FACTORY_ROLE) returns (uint, uint) {
        require(isUnlock || block.timestamp >= lockTime, "SHALL_NOT_WITHDRAW");
        address _defaultAssertAddress = defaultAssertAddress;

        uint _balance = 0;
        if (_defaultAssertAddress == address(0) || _defaultAssertAddress == WETH) {
            _balance = address(this).balance;
            payable(msg.sender).transfer(_balance);
        } else {
            IERC20 _assertContract = IERC20(_defaultAssertAddress);
            _balance = _assertContract.balanceOf(address(this));
            _assertContract.transfer(msg.sender, _balance);
        }

        _init();
        return (initAssert, _balance);
    }

    /*
     * erc20建仓
     * @_tokenNum 建仓投入的token数量
     * @_erc20Addr token合约地址
     * @_defaultAssertNum 价值对标token的数量
     * @_addr 用户地址
     */
    function position(uint _tokenNum, uint _defaultAssertNum, address _addr) external roleCheck(FACTORY_ROLE) {
        address _erc20Addr = positionAddress;
        require(isUserAddress(_addr), "INVALID_ADDRESS");
        require(containsErc20Address(_erc20Addr), "INVALID_ERC20");

        IERC20(_erc20Addr).transferFrom(msg.sender, address(this), _tokenNum);

        _position(_erc20Addr, _tokenNum, _defaultAssertNum, _addr);
    }

    /*
     * eth建仓
     * @_defaultAssertNum 价值对标token的数量
     * @_addr 用户地址
     */
    function positionEth(uint _defaultAssertNum, address _addr) external payable roleCheck(FACTORY_ROLE) {
        require(isUserAddress(_addr), "INVALID_ADDRESS");
        _position(address(0), msg.value, _defaultAssertNum, _addr);
    }

    /*
     * 建仓
     * @_tokenNum 建仓投入的token或eth数量
     * @_defaultAssertNum 价值对标token的数量
     * @_addr 用户地址
     */
    function _position(address _tokenAddr, uint _tokenNum, uint _defaultAssertNum, address _addr) internal {
        uint _positionTokenMax = positionTokenMax;
        uint _positionTokenNum = positionTokenNum;
        _positionTokenNum = _positionTokenNum.add(_tokenNum);

        require(_positionTokenNum <= _positionTokenMax, "POSITION_OVER_MAX_LIMIT");
        positionTokenNum = _positionTokenNum;

        initAssert = initAssert.add(_defaultAssertNum);

        uint _lock = lockTime;
        if (_lock == 0) {
            _lock = lockTimeInterval.add(block.timestamp);
            lockTime = _lock;
        }

        emit PositionLog(crontabId, _tokenAddr, _tokenNum, _defaultAssertNum, _addr, _lock, block.timestamp);
    }

    function fetchETH2Token(
        address _return_address,
        uint _tokenNum,
        uint _serviceCharge,
        uint _queryId
    ) external roleCheck(EXCHANGE_ROLE) returns (uint) {
        require(containsErc20Address(_return_address), "RETURN_ADDRESS_NOT_FUND");
        require(address(this).balance >= _tokenNum, "INSUFFICIENT_BALANCE");

        IERC20 returnContract = IERC20(_return_address);
        uint _return_balance = returnContract.balanceOf(address(this));

        uint exchangeNum = _tokenNum.sub(_serviceCharge);
        uint _exchange = Exchange(_exchangeRateAddress).getAmounts(exchangeNum, WETH, _return_address);
        uint _return_num = FundExchange(msg.sender).fundETH2TokenCallback{value:_tokenNum}(_return_address, _tokenNum, _queryId);

        require(_return_num.add((_return_num.div(100))) >= _exchange, "EXCHANGE_RATE_MISALIGNMENT");

        if (_return_balance.add(_return_num) <= returnContract.balanceOf(address(this))) {
            return _return_num;
        } else {
            revert();
        }
    }

    function fetchToken2ETH(
        address _fetch_address,
        uint _tokenNum,
        uint _serviceCharge,
        uint _queryId
    ) external roleCheck(EXCHANGE_ROLE) returns (uint) {
        require(containsErc20Address(_fetch_address), "FETCH_ADDRESS_NOT_FUND");

        IERC20 fetchContract = IERC20(_fetch_address);
        require(fetchContract.balanceOf(address(this)) >= _tokenNum, "INSUFFICIENT_BALANCE");

        if (_transferToken(msg.sender, _tokenNum, _fetch_address)) {
            uint _return_balance = address(this).balance;

            uint exchangeNum = _tokenNum.sub(_serviceCharge);
            uint _exchange = Exchange(_exchangeRateAddress).getAmounts(exchangeNum, _fetch_address, WETH);
            uint _return_num = FundExchange(msg.sender).fundToken2ETHCallback(_fetch_address, _tokenNum, _queryId);

            require(_return_num.add(_return_num.div(100)) >= _exchange, "Excessive exchange rate misalignment!");

            if (_return_balance.add(_return_num) <= address(this).balance) {
                return _return_num;
            }
        }
        revert();
    }

    function _transferToken(
        address _to,
        uint _value,
        address _erc20Addr
    ) internal returns (bool) {
        require(IERC20(_erc20Addr).balanceOf(address(this)) >= _value, "Transfer out more than the maximum amount!");
        return IERC20(_erc20Addr).transfer(_to, _value);
    }

    function fetchToken2Token(
        address _fetch_address,
        address _return_address,
        uint _tokenNum,
        uint _serviceCharge,
        uint _queryId
    ) external roleCheck(EXCHANGE_ROLE) returns (uint) {
        require(containsErc20Address(_fetch_address), "FETCH_ADDRESS_NOT_FUND");
        require(containsErc20Address(_return_address), "RETURN_ADDRESS_NOT_FUND");

        IERC20 fetchContract = IERC20(_fetch_address);
        require(fetchContract.balanceOf(address(this)) >= _tokenNum, "INSUFFICIENT_BALANCE");

        if (_transferToken(msg.sender, _tokenNum, _fetch_address)) {
            IERC20 returnContract = IERC20(_return_address);
            uint _return_balance = returnContract.balanceOf(address(this));

            uint exchangeNum = _tokenNum.sub(_serviceCharge);
            uint _exchange = Exchange(_exchangeRateAddress).getAmounts(exchangeNum, _fetch_address, _return_address);
            uint _return_num = FundExchange(msg.sender).fundToken2TokenCallback(_fetch_address, _return_address, _tokenNum, _queryId);

            require(_return_num.add(_return_num.div(100)) >= _exchange, "Excessive exchange rate misalignment!");

            if (_return_balance.add(_return_num) <= returnContract.balanceOf(address(this))) {
                return _return_num;
            }
        }
        revert();
    }

    receive() external payable {}
}