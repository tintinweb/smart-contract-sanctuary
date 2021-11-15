// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: None
/*
 * $RXC (rxc.world)
 * Transaction Fee: 5%
 * Transaction Fee breakdown:
 * - Treasury Fee: 25% of transaction fee
 * - Operations Fee: 25% of transaction fee
 * - Marketing Fee: 25% of transaction fee
 * - Developers Fee: 25% of transaction fee
 */
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/access/Ownable.sol";

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


contract RxcToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _specialBalances;
  mapping (address => uint256) private _specialExpenses;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;

  uint256 maxTxAmount;

  //$RXC transaction fee
  uint256 public _transactionFee;
  uint256 public _developerFee;
  uint256 public _treasuryFee;
  uint256 public _operationsFee;
  uint256 public _marketingFee;

  //balance of special addresses 
  uint256 private _specialBalance;
  
  uint256 private _developersInitialBalance = 500000 * 10 ** 9;
  uint256 private _operationsInitialBalance = 1000000 * 10 ** 9;

  //special addresses
  address public operationsAddress;
  address public treasuryAddress;
  address public developersAddress;
  address public marketingAddress; 

  mapping (address => bool) private _isSpecialAddress;

  //setting up SafeSale token locks
    mapping (address => TokenLocks) private tokenLocks;
    mapping (string => address[]) private tokenLockAddresses;
    struct TokenLocks {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        string lockType; //presale, founders, etc.
    }
    mapping (address => bool) private _presaleUnlocked;
    uint256 private constant _presaleUnlockPrice = 50 * 10**6 * 10**9;  // This is 0.05 BNB
    uint256 private constant _presaleMinimum = 100 * 10**6 * 10**9;  // This is 0.1 BNB - must include 18 zeroes
    uint256 private constant _presaleMaximum = 1 * 10**9 * 10**9;  // This is 1 BNB - must include 18 zeroes
    uint256 private constant _tokenPerBNB = 35000;  //15,000
    uint256 private constant _presaleLockDurationSeconds = ( 6 * 2592000 );  // Number of months times seconds in a 30 day period
    uint256 public totalTokensTradedPresale;
    uint256 public presaleMaxTokens;
    bool public safeSaleActive = false;
    uint256 public numOfHODLers;

    event presaleUnlockSuccessful(address sender, string message);
    event presalePaymentSuccessful(address sender, string message);
    // End of SafeSale
    
    bool public maintenanceMode;

  constructor(
    uint256 __totalSupply, /*address _operationsAddress, address _developersAddress, address _marketingAddress,*/
    uint256 transactionFee, /*uint256 developerFee, uint256 treasuryFee, uint256 operationsFee, uint256 marketingFee,*/
    uint256 _maxTxAmount,
    uint256 _presaleMaxTokens
  ) {
    _name = "RxC";
    _symbol = "RXC";
    _decimals = 9;
    _totalSupply = __totalSupply * 10**9;//1000000

    maxTxAmount = _maxTxAmount * 10**9;

    operationsAddress = 0xf6a194a8e8A25eDe2d61bE532F4E288734eFF5Fc;//0xf6a194a8e8A25eDe2d61bE532F4E288734eFF5Fc;
    developersAddress = 0xb132E3575fe3297a7e4D91075EaF5366096BC2aB;//0xb132E3575fe3297a7e4D91075EaF5366096BC2aB;
    marketingAddress = 0x8EC842C1624AE15d70daCBc16919bDc9Bbc60cAd;//0x8EC842C1624AE15d70daCBc16919bDc9Bbc60cAd;
    treasuryAddress = 0x3F5B839E070116C88deccb857516197246843359;//0xEF7e457508601C9D76428D2503E7A3e4c0FB5358

    _isSpecialAddress[operationsAddress] = true;
    _isSpecialAddress[developersAddress] = true;
    _isSpecialAddress[marketingAddress] = true;
    _isSpecialAddress[treasuryAddress] = true;

    _transactionFee = transactionFee;//5
    _developerFee = 25;//25
    _treasuryFee = 25;//25
    _operationsFee = 25;//25
    _marketingFee = 25;//25

    presaleMaxTokens = _presaleMaxTokens * 10**9;

    uint256 _treasuryInitialBalance = _totalSupply.sub(_developersInitialBalance).sub(_operationsInitialBalance); 
    _balances[treasuryAddress] = _treasuryInitialBalance;
    _specialBalances[developersAddress] = _developersInitialBalance;
    _specialBalances[operationsAddress] = _operationsInitialBalance;
    
    assignManualLock(developersAddress, _developersInitialBalance, 24,"developers", true);
    assignManualLock(operationsAddress, _operationsInitialBalance, 24,"operations", true);
    
    emit Transfer(address(0), treasuryAddress, _treasuryInitialBalance);
    emit Transfer(address(0),operationsAddress,_operationsInitialBalance);
    emit Transfer(address(0),developersAddress,_developersInitialBalance);
  }

    function setMaintenanceMode(bool _maintenanceMode) public onlyOwner {
        maintenanceMode = _maintenanceMode;
    }
    
  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view override returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the token name.
   */
  function name() external view override returns (string memory) {
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
    return _getCurrentBalance(account);
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
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
    _transfer(sender, recipient, amount);
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
    require(!maintenanceMode,"Maintenance mode");
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(_getCurrentBalance(sender) >= amount,"BEP20: transfer amount exceeds balance");
    if(sender != owner() && recipient != owner()){
      require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
    }

    if(_takeFee(sender) && _takeFee(recipient)){
      _transferRegular(sender, recipient, amount);
    }else if(!_takeFee(sender) && _takeFee(recipient)){
      _transferSpecialSender(sender, recipient, amount);
    }else if(_takeFee(sender) && !_takeFee(recipient)){
      _transferSpecialReceiver(sender, recipient, amount);
    }else if(!_takeFee(sender) && !_takeFee(recipient)){
      _transferSpecialBoth(sender, recipient, amount);
    }
  }

  //if both address is special address
  function _transferSpecialBoth(address sender, address recipient, uint256 amount) private {
    if(amount > _specialBalances[sender]){
        _specialExpenses[sender] = _specialExpenses[sender].add(amount);
    }else{
        _specialBalances[sender] = _specialBalances[sender].sub(amount);
    }
    _specialBalances[recipient] = _specialBalances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  //if sender is special address
  function _transferSpecialSender(address sender, address recipient, uint256 amount) private {
    if(amount > _specialBalances[sender]){
        _specialExpenses[sender] = _specialExpenses[sender].add(amount);
    }else{
        _specialBalances[sender] = _specialBalances[sender].sub(amount);
    }
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  //if receiver is special address
  function _transferSpecialReceiver(address sender, address recipient, uint256 amount) private {
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    if(amount >= _specialExpenses[sender]){
        _specialExpenses[recipient] = _specialExpenses[recipient].sub(amount);
    }else{
        _specialBalances[recipient] = _specialBalances[recipient].add(amount);
    }
    emit Transfer(sender, recipient, amount);
  }

  //if both sender and receiver is not special address. only regular transfer has transaction fee
  function _transferRegular(address sender, address recipient, uint256 amount) private {
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    uint256 transactionFee = amount.mul(_transactionFee).div(100);
    uint256 toRecipient = amount.sub(transactionFee);
    _balances[recipient] = _balances[recipient].add(toRecipient);
    _takeTransactionFee(sender,transactionFee);
    emit Transfer(sender, recipient, toRecipient);
  }

  function getTreasuryBalance() public view returns(uint256){
    return _getCurrentBalance(treasuryAddress);
  }

  function getOperationsBalance() public view returns(uint256){
    return _getCurrentBalance(operationsAddress);
  }

  function getDevelopersBalance() public view returns(uint256){
    return _getCurrentBalance(developersAddress);
  }

  function getMarketingBalance() public view returns(uint256){
    return _getCurrentBalance(marketingAddress);
  }

  //$RXC custom balanceOf 
  function _getCurrentBalance(address account) private view returns(uint256){
    if(account == developersAddress){
      return _specialBalance
        .mul(_developerFee)
        .div(100)
        .add(_specialBalances[account])
        .sub(_specialExpenses[account])
        .sub(getTokenLockAmount(account));
    }
    if(account == operationsAddress){
      return _specialBalance
        .mul(_operationsFee)
        .div(100)
        .add(_specialBalances[account])
        .sub(_specialExpenses[account])
        .sub(getTokenLockAmount(account));
    }
    if(account == treasuryAddress){
      return _specialBalance.mul(_treasuryFee).div(100).add(_balances[account]).add(_specialBalances[account]).sub(_specialExpenses[account]);
    }
    if(account == marketingAddress){
      return _specialBalance.mul(_marketingFee).div(100).add(_balances[account]).add(_specialBalances[account]).sub(_specialExpenses[account]);
    }
    if (tokenLocks[account].amount != 0){
      return _balances[account].sub(getTokenLockAmount(account));
    } 
    return _balances[account];
  }

  function _takeFee(address account) private view returns(bool){
    if(_isSpecialAddress[account]){
      return false;
    }
    return true;
  }

  function _takeTransactionFee(address sender,uint256 transactionFee) private {
    _specialBalance = _specialBalance.add(transactionFee);
    emit Transfer(sender, operationsAddress, transactionFee.mul(_operationsFee).div(100));
    emit Transfer(sender, developersAddress, transactionFee.mul(_developerFee).div(100));
    emit Transfer(sender, marketingAddress, transactionFee.mul(_marketingFee).div(100));
    emit Transfer(sender, treasuryAddress, transactionFee.mul(_treasuryFee).div(100));
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

  receive() external payable{}

  /**
    * @dev Sets the transaction fee rate of $SLPY
   */
  function setTransactionFee(uint256 newTransactionFee) public onlyOwner {
    _transactionFee = newTransactionFee;
  }

  /** @dev This section integrates SafeSale                                   
    *   SafeSale is meant to elimate bots and post-presale sell-off that only hurts legitimate projects.
    *   True tokens are meant to be a long term HODL.
    *   SafeSale is meant to provide a safe presale of your tokens by requiring
    *   registration and a small payment beforehand to elimiate, or at least reduce,
    *   the ability for bots to take over your presale reducing the dreaded plummet
    *   of price when the bots take their profits and screw everyone else.
    *   The second part of SafeSale is the linear lock which creates a linear lock schedule
    */

  function toggleSafeSale(bool toggle) public onlyOwner {
      safeSaleActive = toggle;
  }

  // @dev This view is to display the wallet owner's locked\available tokens and endTime within dapp
  function getLockedWalletDetails(address account) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
      uint256 _startTime = tokenLocks[account].startTime;
      uint256 _endTime = tokenLocks[account].endTime;
      uint256 _totalAmount = tokenLocks[account].amount;
      uint256 _lockedAmount = getTokenLockAmount(account);
      uint256 _accessibleAmount = _totalAmount - _lockedAmount;
      return (_startTime, _endTime, _totalAmount, _lockedAmount, _accessibleAmount, block.timestamp);
  }

  // @dev This function figures the proportion of time that has passed since the start relative to the end date and returns the proportion of tokens accessible
  function getTokenLockAccessible(address account) private view returns (uint256) {
      if (block.timestamp > tokenLocks[account].endTime) return (tokenLocks[account].amount); // If endtime has passed then display all since they're unlocked
      return (tokenLocks[account].amount * (((block.timestamp - tokenLocks[account].startTime) * 100) / (tokenLocks[account].endTime - tokenLocks[account].startTime))) / 100;
  }

  // @dev This function figures the proportion of time that has passed since the start relative to the end date and returns the proportion of tokens locked
  function getTokenLockAmount(address account) private view returns (uint256) {
      if (block.timestamp > tokenLocks[account].endTime) return 0;
      return (tokenLocks[account].amount * (((tokenLocks[account].endTime - block.timestamp) * 100) / (tokenLocks[account].endTime - tokenLocks[account].startTime))) / 100;
  }

  // @dev This is the start of the SafeSale registrtation process. This function takes in the presale unlock amount and approves it
  function acceptPresaleUnlockPayment() public payable {
      require(safeSaleActive, "Presale is not active at this time");
      require(msg.value == _presaleUnlockPrice, "Value not equal to unlock amount");
      require(totalTokensTradedPresale <= presaleMaxTokens, "Presale is Full");
      _presaleUnlocked[msg.sender] = true;
      emit presaleUnlockSuccessful(msg.sender, "Thank you, Presale is unlocked!");
  }

  /** @dev If the wallet is approved then the wallet can send coin to this function
  *   The function first requires that the amount falls within the presale limits
  *   Then it makes sure the sender is approved for the presale, that they paid the registration
  *   Then it figures out how many tokens to provide based on the amount sent in, this uses the variable set up top to determine ratio needed
  *   Then it calls the assignTokenLock function which records the lock and transfers the tokens
  */
  function acceptPresalePayment() public payable {
      require(safeSaleActive, "Presale is not active at this time");
      require(msg.value >= _presaleMinimum, "Amount below minimum"); // This is the minimum
      require(msg.value <= _presaleMaximum, "Amount above maximum"); // This is the maximum
      require(_presaleUnlocked[msg.sender], "You have not unlocked Presale"); // make sure they unlocked
      require(tokenLocks[msg.sender].amount == 0, "You already have tokens locked");
      uint256 _tokensFromPayment = ((msg.value / 10**9) * _tokenPerBNB); // count the tokens to give based on value sent in
      uint256 _lockEndTime = _presaleLockDurationSeconds + block.timestamp; // How long to lock for
      assignTokenLock(msg.sender, (_tokensFromPayment * 10**9), block.timestamp, _lockEndTime ,"presale", false);
      totalTokensTradedPresale = totalTokensTradedPresale.add(_tokensFromPayment);
      emit presalePaymentSuccessful(msg.sender, "Thank you, Presale payment is Successful!");
  }
    
  function manualPresaleAssignment(address recipient, uint256 _tokens, uint256 _lockStartTime, uint256 _lockEndTime) public onlyOwner {
      _presaleUnlocked[recipient] = true;
      assignTokenLock(recipient, _tokens, _lockStartTime, _lockEndTime ,"presale", false);
      totalTokensTradedPresale = totalTokensTradedPresale.add(_tokens);
      emit presalePaymentSuccessful(recipient, "Presale payment Successful!");
  }

  /** @dev This function provides a mechanism to provide tokens to anyone at anytime for any # of months
  *   This function uses a 30day period to account for 1 month, yes this will not calculate out to a full year however it is close enough
  */
  function assignManualLock(address account, uint256 _amount,uint256 _lengthInMonths, string memory _type, bool isInitial) public onlyOwner {
      uint256 _lockEndTime = (_lengthInMonths * 2592000) + block.timestamp;
      assignTokenLock(account, _amount, block.timestamp, _lockEndTime ,_type, isInitial);
  }

  // @dev This function records the transaction to keep track of the lock and then transfers the tokens to the wallet as normal
  function assignTokenLock(address account, uint256 _amount, uint256 _startTime, uint256 _endTIme, string memory _type, bool isInitial) private {
      tokenLocks[account].amount = _amount;
      tokenLocks[account].startTime = _startTime;
      tokenLocks[account].endTime = _endTIme;
      tokenLocks[account].lockType = _type;
      tokenLockAddresses[_type].push(account);
      if(!isInitial)
        _transfer(treasuryAddress, account, _amount);
  }

  // @dev A view to access the list of addresses that have locked tokens
  function getTokenLockAddresses(string memory _type) public view returns (address[] memory){
      return tokenLockAddresses[_type];
  }

  function checkWalletPresaleUnlock(address account) public view returns (bool) {
      return _presaleUnlocked[account];
  }

  function getPresaleDetails() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256){
      return (_presaleUnlockPrice, _presaleMinimum, _presaleMaximum, _tokenPerBNB, _presaleLockDurationSeconds, totalTokensTradedPresale, presaleMaxTokens);
  }

  /** @dev This ends the SafeSale section */

}

