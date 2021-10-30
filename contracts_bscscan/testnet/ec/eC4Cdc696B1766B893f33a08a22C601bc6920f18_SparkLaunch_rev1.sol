/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

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

/**
 * SparkLaunch but token distribution after sales will be distributed using Manual Airdrop
 */

contract SparkLaunch_rev1 is Ownable {

  struct WhitelistInput {
    address wallet;
    uint256 maxPayableAmount;
  }

  struct Whitelist {
    address wallet;
    uint256 amount;
    uint256 maxPayableAmount;
    uint256 rewardedAmount;
    bool whitelist;
    bool redeemed;
  }

  // Whitelist map
  mapping(address => Whitelist) private whitelist;

  struct RewardedData{
      address wallet;
      uint256 rewardedAmount;
  }
  
  // Buyers array
  address[] private buyers;

  // Private
  IERC20 private _token;
  uint256 private _tokenDecimal = 18;
  // Public
  uint256 public startTime;
  uint256 public tokenRate;
  uint256 public soldAmount;
  uint256 public totalRaise;
  uint256 public totalParticipant;
  uint256 public totalRedeemed;
  uint256 public totalRewardTokens;
  bool public isFinished;

  // Events
  event ESetAcceptedTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetTokenAddress(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply);
  event ESetTokenRate(uint256 _tokenRate);
  event EOpenSale(uint256 _startTime, bool _isStart);
  event EBuyTokens(address _sender, uint256 _value, uint256 _totalToken, uint256 _rewardedAmount, uint256 _senderTotalAmount, uint256 _senderTotalRewardedAmount, uint256 _senderSoldAmount, uint256 _senderTotalRise, uint256 _totalParticipant, uint256 _totalRedeemed);
  event EFinishSale(bool _isFinished);
  event ERedeemTokens(address _wallet, uint256 _rewardedAmount);
  event EAddWhiteList(WhitelistInput[] _addresses);
  event ERemoveWhiteList(address[] _addresses);
  event EWithdrawBNBBalance(address _sender, uint256 _balance);
  event EWithdrawRemainingTokens(address _sender, uint256 _remainingAmount);
  event EAddRewardTokens(address _sender, uint256 _amount, uint256 _remaingRewardTokens);
  event EAdminTokenRecovery(address tokenRecovered, uint256 amount);

  constructor() {
    // Token rate
    tokenRate = 10000000000000000;
    // default token rate is 0.01
  }

  // Read: Get token address
  function getTokenAddress() public view returns (address tokenAddress) {
    return address(_token);
  }

  // Read: Get Total Token
  function getTotalToken() public view returns (uint256) {
    return totalRewardTokens;
  }

  function isInitialized() public view returns (bool) {
    return startTime != 0;
  }

  // Read: Is Sale Start
  function isStart() public view returns (bool) {
    return isInitialized() && startTime > 0 && block.timestamp >= startTime;
  }

  //read token in BNB
  function getTokenInBNB(uint256 tokens) public view returns (uint256){
    uint256 tokenDecimal = 10 ** _tokenDecimal;
    return (tokens * tokenRate) / tokenDecimal;
  }

  // Read: Calculate Token
  function calculateAmount(uint256 acceptedAmount) public view returns (uint256) {
    uint256 tokenDecimal = 10 ** _tokenDecimal;
    return (acceptedAmount * tokenDecimal) / tokenRate;
  }

  // Read: Get max payable amount against whitelisted address
  function getMaxPayableAmount(address _address) public view returns (uint256) {
    Whitelist memory whitelistWallet = whitelist[_address];
    return whitelistWallet.maxPayableAmount;
  }

  // Read: Get whitelist wallet
  function getWhitelist(address _address) public view returns (
    address _wallet,
    uint256 _amount,
    uint256 _maxPayableAmount,
    uint256 _rewardedAmount,
    bool _redeemed,
    bool _whitelist
  ) {
    Whitelist memory whitelistWallet = whitelist[_address];
    return (
    _address,
    whitelistWallet.amount,
    whitelistWallet.maxPayableAmount,
    whitelistWallet.rewardedAmount,
    whitelistWallet.redeemed,
    whitelistWallet.whitelist
    );
  }

  //Read return remaining reward
  function getRemainingReward() external view returns (uint256){
    return totalRewardTokens - soldAmount;
  }

  // Read return address and their rewardedAmount data
  function getRewardedData() external view returns (RewardedData[] memory){
      RewardedData[] memory _rewardedData = new RewardedData[](buyers.length);

      for (uint x = 0 ; x < buyers.length ; x++ ){
          _rewardedData[x].wallet = buyers[x];
          _rewardedData[x].rewardedAmount = whitelist[buyers[x]].rewardedAmount;
      }


      return _rewardedData;
  }

  // Fallback: Revert receive ether
  fallback() external {
    revert();
  }

  // Write: Token Address
  // Do not call. Set token decimal instead
  function setTokenAddress(IERC20 token) external onlyOwner {
    require(false, "Set token decimal instead");
    require(startTime == 0, "This step should perform before the sale");

    _token = token;
    // Emit event
    emit ESetTokenAddress(token.name(), token.symbol(), token.decimals(), token.totalSupply());
  }

  function setTokenDecimal(uint256 tokenDecimal) external onlyOwner {
    require(startTime == 0, "This step should perform before the sale");  
    _tokenDecimal = tokenDecimal;
  }

  // Write: Owner set exchange rate
  function setTokenRate(uint256 _tokenRate) external onlyOwner {
    require(!isInitialized(), "This step should perform before the sale");
    require(_tokenRate > 0, "The rate must not be zero");

    tokenRate = _tokenRate;
    // Emit event
    emit ESetTokenRate(tokenRate);
  }

  // Write: Open sale
  // Ex _startTime = 1618835669
  function openSale(uint256 _startTime) external onlyOwner {
    require(!isInitialized(), "This step should perform before the sale");
    require(_startTime >= block.timestamp, "start time should be greater than current time");
    require(_tokenDecimal != 0, "Token decimal has not initialized yet");
    require(getTotalToken() > 0, "Total token for sale must greater than zero");

    startTime = _startTime;
    isFinished = false;
    // Emit event
    emit EOpenSale(startTime, isStart());
  }

  ///////////////////////////////////////////////////
  // IN SALE
  // Write: User buy token by sending BNB
  // Convert Accepted bnb to Sale token
  function buyTokens() external payable {

    address payable senderAddress = _msgSender();
    uint256 acceptedAmount = msg.value;
    Whitelist memory whitelistSnapshot = whitelist[senderAddress];

    // Asserts
    require(isStart(), "Sale is not started yet");
    require(!isFinished, "Sale is finished");
    require(whitelistSnapshot.whitelist, "You are not in whitelist");
    require(acceptedAmount > 0, "You must pay some accepted tokens to get sale tokens");

    uint256 rewardedAmount = calculateAmount(acceptedAmount);
    require(
      whitelistSnapshot.maxPayableAmount >= whitelistSnapshot.rewardedAmount + rewardedAmount,
      "You can not send ether more than max payable amount"
    );

    uint256 totalToken = getTotalToken();
    uint256 unsoldTokens = totalRewardTokens - soldAmount;
    uint256 tokenValueInBNB = getTokenInBNB(unsoldTokens);

    if (acceptedAmount > tokenValueInBNB) {
      //refund excess amount
      uint256 excessAmount = acceptedAmount - tokenValueInBNB;
      //remaining amount
      acceptedAmount = acceptedAmount - excessAmount;
      senderAddress.transfer(excessAmount);
      //finish the sale
      isFinished = true;
      emit EFinishSale(isFinished);
      rewardedAmount = calculateAmount(acceptedAmount);
    }

    require(rewardedAmount > 0, "Zero rewarded amount");

    // Update total participant
    // Check if current whitelist amount is zero and will be deposit
    // then increase totalParticipant variable
    if (whitelistSnapshot.amount == 0 && acceptedAmount > 0) {
      totalParticipant = totalParticipant + 1;
      buyers.push(senderAddress);
    }
    // Update whitelist detail info
    whitelist[senderAddress].amount = whitelistSnapshot.amount + acceptedAmount;
    whitelist[senderAddress].rewardedAmount = whitelistSnapshot.rewardedAmount + rewardedAmount;
    // Update global info
    soldAmount = soldAmount + rewardedAmount;
    totalRaise = totalRaise + acceptedAmount;

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
  // redeemToken() function is retained to avoid changes with the contract ABI
  // Do not call this function. Token redemption will be availale in a separate manual airdrop contract
  function redeemTokens() external {address senderAddress = _msgSender();

    require(whitelist[senderAddress].whitelist, "Sender is not in whitelist");

    Whitelist memory whitelistWallet = whitelist[senderAddress];

    require(isFinished, "Sale is not finalized yet");
    require(!whitelistWallet.redeemed, "Redeemed already");
    
    require(false, "Token redemption will be availale in a separate manual airdrop contract");

    whitelist[senderAddress].redeemed = true;
    _token.transfer(
      whitelistWallet.wallet,
      whitelistWallet.rewardedAmount
    );

    // Update total redeem
    totalRedeemed = totalRedeemed + whitelistWallet.rewardedAmount;

    // Emit event
    emit ERedeemTokens(whitelistWallet.wallet, whitelistWallet.rewardedAmount);
    // rewarded amount should b 0 after giving the reward
    whitelist[senderAddress].rewardedAmount = 0;
    whitelist[senderAddress].amount = 0;
  }

  ///////////////////////////////////////////////////
  // FREE STATE
  // Write: Add Whitelist
  function addWhitelist(WhitelistInput[] memory inputs) external onlyOwner {
    require(!isStart(), "Sale is started");

    uint256 addressesLength = inputs.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      WhitelistInput memory input = inputs[i];
      Whitelist memory _whitelist = Whitelist(input.wallet, 0, input.maxPayableAmount, 0, true, false);
      whitelist[input.wallet] = _whitelist;
    }
    // Emit event
    emit EAddWhiteList(inputs);
  }

  // Write: Remove Whitelist
  function removeWhitelist(address[] memory addresses) external onlyOwner {
    require(!isStart(), "Sale is started");

    uint256 addressesLength = addresses.length;

    for (uint256 i = 0; i < addressesLength; i++) {
      address _address = addresses[i];
      Whitelist memory _whitelistSnapshot = whitelist[_address];
      whitelist[_address] = Whitelist(
        _address,
        _whitelistSnapshot.amount,
        _whitelistSnapshot.maxPayableAmount,
        _whitelistSnapshot.rewardedAmount,
        _whitelistSnapshot.redeemed,
        false);
    }
    // Emit event
    emit ERemoveWhiteList(addresses);
  }

  // Write: owner can withdraw all BNB
  function withdrawBNBBalance() external onlyOwner {
    address payable sender = _msgSender();

    uint256 balance = address(this).balance;
    sender.transfer(
      balance
    );

    // Emit event
    emit EWithdrawBNBBalance(sender, balance);
  }

  // Write: Owner withdraw tokens which are not sold
  // withdrawRemainingTokens() is retained to avoid changes with the contract ABI
  function withdrawRemainingTokens() external onlyOwner {
    require(false, "Nothing to withdraw");
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

  // Write: Owner recover wrong tokens 
  function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    emit EAdminTokenRecovery(_tokenAddress, _tokenAmount);
  }

  // Write: Owner can add reward tokens
  function addRewardTokens(uint256 _amount) external onlyOwner {
    require(_amount > 0, "amont should not be 0");

    address payable sender = _msgSender();
    // Take notes for the total reward tokens
    totalRewardTokens = totalRewardTokens + _amount;

    emit EAddRewardTokens(sender, _amount, totalRewardTokens);
  }
}