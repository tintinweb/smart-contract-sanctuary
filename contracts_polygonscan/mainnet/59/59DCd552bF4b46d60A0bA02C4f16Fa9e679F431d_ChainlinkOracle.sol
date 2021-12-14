/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library ERC165Checker {
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    function supportsERC165(address account) internal view returns (bool) {
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        if (supportsERC165(account)) {
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        if (!supportsERC165(account)) {
            return false;
        }

        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        return true;
    }

    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
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

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

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
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

library SafeCast {
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

library Counters {
    using SafeMath for uint256;

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
        counter._value = counter._value.sub(1);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Orchestrator is Ownable {
  enum Functions {BURNFEE, LIQUIDATION, PAUSE}

  address public guardian;

  bytes4 private constant _INTERFACE_ID_IVAULT = 0x9e75ab0c;
  bytes4 private constant _INTERFACE_ID_ALTS = 0xbd115939;
  bytes4 private constant _INTERFACE_ID_CHAINLINK_ORACLE = 0x85be402b;

  mapping(IVaultHandler => mapping(Functions => bool)) private emergencyCalled;

  event GuardianSet(address indexed _owner, address guardian);

  event TransactionExecuted(
    address indexed target,
    uint256 value,
    string signature,
    bytes data
  );

  constructor(address _guardian) {
    require(
      _guardian != address(0),
      "Orchestrator::constructor: guardian can't be zero address"
    );
    guardian = _guardian;
  }

  modifier onlyGuardian() {
    require(
      msg.sender == guardian,
      "Orchestrator::onlyGuardian: caller is not the guardian"
    );
    _;
  }

  modifier validVault(IVaultHandler _vault) {
    require(
      ERC165Checker.supportsInterface(address(_vault), _INTERFACE_ID_IVAULT),
      "Orchestrator::validVault: not a valid vault"
    );
    _;
  }

  modifier validALTS(ALTS _alts) {
    require(
      ERC165Checker.supportsInterface(address(_alts), _INTERFACE_ID_ALTS),
      "Orchestrator::validALTS: not a valid ALTS ERC20"
    );
    _;
  }

  modifier validChainlinkOracle(address _oracle) {
    require(
      ERC165Checker.supportsInterface(
        address(_oracle),
        _INTERFACE_ID_CHAINLINK_ORACLE
      ),
      "Orchestrator::validChainlinkOrchestrator: not a valid Chainlink Oracle"
    );
    _;
  }

  function setGuardian(address _guardian) external onlyOwner {
    require(
      _guardian != address(0),
      "Orchestrator::setGuardian: guardian can't be zero address"
    );
    guardian = _guardian;
    emit GuardianSet(msg.sender, _guardian);
  }

  function setRatio(IVaultHandler _vault, uint256 _ratio)
    external
    onlyOwner
    validVault(_vault)
  {
    _vault.setRatio(_ratio);
  }

  function setBurnFee(IVaultHandler _vault, uint256 _burnFee)
    external
    onlyOwner
    validVault(_vault)
  {
    _vault.setBurnFee(_burnFee);
  }

  function setEmergencyBurnFee(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.BURNFEE] != true,
      "Orchestrator::setEmergencyBurnFee: emergency call already used"
    );
    emergencyCalled[_vault][Functions.BURNFEE] = true;
    _vault.setBurnFee(0);
  }

  function setLiquidationPenalty(
    IVaultHandler _vault,
    uint256 _liquidationPenalty
  ) external onlyOwner validVault(_vault) {
    _vault.setLiquidationPenalty(_liquidationPenalty);
  }

  function setEmergencyLiquidationPenalty(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.LIQUIDATION] != true,
      "Orchestrator::setEmergencyLiquidationPenalty: emergency call already used"
    );
    emergencyCalled[_vault][Functions.LIQUIDATION] = true;
    _vault.setLiquidationPenalty(0);
  }

  function pauseVault(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.PAUSE] != true,
      "Orchestrator::pauseVault: emergency call already used"
    );
    emergencyCalled[_vault][Functions.PAUSE] = true;
    _vault.pause();
  }

  function unpauseVault(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    _vault.unpause();
  }

  function enableALTSCap(ALTS _alts, bool _enable)
    external
    onlyOwner
    validALTS(_alts)
  {
    _alts.enableCap(_enable);
  }

  function setALTSCap(ALTS _alts, uint256 _cap)
    external
    onlyOwner
    validALTS(_alts)
  {
    _alts.setCap(_cap);
  }

  function addALTSVault(ALTS _alts, IVaultHandler _vault)
    external
    onlyOwner
    validALTS(_alts)
    validVault(_vault)
  {
    _alts.addVaultHandler(address(_vault));
  }

  function removeALTSVault(ALTS _alts, IVaultHandler _vault)
    external
    onlyOwner
    validALTS(_alts)
    validVault(_vault)
  {
    _alts.removeVaultHandler(address(_vault));
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data
  ) external payable onlyOwner returns (bytes memory) {
    bytes memory callData;
    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    require(
      target != address(0),
      "Orchestrator::executeTransaction: target can't be zero address"
    );

    (bool success, bytes memory returnData) =
      target.call{value: value}(callData);
    require(
      success,
      "Orchestrator::executeTransaction: Transaction execution reverted."
    );

    emit TransactionExecuted(target, value, signature, data);
    (target, value, signature, data);

    return returnData;
  }

  function retrieveETH(address _to) external onlyOwner {
    require(
      _to != address(0),
      "Orchestrator::retrieveETH: address can't be zero address"
    );
    uint256 amount = address(this).balance;
    payable(_to).transfer(amount);
  }

  receive() external payable {}
}

contract ALTS is ERC20, Ownable, IERC165 {
  using SafeMath for uint256;

  bool public capEnabled = false;

  uint256 public cap;

  address public orchestratorSetter;

  Orchestrator public orchestrator;

  mapping(address => bool) public vaultHandlers;

  bytes4 private constant _INTERFACE_ID_ALTS = 0xbd115939;

  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  event VaultHandlerAdded(
    address indexed _owner,
    address indexed _tokenHandler
  );

  event VaultHandlerRemoved(
    address indexed _owner,
    address indexed _tokenHandler
  );

  event NewCap(address indexed _owner, uint256 _amount);

  event NewCapEnabled(address indexed _owner, bool _enable);
  
  event OrchestratorSet(address indexed _setter, Orchestrator _orchestrator);

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _cap
  ) ERC20(_name, _symbol) {
    cap = _cap;

    orchestratorSetter = msg.sender;
  }
  
  function setOrchestrator(Orchestrator _orchestrator) public {
    require(msg.sender == orchestratorSetter, "ALTS::setOrchestrator: not allowed to set the orchestrator");
      
    transferOwnership(address(_orchestrator));
    
    orchestrator = _orchestrator;
    emit OrchestratorSet(orchestratorSetter, _orchestrator);
  }

  function addVaultHandler(address _vaultHandler) external onlyOwner {
    vaultHandlers[_vaultHandler] = true;
    emit VaultHandlerAdded(msg.sender, _vaultHandler);
  }

  function removeVaultHandler(address _vaultHandler) external onlyOwner {
    vaultHandlers[_vaultHandler] = false;
    emit VaultHandlerRemoved(msg.sender, _vaultHandler);
  }

  function mint(address _account, uint256 _amount) external {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) external {
    _burn(_account, _amount);
  }

  function setCap(uint256 _cap) external onlyOwner {
    cap = _cap;
    emit NewCap(msg.sender, _cap);
  }

  function enableCap(bool _enable) external onlyOwner {
    capEnabled = _enable;
    emit NewCapEnabled(msg.sender, _enable);
  }

  function supportsInterface(bytes4 _interfaceId)
    external
    pure
    override
    returns (bool)
  {
    return (_interfaceId == _INTERFACE_ID_ALTS ||
      _interfaceId == _INTERFACE_ID_ERC165);
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _amount);

    require(
      _to != address(this),
      "ALTS::transfer: can't transfer to ALTS contract"
    );

    if (_from == address(0) && capEnabled) {
      require(
        totalSupply().add(_amount) <= cap,
        "ALTS::Transfer: ALTS cap exceeded"
      );
    }
  }
}

interface IRewardHandler {
  function stake(address _staker, uint256 amount) external;

  function withdraw(address _staker, uint256 amount) external;

  function getRewardFromVault(address _staker) external;
}

abstract contract IVaultHandler is
  Ownable,
  AccessControl,
  ReentrancyGuard,
  Pausable,
  IERC165
{
  using SafeMath for uint256;
  using SafeCast for int256;
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;

  struct Vault {
    uint256 Id;
    uint256 Collateral;
    uint256 Debt;
    address Owner;
  }

  Counters.Counter public counter;

  ALTS public immutable ALTSToken;

  ChainlinkOracle public immutable altsOracle;

  IERC20 public immutable collateralContract;

  ChainlinkOracle public immutable collateralPriceOracle;

  ChainlinkOracle public immutable ETHPriceOracle;

  uint256 public divisor;

  uint256 public ratio;

  uint256 public burnFee;

  uint256 public liquidationPenalty;

  IRewardHandler public rewardHandler;

  address public feeAddress;

  mapping(address => uint256) public userToVault;

  mapping(uint256 => Vault) public vaults;

  uint256 public constant oracleDigits = 100000000;

  uint256 public constant MIN_RATIO = 105;

  uint256 public constant MAX_FEE = 25;

  bytes4 private constant _INTERFACE_ID_IVAULT = 0x9e75ab0c;

  bytes4 private constant _INTERFACE_ID_TIMELOCK = 0x6b5cc770;

  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  event NewRatio(address indexed _owner, uint256 _ratio);

  event NewBurnFee(address indexed _owner, uint256 _burnFee);

  event NewLiquidationPenalty(
    address indexed _owner,
    uint256 _liquidationPenalty
  );

  event NewFeeAddress(address indexed _feeAddress, address _newFeeAddress);

  event RewardHandlerSet(address indexed _feeAddress, address _rewardHandler);

  event VaultCreated(address indexed _owner, uint256 indexed _id);

  event CollateralAdded(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  event CollateralRemoved(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  event TokensMinted(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  event TokensBurned(
    address indexed _owner,
    uint256 indexed _id,
    uint256 _amount
  );

  event VaultLiquidated(
    uint256 indexed _vaultId,
    address indexed _liquidator,
    uint256 _liquidationCollateral,
    uint256 _reward
  );

  event Recovered(address _token, uint256 _amount);

  constructor(
    Orchestrator _orchestrator,
    uint256 _divisor,
    uint256 _ratio,
    uint256 _burnFee,
    uint256 _liquidationPenalty,
    address _altsOracle,
    ALTS _altsAddress,
    address _collateralAddress,
    address _collateralOracle,
    address _ethOracle,
    address _feeAddress
  ) {
    require(
      _liquidationPenalty.add(100) < _ratio,
      "VaultHandler::constructor: liquidation penalty too high"
    );
    require(
      _ratio >= MIN_RATIO,
      "VaultHandler::constructor: ratio lower than MIN_RATIO"
    );

    require(
      _burnFee <= MAX_FEE,
      "VaultHandler::constructor: burn fee higher than MAX_FEE"
    );

    divisor = _divisor;
    ratio = _ratio;
    burnFee = _burnFee;
    liquidationPenalty = _liquidationPenalty;
    collateralContract = IERC20(_collateralAddress);
    altsOracle = ChainlinkOracle(_altsOracle);
    collateralPriceOracle = ChainlinkOracle(_collateralOracle);
    ETHPriceOracle = ChainlinkOracle(_ethOracle);
    ALTSToken = _altsAddress;
    feeAddress = _feeAddress;

    counter.increment();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    transferOwnership(address(_orchestrator));
  }

  modifier vaultExists() {
    require(
      userToVault[msg.sender] != 0,
      "VaultHandler::vaultExists: no vault created"
    );
    _;
  }

  modifier notZero(uint256 _value) {
    require(_value != 0, "VaultHandler::notZero: value can't be 0");
    _;
  }

  function setRatio(uint256 _ratio) external virtual onlyOwner {
    require(
      _ratio >= MIN_RATIO,
      "VaultHandler::setRatio: ratio lower than MIN_RATIO"
    );
    ratio = _ratio;
    emit NewRatio(msg.sender, _ratio);
  }

  function setBurnFee(uint256 _burnFee) external virtual onlyOwner {
    require(
      _burnFee <= MAX_FEE,
      "VaultHandler::setBurnFee: burn fee higher than MAX_FEE"
    );
    burnFee = _burnFee;
    emit NewBurnFee(msg.sender, _burnFee);
  }

  function setLiquidationPenalty(uint256 _liquidationPenalty)
    external
    virtual
    onlyOwner
  {
    require(
      _liquidationPenalty.add(100) < ratio,
      "VaultHandler::setLiquidationPenalty: liquidation penalty too high"
    );

    liquidationPenalty = _liquidationPenalty;
    emit NewLiquidationPenalty(msg.sender, _liquidationPenalty);
  }

  function setFeeAddress(address _feeAddress) public virtual {
    require(msg.sender == feeAddress, "VaultHandler::setFeeAddress: not allowed to set the new dev team address");

    feeAddress = _feeAddress;
    emit NewFeeAddress(msg.sender, _feeAddress);
  }

  function setRewardHandler(address _rewardHandler) public virtual {
    require(msg.sender == feeAddress, "VaultHandler::setRewardHandler: not allowed to set the reward handler");

    rewardHandler = IRewardHandler(_rewardHandler);
    emit RewardHandlerSet(msg.sender, _rewardHandler);
  }

  function createVault() external virtual whenNotPaused {
    require(
      userToVault[msg.sender] == 0,
      "VaultHandler::createVault: vault already created"
    );

    uint256 id = counter.current();
    userToVault[msg.sender] = id;
    Vault memory vault = Vault(id, 0, 0, msg.sender);
    vaults[id] = vault;
    counter.increment();
    emit VaultCreated(msg.sender, id);
  }

  function addCollateral(uint256 _amount)
    external
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    require(
      collateralContract.transferFrom(msg.sender, address(this), _amount),
      "VaultHandler::addCollateral: ERC20 transfer did not succeed"
    );

    Vault storage vault = vaults[userToVault[msg.sender]];
    vault.Collateral = vault.Collateral.add(_amount);
    emit CollateralAdded(msg.sender, vault.Id, _amount);
  }

  function removeCollateral(uint256 _amount)
    external
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    Vault storage vault = vaults[userToVault[msg.sender]];
    uint256 currentRatio = getVaultRatio(vault.Id);

    require(
      vault.Collateral >= _amount,
      "VaultHandler::removeCollateral: retrieve amount higher than collateral"
    );

    vault.Collateral = vault.Collateral.sub(_amount);
    if (currentRatio != 0) {
      require(
        getVaultRatio(vault.Id) >= ratio,
        "VaultHandler::removeCollateral: collateral below min required ratio"
      );
    }
    require(
      collateralContract.transfer(msg.sender, _amount),
      "VaultHandler::removeCollateral: ERC20 transfer did not succeed"
    );
    emit CollateralRemoved(msg.sender, vault.Id, _amount);
  }

  function mint(uint256 _amount)
    external
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    Vault storage vault = vaults[userToVault[msg.sender]];
    uint256 collateral = requiredCollateral(_amount);

    require(
      vault.Collateral >= collateral,
      "VaultHandler::mint: not enough collateral"
    );

    vault.Debt = vault.Debt.add(_amount);
    require(
      getVaultRatio(vault.Id) >= ratio,
      "VaultHandler::mint: collateral below min required ratio"
    );

    if (address(rewardHandler) != address(0)) {
      rewardHandler.stake(msg.sender, _amount);
    }

    ALTSToken.mint(msg.sender, _amount);
    emit TokensMinted(msg.sender, vault.Id, _amount);
  }

  function burn(uint256 _amount)
    external
    payable
    virtual
    nonReentrant
    vaultExists
    whenNotPaused
    notZero(_amount)
  {
    uint256 fee = getFee(_amount);
    require(
      msg.value >= fee,
      "VaultHandler::burn: burn fee less than required"
    );

    Vault memory vault = vaults[userToVault[msg.sender]];

    _burn(vault.Id, _amount);

    if (address(rewardHandler) != address(0)) {
      rewardHandler.withdraw(msg.sender, _amount);
      rewardHandler.getRewardFromVault(msg.sender);
    }
    safeTransferETH(feeAddress, fee);
 
    safeTransferETH(msg.sender, msg.value.sub(fee));
    emit TokensBurned(msg.sender, vault.Id, _amount);
  }

  function liquidateVault(uint256 _vaultId, uint256 _maxALTS)
    external
    payable
    nonReentrant
    whenNotPaused
  {
    Vault storage vault = vaults[_vaultId];
    require(vault.Id != 0, "VaultHandler::liquidateVault: no vault created");

    uint256 vaultRatio = getVaultRatio(vault.Id);
    require(
      vaultRatio < ratio,
      "VaultHandler::liquidateVault: vault is not liquidable"
    );

    uint256 requiredALTS = requiredLiquidationALTS(vault.Id);
    require(
      _maxALTS >= requiredALTS,
      "VaultHandler::liquidateVault: liquidation amount different than required"
    );

    uint256 fee = getFee(requiredALTS);
    require(
      msg.value >= fee,
      "VaultHandler::liquidateVault: burn fee less than required"
    );

    uint256 reward = liquidationReward(vault.Id);
    _burn(vault.Id, requiredALTS);

    vault.Collateral = vault.Collateral.sub(reward);

    if (address(rewardHandler) != address(0)) {
      rewardHandler.withdraw(vault.Owner, requiredALTS);
    }

    require(
      collateralContract.transfer(msg.sender, reward),
      "VaultHandler::liquidateVault: ERC20 transfer did not succeed"
    );
    safeTransferETH(feeAddress, fee);

    safeTransferETH(msg.sender, msg.value.sub(fee));
    emit VaultLiquidated(vault.Id, msg.sender, requiredALTS, reward);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
    external
    onlyOwner
  {
    require(
      _tokenAddress != address(collateralContract),
      "Cannot withdraw the collateral tokens"
    );
    IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
    emit Recovered(_tokenAddress, _tokenAmount);
  }

  function safeTransferETH(address _to, uint256 _value) internal {
    (bool success, ) = _to.call{value: _value}(new bytes(0));
    require(success, "ETHVaultHandler::safeTransferETH: ETH transfer failed");
  }

  function supportsInterface(bytes4 _interfaceId)
    external
    pure
    override
    returns (bool)
  {
    return (_interfaceId == _INTERFACE_ID_IVAULT ||
      _interfaceId == _INTERFACE_ID_ERC165);
  }

  function getVault(uint256 _id)
    external
    view
    virtual
    returns (
      uint256,
      uint256,
      address,
      uint256
    )
  {
    Vault memory vault = vaults[_id];
    return (vault.Id, vault.Collateral, vault.Owner, vault.Debt);
  }

  function getOraclePrice(ChainlinkOracle _oracle) public view virtual returns (uint256 price) {
    price = _oracle.getLatestAnswer().toUint256().mul(oracleDigits);
  } 

  function ALTSPrice() public view virtual returns (uint256 price) {
    uint256 altsPrice = getOraclePrice(altsOracle);
    price = altsPrice.div(divisor);
  }

  function requiredCollateral(uint256 _amount)
    public
    virtual
    returns (uint256 collateral)
  {
    uint256 altsPrice = ALTSPrice();
    uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
    collateral = ((altsPrice.mul(_amount).mul(ratio)).div(100)).div(
      collateralPrice
    );
  }

  function requiredLiquidationALTS(uint256 _vaultId)
    public
    virtual
    returns (uint256 amount)
  {
    Vault memory vault = vaults[_vaultId];
    uint256 altsPrice = ALTSPrice();
    uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
    uint256 collateralALTS =
      (vault.Collateral.mul(collateralPrice)).div(altsPrice);
    uint256 reqDividend =
      (((vault.Debt.mul(ratio)).div(100)).sub(collateralALTS)).mul(100);
    uint256 reqDivisor = ratio.sub(liquidationPenalty.add(100));
    amount = reqDividend.div(reqDivisor);
  }

  function liquidationReward(uint256 _vaultId)
    public
    virtual
    returns (uint256 rewardCollateral)
  {
    uint256 req = requiredLiquidationALTS(_vaultId);
    uint256 altsPrice = ALTSPrice();
    uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
    uint256 reward = (req.mul(liquidationPenalty.add(100)));
    rewardCollateral = (reward.mul(altsPrice)).div(collateralPrice.mul(100));
  }

  function getVaultRatio(uint256 _vaultId)
    public
    virtual
    returns (uint256 currentRatio)
  {
    Vault memory vault = vaults[_vaultId];
    if (vault.Id == 0 || vault.Debt == 0) {
      currentRatio = 0;
    } else {
      uint256 collateralPrice = getOraclePrice(collateralPriceOracle);
      currentRatio = (
        (collateralPrice.mul(vault.Collateral.mul(100))).div(
          vault.Debt.mul(ALTSPrice())
        )
      );
    }
  }

  function getFee(uint256 _amount) public virtual returns (uint256 fee) {
    uint256 ethPrice = getOraclePrice(ETHPriceOracle);
    fee = (ALTSPrice().mul(_amount).mul(burnFee)).div(100).div(ethPrice);
  }

  function _burn(uint256 _vaultId, uint256 _amount) internal {
    Vault storage vault = vaults[_vaultId];
    require(
      vault.Debt >= _amount,
      "VaultHandler::burn: amount greater than debt"
    );
    vault.Debt = vault.Debt.sub(_amount);
    ALTSToken.burn(msg.sender, _amount);
  }
}

contract ChainlinkOracle is Ownable, IERC165 {
  AggregatorV3Interface internal aggregatorContract;

  bytes4 private constant _INTERFACE_ID_CHAINLINK_ORACLE = 0x85be402b;

  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  constructor(address _aggregator) {
    aggregatorContract = AggregatorV3Interface(_aggregator);
  }

  function setReferenceContract(address _aggregator) public onlyOwner() {
    aggregatorContract = AggregatorV3Interface(_aggregator);
  }

  function getLatestAnswer() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      ,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContract.latestRoundData();
    require(
      timeStamp != 0,
      "ChainlinkOracle::getLatestAnswer: round is not complete"
    );
    require(
      answeredInRound >= roundID,
      "ChainlinkOracle::getLatestAnswer: stale data"
    );
    return price;
  }

  function getLatestRound()
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContract.latestRoundData();

    return (roundID, price, startedAt, timeStamp, answeredInRound);
  }

  function getRound(uint80 _id)
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = aggregatorContract.getRoundData(_id);

    return (roundID, price, startedAt, timeStamp, answeredInRound);
  }

  function getLatestTimestamp() public view returns (uint256) {
    (, , , uint256 timeStamp, ) = aggregatorContract.latestRoundData();
    return timeStamp;
  }

  function getPreviousAnswer(uint80 _id) public view returns (int256) {
    (uint80 roundID, int256 price, , , ) = aggregatorContract.getRoundData(_id);
    require(
      _id <= roundID,
      "ChainlinkOracle::getPreviousAnswer: not enough history"
    );
    return price;
  }

  function getPreviousTimestamp(uint80 _id) public view returns (uint256) {
    (uint80 roundID, , , uint256 timeStamp, ) =
      aggregatorContract.getRoundData(_id);
    require(
      _id <= roundID,
      "ChainlinkOracle::getPreviousTimestamp: not enough history"
    );
    return timeStamp;
  }

  function supportsInterface(bytes4 interfaceId)
    external
    pure
    override
    returns (bool)
  {
    return (interfaceId == _INTERFACE_ID_CHAINLINK_ORACLE ||
      interfaceId == _INTERFACE_ID_ERC165);
  }
}

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ETHVaultHandler is IVaultHandler {
  using SafeMath for uint256;

  constructor(
    Orchestrator _orchestrator,
    uint256 _divisor,
    uint256 _ratio,
    uint256 _burnFee,
    uint256 _liquidationPenalty,
    address _altsOracle, 
    ALTS _altsAddress,
    address _collateralAddress,
    address _collateralOracle,
    address _ethOracle,
    address _feeAddress
  )
    IVaultHandler(
      _orchestrator,
      _divisor,
      _ratio,
      _burnFee,
      _liquidationPenalty,
      _altsOracle,
      _altsAddress,
      _collateralAddress,
      _collateralOracle,
      _ethOracle,
      _feeAddress
    )
  {}

  receive() external payable {
    assert(msg.sender == address(collateralContract));
  }

  function addCollateralETH()
    external
    payable
    nonReentrant
    vaultExists
    whenNotPaused
  {
    require(
      msg.value > 0,
      "ETHVaultHandler::addCollateralETH: value can't be 0 ETH"
    );
    IWETH(address(collateralContract)).deposit{value: msg.value}();
    Vault storage vault = vaults[userToVault[msg.sender]];
    vault.Collateral = vault.Collateral.add(msg.value);
    emit CollateralAdded(msg.sender, vault.Id, msg.value);
  }

  function removeCollateralETH(uint256 _amount)
    external
    nonReentrant
    vaultExists
    whenNotPaused
  {
    require(
      _amount > 0,
      "ETHVaultHandler::removeCollateralETH: value can't be 0 ETH"
    );
    Vault storage vault = vaults[userToVault[msg.sender]];
    uint256 currentRatio = getVaultRatio(vault.Id);
    require(
      vault.Collateral >= _amount,
      "ETHVaultHandler::removeCollateralETH: retrieve amount higher than collateral"
    );
    vault.Collateral = vault.Collateral.sub(_amount);
    if (currentRatio != 0) {
      require(
        getVaultRatio(vault.Id) >= ratio,
        "ETHVaultHandler::removeCollateralETH: collateral below min required ratio"
      );
    }

    IWETH(address(collateralContract)).withdraw(_amount);
    safeTransferETH(msg.sender, _amount);
    emit CollateralRemoved(msg.sender, vault.Id, _amount);
  }
}

contract ERC20VaultHandler is IVaultHandler {
  constructor(
    Orchestrator _orchestrator,
    uint256 _divisor,
    uint256 _ratio,
    uint256 _burnFee,
    uint256 _liquidationPenalty,
    address _altsOracle,
    ALTS _altsAddress,
    address _collateralAddress,
    address _collateralOracle,
    address _ethOracle,
    address _feeAddress
  )
    IVaultHandler(
      _orchestrator,
      _divisor,
      _ratio,
      _burnFee,
      _liquidationPenalty,
      _altsOracle,
      _altsAddress,
      _collateralAddress,
      _collateralOracle,
      _ethOracle,
      _feeAddress
    )
  {}
}