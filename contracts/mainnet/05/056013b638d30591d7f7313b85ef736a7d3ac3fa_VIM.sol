pragma solidity ^0.4.24;


contract ERC20Interface{ 
  function totalSupply() public view returns (uint);

  function balanceOf(address who) public view returns (uint);
 
  function transfer(address to, uint value) public returns (bool);
 
  event Transfer(address indexed from, address indexed to, uint value);
  
}


contract ERC20 is ERC20Interface{
 
  function allowance(address owner, address spender) public view returns (uint);
  
  function transferFrom(address from, address to, uint value) public returns (bool);
  
  function approve (address spender, uint value) public returns (bool);

  event Approval (address indexed owner, address indexed spender, uint value);
 
}


library SafeMath {

  
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

 
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); 
    uint256 c = _a / _b;
   
    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

 
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract BasicToken is ERC20Interface{
  using SafeMath for uint256;


  mapping (address => uint256) balances;


  uint totalSupply_;


  function totalSupply() public view returns (uint){
    return totalSupply_;
  }

  function transfer(address _to, uint _value) public returns (bool){
    require (_to != address(0));
  
    require (_value <= balances[msg.sender]);
   

    balances[msg.sender] = balances[msg.sender].sub(_value);

    balances[_to] = balances[_to].add(_value);


    emit Transfer(msg.sender,_to,_value);
   
    return true; //모든것이 실행되면 참을 출력.

  }

  function balanceOf(address _owner) public view returns(uint balance){
    return balances[_owner];
  }



}


contract StandardToken is ERC20, BasicToken{


  mapping (address => mapping (address => uint)) internal allowed;
 

  function transferFrom(address _from, address _to, uint _value) public returns (bool){
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
   

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from,_to,_value);
    return true;

  }

  function approve(address _spender, uint _value) public returns (bool){
    allowed[msg.sender][_spender] = _value;
   
    emit Approval(msg.sender,_spender,_value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint){
    return allowed[_owner][_spender];
  }


}


contract VIM is StandardToken{

  string public constant name = "VIM";
  string public constant symbol = "VIM";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 4000000000 * (10**uint(decimals));

  constructor() public{
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0,msg.sender,INITIAL_SUPPLY);

  }
}