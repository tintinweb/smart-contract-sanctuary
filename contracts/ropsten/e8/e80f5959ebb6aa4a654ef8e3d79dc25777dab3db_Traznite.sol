pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See:  tested
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

}

contract Traznite is Ownable{

using SafeMath for uint256;

  // function totalSupply() public view returns (uint256);
  // function balanceOf(address who) public view returns (uint256);
  // function transfer(address to, uint256 value) public payable returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);  

 mapping(address => uint256) balances;

 string public name = "Traznite";
 uint256 totalSupply_;
 uint256 public RATE = 3 * 10 ** 18 wei;
 string public symbol = "TRZN";                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
 uint8 public decimals = 18;
 uint public INITIAL_SUPPLY = 20000000000;
 uint public totalSold_ = 0;

 constructor() public {
   totalSupply_ = INITIAL_SUPPLY;
   balances[msg.sender] = INITIAL_SUPPLY;
 }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }


  function buy(address _address, uint256 _amount) public payable returns (bool) {
    // uint256 _amount = msg.value;
    // uint256 _amount = amount;
    require(_amount > 0);
    require(_address.balance >= _amount);

    // calculation of token
    uint256 quantity = _amount.div(RATE);

    totalSupply_ = totalSupply_.sub(quantity);
    balances[owner] = balances[owner].sub(quantity);
    balances[_address] = balances[_address].add(quantity);
    totalSold_ = totalSold_.add(quantity);
    // _address.balance -= _amount;
    // owner.balance += _amount;
    return true;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public payable returns (bool) {
    require(_to != address(0));
    require(_value <= balances[owner]);
    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
    totalSold_ = totalSold_.add(_value);
    totalSupply_ = totalSupply_.sub(_value);
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

  function balanceEth(address _owner) public view returns (uint256) {
    return _owner.balance;
   }

  function change_rate(uint256 value) onlyOwner public{
    RATE = value*(1*10**18);
  }
}