/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

pragma solidity ^0.8.0;

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
  function allowance(address owner, address spender) external view returns (uint256);

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract PrivateSaleAndVesting is Context, Ownable {
  struct VestingDetail {
    uint256 _withdrawalTime;
    uint256 _withdrawalAmount;
    uint256 _lockDuration;
  }

  IERC20 _paymentToken;
  address payable _foundationAddress;
  uint256 _rate;
  uint256 _startTime;
  uint256 _endTime;
  uint256 _daysBeforeWithdrawal;
  uint256 _totalVested;
  uint256 _tokensBought;
  bool _initialized;

  mapping(address => VestingDetail) _vestingDetails;
  mapping(address => bool) _whiteListed;

  modifier onlyFoundationAddress() {
    require(_msgSender() == _foundationAddress, 'token vest: only foundation address can call this function');
    _;
  }

  modifier onlyWhiteListed() {
    require(_whiteListed[_msgSender()], 'token vest: only whitelisted addresses can call this function');
    _;
  }

  event TokenSaleStarted(uint256 _startTime);
  event TokenSaleExtended(uint256 _extension);
  event TokensBoughtAndVested(address _vestedBy, uint256 _vested, uint256 _totalVesting);
  event TokensWithdrawn(uint256 _amount, uint256 _inVesting);
  event RateChanged(uint256 _newRate);
  event Whitelisted(address[] accounts_);

  constructor(
    address paymentToken_,
    uint256 rate_,
    address payable foundationAddress_
  ) Ownable() {
    _paymentToken = IERC20(paymentToken_);
    _rate = rate_;
    _foundationAddress = foundationAddress_;
  }

  /** @dev Start the token sale. Can only be called by the foundation
   *  @param _daysToLast The number of days the token sale should last
   *  @param daysBeforeWithdrawal_ The number of days before tokens can be withdrawn after vesting
   */
  function startSale(
    uint256 _daysBeforeStart,
    uint256 _daysToLast,
    uint256 daysBeforeWithdrawal_
  ) external onlyFoundationAddress {
    uint256 _time = block.timestamp;
    _startTime = _time + (_daysBeforeStart * 1 days);
    _endTime = _startTime + (_daysToLast * 1 days);
    _daysBeforeWithdrawal = (daysBeforeWithdrawal_ * 1 days);
    _initialized = true;
    emit TokenSaleStarted(_time);
  }

  /** @dev Extend the token sale
   *  @param _daysToExtendSaleBy The number of days to extend the end date by
   */
  function extendSale(uint256 _daysToExtendSaleBy) external onlyFoundationAddress {
    require(block.timestamp >= _startTime, 'token vest: sale must be started before the end date can be extended');

    if (_endTime < block.timestamp) _endTime = block.timestamp + (_daysToExtendSaleBy * 1 days);
    else _endTime = _endTime + (_daysToExtendSaleBy * 1 days);

    emit TokenSaleExtended(_daysToExtendSaleBy);
  }

  /** @dev Function to be called by intending vestor. Amount of BNB to spend is sent to this function
   */
  function buyAndVest() public payable onlyWhiteListed {
    uint256 _currentTime = block.timestamp;

    require(_startTime != 0 && _currentTime >= _startTime, 'token vest: sale not started yet');
    require(_endTime > _currentTime, 'token vest: sale has ended');
    require(msg.value >= 2 ether, 'token vest: value is less than 2 ether');

    address _vestor = _msgSender();
    uint256 _vestable = (msg.value * 10**18) / _rate;

    require(
      _totalVested + _vestable <= getAvailableTokens(),
      'token vest: cannot buy and vest as allocation is not enough'
    );

    VestingDetail storage vestingDetail = _vestingDetails[_vestor];
    vestingDetail._withdrawalAmount = vestingDetail._withdrawalAmount + _vestable;
    vestingDetail._withdrawalTime = block.timestamp + _daysBeforeWithdrawal;
    vestingDetail._lockDuration = block.timestamp + 365 days;
    _totalVested = _totalVested + _vestable;
    _tokensBought = _tokensBought + _vestable;

    emit TokensBoughtAndVested(_vestor, vestingDetail._withdrawalAmount, _totalVested);
  }

  /** @dev Withdrawal function. Can only be called after vesting period has elapsed
   */
  function withdraw() external {
    uint256 _cliff = _endTime + (60 * 1 days);
    require(block.timestamp > _cliff, 'token vest: token withdrawal before 2 month cliff');
    VestingDetail storage vestingDetail = _vestingDetails[_msgSender()];
    uint256 _withdrawable;

    require(vestingDetail._withdrawalTime != 0, 'token vest: withdrawal not possible');

    if (block.timestamp >= vestingDetail._lockDuration) {
      _withdrawable = vestingDetail._withdrawalAmount;
    } else {
      _withdrawable = (vestingDetail._withdrawalAmount * 6) / 100;
    }

    require((block.timestamp >= vestingDetail._withdrawalTime), 'token vest: it is not time for withdrawal');
    require(
      getAvailableTokens() >= _withdrawable,
      'token vest: not enough tokens to sell. please reach out to the foundation concerning this'
    );
    require(_paymentToken.transfer(_msgSender(), _withdrawable), 'token vest: could not transfer tokens');

    vestingDetail._withdrawalAmount = vestingDetail._withdrawalAmount - _withdrawable;
    vestingDetail._withdrawalTime = block.timestamp < vestingDetail._lockDuration
      ? block.timestamp + _daysBeforeWithdrawal
      : 0;

    if (block.timestamp >= vestingDetail._lockDuration) vestingDetail._lockDuration = 0;

    _totalVested = _totalVested - _withdrawable;

    emit TokensWithdrawn(_withdrawable, _totalVested);
  }

  /** @dev Function to whitelist addresses. Can only be called by foundation address
   *  @param _accounts The array of addresses to whitelist
   */
  function whitelistForSale(address[] memory _accounts) external onlyFoundationAddress returns (bool) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      require(_accounts[i] != address(0), 'token vest: cannot whitelist a zero address');
      _whiteListed[_accounts[i]] = true;
    }
    emit Whitelisted(_accounts);
    return true;
  }

  /** @dev Function to withdraw BNB deposited during sale. Can only be called by the foundation
   */
  function withdrawBNB() external onlyFoundationAddress {
    uint256 _balance = address(this).balance;
    _foundationAddress.transfer(_balance);
  }

  /** @dev Function to withdraw left-over tokens. Can only be called by the foundation and after the sale has ended.
   */
  function withdrawLeftOverTokens() external onlyFoundationAddress {
    require(block.timestamp >= _endTime, 'token vest: left over tokens can only be withdrawn after sale');
    require(_paymentToken.balanceOf(address(this)) > 0, 'token vest: no left over tokens to withdraw');
    require(
      _paymentToken.transfer(_foundationAddress, _paymentToken.balanceOf(address(this))),
      'token vest: could not withdraw left over tokens'
    );
  }

  /** @dev Set the rate for the sale
   *  @param rate_ The rate to be set
   */
  function setRate(uint256 rate_) external onlyFoundationAddress {
    require(rate_ > 0, 'token vest: rate must be greater than 0');
    _rate = rate_;

    emit RateChanged(_rate);
  }

  /** @dev Set foundation address. Can only be called by contract owner
   *  @param foundationAddress_ address to set
   */
  function setFoundationAddress(address payable foundationAddress_) external onlyOwner {
    require(foundationAddress_ != address(0), 'token vest: set zero address as foundation address');
    _foundationAddress = foundationAddress_;
  }

  /** @dev Get time remaining before sale starts
   */
  function getTimeBeforeStart() public view returns (uint256) {
    uint256 _currentTime = block.timestamp;

    if (_startTime < _currentTime) return 0;

    return _startTime - _currentTime;
  }

  /** @dev Get time remaining before sale ends
   */
  function getRemainingTime() public view returns (uint256) {
    uint256 _currentTime = block.timestamp;

    if (_endTime < _currentTime) return 0;

    return _endTime - _currentTime;
  }

  /** @dev Returns a boolean value indication whether the counter has been started or not
   */
  function isInitialized() external view returns (bool) {
    return _initialized;
  }

  /** @dev Get vesting detail of address
   *  @param _vestor Address for which to view vesting detail
   */
  function getVestingDetail(address _vestor) external view returns (VestingDetail memory _detail) {
    return _vestingDetails[_vestor];
  }

  /** @dev Returns the presently set rate
   */
  function getRate() external view returns (uint256) {
    return _rate;
  }

  /** @dev Returns the amount of tokens bought
   */
  function getTokensBought() external view returns (uint256) {
    return _tokensBought;
  }

  /** @dev Returns the amount of tokens available
   */
  function getAvailableTokens() public view returns (uint256) {
    return _paymentToken.balanceOf(address(this));
  }

  receive() external payable {
    buyAndVest();
  }
}