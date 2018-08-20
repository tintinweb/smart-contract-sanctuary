pragma solidity ^0.4.24;



library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
   emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }


}

contract iHOME is Ownable {
  using SafeMath for uint256;
  


  event Transfer(address indexed from,address indexed to,uint256 _tokenId);
  event Approval(address indexed owner,address indexed approved,uint256 _tokenId);
 

  
  string public constant symbol = "iHOME";
  string public constant name = "iHOME Credits";
  uint8 public decimals = 18;
  uint256 public totalSupply = 1000000000000 * 10 ** uint256(decimals);

  
  uint256 public totalSold = 0;
 
  

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

 



  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
 

  function totalTokenSold() public constant returns (uint256 balance) {
    return totalSold;
  }
  
 
  function balanceEth(address _owner) public constant returns (uint256 balance) {
    return _owner.balance;
  }

  function collect(uint256 amount) onlyOwner public{
  msg.sender.transfer(amount);
  }
  
  
 
 
  constructor() public {
      balances[msg.sender] = totalSupply;
      }
 

   function approve(address _spender, uint256 _amount) public returns (bool success) {
       allowed[msg.sender][_spender] = _amount;
    emit   Approval(msg.sender, _spender, _amount);
      return true;
   }

 


  function transfer(address _to, uint256 _value) public returns (bool) {
    totalSold = SafeMath.add(totalSold , _value);
    require(_to != address(0));
    
    require(_value <= balances[msg.sender]);
  
   
    // balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply =  balances[msg.sender];
    // balances[_to] = SafeMath.add(balances[_to] , _value);
    balances[_to] = balances[_to].add(_value);
  
   emit  Transfer(msg.sender, _to, _value);
  
   
    return true;
  }



}