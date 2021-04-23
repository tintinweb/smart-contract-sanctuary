/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

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
abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
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
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
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
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);

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

contract LaunchX is Ownable {

  struct Whitelist {
    address wallet;
    uint256 amount;
    uint256 rewardedAmount;
    bool whitelist;
    bool redeemed;
  }

  // Libs
  using SafeMath for uint256;

  // Whitelist map
  mapping(address => Whitelist) private whitelist;

  // Private
  IERC20 private _token;
  IERC20 private _acceptedToken;
  // Public
  bool public isInitialized;
  uint256 public startTime;
  uint256 public maxPayableAmount;
  uint256 public exchangeRate;
  uint256 public soldAmount;
  uint256 public totalRaise;
  uint256 public totalParticipant;
  uint256 public totalRedeemed;
  bool public isFinished;

  // Events
  event ESetAcceptedTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetExchangeRate(uint256 _exchangeRate);
  event ESetMaxPayableAmount(uint256 _maxPayableAmount);
  event EOpenSale(uint256 _startTime, bool _isStart);
  event EBuyTokens(address _sender, uint256 _value, uint256 _totalToken, uint256 _rewardedAmount, uint256 _senderTotalAmount, uint256 _senderTotalRewardedAmount, uint256 _senderSoldAmount, uint256 _senderTotalRise, uint256 _totalParticipant, uint256 _totalRedeemed);
  event EFinishSale(bool _isFinished);
  event ERedeemTokens(address _wallet, uint256 _rewardedAmount);
  event EAddWhiteList(address[] _addresses);
  event ERemoveWhiteList(address[] _addresses);
  event EWithdrawAcceptedTokenBalance(address _sender, uint256 _balance);
  event EWithdrawRemainingTokens(address _sender, uint256 _remainingAmount);

  constructor() {
    maxPayableAmount = 1e18;
    // 1 Accepted token = x10 times Sale Token
    exchangeRate = 10;
  }

  // Read: Get accepted token address
  function getAcceptedTokenAddress() public view returns (address tokenAddress) {
    return address(_acceptedToken);
  }

  // Read: Get token address
  function getTokenAddress() public view returns (address tokenAddress) {
    return address(_token);
  }

  // Read: Get Contract Address
  function getContractAddress() public view returns (address) {
    return address(this);
  }

  // Read: Get Total Token
  function getTotalToken() public view returns (uint256) {
    return _token.balanceOf(getContractAddress());
  }

  // Read: Is Sale Start
  function isStart() public view returns (bool) {
    uint256 timestamp = block.timestamp;
    return isInitialized && startTime > 0 && timestamp >= startTime;
  }

  // Read: Calculate Token
  function calculateAmount(uint256 acceptedAmount) public view returns (uint256) {
    uint256 rate = acceptedAmount.mul(exchangeRate);
    uint256 oneAcceptedToken = 10 ** uint256(_acceptedToken.decimals());
    uint256 oneSaleToken = 10 ** uint256(_token.decimals());
    return (rate * oneSaleToken).div(oneAcceptedToken);
  }

  // Read: Get whitelist wallet
  function getWhitelist(address _address) public view returns (
    address _wallet,
    uint256 _amount,
    uint256 _rewardedAmount,
    bool _redeemed,
    bool _whitelist
  ) {
    Whitelist memory whitelistWallet = whitelist[_address];
    return (
    _address,
    whitelistWallet.amount,
    whitelistWallet.rewardedAmount,
    whitelistWallet.redeemed,
    whitelistWallet.whitelist
    );
  }

  // Fallback: Revert receive ether
  fallback() external {
    revert();
  }

  ///////////////////////////////////////////////////
  // BEFORE SALE
  // Write: Accepted Token Address
  function setAcceptedTokenAddress(IERC20 acceptedToken) external onlyOwner {

    require(!isInitialized, "This step should perform before the sale");

    _acceptedToken = acceptedToken;
    // Emit event
    emit ESetAcceptedTokenAddress(acceptedToken.name(), acceptedToken.symbol(), acceptedToken.decimals(), acceptedToken.totalSupply());
  }

  // Write: Token Address
  function setTokenAddress(IERC20 token) external onlyOwner {

    require(!isInitialized, "This step should perform before the sale");

    _token = token;
    // Emit event
    emit ESetTokenAddress(token.name(), token.symbol(), token.decimals(), token.totalSupply());
  }

  // Write: Owner set exchange rate
  function setExchangeRate(uint256 _exchangeRate) external onlyOwner {

    require(!isInitialized, "This step should perform before the sale");
    require(_exchangeRate > 0, "The rate must not be zero");

    exchangeRate = _exchangeRate;
    // Emit event
    emit ESetExchangeRate(exchangeRate);
  }

  // Write: Owner set max payable amount
  function setMaxPayableAmount(uint256 _maxAmount) external onlyOwner {

    require(!isInitialized, "This step should perform before the sale");
    require(_maxAmount > 0, "The max amount must not be zero");

    maxPayableAmount = _maxAmount;
    // Emit event
    emit ESetMaxPayableAmount(maxPayableAmount);
  }

  // Write: Open sale
  // Ex _startTime = 1618835669
  function openSale(uint256 _startTime) external onlyOwner {

    require(!isInitialized, "This step should perform before the sale");
    require(getTokenAddress() != address(0), "Token address has not initialized yet");
    require(getAcceptedTokenAddress() != address(0), "Accepted token address has not initialized yet");
    require(getTotalToken() > 0, "Total token for sale must greater than zero");
    require(maxPayableAmount > 0, "Max payable amount must greater than zero");
    require(exchangeRate > 0, "Exchange rate must greater than zero");

    startTime = _startTime;
    isFinished = false;
    isInitialized = true;
    // Emit event
    emit EOpenSale(startTime, isStart());
  }

  ///////////////////////////////////////////////////
  // IN SALE
  // Write: User buy token
  // Convert Accepted token to Sale token
  function buyTokens(uint256 acceptedAmount) external {

    address senderAddress = _msgSender();
    Whitelist memory whitelistSnapshot = whitelist[senderAddress];

    // Asserts
    require(isStart(), "Sale is not started yet");
    require(!isFinished, "Sale is finished");
    require(whitelistSnapshot.whitelist, "You are not in whitelist");
    require(acceptedAmount > 0, "You must pay some accepted tokens to get sale tokens");
    require(
      maxPayableAmount >= whitelistSnapshot.amount.add(acceptedAmount),
      "You can not send ether more than max payable amount"
    );

    uint256 totalToken = getTotalToken();
    uint256 rewardedAmount = calculateAmount(acceptedAmount);

    require(rewardedAmount > 0, "Zero rewarded amount");

    uint256 lockAmount = soldAmount - totalRedeemed;
    require(lockAmount.add(rewardedAmount) <= totalToken, "Insufficient token");

    // transfer tokens into contract
    require(_acceptedToken.transferFrom(senderAddress, address(this), acceptedAmount));

    // Update total participant
    // Check if current whitelist amount is zero and will be deposit
    // then increase totalParticipant variable
    if (whitelistSnapshot.amount == 0 && acceptedAmount > 0) {
      totalParticipant = totalParticipant.add(1);
    }
    // Update whitelist detail info
    whitelist[senderAddress].amount = whitelistSnapshot.amount.add(acceptedAmount);
    whitelist[senderAddress].rewardedAmount = whitelistSnapshot.rewardedAmount.add(rewardedAmount);
    // Update global info
    soldAmount = soldAmount.add(rewardedAmount);
    totalRaise = totalRaise.add(acceptedAmount);

    // Emit buy event
    emit EBuyTokens(senderAddress, acceptedAmount, totalToken, rewardedAmount, whitelist[senderAddress].amount, whitelist[senderAddress].rewardedAmount, soldAmount, totalRaise, totalParticipant, totalRedeemed);
  }

  // Write: Finish sale
  function finishSale() external onlyOwner returns (bool) {
    isFinished = true;
    // Emit event
    emit EFinishSale(isFinished);
    return isFinished;
  }

  ///////////////////////////////////////////////////
  // AFTER SALE
  // Write: Redeem Rewarded Tokens
  function redeemTokens() external {
    require(whitelist[_msgSender()].whitelist, "Sender is not in whitelist");

    Whitelist memory whitelistWallet = whitelist[_msgSender()];

    require(isFinished, "Sale is not finalized yet");
    require(!whitelistWallet.redeemed, "Redeemed already");
    require(whitelistWallet.rewardedAmount > 0, "No token to redeem");

    whitelist[_msgSender()].redeemed = true;
    _token.transfer(
      whitelistWallet.wallet,
      whitelistWallet.rewardedAmount
    );

    // Update total redeem
    totalRedeemed = totalRedeemed.add(whitelistWallet.rewardedAmount);

    // Emit event
    emit ERedeemTokens(whitelistWallet.wallet, whitelistWallet.rewardedAmount);
  }

  ///////////////////////////////////////////////////
  // FREE STATE
  // Write: Add Whitelist
  function addWhitelist(address[] memory addresses) external onlyOwner {

    uint256 addressesLength = addresses.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      address _address = addresses[i];
      Whitelist memory _whitelist = Whitelist(_address, 0, 0, true, false);
      whitelist[_address] = _whitelist;
    }
    // Emit event
    emit EAddWhiteList(addresses);
  }

  // Write: Remove Whitelist
  function removeWhitelist(address[] memory addresses) external onlyOwner {

    uint256 addressesLength = addresses.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      address _address = addresses[i];
      Whitelist memory _whitelistSnapshot = whitelist[_address];
      whitelist[_address] = Whitelist(
        _address,
        _whitelistSnapshot.amount,
        _whitelistSnapshot.rewardedAmount,
        _whitelistSnapshot.redeemed,
        false);
    }
    // Emit event
    emit ERemoveWhiteList(addresses);
  }

  // Write: Owner withdraw all Accepted Token balance
  function withdrawAcceptedTokenBalance() external onlyOwner {
    address payable sender = _msgSender();

    uint256 balance = _acceptedToken.balanceOf(getContractAddress());
    _acceptedToken.transfer(
      sender,
      balance
    );

    // Emit event
    emit EWithdrawAcceptedTokenBalance(sender, balance);
  }

  // Write: Owner withdraw tokens which are not sold
  function withdrawRemainingTokens() external onlyOwner {
    address payable sender = _msgSender();
    uint256 lockAmount = soldAmount - totalRedeemed;
    uint256 remainingAmount = getTotalToken() - lockAmount;

    _token.transfer(
      sender,
      remainingAmount
    );

    // Emit event
    emit EWithdrawRemainingTokens(sender, remainingAmount);
  }

}