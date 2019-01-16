pragma solidity ^0.4.24;

// File: contracts/ERC20-token.sol

/**
 * @title ERC20 interface 
 * 
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/OwnableWithAdmin.sol

/**
 * @title OwnableWithAdmin 
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableWithAdmin {
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

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
      // benefit is lost if &#39;b&#39; is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
      if (a == 0) {
          return 0;
      }

      uint256 c = a * b;
      require(c / a == b);

      return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // Solidity only automatically asserts when dividing by 0
      require(b > 0);
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

      return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a);
      uint256 c = a - b;

      return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a);

      return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b != 0);
      return a % b;
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

// File: contracts/LockedCrowdsale.sol

/**
 * @title LockedCrowdsale
 * @notice Contract is payable and owner or admin can allocate tokens.
 * Tokens will be released in 10 steps 
 *
 *
 *
 */
contract LockedCrowdsale is OwnableWithAdmin {
  using SafeMath for uint256;

  uint256 private constant DECIMALFACTOR = 10**uint256(18);

  event FundsBooked(address backer, uint256 amount, bool isContribution);
  event LogTokenClaimed(address indexed _recipient, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);
  event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogOwnerAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogRemoveAllocation(address indexed _recipient, uint256 _tokenAmountRemoved);
   

  // Amount of tokens claimed
  uint256 public grandTotalClaimed = 0;


  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many weis one token costs 
  uint256 public rate;

  // Minimum weis one token costs 
  uint256 public minRate; 

  // Minimum buy in weis 
  uint256 public minWeiAmount = 50000000000000000; 

  // Amount of tokens Raised
  uint256 public tokensTotal = 0;

  // Max token amount
  uint256 public hardCap = 0;

  
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  uint256 public oneMonth = 100; // 2629743;
  
  // Buyers step allocation amount
  mapping (address => uint256) public stepAmount;

  // Buyers total allocation
  mapping (address => uint256) public allocationsTotal;

  // User total Claimed
  mapping (address => uint256) public totalClaimed;

  // Buyers
  mapping(address => bool) private buyers;


  // List of all addresses
  address[] private addresses;


  // Whitelist
  mapping(address => bool) private whitelist;
  
 
  constructor(uint256 _startTime, uint256 _endTime, address _wallet, ERC20 _token) public {
     
    require(_wallet != address(0));
    require(_token != address(0));

   
    require(_endTime > _startTime);

    startTime   = _startTime;
    endTime     = _endTime;

    wallet = _wallet;
    token = _token;

  }

  // -----------------------------------------
  // External interface
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

    //Wei sent
    uint256 _weiAmount = msg.value;

    //Minimum buy in wei 
    require(_weiAmount>minWeiAmount);

    //Calculate token amount to be allocated
    uint256 _tokenAmount = _calculateTokens(_weiAmount);

    //Check hardCap 
    require(_validateHardCap(_tokenAmount));

    //Allocate tokens
    _setAllocation(msg.sender, _tokenAmount);

    //Increese token amount
    tokensTotal = tokensTotal.add(_tokenAmount);

    //Funds log function
    emit FundsBooked(msg.sender, _weiAmount, true);

    //Transfer funds to wallet
    _forwardFunds();

 
  }


  /**
    * @dev Set allocation buy admin
    * @param _recipient Buyers address
    * @param _tokenAmount Token amount
    */
  function setAllocation(address _recipient, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
      require(_tokenAmount > 0);      
      require(_recipient != address(0)); 

      //Validate crowdSale
      require(_validCrowdsale());

      //Validate whitelisted
      require(isWhitelisted(_recipient)); 

      //Check hardCap 
      require(_validateHardCap(_tokenAmount));

      //Allocate tokens
      _setAllocation(_recipient, _tokenAmount);    

      //Increese token amount
      tokensTotal = tokensTotal.add(_tokenAmount);  

      //Logg Allocation
      emit LogOwnerAllocation(_recipient, _tokenAmount);
  }

  /**
    * @dev Remove allocation 
    * @param _recipient 
    *  
    */
  function removeAllocation(address _recipient) onlyOwner  public{         
      require(_recipient != address(0)); 
      require(totalClaimed[_recipient] == 0); //Check if user claimed tokens


      //_recipient total amount
      uint256 _tokenAmountRemoved = allocationsTotal[_recipient];

      //Decreese token amount
      tokensTotal = tokensTotal.sub(_tokenAmountRemoved);

      //Reset allocations
      allocationsTotal[_recipient]  = 0; // Remove 

      //Set buyer to false
      buyers[_recipient] = false;


      emit LogRemoveAllocation(_recipient, _tokenAmountRemoved);
  }


 /**
   * @dev Set internal allocation and transfer first month
   *  _buyer The adress of the buyer
   *  _tokenAmount Amount Allocated tokens + 18 decimals
   */
  function _setAllocation (address _buyer, uint256 _tokenAmount) internal{

      if(!buyers[_buyer]){
        
        //Add buyer to buyers list 
        buyers[_buyer] = true;

        //Add _buyer to addresses list
        addresses.push(_buyer);

        //Reset buyer allocation
        allocationsTotal[_buyer] = 0;

      }  

      //Add tokens to buyers allocation
      allocationsTotal[_buyer]  = allocationsTotal[_buyer].add(_tokenAmount);

      //Set stepAmount - 10 months
      stepAmount[_buyer]  = allocationsTotal[_buyer].div(10);


      //Logg Allocation
      emit LogNewAllocation(_buyer, _tokenAmount);

      
      //Transfer first month
      uint256 _availableTokens = stepAmount[_buyer];

      //Check if contract has tokens
      require(token.balanceOf(this)>=_availableTokens);

      //Transfer tokens
      require(token.transfer(_buyer, _availableTokens));

      //Add claimed tokens to user totalClaimed
      totalClaimed[_buyer] = totalClaimed[_buyer].add(_availableTokens);

      //Add claimed tokens to grandTotalClaimed
      grandTotalClaimed = grandTotalClaimed.add(_availableTokens);

      emit LogTokenClaimed(_buyer, _availableTokens, allocationsTotal[_buyer], grandTotalClaimed);


  }


  /**
    * @dev Return address available allocation after x months
    * @param _recipient which address is applicable
    * @param _months after x months user will get a tokens
    */
  function checkAvailableTokens (address _recipient, uint256 _months) public view returns (uint256) {
    //Check if user have bought tokens
    require(buyers[_recipient]);


    //Only 10 months
    require(_months <= 10);

    //Check if all tokens are claimed 
    require(totalClaimed[_recipient] < allocationsTotal[_recipient]);

    //Set available tokens
    //Multiple amount through month gone, remove already claimed tokens
    uint256 _availableTokens = _months.mul(stepAmount[_recipient]).sub(totalClaimed[_recipient]);


    
    return _availableTokens;
  }

 
 


  /**
    * @notice Withdraw available tokens
    *
    */
  function withdrawTokens() public {
    distributeTokens(msg.sender);
  }

  /**
    * @dev Transfer a recipients available allocation to _recipient
    *
    */
  function distributeTokens(address _recipient) public {

    //Check date
    require(now >= endTime);
    
    //Check if _recipient bought tokens
    require( buyers[_recipient] );

   
    //How many months have gone after endTime
    uint256 _months = now.sub(endTime).div(oneMonth);

    //Only 10 months
    require(_months <= 10);

    //Check if all tokens are claimed 
    require(totalClaimed[_recipient] < allocationsTotal[_recipient]);


    //Set available tokens
    //Multiple amount through month gone, remove already claimed tokens
    uint256 _availableTokens = _months.mul(stepAmount[_recipient]).sub(totalClaimed[_recipient]);
     

    require(_availableTokens>0);    

    //Check if contract has tokens
    require(token.balanceOf(this)>=_availableTokens);

    //Transfer tokens
    require(token.transfer(_recipient, _availableTokens));

    //Add claimed tokens to user totalClaimed
    totalClaimed[_recipient] = totalClaimed[_recipient].add(_availableTokens);

    //Add claimed tokens to grandTotalClaimed
    grandTotalClaimed = grandTotalClaimed.add(_availableTokens);

    emit LogTokenClaimed(_recipient, _availableTokens, allocationsTotal[_recipient], grandTotalClaimed);


  }


  // send ether to the fund collection wallet
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function _validCrowdsale() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }
  

  function _validateHardCap(uint256 _tokenAmount) internal view returns (bool) {
      return tokensTotal.add(_tokenAmount) <= hardCap;
  }


  function _calculateTokens(uint256 _wei) internal view returns (uint256) {
    return _wei.mul(DECIMALFACTOR).div(rate);
  }


  function isCrowdsaleActive() public view returns (bool) {    
    return _validCrowdsale();
  }


  /**
   * @dev Update current rate
   * @param _rate How many weis one token costs
   * We need to be able to update the rate as the eth rate changes
   */ 
  function setRate(uint256 _rate) onlyOwnerOrAdmin public{
    require(_rate > minRate);
    rate = _rate;
  }


  function addToWhitelist(address _buyer) onlyOwnerOrAdmin public{
    require(_buyer != 0x0);     
    whitelist[_buyer] = true;
  }
  

  function addManyToWhitelist(address[] _beneficiaries) onlyOwnerOrAdmin public{
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      if(_beneficiaries[i] != 0x0){
        whitelist[_beneficiaries[i]] = true;
      }
    }
  }


  function removeFromWhitelist(address _buyer) onlyOwnerOrAdmin public{
    whitelist[_buyer] = false;
  }


  // @return true if buyer is whitelisted
  function isWhitelisted(address _buyer) public view returns (bool) {
      return whitelist[_buyer];
  }

  function getListOfAddresses() onlyOwnerOrAdmin public  view returns (address[]) {    
    return addresses;
  }


  // Owner can transfer tokens that are sent here by mistake
  function refundTokens(address _recipient, ERC20 _token) public onlyOwner {
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }


}

// File: contracts/ZBX/ZBXCrowdsale.sol

/**
 * @title ZBXCrowdsale
 *  
 *
*/
contract ZBXCrowdsale is LockedCrowdsale {
  constructor(   
    uint256 _startTime, 
    uint256 _endTime,  
    address _wallet, 
    ERC20 _token
  ) public LockedCrowdsale( _startTime, _endTime,  _wallet, _token) {

    // Initial rate
    // What one token cost in wei
    // 0.10 euro
    rate = 1080000000000000;   

    // Safe Initial minimum rate
    // rate can&#39;t be set below this
    // 0.05 euro
    minRate = 540000000000000;  

    // HardCap 80,000,000
    hardCap = 80000000 * (10**uint256(18)); 

    // min buy amount in wei
    // 10 euro
    minWeiAmount = 107950000000000000;

  }
}