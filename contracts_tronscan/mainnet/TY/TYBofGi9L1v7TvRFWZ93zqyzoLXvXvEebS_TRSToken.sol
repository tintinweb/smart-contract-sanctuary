//SourceUnit: TRSToken.sol

pragma solidity ^0.5.4;
 
library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure  returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }

}


contract ERC20Basic {

  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public ;
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic {

  using SafeMath for uint;
    
  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public {
	balances[msg.sender] = balances[msg.sender].sub(_value);
	balances[_to] = balances[_to].add(_value);
	emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
 
}

contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) public  {
    uint _allowance = allowed[_from][msg.sender];
  
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public {
    //require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}



contract TRSToken is StandardToken {
    string public constant name = "TRS";
    string public constant symbol = "TRS";
    uint public constant decimals = 6;
    constructor () public  {
        totalSupply = 21000000 * (10 ** decimals);
        balances[msg.sender] = totalSupply;
		emit Transfer(address(0x0), msg.sender, totalSupply);
    }
    function () external payable {
        revert();
    }
}