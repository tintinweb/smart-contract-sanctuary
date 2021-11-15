pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) { return functionCall(target, data, "Address: low-level call failed"); }
    function functionCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) { return functionCallWithValue(target, data, 0, errorMessage); }
    function functionCallWithValue( address target, bytes memory data, uint256 value ) internal returns (bytes memory) { return functionCallWithValue( target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) { return functionStaticCall( target, data, "Address: low-level static call failed"); }
    function functionStaticCall( address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) { return functionDelegateCall( target, data, "Address: low-level delegate call failed" ); }
    function functionDelegateCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult( bool success, bytes memory returndata, string memory errorMessage ) private pure returns (bytes memory) {
        if (success) { return returndata;} else {
            if (returndata.length > 0) {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { return interfaceId == type(IERC165).interfaceId; }
}
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view override returns (bool) { return _roles[role].members[account]; }
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) { return _roles[role].adminRole; }
    function grantRole(bytes32 role, address account) public virtual override { 
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override {
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override
    {
        require( account == _msgSender(), "AccessControl: can only renounce roles for self" );
        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual { _grantRole(role, account); }
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
library Counters {
    struct Counter {
        uint256 _value;
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        counter._value += 1;
    }
    function decrement(Counter storage counter) internal {
        counter._value = counter._value - 1;
    }
} 
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(IERC20 token,address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom( IERC20 token,address from,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token,address spender,uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance( IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
 
contract IngameReward is AccessControl {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    bytes32 public constant CREATOR_ADMIN = keccak256("CREATOR_ADMIN");
    uint256 public decimalHeroes;
    IERC20 public tokenHeroes;
    uint256 public totalAdd;
    uint256 public lockTime; //block.timestamp;
    uint256 public vestingPeriod; // uint month 
    uint256 public vestingInternal = 2592000 ; //30 * 24 * 60 * 60 uint second
    uint256 public totalPoolLock;
    uint256 public vestingStart;
    bool public lockBool = false; 
    mapping(address => uint256) public totalAmount;
    mapping(address => uint256) public withdrawnAmount;
    mapping(uint256 => uint256) public percent; // month => percent
    constructor(address minter, address _tokenHeroes, uint256 _decimalHeroes, uint256 _vestingPeriod, uint256 _totalPoolLock){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN, minter);
        tokenHeroes = IERC20(_tokenHeroes);
        decimalHeroes = _decimalHeroes;
        vestingPeriod = _vestingPeriod;
        totalPoolLock = _totalPoolLock*10**decimalHeroes;
        vestingStart = block.timestamp;
    }

    event claim(
        address member,
        uint256 amount,
        uint256 timeClaim
    );
    event addRule(
        uint256 timeLock,
        uint256 percentUnlock
    );
    function addRuleUnlock(uint256[] memory _month, uint256[] memory _percent) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_month.length == _percent.length, "Array list error");
        for(uint256 i = 0; i < _month.length; i++){
            percent[_month[i]] = _percent[i];
            emit addRule(
                _month[i],
                _percent[i]
            );
        }
    }
    function setVestingStart(uint256 _vestingStart) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_vestingStart > block.timestamp, "VestingStart must be in future date");
        vestingStart = _vestingStart;
    }
    function lockToken() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(lockBool == false, "Token has been locked");
        lockBool = true;
        tokenHeroes.safeTransferFrom(address(msg.sender), address(this), totalPoolLock);
    }

    function addIngameReward(address[] memory _account, uint256[] memory _amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0 ; i < _account.length ; i ++) {
            require(totalAdd.add(_amount[i]) <= totalPoolLock, "Exceeded the allowed amount");
            totalAmount[address(_account[i])] = totalAmount[address(_account[i])].add(_amount[i]*10**decimalHeroes);
            totalAdd = totalAdd.add(_amount[i]*10**decimalHeroes);
        }
    }
 
    function claimToken() public {
        require(block.timestamp > lockTime, 'Not open yet');
        uint256 amountClaim = availableAmount(address(msg.sender));
        require(amountClaim > 0, "amount > 0");
        withdrawnAmount[address(msg.sender)] = withdrawnAmount[address(msg.sender)].add(amountClaim);
        safeHETransfer(address(msg.sender), amountClaim);
        emit claim(
            msg.sender,
            amountClaim,
            block.timestamp
        );
    }
    function getPercent(uint256 _timeStamp) public view returns( uint256 ){
        uint256 percentTime = 0;
        if(vestingStart < _timeStamp){
            uint256 currentTime = _timeStamp;
            uint256 currentMonth = currentTime.sub(vestingStart).div(vestingInternal);
            uint256 monthUnlock = currentMonth > vestingPeriod ? vestingPeriod : currentMonth;
            percentTime = percent[monthUnlock];
        }
        return percentTime;
    }
    function availableAmount(address _address) public view returns( uint256 ) {
        uint256 amount= 0;
        if(vestingStart < block.timestamp){
            uint256 currentTime = block.timestamp;
            uint256 currentMonth = currentTime.sub(vestingStart).div(vestingInternal);
            uint256 monthUnlock = currentMonth > vestingPeriod ? vestingPeriod : currentMonth;
            uint256 percentUnlock = percent[monthUnlock];
            amount = totalAmount[address(_address)].mul(percentUnlock).div(1000) > withdrawnAmount[address(_address)] ? totalAmount[address(_address)].mul(percentUnlock).div(1000) - withdrawnAmount[address(_address)] : 0;
        }
        return amount;
    }


    function safeHETransfer(address _to, uint256 _amount) internal {
        uint256 HEBalance = tokenHeroes.balanceOf(address(this));
        if (_amount > HEBalance) {
            tokenHeroes.transfer(_to, HEBalance);
        } else {
            tokenHeroes.transfer(_to, _amount);
        }
    }
}

