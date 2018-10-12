pragma solidity ^0.4.20;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) public pure  returns (uint256)  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b)public pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function _assert(bool assertion)public pure {
    assert(!assertion);
  }
}


contract ERC20Interface {
  string public name;
  string public symbol;
  uint8 public  decimals;
  uint public totalSupply;
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
 
 contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwer) public onlyOwner {
        owner = newOwer;
    }

}

contract SelfDesctructionContract is owned {
   
   string  public someValue;
   modifier ownerRestricted {
      require(owner == msg.sender);
      _;
   } 
 
   function SelfDesctructionContract() {
      owner = msg.sender;
   }
   
   function setSomeValue(string value){
      someValue = value;
   } 

   function destroyContract() ownerRestricted {
     selfdestruct(owner);
   }
}
 
contract ERC20 is ERC20Interface,SafeMath,SelfDesctructionContract{

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) allowed;

    constructor(string _name) public {
       name = _name;  // "UpChain";
       symbol = "GT";
       decimals = 4;
       totalSupply = 8000000000000;
       balanceOf[msg.sender] = totalSupply;
    }

  function transfer(address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));
      require(balanceOf[msg.sender] >= _value);
      require(balanceOf[ _to] + _value >= balanceOf[ _to]); 

      balanceOf[msg.sender] =SafeMath.safeSub(balanceOf[msg.sender],_value) ;
      balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to],_value) ;

      emit Transfer(msg.sender, _to, _value);

      return true;
  }


  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));
      require(allowed[_from][msg.sender] >= _value);
      require(balanceOf[_from] >= _value);
      require(balanceOf[ _to] + _value >= balanceOf[ _to]);

      balanceOf[_from] =SafeMath.safeSub(balanceOf[_from],_value) ;
      balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to],_value) ;

      allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender],_value) ;

      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      emit Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender) view returns (uint256 remaining) {
      return allowed[_owner][_spender];
  }

}