/**
 *Submitted for verification at BscScan.com on 2021-11-11
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



/**

 * @dev Wrappers over Solidity's arithmetic operations with added overflow

 * checks.

 *

 * Arithmetic operations in Solidity wrap on overflow. This can easily result

 * in bugs, because programmers usually assume that an overflow raises an

 * error, which is the standard behavior in high level programming languages.

 * `SafeMath` restores this intuition by reverting the transaction when an

 * operation overflows.

 *

 * Using this library instead of the unchecked operations eliminates an entire

 * class of bugs, so it's recommended to use it always.

 */

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



  constructor() public {

    _name = "DTOT Coin";

    _symbol = "DTOT";

    _decimals = 18;

    _totalSupply = 1000000000 *10 ** 18;

    _balances[msg.sender] = _totalSupply;



    emit Transfer(address(0), msg.sender, _totalSupply);

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

}