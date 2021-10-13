/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity 0.8.6;
//SPDX-License-Identifier: UNLICENSED


interface IERC20 {

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

contract Context {
    
  constructor () { }
  
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }
  
  function _msgData() internal view returns (bytes memory) {
    this;
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
    require(b > 0, errorMessage);
    uint256 c = a / b;
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

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
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
}


contract TestSaga11 is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => bool) private _noReward;
  mapping (address => bool) private _noFeeFrom;
  mapping (address => bool) private _noFeeTo;
  mapping (address => uint256) private _privateSaleAmount;
  mapping (address => bool) private _preSaleMamber;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _totalReward;
  uint256 private _totalNoReward;
  uint256 private _rewardCumulation;

  uint256 private _lastRewardCumulationTime;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  address public _developmentFundsAddress;
  address public _liquidityPoolAddress;

  uint256 public _rewardMilipercent = 5000;
  uint256 public _developmentMilipercent = 3000;
  uint256 public _liquidityMilipercent = 2000;

  constructor() {
    _name = "TestSaga11";
    _symbol = "TSAG11";
    _decimals = 9;
    _totalSupply = 10**15 * 10**9;
    _totalReward = 0;
    _totalNoReward = 0;
    _rewardCumulation = 0;
    _lastRewardCumulationTime = block.timestamp;
    _balances[msg.sender] = _totalSupply;
    _developmentFundsAddress = msg.sender;
    _liquidityPoolAddress = msg.sender;
  
    _noReward[address(0)] = true;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() external override view returns (address) {
    return owner();
  }

  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  function name() external override view returns (string memory) {
    return _name;
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _getBalanceIncReward(account);
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function burn(uint256 amount) external returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "decreased allowance below zero"));
    return true;
  }

 
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "transfer from the zero address");
    require(recipient != address(0), "transfer to the zero address");
    require(amount > 0, "transfer amount must be greater than zero");
    
    uint256 noRewardAmount = _deductBalanceIncReward(sender, amount);
    
    if (!_noFeeFrom[sender] && !_noFeeTo[recipient]) {
      uint256 deductTotal = 0;
      deductTotal = deductTotal.add(_deductDevelopmentFund(sender, noRewardAmount, 10));
      deductTotal = deductTotal.add(_deductLiquidityPool(sender, noRewardAmount, 10));
      deductTotal = deductTotal.add(_deductRewardInc(noRewardAmount, 10));
      noRewardAmount = noRewardAmount.sub(deductTotal);
    }

    amount = _addBalanceIncReward(recipient, noRewardAmount);
    emit Transfer(sender, recipient, amount);
    
 
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "approve from the zero address");
    require(spender != address(0), "approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "burn from the zero address");

    amount = _addBalanceIncReward(address(0), _deductBalanceIncReward(account, amount));

    emit Transfer(account, address(0), amount);
  }


  function _deductDevelopmentFund(address sender, uint256 amount, uint256 totalFeeMultiplier) private returns(uint256) {
    uint256 deductAmount = amount.mul(_developmentMilipercent).mul(totalFeeMultiplier).div(1000000);
    emit Transfer(sender, _developmentFundsAddress, _addBalanceIncReward(_developmentFundsAddress, deductAmount));
    return deductAmount;
  }



  function _deductLiquidityPool(address sender, uint256 amount, uint256 totalFeeMultiplier) private returns(uint256) {
    uint256 deductAmount = amount.mul(_liquidityMilipercent).mul(totalFeeMultiplier).div(1000000);
    emit Transfer(sender, _liquidityPoolAddress, _addBalanceIncReward(_liquidityPoolAddress, deductAmount));
    return deductAmount;
  }
  

  function _deductRewardInc(uint256 amount, uint256 totalFeeMultiplier) private returns(uint256) {
    uint256 deductAmount = amount.mul(_rewardMilipercent).mul(totalFeeMultiplier).div(1000000);
    _rewardCumulation = _rewardCumulation.add(deductAmount);
    return deductAmount;
  }

  function _incRewardArc(uint256 amount) private view returns(uint256) {
     return amount * (_totalSupply - _totalNoReward) / (_totalSupply - _totalNoReward - _totalReward);
  }



  function _excRewardGan(uint256 amount) private view returns(uint256) {
     return amount * (_totalSupply - _totalNoReward - _totalReward) / (_totalSupply - _totalNoReward);
  }

 
  function _getBalanceIncReward(address account) private view returns(uint256) {
    if (!_noReward[account]) {
      return _incRewardArc(_balances[account]);
    }
    return _balances[account];
  }
  
 
  function _deductBalanceIncReward(address account, uint256 amount) private returns(uint256) {
    if (!_noReward[account]) {
      amount = _excRewardGan(amount);
      _balances[account] = _balances[account].sub(amount, "transfer amount exceeds balance");
      return amount;
    } else {
      _balances[account] = _balances[account].sub(amount, "transfer amount exceeds balance");
      _totalReward = _totalReward + amount * _totalReward / (_totalSupply - _totalNoReward);
      _totalNoReward = _totalNoReward.sub(amount);
      return _excRewardGan(amount);
    }
  }
 
  function _addBalanceIncReward(address account, uint256 amount) private returns(uint256) {
    if (!_noReward[account]) {
      _balances[account] = _balances[account].add(amount);
      amount = _incRewardArc(amount);
    } else {
      amount = _incRewardArc(amount);
      _totalReward = _totalReward.sub(amount * _totalReward / (_totalSupply - _totalNoReward));
      _totalNoReward = _totalNoReward + amount;
      _balances[account] = _balances[account].add(amount);
    }
    return amount;
  }


  function setDevelopmentFundsAddress(address account) external onlyOwner returns (bool) {
    _developmentFundsAddress = account;
    return true;
  }


  function setLiquidityPoolAddress(address account) external onlyOwner returns (bool) {
    _liquidityPoolAddress = account;
    return true;
  }

 


 
  function excludeIncludeFeeFrom(address account, bool value) external onlyOwner returns (bool) {
    _noFeeFrom[account] = value;
    return true;
  }


  function excludeIncludeFeeTo(address account, bool value) external onlyOwner returns (bool) {
    _noFeeTo[account] = value;
    return true;
  }
  
 
  function excludeFromReward(address account) external onlyOwner returns (bool) {
    require(!_noReward[account]);
    _noReward[account] = true;
    uint256 balance = _incRewardArc(_balances[account]);
    _totalReward = _totalReward.sub(balance - _balances[account]);
    _totalNoReward = _totalNoReward + balance;
    _balances[account] = balance;
    return true;
  }

}