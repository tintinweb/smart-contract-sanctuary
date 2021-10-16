/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity 0.5.16;

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
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
    // Solidity only automatically asserts when dividing by 0
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

  constructor () internal {
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

contract TestToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  
  mapping (address => bool) private _skipFee;

  mapping (address => mapping (address => uint256)) private _allowances;
  
  mapping (address => uint8) public _addressStatus; // 0 NA, 1 holder, 2 excluded from loterry.
  mapping (address => uint256) public _addressIndex;
  mapping (uint256 => address) public _holders;
  mapping (uint256 => address) public _excludedHolders;
  uint256 public _holdersCount; 
  uint256 public _excludedHoldersCount; 


  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  uint256 private _decimalsPower;
  
  address public jackpotAddress1;
  address public jackpotAddress2;
  address public jackpotAddress3;
  address public jackpotAddress4;
  address public superJackpotAddress;
  address public devAddress;
  address public marketingAddress;
  address payable public preSaleAddress;
  
  uint256 public jackpotPercent;
  uint256 public superJackpotPercent;
  uint256 public superJackpotWinPercent;
  uint256 public devPercent;
  uint256 public marketingPercent;
  uint256 public preSaleFeePercent;
  uint256 public preSalePrice;
  uint256 public jackpotInitialAmount;
  

  constructor() public {
    _name = "Test Token";
    _symbol = "TTW";
    _decimals = 9;
    _decimalsPower = 1000000000;
    _totalSupply = 0;
    _balances[msg.sender] = _totalSupply;
    
    jackpotAddress1 = address(1);
    jackpotAddress2 = address(2);
    jackpotAddress3 = address(3);
    jackpotAddress4 = address(4);
    superJackpotAddress = address(5);
    devAddress = msg.sender;
    marketingAddress = msg.sender;
    preSaleAddress = msg.sender;
    jackpotPercent = 2;
    superJackpotPercent = 5;
    superJackpotWinPercent = 1;
    devPercent = 1;
    marketingPercent = 1;
    preSaleFeePercent = 67;
    preSalePrice = 77700000000000;
    jackpotInitialAmount = 1000000000000;
    
    _mint(jackpotAddress1, jackpotInitialAmount);
    _mint(jackpotAddress2, jackpotInitialAmount);
    _mint(jackpotAddress3, jackpotInitialAmount);
    _mint(jackpotAddress4, jackpotInitialAmount);
    
    changeAddressStatus(address(0), 2);
    changeAddressStatus(jackpotAddress1, 2);
    changeAddressStatus(jackpotAddress2, 2);
    changeAddressStatus(jackpotAddress3, 2);
    changeAddressStatus(jackpotAddress4, 2);
    changeAddressStatus(superJackpotAddress, 2);
  }
  
  function getOwner() external view returns (address) {
    return owner();
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    if (!_skipFee[_msgSender()] && !_skipFee[recipient])
        amount = _payFees(amount, _msgSender(), 100);
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    if (!_skipFee[sender] && !_skipFee[recipient])
        amount = _payFees(amount, sender, 100);
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    
    if (_addressStatus[recipient] == 0) {
        changeAddressStatus(recipient, 1);
    }
    
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
  
  function changeAddressStatus(address account, uint8 status) public onlyOwner returns (bool) {
    if (_addressStatus[account] != status) {
      // remove from status list
      if (_addressStatus[account] == 1) {
        if (_addressIndex[account] < _holdersCount) {
          _addressIndex[_holders[_holdersCount]] = _addressIndex[account];
          _holders[_addressIndex[account]] = _holders[_holdersCount];
        }
        _holdersCount--;
      }
      if (_addressStatus[account] == 2) {
        if (_addressIndex[account] < _excludedHoldersCount) {
          _addressIndex[_excludedHolders[_excludedHoldersCount]] = _addressIndex[account];
          _excludedHolders[_addressIndex[account]] = _excludedHolders[_excludedHoldersCount];
        }
        _excludedHoldersCount--;
      }
      // add to new status list
      if (status == 1) {
        _holdersCount++;
        _addressIndex[account] = _holdersCount;
        _addressStatus[account] = status;
        _holders[_holdersCount] = account;
      }
      if (status == 2) {
        _excludedHoldersCount++;
        _addressIndex[account] = _excludedHoldersCount;
        _addressStatus[account] = status;
        _excludedHolders[_excludedHoldersCount] = account;
      }
    }
    return true;
  }
  
  function setPreSalePrice(uint256 amount) public onlyOwner returns (bool) {
    preSalePrice = amount;
    return true;
  }
  
  function setPreSaleAddress(address payable account) public onlyOwner returns (bool) {
    preSaleAddress = account;
    return true;
  }
  
  function setSkipFee(address account, bool value) public onlyOwner returns (bool) {
    _skipFee[account] = value;
    return true;
  }
  
  function setSuperJackpotWinPercent(uint256 amount) public onlyOwner returns (bool) {
    require(amount <= 100, "Set valid percent");
    superJackpotWinPercent = amount;
    return true;
  }
  
  function setJackpotInitialAmount(uint256 amount) public onlyOwner returns (bool) {
    jackpotInitialAmount = amount;
    return true;
  }
  
  function setDevAddress(address account) public onlyOwner returns (bool) {
    devAddress = account;
    return true;
  }
  
  function setMarketingAddress(address account) public onlyOwner returns (bool) {
    marketingAddress = account;
    return true;
  }
  
  function _payFees(uint256 amount, address account, uint256 feePercent) internal returns (uint256) {
    if (feePercent > 0) {
        uint256 jackpotFee = amount.mul(jackpotPercent).mul(feePercent).div(10000);
        uint256 devFee = amount.mul(devPercent).mul(feePercent).div(10000);
        uint256 marketingFee = amount.mul(marketingPercent).mul(feePercent).div(10000);
        uint256 superJackpotFee = amount.mul(superJackpotPercent).mul(feePercent).div(10000);
        
        _transfer(account, jackpotAddress1, jackpotFee);
        _transfer(account, jackpotAddress2, jackpotFee);
        _transfer(account, jackpotAddress3, jackpotFee);
        _transfer(account, jackpotAddress4, jackpotFee);
        _transfer(account, superJackpotAddress, superJackpotFee);
        _transfer(account, devAddress, devFee);
        _transfer(account, marketingAddress, marketingFee);
        
        amount = amount.sub(jackpotFee.mul(4));
        amount = amount.sub(superJackpotFee);
        amount = amount.sub(devFee);
        amount = amount.sub(marketingFee);
    }
    return amount;
  }
  
  function() external payable {
    uint256 amount = _decimalsPower.mul(msg.value).div(preSalePrice);
    _mint(msg.sender, amount);
    if (!_skipFee[msg.sender])
        _payFees(amount, msg.sender, preSaleFeePercent);
    preSaleAddress.transfer(msg.value);
  }
  
  function _getWinner(uint256 playableSupply, uint256 seed) internal view returns (address) {
    uint256 randWinner = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "Winner", seed))) % playableSupply;
    address winner = address(0);
    for (uint i=1; i<=_holdersCount; i++) {
      if (randWinner < _balances[_holders[i]]) {
        winner = _holders[i];
        break;
      }
      randWinner -= _balances[_holders[i]];
    }
    require(winner != address(0), "winner is the zero address");
    return winner;
  }
  
  function doLottery() public onlyOwner returns (bool) {
    uint256 playableSupply = _totalSupply;
    for (uint i=1; i<=_excludedHoldersCount; i++) {
      playableSupply = playableSupply.sub(_balances[_excludedHolders[i]]);
    }

    uint256 randSuperJackpot = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "SuperJackpot"))) % 100;
    if (randSuperJackpot < superJackpotWinPercent) {
       _transfer(superJackpotAddress, jackpotAddress1, _balances[superJackpotAddress]);
    }
    
    address winner1 = _getWinner(playableSupply, 777);
    address winner2 = _getWinner(playableSupply, 888);
    address winner3 = _getWinner(playableSupply, 999);
    
    uint256 total = _balances[jackpotAddress1];
    _transfer(jackpotAddress1, winner1, total.mul(50).div(100));
    _transfer(jackpotAddress1, winner2, total.mul(25).div(100));
    _transfer(jackpotAddress1, winner3, total.mul(15).div(100));
    _burn(jackpotAddress1, _balances[jackpotAddress1]);

    _transfer(jackpotAddress2, jackpotAddress1, _balances[jackpotAddress2]);
    _transfer(jackpotAddress3, jackpotAddress2, _balances[jackpotAddress3]);
    _transfer(jackpotAddress4, jackpotAddress3, _balances[jackpotAddress4]);
    _mint(jackpotAddress4, jackpotInitialAmount);
    return true;
  }
}