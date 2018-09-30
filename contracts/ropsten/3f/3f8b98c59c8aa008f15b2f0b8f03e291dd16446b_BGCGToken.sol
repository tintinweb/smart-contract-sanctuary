pragma solidity ^0.4.22;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

// copy from openzeppelin-solidity/contracts/math/SafeMath.sol
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  constructor() public  {
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
  function transferOwnership(address newOwner) public  onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

contract BGCGToken is Pausable {

  using SafeMath for SafeMath;

  string public name = "Blockchain Game Coalition Gold";
  string public symbol = "BGCG";
  uint8 public decimals = 18;
  uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals); // 10 billion tokens

 
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed from, uint256 value);

 mapping (address => bool) public frozenAccount;
 event FrozenFunds(address target, bool frozen);



 constructor() public payable {
    balanceOf[msg.sender] = totalSupply;
    owner = msg.sender;
  }

  //make this contract can receive ETH 
  function() public payable {
       
    }

  
//only owner can withdraw all contract&#39;s ETH  
  function withdraw() public onlyOwner {
      owner.transfer(address(this).balance); 
    }

//msg.sender approve he&#39;s allowance to _spender
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
    require((_value == 0 ) || ( allowance[msg.sender][_spender] == 0  ));
    require(!frozenAccount[msg.sender]);
    require(!frozenAccount[_spender]);
   
    allowance[msg.sender][_spender] = _value;

    emit Approval(msg.sender,_spender, _value);

    return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public whenNotPaused returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
      }
  }

  
  function burn(uint256 _value) public whenNotPaused returns (bool success) {
    require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
    require(totalSupply >= _value );
    require( _value > 0 );

    balanceOf[msg.sender] = SafeMath.sub( balanceOf[msg.sender],_value);            // Subtract from the sender
    totalSupply = SafeMath.sub(totalSupply, _value);                      // Updates totalSupply
    emit Burn(msg.sender, _value);
    return true;
  }

  
  function burnFrom(address _from, uint256 _value) public whenNotPaused returns (bool success) {
    require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
    require(_value <= allowance[_from][msg.sender]);    // Check allowance
    require(totalSupply >= _value );
    require( _value > 0 );

    balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);                         // Subtract from the targeted balance
    allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);             // Subtract from the sender&#39;s allowance
    totalSupply = SafeMath.sub(totalSupply, _value);                              // Update totalSupply
    emit Burn(_from, _value);
    return true;
  }



// Send `_value` tokens to `_to` from msg.sender
 function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require( _value > 0 );
    require(_to != address(0)); 
    require(msg.sender != _to );// forbit to transfer to himself
    require(balanceOf[msg.sender] >= _value);
    require(SafeMath.add(balanceOf[_to],_value) > balanceOf[_to]);  //SafeMath pretect not overflow


    require(!frozenAccount[msg.sender]);
    require(!frozenAccount[_to]);
    
    uint256 previousBalances = balanceOf[msg.sender] + balanceOf[_to]; 

    balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender],_value);
    balanceOf[_to] = SafeMath.add(balanceOf[_to],_value);
    emit Transfer(msg.sender, _to, _value);

    // Asserts are used to use static analysis to find bugs in your code. They should never fail
    assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);

    return true;
  }

//Send `_value` tokens to `_to` from &#39;_from&#39; address,the &#39;_value&#39; can&#39;t larger then allowance by &#39;_from&#39; who set to &#39;msg.sender&#39; 
function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require( _value > 0 );
    require(_to != address(0));
    require(_from != address(0));
  
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    require(SafeMath.add(balanceOf[_to],_value) > balanceOf[_to]); //SafeMath pretect not overflow

    require(!frozenAccount[_from]);
    require(!frozenAccount[_to]);

    balanceOf[_from] = SafeMath.sub(balanceOf[_from],_value);
    balanceOf[_to] = SafeMath.add(balanceOf[_to],_value);
    allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender],_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

//freeze  or unfreeze account
  function freezeAccount(address target, bool freeze) public onlyOwner {
    require(target != address(0));
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
 }



}