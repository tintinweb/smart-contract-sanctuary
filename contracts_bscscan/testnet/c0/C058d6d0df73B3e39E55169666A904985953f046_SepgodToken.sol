/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

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

contract SepgodToken is Context, IBEP20 {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  address private _liquidityAddress;
  uint8 private _liquidityTax; // 0 - 100

  address private _ownerAddress;
  uint8 private _developmentTax; // 0 - 100

  address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
  uint8 private _burnTax;

  address private constant _prizeAddress = 0x0000000000000000000000000000000000000777;
  uint8 private _prizeTax;

  uint256 private constant _totalSupply = 100000000 * 10 ** 8;
  uint8 private constant _decimals = 8;
  string private _symbol;
  string private _name;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _name = "ElenaBeans";
    _symbol = "ElenaBeans";

    _liquidityTax = 4;
    _developmentTax = 4;
    _burnTax = 4;
    _prizeTax = 4;

    _ownerAddress = msgSender;
    emit OwnershipTransferred(address(0), msgSender);

    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  modifier onlyOwner() {
    require(_ownerAddress == _msgSender(), "Ownable: caller is not the _ownerAddress");
    _;
  }

  function getOwner() override external view returns (address) {
    return _ownerAddress;
  }

  function transferOwnership(address newOwnerAddress) public onlyOwner {
    require(newOwnerAddress != address(0), "Ownable: new _ownerAddress is the zero address");
    emit OwnershipTransferred(_ownerAddress, newOwnerAddress);
    _ownerAddress = newOwnerAddress;
  }

  //////////////////////////////////////////////////////////
  //////////////////////Liquidity functions/////////////////
  function getLiquidityTax() external view returns (uint8) { 
    return _liquidityTax;
  }

  function setLiquidityTax(uint8 value) external onlyOwner {
    require(value <= 10, "Liquidity tax is too high");
    _liquidityTax = value;
  }

  function getLiquidityAddress() external view returns (address){
    return _liquidityAddress;
  }

  function setLiquidityAddress(address _address) external onlyOwner () { 
    _liquidityAddress = _address;
  }
  //////////////////////Liquidity functions/////////////////
  //////////////////////////////////////////////////////////


  //////////////////////////////////////////////////////////
  //////////////////////Development functions///////////////
  function getDevelopmentTax() external view returns (uint8) { 
    return _developmentTax;
  }

  function setDevelopmentTax(uint8 value) external onlyOwner {
    require(value <= 10, "Development tax is too high");
    _developmentTax = value;
  }
  //////////////////////Development functions///////////////
  //////////////////////////////////////////////////////////


  //////////////////////////////////////////////////////////
  //////////////////////Burn functions//////////////////////
  function setBurnTax(uint8 value) external onlyOwner {
    require(value <= 10, "Burn tax is too high");
    _burnTax = value;
  }

  function getBurnTax() external view returns (uint8) { 
    return _burnTax;
  }

  function getBurnAddress() external pure returns (address){
    return _burnAddress;
  }
  //////////////////////Burn functions//////////////////////
  //////////////////////////////////////////////////////////


  //////////////////////////////////////////////////////////
  //////////////////////Prize functions//////////////////////
  function setPrizeTax(uint8 value) external onlyOwner {
    require(value <= 10, "Prize tax is too high");
    _prizeTax = value;
  }

  function getPrizeTax() external view returns (uint8) { 
    return _prizeTax;
  }

  function getPrizeAddress() external pure returns (address){
    return _prizeAddress;
  }
  //////////////////////Prize functions//////////////////////
  //////////////////////////////////////////////////////////


  function decimals() override external pure returns (uint8) {
    return _decimals;
  }

  function symbol() override external view returns (string memory) {
    return _symbol;
  }

  function name() override external view returns (string memory) {
    return _name;
  }

  function totalSupply() override external pure returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) override external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address _owner, address spender) override external view returns (uint256) {
    return _allowances[_owner][spender];
  }

  function approve(address spender, uint256 amount) override external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].add(_addedValue));
    return true;
  }

  function decreaseAllowance(address _spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    bool applyTaxes = (sender != _ownerAddress && recipient != _ownerAddress); 

    uint256 prizeTaxAmount = 0;
    if(_prizeTax > 0 && recipient != _prizeAddress && applyTaxes) {
      prizeTaxAmount = amount.div(100);
      prizeTaxAmount = prizeTaxAmount.mul(_prizeTax);
      _balances[_prizeAddress] = _balances[_prizeAddress].add(prizeTaxAmount);
      emit Transfer(sender, _prizeAddress, prizeTaxAmount);
    }

    uint256 burnTaxAmount = 0;
    if(_burnTax > 0 && recipient != _burnAddress && applyTaxes) {
      burnTaxAmount = amount.div(100);
      burnTaxAmount = burnTaxAmount.mul(_burnTax);
      _balances[_burnAddress] = _balances[_burnAddress].add(burnTaxAmount);
      emit Transfer(sender, _burnAddress, burnTaxAmount);
    }
    
    uint256 liquidityTaxAmount = 0;
    if(_liquidityTax > 0 && _liquidityAddress != address(0) && applyTaxes) {
      liquidityTaxAmount = amount.div(100);
      liquidityTaxAmount = liquidityTaxAmount.mul(_liquidityTax);
      _balances[_liquidityAddress] = _balances[_liquidityAddress].add(liquidityTaxAmount);
      emit Transfer(sender, _liquidityAddress, liquidityTaxAmount);
    }
    
    uint256 developmentTaxAmount = 0;
    if(_developmentTax > 0 && _ownerAddress != address(0) && applyTaxes) {
      developmentTaxAmount = amount.div(100);
      developmentTaxAmount = developmentTaxAmount.mul(_developmentTax);
      _balances[_ownerAddress] = _balances[_ownerAddress].add(developmentTaxAmount);
      emit Transfer(sender, _ownerAddress, developmentTaxAmount);
    }

    if(prizeTaxAmount > 0) {
      amount -= prizeTaxAmount;
    }

    if(liquidityTaxAmount > 0) {
      amount -= liquidityTaxAmount;
    }

    if(developmentTaxAmount > 0) {
      amount -= developmentTaxAmount;
    }

     if(burnTaxAmount > 0) {
      amount -= burnTaxAmount;
    }

    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address addressValue, address _spender, uint256 amount) internal {
    require(addressValue != address(0), "BEP20: approve from the zero address");
    require(_spender != address(0), "BEP20: approve to the zero address");

    _allowances[addressValue][_spender] = amount;
    emit Approval(addressValue, _spender, amount);
  }
}