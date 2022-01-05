/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/*
    ◘◘◘◘◘◘      ◘◘       ◘◘◘◘◘◘◘◘◘◘     ◘◘◘◘◘◘ 
    ◘◘    ◘◘    ◘◘       ◘◘  ◘◘  ◘◘   ◘◘       
    ◘◘◘◘◘◘◘◘    ◘◘       ◘◘  ◘◘  ◘◘  ◘◘        
    ◘◘    ◘◘    ◘◘       ◘◘  ◘◘  ◘◘   ◘◘       
    ◘◘◘◘◘◘      ◘◘◘◘◘◘◘  ◘◘  ◘◘  ◘◘     ◘◘◘◘◘◘   BLM Platform Token
 
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
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 private Circul_Supply ;
    
    uint256 public Max_balance ; 
    function setfees(uint _autoBurn, uint _LiquidityFee ,uint _MarketingFee,uint _destribFee) public onlyOwner {
    autoBurn= _autoBurn;LiquidityFee = _LiquidityFee;MarketingFee = _MarketingFee;destribFee = _destribFee;}
    uint autoBurn = 1;
    uint LiquidityFee  = 1;
    uint MarketingFee = 1;
    uint destribFee = 1;
    address marketWallet = 0xd000CC73Bb441408a1B860f33377f9ac674B310a ;
/*
4% re-destribution to holders

2% liquditiy

2% marketing

3% burn
*/
  constructor() public {
    _name = "BLM Platform Token”";
    _symbol = "BLMC";
    _decimals = 0;
    _totalSupply = 100000000000 *10**0;                 // 100000000000 token
    Circul_Supply = _totalSupply.mul(5)/100;    // 5000000000 token
    Max_balance = Circul_Supply.mul(5)/1000;// 25000000
    _balances[msg.sender] = _totalSupply;


    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() external view returns (address) { 
    return owner();
  }
  
  function getMaxbalance() external view returns (uint256) {return Max_balance;}
  function setMaxbalance(uint256 newMaxBalance) public onlyOwner {Max_balance=newMaxBalance;}
  function getMarketWallet() external view returns (address) {return marketWallet;}
  function setMarketWallet(address newMarket) public onlyOwner {marketWallet=newMarket;}
  function getDevtWallet() external view returns (address) {return marketWallet;}
  

  
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
    
    _transfer(_msgSender(), recipient, amount);
        
        
    return true;
   
  }
  function BuyAmount(address recipient, uint256 amount) external returns (bool) {
    require(balanceOf(recipient).add(amount) <= Max_balance, "Anti whale mechanism wallet cannot more then 0.005% of coins. This is to prevent whale from holding too much coin.");
    uint256 burnAmount = amount.mul(autoBurn)/100;
    uint256 ownerAmount = amount.mul(LiquidityFee )/100;
    uint256 marketAmount = amount.mul(MarketingFee )/100;
    uint256 destribAmount = amount.mul(destribFee )/100;
    _burn(_msgSender(), burnAmount);
    _transfer(_msgSender(), owner() ,ownerAmount);
    _transfer(_msgSender(), marketWallet ,marketAmount);
    uint256 totalamounttax = ownerAmount.add(destribAmount).add(marketAmount).add(burnAmount);
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

  /*function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }*/


  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /*function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }*/


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
}