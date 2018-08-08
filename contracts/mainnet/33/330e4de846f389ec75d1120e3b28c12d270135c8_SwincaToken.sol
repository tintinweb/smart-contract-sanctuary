pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract SwincaToken is BasicToken {
    
  struct Booking {
      address addr;
      bool isEnabled;
  }

  string public constant name = "Swinca"; // solium-disable-line uppercase
  string public constant symbol = "SWI"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  
  address public owner;
  mapping(address => uint256) balancesBooking;
  address[] balancesBookingArray;

  uint256 public constant INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    owner = msg.sender;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
  
  function book(address _to, uint256 _value) public returns (bool) {
    require(msg.sender == owner);

    if(balancesBooking[_to]==0){
        balancesBookingArray.push(_to);
    }
    balancesBooking[_to] = balancesBooking[_to].add(_value);
    return true;
  }
  
  function distributeBooking(uint256 _n) public returns (bool) {
    require(msg.sender == owner);
    require(_n <= balancesBookingArray.length);
    
    uint256 balancesBookingArrayLength = balancesBookingArray.length;
    for(uint256 i=balancesBookingArray.length;i>=balancesBookingArrayLength-_n+1;i--){
        uint256 j = i-1;
        address _to = balancesBookingArray[j];
        uint256 _value = balancesBooking[_to];
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        balancesBooking[_to] = 0;
        balancesBookingArray.length--;
        emit Transfer(msg.sender, _to, _value);
    }
    return true;
  }
  
  function bookingBalanceOf(address _address) public view returns (uint256) {
    return balancesBooking[_address];
  }
  
  function cancelBooking(address _address) public returns (bool) {
    require(msg.sender == owner);
    
    balancesBooking[_address] = 0;
    return true;
  }

}
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