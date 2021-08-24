/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma experimental ABIEncoderV2;
pragma solidity >=0.7.6 <0.8.6;

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
        return _add(set._inner, bytes32(uint256(value)));
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

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library ECRecovery {

  function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return (address(0));
    }

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }
  
  function isValidSignature(address from, address to, address signer, uint256[] memory amounts, bytes memory signature) internal pure returns (bool) {
      
      bytes32 message = prefix(keccak256(abi.encodePacked(
            from,
            to,
            amounts[0],
            amounts[1],
            amounts[2],
            amounts[3],
            amounts[4],
            amounts[5],
            amounts[6]
        )));
        
        if(address(recover(message, signature)) == signer) {
            return true;
        }
        else {
            return false;
        }
  }
  
    function gatekeeperIsValidSignature(address from, address to, address gatekeeper, uint256[] memory amounts, bytes[] memory signatures) internal pure returns (bool) {
      
      bytes32 message = prefix(keccak256(abi.encodePacked(
            from,
            to,
            amounts[0],
            amounts[1],
            amounts[2],
            amounts[3],
            amounts[4],
            amounts[5],
            amounts[6],
            signatures[0],
            signatures[1]
        )));
        
        if(address(recover(message, signatures[2])) == gatekeeper) {
            return true;
        }
        else {
            return false;
        }
  }
  
  function prefix(bytes32 message) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        message
    ));
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
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

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract CondorWrappedERC20 is ERC20, AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor() ERC20("Condor Token", "CONDOR") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }
    
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _mint(to, amount);
    }
    
    function burn(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _burn(to, amount);
    }
}

contract CondorForeignBridgeErcToNative is Context, AccessControl, ReentrancyGuard, Pausable {
    
    using SafeMath for uint256;
    
    CondorWrappedERC20 public condor;
  
    uint256 public DIVISIBLE_BASE = 1000000000000000000; //0.1
    
    uint256 public devFee;
    uint256 public burnFee;
    uint256 public bankFee;
    uint256 public totalFee;
    
    address public devWallet;
    address public burnWallet;
    address public bankWallet;
    
    address public auditorWallet;
    address public gatekeeperWallet;
    
    struct TransactionInfo {
        address from;
        address to;
        uint256 amount;
        uint256 totalFeeAmount;
        uint256 burnFeeAmount;
        uint256 bankFeeAmount;
        uint256 devFeeAmount;
        uint256 date;
        uint256 nonce;
        uint256 blockNumber;
        bytes userSignature;
        bytes auditorSignature;
        bytes gatekeeperSignature;
    }
    
    TransactionInfo[] public transactions;
    
    mapping(address => TransactionInfo[]) public userTransactions;
    mapping(address => mapping(uint => bool)) public processed;
      
    fallback() external {
        revert();
    }
    
    constructor(address _condor, uint256 _devFee, uint256 _burnFee, uint256 _bankFee, address _devWallet, address _burnWallet, address _bankWallet, address _auditorWallet, address _gatekeeperWallet) {
        condor = CondorWrappedERC20(_condor);
        
        devFee = _devFee;
        burnFee = _burnFee;
        bankFee = _bankFee;
        updateTotalFee();
        
        devWallet = address(_devWallet);
        burnWallet = address(_burnWallet);
        bankWallet = address(_bankWallet);
        
        auditorWallet = address(_auditorWallet);
        gatekeeperWallet = address(_gatekeeperWallet);
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    function transactionLength() public view returns (uint256) {
        return transactions.length;
    }
    
    function userTransactionLength(address addr) public view returns (uint256) {
        return userTransactions[addr].length;
    }
    
    function updateDevWallet(address _newAddr) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        devWallet = _newAddr;
    }
    
    function updateBurnWallet(address _newAddr) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        burnWallet = _newAddr;
    }
    
    function updateBankWallet(address _newAddr) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        bankWallet = _newAddr;
    }
    
    function updateAuditorWallet(address _newAddr) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        auditorWallet = _newAddr;
    }
    
    function updateGatekeeperWallet(address _newAddr) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        gatekeeperWallet = _newAddr;
    }
    
    function updateBankFee(uint256 _newBankFee) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        bankFee = _newBankFee;
        updateTotalFee();
    }
    
    function updateBurnFee(uint256 _newBurnFee) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        burnFee = _newBurnFee;
        updateTotalFee();
    }
    
    function updateDevFee(uint256 _newDevFee) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        devFee = _newDevFee;
        updateTotalFee();
    }
    
    function updateTotalFee() internal {
        totalFee = 0;
        totalFee = totalFee.add(devFee).add(burnFee).add(bankFee);
    }
    
    function getUserPendingTransactions(address addr, uint256[] memory nonces) public view returns (uint256[] memory pending) {
        
        for (uint256 pid = 0; pid < nonces.length; pid++) {
            if(!processed[addr][nonces[pid]]) {
                pending[pid] = nonces[pid];
            }
        }
    }
    
    function deposit(address _to, uint256[] memory _amounts, bytes[] memory _signatures) external nonReentrant whenNotPaused {
        
       TransactionInfo memory transaction = TransactionInfo({
            from: _msgSender(),
            to: _to,
            amount: _amounts[0],
            totalFeeAmount: _amounts[1],
            burnFeeAmount: _amounts[2],
            bankFeeAmount: _amounts[3],
            devFeeAmount: _amounts[4],
            date: _amounts[5],
            nonce: _amounts[6],
            blockNumber: block.number,
            userSignature: _signatures[0],
            auditorSignature: _signatures[1],
            gatekeeperSignature: _signatures[2]
        });
        
        require(transaction.amount > 0, "Cannot transfer 0");
        require(transaction.amount <= condor.balanceOf(_msgSender()), 'dont have enough balance');
        require(processed[_msgSender()][transaction.nonce] == false, 'transfer already processed');
        
        require(ECRecovery.isValidSignature(_msgSender(), _to, _msgSender(), _amounts, transaction.userSignature), 'user wrong signature');
        require(ECRecovery.isValidSignature(_msgSender(), _to, auditorWallet, _amounts, transaction.auditorSignature), 'auditor wrong signature');
        require(ECRecovery.gatekeeperIsValidSignature(_msgSender(), _to, gatekeeperWallet, _amounts, _signatures), 'gatekeeper wrong signature');
        
        require(totalFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.totalFeeAmount, 'total fees doesnt match');
        require(burnFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.burnFeeAmount, 'burn fees doesnt match');
        require(bankFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.bankFeeAmount, 'bank fees doesnt match');
        require(devFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.devFeeAmount, 'dev fees doesnt match');
      
        require(condor.transferFrom(_msgSender(), devWallet, transaction.devFeeAmount), 'cannot transfer dev fee');
        require(condor.transferFrom(_msgSender(), burnWallet, transaction.burnFeeAmount), 'cannot transfer burn fee');
        require(condor.transferFrom(_msgSender(), bankWallet, transaction.bankFeeAmount), 'cannot transfer bank fee');

        transactions.push(transaction);
        userTransactions[_msgSender()].push(transaction);
        processed[_msgSender()][transaction.nonce] = true;
        
        condor.burn(_msgSender(), transaction.amount.sub(transaction.totalFeeAmount));
    }
    
    function withdraw(address _to, uint256[] memory _amounts, bytes[] memory _signatures) external nonReentrant whenNotPaused {
        
       TransactionInfo memory transaction = TransactionInfo({
            from: _msgSender(),
            to: _to,
            amount: _amounts[0],
            totalFeeAmount: _amounts[1],
            burnFeeAmount: _amounts[2],
            bankFeeAmount: _amounts[3],
            devFeeAmount: _amounts[4],
            date: _amounts[5],
            nonce: _amounts[6],
            blockNumber: block.number,
            userSignature: _signatures[0],
            auditorSignature: _signatures[1],
            gatekeeperSignature: _signatures[2]
        });
        
        require(transaction.amount > 0, "Cannot transfer 0");
        require(transaction.amount <= condor.balanceOf(_msgSender()), 'dont have enough balance');
        require(processed[_msgSender()][transaction.nonce] == false, 'transfer already processed');
        
        require(ECRecovery.isValidSignature(_msgSender(), _to, _msgSender(), _amounts, transaction.userSignature), 'user wrong signature');
        require(ECRecovery.isValidSignature(_msgSender(), _to, auditorWallet, _amounts, transaction.auditorSignature), 'auditor wrong signature');
        require(ECRecovery.gatekeeperIsValidSignature(_msgSender(), _to, gatekeeperWallet, _amounts, _signatures), 'gatekeeper wrong signature');
        
        require(totalFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.totalFeeAmount, 'total fees doesnt match');
        require(burnFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.burnFeeAmount, 'burn fees doesnt match');
        require(bankFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.bankFeeAmount, 'bank fees doesnt match');
        require(devFee.mul(transaction.amount).div(DIVISIBLE_BASE) == transaction.devFeeAmount, 'dev fees doesnt match');
      
        transactions.push(transaction);
        userTransactions[_msgSender()].push(transaction);
        processed[_msgSender()][transaction.nonce] = true;
        
        condor.mint(_to, transaction.amount.sub(transaction.totalFeeAmount));
    }
    
    function pause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        _pause();
    }
    
    function unpause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        _unpause();
    }

}