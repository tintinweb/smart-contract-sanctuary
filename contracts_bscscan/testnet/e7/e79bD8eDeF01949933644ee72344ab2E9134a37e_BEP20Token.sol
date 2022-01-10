/**
 *Submitted for verification at BscScan.com on 2022-01-09
*/

pragma solidity ^0.8.11;

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
    * 7EX - @dev Returns the amount of tokens owned by Contract.
    */
    function balanceOfContract() external view returns (uint256);
    
    /* Set how much bnb is the token */
    function setPrice(uint8 price) external returns (bool);
    
    /* Set Profit Address */
    function setProfitAddr(address addr) external returns(bool);

    /* Bank take th amount of BNB */
    function pix() external payable returns (bool);
    
    /* Get how much bnb is the token */
    function getPrice() external view returns (uint);
    
    /* Get how many bnb the address has */
    function getAmountBNB() external view returns (uint);
    
    /* Get Profit Address */
    function getProfitAddr()  external view returns (address);

    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
    * another (`to`).
    *
    * Note that `value` may be zero.
    */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
    * another (`to`).
    *
    * Note that `value` may be zero.
    */
    event Deposit(address indexed from, address indexed to, uint256 value);

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
  constructor ()  { }

  function _msgSender() internal view returns (address) {
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
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
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

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
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
  
  /* 7EX implementation */
  uint public _amount_bnb;
  uint public _token_price;
  uint public _sell_des; //Deprec price to sell
  uint public _pix_amount;
  address _profit_addr;
  address[] private _customers;
  /* ------------------ */
 
  
  constructor() public {
    _name = "7X COIN";
    _symbol = "SXC";
    _decimals = 8;
    _totalSupply = 1000 * 10 ** uint(_decimals);
    _amount_bnb = 0;
    _token_price = 1;
    _sell_des = 50; /* 2% */

    _balances[address(this)] = _totalSupply * 50 / 100;
    _balances[address(msg.sender)] = _totalSupply * 50 / 100;
    emit Transfer(address(0), address(this), _totalSupply * 50 / 100);
  }


  /**
   * @dev Buy 7EX Token.
   */
  receive() external payable {
      
    require(msg.value > 0, "Buy Error: Value needs > 0");
    require(_balances[address(this)] > (msg.value * _token_price), "Buy Error: TotalSupply isnt enouf");

    uint tokens;
    _amount_bnb += msg.value;
    tokens = msg.value * _token_price;
    
    _balances[address(this)] -= tokens;
    _balances[msg.sender] += tokens;
    _customers.push(msg.sender);
    
    emit Transfer(address(this), msg.sender, tokens);
    
  }
  
  /**
   * @dev Sell 7EX Token.
   */
  function withdraw(uint256 amount) external {    
    require(amount > 0, "Token amount: Needs to be > 0");
    require(_balances[address(msg.sender)] >= amount, "Token amount: You han't token enouf");
    
    uint bnbs;
    uint tax;

    bnbs = (amount/_token_price);
    
    tax = bnbs / _sell_des;
    
    require(_amount_bnb >= bnbs, "Withdraw: Not enouf BNB");
    
    _amount_bnb -= bnbs;
    bnbs -= tax;
    _pix_amount += tax;
    
    _balances[address(msg.sender)] -= amount;
    _balances[address(this)] += amount;
    
    payable(msg.sender).transfer(bnbs);
    emit Deposit(msg.sender, address(this), amount);
  }

  /**
   * @dev Profit 7XC.
   */
  function profit(uint256 amount) onlyOwner external payable {
    require(amount > 0, "Profit Error: Value needs > 0");

    address cliente;
    uint256 percent;
    uint profit_percent_vlr;
    uint profit_vlr;
    
    profit_vlr = msg.value;

    for (uint pos = _customers.length-1; pos > 0; pos--) { 
        cliente = address(_customers[pos]);
        if (_balances[cliente] > 0) {
          percent = _balances[cliente] / _balances[address(this)];
          profit_percent_vlr = percent * msg.value;
          if (profit_vlr >= profit_percent_vlr) {
              profit_vlr = profit_vlr - profit_percent_vlr;
              payable(cliente).transfer(profit_percent_vlr);
          }
        } else {
          delete _balances[cliente];
        } 
    }
  }

  /**
  * @dev Price 7EX Token.
  */
  function setPrice(uint8 price) override onlyOwner public returns(bool) {
    require(price > 0, "Price: Needs to be > 0");
    _token_price = price;
    return true;
    
  }

  /**
  * @dev Set PRofit Address.
  */
  function setProfitAddr(address addr) onlyOwner override public returns(bool) {
    _profit_addr = addr;
    return true;
  }  

  /**
  * @dev Sell_des 7EX Token.
  */
  function setSelldes(uint8 des) onlyOwner public returns(bool){
    require(des > 0, "Deprec Tax: Needs to be > 0");
    _sell_des = des;
    return true;
    
  }
  
  /**
   * @dev PIX 7EX Token.
   */
  function pix() override onlyOwner public payable returns(bool) {
    require(_pix_amount > 0, "PIX: Amount is 0");
    payable(msg.sender).transfer(_pix_amount);
    _pix_amount = 0;
    return true;
  }
    
    

    
  /**
   * @dev Returns the price of token.
   */
  function getProfitAddr() override external view returns (address) {
    return _profit_addr;
  }

 /**
   * @dev Returns the price of token.
   */
  function getPrice() override external view returns (uint) {
    return _token_price;
  }


  /**
   * @dev Returns the BNB Bank Balance.
   */
  function getAmountBNB() override external view returns (uint) {
    return _amount_bnb;
  }
  
  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() override external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() override external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() override external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() override external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() override external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }
  
   /**
   * @dev See {BEP20-balanceOfContract}.
   */
  function balanceOfContract() override external view returns (uint256) {
    return _balances[address(this)];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) override external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

    /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

}