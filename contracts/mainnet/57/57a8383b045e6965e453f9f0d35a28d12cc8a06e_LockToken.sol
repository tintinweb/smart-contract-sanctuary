pragma solidity ^0.4.25;

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  struct restrict {
        uint amount;
        uint restrictTime;
  } 

  mapping(address => uint256) balances;
  mapping (address => restrict) restricts;

  function getrestrict(address _owner) public view  returns (uint){
      uint restrictAmount = 0;

      if(restricts[_owner].amount != 0){
        if(restricts[_owner].restrictTime <= now){
            uint diffmonth = (now - restricts[_owner].restrictTime) / (10 minutes);
            if(diffmonth < 4){
                diffmonth = 4 - diffmonth;
                restrictAmount = (diffmonth * restricts[_owner].amount)/4;
            }
        }else{
            restrictAmount = restricts[_owner].amount;
        }
      }

      return restrictAmount;
  }

  function getrestrictTime(address _owner) public view returns (uint){
      return restricts[_owner].restrictTime;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
  
    require(_to != address(0));
    
    uint restrictAmount =  getrestrict(msg.sender);
    
    require((_value + restrictAmount) <= balances[msg.sender]);
    
    /* if send address is AB, restrict token */ 
    if(msg.sender == address(0xFA3aA02539d1217fe6Af1599913ddb1A852f1934)){
        require(0 == restricts[_to].amount);
        restricts[_to].restrictTime = now + (10 minutes);
        restricts[_to].amount = _value;
    } else if(msg.sender == address(0xD5345443886e2188e63609E77EA73d1df44Ea4BC)){
        require(0 == restricts[_to].amount);
        restricts[_to].restrictTime = now + (10 minutes);
        restricts[_to].amount = _value;
    } 

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract LockToken is BasicToken {

  string public constant name = "Lock Token";
  string public constant symbol = "LKT";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
  
  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[0xFA3aA02539d1217fe6Af1599913ddb1A852f1934] = 100000000 * (10 ** uint256(decimals));
    balances[0xD5345443886e2188e63609E77EA73d1df44Ea4BC] = 800000000 * (10 ** uint256(decimals));
    balances[0x617eC39184E1527e847449A5d8a252FfD7C29DDf] = 100000000 * (10 ** uint256(decimals));
    
    emit Transfer(msg.sender, 0xFA3aA02539d1217fe6Af1599913ddb1A852f1934, 100000000 * (10 ** uint256(decimals)));
    emit Transfer(msg.sender, 0xD5345443886e2188e63609E77EA73d1df44Ea4BC, 800000000 * (10 ** uint256(decimals)));
    emit Transfer(msg.sender, 0x617eC39184E1527e847449A5d8a252FfD7C29DDf, 100000000 * (10 ** uint256(decimals)));
  }
}