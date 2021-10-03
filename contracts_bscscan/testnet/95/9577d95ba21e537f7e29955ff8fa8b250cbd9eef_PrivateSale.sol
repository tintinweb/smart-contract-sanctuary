/**
 *Submitted for verification at BscScan.com on 2021-10-03
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

contract PrivateSale is Context, Ownable {
  struct WithdrawalDetail {
    uint256 withdrawalTime;
    uint256 amountWithdrawable;
  }

  IERC20 _token;
  mapping(address => bool) _isInvestor;
  uint256 _rate;
  address payable _controlAddress;
  mapping(address => WithdrawalDetail) _withdrawalDetails;

  modifier onlyInvestor() {
    require(
      _isInvestor[_msgSender()],
      "Doge2PrivateSale: Only an investor can call this function"
    );
    _;
  }

  modifier onlyControlAddress() {
    require(
      _msgSender() == _controlAddress,
      "Doge2PrivateSale: Only control address can call this function"
    );
    _;
  }

  modifier notInvestor(address _investor) {
    require(!_isInvestor[_investor], "Doge2PrivateSale: Already an investor");
    _;
  }

  event AddedInvestor(address _investor);
  event RemovedInvestor(address _investor);
  event TokenSold(address _investor, uint256 amount);
  event WhiteListedForWithdrawal(address _investor);
  event RateChanged(uint256 rate_);

  constructor(
    address token_,
    uint256 rate_,
    address controlAddress_
  ) public Ownable() {
    _token = IERC20(token_);
    _rate = rate_;
    _controlAddress = payable(controlAddress_);
  }

  function addInvestor(address _investor)
    external
    onlyControlAddress
    notInvestor(_investor)
    returns (address)
  {
    _isInvestor[_investor] = true;
    emit AddedInvestor(_investor);
    return _investor;
  }

  function removeInvestor(address _investor) external onlyControlAddress {
    require(_isInvestor[_investor], "Doge2PrivateSale: Not an investor");
    emit RemovedInvestor(_investor);
    _isInvestor[_investor] = false;
  }

  function buyWithImmediateWithdrawal()
    public
    payable
    onlyInvestor
    returns (bool)
  {
    uint256 _valueToBeBought = (msg.value * 10**9) / _rate;
    uint256 _25Percent = (_valueToBeBought * 25) / 100;

    require(
      _token.balanceOf(address(this)) >= _25Percent,
      "Doge2PrivateSale: Not enough tokens to sell"
    );
    bool _sold = _token.transfer(_msgSender(), _25Percent);
    require(_sold, "Doge2PrivateSale: Failed to transfer tokens");
    emit TokenSold(_msgSender(), _25Percent);
    return true;
  }

  function buyWithLateWithdrawal() public payable onlyInvestor returns (bool) {
    uint256 _valueToBeBought = (msg.value * 10**9) / _rate;

    require(
      _token.balanceOf(address(this)) >= _valueToBeBought,
      "Doge2PrivateSale: Not enough tokens to sell"
    );

    WithdrawalDetail storage _withdrawalDetail = _withdrawalDetails[
      _msgSender()
    ];

    if (_withdrawalDetail.withdrawalTime == 0) {
      _withdrawalDetail.withdrawalTime = block.timestamp + (3 * 1 minutes);
    }

    _withdrawalDetail.amountWithdrawable = _valueToBeBought;

    emit WhiteListedForWithdrawal(_msgSender());
    return true;
  }

  function withdraw() external onlyInvestor returns (bool) {
    require(
      _withdrawalDetails[_msgSender()].withdrawalTime <= block.timestamp,
      "Doge2PrivateSale: Can only withdraw in 30 days from purchase request"
    );
    require(
      _token.transfer(
        _msgSender(),
        _withdrawalDetails[_msgSender()].amountWithdrawable
      ),
      "Doge2PrivateSale: Could not withdraw tokens"
    );
    WithdrawalDetail storage _withdrawalDetail = _withdrawalDetails[
      _msgSender()
    ];
    _withdrawalDetail.withdrawalTime = 0;

    emit TokenSold(
      _msgSender(),
      _withdrawalDetails[_msgSender()].amountWithdrawable
    );
    _withdrawalDetail.amountWithdrawable = 0;
    return true;
  }

  function tokensToBeReceived(uint256 _amount) public view returns (uint256) {
    uint256 _tbr = _amount / _rate;
    return _tbr * 10**18;
  }

  function balance(address _account) public view returns (uint256) {
    return _withdrawalDetails[_account].amountWithdrawable;
  }

  function setControlAddress(address controlAddress_) external onlyOwner {
    _controlAddress = payable(controlAddress_);
  }

  function setRate(uint256 rate_) external onlyControlAddress {
    require(rate_ > 0, "Doge2PrivateSale: Rate must be greater than 0");
    _rate = rate_;
    emit RateChanged(rate_);
  }

  function withdrawBNB() external onlyControlAddress returns (bool) {
    uint256 bal = address(this).balance;
    _controlAddress.transfer(bal);
    return true;
  }

  receive() external payable {
    buyWithLateWithdrawal();
  }
}