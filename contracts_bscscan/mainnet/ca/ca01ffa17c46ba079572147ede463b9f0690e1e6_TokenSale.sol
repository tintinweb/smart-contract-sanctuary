/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

contract TokenSale is Context, Ownable {
  address payable _withdrawalWallet;
  uint256 _rate;
  uint256 _startTime;
  uint256 _endTime;
  bool _initialized = false;
  bool _finalized = false;
  IERC20 _tradeToken;

  modifier onlyWithdrawalAddress() {
    require(
      _msgSender() == _withdrawalWallet,
      "Error: Only organization can call this function"
    );
    _;
  }

  event RateChanged(uint256 newRate);
  event TokenSaleStarted(uint256 startTime, uint256 endTime);
  event TokenSaleExtended(uint256 newEndTime);
  event TokenSaleFinalized(uint256 finalTime);
  event TokenSold(uint256 amount, address buyer);
  event BNBWithdrawn(address recipient, uint256 amount);

  constructor(
    address withdrawalWallet_,
    uint256 rate_,
    address token_
  ) public Ownable() {
    _withdrawalWallet = payable(withdrawalWallet_);
    _rate = rate_;
    _tradeToken = IERC20(token_);
  }

  function _setRate(uint256 rate_) private returns (bool) {
    require(rate_ > 0, "Error: Rate must be greater than 0");
    _rate = rate_;
    emit RateChanged(_rate);
    return true;
  }

  function setRate(uint256 rate_)
    external
    onlyWithdrawalAddress
    returns (bool)
  {
    return _setRate(rate_);
  }

  function _beginTokenSale(uint256 _daysFromStart) private returns (bool) {
    require(!_initialized, "Error: Token sale already begun");
    _startTime = block.timestamp;
    _endTime = block.timestamp + (_daysFromStart * 1 days);
    _initialized = true;
    emit TokenSaleStarted(_startTime, _endTime);
  }

  function beginTokenSale(uint256 _daysFromStart)
    external
    onlyWithdrawalAddress
    returns (bool)
  {
    return _beginTokenSale(_daysFromStart);
  }

  function extendTokenSale(uint256 extension)
    external
    onlyWithdrawalAddress
    returns (bool)
  {
    require(
      !_finalized,
      "Error: Token sale has been finalized and cannot be extended"
    );
    _endTime = block.timestamp + (extension * 1 days);
    emit TokenSaleExtended(_endTime);
    return true;
  }

  function finalizeTokenSale() external onlyWithdrawalAddress returns (bool) {
    require(!_finalized, "Error: Token sale cannot be finalized twice");
    require(
      _tradeToken.transfer(
        _withdrawalWallet,
        _tradeToken.balanceOf(address(this))
      ),
      "Error: Could not transfer remaining tokens"
    );
    _finalized = true;
    emit TokenSaleFinalized(block.timestamp);
    return true;
  }

  function getRemainingDays() public view returns (uint256) {
    if (_finalized) return 0;

    uint256 currentTimestamp = block.timestamp;

    if (_endTime > currentTimestamp) return _endTime - currentTimestamp;

    return 0;
  }

  function buyXOX() public payable {
    require(
      block.timestamp >= _startTime,
      "Error: Token sale has not begun yet"
    );
    require(block.timestamp < _endTime, "Error: Token sale has ended");

    uint256 _valueAsWei = msg.value * 10**18;
    uint256 _valueDividedByRate = _valueAsWei / _rate;
    uint256 _tenPercent = (_valueDividedByRate * 10) / 100;
    uint256 _sending = _valueDividedByRate + _tenPercent;

    require(
      _tradeToken.balanceOf(address(this)) >= _sending,
      "Error: Not enough tokens to sell"
    );
    bool sold = _tradeToken.transfer(msg.sender, _sending);
    require(sold, "Error: Failed to send XOXCASH");
    emit TokenSold(_sending, msg.sender);
  }

  function setWithdrawalWallet(address withdrawalWallet_)
    external
    onlyOwner
    returns (bool)
  {
    _withdrawalWallet = payable(withdrawalWallet_);
    return true;
  }

  function getRate() external view returns (uint256) {
    return _rate;
  }

  function getStartTime() external view returns (uint256) {
    return _startTime;
  }

  function getEndTime() external view returns (uint256) {
    return _endTime;
  }

  function withdrawBNB() public onlyWithdrawalAddress returns (bool) {
    uint256 bal = address(this).balance;
    _withdrawalWallet.transfer(bal);
    emit BNBWithdrawn(msg.sender, bal);
  }

  receive() external payable {
    buyXOX();
  }
}