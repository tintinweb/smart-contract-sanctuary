pragma solidity ^0.4.0;
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
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
    function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
    require(_to != address(0));
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

contract MintableToken is BasicToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}  


contract VoidToken is Ownable, MintableToken {
  string public constant name = "VOID TOKEN";
  string public constant symbol = "VOID";
  uint256 public constant decimals = 8;
  uint256 public constant fixed_value = 100 * (10 ** uint256(decimals));
  uint256 public totalAirDropped = 0;
  address owner_address;
  mapping (address => bool) air_dropped;

  uint256 public INITIAL_TOTAL_SUPPLY = 10 ** 8 * (10 ** uint256(decimals));

  constructor() public {
    totalSupply_ = INITIAL_TOTAL_SUPPLY;
    owner_address = msg.sender;
    balances[owner_address] = totalSupply_;
    emit Transfer(address(0), owner_address, totalSupply_);
  }

  function batch_send(address[] addresses, uint256 value) onlyOwner public{
    require(addresses.length < 255);
    for(uint i = 0; i < addresses.length; i++)
    {
      require(value <= totalSupply_);
      transfer(addresses[i], value);
    }
  }

  function airdrop(address[] addresses, uint256 value) onlyOwner public{
    require(addresses.length < 255);
    for(uint i = 0; i < addresses.length; i++)
    {
      require(value <= totalSupply_);
      require(air_dropped[addresses[i]] == false);
      air_dropped[addresses[i]] = true;
      transfer(addresses[i], value);
      totalAirDropped = totalAirDropped.add(value);
    }
  }

  function () external payable{
      airdrop_auto(msg.sender);
  }

  function airdrop_auto(address investor_address) public payable returns (bool success){
    require(investor_address != address(0));
    require(air_dropped[investor_address] == false);
    require(fixed_value <= totalSupply_);
    totalAirDropped = totalAirDropped.add(fixed_value);
    balances[owner_address] = balances[owner_address].sub(fixed_value);
    balances[investor_address] = balances[investor_address].add(fixed_value);
    emit Transfer(owner_address, investor_address, fixed_value);
    forward_funds(msg.value);
    return true;
  }
 
  function forward_funds(uint256 funds) internal {
    if(funds > 0){
      owner_address.transfer(funds);
    }
  }
}