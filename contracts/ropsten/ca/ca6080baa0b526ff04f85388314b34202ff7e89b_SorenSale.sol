pragma solidity ^0.4.18;

/**
 * SOREN Pre Sale
 * @desc Contract is payable and owner or admin can allocate tokens.
 * Only owner or admin can allocate tokens. Tokens will be minted to this contract for allocation.
 * Tokens will be released after release date / time. 
 * User will use colletTokens to recive tokens to wallet. 
 *
*/



/**
 * @title ERC20 + Mint function
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
 * @title lockedCrowdsale
 * 
 *
 *
 *
 */
contract lockedCrowdsale is Ownable {
  using SafeMath for uint256;

  uint256 private constant decimalFactor = 10**uint256(18);

  event FundsBooked(address backer, uint256 amount, bool isContribution);
  event FundTransfer(address backer, uint256 amount, bool isContribution);
  event LogTokenClaimed(address indexed _recipient, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);
  event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogOwnerAllocation(address indexed _recipient, uint256 _totalAllocated);
   
  //Is active
  bool internal crowdsaleActive = true;

  // Amount of tokens claimed
  uint256 public grandTotalClaimed = 0;

  // Buyers total allocation
  mapping (address => uint256) public allocationsTotal;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many weis one token costs 
  uint256 public rate;

  // Miniemum weis one token costs 
  uint256 public minRate; 

  // Amount of tokens Raised
  uint256 public tokensTotal = 0;

  // Max token amout
  uint256 public hardCap = 1000000000 * decimalFactor;

  
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
  uint256 public releaseTime;

  //Buyers
  mapping(address => bool) public buyers;

  //List of all addrees
  address[] private addresses;

  //Whitelist
  mapping(address => bool) public whitelist;
  
 
  constructor(uint256 _releaseTime, uint256 _startTime, uint256 _endTime, address _wallet, ERC20 _token) public {
     
    require(_wallet != address(0));
    require(_token != address(0));

    require(_startTime >= now);
    require(_endTime >= _startTime);

    //_releaseTime must be later then the sales _endTime
    require(_releaseTime >= _endTime);

    startTime = _startTime;
    endTime = _endTime;
    releaseTime = _releaseTime;
     
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
    require(validCrowdsale());

    //Validate whitelisted
    require(isWhitelisted(msg.sender));

    // wei sent
    uint256 _weiAmount = msg.value;

    // calculate token amount to be created after rate update
    uint256 _tokenAmount = calculateTokens(_weiAmount);

    //Check hardCap 
    require(validateHarCap(_tokenAmount));

    //Mint tokens and transfer tokens to this contract. Then allocation the tokens to buyer
    require(token.mint(this, _tokenAmount));

    //Allocate tokens
    _setAllocation(msg.sender, _tokenAmount);

    //Increese token amount
    tokensTotal = tokensTotal.add(_tokenAmount);

    //Funds logged function
    emit FundsBooked(msg.sender, _weiAmount, true);

    //Transfer found to wallet
    forwardFunds();

 
  }

  function testAmount(uint256 _weiAmount) public view returns (uint256) {
    return calculateTokens(_weiAmount);
  }

  function testVali(address _recipient, uint256 _weiAmount) public view returns (bool) {
       //Check if msg sender value is more then 0
    require(_weiAmount > 0 );

    //Validate crowdSale
    require(validCrowdsale());

    //Validate whitelisted
    require(isWhitelisted(_recipient));

    // calculate token amount to be created after rate update
    uint256 _tokenAmount = calculateTokens(_weiAmount);

    //Check hardCap 
    require(validateHarCap(_tokenAmount));

    return true;
  }



  // @return true if buyer is whitelisted
  function isBuyer(address _buyer) public constant returns (bool) {
      return buyers[_buyer];
  }


  /**
    * @dev Set allocation 
    * @param _recipient 
    * @param _tokenAmount Amount Allocated tokens + 18 decimals
    */
  function setAllocation (address _recipient, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
      require(_tokenAmount > 0);      
      require(_recipient != address(0)); 

      //Validate crowdSale
      require(validCrowdsale());

      //Validate whitelisted
      require(isWhitelisted(_recipient)); 

      //Check hardCap 
      require(validateHarCap(_tokenAmount));

      //Mint tokens and transfer tokens to this contract. Then allocation the tokens to buyer
      require(token.mint(this, _tokenAmount));

      //Allocate tokens
      _setAllocation(_recipient, _tokenAmount);    

      //Increese token amount
      tokensTotal = tokensTotal.add(_tokenAmount);  

      //Logg Allocation
      emit LogOwnerAllocation(_recipient, _tokenAmount);
  }


 /**
   * @dev Set internal allocation 
   *  _buyer The adress of the buyer
   *  _tokenAmount Amount Allocated tokens + 18 decimals
   */
  function _setAllocation (address _buyer, uint256 _tokenAmount) internal{

      if(!isBuyer(_buyer)){
        //Add buyer to buyers list 
        buyers[_buyer] = true;

        //Add _buyer to addresses list
        addresses.push(_buyer);

        //Init buyer
        allocationsTotal[_buyer] = 0;

      }     

      //Add tokens to buyers allocation
      allocationsTotal[_buyer]  = allocationsTotal[_buyer].add(_tokenAmount); 

      //Logg Allocation
      emit LogNewAllocation(_buyer, _tokenAmount);

  }


  /**
    * @dev Return address available allocation
    * @param _recipient 
    */
  function checkAvailableTokens (address _recipient) public view returns (uint256) {
    //Check have bought tokens
    require(isBuyer(_recipient));

    uint256 availableTokens = 0;
    
    if(now >= releaseTime){
      availableTokens = allocationsTotal[_recipient];
    } 

    return availableTokens;
  }

  /**
    * @dev Transfer a recipients available allocation to their address
    * @param _recipients Array of addresses to withdraw tokens for
    */
  function distributeManyTokens(address[] _recipients) onlyOwnerOrAdmin public {
    for (uint256 i = 0; i < _recipients.length; i++) {
      distributeTokens( _recipients[i]);
    }
  }

  /**
    * @dev Transfer a recipients available allocation to their address
    * @param _recipient The address to withdraw tokens for
    */
  function distributeTokens(address _recipient) onlyOwnerOrAdmin public {
    require(now >= releaseTime);
    uint256 availableTokens = 0;
    
    if(now >= releaseTime){
      availableTokens = allocationsTotal[_recipient];
    } 

    require(availableTokens>0);    
    require(token.balanceOf(this)>=availableTokens);
    require(token.transfer(_recipient, availableTokens));

    //Add claimed tokens to grandTotalClaimed
    grandTotalClaimed = grandTotalClaimed.add(availableTokens);

    emit LogTokenClaimed(_recipient, availableTokens, allocationsTotal[_recipient], grandTotalClaimed);
  }



  // send ether to the fund collection wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validCrowdsale() internal view returns (bool) {
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
   * @dev Get current rate
   * 
   */ 
  function getRate() public view returns (uint256) {
    return rate;
  } 


  // @return false is hardcap is reached
  function validateHarCap(uint256 _tokenAmount) internal view returns (bool) {
      if(tokensTotal.add(_tokenAmount)>hardCap){
        //If tokensSold is more then hardCap return false
        return false;
      }else{
        //If tokensSold is less then hardCap return true
        return true;
      }
  }


  function calculateTokens(uint256 _wei) internal view returns (uint256) {
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
 
  
  function getListOfAddresses() onlyOwnerOrAdmin public view returns (address[]) {    
    return addresses;
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


}






contract SorenSale is lockedCrowdsale {
  constructor(uint256 _releaseTime, uint256 _startTime, uint256 _endTime,  address _wallet, ERC20 _token) public lockedCrowdsale(_releaseTime, _startTime, _endTime,  _wallet, _token) {

    // Initial rate
    //What one token cost in ether
    rate = 305000000000000;   

    // Initial minimum rate
    minRate = 297406614323102;   

  }


}