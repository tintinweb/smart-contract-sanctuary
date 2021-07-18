/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

pragma solidity 0.8.6;
//SPDX-License-Identifier: UNLICENSED

/*
    /$$$$$$$                                           /$$   /$$
   | $$__  $$                                         | $$  / $$
   | $$  \ $$   /$$$$$$    /$$$$$$/$$$$     /$$$$$$   |  $$/ $$/
   | $$$$$$$/  /$$__  $$  | $$_  $$_  $$   /$$__  $$   \  $$$$/ 
   | $$__  $$ | $$$$$$$$  | $$ \ $$ \ $$  | $$$$$$$$    >$$  $$ 
   | $$  \ $$ | $$_____/  | $$ | $$ | $$  | $$_____/   /$$/\  $$
   | $$  | $$ |  $$$$$$$  | $$ | $$ | $$  |  $$$$$$$  | $$  \ $$
   |__/  |__/  \_______/  |__/ |__/ |__/   \_______/  |__/  |__/

*/

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


contract RemeX is Context, IERC20, Ownable {
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
  uint256 private _rewardCumulationTime;
  uint256 private _lastRewardCumulationTime;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  address public _developmentFundsAddress;
  address public _fundRaisingAddress;
  address public _liquidityPoolAddress;

  uint256 public _privateSaleStartTime;
  uint256 public _preSaleStartTime;
  uint256 public _publicStartTime;

  uint256 public _rewardMilipercent = 3000;
  uint256 public _developmentMilipercent = 3000;
  uint256 public _fundRaisingMilipercent = 1000;
  uint256 public _liquidityMilipercent = 3000;

  constructor() {
    _name = "RemeX";
    _symbol = "RMX";
    _decimals = 9;
    _totalSupply = 10**15 * 10**9;
    _totalReward = 0;
    _totalNoReward = 0;
    _rewardCumulation = 0;
    _rewardCumulationTime = 0;
    _lastRewardCumulationTime = block.timestamp;
    _balances[msg.sender] = _totalSupply;
    _developmentFundsAddress = msg.sender;
    _fundRaisingAddress = msg.sender;
    _liquidityPoolAddress = msg.sender;
    _privateSaleStartTime = block.timestamp;
    _preSaleStartTime = _privateSaleStartTime + 30 * 86400;
    _publicStartTime = _preSaleStartTime + 30 * 86400;
  
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
 
  /**
    * Calculates fee depending on public sale start time for presale members.
    *
    * @param sender Address of amount sender.   
    * 
    * @return Calculated fee for presale member.
    */ 
  function totalFeeMultiplierForSender(address sender, uint256 timestamp) private view returns(uint256) {
    if (_preSaleMamber[sender]) {
      uint256 publicSaleFeeEnds = _publicStartTime + 20 * 86400; // 20 days
      if (timestamp < publicSaleFeeEnds) {
        return 10 + (publicSaleFeeEnds - timestamp) / 86400; // 10 + ramaining days %
      }
    }
    return 10;
  }
  
  /**
    * Checks if private presale member dont extended limit of possible amount transfer, 
    * depending on yearly quarters.
    *
    * @param sender Address of amount sender.  
    * @param amount Amount of token which sender wants to transfer.
    * 
    * @return boolean If selected amount is transferable
    */ 
  function checkIfBalanceNotFrozen(address sender, uint256 amount, uint256 timestamp) private view returns(bool) {
    if (_privateSaleAmount[sender] > 0) {
      uint256 quarter = (timestamp - _publicStartTime) / 7776000; // 90 days
      if (quarter < 3) {
        uint frozen = _privateSaleAmount[sender] * (3 - quarter) / 4;
        return (_getBalanceIncReward(sender) - frozen >=  amount);
      }
    }
    return true;
  }

  /**
    * Amount transfer function between 2 addresses after the conditions are met.
    * Conditions: 
    *   1) Sender must not be burn address.
    *   2) Recipient must not be burn address.
    *   3) Amount must be higher then 0.
    *   4) Contract must be in live or sender must be owner or recipient must be the owner.
    *   5) Checks if private presale member dont extended limit of possible amount transfer, 
    *     depending on yearly quarters.
    *   6) Transfer amount must not exceed total balanse of sender.
    *
    * Additionaly only owner can transfer amount before public start date.
    * Fee is separated depending on imposed percentages in addresses 
    * (Development, Fundraising, Liquidity) and goes as reward for holders.
    *
    * @param sender Address of amount sender.  
    * @param recipient Address of amount reciever.
    * @param amount Amount of token which sender wants to transfer. 
    */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "transfer from the zero address");
    require(recipient != address(0), "transfer to the zero address");
    require(amount > 0, "transfer amount must be greater than zero");
    require(block.timestamp >= _publicStartTime || sender == owner() || recipient == owner());
    require(checkIfBalanceNotFrozen(sender, amount, block.timestamp)); // private sale
    
    uint256 noRewardAmount = _deductBalanceIncReward(sender, amount);
    
    if (!_noFeeFrom[sender] && !_noFeeTo[recipient]) {
      uint256 deductTotal = 0;
      uint256 totalFeeMultiplier = totalFeeMultiplierForSender(sender, block.timestamp); // presale
      deductTotal = deductTotal.add(_deductDevelopmentFund(sender, noRewardAmount, totalFeeMultiplier));
      deductTotal = deductTotal.add(_deductFundRaising(sender, noRewardAmount, totalFeeMultiplier));
      deductTotal = deductTotal.add(_deductLiquidityPool(sender, noRewardAmount, totalFeeMultiplier));
      deductTotal = deductTotal.add(_deductReward(noRewardAmount, totalFeeMultiplier));
      noRewardAmount = noRewardAmount.sub(deductTotal);
    }

    amount = _addBalanceExcReward(recipient, noRewardAmount);
    emit Transfer(sender, recipient, amount);

    if (sender == owner() && block.timestamp < _publicStartTime) {
      if (block.timestamp < _preSaleStartTime) {
         _privateSaleAmount[recipient] = _privateSaleAmount[recipient].add(amount);
      } else {
        _preSaleMamber[recipient] = true;
      }
    }
    
    if (_lastRewardCumulationTime + _rewardCumulationTime <= block.timestamp) {
      _lastRewardCumulationTime = _lastRewardCumulationTime + _rewardCumulationTime;
      _totalReward = _totalReward + _rewardCumulation;
      _rewardCumulation = 0;   
    } 
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "approve from the zero address");
    require(spender != address(0), "approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "burn from the zero address");

    amount = _addBalanceExcReward(address(0), _deductBalanceIncReward(account, amount));

    emit Transfer(account, address(0), amount);
  }

  /**
    * Calculates amount which must be transfered to development address.
    *
    * @param amount Transaction token amount.
    * @param totalFeeMultiplier Coefficient for adjusting presale fee. 
    * 
    * @return deductAmount Amount for development address.
    */ 
  function _deductDevelopmentFund(address sender, uint256 amount, uint256 totalFeeMultiplier) private returns(uint256) {
    uint256 deductAmount = amount.mul(_developmentMilipercent).mul(totalFeeMultiplier).div(1000000);
    emit Transfer(sender, _developmentFundsAddress, _addBalanceExcReward(_developmentFundsAddress, deductAmount));
    return deductAmount;
  }

  /**
    * Calculates amount which must be transfered to fundraising address.
    *
    * @param amount Transaction token amount.
    * @param totalFeeMultiplier Coefficient for adjusting presale fee. 
    * 
    * @return deductAmount Amount for fundraising address.
    */ 
  function _deductFundRaising(address sender, uint256 amount, uint256 totalFeeMultiplier) private returns(uint256) {
    uint256 deductAmount = amount.mul(_fundRaisingMilipercent).mul(totalFeeMultiplier).div(1000000);
    emit Transfer(sender, _fundRaisingAddress, _addBalanceExcReward(_fundRaisingAddress, deductAmount));
    return deductAmount;
  }

  /**
    * Calculates amount which must be transfered to liquidity.
    *
    * @param amount Transaction token amount.
    * @param totalFeeMultiplier Coefficient for adjusting presale fee. 
    * 
    * @return deductAmount Amount for liquidity.
    */ 
  function _deductLiquidityPool(address sender, uint256 amount, uint256 totalFeeMultiplier) private returns(uint256) {
    uint256 deductAmount = amount.mul(_liquidityMilipercent).mul(totalFeeMultiplier).div(1000000);
    emit Transfer(sender, _liquidityPoolAddress, _addBalanceExcReward(_liquidityPoolAddress, deductAmount));
    return deductAmount;
  }
  
  /**
    * Calculates amount which must be transfered to holder rewards.
    *
    * @param amount Transaction token amount.
    * @param totalFeeMultiplier Coefficient for adjusting presale fee. 
    * 
    * @return deductAmount Amount for holder rewards.
    */ 
  function _deductReward(uint256 amount, uint256 totalFeeMultiplier) private returns(uint256) {
    uint256 deductAmount = amount.mul(_rewardMilipercent).mul(totalFeeMultiplier).div(1000000);
    _rewardCumulation = _rewardCumulation.add(deductAmount);
    return deductAmount;
  }
  
  /**
    * Inteface to add reward to balance.
    *
    * @param amount Balance without reward.
    * 
    * @return Balance amount including reward.
    */ 
  function _incReward(uint256 amount) private view returns(uint256) {
     return amount * (_totalSupply - _totalNoReward) / (_totalSupply - _totalNoReward - _totalReward);
  }


  /**
    * Inteface to deduct reward from balance.
    *
    * @param amount Balance including reward.
    * 
    * @return Balance amount excluding reward.
    */ 
  function _excReward(uint256 amount) private view returns(uint256) {
     return amount * (_totalSupply - _totalNoReward - _totalReward) / (_totalSupply - _totalNoReward);
  }

  /**
    * Interface to get balance amount including reward.
    *
    * @param account Address of user.
    * 
    * @return Balance amount including reward.
    */ 
  function _getBalanceIncReward(address account) private view returns(uint256) {
    if (!_noReward[account]) {
      return _incReward(_balances[account]);
    }
    return _balances[account];
  }
  
  /**
    * Interface to deduct amount from address considering reward.
    *
    * @param account Address of user.
    * @param amount Amount of tokens including reward.
    * 
    * @return Deducted tokens excluding reward.
    */
  function _deductBalanceIncReward(address account, uint256 amount) private returns(uint256) {
    if (!_noReward[account]) {
      amount = _excReward(amount);
      _balances[account] = _balances[account].sub(amount, "transfer amount exceeds balance");
      return amount;
    } else {
      _balances[account] = _balances[account].sub(amount, "transfer amount exceeds balance");
      _totalReward = _totalReward + amount * _totalReward / (_totalSupply - _totalNoReward);
      _totalNoReward = _totalNoReward.sub(amount);
      return _excReward(amount);
    }
  }
  
  /**
    * Interface to add amount to address excluding reward.
    *
    * @param account Address of user.
    * @param amount Amount of tokens excluding rewards.
    * 
    * @return Add tokens including reward.
    */
  function _addBalanceExcReward(address account, uint256 amount) private returns(uint256) {
    if (!_noReward[account]) {
      _balances[account] = _balances[account].add(amount);
      amount = _incReward(amount);
    } else {
      amount = _incReward(amount);
      _totalReward = _totalReward.sub(amount * _totalReward / (_totalSupply - _totalNoReward));
      _totalNoReward = _totalNoReward + amount;
      _balances[account] = _balances[account].add(amount);
    }
    return amount;
  }

  /**
    * Interface to set address for development funds.
    *
    * @param account Address for collecting development funds.
    * 
    * @return boolean.
    */
  function setDevelopmentFundsAddress(address account) external onlyOwner returns (bool) {
    _developmentFundsAddress = account;
    return true;
  }

  /**
    * Interface to set address for fundraising tokens.
    *
    * @param account Address for collecting fundraising tokens.
    * 
    * @return boolean.
    */
  function setFundRaisingAddress(address account) external onlyOwner returns (bool) {
    _fundRaisingAddress = account;
    return true;
  }

  /**
    * Interface to set address for liquidity pool tokens.
    *
    * @param account Address for collecting liquidity pool tokens.
    * 
    * @return boolean.
    */
  function setLiquidityPoolAddress(address account) external onlyOwner returns (bool) {
    _liquidityPoolAddress = account;
    return true;
  }

  /**
    * Function for checking fee threshold. 
    *  1) Summary of all fees must not exceed 10%.
    *  2) Fee for development funds must not exceed 5%.
    * 
    * @return boolean
    */
  function checkFeeThreshold() private view returns(bool) {
    if (_rewardMilipercent + _developmentMilipercent + _fundRaisingMilipercent + _liquidityMilipercent > 10000) {
      return false;
    }
    if (_developmentMilipercent > 5000) {
      return false;
    }
    return true;
  }

  /**
    * Interface to set fee percentage for rewards.
    * 
    * @param value Percentage in milipercents.
    * 
    * @return boolean
    */
  function setRewardMilipercent(uint256 value) external onlyOwner returns (bool) {
    _rewardMilipercent = value;
    require(checkFeeThreshold());
    return true;
  }

  /**
    * Interface to set fee percentage for development funds.
    * 
    * @param value Percentage in milipercents.
    * 
    * @return boolean
    */
  function setDevelopmentMilipercent(uint256 value) external onlyOwner returns (bool) {
    _developmentMilipercent = value;
    require(checkFeeThreshold());
    return true; 
  }

  /**
    * Interface to set fee percentage for fundraising.
    * 
    * @param value Percentage in milipercents.
    * 
    * @return boolean
    */
  function setFundRaisingMilipercent(uint256 value) external onlyOwner returns (bool) {
    _fundRaisingMilipercent = value;
    require(checkFeeThreshold());
    return true;   
  }

  /**
    * Interface to set fee percentage for liquidity pool.
    * 
    * @param value Percentage in milipercents.
    * 
    * @return boolean
    */
  function setLiquidityMilipercent(uint256 value) external onlyOwner returns (bool) {
    _liquidityMilipercent = value;
    require(checkFeeThreshold());
    return true;
  }

  /**
    * Interface to set reward cumulation time interval.
    * 
    * @param value Time interval.
    * 
    * @return boolean
    */
  function setRewardCumulationTime(uint256 value) external onlyOwner returns (bool) {
    _rewardCumulationTime = value;
    return true;
  }

  /**
    * Interface to exclude address from fee during transfer.
    * 
    * @param account Address of sender.
    * @param value Boolean.
    * 
    * @return boolean
    */
  function excludeIncludeFeeFrom(address account, bool value) external onlyOwner returns (bool) {
    _noFeeFrom[account] = value;
    return true;
  }

  /**
    * Interface to exclude address from fee during recieve.
    * 
    * @param account Address of recipient.
    * @param value Boolean.
    * 
    * @return boolean
    */
  function excludeIncludeFeeTo(address account, bool value) external onlyOwner returns (bool) {
    _noFeeTo[account] = value;
    return true;
  }
  
  /**
    * Interface to exclude address from rewards.
    * 
    * @param account Address.
    *
    * @return boolean
    */
  function excludeFromReward(address account) external onlyOwner returns (bool) {
    require(!_noReward[account]);
    _noReward[account] = true;
    uint256 balance = _incReward(_balances[account]);
    _totalReward = _totalReward.sub(balance - _balances[account]);
    _totalNoReward = _totalNoReward + balance;
    _balances[account] = balance;
    return true;
  }

  /**
    * Interface to set private pre sale duration in hours.
    * 
    * @param hr Hours.
    *
    * @return boolean
    */
  function setPrivateSaleHours(uint256 hr) external onlyOwner returns (bool) {
    require(block.timestamp < _preSaleStartTime);
    uint256 preSaleLength = _publicStartTime - _preSaleStartTime;
    _preSaleStartTime = _privateSaleStartTime + hr * 3600; 
    _publicStartTime = _preSaleStartTime + preSaleLength;
    return true;
  }

  /**
    * Interface to set public pre sale duration in hours.
    * 
    * @param hr Hours.
    *
    * @return boolean
    */
  function setPreSaleHours(uint256 hr) external onlyOwner returns (bool) {
    require(block.timestamp < _publicStartTime);
    _publicStartTime = _preSaleStartTime + hr * 3600;
    return true;
  }
}