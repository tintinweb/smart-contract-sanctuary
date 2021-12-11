/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT

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
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract StarshipWLCrowdsale {

  // Alpha Starship Token
  IERC20 public token;
  IERC20 public usdToken;

  // Alpha Starship Whitelisted Crowdsale price in dollar. Warning : this price is in dollar, not wei
  // This varable is the only amount that is not in wei in the contract
  uint256 public tokenPrice;

  // Maximum amount of tokens that can be bought per address
  uint256 maximumPurchase;

  // Administrator
  address admin;

  // Amount of wei raised
  uint256 public weiRaised;

  // Multi-signature wallet used to revieve the funds
  address wallet;

  // Whitelist
  mapping (address => bool) public isWhitelisted;

  // Maximum tokens
  mapping (address => uint256) public tokensPurchased;

  // Triggers public crowdsale
  bool isPublic;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /*
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(address[] memory _addrs, address _wallet, address _token, address _usdToken, uint256 _price, uint256 _maxPurchase) {
    require(_token != address(0));

    usdToken = IERC20(_usdToken);
    token = IERC20(_token);
    tokenPrice = _price;
    maximumPurchase = _maxPurchase;
    wallet = _wallet;

    // Adding the addresses to the Whitelist
    for(uint256 i = 0; i < _addrs.length; i++){
      isWhitelisted[_addrs[i]] = true;
    }

    admin = msg.sender;

    isPublic = false;
  }

  modifier onlyWhitelisted {
    if(isPublic == false){
      require(isWhitelisted[msg.sender] == true, "User is not Whitelisted");
    }
    _;
  }

  modifier onlyAdmin {
    require(msg.sender == admin, "You must be admin to execute this function");
    _;

  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev Recieve funciton so that nobody directly sends ETH
   */
  receive() external payable {
    revert(); 
  }

  /**
   * @dev Token purchase
   * @param _beneficiary Address to which the aStarships will be sent
   * @param _weiAmount Amount of dollars to buy aStarships tokens with. In wei
   */
  function buyTokens(address _beneficiary, uint256 _weiAmount) onlyWhitelisted public {
    
    require(_weiAmount > 0, "Amount of tokens purchased must be positive");
    require(tokensPurchased[msg.sender] + _getTokenAmount(_weiAmount) <= maximumPurchase, "Cannot purchase any more tokens");

    _preValidatePurchase(_beneficiary, _weiAmount);

    // calculate token amount to be created
    uint256 tokenAmount = _getTokenAmount(_weiAmount);

    // update state
    weiRaised = weiRaised + _weiAmount;

    _processPurchase(_beneficiary, _weiAmount, tokenAmount);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      _weiAmount,
      tokenAmount
    );

    _updatePurchasingState(_beneficiary, _weiAmount);
    _postValidatePurchase(_beneficiary, _weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _usdTokenAmount Amount of dollars to purchase tokens with
   * @param _tokenAmount Amount of tokens user wants to purchase
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _usdTokenAmount,
    uint256 _tokenAmount

  )
    internal
  {
    // Making the user pay
    require(usdToken.transferFrom(msg.sender, wallet, _usdTokenAmount), "Deposit failed");

    // Increasing purchased tokens
    tokensPurchased[msg.sender] += _tokenAmount;

    // Delivering the tokens
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount/tokenPrice; // Amount in wei
  }

  function addWLAddress(address _addr) onlyAdmin external {
    isWhitelisted[_addr] = true;
  }

  function makePublic() onlyAdmin external {
    tokenPrice = 16;
    maximumPurchase = 75000000000000000000;
    isPublic = true;
  }

   /**
   * @dev Ends the whitelisted Crowdsale.
   */ 
  function endCrodwsale() onlyAdmin external {
    token.transfer(admin, token.balanceOf(address(this)));

    selfdestruct(payable(admin));
}

}