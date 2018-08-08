pragma solidity ^0.4.22;


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
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
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

}



contract HoldersList is Ownable{
   uint256 public _totalTokens;
   
   struct TokenHolder {
        uint256 balance;
        uint       regTime;
        bool isValue;
    }
    
    mapping(address => TokenHolder) holders;
    address[] public payees;
    
    function changeBalance(address _who, uint _amount)  public onlyOwner {
        
            holders[_who].balance = _amount;
            if (notInArray(_who)){
                payees.push(_who);
                holders[_who].regTime = now;
                holders[_who].isValue = true;
            }
            
        //}
    }
    function notInArray(address _who) internal view returns (bool) {
        if (holders[_who].isValue) {
            return false;
        }
        return true;
    }
    
  /**
   * @dev Defines number of issued tokens. 
   */
  
    function setTotal(uint _amount) public onlyOwner {
      _totalTokens = _amount;
  }
  
  /**
   * @dev Returnes number of issued tokens.
   */
  
   function getTotal() public constant returns (uint)  {
     return  _totalTokens;
  }
  
  /**
   * @dev Returnes holders balance.
   
   */
  function returnBalance (address _who) public constant returns (uint){
      uint _balance;
      
      _balance= holders[_who].balance;
      return _balance;
  }
  
  
  /**
   * @dev Returnes number of holders in array.
   
   */
  function returnPayees () public constant returns (uint){
      uint _ammount;
      
      _ammount= payees.length;
      return _ammount;
  }
  
  
  /**
   * @dev Returnes holders address.
   
   */
  function returnHolder (uint _num) public constant returns (address){
      address _addr;
      
      _addr= payees[_num];
      return _addr;
  }
  
  /**
   * @dev Returnes registration date of holder.
   
   */
  function returnRegDate (address _who) public constant returns (uint){
      uint _redData;
      
      _redData= holders[_who].regTime;
      return _redData;
  }
    
}



contract Dividend is Ownable   {
  using SafeMath for uint256;  
  //address multisig;
  uint _totalDivid=0;
  uint _newDivid=0;
  uint public _totalTokens;
  uint pointMultiplier = 10e18;
  HoldersList list;
  bool public PaymentFinished = false;
  
 
  
 
 address[] payees;
 
 struct ETHHolder {
        uint256 balance;
        uint       balanceUpdateTime;
        uint       rewardWithdrawTime;
 }
 mapping(address => ETHHolder) eholders;
 
   function returnMyEthBalance (address _who) public constant returns (uint){
      //require(msg.sender == _who);
      uint _eBalance;
      
      _eBalance= eholders[_who].balance;
      return _eBalance;
  }
  
  
  function returnTotalDividend () public constant returns (uint){
      return _totalDivid;
  }
  
  
  function changeEthBalance(address _who, uint256 _amount) internal {
    //require(_who != address(0));
    //require(_amount > 0);
    eholders[_who].balanceUpdateTime = now;
    eholders[_who].balance += _amount;

  }
  
   /**
   * @dev Allows the owner to set the List of token holders.
   * @param _holdersList the List address
   */
  function setHoldersList(address _holdersList) public onlyOwner {
    list = HoldersList(_holdersList);
  }
  
  
  function Withdraw() public returns (bool){
    uint _eBalance;
    address _who;
    _who = msg.sender;
    _eBalance= eholders[_who].balance;
    require(_eBalance>0);
    eholders[_who].balance = 0;
    eholders[_who].rewardWithdrawTime = now;
    _who.transfer(_eBalance);
    return true;
    
   
  }
  
  /**
   * @dev Function to stop payments.
   * @return True if the operation was successful.
   */
  function finishDividend() onlyOwner public returns (bool) {
    PaymentFinished = true;
    return true;
  }
  
  function() external payable {
     
     require(PaymentFinished==false);
     
     _newDivid= msg.value;
     _totalDivid += _newDivid;
     
     uint _myTokenBalance=0;
     uint _myRegTime;
     uint _myEthShare=0;
     //uint _myTokenPer=0;
     uint256 _length;
     address _addr;
     
     _length=list.returnPayees();
     _totalTokens=list.getTotal();
     
     for (uint256 i = 0; i < _length; i++) {
        _addr =list.returnHolder(i);
        _myTokenBalance=list.returnBalance(_addr);
        _myRegTime=list.returnRegDate(_addr);
        _myEthShare=_myTokenBalance.mul(_newDivid).div(_totalTokens);
          changeEthBalance(_addr, _myEthShare);
        }
    
  }
 
}