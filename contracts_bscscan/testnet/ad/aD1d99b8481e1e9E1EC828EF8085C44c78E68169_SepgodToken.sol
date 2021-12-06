/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

pragma solidity 0.5.16;

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
  mapping (address => uint256) private __Balances;
  mapping (address => mapping (address => uint256)) private __Allowances;

  address private __LiquidityAddress;
  address private __OwnerAddress;

  uint8 private __LiquidityTax; // 0 - 100
  uint8 private __DevelopmentTax; // 0 - 100

  uint256 private __TotalSupply;
  uint8 private __Decimals;
  string private __Symbol;
  string private __Name;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () public {
    address msgSender = _msgSender();
    __OwnerAddress = msgSender;
    __Name = "SepgodTokenV2";
    __Symbol = "Sepgodo";
    __Decimals = 8;
    __TotalSupply = 100000000 * 10 ** 8; // 100 Millions
    __Balances[msg.sender] = __TotalSupply;

    __LiquidityTax = 5;
    __DevelopmentTax = 5;

    emit OwnershipTransferred(address(0), msgSender);
    emit Transfer(address(0), msg.sender, __TotalSupply);
  }

  modifier onlyOwner() {
    require(__OwnerAddress == _msgSender(), "Ownable: caller is not the __OwnerAddress");
    _;
  }

  function getOwner() external view returns (address) {
    return __OwnerAddress;
  }

  function transferOwnership(address newOwnerAddress) public onlyOwner {
    require(newOwnerAddress != address(0), "Ownable: new __OwnerAddress is the zero address");
    emit OwnershipTransferred(__OwnerAddress, newOwnerAddress);
    __OwnerAddress = newOwnerAddress;
  }

  function getLiquidityTax() external view returns (uint8) { 
    return __LiquidityTax;
  }

  function setLiquidityTax(uint8 value) external onlyOwner {
    require(value <= 20, "Liquidity tax is too high");
    __LiquidityTax = value;
  }

  function getLiquidityAddress() external view returns (address){
    return __LiquidityAddress;
  }

  function setLiquidityAddress(address _address) external onlyOwner () { 
    __LiquidityAddress = _address;
  }

  function getDevelopmentTax() external view returns (uint8) { 
    return __DevelopmentTax;
  }

  function setDevelopmentTax(uint8 value) external onlyOwner {
    require(value <= 20, "Development tax is too high");
    __DevelopmentTax = value;
  }

  function decimals() external view returns (uint8) {
    return __Decimals;
  }

  function symbol() external view returns (string memory) {
    return __Symbol;
  }

  function name() external view returns (string memory) {
    return __Name;
  }

  function totalSupply() external view returns (uint256) {
    return __TotalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return __Balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address _owner, address spender) external view returns (uint256) {
    return __Allowances[_owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), __Allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    _approve(_msgSender(), _spender, __Allowances[_msgSender()][_spender].add(_addedValue));
    return true;
  }

  function decreaseAllowance(address _spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), _spender, __Allowances[_msgSender()][_spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    __Balances[sender] = __Balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    
    if(__LiquidityTax > 0 && __LiquidityAddress != address(0) && recipient != __OwnerAddress && sender != __OwnerAddress) {
      uint256 taxAmount = 0;
      taxAmount = amount.div(100);
      taxAmount = taxAmount.mul(__LiquidityTax);
      __Balances[__LiquidityAddress] = __Balances[__LiquidityAddress].add(taxAmount);

      amount -= taxAmount;
      emit Transfer(sender, __LiquidityAddress, taxAmount);
    }
    
    if(__DevelopmentTax > 0 && __OwnerAddress != address(0) && recipient != __OwnerAddress && sender != __OwnerAddress) {
      uint256 taxAmount = 0;
      taxAmount = amount.div(100);
      taxAmount = taxAmount.mul(__DevelopmentTax);
      __Balances[__OwnerAddress] = __Balances[__OwnerAddress].add(taxAmount);

      amount -= taxAmount;
      emit Transfer(sender, __OwnerAddress, taxAmount);
    }

    __Balances[recipient] = __Balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address _ownerAddress, address _spender, uint256 amount) internal {
    require(_ownerAddress != address(0), "BEP20: approve from the zero address");
    require(_spender != address(0), "BEP20: approve to the zero address");

    __Allowances[_ownerAddress][_spender] = amount;
    emit Approval(_ownerAddress, _spender, amount);
  }
}