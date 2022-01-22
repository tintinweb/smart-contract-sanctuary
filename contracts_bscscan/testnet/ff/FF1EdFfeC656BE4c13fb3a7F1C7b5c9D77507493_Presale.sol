/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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

contract Presale {
  uint256 immutable private precision   = 1000000000000000000;
  uint256 immutable private weiConstant = 1000000000000000000;

  IERC20 presaleToken;
  IERC20 stableToken;

  address public owner;
  bool public presaleTokenInitialized;
  bool public stableTokenInitialized;

  /** Price per presaleToken in stableToken in WEI. */
  uint256 public price;
  uint256 public presaleTokensTotal;
  uint256 public presaleTokensSold;
  uint256 public stableTokensRaised;
  uint256 public currentStableTokens;
  mapping(address => uint256) public toRedeem;

  constructor(uint256 _price, uint256 _presaleTokensTotal) {
    owner = msg.sender;
    presaleTokenInitialized = false;
    stableTokenInitialized = false;

    price = _price;
    presaleTokensTotal = _presaleTokensTotal;
    presaleTokensSold = 0;
    stableTokensRaised = 0;
    currentStableTokens = 0;
  }

  event Invest(address walletAddress, uint256 stableTokenAmount, uint256 presaleTokenPurchased);

  /** Modifiers. */

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner can call this.");
    _;
  }

  modifier presaleInitialized {
    require(presaleTokenInitialized == true, "Please initialize presaleToken first.");
    require(stableTokenInitialized == true, "Please initialize stableToken first.");
    _;
  }

  /** Initialize. */
  
  function initializePresaleToken(address presaleTokenAddress) public onlyOwner {
    presaleToken = IERC20(presaleTokenAddress);
    presaleTokenInitialized = true;
  }

  function initializeStableToken(address stableTokenAddress) public onlyOwner {
    stableToken = IERC20(stableTokenAddress);
    stableTokenInitialized = true;
  }

  /** Functions. */

  function changeOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function changePrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function invest(uint256 amount) public presaleInitialized {
    uint256 presaleTokensToBuy = amount / price * weiConstant;
    uint256 presaleTokensLeftToSell = presaleTokensTotal - presaleTokensSold;
    uint256 approveAmount = amount;

    /** ! Make sure there are enough tokens left. */
    /** ! This is probably incorrect. */
    if (presaleTokensToBuy > presaleTokensLeftToSell) {
      approveAmount = approveAmount * precision * presaleTokensLeftToSell / presaleTokensToBuy / precision;
      presaleTokensToBuy = presaleTokensLeftToSell;
    }

    stableToken.approve(address(this), amount);
    /** TODO: Does this 'if' work like this? */
    if (stableToken.transferFrom(msg.sender, address(this), approveAmount)) {
      toRedeem[msg.sender] += presaleTokensToBuy;
      presaleTokensSold += presaleTokensToBuy;
      stableTokensRaised += approveAmount;
      currentStableTokens += approveAmount;
      emit Invest(msg.sender, approveAmount, presaleTokensToBuy);
    }
  }

  function withdrawStableCoin() public onlyOwner {
    stableToken.transferFrom(address(this), owner, currentStableTokens);
    currentStableTokens = 0;
  }

  function automaticallyUpgradePrice() private {
    /** 
     * Upgrade the price when the current presale stage is over and the next one is starting. 
     *
     * Listen to any incoming transfers.
     */
  }

  function someoneTransferedStableTokens() private {
    /** 
     * Listen to any incoming transfers and update toRedeem[].
     */
  }
}