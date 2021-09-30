/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

interface IERC20 {

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
    
    function decimals() external view returns (uint8);

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract UtopiaPresale {
  using SafeMath for uint256;

  // The token being sold
  IERC20 public token;

  // How many token units a buyer gets per wei
  uint256 public bnbUtopiaRate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Admin address
  address payable private admin;

  // Map of purchase states
  mapping(address => uint256) public purchasedBnb;

  // List of Token purchasers
  address[] public purchaserList;

  // Maximum amount of BNB each account is allowed to buy
  mapping (address => uint256) private bnbAllowanceForUser;

  // Finalization state
  bool public finalized;

  uint256 public openingTime;

  uint256 public tokensAlreadyPurchased;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param bnbValue weis paid for purchase
   * @param tokens amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 bnbValue,
    uint256 tokens
  );

  /**
   * Event for token withdrawal
   * @param withdrawer who withdrew the tokens
   * @param tokens amount of tokens purchased
   */
  event TokenWithdrawal(
    address indexed withdrawer,
    uint256 tokens
  );

  event CrowdsaleFinalized();

  /**
   * @param _bnbUtopiaRate Number of token units a buyer gets per wei
   * @param _token Address of the token being sold
   */
  constructor(uint256 _bnbUtopiaRate, IERC20 _token, uint256 _openingTime) public {
    // Rate should be 350 billion UTP = 600 BNB
    require(_bnbUtopiaRate > 0);
    require(_token != IERC20(address(0)));

    bnbUtopiaRate = _bnbUtopiaRate;
    token = _token;
    admin = msg.sender;
    finalized = false;
    openingTime = _openingTime;

    bnbAllowanceForUser[0x8aC129cb9F87ce4208F4AeB639d223f9E87aedC4] = 2000000000000000000;
    bnbAllowanceForUser[0xAD854532e2a57382C39DBfF65C1E77cfff7a0b23] = 2000000000000000000;
    // bnbAllowanceForUser[""] = 2000000000000000000;
    // bnbAllowanceForUser[""] = 2000000000000000000;
    
  }

  /**
     * @return the crowdsale opening time.
     */
    function getOpeningTime() public view returns (uint256) {
        return openingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= openingTime;
    }


  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  fallback () external payable {
    revert();    
  }
  
  receive () external payable {
    revert();
  }


  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    require(bnbAllowanceForUser[_beneficiary] > 0, "Beneficiary does not have any Bnb allowance left");

    uint256 maxBnbAmount = maxBnb(_beneficiary);
    uint256 weiAmountForPurchase = msg.value > maxBnbAmount ? maxBnbAmount : msg.value;

    weiAmountForPurchase = _preValidatePurchase(_beneficiary, weiAmountForPurchase);

    if (weiAmountForPurchase > 0) {
      // calculate token amount that will be purchased
      uint256 tokens = _getTokenAmount(weiAmountForPurchase);

      // update state
      weiRaised = weiRaised.add(weiAmountForPurchase);
      emit TokenPurchase(
        msg.sender,
        _beneficiary,
        weiAmountForPurchase,
        tokens
      );
      _updatePurchasingState(_beneficiary, weiAmountForPurchase);
    }

    

    if (msg.value > weiAmountForPurchase) {
      uint256 refundAmount = msg.value.sub(weiAmountForPurchase);
      msg.sender.transfer(refundAmount);
    }
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmountForPurchase Value in wei involved in the purchase
   * @return Number of weis which can actually be used for purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmountForPurchase
  )
    public view returns (uint256)
  {
    require(_beneficiary != address(0));
    require(_weiAmountForPurchase != 0);

    uint256 tokensToBePurchased = _getTokenAmount(_weiAmountForPurchase);

    if (token.balanceOf(address(this)) >= tokensToBePurchased.add(tokensAlreadyPurchased)) {
      return _weiAmountForPurchase;
    } else {
      tokensToBePurchased = token.balanceOf(address(this)).sub(tokensAlreadyPurchased);
      return tokensToBePurchased.mul(1e9).div(bnbUtopiaRate);
    }
  }

  

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmountForPurchase Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmountForPurchase
  )
    internal
  {
    if (purchasedBnb[_beneficiary] == 0) {
      purchaserList.push(_beneficiary);
    }
    purchasedBnb[_beneficiary] = purchasedBnb[_beneficiary].add(_weiAmountForPurchase);
    bnbAllowanceForUser[_beneficiary] = bnbAllowanceForUser[_beneficiary].sub(_weiAmountForPurchase);
    tokensAlreadyPurchased = tokensAlreadyPurchased.add(_getTokenAmount(_weiAmountForPurchase));
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmountForPurchase Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmountForPurchase
   */
  function _getTokenAmount(uint256 _weiAmountForPurchase)
    public view returns (uint256)
  {
    return _weiAmountForPurchase.mul(bnbUtopiaRate).div(1e9);
  }

  /**
   * @dev Determines how BNB is stored/forwarded on purchases.
   */
  function forwardFunds() external {
    require(admin == msg.sender, "not admin!");
    admin.transfer(address(this).balance);
  }

  function maxBnb(address _beneficiary) public view returns (uint256) {
    return bnbAllowanceForUser[_beneficiary].sub(purchasedBnb[_beneficiary]);
  }

  function numberOfPurchasers() public view returns (uint256) {
    return purchaserList.length;
  }

  /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
  function finalize() public {
      require(admin == msg.sender, "not admin!");
      require(!finalized, "Crowdsale already finalized");

      finalized = true;

      emit CrowdsaleFinalized();
  }

  function withdrawTokens() public {
      // calculate token amount to send for each purchaser and sends it
      require(finalized, "Crowdsale not finalized");
      uint256 tokens =  _getTokenAmount(purchasedBnb[msg.sender]);
      require(tokens > 0, "No tokens left to be withdrawn");
      
      token.transfer(msg.sender, tokens);
      purchasedBnb[msg.sender] = 0;

      emit TokenWithdrawal(msg.sender, tokens);
  }


  function transferAnyERC20Token(address tokenAddress, uint256 tokens) external {
    require(admin == msg.sender, "not admin!");
    IERC20(tokenAddress).transfer(admin, tokens);
  }

  function setBnbAllowanceForUser(address _address, uint256 weiAllowed) public {
    require(admin == msg.sender, "not admin!");
    bnbAllowanceForUser[_address] = weiAllowed;
    // Default should be 1000000000000000000 wei (1 BNB)
  }

  function viewBnbAllowanceForUser(address _address) public view returns (uint256) {
    return bnbAllowanceForUser[_address];
  }
}