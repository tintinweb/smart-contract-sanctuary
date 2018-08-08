pragma solidity ^0.4.24;



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
 * @title AirDrop
 * @notice Contract is not payable.
 * Owner or admin can allocate tokens.
 * Tokens will be released direct. 
 *
 *
 */
contract AirDrop is OwnableWithAdmin {
  using SafeMath for uint256;

  uint256 private constant DECIMALFACTOR = 10**uint256(18);


  event FundsBooked(address backer, uint256 amount, bool isContribution);
  event LogTokenClaimed(address indexed _recipient, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);
  event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogRemoveAllocation(address indexed _recipient, uint256 _tokenAmountRemoved);
  event LogOwnerSetAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogTest();
   

  // Amount of tokens claimed
  uint256 public grandTotalClaimed = 0;

  // The token being sold
  ERC20 public token;

  // Amount of tokens Raised
  uint256 public tokensTotal = 0;

  // Max token amount
  uint256 public hardCap = 0;
  


  // Buyers total allocation
  mapping (address => uint256) public allocationsTotal;

  // User total Claimed
  mapping (address => uint256) public totalClaimed;


  //Buyers
  mapping(address => bool) public buyers;

  //Buyers who received all there tokens
  mapping(address => bool) public buyersReceived;

  //List of all addresses
  address[] public addresses;
  
 
  constructor(ERC20 _token) public {
     
    require(_token != address(0));

    token = _token;
  }

  
  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () public {
    //Not payable
  }

  /**
    * @dev Set many allocations buy admin
    * @param _recipients Array of wallets
    * @param _tokenAmount Amount Allocated tokens + 18 decimals
    */
  function setManyAllocations (address[] _recipients, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
    for (uint256 i = 0; i < _recipients.length; i++) {
      setAllocation(_recipients[i],_tokenAmount);
    }    
  }


  /**
    * @dev Set allocation buy admin
    * @param _recipient Users wallet
    * @param _tokenAmount Amount Allocated tokens + 18 decimals
    */
  function setAllocation (address _recipient, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
      require(_tokenAmount > 0);      
      require(_recipient != address(0)); 

      //Check hardCap 
      require(_validateHardCap(_tokenAmount));

      //Allocate tokens
      _setAllocation(_recipient, _tokenAmount);    

      //Increese token amount
      tokensTotal = tokensTotal.add(_tokenAmount);  

      //Logg Allocation
      emit LogOwnerSetAllocation(_recipient, _tokenAmount);
  }

  /**
    * @dev Remove allocation 
    * @param _recipient Users wallet
    *  
    */
  function removeAllocation (address _recipient) onlyOwner  public{         
      require(_recipient != address(0)); 
      require(totalClaimed[_recipient] == 0); //Check if user claimed tokens


      //_recipient total amount
      uint256 _tokenAmountRemoved = allocationsTotal[_recipient];

      //Decreese token amount
      tokensTotal = tokensTotal.sub(_tokenAmountRemoved);

      //Reset allocation
      allocationsTotal[_recipient] = 0;
       
      //Set buyer to false
      buyers[_recipient] = false;

      emit LogRemoveAllocation(_recipient, _tokenAmountRemoved);
  }


 /**
   * @dev Set internal allocation 
   *  _buyer The adress of the buyer
   *  _tokenAmount Amount Allocated tokens + 18 decimals
   */
  function _setAllocation (address _buyer, uint256 _tokenAmount) internal{

      if(!buyers[_buyer]){
        //Add buyer to buyers list 
        buyers[_buyer] = true;

        //Remove from list 
        buyersReceived[_buyer] = false;

        //Add _buyer to addresses list
        addresses.push(_buyer);

        //Reset buyer allocation
        allocationsTotal[_buyer] = 0;


      }  

      //Add tokens to buyers allocation
      allocationsTotal[_buyer]  = allocationsTotal[_buyer].add(_tokenAmount); 


      //Logg Allocation
      emit LogNewAllocation(_buyer, _tokenAmount);

  }


  /**
    * @dev Return address available allocation
    * @param _recipient which address is applicable
    */
  function checkAvailableTokens (address _recipient) public view returns (uint256) {
    //Check if user have bought tokens
    require(buyers[_recipient]); 

    return allocationsTotal[_recipient];
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
    
    //Check have bought tokens
    require(buyers[_recipient]);

    //If all tokens are received, add _recipient to buyersReceived
    //To prevent the loop to fail if user allready used the withdrawTokens 
    buyersReceived[_recipient] = true;

    uint256 _availableTokens = allocationsTotal[_recipient];
     

    //Check if contract has tokens
    require(token.balanceOf(this)>=_availableTokens);

    //Transfer tokens
    require(token.transfer(_recipient, _availableTokens));

    //Add claimed tokens to totalClaimed
    totalClaimed[_recipient] = totalClaimed[_recipient].add(_availableTokens);

    //Add claimed tokens to grandTotalClaimed
    grandTotalClaimed = grandTotalClaimed.add(_availableTokens);


    //Reset allocation
    allocationsTotal[_recipient] = 0;


    emit LogTokenClaimed(_recipient, _availableTokens, allocationsTotal[_recipient], grandTotalClaimed);

    

  }



  function _validateHardCap(uint256 _tokenAmount) internal view returns (bool) {
      return tokensTotal.add(_tokenAmount) <= hardCap;
  }


  function getListOfAddresses() public onlyOwnerOrAdmin view returns (address[]) {    
    return addresses;
  }


  // Allow transfer of tokens back to owner or reserve wallet
  function returnTokens() public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(token.transfer(owner, balance));
  }

  // Owner can transfer tokens that are sent here by mistake
  function refundTokens(address _recipient, ERC20 _token) public onlyOwner {
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }


}



/**
 * @title BYTMAirDrop
 *  
 *
*/
contract BYTMAirDrop is AirDrop {
  constructor(   
    ERC20 _token
  ) public AirDrop(_token) {

    // 40,000,000 tokens
    hardCap = 40000000 * (10**uint256(18)); 

  }
}