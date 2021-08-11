/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner,address indexed spender, uint256 value);
}
library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "error");
    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "error");
  }
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "error");
  }
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }
  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "error");
  }
  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "error");
    require(isContract(target), "error");
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "error");
  }
  function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
    require(isContract(target), "error");
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "error");
  }
  function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    require(isContract(target), "error");
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }
  function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
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
    require(c >= a, "error");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "error");
    return a - b;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "error");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "error");
    return a / b;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "error");
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
abstract contract NonReentrant {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;
  constructor() internal {
    _status = _NOT_ENTERED;
  }
  modifier nonReentrant() {
    require(_status != _ENTERED, "error");
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
    this;
    return msg.data;
  }
}
abstract contract Ownable is Context {
  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }
  function owner() public view virtual returns (address) {
    return _owner;
  }
  modifier ownerOnly() {
    require(owner() == _msgSender(), "error");
    _;
  }
  function renounceOwnership() public virtual ownerOnly {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public virtual ownerOnly {
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
//-----------------------------------------------------------------------------
contract BEP20 is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  using Address for address;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  uint256 public cappedSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  constructor(string memory name, string memory symbol, uint256 _cappedSupply) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
    cappedSupply = _cappedSupply;
  }
  function getOwner() external view override returns (address) {
    return owner();
  }
  function name() public view override returns (string memory) {
    return _name;
  }
  function decimals() public view override returns (uint8) {
    return _decimals;
  }
  function symbol() public view override returns (string memory) {
    return _symbol;
  }
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "error"));
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "error"));
    return true;
  }
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "error");
    require(recipient != address(0), "error");
    _balances[sender] = _balances[sender].sub(amount, "error");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "error");
    require(_totalSupply < cappedSupply, "error" );
    if (_totalSupply.add(amount) > cappedSupply) {
      uint256 newAmount = cappedSupply.sub(_totalSupply);
      _totalSupply = cappedSupply;
      _balances[account] = _balances[account].add(newAmount);
      emit Transfer(address(0), account, newAmount);
    } else {
      _totalSupply = _totalSupply.add(amount);
      _balances[account] = _balances[account].add(amount);
      emit Transfer(address(0), account, amount);
    }
  }
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "error");
    _balances[account] = _balances[account].sub(amount, "error");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "error");
    require(spender != address(0), "error");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}
library SafeBEP20 {
  using SafeMath for uint256;
  using Address for address;
  function safeTransfer(IBEP20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }
  function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }
  function safeApprove(IBEP20 token, address spender, uint256 value) internal {
    // solhint-disable-next-line max-line-length
    require((value == 0) || (token.allowance(address(this), spender) == 0), "error");
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }
  function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value, "error");
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  function _callOptionalReturn(IBEP20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "error");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "error");
    }
  }
}
//-----------------------------------------------------------------------------
contract PolySunshineToken is BEP20("PolySunshine", "SUN", 1000000000000000000000000) {
  function mint(address _to, uint256 _amount) public ownerOnly {
    _mint(_to, _amount);
  }
}
contract MasterChef is Ownable, NonReentrant {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;
  //---------------------------------------------------------------------------
  uint256 public constant EMISSION_RATE = 0.005 ether;
  uint16 public constant NON_NATIVE_FEE = 250;
  //---------------------------------------------------------------------------
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }
  struct PoolInfo {
    IBEP20 lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accPolySunshinePerShare;
    uint16 depositFeeBP;
  }
  //---------------------------------------------------------------------------
  PolySunshineToken public sun;
  PoolInfo[] public poolInfo;
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  mapping(IBEP20 => bool) public allPools;
  mapping(IBEP20 => bool) public nativePools;
  address public feeAddress;
  uint256 public totalAllocPoint = 0;
  uint256 public startBlock;
  //---------------------------------------------------------------------------
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
  constructor(PolySunshineToken _sun, address _feeAddress, uint256 _startBlock) public {
    sun = _sun;
    feeAddress = _feeAddress;
    startBlock = _startBlock;
  }
  modifier isUnique(IBEP20 _lpToken) {
    require(!allPools[_lpToken], "error");
    _;
  }
 //---------------------------------------------------------------------------
  function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) public ownerOnly isUnique(_lpToken) {
    if (_withUpdate) {
      updateAllPools();
    }
    bool isNative = nativePools[_lpToken];
    uint16 depositFee = 0;
    if (!isNative) {
      depositFee = NON_NATIVE_FEE;
    }
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    allPools[_lpToken] = true;
    poolInfo.push(PoolInfo({lpToken: _lpToken, allocPoint: _allocPoint, lastRewardBlock: lastRewardBlock, accPolySunshinePerShare: 0, depositFeeBP: depositFee})
    );
  }
  function pendingSunshine(uint256 _pid, address _user) external view returns (uint256)  {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 share = pool.accPolySunshinePerShare;
    uint256 pot = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && pot != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 PolySunshineReward = multiplier.mul(EMISSION_RATE).mul(pool.allocPoint).div(totalAllocPoint);
      share = share.add(PolySunshineReward.mul(1e12).div(pot));
    }
    return user.amount.mul(share).div(1e12).sub(user.rewardDebt);
  }
  function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accPolySunshinePerShare).div(1e12).sub(user.rewardDebt);
      if (pending > 0) {
        safePolySunshineTransfer(msg.sender, pending);
      }
    }
    if (_amount > 0) {
      pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
      if (pool.depositFeeBP > 0) {
        uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
        pool.lpToken.safeTransfer(feeAddress, depositFee);
        user.amount = user.amount.add(_amount).sub(depositFee);
      } else {
        user.amount = user.amount.add(_amount);
      }
    }
    user.rewardDebt = user.amount.mul(pool.accPolySunshinePerShare).div(1e12);
    emit Deposit(msg.sender, _pid, _amount);
  }
  function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "error");
    updatePool(_pid);
    uint256 pending = user.amount.mul(pool.accPolySunshinePerShare).div(1e12).sub(user.rewardDebt);
    if (pending > 0) {
      safePolySunshineTransfer(msg.sender, pending);
    }
    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      pool.lpToken.safeTransfer(address(msg.sender), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accPolySunshinePerShare).div(1e12);
    emit Withdraw(msg.sender, _pid, _amount);
  }
  function emergencyWithdraw(uint256 _pid) public nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    pool.lpToken.safeTransfer(address(msg.sender), amount);
    emit EmergencyWithdraw(msg.sender, _pid, amount);
  }
  //---------------------------------------------------------------------------
  function updateAllPools() public {
    for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
      updatePool(pid);
    }
  }
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0 || pool.allocPoint == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 PolySunshineReward = multiplier.mul(EMISSION_RATE).mul(pool.allocPoint).div(totalAllocPoint);
    sun.mint(feeAddress, PolySunshineReward.div(20));
    sun.mint(address(this), PolySunshineReward);
    pool.accPolySunshinePerShare = pool.accPolySunshinePerShare.add(PolySunshineReward.mul(1e12).div(lpSupply));
    pool.lastRewardBlock = block.number;
  }
  function isNativePool(IBEP20 _lpToken) external ownerOnly {
    nativePools[_lpToken] = true;
  }
  //---------------------------------------------------------------------------
  function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
    return _to.sub(_from);
  }
  function safePolySunshineTransfer(address _to, uint256 _amount) internal {
    uint256 pot = sun.balanceOf(address(this));
    bool success = false;
    if (_amount > pot) {
      success = sun.transfer(_to, pot);
    } else {
      success = sun.transfer(_to, _amount);
    }
    require(success, "error");
  }
  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }
}