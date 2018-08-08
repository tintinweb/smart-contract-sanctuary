pragma solidity ^0.4.24;




/**
 * @title ERC20 interface + Mint function
 * 
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function mint(address _to, uint256 _amount) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}






/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function uint2str(uint i) internal pure returns (string){
      if (i == 0) return "0";
      uint j = i;
      uint length;
      while (j != 0){
          length++;
          j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint k = length - 1;
      while (i != 0){
          bstr[k--] = byte(48 + i % 10);
          i /= 10;
      }
      return string(bstr);
  }

 

  
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public adminOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    adminOwner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    require(msg.sender == adminOwner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner or admin.
   */
  modifier onlyOwnerOrAdmin() {
    require(msg.sender == adminOwner || msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current adminOwner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferAdminOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(adminOwner, newOwner);
    adminOwner = newOwner;
  }

}




/**
 * @title simpleCrowdsale
 * Contract is payable 
 * Has no allocation.
 *
 *
 */
contract simpleCrowdsale is Ownable {
  using SafeMath for uint256;

  uint256 private constant decimalFactor = 10**uint256(18);

  event FundTransfer(address backer, uint256 amount, bool isContribution);
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount  );
   
  //Is active
  bool internal crowdsaleActive = true;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many weis one token costs 
  uint256 public rate;

  // Miniemum weis one token costs 
  uint256 public minRate; 

  // Miniemum buy in weis 
  uint256 public minBuyAmount; 

  // Amount of tokens Raised
  uint256 public tokensRaised = 0;

  // Amount of wei raised
  uint256 public weiRaised;

  // Max token amout
  uint256 public hardCap = 0;

  
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
  
  //Whitelist
  mapping(address => bool) public whitelist;
  
 
  constructor(uint256 _startTime, uint256 _endTime, address _wallet, ERC20 _token) public {
     
    require(_wallet != address(0));
    require(_token != address(0));

    require(_startTime >= now);
    require(_endTime >= _startTime);

    startTime   = _startTime;
    endTime     = _endTime;
  
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Locked Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () public payable  {

    //Check if msg sender value is more then 0
    require( msg.value > 0 );

    //Validate crowdSale
    require(_validCrowdsale());

    //Validate whitelisted
    require(isWhitelisted(msg.sender));

    // wei sent
    uint256 _weiAmount = msg.value;

    // Miniemum buy in weis 
    require(_weiAmount>minBuyAmount);

    // calculate token amount to be created after rate update
    uint256 _tokenAmount = _calculateTokens(_weiAmount);

    //Check hardCap 
    require(_validateHardCap(_tokenAmount));

    //Mint tokens and transfer tokens to buyer
    require(token.mint(msg.sender, _tokenAmount));

    //Update state
    tokensRaised = tokensRaised.add(_tokenAmount);

    //Update state
    weiRaised = weiRaised.add(_weiAmount);

    emit TokenPurchase(msg.sender, _tokenAmount , _weiAmount);

    //Transfer found to wallet
    _forwardFunds();

 
  }

 


  // send ether to the fund collection wallet
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function _validCrowdsale() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    
    return withinPeriod && crowdsaleActive;
  }
 

  /**
   * @dev Update current rate
   * @param _rate How many weis one token costs
   * We need to be able to update the rate as the eth rate changes
   */ 
  function setRate(uint256 _rate) onlyOwnerOrAdmin public{
    require(_rate > 0);
    require(_rate > minRate);
    rate = _rate;
  }


  /**
   * @dev Update minBuyAmount
   * @param _value How many weis minimum buy in
   * 
   */ 
  function setMinBuyAmount(uint256 _value) onlyOwnerOrAdmin public{
    require(_value >= 0);
    minBuyAmount = _value;
  }


  // @return false is hardcap is reached
  function _validateHardCap(uint256 _tokenAmount) internal view returns (bool) {
      if(tokensRaised.add(_tokenAmount)>hardCap){
        //If tokensSold is more then hardCap return false
        return false;
      }else{
        //If tokensSold is less then hardCap return true
        return true;
      }
  }


  function _calculateTokens(uint256 _wei) internal view returns (uint256) {
    uint256 _multiplier = 10 ** 18;
    return _wei.mul(_multiplier).div(rate);
  }


  function isCrowdsaleActive() public view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;     
    return withinPeriod && crowdsaleActive;
  }


  function crowdsaleStatus() public view returns (string) {
    bool withinPeriod = now >= startTime && now <= endTime;
    if(!withinPeriod){
      return  "Sale is not within period";
    } 
    if(!crowdsaleActive){
      return  "Sale is inactive";
    }
    return "Sale is active";
  }
 



  function addToWhitelist(address _buyer) onlyOwnerOrAdmin public{
    require(_buyer != 0x0);     
    whitelist[_buyer] = true;
  }
  

  function addManyToWhitelist(address[] _beneficiaries) onlyOwnerOrAdmin public{
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }


  function removeFromWhitelist(address _buyer) onlyOwnerOrAdmin public{
    whitelist[_buyer] = false;
  }


  // @return true if buyer is whitelisted
  function isWhitelisted(address _buyer) public view returns (bool) {
      return whitelist[_buyer];
  }


  // Return token sent here by mistake
  function returnTokens() public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(token.transfer(owner, balance));
  }

  // Owner can transfer other tokens that are sent here by mistake
  function refundOtherTokens(address _recipient, ERC20 _token) public onlyOwner {
    require(_token != token);
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }


}
 

 
/**
 * @title EDCrowdsale
 * @dev Contract is payable and owner or admin can allocate tokens.
 * Only owner or admin can allocate tokens. Tokens will be minted to this contract for allocation.
 * Tokens will be released after release date / time. 
 * User will use colletTokens to recive tokens to wallet. 
 *
*/
contract EDCrowdsale is simpleCrowdsale {
  constructor(   
    uint256 _startTime, 
    uint256 _endTime,  
    address _wallet, 
    ERC20 _token
  ) public simpleCrowdsale( _startTime, _endTime,  _wallet, _token) {

    // Initial rate
    //What one token cost in ether
    rate = 305000000000000;   

    // Initial minimum rate
    // rate can&#39;t be set below this
    minRate = 200000000000000;  

    // HardCap 33,000,000
    hardCap = 33000000 * (10**uint256(18)); 

  }
}