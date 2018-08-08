pragma solidity ^0.4.11;

library SafeMath {
   function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }  
  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }  
  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }  
  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }  
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }  
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }  
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}



contract Ownable {
  address public owner;  
  function Ownable() {
    owner = msg.sender;
  }  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }  
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value)  returns(bool);
  function approve(address spender, uint256 value) returns(bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;  mapping(address => uint256) balances;  
  function transfer(address _to, uint256 _value) returns(bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }  
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }


}

contract StandardToken is BasicToken, ERC20 {  
    mapping (address => mapping (address => uint256)) allowed;  
  function transferFrom(address _from, address _to, uint256 _value)  returns(bool){
    require(_to != address(0));
    var _allowance = allowed[_from][msg.sender];    
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;    
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }  
  function approve(address _spender, uint256 _value) returns(bool) {    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }  
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}



contract GoldenFleeceToken is StandardToken, Ownable{

  string public constant name = "Golden Fleece";
  string public constant symbol = "GFL";
  uint256 public constant decimals = 18;


  /**
   * @dev Contructor that gives msg.sender all of existing tokens. 
   */
  function GoldenFleeceToken(uint256 _total) {
    totalSupply = _total;
    balances[owner] = _total;
  }
}