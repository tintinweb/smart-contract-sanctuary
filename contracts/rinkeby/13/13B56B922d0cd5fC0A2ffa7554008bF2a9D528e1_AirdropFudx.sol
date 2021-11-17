// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./FUDXToken.sol";



contract AirdropFudx is FUDX  {
    
    /* User registers with telegram handle and mobile no (optional)
    Telegram group will brodcast airdrop date and a 4 digit code applicable for a day.
    users will run claimAirdrop fn to claim tokens.
    Tokens will remain with admin who will approve contract to transferFrom 
     
     */
     // The token being sold
    IERC20 private token;

    // User registration
  //   address payable admin;
     uint256 public openingTime;
     uint256 public closingTime;

     modifier onlyWhileOpen {
      require(block.timestamp >= openingTime && block.timestamp <= closingTime);
      _;
     }
      
     constructor (FUDX _token) {
        //require(_price > 0);
        //require(_openingTime >= block.timestamp);
        //require(_closingTime >= _openingTime);

        (admin) = payable(msg.sender);
        token  = _token;
        openingTime = block.timestamp+1;
        closingTime = openingTime +1000;
        price = 1;
     }
     
     address user;
     
     address[]  registered;
     
     mapping (uint256 => address) registration;
     uint256 public count;
     event Register(address indexed User, uint256 Time);
     
     function register() external {
        require(!_check(), "User already registered");
        require(isOpen,"Registration not open");
        count++;
        registration[count] = msg.sender;
        registered.push(msg.sender);
        emit Register(msg.sender, block.timestamp);
        
     }
     
     function _check() internal returns(bool success) {
        for (uint i = 0; i<registered.length; i++ ) {
            if(registered[i] == msg.sender) {
                return true;
            } else {
            return false;
            }
        }
        
     }
     function _checkClaimed() internal view returns(bool success) {
        for (uint i = 0; i<claimed.length; i++) {
            if(claimed[i] == msg.sender) {
                return true;
            }else {
            return false;
            }
        }
        
     }
     
     bool public isOpen;
     
     
     modifier onlyOwner{
      require (msg.sender == admin, "Only Admin");
      _;
     }
     
     function openClose() external onlyOwner {
         if( isOpen) {
             isOpen = false;
         } else {
             isOpen = true;
         }
     }
     
     uint40 code;
     function setCode(uint40 _code) external onlyOwner {
         code = _code;
     }
     
     uint256 tokenAmount;
     function setTokenAmount(uint256 _tokenamount) external onlyOwner {
         tokenAmount = _tokenamount;
     }
     
     function setApprove() public onlyOwner returns(bool success) {
         uint256 xamount = count * tokenAmount;
         require(token.balanceOf(address(this))>= xamount, "Not enough balance in contract");
         return true;
     }
     
     address[] claimed;
     function claimAirdrop(uint40 _code) external returns(bool success) {
         require(!_checkClaimed(),"Already claimed tokens");
         require(isOpen, "Airdrop claims not yet open");
         require(code == _code, "Code Incorrect" );
         
         token.transfer( msg.sender, tokenAmount);    
         claimed.push(msg.sender);
         return true;
         
     }
    
    /**
     *CROWSALE. 
     */

    // How many token units a buyer gets per wei
  uint256 public rate;
  uint256 public price;
  

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    uint256 value,
    uint256 amount
  );

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  fallback () external payable {
    
  }
  receive () external payable {
      
  }
  
  function changeTimes(uint256 _openingTime, uint256 _closingTime) external {
      require( _openingTime<_closingTime, "Opening time must be lower than closing time");
      openingTime = _openingTime;
      closingTime = _closingTime;
  }
  
  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

  /**
  if I want to issue "1 TKN for every Rupee (INR) in Ether", we would calculate it as follows:

  assume 1 ETH == Rs 250,000

  therefore, 10^18 wei = Rs 250,000

  therefore, 1 INR is 10^18 / 250000 , or 4 * 10^12 wei

  we have a decimals of 2, so we’ll use 10 ^ 2 TKNbits instead of 1 TKN

  therefore, if the participant sends the crowdsale 4 * 10^12 wei we should give them 10 ^ 2 TKNbits

  therefore the rate is 4 * 10^12 wei === 10^2 TKNbits, or 1 wei = 25 / 10^12 TKNbits

  therefore, our rate is 25/10^12
  
  therefore, price = 1/rate === 10^12/25 = 4x10^10.
  
  10^18 / (4x10^10) == 100x10^6/4 = 25000000 tknbits = 250,000 token 
  */

  
  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   */
  function buyTokens() public payable {

    //require( msg.value>=10^12, "Not enough ether sent");

    uint256 weiAmount = msg.value;
    _preValidatePurchase(weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);
    //require( tokens<= token.allowance(admin,address(this)), "Insufficient number of tokens for sale");

    // update state
    weiRaised += (weiAmount);

    _processPurchase( tokens);
    emit TokenPurchase(msg.sender,weiAmount,tokens);

    _updatePurchasingState(weiAmount);

    _forwardFunds();
    _postValidatePurchase( weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(uint256 _weiAmount) internal onlyWhileOpen {
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(uint256 _weiAmount)internal{
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(uint256 _tokenAmount)internal{
    token.transferFrom(admin, msg.sender, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(uint256 _tokenAmount)internal{
    _deliverTokens( _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(uint256 _weiAmount)internal{
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)public view returns (uint256){
    
    return _weiAmount/(price);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    payable(admin).transfer(msg.value);
  }  
  function viewTokenBal() external view returns(uint256 balance) {
      return token.balanceOf(address(this));
  }
}