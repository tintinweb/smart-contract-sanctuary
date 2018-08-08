pragma solidity ^0.4.18;
 
//Never Mind :P
/* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




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



contract NVTReceiver {
    function NVTFallback(address _from, uint _value, uint _code);
}

contract BasicToken {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    // SafeMath.sub will throw if there is not enough balance.
    if(!isContract(_to)){
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;}
    else{
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    NVTReceiver receiver = NVTReceiver(_to);
    receiver.NVTFallback(msg.sender, _value, 0);
    Transfer(msg.sender, _to, _value);
        return true;
    }
    
  }
  function transfer(address _to, uint _value, uint _code) public returns (bool) {
      require(isContract(_to));
      require(_value <= balances[msg.sender]);
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      NVTReceiver receiver = NVTReceiver(_to);
      receiver.NVTFallback(msg.sender, _value, _code);
      Transfer(msg.sender, _to, _value);
    
      return true;
    
    }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


function isContract(address _addr) private returns (bool is_contract) {
    uint length;
    assembly {
        //retrieve the size of the code on target address, this needs assembly
        length := extcodesize(_addr)
    }
    return (length>0);
  }


  //function that is called when transaction target is a contract
  //Only used for recycling NVTs
  function transferToContract(address _to, uint _value, uint _code) public returns (bool success) {
    require(isContract(_to));
    require(_value <= balances[msg.sender]);
  
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    NVTReceiver receiver = NVTReceiver(_to);
    receiver.NVTFallback(msg.sender, _value, _code);
    Transfer(msg.sender, _to, _value);
    
    return true;
  }
}






contract NVT is BasicToken, Ownable {

  string public constant name = "NiceVotingToken";
  string public constant symbol = "NVT";
  uint8 public constant decimals = 2;

  uint256 public constant TOTAL_SUPPLY = 100 * 10 ** 10; //10 billion tokens
  uint256 public RELEASE_TIME ;
  uint256 public TOKEN_FOR_SALE = 40 * 10 ** 10;
  uint256 public TOKEN_FOR_TEAM = 10 * 10 ** 10;
  uint256 public TOKEN_FOR_COMUNITY = 20 * 10 ** 10;
  uint256 public TOKEN_FOR_INVESTER = 25 * 10 ** 10;


  uint256 public price = 10 ** 12; //1:10000
  bool public halted = false;

  /**
  * @dev Constructor that gives msg.sender all of existing tokens.
  */
  function NVT() public {
    totalSupply_ = 5 * 10 ** 10; // 5 percent for early market promotion
    balances[msg.sender] = 5 * 10 ** 10;
    Transfer(0x0, msg.sender, 5 * 10 ** 10);
    RELEASE_TIME = now;
  }

  //Rember 18 zeros for decimals of eth(wei), and 2 zeros for NVT. So add 16 zeros with * 10 ** 16
  //price can only go higher
  function setPrice(uint _newprice) onlyOwner{
    require(_newprice > price);
    price=_newprice; 
  }

  //Incoming payment for purchase
  function () public payable{
    require(halted == false);
    uint amout = msg.value.div(price);
    require(amout <= TOKEN_FOR_SALE);
    TOKEN_FOR_SALE = TOKEN_FOR_SALE.sub(amout);
    balances[msg.sender] = balanceOf(msg.sender).add(amout);
    totalSupply_=totalSupply_.add(amout);
    Transfer(0x0, msg.sender, amout);
  }

  function getTokenForTeam (address _to, uint _amout) onlyOwner returns(bool){
    TOKEN_FOR_TEAM = TOKEN_FOR_TEAM.sub(_amout);
    totalSupply_=totalSupply_.add(_amout);
    balances[_to] = balanceOf(_to).add(_amout);
    Transfer(0x0, _to, _amout);
    return true;
  }


  function getTokenForInvester (address _to, uint _amout) onlyOwner returns(bool){
    TOKEN_FOR_INVESTER = TOKEN_FOR_INVESTER.sub(_amout);
    totalSupply_=totalSupply_.add(_amout);
    balances[_to] = balanceOf(_to).add(_amout);
    Transfer(0x0, _to, _amout);
    return true;
  }


  function getTokenForCommunity (address _to, uint _amout) onlyOwner{
    require(_amout <= TOKEN_FOR_COMUNITY);
    TOKEN_FOR_COMUNITY = TOKEN_FOR_COMUNITY.sub(_amout);
    totalSupply_=totalSupply_.add(_amout);
    balances[_to] = balanceOf(_to).add(_amout);
    Transfer(0x0, _to, _amout);
  }
  

  function getFunding (address _to, uint _amout) onlyOwner{
    _to.transfer(_amout);
  }


  function getAllFunding() onlyOwner{
    owner.transfer(this.balance);
  }


  /* stop ICO*/
  function halt() onlyOwner{
    halted = true;
  }
  function unhalt() onlyOwner{
    halted = false;
  }



}