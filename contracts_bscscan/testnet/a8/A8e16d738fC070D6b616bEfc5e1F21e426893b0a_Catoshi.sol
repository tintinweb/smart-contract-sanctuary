/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-16
*/

// SPDX-License-Identifier: MIT
/*
 * Copyright © 2020 reflect.finance. ALL RIGHTS RESERVED.
 */

pragma solidity ^0.6.2;


interface IERC20 {
  function totalSupply() external view returns(uint);

  function balanceOf(address account) external view returns(uint);

  function transfer(address recipient, uint amount) external returns(bool);

  function allowance(address owner, address spender) external view returns(uint);

  function approve(address spender, uint amount) external returns(bool);

  function transferFrom(address sender, address recipient, uint amount) external returns(bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}



contract Context {
  constructor() internal {}
  // solhint-disable-previous-line no-empty-blocks
  function _msgSender() internal view returns(address payable) {
    return msg.sender;
  }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    require(b <= a, errorMessage);
    uint c = a - b;

    return c;
  }

  function mul(uint a, uint b) internal pure returns(uint) {
    if (a == 0) {
        return 0;
    }

    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint a, uint b) internal pure returns(uint) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint c = a / b;

    return c;
  }
}




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Catoshi is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    
    mapping (uint256 => bool) private nonceProcessed;
    uint256 _nonce = 0;
    
    uint256 private _totalSupply = 0; 

    uint256 private _mintFee = 5;

    address system;

 

    uint private curTime;

    event SwapRequest(
        address to,
        uint256 amount,
        uint256 nonce
    );

    modifier onlySystem() {
        require(system == _msgSender(), "Ownable: caller is not the system");
        _;
    }

    
    constructor (string memory cats_name, string memory cats_symbol,address _system)  public {
        
        

        _name = cats_name; _symbol = cats_symbol;
        
        curTime = now;

        system = _system;
   
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function setSystem(address _system) external onlyOwner {
        system = _system;
    }
    


   
    /** 
   * @dev Internal function that burns an amount of the token of a given account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0),"Invalid account");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
    
    emit Transfer(account, address(0), value);
  }

  /** 
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
   
  function burn(uint256 _value) external  {
    _burn(msg.sender, _value);
  }
  
  /** 
   * Function to mint tokens
   * @param _value The amount of tokens to mint.
   */
  function mint(uint256 _value, address to) public onlyOwner {
    require(_value > 0,"The amount should be greater than 0");
    _mint(_value,to);
  }

  /** 
   * @dev Internal function that mints an amount of the token of a given account.
   * @param _value The amount that will be mint.
   * @param _tokenOwner The address of the token owner.
   */
  function _mint(uint256 _value,address _tokenOwner) internal {
     require(_tokenOwner != address(0));
    _totalSupply = _totalSupply.add(_value);
    _balances[_tokenOwner] = _balances[_tokenOwner].add(_value);
    emit Transfer(address(0), _tokenOwner, _value);
  }



    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
    }

    

    /**
   * @dev Function for setting mint fee by owner
   * @param mintFee Mint Fee
   */
  function setSwapFee(uint256 mintFee) public onlyOwner returns(bool){
    require(mintFee > 0, "Invalid Percentage");
    _mintFee = mintFee;
    return true;
  }

  /**
   * @dev Function for getting rewards percentage by owner
   */
  function getSwapFee() public view returns(uint256){
    return _mintFee;
  }
  
  function getSwapStatus(uint256 nonce) view external returns(bool) {
      return nonceProcessed[nonce];
  }


    function swap (uint256 amount) external payable{
        _nonce = _nonce.add(1);
        _burn(_msgSender(),amount);
        emit SwapRequest(_msgSender(),amount,_nonce);
    }

    function feeCalculation(uint256 amount) public view returns(uint256) { 
       uint256 _amountAfterFee = (amount-(amount.mul(_mintFee)/1000));
        return _amountAfterFee;
    }  

    function swapBack (address to, uint256 amount, uint256 nonce) external onlySystem{
        require(!nonceProcessed[nonce], "swap already processed");
        nonceProcessed[nonce] = true;
        uint256 temp = feeCalculation(amount);
        _mint(temp, to);
    }  
}