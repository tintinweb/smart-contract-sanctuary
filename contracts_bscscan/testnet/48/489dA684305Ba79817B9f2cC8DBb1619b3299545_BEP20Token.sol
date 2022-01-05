/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

/**
    
*/

pragma solidity 0.5.16;

interface IBEP20 {

  function totalSupply() external view returns (uint256);


  function decimals() external view returns (uint8);

 
  function symbol() external view returns (string memory);


  function name() external view returns (string memory);


  function getOwner() external view returns (address);
  
  function getMarketWallet() external view returns (address);

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

contract BEP20Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxBal;
    mapping (address => bool) private _isExcludedFromMaxTrans;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 private Circul_Supply;
    
    uint256 private Max_balance; 
    
    uint256 limiteTrans=1000;
    uint256 countTrans=0;
    uint autoBurn = 1;
    uint SellLiquidityFee  = 2;
    uint BuyLiquidityFee  = 1;
    uint MarketingFee = 1;
    uint DevFee = 1;
    address BurnWallet = 0x000000000000000000000000000000000000dEaD;
    address marketWallet = 0x5892c26B03426a38829eB94A3D798F68050af7dF;
    address DevWallet = 0x0Cd2D9184DA4Da804b1303dDBfa25Cf1e43BE001;

  constructor() public {
    _name = "mohtest";
    _symbol = "MOHtest";
    _decimals = 0;
    _totalSupply = 100000000000 *10**0;                 // 100000000000
    Circul_Supply = _totalSupply.mul(5)/100;    // 5000000000
    Max_balance = Circul_Supply.mul(5)/1000;// 25000000
    _balances[msg.sender] = _totalSupply;


    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() external view returns (address) { 
    return owner();
  }
  function setfees(uint _autoBurn, uint _SellLiquidityFee, uint _BuyLiquidityFee ,uint _MarketingFee,uint _DevFee) public onlyOwner {
    autoBurn= _autoBurn;SellLiquidityFee = _SellLiquidityFee;BuyLiquidityFee = _BuyLiquidityFee;MarketingFee = _MarketingFee;DevFee = _DevFee;}
  function getMaxbalance() external view returns (uint256) {return Max_balance;}
  function getLimiteTrans() external view returns (uint256) {return limiteTrans;}
  function setMaxbalance(uint256 newMaxBalance) public onlyOwner {Max_balance=newMaxBalance;}

  function setLimiteTrans(uint256 newLimiteTrans) public onlyOwner {limiteTrans=newLimiteTrans;}

  function getMarketWallet() external view returns (address) {return marketWallet;}
  function setMarketWallet(address newMarket) public onlyOwner {marketWallet=newMarket;}
  function getDevtWallet() external view returns (address) {return marketWallet;}
  function setDevWallet(address newDev) public onlyOwner {DevWallet=newDev;}

  
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

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }


  function transfer(address recipient, uint256 amount) external returns (bool) {
    require(countTrans <= limiteTrans, "You have reached the number of allowed transactions");

    _transfer(_msgSender(), recipient, amount);
        
    countTrans=countTrans.add(1);
    return true;
   
  }
  function BuyAmount(address recipient, uint256 amount) external returns (bool) {
    require(balanceOf(recipient).add(amount) <= Max_balance, "Anti whale mechanism wallet cannot more then 0.005% of coins. This is to prevent whale from holding too much coin.");
    uint256 burnAmount = amount.mul(autoBurn)/100;
    uint256 ownerAmount = amount.mul(BuyLiquidityFee )/100;
    uint256 marketAmount = amount.mul(MarketingFee )/100;
    uint256 DevAmount = amount.mul(DevFee )/100;
    _burn(_msgSender(), burnAmount);
    _transfer(_msgSender(), owner() ,ownerAmount);
    _transfer(_msgSender(), marketWallet ,marketAmount);
    _transfer(_msgSender(), DevWallet ,DevAmount); 
    uint256 totalamounttax = DevAmount.add(ownerAmount).add(marketAmount).add(burnAmount);
    _transfer(_msgSender(), recipient, amount.sub(totalamounttax));
        
        
    return true;
   
  }

  function SellAmount(address recipient, uint256 amount) external returns (bool) {
    require(balanceOf(recipient).add(amount) <= Max_balance, "Anti whale mechanism wallet cannot more then 0.005% of coins. This is to prevent whale from holding too much coin.");
    uint256 burnAmount = amount.mul(autoBurn)/100;
    uint256 ownerAmount = amount.mul(SellLiquidityFee )/100;
    uint256 marketAmount = amount.mul(MarketingFee )/100;
    uint256 DevAmount = amount.mul(DevFee )/100;
    _burn(_msgSender(), burnAmount);
    _transfer(_msgSender(), owner() ,ownerAmount);
    _transfer(_msgSender(), marketWallet ,marketAmount);
    _transfer(_msgSender(), DevWallet ,DevAmount); 
    uint256 totalamounttax = DevAmount.add(ownerAmount).add(marketAmount).add(burnAmount);
    _transfer(_msgSender(), recipient, amount.sub(totalamounttax));
        
        
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

  
  function burn(uint256 amount) public onlyOwner returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }
function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
function isExcludedFromMaxBal(address account) public view returns(bool) {
        return _isExcludedFromMaxBal[account];
    }
function includeInMaxBal(address account) public onlyOwner {
        _isExcludedFromMaxBal[account] = false;
    }//
function isExcludedFromMaxTrans(address account) public view returns(bool) {
        return _isExcludedFromMaxTrans[account];
    }
function includeInMaxTrans(address account) public onlyOwner {
        _isExcludedFromMaxTrans[account] = false;
    }
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }



  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, BurnWallet, amount);
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
}